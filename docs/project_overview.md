# Project Overview

The **Windows Registry Dictionary** is a structured, open-source reference that translates raw Windows Registry keys into human-readable explanations.  
It serves as a foundation for tools and developers who want to interpret registry data more clearly and consistently.

---

## 1. Project Goals

1. Provide a **machine-readable registry dictionary** that maps Windows Registry paths and values to their descriptions and functions.  
2. Improve transparency and understanding of how Windows settings work internally.  
3. Enable developers to create tools that can display registry information in a clear, non-technical format.  
4. Encourage open collaboration on Windows system documentation.

---

## 2. Core Concept

Windows uses the Registry to store configuration data for system, users, hardware, and applications.  
However, most registry entries are undocumented or use cryptic names.

This project standardizes those entries into a structured JSON dictionary containing:
- Registry paths  
- Value names and data types  
- Human-readable descriptions  
- Category classification  
- Optional enumerations for known values (0 = Disabled, 1 = Enabled, etc.)

Example excerpt from `registry_dictionary.json`:

```json
"HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System": {
  "EnableLUA": {
    "description": "Controls User Account Control (UAC) prompts. When 0, UAC is disabled; when 1, UAC is enabled.",
    "type": "DWORD",
    "values": {
      "0": "Disabled",
      "1": "Enabled"
    },
    "category": "Security"
  }
}
```

---

## 3. Repository Structure

| Path                            | Description                                                             |
| ------------------------------- | ----------------------------------------------------------------------- |
| `data/registry_dictionary.json` | Core registry data dictionary.                                          |
| `data/categories.json`          | Defines valid registry categories.                                      |
| `data/examples/`                | Example JSON files for scanners, category sets, and dictionary entries. |
| `docs/schema.md`                | Formal schema definition and structure rules.                           |
| `docs/contribution_guide.md`    | Guidelines for adding and reviewing entries.                            |
| `docs/project_overview.md`      | This document.                                                          |
| `version.json`                  | Tracks current dictionary version.                                      |
| `README.md`                     | Main project description and usage overview.                            |
| `LICENSE`                       | Licensing information (MIT).                                            |

---

## 4. Data Flow and Usage
Applications that use this dictionary typically follow this workflow:
1. Load the dictionary
   - Load registry_dictionary.json into memory or as a data structure.
2. Scan registry values
   - Retrieve real registry data using PowerShell, C#, Python, etc.
3. Match entries
   - Compare the scanned registry paths with entries in the dictionary.
   - Use wildcard patterns (*) when available.
4. Interpret results
   - Replace raw data (e.g., EnableLUA = 0) with readable output (e.g., “UAC Disabled”).
   - Display or export human-readable reports.
5. Output examples
   - See /data/examples/sample_scan_output.json for a practical reference.

---

## 5. Versioning

Version information is stored in version.json.
Example:

```json
{
  "version": "0.1"
}
```

The version number should be incremented by 0.1 for each major update or significant addition to the dictionary.

---

## 6. Contribution and Review Process

1. All new entries must follow the schema described in docs/schema.md.
2. Contributors must use the docs/contribution_guide.md for format and validation rules.
3. Pull Requests are reviewed for:
   - JSON validity
   - Descriptive accuracy
   - Consistent formatting
   - Appropriate categorization

Accepted contributions are merged into main, and the version number is updated accordingly.

---

## 7. Use Cases

| Scenario                   | Description                                                              |
| -------------------------- | ------------------------------------------------------------------------ |
| **System Auditing Tools**  | Applications that scan and explain system registry configurations.       |
| **Security Analysis**      | Identify settings that weaken or strengthen Windows security posture.    |
| **Automation Scripts**     | PowerShell or C# scripts that automate registry management.              |
| **Documentation Projects** | Provide readable explanations for undocumented Windows features.         |
| **Educational Tools**      | Help users or students learn how Windows configuration works internally. |

---

## 8. Future Roadmap

Planned improvements and expansions include:
- Adding additional registry paths for Windows 10 and 11.
- Introducing wildcard support for dynamic subkeys.
- Creating PowerShell and C# libraries for dictionary integration.
- Multi-language support (description_en, description_ms, etc.).
- API or web endpoint for querying the dictionary online.
- Versioned releases (v0.2, v0.3, etc.) with change logs.

---

## 9. Collaboration Philosophy

This project is built around openness and technical accuracy.
Contributors are encouraged to verify registry data through documentation, observation, or testing.
Each addition improves collective understanding of Windows internals.

Collaboration is welcome through:
- GitHub Pull Requests
- GitHub Issues (for unclear or undocumented keys)
- Discussions for category expansion and schema refinement

---

## 10. License

This project is released under the MIT License.
All files and data may be freely used, modified, and redistributed, provided the license notice is included.
