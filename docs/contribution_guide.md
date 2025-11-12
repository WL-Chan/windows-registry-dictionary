# Contribution Guide

This document outlines how contributors can safely add or update entries in the Windows Registry Dictionary project.

---

## 1. Overview

The goal of this repository is to provide a structured, human-readable library of Windows Registry keys and their functions.  
Accuracy and consistency are essential. Each contribution should follow the schema and style rules defined in `docs/schema.md`.

All edits should maintain:
- Correct JSON formatting
- Verified registry paths and keys
- Clear and neutral descriptions

---

## 2. Repository Structure Reference

| Folder / File | Description |
|----------------|-------------|
| `data/registry_dictionary.json` | Main registry key dictionary. Add or update entries here. |
| `data/categories.json` | Defines valid category names used for classification. |
| `version.json` | Contains the current library version number. Increment when major updates occur. |
| `docs/schema.md` | Schema rules and format reference. |
| `docs/contribution_guide.md` | This file. |

---

## 3. Adding a New Registry Entry

1. **Locate the correct hive** (e.g., `HKEY_LOCAL_MACHINE`, `HKEY_CURRENT_USER`, etc.).
2. **Add the new entry** to `data/registry_dictionary.json` under the proper path.
3. Use the format defined in the schema document.

### Example

```json
"HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System": {
  "EnableLUA": {
    "description": "Controls User Account Control (UAC) prompts. When 0, UAC prompts are disabled; when 1, UAC is enabled.",
    "type": "DWORD",
    "values": {
      "0": "Disabled",
      "1": "Enabled"
    },
    "category": "Security"
  }
}
```
Notes:
- Use double backslashes (\\) for registry paths.
- Match category names to those defined in categories.json.
- Keep entries alphabetically sorted by registry path and key name.

---

