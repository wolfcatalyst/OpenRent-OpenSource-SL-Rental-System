//Prim Counter Module v3.2 - Strict Channel Communication
//Configurable Access and Reports with Aggressive Mode - Strict channel-only communication

// Module information
string MODULE_NAME = "Prim Counter";
list MODULE_CAPABILITIES = ["PrimTracking"];

// Configuration
string configNotecardName = "_PrimCounterSettings";

// Module communication channel (configurable)
integer moduleChannel = 0; // 0 = auto-assign random channel
integer assignedChannel = 0; // The actual channel we're using

// Settings from notecard
string accessMode = "available";
string ownerReportLevel = "detailed";
string renterReportLevel = "parcel";
string displayMethod = "im";
string quickAccess = "yes";
string updateNotifications = "yes";
string aggressiveMode = "disabled";
integer aggressiveThreshold = 0;
string aggressiveTexture = "overprims_mesh";
string aggressiveMessage = "PRIM LIMIT EXCEEDED";
integer aggressiveCheckInterval = 86400; // 24 hours default
string notifyOwner = "yes";
string notifyRenter = "yes";
string setTexture = "yes";

// Runtime variables
integer listenHandle = 0;
key configKey = NULL_KEY;
integer configLine = 0;
integer settingsLoaded = FALSE;
integer lastPrimCount = 0;
integer aggressiveActive = FALSE;
key currentRenterID = NULL_KEY;
string currentState = "idle";
integer systemPrimCount = 0; // Prim count from main rental system

// Mesh face constants (same as mesh script)
integer SIGN_FRONT = 2;
integer SIGN_BACK = 3;
list floatingSignFaces = [2, 3]; // SIGN_FRONT, SIGN_BACK
float meshTransparency = 0.8; // Default transparency level
float meshGlow = 0.1; // Default glow level

// Module channel management
assignModuleChannel() {
    if (moduleChannel == 0) {
        // Generate random channel between 1000 and 2147483647 (max positive integer)
        assignedChannel = 1000 + (integer)(llFrand(2147482647.0));
    } else {
        assignedChannel = moduleChannel;
    }
    
    if (updateNotifications == "yes") {
        llOwnerSay("Prim Counter: Using module channel " + (string)assignedChannel);
    }
}

// Configuration loading
loadSettings() {
    settingsLoaded = FALSE;
    configLine = 0;
    
    integer found = FALSE;
    integer x;
    for (x = 0; x < llGetInventoryNumber(INVENTORY_NOTECARD) && !found; x++) {
        if (llGetInventoryName(INVENTORY_NOTECARD, x) == configNotecardName) {
            found = TRUE;
        }
    }
    
    if (found) {
        llOwnerSay("Prim Counter: Reading settings...");
        configKey = llGetNotecardLine(configNotecardName, configLine);
    } else {
        // Use defaults if no config found
        settingsLoaded = TRUE;
        assignModuleChannel();
        if (updateNotifications == "yes") {
            llOwnerSay("Prim Counter: Using default settings (no config notecard found)");
        }
    }
}

processConfigLine(string line) {
    line = llStringTrim(line, STRING_TRIM);
    if (line == "" || llGetSubString(line, 0, 0) == "#") return;
    
    list parts = llParseString2List(line, [":"], []);
    if (llGetListLength(parts) != 2) return;
    
    string setting = llStringTrim(llList2String(parts, 0), STRING_TRIM);
    string value = llStringTrim(llList2String(parts, 1), STRING_TRIM);
    
    if (setting == "ACCESS_MODE") accessMode = value;
    else if (setting == "OWNER_REPORT_LEVEL") ownerReportLevel = value;
    else if (setting == "RENTER_REPORT_LEVEL") renterReportLevel = value;
    else if (setting == "DISPLAY_METHOD") displayMethod = value;
    else if (setting == "QUICK_ACCESS") quickAccess = value;
    else if (setting == "UPDATE_NOTIFICATIONS") updateNotifications = value;
    else if (setting == "AGGRESSIVE_MODE") aggressiveMode = value;
    else if (setting == "AGGRESSIVE_THRESHOLD") aggressiveThreshold = (integer)value;
    else if (setting == "AGGRESSIVE_TEXTURE") aggressiveTexture = value;
    else if (setting == "AGGRESSIVE_MESSAGE") aggressiveMessage = value;
    else if (setting == "AGGRESSIVE_CHECK_INTERVAL") aggressiveCheckInterval = (integer)value;
    else if (setting == "NOTIFY_OWNER") notifyOwner = value;
    else if (setting == "NOTIFY_RENTER") notifyRenter = value;
    else if (setting == "SET_TEXTURE") setTexture = value;
    else if (setting == "MODULE_CHANNEL") moduleChannel = (integer)value;
}

