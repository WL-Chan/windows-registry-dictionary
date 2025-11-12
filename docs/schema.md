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
