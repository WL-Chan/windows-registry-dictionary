Add-Type -AssemblyName PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Registry Dictionary Scanner"
        Width="1200" Height="800"
        Background="#1e1e1e"
        WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <TextBlock Text="Registry Dictionary Scanner"
                   FontSize="24" FontWeight="Bold"
                   Foreground="White"
                   HorizontalAlignment="Center"
                   Margin="0,0,0,10"/>
        <GroupBox Grid.Row="1" Header="Known Entries"
                  FontSize="16" Foreground="White"
                  Background="#252526"
                  BorderBrush="#4caf50"
                  BorderThickness="2"
                  Margin="0,5,0,10">
            <ScrollViewer VerticalScrollBarVisibility="Auto">
                <StackPanel Name="KnownList" Margin="10"/>
            </ScrollViewer>
        </GroupBox>
        <TextBlock Grid.Row="2" Text="Unknown Entries"
                   FontSize="16"
                   FontWeight="Bold"
                   Foreground="White"
                   Margin="0,10,0,5"/>
        <GroupBox Grid.Row="3" Header="Unrecognized Registry Entries"
                  FontSize="16" Foreground="White"
                  Background="#252526"
                  BorderBrush="#e53935"
                  BorderThickness="2">
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

$DictionaryUrl = "https://raw.githubusercontent.com/WL-Chan/windows-registry-dictionary/main/data/registry_dictionary.json"

function Load-Dictionary {
    try { return (Invoke-RestMethod -Uri $DictionaryUrl -UseBasicParsing) }
    catch { [System.Windows.MessageBox]::Show("Failed to load dictionary.`n$($_.Exception.Message)","Error") }
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
        if ($prov.StartsWith($k)) {
            return $map[$k] + "\" + $prov.Substring($k.Length + 1)
        }
    }
    return $prov
}

$dict = Load-Dictionary
if (-not $dict) { return }

$known = @()
$unknown = @()

$scanRoots = @("HKLM:\SOFTWARE", "HKCU:\SOFTWARE")

foreach ($root in $scanRoots) {
    try {
        $keys = Get-ChildItem -Path $root -Recurse -ErrorAction SilentlyContinue
        foreach ($key in $keys) {
            try {
                $values = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue
                $valueNames = $values.PSObject.Properties | Where-Object {
                    $_.Name -notmatch '^PS(A|P|C)'
                } | ForEach-Object { $_.Name }
                foreach ($vName in $valueNames) {
                    $val = $values.$vName
                    $fullPath = Convert-PathToFull $key.PSPath
                    $entry = Get-EntryInfo -dict $dict -path $fullPath -name $vName
                    if ($entry) {
                        $known += [PSCustomObject]@{
                            Path = "$fullPath\$vName"
                            Desc = $entry.description
                            Cat = $entry.category
                        }
                    } else {
                        $unknown += [PSCustomObject]@{
                            Path = "$fullPath\$vName"
                        }
                    }
                }
            } catch {}
        }
    } catch {}
}

foreach ($item in $known) {
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = "📘 $($item.Path)`n   → $($item.Desc)"
    $tb.TextWrapping = "Wrap"
    $tb.Margin = "0,5,0,5"
    $tb.Foreground = [Windows.Media.Brushes]::LightGreen
    $tb.FontFamily = "Consolas"
    $tb.FontSize = 13
    $KnownList.Children.Add($tb)
}

foreach ($item in $unknown) {
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = "🧩 $($item.Path)"
    $tb.TextWrapping = "Wrap"
    $tb.Margin = "0,5,0,5"
    $tb.Foreground = [Windows.Media.Brushes]::OrangeRed
    $tb.FontFamily = "Consolas"
    $tb.FontSize = 13
    $UnknownList.Children.Add($tb)
}

$window.ShowDialog() | Out-Null
