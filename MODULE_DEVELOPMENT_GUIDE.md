# OpenRent v3.1 - Module Development Guide

## Overview

The OpenRent module system allows developers to extend rental box functionality through standardized plugins. Modules communicate with the core system via secure channel-based messaging and can provide additional features like prim monitoring, security integration, web services, and more.

## Module Architecture

### Core Components
- **Module Manager**: Handles module registration, channel assignment, and communication routing
- **Channel System**: Secure inter-module communication using randomized channels
- **Registration Protocol**: Automatic module discovery and capability reporting
- **Lifecycle Management**: Proper initialization, state changes, and cleanup

### Communication Flow
1. Module starts and requests channel assignment from Module Manager
2. Module Manager assigns unique channel and registers module capabilities
3. Module receives rental state updates and responds to commands
4. Module can send notifications and requests back to core system

## Getting Started

### Use the Hello World Template
The `Hello World.lsl` module serves as the perfect starting template:

```lsl
// Basic module structure
string MODULE_NAME = "Your Module Name";
list MODULE_CAPABILITIES = ["YourCapability"];

integer moduleChannel = 0; // 0 = auto-assign
integer assignedChannel = 0;
integer listenHandle = 0;

// Registration with Module Manager
assignModuleChannel() {
    if (moduleChannel == 0) {
        assignedChannel = 1000 + (integer)(llFrand(2147482647.0));
    } else {
        assignedChannel = moduleChannel;
    }
    llOwnerSay("Your Module: Using channel " + (string)assignedChannel);
}
```

### Required Functions

#### Module Registration
```lsl
default {
    state_entry() {
        assignModuleChannel();
        setupListener();
        registerWithModuleManager();
    }
}
```

#### Channel Communication
```lsl
setupListener() {
    if (listenHandle != 0) llListenRemove(listenHandle);
    listenHandle = llListen(assignedChannel, "", NULL_KEY, "");
}

listen(integer channel, string name, key id, string message) {
    if (channel == assignedChannel) {
        processModuleMessage(message);
    }
}
```

## Module Capabilities

### Capability Types
Modules should declare their capabilities in the `MODULE_CAPABILITIES` list:

- `"PrimTracking"` - Prim counting and monitoring
- `"SecurityIntegration"` - Access control systems
- `"TeleportIntegration"` - Teleport system management
- `"WebServices"` - HTTP/web functionality
- `"Notifications"` - Extended notification services
- `"DataStorage"` - Additional data management
- `"CustomUI"` - User interface extensions

### Example Capability Declaration
```lsl
string MODULE_NAME = "Advanced Security Module";
list MODULE_CAPABILITIES = ["SecurityIntegration", "Notifications"];
```

## Communication Protocol

### Messages from Core System

#### State Changes
```lsl
// Format: "StateChange^newState^renterID^renterName^rentalTime"
if (command == "StateChange") {
    string newState = llList2String(parts, 1);
    key renterID = llList2Key(parts, 2);
    string renterName = llList2String(parts, 3);
    float rentalTime = llList2Float(parts, 4);
    
    handleStateChange(newState, renterID, renterName, rentalTime);
}
```

#### Rental Events
```lsl
// Format: "RentalEvent^eventType^renterID^renterName^additionalData"
if (command == "RentalEvent") {
    string eventType = llList2String(parts, 1); // "payment", "extension", "expiration"
    key renterID = llList2Key(parts, 2);
    string renterName = llList2String(parts, 3);
    // Handle rental events
}
```

#### Configuration Updates
```lsl
// Format: "ConfigUpdate^setting^value"
if (command == "ConfigUpdate") {
    string setting = llList2String(parts, 1);
    string value = llList2String(parts, 2);
    updateModuleConfig(setting, value);
}
```

### Messages to Core System

#### Status Reports
```lsl
// Send status update to Module Manager
llSay(0, "ModuleStatus^" + MODULE_NAME + "^active^" + additionalInfo);
```

#### Notifications
```lsl
// Request owner notification
llSay(0, "NotifyOwner^" + MODULE_NAME + "^" + message);
```

#### Configuration Requests
```lsl
// Request configuration value
llSay(0, "RequestConfig^" + MODULE_NAME + "^" + settingName);
```

## Module States

### Core Rental States
Modules receive these state changes:
- `"initialize"` - System starting up
- `"idle"` - Available for rent
- `"rented"` - Currently rented
- `"grace"` - In grace period
- `"locked"` - Locked by owner
- `"unavailable"` - Marked unavailable

### Module State Handling
```lsl
handleStateChange(string newState, key renterID, string renterName, float rentalTime) {
    if (newState == "rented") {
        // Grant access, start monitoring, etc.
        grantAccess(renterID, renterName);
    } else if (newState == "idle") {
        // Revoke access, cleanup, etc.
        revokeAccess(renterID, "lease_ended");
    }
    // Update module state
    currentState = newState;
}
```

## Configuration System

### Module-Specific Settings
Modules can have their own configuration notecards:

