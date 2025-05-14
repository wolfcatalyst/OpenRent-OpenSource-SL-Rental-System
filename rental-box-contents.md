# OpenRent Rental Box – Required Contents

This file lists the required components that must be inside the in-world rental object for the system to function correctly.

---

## ✅ REQUIRED SCRIPTS
These must be inside the rental box prim:
- `Rental Script.lsl` *(main controller script)*
- `mesh script.lsl` *(controls hovertext or mesh-based display)*

Any other scripts are optional or provided as examples for API usage.

---

## 📄 REQUIRED NOTECARDS
- `Rental Info.txt` – Configures rental parameters (time, price, etc.)
- `Welcome Notecard.txt` – Given to tenants upon successful rental
- `_Settings.txt` – Advanced config overrides
- `OpenRentMeshKitInformation.txt` – (Recommended) Setup info and developer guidance

---

## 🔧 OPTIONAL FILES
- Any `.obj` or `.blend` files for mesh-based versions (provided or custom made)
- Additional example notecards, API documentation, or mesh helpers

---

## 🖼️ TEXTURES / VISUALS
Include **all provided textures** for full functionality, except:
- `BaseEdgeDetectionTemplate.tga`
- `CalendarEdgeDetectionTemplate.tga`

You may use those as templates to create your own textures.

Note: Some other textures may be unnecessary, but for simplicity, add all provided textures initially to ensure full functionality.

---

## 💬 IMPORTANT NOTES
- All scripts must be set to **Running = true** unless specified otherwise.
- All files uploaded or copy-pasted into Second Life must retain **exact file names**, including capitalization. Scripts depend on accurate naming for lookups.

---

For support or the latest version, visit:  
[GitHub Repo](https://github.com/wolfcatalyst/OpenRent-OpenSource-SL-Rental-System)

Support is only available for official purchases made from [Your SL Store Name] or directly from [Your SL Name].
