<#
.SYNOPSIS
  Simple registry scanner that uses the Windows Registry Dictionary JSON to interpret values.

.DESCRIPTION
  Loads registry_dictionary.json (remote URL by default) and scans registry paths.
  For each value found, the script attempts to look up a human-readable description
  and interpreted value. Outputs results to console and optionally to a JSON file.

.NOTES
  - This script reads the registry only. It does not write or modify anything.
  - Use Run as Administrator for full access to system hives if required.
  - Replace <yourusername> in $DefaultDictionaryUrl with your GitHub username or raw URL.

.PARAMETER DictionaryUrl
  Optional override URL to the registry_dictionary.json raw file.

.PARAMETER ScanPaths
  Array of registry provider-style paths to scan (defaults provided).

.PARAMETER OutputJson
  Optional path to save machine-readable scan results as JSON.

.EXAMPLE
  .\registry_scanner.ps1 -OutputJson .\scan_results.json

#>

param (
    [string]$DictionaryUrl = "https://raw.githubusercontent.com/<yourusername>/windows-registry-dictionary/main/data/registry_dictionary.json",
    [string[]]$ScanPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\Control Panel\Desktop",
        "HKLM:\SYSTEM\CurrentControlSet\Control"
    ),
    [string]$OutputJson = ""
)

