Add-Type -AssemblyName PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Registry Dictionary Scanner"
        Width="1200" Height="850"
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
        </Grid.RowDefinitions>

        <TextBlock Text="Registry Dictionary Scanner" 
                   FontSize="24" 
                   FontWeight="Bold" 
                   Foreground="White"
                   HorizontalAlignment="Center"
                   Margin="0,0,0,10"/>

        <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,10">
            <ProgressBar Name="Progress" Width="400" Height="20" Margin="0,0,10,0" Background="#333" Foreground="#4caf50"/>
            <TextBlock Name="CounterText" Text="Ready" Foreground="White" FontSize="14" VerticalAlignment="Center"/>
        </StackPanel>

        <Button Grid.Row="2" Content="Save Report" Width="150" Height="35" HorizontalAlignment="Center" Background="#0078D7" Foreground="White" FontWeight="Bold" Margin="0,0,0,10" Name="SaveButton"/>

        <GroupBox Grid.Row="3" Header="Known Entries" FontSize="16" Foreground="White" Background="#252526" BorderBrush="#4caf50" BorderThickness="2" Margin="0,5,0,10">
            <ScrollViewer VerticalScrollBarVisibility="Auto">
                <StackPanel Name="KnownList" Margin="10"/>
            </ScrollViewer>
        </GroupBox>

        <TextBlock Grid.Row="4" Text="Unknown Entries" FontSize="16" FontWeight="Bold" Foreground="White" Margin="0,10,0,5"/>

        <GroupBox Grid.Row="5" Header="Unrecognized Registry Entries" FontSize="16" Foreground="White" Background="#252526" BorderBrush="#e53935" BorderThickness="2">
            <ScrollViewer VerticalScrollBarVisibility="Auto">
                <StackPanel Name="UnknownList" Margin="10"/>
            </ScrollViewer>
        </GroupBox>
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

$DictionaryUrl = "https://raw.githubusercontent.com/WL-Chan/windows-registry-dictionary/main/data/registry_dictionary.json"

function Load-Dictionary {
    try { return (Invoke-RestMethod -Uri $DictionaryUrl -UseBasicParsing) } catch { [System.Windows.MessageBox]::Show("Failed to load dictionary.","Error") }
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

function Show-TextBlock($stack, $text, $color) {
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

Start-Job -ScriptBlock {
    param($dict, $ProgressBar, $CounterText)
    $scanRoots = @("HKLM:\SOFTWARE", "HKCU:\SOFTWARE")
    $allKeys = @()
    foreach ($root in $scanRoots) {
        $allKeys += Get-ChildItem -Path $root -Recurse -ErrorAction SilentlyContinue
    }

    $total = $allKeys.Count
    $i = 0
    foreach ($key in $allKeys) {
        $i++
        $syncHash = [System.Management.Automation.PSReference]::new($using:ProgressBar)
        $syncCounter = [System.Management.Automation.PSReference]::new($using:CounterText)
        $syncCounter.Value.Dispatcher.Invoke({ $_.Text = "Scanning $i / $total" }, $syncCounter.Value)
        $syncHash.Value.Dispatcher.Invoke({ $_.Value = [math]::Round(($i / $total) * 100, 2) }, $syncHash.Value)
        try {
            $values = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue
            $valueNames = $values.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS(A|P|C)' } | ForEach-Object { $_.Name }
            foreach ($vName in $valueNames) {
                $val = $values.$vName
                $fullPath = (&{
                    $map = @{
                        "HKLM:"="HKEY_LOCAL_MACHINE"
                        "HKCU:"="HKEY_CURRENT_USER"
                        "HKCR:"="HKEY_CLASSES_ROOT"
                        "HKU:"="HKEY_USERS"
                        "HKCC:"="HKEY_CURRENT_CONFIG"
                    }
                    foreach ($k in $map.Keys) {
                        if ($key.PSPath.StartsWith($k)) { return $map[$k] + "\" + $key.PSPath.Substring($k.Length + 1) }
                    }
                    return $key.PSPath
                })
                $entry = if ($dict.ContainsKey($fullPath)) {
                    $keys = $dict[$fullPath].PSObject.Properties.Name
                    if ($keys -contains $vName) { $dict[$fullPath].$vName }
                    elseif ($keys -contains "*") { $dict[$fullPath]."*" }
                    else { $null }
                } else { $null }

                if ($entry) {
                    [PSCustomObject]@{
                        Path = "$fullPath\$vName"
                        Desc = $entry.description
                        Cat  = $entry.category
                        Type = "Known"
                    }
                } else {
                    [PSCustomObject]@{
                        Path = "$fullPath\$vName"
                        Type = "Unknown"
                    }
                }
            }
        } catch {}
    }
} -ArgumentList $dict, $ProgressBar, $CounterText | Out-Null

Register-ObjectEvent -InputObject $SaveButton -EventName Click -Action {
    $dialog = New-Object -ComObject Microsoft.Win32.SaveFileDialog
    $dialog.Filter = "JSON File (*.json)|*.json"
    $dialog.Title = "Save Registry Scan Report"
    $dialog.FileName = "registry_scan_report.json"
    if ($dialog.ShowDialog() -eq $true) {
        $output = @{
            Known = $known
            Unknown = $unknown
            Timestamp = (Get-Date)
        }
        $json = $output | ConvertTo-Json -Depth 5
        Set-Content -Path $dialog.FileName -Value $json -Encoding UTF8
        [System.Windows.MessageBox]::Show("Report saved successfully.`n$($dialog.FileName)","Export Complete")
    }
}

$window.ShowDialog() | Out-Null