```lsl
string configNotecardName = "_YourModuleSettings";

loadModuleSettings() {
    // Read module-specific configuration
    configKey = llGetNotecardLine(configNotecardName, 0);
}
```

### Settings Format
```
# Your Module Configuration
ACCESS_MODE: owner_only
NOTIFICATIONS: enabled
CUSTOM_SETTING: value
```

## Best Practices

### Memory Management
```lsl
// Clean up listeners on state changes
cleanup() {
    if (listenHandle != 0) {
        llListenRemove(listenHandle);
        listenHandle = 0;
    }
}
```

### Error Handling
```lsl
processModuleMessage(string message) {
    list parts = llParseString2List(message, ["^"], []);
    if (llGetListLength(parts) < 2) {
        llOwnerSay("Module Error: Invalid message format");
        return;
    }
    
    string command = llList2String(parts, 0);
    // Process command with validation
}
```

### Performance Optimization
```lsl
// Use efficient data structures
list activeRenters = [];
integer maxRenters = 100;

// Limit resource usage
if (llGetListLength(activeRenters) > maxRenters) {
    // Cleanup old entries
    activeRenters = llList2List(activeRenters, -50, -1);
}
```

## Advanced Features

### Timer Management
```lsl
float moduleTimer = 300.0; // 5 minutes

default {
    timer() {
        // Periodic module tasks
        performPeriodicTasks();
    }
}
```

### HTTP Integration
```lsl
key httpRequest;

sendWebNotification(string message) {
    httpRequest = llHTTPRequest("https://your-api.com/notify", 
        [HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/json"], 
        "{\"message\":\"" + message + "\"}");
}

http_response(key request_id, integer status, list metadata, string body) {
    if (request_id == httpRequest) {
        // Handle web response
    }
}
```

### Data Persistence
```lsl
saveModuleData() {
    string data = llDumpList2String([setting1, setting2, setting3], "^");
    llSetObjectDesc("MODULE:" + MODULE_NAME + ":" + data);
}

loadModuleData() {
    string desc = llGetObjectDesc();
    if (llGetSubString(desc, 0, 6) == "MODULE:") {
        // Parse and restore module data
    }
}
```

## Testing and Debugging

### Debug Messages
```lsl
integer DEBUG = TRUE;

debug(string message) {
    if (DEBUG) {
        llOwnerSay("DEBUG [" + MODULE_NAME + "]: " + message);
    }
}
```

### Module Validation
```lsl
validateModule() {
    if (MODULE_NAME == "") {
        llOwnerSay("ERROR: MODULE_NAME not set");
        return FALSE;
    }
    if (llGetListLength(MODULE_CAPABILITIES) == 0) {
        llOwnerSay("ERROR: No capabilities declared");
        return FALSE;
    }
    return TRUE;
}
```

## Example Modules

### Simple Notification Module
```lsl
string MODULE_NAME = "Notification Enhancer";
list MODULE_CAPABILITIES = ["Notifications"];

processModuleMessage(string message) {
    list parts = llParseString2List(message, ["^"], []);
    string command = llList2String(parts, 0);
    
    if (command == "StateChange") {
        string newState = llList2String(parts, 1);
        string renterName = llList2String(parts, 3);
        
        if (newState == "rented") {
            llSay(0, "🎉 Welcome " + renterName + " to your new rental space!");
        }
    }
}
```

### Web Integration Module
```lsl
string MODULE_NAME = "Web Dashboard";
list MODULE_CAPABILITIES = ["WebServices"];

handleRentalEvent(string eventType, key renterID, string renterName) {
    string url = "https://your-dashboard.com/api/rental-event";
    string data = "{\"event\":\"" + eventType + "\",\"renter\":\"" + renterName + "\"}";
    
    llHTTPRequest(url, [HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/json"], data);
}
```

## Deployment

### Module Installation
1. Add module script to rental box
2. Add module configuration notecard (if needed)
3. Reset rental box to initialize module
4. Verify module registration in chat

### Module Updates
1. Replace module script with new version
2. Update configuration if needed
3. Reset rental box
4. Test module functionality

## Troubleshooting

### Common Issues

**Module not registering:**
- Check MODULE_NAME is set
- Verify capabilities list is not empty
- Ensure channel assignment is working

**Communication failures:**
- Verify listen channel matches assigned channel
- Check message format (use ^ as separator)
- Ensure proper cleanup of old listeners

**Performance problems:**
- Limit timer frequency
- Clean up unused data
- Optimize message processing

### Debug Tools
```lsl
// Module status report
reportModuleStatus() {
    llOwnerSay("=== " + MODULE_NAME + " Status ===");
    llOwnerSay("Channel: " + (string)assignedChannel);
    llOwnerSay("State: " + currentState);
    llOwnerSay("Listen Handle: " + (string)listenHandle);
}
```

## Support and Resources

- **Template Module**: Use `Hello World.lsl` as starting point
- **Reference Implementation**: Study `Prim Counter.lsl` for advanced features
- **Core System**: Review Module Manager for communication protocols
- **Community**: Share modules and get help via GitHub

---

**Ready to extend OpenRent with your custom module? Start with the Hello World template and build something amazing!** 