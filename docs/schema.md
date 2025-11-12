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

---

## 4. Field Descriptions

| Field           | Type   | Description                                                                                      | Required |
| --------------- | ------ | ------------------------------------------------------------------------------------------------ | -------- |
| **description** | string | Human-readable explanation of the key or value.                                                  | Yes      |
| **type**        | string | Registry data type (e.g., `DWORD`, `REG_SZ`, `REG_BINARY`, `complex`).                           | Yes      |
| **values**      | object | Optional mapping of registry data values to readable states. Used for enumeration-type settings. | No       |
| **category**    | string | Logical category (must match one defined in `categories.json`).                                  | Yes      |

---

## 5. Wildcard Rules
Some keys represent multiple subkeys or values.
To support this, wildcards are used.
| Wildcard | Meaning                                                                |
| -------- | ---------------------------------------------------------------------- |
| `*`      | Matches any subkey or value under the specified path.                  |
| `{any}`  | Placeholder for variable subkey names (optional alternative notation). |

Example:
```json
"HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services": {
  "*": {
    "description": "Each subkey represents a system service or driver.",
    "type": "complex",
    "values": {},
    "category": "System Core"
  }
}
```

---

## 6. Data Types (type Field)

| Type            | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `REG_SZ`        | String value.                                                        |
| `DWORD`         | 32-bit integer.                                                      |
| `QWORD`         | 64-bit integer.                                                      |
| `REG_BINARY`    | Binary data.                                                         |
| `REG_MULTI_SZ`  | Multi-string value.                                                  |
| `REG_EXPAND_SZ` | Expandable string with environment variables.                        |
| `complex`       | Indicates a container key with multiple sub-values (e.g., Services). |

---

## 7. Categories (category Field)

Categories provide organization for registry entries.
All entries must reference one of the valid categories listed in categories.json.

Example:
```json
{
  "Security": "Keys that affect Windows security, permissions, and access control.",
  "Startup": "Programs and services that start with Windows."
}
```

---

## 8. Versioning

The file version.json tracks the current public version of the dictionary.

Example:
```json
{
  "version": "0.1"
}
```

Applications or scripts using this repository can periodically check this version number to detect updates.

---

## 9. Contribution Guidelines (summary)

- Each new registry key entry must include description, type, and category.
- If applicable, include a values object mapping integer or string data to readable descriptions.
- Avoid including undocumented or potentially unsafe keys without clear explanation.
- Use double backslashes (\\) in registry paths for JSON validity.
- Keep all keys alphabetically ordered for easier maintenance.

---

## 10. Future Schema Extensions

- Multi-language support (description_en, description_ms, etc.)
- Source reference field (source: "Microsoft Docs", "Internal Test", etc.)
- Tag system for filtering (tags: ["network", "policy", "deprecated"])
- Validation schema file for automated JSON linting.

---

## 11. Validation

Before committing changes:

1. Validate JSON syntax using any JSON linter.
2. Confirm all category names exist in categories.json.
3. Ensure descriptions are concise and neutral.
4. Avoid including user-specific registry keys or transient entries.


---


