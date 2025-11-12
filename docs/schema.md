# Windows Registry Dictionary - JSON Schema Specification

This document defines the structure and conventions used in `registry_dictionary.json` and other related data files within this project.

---

## 1. Purpose

The JSON schema standardizes how Windows Registry data is stored, categorized, and interpreted in a human-readable format.  
This ensures consistency for developers, contributors, and tools that consume the dictionary.

---

## 2. File Overview

| File | Description |
|------|--------------|
| `registry_dictionary.json` | Main registry data dictionary. Contains registry paths, value definitions, and descriptions. |
| `categories.json` | Contains all recognized category names and their descriptions. |
| `version.json` | Holds the current version number of the dictionary for update tracking. |

---

## 3. Schema Structure: `registry_dictionary.json`

Each top-level key in the dictionary represents a registry path.  
Each path may contain one or more registry values, with associated metadata.

### Example

```json
{
  "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System": {
    "EnableLUA": {
      "description": "Controls User Account Control (UAC) prompts.",
      "type": "DWORD",
      "values": {
        "0": "UAC Disabled",
        "1": "UAC Enabled"
      },
      "category": "Security"
    }
  }
}
```

### 4. Field Descriptions
| Field           | Type   | Description                                                                                      | Required |
| --------------- | ------ | ------------------------------------------------------------------------------------------------ | -------- |
| **description** | string | Human-readable explanation of the key or value.                                                  | Yes      |
| **type**        | string | Registry data type (e.g., `DWORD`, `REG_SZ`, `REG_BINARY`, `complex`).                           | Yes      |
| **values**      | object | Optional mapping of registry data values to readable states. Used for enumeration-type settings. | No       |
| **category**    | string | Logical category (must match one defined in `categories.json`).                                  | Yes      |

### 5. Wildcard Rules
Some keys represent multiple subkeys or values.
To support this, wildcards are used.
| Wildcard | Meaning                                                                |
| -------- | ---------------------------------------------------------------------- |
| `*`      | Matches any subkey or value under the specified path.                  |
| `{any}`  | Placeholder for variable subkey names (optional alternative notation). |

Example:
```
"HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services": {
  "*": {
    "description": "Each subkey represents a system service or driver.",
    "type": "complex",
    "values": {},
    "category": "System Core"
  }
}
```


