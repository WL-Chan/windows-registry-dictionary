Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$DictionaryUrl = "https://raw.githubusercontent.com/WL-Chan/windows-registry-dictionary/main/data/registry_dictionary.json"

function Load-Dictionary {
    try { Invoke-RestMethod -Uri $DictionaryUrl -UseBasicParsing } 
    catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to load dictionary from GitHub.`n$($_.Exception.Message)","Error")
        return $null
    }
}

function Get-EntryInfo {
    param($dict, $path, $name)
    if ($null -eq $dict) { return $null }
    if ($dict.ContainsKey($path)) {
        $keys = $dict[$path].PSObject.Properties.Name
        if ($keys -contains $name) { return $dict[$path].$name }
        elseif ($keys -contains "*") { return $dict[$path]."*" }
    }
    return $null
}

function Convert-PathToFull {
    param([string]$prov)
    $map = @{
        "HKLM:"="HKEY_LOCAL_MACHINE"
        "HKCU:"="HKEY_CURRENT_USER"
        "HKCR:"="HKEY_CLASSES_ROOT"
        "HKU:"="HKEY_USERS"
        "HKCC:"="HKEY_CURRENT_CONFIG"
    }
    foreach ($k in $map.Keys) {
        if ($prov.StartsWith($k)) { return $map[$k] + "\" + $prov.Substring($k.Length + 1) }
    }
    return $prov
}

# -------- UI ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Registry Dictionary Scanner"
$form.Width = 1000
$form.Height = 700
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)

$font = New-Object System.Drawing.Font("Consolas",10)

$labelStatus = New-Object System.Windows.Forms.Label
$labelStatus.Text = "Idle"
$labelStatus.ForeColor = "White"
$labelStatus.Font = $font
$labelStatus.Location = New-Object System.Drawing.Point(20,20)
$labelStatus.AutoSize = $true
$form.Controls.Add($labelStatus)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20,50)
$progressBar.Size = New-Object System.Drawing.Size(940,20)
$form.Controls.Add($progressBar)

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Start Scan"
$btnStart.Location = New-Object System.Drawing.Point(20,80)
$btnStart.Width = 120
$btnStart.BackColor = [System.Drawing.Color]::FromArgb(60,180,75)
$btnStart.ForeColor = "White"
$form.Controls.Add($btnStart)

$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "Save Report"
$btnSave.Location = New-Object System.Drawing.Point(160,80)
$btnSave.Width = 120
$btnSave.BackColor = [System.Drawing.Color]::FromArgb(0,120,215)
$btnSave.ForeColor = "White"
$form.Controls.Add($btnSave)

$txtKnown = New-Object System.Windows.Forms.TextBox
$txtKnown.Multiline = $true
$txtKnown.ScrollBars = "Vertical"
$txtKnown.Font = $font
$txtKnown.BackColor = [System.Drawing.Color]::FromArgb(40,40,40)
$txtKnown.ForeColor = "LightGreen"
$txtKnown.ReadOnly = $true
$txtKnown.WordWrap = $false
$txtKnown.Location = New-Object System.Drawing.Point(20,120)
$txtKnown.Size = New-Object System.Drawing.Size(450,480)
$form.Controls.Add($txtKnown)

$txtUnknown = New-Object System.Windows.Forms.TextBox
$txtUnknown.Multiline = $true
$txtUnknown.ScrollBars = "Vertical"
$txtUnknown.Font = $font
$txtUnknown.BackColor = [System.Drawing.Color]::FromArgb(40,40,40)
$txtUnknown.ForeColor = "IndianRed"
$txtUnknown.ReadOnly = $true
$txtUnknown.WordWrap = $false
$txtUnknown.Location = New-Object System.Drawing.Point(510,120)
$txtUnknown.Size = New-Object System.Drawing.Size(450,480)
$form.Controls.Add($txtUnknown)

$lblSummary = New-Object System.Windows.Forms.Label
$lblSummary.ForeColor = "LightGray"
$lblSummary.Font = $font
$lblSummary.Location = New-Object System.Drawing.Point(20,620)
$lblSummary.AutoSize = $true
$form.Controls.Add($lblSummary)

$btnSave.Enabled = $false

# Preload dictionary on main thread
$labelStatus.Text = "Loading dictionary..."
$form.Refresh()
$global:RegistryDict = Load-Dictionary
if ($null -eq $global:RegistryDict) {
    $labelStatus.Text = "Failed to load dictionary."
} else {
    $labelStatus.Text = "Dictionary loaded. Ready."
}

# Concurrent queue for inter-thread messages
$queueType = [type]::GetType("System.Collections.Concurrent.ConcurrentQueue`1[[System.Object]]")
$queue = $queueType::new()

# Timer to poll queue and update UI
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 200

$timer.Add_Tick({
    while ($queue.TryDequeue([ref]$msg)) {
        if ($null -eq $msg) { continue }
        switch ($msg.Type) {
            "Progress" {
                $progressBar.Value = [math]::Max(0, [math]::Min(100, [int]$msg.Percent))
                $labelStatus.Text = $msg.Message
            }
            "Partial" {
                # partial text chunk to append (avoid huge single writes)
                if ($msg.Target -eq "Known") { $txtKnown.AppendText($msg.Text + "`r`n") }
                elseif ($msg.Target -eq "Unknown") { $txtUnknown.AppendText($msg.Text + "`r`n") }
            }
            "Complete" {
                $txtKnown.Lines = $msg.KnownLines
                $txtUnknown.Lines = $msg.UnknownLines
                $lblSummary.Text = "Known: $($msg.KnownCount)    Unknown: $($msg.UnknownCount)"
                $labelStatus.Text = "Scan complete."
                $btnSave.Enabled = $true
                $btnStart.Enabled = $true
                $progressBar.Value = 100
            }
            "Error" {
                $labelStatus.Text = "Error: " + $msg.Message
                $btnStart.Enabled = $true
            }
        }
    }
})

# Start scan button -> create runspace and begin scanning
$btnStart.Add_Click({
    if ($null -eq $global:RegistryDict) {
        [System.Windows.Forms.MessageBox]::Show("Dictionary not loaded. Cannot scan.","Error")
        return
    }

    $btnStart.Enabled = $false
    $btnSave.Enabled = $false
    $txtKnown.Clear()
    $txtUnknown.Clear()
    $lblSummary.Text = ""
    $progressBar.Value = 0
    $labelStatus.Text = "Starting scan..."
    $form.Refresh()
    $timer.Start()

    $ps = [powershell]::Create()
    $ps.Runspace = [runspacefactory]::CreateRunspace()
    $ps.Runspace.ApartmentState = "STA"
    $ps.Runspace.ThreadOptions = "ReuseThread"
    $ps.Runspace.Open()

    $ps.AddArgument($queue)
    $ps.AddArgument($global:RegistryDict)

    $ps.AddScript({
        param($queue, $dict)
        try {
            $scanRoots = @("HKLM:\SOFTWARE", "HKCU:\SOFTWARE")
            $allKeys = @()
            foreach ($root in $scanRoots) {
                try { $allKeys += Get-ChildItem -Path $root -Recurse -ErrorAction SilentlyContinue }
                catch {}
            }
            $total = $allKeys.Count
            if ($total -eq 0) { $total = 1 }
            $i = 0
            $known = New-Object System.Collections.ArrayList
            $unknown = New-Object System.Collections.ArrayList

            foreach ($key in $allKeys) {
                $i++
                $percent = [math]::Round(($i / $total) * 100)
                $msg = @{ Type="Progress"; Percent=$percent; Message="Scanning $i / $total" }
                $queue.Enqueue($msg)

                try {
                    $values = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue
                    $valueNames = $values.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS(A|P|C)' } | ForEach-Object { $_.Name }
                    foreach ($vName in $valueNames) {
                        $fullPath = Convert-PathToFull $key.PSPath
                        $entry = $null
                        if ($null -ne $dict) {
                            if ($dict.ContainsKey($fullPath)) {
                                $keys = $dict[$fullPath].PSObject.Properties.Name
                                if ($keys -contains $vName) { $entry = $dict[$fullPath].$vName }
                                elseif ($keys -contains "*") { $entry = $dict[$fullPath]."*" }
                            }
                        }
                        if ($entry) {
                            $obj = [PSCustomObject]@{ Path = "$fullPath\$vName"; Desc = $entry.description; Cat = $entry.category }
                            [void]$known.Add($obj)
                        } else {
                            $obj = [PSCustomObject]@{ Path = "$fullPath\$vName" }
                            [void]$unknown.Add($obj)
                        }
                    }
                } catch {}
                # reduce UI flooding: send partial lines every 200 items
                if (($i % 200) -eq 0) {
                    # send small sample partial lines (not required, main final will set all)
                    $queue.Enqueue(@{ Type="Partial"; Target="Known"; Text="Scanned $i of $total..." })
                }
            }

            # prepare final arrays for UI
            $knownSorted = $known | Sort-Object Path
            $unknownSorted = $unknown | Sort-Object Path
            $knownLines = $knownSorted | ForEach-Object { "[$($_.Cat)] $($_.Path)`r`n    $($_.Desc)" }
            $unknownLines = $unknownSorted | ForEach-Object { $_.Path }

            $completeMsg = @{
                Type = "Complete"
                KnownLines = $knownLines
                UnknownLines = $unknownLines
                KnownCount = $knownSorted.Count
                UnknownCount = $unknownSorted.Count
            }
            $queue.Enqueue($completeMsg)
        } catch {
            $queue.Enqueue(@{ Type="Error"; Message = $_.Exception.Message })
        }
    })

    $ps.BeginInvoke() | Out-Null
})

# Save Report
$btnSave.Add_Click({
    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Filter = "JSON Files (*.json)|*.json"
    $dialog.Title = "Save Registry Scan Report"
    $dialog.FileName = "registry_scan_report.json"
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $output = @{
            Known = $txtKnown.Lines
            Unknown = $txtUnknown.Lines
            Summary = @{
                KnownCount = $txtKnown.Lines.Count
                UnknownCount = $txtUnknown.Lines.Count
                Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
        }
        $output | ConvertTo-Json -Depth 5 | Set-Content -Path $dialog.FileName -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Report saved:`n$($dialog.FileName)","Export Complete","OK","Information")
    }
})

[void]$form.ShowDialog()
#
