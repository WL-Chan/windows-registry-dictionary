if (![Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Write-Host "Restarting in STA mode..."
    Start-Process pwsh -ArgumentList "-STA -File `"$PSCommandPath`"" -Wait
    exit
}

Add-Type -AssemblyName PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Registry Dictionary Scanner"
        Width="1250" Height="850"
        Background="#1e1e1e"
        WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="Registry Dictionary Scanner" 
                   FontSize="26" 
                   FontWeight="Bold" 
                   Foreground="White"
                   HorizontalAlignment="Center"
                   Margin="0,0,0,15"/>

        <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,10">
            <ProgressBar Name="Progress" Width="400" Height="22" Background="#333" Foreground="#4CAF50" Margin="0,0,15,0"/>
            <TextBlock Name="CounterText" Text="Waiting to start..." Foreground="White" FontSize="14" VerticalAlignment="Center"/>
        </StackPanel>

        <Button Grid.Row="2" Content="Save Report" Width="150" Height="35" HorizontalAlignment="Center" Background="#0078D7" Foreground="White" FontWeight="Bold" Margin="0,0,0,15" Name="SaveButton"/>

        <GroupBox Grid.Row="3" Header="Known Entries" FontSize="16" Foreground="White" Background="#252526" BorderBrush="#4caf50" BorderThickness="2" Margin="0,5,0,10">
            <ScrollViewer VerticalScrollBarVisibility="Auto">
                <StackPanel Name="KnownList" Margin="10"/>
            </ScrollViewer>
        </GroupBox>

        <TextBlock Grid.Row="4" Text="Unknown Entries" FontSize="16" FontWeight="Bold" Foreground="White" Margin="0,10,0,5"/>

        <GroupBox Grid.Row="5" Header="Unrecognized Registry Entries" FontSize="16" Foreground="White" Background="#252526" BorderBrush="#E53935" BorderThickness="2">
            <ScrollViewer VerticalScrollBarVisibility="Auto">
                <StackPanel Name="UnknownList" Margin="10"/>
            </ScrollViewer>
        </GroupBox>

        <TextBlock Grid.Row="6" Name="SummaryText" Foreground="LightGray" FontSize="13" HorizontalAlignment="Center" Margin="0,10,0,0"/>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$KnownList   = $window.FindName("KnownList")
$UnknownList = $window.FindName("UnknownList")
$ProgressBar = $window.FindName("Progress")
$CounterText = $window.FindName("CounterText")
$SaveButton  = $window.FindName("SaveButton")
$SummaryText = $window.FindName("SummaryText")

$DictionaryUrl = "https://raw.githubusercontent.com/WL-Chan/windows-registry-dictionary/main/data/registry_dictionary.json"

function Load-Dictionary {
    try { return (Invoke-RestMethod -Uri $DictionaryUrl -UseBasicParsing) }
    catch { [System.Windows.MessageBox]::Show("Failed to load dictionary from GitHub.","Error") }
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

function Add-Text($stack, $text, $color) {
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $text
    $tb.TextWrapping = "Wrap"
    $tb.Margin = "0,5,0,5"
    $tb.Foreground = (New-Object Windows.Media.SolidColorBrush ([Windows.Media.ColorConverter]::ConvertFromString($color)))
    $tb.FontFamily = "Consolas"
    $tb.FontSize = 13
    $stack.Children.Add($tb)
}

$dict = Load-Dictionary
if (-not $dict) { return }

$known = New-Object System.Collections.Generic.List[Object]
$unknown = New-Object System.Collections.Generic.List[Object]

$scanRoots = @("HKLM:\SOFTWARE", "HKCU:\SOFTWARE")
$allKeys = @()
foreach ($root in $scanRoots) {
    try { $allKeys += Get-ChildItem -Path $root -Recurse -ErrorAction SilentlyContinue }
    catch {}
}

$total = $allKeys.Count
$count = 0
$ProgressBar.Maximum = 100

foreach ($key in $allKeys) {
    $count++
    $ProgressBar.Dispatcher.Invoke({ $_.Value = [math]::Round(($count / $total) * 100, 1) }, $ProgressBar)
    $CounterText.Dispatcher.Invoke({ $_.Text = "Scanning $count / $total" }, $CounterText)
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

foreach ($item in $known) {
    Add-Text $KnownList ("📘 " + $item.Path + "`n    → " + $item.Desc) "#90EE90"
}

foreach ($item in $unknown) {
    Add-Text $UnknownList ("🧩 " + $item.Path) "#FF6347"
}

$SummaryText.Text = "Known: $($known.Count)    Unknown: $($unknown.Count)"

$SaveButton.Add_Click({
    $dialog = New-Object -ComObject Microsoft.Win32.SaveFileDialog
    $dialog.Filter = "JSON File (*.json)|*.json"
    $dialog.Title = "Save Registry Scan Report"
    $dialog.FileName = "registry_scan_report.json"
    if ($dialog.ShowDialog() -eq $true) {
        $output = @{
            Known = $known
            Unknown = $unknown
            Summary = @{
                KnownCount = $known.Count
                UnknownCount = $unknown.Count
                Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }
        }
        $json = $output | ConvertTo-Json -Depth 5
        Set-Content -Path $dialog.FileName -Value $json -Encoding UTF8
        [System.Windows.MessageBox]::Show("Report saved successfully.`n$($dialog.FileName)","Export Complete")
    }
})

$CounterText.Text = "Scan completed."
$window.ShowDialog() | Out-Null
