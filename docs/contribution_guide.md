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

## 4. Editing or Updating an Existing Entry

If an entry already exists:
1. Confirm that your changes are factual and documented.
2. Update the description, values, or category as needed.
3. Do not remove fields or keys unless they are confirmed obsolete.
4. Keep the language neutral and descriptive.

When updating large sections, include a brief note in your pull request summarizing what changed.

---

## 5. Formatting Rules

- Indentation: 2 spaces per level
- Quotation marks: Always use double quotes "
- No trailing commas in JSON objects
- Descriptions should be short, technical, and clear
- Always use valid JSON (test with a JSON linter before committing)

---

## 6. Version Control
When major additions or updates are made:
1. Increment the version number in version.json by 0.1.
   - Example: from 0.1 to 0.2
2. Commit the version change as a separate commit if possible.

Minor typo fixes or description improvements do not require a version increment.

---

## 7. Pull Request Checklist

Before submitting a pull request:
1. Validate JSON formatting.
2. Confirm that all categories exist in categories.json.
3. Ensure your addition follows the schema rules in docs/schema.md.
4. Provide a clear PR title and summary (e.g., “Add registry entry: EnableLUA under Security category”).
5. Avoid adding duplicate or redundant entries.

---

## 8. Validation Tools

Recommended ways to verify your JSON:
- Use an online JSON validator such as jsonlint.com
- Or run a local linter if available in your editor/IDE
- Ensure your editor saves files using UTF-8 without BOM

---

## 9. Quality Standards

- Each description must be factually correct and technically verified.
- Avoid speculation or undocumented Windows behavior.
- If an entry is experimental or uncertain, include a note field:
  ```json
  "note": "Behavior observed in Windows 11 build 22621; requires confirmation."
  ```
- Keep all explanations concise (under 3 sentences preferred).

---

## 10. Example of a Complete Category Entry
```json
"HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters": {
  "EnableDeadGWDetect": {
    "description": "Determines whether Windows detects and switches to an alternate gateway when the current one is unreachable.",
    "type": "DWORD",
    "values": {
      "0": "Disabled",
      "1": "Enabled"
    },
    "category": "Network"
  }
}
```

---

## 11. Communication and Review

All submissions are subject to review for accuracy and consistency.
Discussions, clarifications, and suggestions should be opened using GitHub Issues or Pull Request comments.

If unsure about a registry key or value, open an Issue before submitting a Pull Request.

---

## 12. License and Attribution

This project uses the MIT License.
All contributions are considered open-source and may be modified or redistributed under the same license.

