# Documentation Index

This directory contains all technical documentation for the **Windows Registry Dictionary** project.  
Use this index as a navigation guide for contributors, developers, and maintainers.

---

## 1. Overview

The **Windows Registry Dictionary** provides a structured, machine-readable reference for Windows Registry keys and values.  
Each registry entry is described using a standardized JSON format defined by this project.

For a complete project summary, see:  
**[Project Overview](./project_overview.md)**

---

## 2. Primary Documents

| Document | Description |
|-----------|-------------|
| **[Schema Specification](./schema.md)** | Defines the JSON structure, formatting, and required fields. |
| **[Contribution Guide](./contribution_guide.md)** | Instructions for adding, editing, and validating new registry entries. |
| **[Project Overview](./project_overview.md)** | Explains the project’s goals, data flow, and architecture. |
| **[Changelog](../CHANGELOG.md)** | Lists version history, updates, and planned improvements. |
| **[License](../LICENSE)** | Details the MIT License terms for usage and redistribution. |

---

## 3. Data Files

| File | Description |
|------|--------------|
| **[`data/registry_dictionary.json`](../data/registry_dictionary.json)** | Main registry reference file with human-readable definitions. |
| **[`data/categories.json`](../data/categories.json)** | List of recognized registry categories. |
| **[`data/examples/`](../data/examples/)** | Example data showing structure, category sets, and scan output. |
| **[`version.json`](../version.json)** | Current dictionary version for update tracking. |

---

## 4. Examples

| Example | Description |
|----------|-------------|
| [`sample_dictionary_entry.json`](../data/examples/sample_dictionary_entry.json) | Template showing a single registry entry format. |
| [`sample_scan_output.json`](../data/examples/sample_scan_output.json) | Example of registry scan results translated into human-readable form. |
| [`sample_category_set.json`](../data/examples/sample_category_set.json) | Example of category definitions used in the dictionary. |

---

## 5. Contribution Workflow

To contribute:

1. Review the [Schema Specification](./schema.md) for the correct JSON format.  
2. Read the [Contribution Guide](./contribution_guide.md) for submission rules.  
3. Add or update entries in `data/registry_dictionary.json`.  
4. Validate your changes using a JSON linter.  
5. Submit a pull request describing your changes.

Contributions are reviewed for accuracy, formatting, and category consistency.

---

## 6. Versioning

Version information is maintained in [`version.json`](../version.json).  
See [CHANGELOG](../CHANGELOG.md) for the complete release history.

---

## 7. Future Expansion

Planned documentation additions:
- Developer API usage guide (for PowerShell or C# tools).
- Validation and automation scripts.
- Category reference index (detailed breakdown of each category’s registry keys).

---

**Maintainer:** WL Chan  
**Repository:** [Windows Registry Dictionary](https://github.com/WL-Chan/windows-registry-dictionary)

End of Documentation Index
