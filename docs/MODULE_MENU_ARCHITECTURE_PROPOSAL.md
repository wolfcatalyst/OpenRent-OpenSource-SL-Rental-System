# Module Menu Architecture Proposal
## Fixing Double Menu Issue and Eliminating Constant Listeners

### Current Problem
- Modules are setting up listeners immediately when they receive routing messages
- This causes double menus when clicking "back"
- Multiple modules listening simultaneously creates resource waste
- Complex message flow with multiple round trips

### Current Flow (Problematic)
1. User clicks "Modules" → UI shows modules menu
2. User clicks "Hello World" → UI sends `Module:Route^Hello World^ShowMenu` to ALL modules
3. Hello World module receives message and requests user role: `Core:Action^CheckUserRole^userID`
4. Core responds with `Core:UserRole^role^userID`
5. Hello World shows menu and sets up listener
6. **Problem**: Other modules might also be processing or setting up listeners

### Proposed New Flow (Clean)
1. User clicks "Modules" → UI determines user role immediately
2. UI shows modules menu with role already known
3. User clicks "Hello World" → UI sends `Module:Activate^Hello World^owner^userID` to ALL modules
4. Only Hello World module responds (name match) and shows appropriate menu immediately
5. Module sets up listener ONLY when actually showing its menu

## Implementation Changes

### UI Manager Changes
```lsl
// In processMenuSelection function, when handling modules menu:
else if (lastMenuContext == "modules") {
    if (message == "<< Back") {
        // Return to appropriate owner menu based on current state
        llMessageLinked(LINK_SET, 0, "Core:Touch^" + (string)id, NULL_KEY);
    } else if (message == "<< Previous" || message == "Next >>") {
        // Handle pagination (existing code)
        // ...
    } else {
        // NEW: Get user role first, then activate module
        // Store the selected module and user for role response
        selectedModule = message;
        selectedUser = id;
        llMessageLinked(LINK_SET, 0, "Core:Action^CheckUserRole^" + (string)id, NULL_KEY);
    }
}

// Add new context handling for module activation:
else if (command == "Core:UserRole" && selectedModule != "") {
    string role = llList2String(parts, 1);
    key userID = (key)llList2String(parts, 2);
    
    // Send single activation message to modules
    llMessageLinked(LINK_SET, 0, "Module:Activate^" + selectedModule + "^" + role + "^" + (string)userID, NULL_KEY);
    
    // Clear selection
    selectedModule = "";
    selectedUser = NULL_KEY;
    cleanupListeners();
}
```

### Module Changes (Example: Hello World)
```lsl
// Remove the Core:UserRole handling entirely
// Replace Module:Route handling with:

else if (command == "Module:Activate" && llList2String(parts, 1) == MODULE_NAME) {
    string role = llList2String(parts, 2);
    key userID = (key)llList2String(parts, 3);
    
    // Show appropriate menu immediately based on role
    if (role == "owner") {
        showOwnerMenu(userID);
    } else if (role == "renter") {
        showRenterMenu(userID);
    } else {
        // For visitors or other users
        llInstantMessage(userID, "Hello World Module: This is a demo module. Only the owner and renter can access the full features, but hello to you too!");
        sayHello(userID);
    }
}
```

### Prim Counter Changes
```lsl
// Replace existing Module:Route and Core:UserRole handling with:

else if (command == "Module:Activate" && llList2String(parts, 1) == MODULE_NAME) {
    string role = llList2String(parts, 2);
    key userID = (key)llList2String(parts, 3);
    
    // Check access permissions
    if (accessMode == "disabled") {
        llInstantMessage(userID, "Prim Counter: Module is disabled.");
        return;
    }
    else if (accessMode == "owner_only" && role != "owner") {
        llInstantMessage(userID, "Prim Counter: Owner access only.");
        return;
    }
    else if (accessMode == "renter_only" && role != "renter") {
        llInstantMessage(userID, "Prim Counter: Renter access only.");
        return;
    }
    
    // Show appropriate menu
    if (role == "owner" && (accessMode == "available" || accessMode == "owner_only")) {
        showOwnerMenu(userID);
    }
    else if (role == "renter" && (accessMode == "available" || accessMode == "renter_only")) {
        showRenterMenu(userID);
    }
    else {
        llInstantMessage(userID, "Prim Counter: Access not available for your role.");
    }
}
```

## Benefits of This Approach

1. **Eliminates Double Menus**: Single message flow with no race conditions
2. **No Constant Listeners**: Modules only listen when actively showing menus
3. **More Efficient**: Fewer message exchanges (3 steps vs 4+ steps)
4. **Cleaner Code**: Simpler logic flow, easier to debug
5. **Better Resource Usage**: Only one module listening at a time
6. **Scalable**: Works with any number of modules without performance impact

## Variables to Add to UI Manager
```lsl
// Add these variables to UI Manager:
string selectedModule = "";
key selectedUser = NULL_KEY;
```

## Files That Need Changes
1. **Scripts/main/UI Manager.lsl** - Main logic changes
2. **Scripts/modules/Hello World.lsl** - Example implementation
3. **Scripts/modules/Prim Counter.lsl** - Production module implementation
4. **Any other existing modules** - Apply same pattern

## Testing Plan
1. Test single module (Hello World) activation
2. Test multiple modules don't interfere
3. Test "back" button doesn't cause double menus
4. Test different user roles (owner/renter/visitor)
5. Test with many modules to ensure no performance issues

## Migration Notes
- This is a breaking change for existing modules
- All modules need to be updated to use new `Module:Activate` message
- Old `Module:Route` and `Core:UserRole` handling should be removed
- The change is backwards compatible at the UI level (users won't notice difference)

---
*Created: [Current Date]*
*Status: Proposal - Ready for Implementation* 