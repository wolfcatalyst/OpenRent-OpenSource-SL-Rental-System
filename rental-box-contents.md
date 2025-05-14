# OpenRent Rental Box – Required Contents

This file lists the required components that must be inside the in-world rental object for the system to work correctly.

---

## ✅ REQUIRED SCRIPTS
These must be inside the rental box prim:
- `Rental Script.lsl`
- `mesh script.lsl` *(used for hovertext or mesh interaction)*

Any other scripts are extras or examples for API usage.
---

## 📄 REQUIRED NOTECARDS
- `Rental Info.txt` – Configures the rental box (rental time, price, etc.)
- `Welcome Notecard.txt` – Given to the user when they rent
- `OpenRentMeshKitInformation.txt` – Developer info or setup help (recommend adding for ease of use)
- `_Settings.txt` – Advanced config overrides
---

## 🔧 OPTIONAL FILES
- `OpenRentMeshKitInformation.txt` – Developer info or setup help (recommend adding for ease of use)
- Any .obj/.blend previews for mesh-based versions

---

## 🖼️ TEXTURES / VISUALS
Add all textures except for 'BaseEdgeDetection Template.tga' and 'CalendarEdgeDetectionTemplate.tga'
You can also use the textures as templates to create your own.
Some other textures can be removed, but for ease of use on your part, just add them all for now.

---

## 💬 NOTES
- All scripts should be set to **running = true**
- Recommended: Set the object to copy/mod/no transfer for end-users
- Make sure your box links are correct if using multi-prim meshes or child objects

---

For support or the latest version, visit:
[GitHub Repo](https://github.com/wolfcatalyst/OpenRent-OpenSource-SL-Rental-System)