function Convert-ProviderToRegistryPath {
    param([string]$provPath)
    # Convert PowerShell provider style (HKLM:\...) to long form (HKEY_LOCAL_MACHINE\...)
    $map = @{
        "HKLM:" = "HKEY_LOCAL_MACHINE"
        "HKCU:" = "HKEY_CURRENT_USER"
        "HKCR:" = "HKEY_CLASSES_ROOT"
        "HKU:"  = "HKEY_USERS"
        "HKCC:" = "HKEY_CURRENT_CONFIG"
    }
    foreach ($k in $map.Keys) {
        if ($provPath -like "$k*") {
            $rest = $provPath.Substring($k.Length)
            # Normalize leading backslash
            if ($rest.StartsWith('\')) { $rest = $rest.Substring(1) }
            return ($map[$k] + "\" + $rest)
        }
    }
    return $provPath
}

function Load-Dictionary {
    param([string]$url)

    Write-Host "Loading dictionary from: $url"
    try {
        $json = Invoke-RestMethod -Uri $url -UseBasicParsing -ErrorAction Stop
        return $json
    } catch {
        Write-Warning "Failed to load dictionary from URL: $($_.Exception.Message)"
        # fallback: try local data file if exists in repo relative path
        $local = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "..\data\registry_dictionary.json"
        $local = (Resolve-Path $local -ErrorAction SilentlyContinue)
        if ($local) {
            Write-Host "Loading dictionary from local file: $local"
            $text = Get-Content -Path $local -Raw
            return $text | ConvertFrom-Json
        } else {
            throw "Unable to load dictionary from remote or local path."
        }
    }
}

function Find-DictionaryEntry {
    param(
        [hashtable]$dict,
        [string]$regKeyPath,   # e.g. HKEY_LOCAL_MACHINE\SOFTWARE\...
        [string]$valueName     # e.g. EnableLUA or "MyApp"
    )

    # Direct exact match: dict[regKeyPath][valueName]
    if ($dict.ContainsKey($regKeyPath)) {
        $entrySet = $dict[$regKeyPath]
        if ($entrySet -and $entrySet.PSObject.Properties.Name -contains $valueName) {
            return $entrySet.$valueName
        }
        # If path has a '*' wildcard mapping
        if ($entrySet -and $entrySet.PSObject.Properties.Name -contains '*') {
            return $entrySet.'*'
        }
    }

    # If not found, try wildcard entries on parent paths (e.g., Services wildcard)
    # Walk up the path segments and check for a '*' mapping at higher levels
    $segments = $regKeyPath.Split("\")
    for ($i = $segments.Length - 1; $i -gt 0; $i--) {
        $parent = ($segments[0..($i-1)] -join "\")
        if ($dict.ContainsKey($parent)) {
            $parentSet = $dict[$parent]
            if ($parentSet -and $parentSet.PSObject.Properties.Name -contains '*') {
                return $parentSet.'*'
            }
        }
    }

    return $null
}

function Interpret-Value {
    param(
        $entry,       # dictionary entry object (may contain values map)
        $rawValue
    )
    if (-not $entry) { return $null }
    # If entry has values mapping and contains the key for rawValue (as string)
    if ($entry.values) {
        $key = $rawValue -as [string]
        if ($null -ne $key -and $entry.values.PSObject.Properties.Name -contains $key) {
            return $entry.values.$key
        }
    }
    return $null
}

# Script start
$dictObject = Load-Dictionary -url $DictionaryUrl
if (-not $dictObject) { throw "Dictionary could not be loaded." }

# Ensure we have a hashtable-like object for lookup (ConvertFrom-Json returns PSCustomObject)
# Convert to hashtable keyed by path for easier ContainsKey usage
$dict = @{}
foreach ($prop in $dictObject.PSObject.Properties) {
    $dict[$prop.Name] = $prop.Value
}

$results = @()

foreach ($provPath in $ScanPaths) {
    Write-Host "`nScanning path: $provPath" -ForegroundColor Cyan

    try {
        # Check path exists
        if (-not (Test-Path -Path $provPath)) {
            Write-Warning "Path not found or inaccessible: $provPath"
            continue
        }

        # Get values under that key (properties)
        $item = Get-Item -Path $provPath -ErrorAction Stop
        $props = Get-ItemProperty -Path $provPath -ErrorAction Stop

        # Enumerate value names and values: properties include PSPath, PSChildName etc.
        $valueNames = $props.PSObject.Properties | Where-Object {
            $_.Name -notin @('PSPath','PSParentPath','PSChildName','PSDrive','PSProvider')
        } | ForEach-Object { $_.Name }

        foreach ($vName in $valueNames) {
            $vRaw = $props.$vName
            # Build registry style full path for lookup
            $regKeyLong = Convert-ProviderToRegistryPath -provPath $provPath
            # Some provider paths include subkeys; we want the parent key path where the value resides
            $fullPathForLookup = $regKeyLong

            $entry = Find-DictionaryEntry -dict $dict -regKeyPath $fullPathForLookup -valueName $vName
            $interpreted = Interpret-Value -entry $entry -rawValue $vRaw

            $res = [PSCustomObject]@{
                path = ($fullPathForLookup + "\" + $vName)
                raw_value = $vRaw
                interpreted_value = if ($interpreted) { $interpreted } else { switch -Regex ($vRaw) {
                        '^(?:\\|/|[A-Za-z]:\\)' { "Path or command: $vRaw"; break }
                        default { if ($entry) { "Known key, raw value: $vRaw" } else { "Unknown (no dictionary entry)" } }
                    }
                }
                description = if ($entry) { $entry.description } else { $null }
                category = if ($entry) { $entry.category } else { $null }
            }
            $results += $res

            # Print human-friendly
            $shortDesc = if ($res.description) { $res.description } else { "No description available" }
            Write-Host "  - $($vName) = $($vRaw)" -ForegroundColor Yellow
            Write-Host "    -> $($res.interpreted_value) ; $shortDesc" -ForegroundColor Gray
        }

        # Optionally, enumerate subkeys (to allow scanning deeper). Not automatic to avoid large scans.
        # $subkeys = Get-ChildItem -Path $provPath -ErrorAction SilentlyContinue
        # foreach ($sk in $subkeys) { ... }

    } catch {
        Write-Warning "Failed to read $provPath : $($_.Exception.Message)"
    }
}

# Output JSON if requested
if ($OutputJson) {
    $out = [PSCustomObject]@{
        scan_metadata = @{
            scan_date = (Get-Date).ToUniversalTime().ToString("o")
            scanned_paths = $ScanPaths
            dictionary_source = $DictionaryUrl
            dictionary_version = ( (Get-Content -Path (Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "..\version.json") -Raw) -as [string] ) 2>$null
        }
        results = $results
    }

    $jsonText = $out | ConvertTo-Json -Depth 6
    try {
        $dir = Split-Path -Path $OutputJson -Parent
        if ($dir -and -not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
        $jsonText | Set-Content -Path $OutputJson -Encoding UTF8
        Write-Host "`nSaved results to $OutputJson"
    } catch {
        Write-Warning "Failed to save output JSON: $($_.Exception.Message)"
    }
}

# Return results object
return $results
