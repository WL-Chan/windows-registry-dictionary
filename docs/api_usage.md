# API Usage Guide

This document explains how developers can use the **Windows Registry Dictionary** in external applications or scripts to interpret Windows Registry data in a human-readable format.

---

## 1. Purpose

The dictionary provides a structured JSON file (`registry_dictionary.json`) that maps registry paths and value names to readable descriptions and categories.  
Developers can integrate this file into their tools to:
- Scan registry keys and match them to known definitions.
- Translate raw values (e.g., `0`, `1`, or paths) into meaningful text.
- Build readable configuration or diagnostic reports.

---

## 2. Accessing the Dictionary

You can access the dictionary in several ways:

| Method | Description |
|--------|--------------|
| **Direct File Access** | Download or clone the repository and read the JSON file from `data/registry_dictionary.json`. |
| **Online Access (Raw URL)** | Access directly from GitHub raw content:  |
| | `https://raw.githubusercontent.com/<yourusername>/windows-registry-dictionary/main/data/registry_dictionary.json` |
| **Version Control** | Use `version.json` to check for updates before pulling new data. |

---

## 3. PowerShell Example

PowerShell provides native JSON parsing and registry access, making it a simple way to integrate the dictionary.

```powershell
# Load the dictionary from GitHub
$dictUrl = "https://raw.githubusercontent.com/<yourusername>/windows-registry-dictionary/main/data/registry_dictionary.json"
$dict = Invoke-RestMethod -Uri $dictUrl

# Example: Read a real registry value
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$valName = "EnableLUA"
$val = Get-ItemProperty -Path $regPath -Name $valName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $valName

# Lookup the meaning from the dictionary
$entry = $dict."HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System"."EnableLUA"

Write-Host "Registry Key: $regPath\$valName"
Write-Host "Value: $val"
Write-Host "Description: $($entry.description)"
Write-Host "Type: $($entry.type)"
if ($entry.values."$val") {
    Write-Host "Interpreted: $($entry.values."$val")"
}
```

Output Example:

```vbnet
Registry Key: HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA
Value: 0
Description: Controls User Account Control (UAC) prompts.
Type: DWORD
Interpreted: UAC Disabled
```

---

## 4. C# Example

Below is a basic example of using the dictionary in C# (WPF or Console).

```csharp
using System;
using System.IO;
using Microsoft.Win32;
using Newtonsoft.Json.Linq;
using System.Net.Http;
using System.Threading.Tasks;

class RegistryInterpreter
{
    static async Task Main()
    {
        string url = "https://raw.githubusercontent.com/<yourusername>/windows-registry-dictionary/main/data/registry_dictionary.json";
        using HttpClient client = new HttpClient();
        string json = await client.GetStringAsync(url);
        var dict = JObject.Parse(json);

        string regPath = @"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System";
        string valName = "EnableLUA";

        object? value = Registry.GetValue(regPath, valName, null);
        if (value == null)
        {
            Console.WriteLine("Registry value not found.");
            return;
        }

        var entry = dict[regPath]?[valName];
        if (entry != null)
        {
            Console.WriteLine($"Registry: {regPath}\\{valName}");
            Console.WriteLine($"Value: {value}");
            Console.WriteLine($"Description: {entry["description"]}");
            Console.WriteLine($"Type: {entry["type"]}");
            var valDict = entry["values"]?[value.ToString()];
            if (valDict != null)
                Console.WriteLine($"Interpreted: {valDict}");
        }
    }
}
```

This code:
1. Loads the JSON dictionary from GitHub.
2. Reads a registry value using Microsoft.Win32.Registry.
3. Matches the path and name in the dictionary.
4. Outputs human-readable information.

---

## 5. Python Example

For Python users, the dictionary can be integrated easily using requests and winreg.

```python
import json, requests, winreg

url = "https://raw.githubusercontent.com/<yourusername>/windows-registry-dictionary/main/data/registry_dictionary.json"
data = json.loads(requests.get(url).text)

reg_path = r"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, reg_path)
val, _ = winreg.QueryValueEx(key, "EnableLUA")

entry = data.get("HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System", {}).get("EnableLUA", {})

print("Registry Key:", reg_path)
print("Value:", val)
print("Description:", entry.get("description"))
print("Type:", entry.get("type"))
print("Interpreted:", entry.get("values", {}).get(str(val), "Unknown"))
```

---

## 6. Integration Ideas

| Use Case                      | Description                                                                              |
| ----------------------------- | ---------------------------------------------------------------------------------------- |
| **Registry Scanner**          | Build a tool that scans the registry and explains detected values using this dictionary. |
| **System Diagnostics App**    | Translate system configuration into readable summaries for support or troubleshooting.   |
| **Policy Compliance Checker** | Compare registry values to expected defaults for corporate or security compliance.       |
| **Documentation Generator**   | Export registry info and interpretations into HTML or Markdown reports.                  |

---

## 7. Version Synchronization

Applications using this dictionary should:
1. Fetch version.json periodically.
2. Compare local and remote versions.
3. Download updates only when a newer version is available.

Example (PowerShell):

```powershell
$remoteVersion = (Invoke-RestMethod -Uri "https://raw.githubusercontent.com/<yourusername>/windows-registry-dictionary/main/version.json").version
Write-Host "Latest Dictionary Version: $remoteVersion"
```

---

## 8. Recommended Libraries

| Language   | Libraries                                     |
| ---------- | --------------------------------------------- |
| PowerShell | `ConvertFrom-Json`, `Invoke-RestMethod`       |
| C#         | `Newtonsoft.Json`, `Microsoft.Win32.Registry` |
| Python     | `requests`, `json`, `winreg`                  |

---

## 9. Notes and Best Practices

- Always validate registry paths before use.
- Handle exceptions for missing keys or permissions.
- Cache the dictionary locally to reduce network calls.
- Respect user privileges when scanning system hives (may require admin).
- Match keys case-insensitively for better compatibility.

---

## 10. License

Usage of this dictionary is covered under the MIT License.
You may freely use, integrate, and distribute it in your own tools or products, provided attribution remains intact.