// Get basic parcel prim counts
list getParcelPrimInfo() {
    vector pos = llGetPos();
    integer totalPrims = llGetParcelPrimCount(pos, PARCEL_COUNT_TOTAL, FALSE);
    integer ownerPrims = llGetParcelPrimCount(pos, PARCEL_COUNT_OWNER, FALSE);
    integer groupPrims = llGetParcelPrimCount(pos, PARCEL_COUNT_GROUP, FALSE);
    integer otherPrims = llGetParcelPrimCount(pos, PARCEL_COUNT_OTHER, FALSE);
    integer selectedPrims = llGetParcelPrimCount(pos, PARCEL_COUNT_SELECTED, FALSE);
    integer tempPrims = llGetParcelPrimCount(pos, PARCEL_COUNT_TEMP, FALSE);
    
    return [totalPrims, ownerPrims, groupPrims, otherPrims, selectedPrims, tempPrims];
}

// Get specific user's prim count
integer getUserPrimCount(key userID) {
    vector pos = llGetPos();
    list primOwners = llGetParcelPrimOwners(pos);
    
    integer i;
    for (i = 0; i < llGetListLength(primOwners); i += 2) {
        key owner = llList2Key(primOwners, i);
        if (owner == userID) {
            return llList2Integer(primOwners, i + 1);
        }
    }
    return 0;
}

// Texture application functions (same as mesh script)
applyTexture(list faces, string texture) {
    integer i;
    for (i = 0; i < llGetListLength(faces); i++) {
        integer face = llList2Integer(faces, i);
        llSetTexture(texture, face);
    }
}

applyAlpha(list faces, float transparency) {
    integer i;
    for (i = 0; i < llGetListLength(faces); i++) {
        integer face = llList2Integer(faces, i);
        llSetAlpha(transparency, face);
    }
}

applyGlow(list faces, float glow) {
    integer i;
    for (i = 0; i < llGetListLength(faces); i++) {
        integer face = llList2Integer(faces, i);
        llSetPrimitiveParams([
            PRIM_GLOW, face, glow
        ]);
    }
}

// Aggressive mode functions
checkAggressiveMode() {
    // Only check aggressive mode when rented
    if (aggressiveMode != "enabled" || currentState != "rented") {
        return;
    }
    
    list primInfo = getParcelPrimInfo();
    integer totalPrims = llList2Integer(primInfo, 0);
    
    // Use system prim count if aggressive threshold is 0
    integer effectiveThreshold = aggressiveThreshold;
    if (effectiveThreshold == 0) effectiveThreshold = systemPrimCount;
    
    if (totalPrims > effectiveThreshold && !aggressiveActive) {
        // Activate aggressive mode
        aggressiveActive = TRUE;
        
        // Set texture if enabled - apply directly
        if (setTexture == "yes") {
            applyTexture(floatingSignFaces, aggressiveTexture);
            applyAlpha(floatingSignFaces, meshTransparency);
            applyGlow(floatingSignFaces, meshGlow);
        }
        
        // Notify owner if enabled
        if (notifyOwner == "yes") {
            llInstantMessage(llGetOwner(), "Prim Limit Notice: " + (string)totalPrims + " prims exceed limit of " + (string)effectiveThreshold + ". Check in 24 hours if not resolved.");
        }
        
        // Notify renter if enabled and we have a current renter
        if (notifyRenter == "yes" && currentRenterID != NULL_KEY) {
            llInstantMessage(currentRenterID, "Prim Limit Notice: Your parcel has " + (string)totalPrims + " prims, exceeding the limit of " + (string)effectiveThreshold + ". Please reduce your prim usage.");
        }
        
        // Optional: Subtle public message (less aggressive)
        if (aggressiveMessage != "") {
            llSay(0, "Prim usage notice: " + (string)(totalPrims - effectiveThreshold) + " prims over limit");
        }
    } else if (totalPrims <= effectiveThreshold && aggressiveActive) {
        // Deactivate aggressive mode
        aggressiveActive = FALSE;
        
        // Reset texture if enabled - make aggressive texture invisible
        if (setTexture == "yes") {
            applyAlpha(floatingSignFaces, 1.0);  // Make completely transparent
            applyGlow(floatingSignFaces, 0.0);   // Remove glow
        }
        
        // Notify owner if enabled
        if (notifyOwner == "yes") {
            llInstantMessage(llGetOwner(), "Prim limit restored: " + (string)totalPrims + " prims within limit of " + (string)effectiveThreshold);
        }
        
        // Notify renter if enabled and we have a current renter
        if (notifyRenter == "yes" && currentRenterID != NULL_KEY) {
            llInstantMessage(currentRenterID, "Prim limit restored: Your parcel is now within the prim limit of " + (string)effectiveThreshold + ".");
        }
    }
    
    lastPrimCount = totalPrims;
}

