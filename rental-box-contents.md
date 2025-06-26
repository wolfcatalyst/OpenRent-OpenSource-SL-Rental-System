# OpenRent v3.1 Rental Box – Required Contents

This file lists the required components that must be inside the in-world rental object for the system to function correctly.

---

## ✅ REQUIRED SCRIPTS
These must be inside the rental box prim:
- `Rental Core.lsl` *(main rental system controller)*
- `Module Manager.lsl` *(handles module system and communication)*
- `UI Manager.lsl` *(manages all user interface dialogs and menus)*
- `mesh script.lsl` *(controls mesh textures and visual state display)*

---

## 📦 REQUIRED MODULES
These must be placed inside the rental box:
- `Prim Counter.lsl` *(production-ready prim monitoring module)*
- `Hello World.lsl` *(example module for developers - can be removed if not needed)*

---

## 📄 REQUIRED NOTECARDS
- `Rental Info` – Information given to potential renters when they request info
- `Welcome Notecard` – Given to renters upon successful rental payment
- `_Settings` – Main configuration file for the rental system
- `_PrimCounterSettings` – Configuration file for the Prim Counter module
- `OpenRentMeshKitInformation` – (Recommended) Setup information and developer guidance

---

## 🔧 OPTIONAL FILES
- Any `.dae` mesh files for custom rental box appearances
- Additional example notecards or documentation files
- Extra module scripts (for extended functionality)
- Example scripts in the **extras** folder

---

## 🖼️ TEXTURES / VISUALS
Include **all provided textures** for full functionality, except:
- `BaseEdgeDetectionTemplate.tga` *(template for creating custom textures)*
- `CalendarEdgeDetectionTemplate.tga` *(template for creating custom textures)*

You may use the template files to create your own custom textures.

**Required texture states:**
- `for_rent_mesh.tga` - Available for rent
- `initializing_mesh.tga` - System starting up
- `locked_mesh.tga` - Locked by owner
- `overdue_mesh.tga` - Payment overdue
- `reserved_mesh.tga` - Reserved for specific renter
- `tempunavailable_mesh.tga` - Temporarily unavailable
- Various timeframe textures for rental duration display

---

## 🏗️ FOLDER STRUCTURE
```
Rental Box Contents:
├── Scripts/
│   ├── main/
│   │   ├── Rental Core.lsl
│   │   ├── Module Manager.lsl
│   │   ├── UI Manager.lsl
│   │   └── mesh script.lsl
│   ├── modules/
│   │   ├── Prim Counter.lsl
│   │   └── Hello World.lsl (optional)
│   └── extras/ (optional)
│       ├── DieScript.lsl
│       └── Face Definer.lsl
├── Notecards/
│   ├── _Settings
│   ├── _PrimCounterSettings
│   ├── Rental Info
│   ├── Welcome Notecard
│   └── OpenRentMeshKitInformation
└── Textures/
    └── (all provided texture files)
```

**Note:** Some configuration and application of textures to the mesh objects will be required.

---

## 💬 IMPORTANT NOTES
- All scripts must be set to **Running = true** unless specified otherwise
- All files uploaded to Second Life must retain **exact file names**, including capitalization
- Scripts depend on accurate naming for lookups and communication
- The modular architecture requires all core scripts to be present for proper functionality
- Module scripts communicate via the Module Manager - don't modify the communication system

---

## 🔧 SYSTEM REQUIREMENTS
- **LSL Memory**: The system is optimized for efficient memory usage
- **Script Limits**: Uses 4 main scripts + 1-2 module scripts (well within SL limits)
- **Permissions**: Requires debit permissions for payment processing
- **Land**: Works on any land where scripts can run

---

## 📋 SETUP CHECKLIST
1. ✅ All required scripts added and set to Running
2. ✅ All required notecards present with correct names
3. ✅ _Settings notecard configured with your rental parameters
4. ✅ Textures uploaded and available in rental box
5. ✅ Rental box positioned in desired location
6. ✅ Debit permissions granted when prompted
7. ✅ System reset and "Initialized" message received

---

For support or the latest version, visit:  
[GitHub Repo](https://github.com/wolfcatalyst/OpenRent-OpenSource-SL-Rental-System)

**Support Policy**: Official support is only available for purchases made directly from Wolf Catalyst in Second Life or from the SL Marketplace. GitHub downloads are provided as-is for development and learning purposes. 