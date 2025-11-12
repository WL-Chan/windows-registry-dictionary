Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$DictionaryUrl = "https://raw.githubusercontent.com/WL-Chan/windows-registry-dictionary/main/data/registry_dictionary.json"

function Load-Dictionary {
    try {
        return (Invoke-RestMethod -Uri $DictionaryUrl -UseBasicParsing)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to load dictionary from GitHub.","Error","OK","Error")
        exit
    }
}

function Get-EntryInfo {
    param($dict, $path, $name)
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

# ---------- UI SETUP ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Registry Dictionary Scanner"
$form.Width = 1000
$form.Height = 700
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)

$font = New-Object System.Drawing.Font("Consolas",10)

$labelStatus = New-Object System.Windows.Forms.Label
$labelStatus.Text = "Ready to scan."
$labelStatus.ForeColor = "White"
$labelStatus.Font = $font
$labelStatus.Location = New-Object System.Drawing.Point(20,20)
$labelStatus.AutoSize = $true
$form.Controls.Add($labelStatus)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20,50)
$progressBar.Size = New-Object System.Drawing.Size(940,20)
$form.Controls.Add($progressBar)

$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "Save Report"
$btnSave.Location = New-Object System.Drawing.Point(20,80)
$btnSave.BackColor = [System.Drawing.Color]::FromArgb(0,120,215)
$btnSave.ForeColor = "White"
$btnSave.FlatStyle = "Flat"
$form.Controls.Add($btnSave)

# Panels
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

# ---------- SCAN ----------
$form.Add_Shown({
    $labelStatus.Text = "Loading dictionary..."
    $dict = Load-Dictionary
    $known = New-Object System.Collections.Generic.List[Object]
    $unknown = New-Object System.Collections.Generic.List[Object]

    $scanRoots = @("HKLM:\SOFTWARE", "HKCU:\SOFTWARE")
    $allKeys = @()
    foreach ($root in $scanRoots) {
        try { $allKeys += Get-ChildItem -Path $root -Recurse -ErrorAction SilentlyContinue }
        catch {}
    }

    $total = $allKeys.Count
    $i = 0

    foreach ($key in $allKeys) {
        $i++
        $percent = [math]::Round(($i / $total) * 100)
        $progressBar.Value = $percent
        $labelStatus.Text = "Scanning $i / $total ..."
        $form.Refresh()

        try {
            $values = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue
            $valueNames = $values.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS(A|P|C)' } | ForEach-Object { $_.Name }
            foreach ($vName in $valueNames) {
                $val = $values.$vName
                $fullPath = Convert-PathToFull $key.PSPath
                $entry = Get-EntryInfo -dict $dict -path $fullPath -name $vName
                if ($entry) {
                    $known.Add([PSCustomObject]@{
                        Path = "$fullPath\$vName"
                        Desc = $entry.description
                        Cat  = $entry.category
                    })
                } else {
                    $unknown.Add([PSCustomObject]@{
                        Path = "$fullPath\$vName"
                    })
                }
            }
        } catch {}
    }

    $known = $known | Sort-Object Path
    $unknown = $unknown | Sort-Object Path

    foreach ($k in $known) { $txtKnown.AppendText("[$($k.Cat)] $($k.Path)`r`n    $($k.Desc)`r`n`r`n") }
    foreach ($u in $unknown) { $txtUnknown.AppendText("$($u.Path)`r`n") }

    $lblSummary.Text = "Known: $($known.Count)    Unknown: $($unknown.Count)"
    $labelStatus.Text = "Scan complete."
})

# ---------- SAVE ----------
$btnSave.Add_Click({
    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Filter = "JSON Files (*.json)|*.json"
    $dialog.Title = "Save Registry Scan Report"
    $dialog.FileName = "registry_scan_report.json"

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $output = @{
            Known = $known
            Unknown = $unknown
            Summary = @{
                KnownCount = $known.Count
                UnknownCount = $unknown.Count
                Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
        }
        $output | ConvertTo-Json -Depth 5 | Set-Content -Path $dialog.FileName -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Report saved:`n$($dialog.FileName)","Export Complete","OK","Information")
    }
})

[void]$form.ShowDialog()
