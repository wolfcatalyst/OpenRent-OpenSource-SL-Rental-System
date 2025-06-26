# OpenRent Module Development Guide

## Overview

The OpenRent rental system uses a modular architecture that allows developers to create custom modules that integrate seamlessly with the core rental functionality. This guide explains how to create your own modules.

## Module Pagination System

**NEW in v2.0:** The module menu system now supports pagination to handle large numbers of modules gracefully.

### How Pagination Works
- **Modules per page**: 9 modules per page (leaves room for navigation buttons)
- **Automatic navigation**: "Previous" and "Next" buttons appear when needed
- **Page indicators**: Shows current page and total pages when multiple pages exist
- **Maximum modules**: Configurable limit (default: 20 modules)

### User Experience
- **Single page**: Shows modules + "Back" button (normal behavior)
- **Multiple pages**: Shows modules + navigation buttons + "Back" button
- **Page info**: "Page 1 of 3 (25 total modules)" displayed in dialog header
- **Navigation**: Users can move between pages seamlessly

### For Module Developers
The pagination system is completely transparent to module developers. Your modules will automatically be included in the paginated menu system without any code changes required.

## Module Architecture

### Core Components
- **Rental Core**: Handles payments, state management, and user roles
- **UI Manager**: Manages dialogs and user interfaces (now with pagination)
- **Module Manager**: Routes messages between modules and provides discovery (now with pagination)
- **Modules**: Individual feature scripts that extend functionality

### Communication System
Modules communicate via `llMessageLinked()` using a structured message format:
```
"Command^Parameter1^Parameter2^..."
```

## Module Registration

### Required Steps
1. **Register on startup**: Send `Module:Register` message
2. **Handle discovery**: Respond to `Module:Discover` requests
3. **Handle routing**: Process `Module:Route` messages

### Registration Message Format
```lsl
llMessageLinked(LINK_SET, 0, "Module:Register^ModuleName^Capability1,Capability2", NULL_KEY);
```

## Core Messages Your Module Can Send

### User Role Detection
```lsl
// Request user role (owner/renter/other)
llMessageLinked(LINK_SET, 0, "Core:Action^CheckUserRole^" + (string)userID, NULL_KEY);

// Response will be:
// "Core:UserRole^role^userID"
```

### UI Integration
```lsl
// Return to modules menu
llMessageLinked(LINK_SET, 0, "UI:ShowModulesMenu", userID);
```

### Mesh Control (if applicable)
```lsl
// Change mesh texture/state
llMessageLinked(LINK_SET, 0, "Mesh:CustomState", NULL_KEY);
```

## Core Messages Your Module Should Handle

### Module Discovery
```lsl
if (command == "Module:Discover") {
    // Re-register your module
    llMessageLinked(LINK_SET, 0, "Module:Register^" + MODULE_NAME + "^" + capabilities, NULL_KEY);
}
```

### Module Routing
```lsl
if (command == "Module:Route" && llList2String(parts, 1) == MODULE_NAME) {
    string action = llList2String(parts, 2);
    if (action == "ShowMenu") {
        // User selected your module from the modules menu
        // Check user role and show appropriate interface
    }
}
```

### User Role Response
```lsl
if (command == "Core:UserRole") {
    string role = llList2String(parts, 1);      // "owner", "renter", or "other"
    key userID = (key)llList2String(parts, 2);  // User who triggered the request
    
    // Show role-appropriate interface
    if (role == "owner") {
        showOwnerMenu(userID);
    } else if (role == "renter") {
        showRenterMenu(userID);
    }
}
```

## Module Template

Here's a basic module template to get you started:

