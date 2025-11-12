# Windows Registry Dictionary

The **Windows Registry Dictionary** is an open JSON-based reference that translates raw Windows Registry keys and values into human-readable names, descriptions, and categories.

Its goal is to make the Windows Registry easier to understand — for both developers and system administrators — by mapping technical keys to meaningful explanations.

---

## 1. Purpose

Windows stores thousands of configuration settings in the Registry, but most are cryptic and undocumented.  
This project provides a public, structured library that explains what each registry key does, what values mean, and which Windows features they control.

Example use cases:
- Creating system scanners or analyzers that explain Registry settings.
- Building friendly interfaces or configuration tools for Windows internals.
- Learning and documenting undocumented Windows behaviors.

---

## 2. Repository Structure

| Path | Description |
|------|--------------|
| `data/registry_dictionary.json` | Main data file containing registry keys, value definitions, and descriptions. |
| `data/categories.json` | Category definitions (e.g., Security, Network, Startup). |
| `data/examples/` | Example output and usage samples. |
| `docs/schema.md` | Defines the JSON structure and formatting rules. |
| `docs/contribution_guide.md` | Contributor instructions and review requirements. |
| `version.json` | Tracks the current dictionary version. |
| `LICENSE` | License file (MIT). |

---

## 3. Example Entry

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

## 4. Categories

Example classification of registry areas:

| Category       | Description                                                     |
| -------------- | --------------------------------------------------------------- |
| Security       | Access control, permissions, and UAC-related settings.          |
| Startup        | Programs and services that run automatically at boot or login.  |
| Network        | Network configuration, TCP/IP parameters, and host information. |
| User Interface | Visual and personalization-related settings.                    |
| System Core    | System services, drivers, and internal Windows components.      |
| Updates        | Windows Update and patching configuration.                      |
| Performance    | Timing and optimization-related settings.                       |

---

## 5. How It Works

The dictionary is stored as a single structured JSON file.
Applications or scripts can:
1. Parse the registry using PowerShell, C#, or another language.
2. Compare registry paths and keys against this dictionary.
3. Translate technical registry entries into friendly, human-readable text.

This makes it suitable for:
- System configuration tools
- Registry scanners or viewers
- Educational or documentation purposes

---

## 6. Contributing

Contributions are welcome.

Before adding or editing entries:
1. Review docs/schema.md for the correct JSON structure.
2. Read docs/contribution_guide.md for contribution rules.
3. Validate your JSON using a linter before committing.
4. Submit a Pull Request with a clear title and description.

All entries should be factual, verified, and consistent in formatting.

---

## 7. Versioning

The current dictionary version is defined in version.json.

Example:
```json
{
  "version": "0.1"
}
```

The version number increases when new registry keys or categories are added.

---

## 8. License

This project is released under the MIT License.
You are free to use, modify, and distribute it, provided that the copyright notice is retained.

---

## 9. Maintainer

WL Chan
Creator and maintainer of the Windows Registry Dictionary project.
GitHub: @WL-Chan

---

## 10. Roadmap

Planned future improvements:
- Expand coverage of common Windows registry paths.
- Add pattern matching for wildcard paths (*) and dynamic subkeys.
- Introduce versioned releases of the dictionary (v0.2, v0.3, etc.).
- Provide example parsers in PowerShell and C#.
- Optionally include language localization support (English, Chinese, etc.).

---

## 11. Project Goal

To make the Windows Registry understandable and accessible —
turning obscure registry data into readable, structured information for everyone.

---
