# Windows Registry Dictionary
# A Windows Registry Human Dictionary
This project is an open JSON-based dictionary that translates **Windows Registry keys** into human-readable names and explanations.

# Purpose
To make the Windows Registry understandable — both for developers and regular users.

# Structure
- **registry_dictionary.json** — Main list of keys, descriptions, and value meanings  
- **categories.json** — Classification for easy filtering  
- **version.json** — Used by external tools to check for updates  

# Example
```json
"HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System": {
  "EnableLUA": {
    "description": "Controls User Account Control (UAC) prompts.",
    "type": "DWORD",
    "values": {
      "0": "Disabled",
      "1": "Enabled"
    },
    "category": "Security"
  }
}

