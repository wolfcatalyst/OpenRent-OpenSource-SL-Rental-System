//Module Manager Script v3.1.0 - Strict Channel Communication
//Lightweight module system with pagination support for large module lists
//Strict channel-only communication (no backwards compatibility)
//Created by Wolf Starforge
//Version 3.1.0
//Date: 2025-06-26
//Open Source: See license file for more information.


// Simplified module registry (increased limit for pagination testing)
list moduleNames = [];
list moduleCapabilities = [];
list moduleChannels = []; // Track each module's communication channel
integer maxModules = 20; // Increased to test pagination

// Pagination settings
integer modulesPerPage = 9; // Leave room for navigation buttons (9 + Back + Next/Prev = 11 max)

// Functions
addModule(string name, string caps, integer channel) {
    if (llGetListLength(moduleNames) >= maxModules) {
        llOwnerSay("Module limit reached: " + name);
        return;
    }
    
    integer i;
    for (i = 0; i < llGetListLength(moduleNames); i++) {
        if (llList2String(moduleNames, i) == name) {
            moduleCapabilities = llListReplaceList(moduleCapabilities, [caps], i, i);
            moduleChannels = llListReplaceList(moduleChannels, [channel], i, i);
            llOwnerSay("Module updated: " + name + " (channel " + (string)channel + ")");
            return;
        }
    }
    
    moduleNames += [name];
    moduleCapabilities += [caps];
    moduleChannels += [channel];
    llOwnerSay("Module registered: " + name + " (" + (string)llGetListLength(moduleNames) + "/" + (string)maxModules + ") on channel " + (string)channel);
}

sendModuleRequest(string name, string action, string params, key user) {
    // Find the module's channel (strict mode - module must be registered)
    integer channel = -1; // Invalid channel indicates module not found
    integer i;
    for (i = 0; i < llGetListLength(moduleNames); i++) {
        if (llList2String(moduleNames, i) == name) {
            channel = llList2Integer(moduleChannels, i);
        }
    }
    
    // Only send request if module is registered with a valid channel (not 0 or -1)
    if (channel != 0 && channel != -1) {
        llMessageLinked(LINK_SET, channel, "Module:Route^" + name + "^" + action + "^" + params, user);
    } else {
        llOwnerSay("Module Manager: Module '" + name + "' not found or not properly registered");
        if (user != NULL_KEY) {
            llInstantMessage(user, "Module '" + name + "' is not available or not properly registered.");
        }
    }
}

default {
    state_entry() {
        llOwnerSay("Module Manager v3.1: Strict channel communication enabled. Max " + (string)maxModules + " modules, " + (string)modulesPerPage + " per page.");
    }
    
    link_message(integer sender_num, integer num, string message, key id) {
        list parts = llParseString2List(message, ["^"], []);
        string command = llList2String(parts, 0);
        
        if (command == "Module:Register") {
            if (llGetListLength(parts) >= 4) {
                string name = llList2String(parts, 1);
                string caps = llList2String(parts, 2);
                integer channel = (integer)llList2String(parts, 3);
                
                // Strict mode: only reject channel 0 (broadcast channel)
                if (channel != 0) {
                    addModule(name, caps, channel);
                } else {
                    llOwnerSay("Module Manager: Rejecting module '" + name + "' - channel 0 not allowed in strict mode");
                }
            } else {
                llOwnerSay("Module Manager: Rejecting incomplete module registration (strict mode requires channel)");
            }
        }
        else if (command == "Module:Request") {
            if (llGetListLength(parts) >= 3) {
                string name = llList2String(parts, 1);
                string action = llList2String(parts, 2);
                string params = "";
                if (llGetListLength(parts) > 3) {
                    params = llList2String(parts, 3);
                }
                sendModuleRequest(name, action, params, id);
            }
        }
        else if (command == "Module:GetList") {
            // Handle pagination
            integer page = 0;
            if (llGetListLength(parts) > 1) {
                page = (integer)llList2String(parts, 1);
            }
            
            integer totalModules = llGetListLength(moduleNames);
            integer startIndex = page * modulesPerPage;
            integer endIndex = startIndex + modulesPerPage - 1;
            
            // Build page of modules
            list pageModules = [];
            integer i;
            for (i = startIndex; i <= endIndex && i < totalModules; i++) {
                pageModules += [llList2String(moduleNames, i)];
            }
            
            string moduleList = llDumpList2String(pageModules, ",");
            integer totalPages = (totalModules - 1) / modulesPerPage + 1;
            if (totalModules == 0) totalPages = 0;
            
            // Send: Module:List^moduleList^currentPage^totalPages^totalModules
            llMessageLinked(LINK_SET, 0, "Module:List^" + moduleList + "^" + (string)page + "^" + (string)totalPages + "^" + (string)totalModules, NULL_KEY);
        }
        else if (command == "Module:Clear") {
            // Emergency clear for memory issues
            moduleNames = [];
            moduleCapabilities = [];
            moduleChannels = [];
            llOwnerSay("Module registry cleared.");
        }
        else if (command == "Module:Discover") {
            // Broadcast discovery only on registered module channels (strict mode)
            integer i;
            for (i = 0; i < llGetListLength(moduleChannels); i++) {
                integer channel = llList2Integer(moduleChannels, i);
                if (channel != 0) {
                    llMessageLinked(LINK_SET, channel, "Module:Discover", NULL_KEY);
                }
            }
            // No longer broadcast on channel 0 - strict channel mode only
        }
        // Ignore other module commands to prevent errors
    }
} 