```lsl
// Your Module Name v1.0
// Description of what your module does

// Module information
string MODULE_NAME = "Your Module";
list MODULE_CAPABILITIES = ["YourCapability"];

// Your module variables here
integer listenHandle = 0;

// Your module functions here
showOwnerMenu(key userID) {
    list options = ["Option 1", "Option 2", "<< Back"];
    llDialog(userID, "Your Module - Owner Options:", options, -8675309);
    llListenRemove(listenHandle);
    listenHandle = llListen(-8675309, "", userID, "");
    llSetTimerEvent(30.0);
}

showRenterMenu(key userID) {
    list options = ["Renter Option", "<< Back"];
    llDialog(userID, "Your Module - Renter Options:", options, -8675309);
    llListenRemove(listenHandle);
    listenHandle = llListen(-8675309, "", userID, "");
    llSetTimerEvent(30.0);
}

default {
    state_entry() {
        // Register this module
        llMessageLinked(LINK_SET, 0, "Module:Register^" + MODULE_NAME + "^" + llDumpList2String(MODULE_CAPABILITIES, ","), NULL_KEY);
        llOwnerSay(MODULE_NAME + " v1.0: Ready!");
    }
    
    link_message(integer sender_num, integer num, string message, key id) {
        list parts = llParseString2List(message, ["^"], []);
        string command = llList2String(parts, 0);
        
        if (command == "Module:Discover") {
            // Re-register when discovery is requested
            llMessageLinked(LINK_SET, 0, "Module:Register^" + MODULE_NAME + "^" + llDumpList2String(MODULE_CAPABILITIES, ","), NULL_KEY);
        }
        else if (command == "Module:Route" && llList2String(parts, 1) == MODULE_NAME) {
            string action = llList2String(parts, 2);
            
            if (action == "ShowMenu") {
                // Check user role
                llMessageLinked(LINK_SET, 0, "Core:Action^CheckUserRole^" + (string)id, NULL_KEY);
            }
        }
        else if (command == "Core:UserRole") {
            string role = llList2String(parts, 1);
            key userID = (key)llList2String(parts, 2);
            
            if (role == "owner") {
                showOwnerMenu(userID);
            } else if (role == "renter") {
                showRenterMenu(userID);
            } else {
                llInstantMessage(userID, MODULE_NAME + ": Access restricted to owner and renter.");
            }
        }
    }
    
    listen(integer channel, string name, key id, string message) {
        if (channel == -8675309) {
            llListenRemove(listenHandle);
            listenHandle = 0;
            llSetTimerEvent(0);
            
            if (message == "Option 1") {
                // Handle option 1
                llInstantMessage(id, "You selected Option 1");
            }
            else if (message == "Option 2") {
                // Handle option 2
                llInstantMessage(id, "You selected Option 2");
            }
            else if (message == "Renter Option") {
                // Handle renter option
                llInstantMessage(id, "Renter option selected");
            }
            else if (message == "<< Back") {
                llMessageLinked(LINK_SET, 0, "UI:ShowModulesMenu", id);
            }
        }
    }
    
    timer() {
        // Cleanup expired listener
        if (listenHandle != 0) {
            llListenRemove(listenHandle);
            listenHandle = 0;
            llSetTimerEvent(0);
        }
    }
}
```

## Best Practices

### Memory Management
- Use `llListenRemove()` to clean up listeners
- Set timers to clean up expired dialogs
- Avoid large string operations in loops

### User Experience
- Always provide a "<< Back" option to return to modules menu
- Use clear, descriptive dialog text
- Provide appropriate access control (owner/renter/other)

### Error Handling
- Check for valid user roles before showing menus
- Handle edge cases gracefully
- Provide informative error messages

### Configuration
- Use notecards for configurable settings
- Implement `changed(CHANGED_INVENTORY)` to reload settings
- Provide sensible defaults if config is missing

## Advanced Features

### Notecard Configuration
```lsl
// Load settings from notecard
key configKey = NULL_KEY;
integer configLine = 0;

loadSettings() {
    if (llGetInventoryType("_YourModuleSettings") == INVENTORY_NOTECARD) {
        configKey = llGetNotecardLine("_YourModuleSettings", configLine);
    }
}

dataserver(key query_id, string data) {
    if (query_id == configKey) {
        if (data != EOF) {
            // Process configuration line
            processConfigLine(data);
            configLine++;
            configKey = llGetNotecardLine("_YourModuleSettings", configLine);
        } else {
            // Configuration loaded
            llOwnerSay("Settings loaded");
        }
    }
}
```

### Timer-based Operations
```lsl
// For modules that need periodic operations
timer() {
    // Your periodic code here
    
    // Don't forget to handle dialog cleanup too
    if (listenHandle != 0) {
        llListenRemove(listenHandle);
        listenHandle = 0;
    }
}
```

## Installation

1. **Create your module script** using the template above
2. **Add to rental box** - Drop the script into the rental box prim
3. **Test functionality** - The module should auto-register and appear in the modules menu
4. **Add configuration** - Create any needed notecard settings

## Examples

See the included modules for examples:
- **Prim Counter**: User interface, role-based access, notecard configuration
- **Hello World**: Basic module structure and messaging
- **Security Integration**: Advanced integration with external systems

## Troubleshooting

### Module Not Appearing
- Check that `Module:Register` is sent in `state_entry()`
- Verify module name doesn't conflict with existing modules
- Ensure script is in the same linkset as the rental core

### Permission Issues
- Make sure you're handling `Core:UserRole` responses correctly
- Check that user role detection is working properly

### Dialog Issues
- Always clean up listeners with `llListenRemove()`
- Set appropriate timeouts for dialogs
- Handle the "<< Back" option to return to modules menu

## Support

For additional help with module development, consult the existing modules in the `/Scripts/modules/` directory or refer to the main system documentation. 