// Owner reports
showOwnerReport(key userID) {
    list primInfo = getParcelPrimInfo();
    integer totalPrims = llList2Integer(primInfo, 0);
    integer ownerPrims = llList2Integer(primInfo, 1);
    integer groupPrims = llList2Integer(primInfo, 2);
    integer otherPrims = llList2Integer(primInfo, 3);
    integer selectedPrims = llList2Integer(primInfo, 4);
    integer tempPrims = llList2Integer(primInfo, 5);
    
    string report = "=== PARCEL PRIM REPORT ===\n";
    report += "Total Prims: " + (string)totalPrims + "\n";
    report += "Owner Prims: " + (string)ownerPrims + "\n";
    report += "Group Prims: " + (string)groupPrims + "\n";
    report += "Other Prims: " + (string)otherPrims + "\n";
    
    if (aggressiveMode == "enabled") {
        string modeStatus = "Inactive";
        if (aggressiveActive) modeStatus = "ACTIVE";
        report += "\nAGGRESSIVE MODE: " + modeStatus + "\n";
        
        integer effectiveThreshold = aggressiveThreshold;
        if (effectiveThreshold == 0) effectiveThreshold = systemPrimCount;
        
        report += "Threshold: " + (string)effectiveThreshold + " prims";
        if (aggressiveThreshold == 0) report += " (from main system)";
        report += "\n";
        report += "State: " + currentState + " (only checks when rented)\n";
        if (aggressiveActive) {
            report += "⚠️ OVER LIMIT BY: " + (string)(totalPrims - effectiveThreshold) + " prims\n";
        }
    }
    
    if (ownerReportLevel == "full") {
        report += "Selected: " + (string)selectedPrims + "\n";
        report += "Temp Prims: " + (string)tempPrims + "\n";
    }
    
    if (ownerReportLevel == "detailed" || ownerReportLevel == "full") {
        vector pos = llGetPos();
        list primOwners = llGetParcelPrimOwners(pos);
        
        if (llGetListLength(primOwners) > 0) {
            report += "\nPER-AVATAR BREAKDOWN:\n";
            integer i;
            for (i = 0; i < llGetListLength(primOwners); i += 2) {
                key owner = llList2Key(primOwners, i);
                integer count = llList2Integer(primOwners, i + 1);
                string name = llKey2Name(owner);
                if (name == "") name = "Unknown User";
                report += name + ": " + (string)count + " prims\n";
            }
        }
    }
    
    report += "==============================";
    llInstantMessage(userID, report);
}

// Renter reports
showRenterReport(key userID) {
    integer userPrims = getUserPrimCount(userID);
    string report = "=== YOUR PRIM USAGE ===\n";
    report += "Your Prims: " + (string)userPrims + "\n";
    
    if (renterReportLevel == "parcel" || renterReportLevel == "detailed") {
        list primInfo = getParcelPrimInfo();
        integer totalPrims = llList2Integer(primInfo, 0);
        report += "Total on Parcel: " + (string)totalPrims + "\n";
        
        if (aggressiveMode == "enabled" && aggressiveActive) {
            integer effectiveThreshold = aggressiveThreshold;
            if (effectiveThreshold == 0) effectiveThreshold = systemPrimCount;
            report += "⚠️ PARCEL OVER LIMIT: " + (string)(totalPrims - effectiveThreshold) + " prims over\n";
        }
    }
    
    if (renterReportLevel == "detailed") {
        list primInfo = getParcelPrimInfo();
        integer ownerPrims = llList2Integer(primInfo, 1);
        integer groupPrims = llList2Integer(primInfo, 2);
        integer otherPrims = llList2Integer(primInfo, 3);
        report += "Owner Prims: " + (string)ownerPrims + "\n";
        report += "Group Prims: " + (string)groupPrims + "\n";
        report += "Other Users: " + (string)(otherPrims - userPrims) + "\n";
    }
    
    report += "======================";
    llInstantMessage(userID, report);
}

