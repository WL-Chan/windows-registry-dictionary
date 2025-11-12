# Changelog

All notable changes to this project will be documented in this file.  
This changelog follows a simple semantic versioning format using incremental decimal versions (e.g., `0.1`, `0.2`, `1.0`).

---

## [0.1] - 2025-11-12  
### Initial Public Release

**Overview**
- First release of the Windows Registry Dictionary project.
- Established the repository structure, documentation, and data format.

**Details**
- Created base directory layout:
  - `/data/registry_dictionary.json`
  - `/data/categories.json`
  - `/data/examples/`
  - `/docs/schema.md`
  - `/docs/contribution_guide.md`
  - `/docs/project_overview.md`
  - `/version.json`
  - `/README.md`
  - `/LICENSE`
- Implemented `registry_dictionary.json` with core entries:
  - `EnableLUA` (UAC control)
  - `ConsentPromptBehaviorAdmin` (UAC prompt behavior)
  - `Run` startup keys
  - `Wallpaper` and `ScreenSaveActive` for user interface
  - `WaitToKillServiceTimeout` (performance)
  - `NoAutoUpdate` (Windows Update policy)
- Added `/data/examples/` with:
  - `sample_scan_output.json`
  - `sample_dictionary_entry.json`
  - `sample_category_set.json`
- Added contributor documentation and schema specification.
- Licensed the repository under the MIT License.
- Version set to `0.1`.

---

## [Planned - 0.2]
**Goals**
- Expand dictionary coverage with more system-related keys:
  - Explorer policies
  - Task Manager preferences
  - Windows Defender and privacy settings
- Introduce optional `tags` field for additional filtering.
- Add multi-language description fields (`description_en`, `description_ms`).
- Include PowerShell and C# example scripts for dictionary usage.
- Add automatic validation script to ensure schema compliance.

---

## [Future]
**Long-Term Roadmap**
- Implement an online API endpoint for dictionary access.
- Provide release archives for each version (`registry_dictionary_v0.1.json`, etc.).
- Include additional categories such as:
  - `Privacy`
  - `Display`
  - `Audio`
- Continue refining documentation and contributor processes.

---

**Version Format Explanation**

| Version | Meaning |
|----------|----------|
| `0.x` | Early-stage development and experimental releases. |
| `1.x` | Stable format and structure finalized. |
| `2.x` | Extended functionality or language support added. |

---

End of Changelog