// Menu functions
showOwnerMenu(key userID) {
    list options = [];
    if (ownerReportLevel == "basic") options += ["Basic Report"];
    else if (ownerReportLevel == "detailed") options += ["Detailed Report"];
    else if (ownerReportLevel == "full") options += ["Full Report"];
    
    if (quickAccess == "yes") options += ["Quick Count"];
    if (aggressiveMode == "enabled") options += ["Check Limits"];
    options += ["<< Back"];
    
    llDialog(userID, "Prim Counter - Owner Options:", options, -8675309);
    llListenRemove(listenHandle);
    listenHandle = llListen(-8675309, "", userID, "");
    llSetTimerEvent(30.0);
}

showRenterMenu(key userID) {
    list options = ["My Prims"];
    if (quickAccess == "yes") options += ["Quick Count"];
    if (aggressiveMode == "enabled") options += ["Check Limits"];
    options += ["<< Back"];
    
    llDialog(userID, "Prim Counter - Your Usage:", options, -8675309);
    llListenRemove(listenHandle);
    listenHandle = llListen(-8675309, "", userID, "");
    llSetTimerEvent(30.0);
}

default {
    state_entry() {
        loadSettings();
        // Register this module - send on channel 0 so all scripts receive it
        llMessageLinked(LINK_SET, 0, "Module:Register^" + MODULE_NAME + "^" + llDumpList2String(MODULE_CAPABILITIES, ",") + "^" + (string)assignedChannel, NULL_KEY);
        llOwnerSay("Prim Counter v3.2: Strict channel communication with aggressive mode loading...");
        
        // Request current rental data when module starts
        llMessageLinked(LINK_SET, 0, "UI:RequestData", NULL_KEY);
    }
    
    dataserver(key query_id, string data) {
        if (query_id == configKey) {
            if (data != EOF) {
                processConfigLine(data);
                configLine++;
                configKey = llGetNotecardLine(configNotecardName, configLine);
            } else {
                settingsLoaded = TRUE;
                assignModuleChannel();
                if (updateNotifications == "yes") {
                    llOwnerSay("Prim Counter: Settings loaded - Mode: " + accessMode + ", Aggressive: " + aggressiveMode);
                }
                
                // Re-register with channel info now that settings are loaded
                llMessageLinked(LINK_SET, 0, "Module:Register^" + MODULE_NAME + "^" + llDumpList2String(MODULE_CAPABILITIES, ",") + "^" + (string)assignedChannel, NULL_KEY);
                
                // Start aggressive mode timer if enabled
                if (aggressiveMode == "enabled") {
                    llSetTimerEvent(aggressiveCheckInterval);
                }
                
                // Request current rental data after settings are loaded
                llMessageLinked(LINK_SET, 0, "UI:RequestData", NULL_KEY);
            }
        }
    }
    
    link_message(integer sender_num, integer num, string message, key id) {
        list parts = llParseString2List(message, ["^"], []);
        string command = llList2String(parts, 0);
        
        // Allow rental state messages on any channel (broadcast messages)
        if (command == "Mesh:Rented" || command == "Mesh:Idle" || command == "Mesh:Locked" || 
            command == "Mesh:Unavailable" || command == "Mesh:Reserved" || command == "Mesh:Grace" || 
            command == "Mesh:Initializing" || command == "Core:ChangeState" || command == "UI:UpdateData") {
            // Process rental state messages regardless of channel
        } else {
            // Only process other messages on our assigned channel (strict channel mode)
            if (num != assignedChannel) return;
        }
        
        if (!settingsLoaded) return; // Wait for settings to load
        
        if (command == "Module:Discover") {
            llMessageLinked(LINK_SET, 0, "Module:Register^" + MODULE_NAME + "^" + llDumpList2String(MODULE_CAPABILITIES, ",") + "^" + (string)assignedChannel, NULL_KEY);
        }
        else if (command == "Module:Route" && llList2String(parts, 1) == MODULE_NAME) {
            string action = llList2String(parts, 2);
            
            if (action == "ShowMenu") {
                if (accessMode == "disabled") {
                    llInstantMessage(id, "Prim Counter: Module is disabled.");
                    return;
                }
                
                // Send user role check request on our channel so only we get the response
                llMessageLinked(LINK_SET, assignedChannel, "Core:Action^CheckUserRole^" + (string)id, NULL_KEY);
            }
        }
        else if (command == "Core:UserRole") {
            string role = llList2String(parts, 1);
            key userID = (key)llList2String(parts, 2);
            
            if (accessMode == "disabled") {
                llInstantMessage(userID, "Prim Counter: Module is disabled.");
            }
            else if (accessMode == "owner_only" && role != "owner") {
                llInstantMessage(userID, "Prim Counter: Owner access only.");
            }
            else if (accessMode == "renter_only" && role != "renter") {
                llInstantMessage(userID, "Prim Counter: Renter access only.");
            }
            else if (role == "owner" && (accessMode == "available" || accessMode == "owner_only")) {
                showOwnerMenu(userID);
            }
            else if (role == "renter" && (accessMode == "available" || accessMode == "renter_only")) {
                showRenterMenu(userID);
            }
            else {
                llInstantMessage(userID, "Prim Counter: Access not available for your role.");
            }
        }
        else if (command == "UI:UpdateData") {
            // Get current renter ID and system prim count from rental data
            currentRenterID = (key)llList2String(parts, 6);
            systemPrimCount = (integer)llList2String(parts, 3);
        }
        // Handle mesh state messages for aggressive mode
        else if (command == "Mesh:Rented") {
            currentState = "rented";
            if (updateNotifications == "yes") {
                string modeStatus = "disabled";
                if (aggressiveMode == "enabled") {
                    modeStatus = "active";
                }
                llOwnerSay("Prim Counter: State changed to rented - aggressive mode " + modeStatus);
            }
            // Check aggressive mode immediately when entering rented state
            if (aggressiveMode == "enabled") {
                checkAggressiveMode();
            }
        }
        else if (command == "Mesh:Idle" || command == "Mesh:Locked" || command == "Mesh:Unavailable" || 
                 command == "Mesh:Reserved" || command == "Mesh:Grace" || command == "Mesh:Initializing") {
            // Extract state name from command
            string newState = llGetSubString(command, 5, -1); // Remove "Mesh:" prefix
            currentState = llToLower(newState);
            
            if (updateNotifications == "yes") {
                llOwnerSay("Prim Counter: State changed to " + currentState + " - aggressive mode disabled");
            }
            
            // Reset aggressive mode when leaving rented state
            if (aggressiveActive) {
                aggressiveActive = FALSE;
                // Let the mesh script handle the texture change for the new state
                // (no need to interfere since we're leaving rented state)
            }
        }
        else if (command == "Core:ChangeState") {
            // Track rental state changes (fallback)
            string newState = llList2String(parts, 1);
            currentState = newState;
            
            // Reset aggressive mode when leaving rented state
            if (newState != "rented" && aggressiveActive) {
                aggressiveActive = FALSE;
                if (updateNotifications == "yes") {
                    llOwnerSay("Prim Counter: Aggressive mode deactivated (not rented)");
                }
            }
        }
    }
    
    listen(integer channel, string name, key id, string message) {
        if (channel == -8675309) {
            llListenRemove(listenHandle);
            listenHandle = 0;
            llSetTimerEvent(0);
            
            if (message == "Basic Report" || message == "Detailed Report" || message == "Full Report") {
                showOwnerReport(id);
            }
            else if (message == "My Prims") {
                showRenterReport(id);
            }
            else if (message == "Quick Count") {
                list primInfo = getParcelPrimInfo();
                llInstantMessage(id, "Quick Count: " + (string)llList2Integer(primInfo, 0) + " total prims on parcel");
            }
            else if (message == "Check Limits") {
                if (currentState != "rented") {
                    llInstantMessage(id, "Limit Check: Only available when rented (current state: " + currentState + ")");
                } else {
                    checkAggressiveMode();
                    list primInfo = getParcelPrimInfo();
                    integer totalPrims = llList2Integer(primInfo, 0);
                    integer effectiveThreshold = aggressiveThreshold;
                    if (effectiveThreshold == 0) effectiveThreshold = systemPrimCount;
                    llInstantMessage(id, "Limit Check: " + (string)totalPrims + " / " + (string)effectiveThreshold + " prims");
                }
            }
            else if (message == "<< Back") {
                llMessageLinked(LINK_SET, 0, "UI:ShowModulesMenu", id);
            }
        }
    }
    
    timer() {
        if (listenHandle != 0) {
            llListenRemove(listenHandle);
            listenHandle = 0;
            llSetTimerEvent(0);
        } else if (aggressiveMode == "enabled") {
            // Check prim limits periodically (only when rented)
            checkAggressiveMode();
            llSetTimerEvent(aggressiveCheckInterval);
        }
    }
    
    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            // Reload settings if notecard changed
            loadSettings();
        }
    }
} 