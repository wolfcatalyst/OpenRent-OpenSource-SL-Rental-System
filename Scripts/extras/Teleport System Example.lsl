//Teleport System Example - Integration with OpenRent Modular System
//This is an EXAMPLE script showing how your existing teleport system can integrate
//Replace this with your actual teleport system logic

// Teleport settings
integer TELEPORT_CHANNEL = -7654321; // Must match the channel in Teleport Integration module
string TELEPORT_PASSWORD = "YourTeleportPassword123"; // Set this to match your integration module
list authorizedTeleporters = []; // List of currently authorized teleporter UUIDs
list teleportDestinations = []; // List of destinations in format: [userID, landmark/position]

// Your existing teleport functions would go here
addUserToTeleport(key userID, string userName, string teleportData) {
    // Add to authorized list
    if (llListFindList(authorizedTeleporters, [userID]) == -1) {
        authorizedTeleporters += [userID];
        teleportDestinations += [userID, teleportData];
    }
    
    // Your teleport logic here - examples:
    // - Add to teleport hub access list
    // - Create teleport landmark
    // - Add to teleport HUD
    // - Register destination in teleport network
    
    llOwnerSay("Teleport System: Added " + userName + " (" + (string)userID + ") to teleport system");
    llOwnerSay("Teleport Data: " + teleportData);
    
    // Example: Send confirmation back to rental system (optional)
    llRegionSay(TELEPORT_CHANNEL, TELEPORT_PASSWORD + "|USER_ADDED|" + (string)userID + "|" + userName);
}

removeUserFromTeleport(key userID, string userName, string reason) {
    // Remove from authorized list
    integer index = llListFindList(authorizedTeleporters, [userID]);
    if (index != -1) {
        authorizedTeleporters = llDeleteSubList(authorizedTeleporters, index, index);
        teleportDestinations = llDeleteSubList(teleportDestinations, index * 2, index * 2 + 1);
    }
    
    // Your teleport logic here - examples:
    // - Remove from teleport hub access list
    // - Delete teleport landmark
    // - Remove from teleport HUD
    // - Unregister destination from teleport network
    
    llOwnerSay("Teleport System: Removed " + userName + " (" + (string)userID + ") from teleport system - Reason: " + reason);
    
    // Example: Send confirmation back to rental system (optional)
    llRegionSay(TELEPORT_CHANNEL, TELEPORT_PASSWORD + "|USER_REMOVED|" + (string)userID + "|" + userName);
}

teleportUser(key userID, string teleportData) {
    // Find user's teleport destination
    integer index = llListFindList(authorizedTeleporters, [userID]);
    if (index == -1) {
        llInstantMessage(userID, "Teleport System: You are not authorized for teleport access.");
        return;
    }
    
    // Parse teleport data
    if (llSubStringIndex(teleportData, "POSITION:") == 0) {
        // Teleport to position
        string posStr = llGetSubString(teleportData, 9, -1);
        vector pos = (vector)posStr;
        
        // Your teleport logic here - examples:
        // - Use llTeleportAgentHome() for home teleport
        // - Use llTeleportAgent() for position teleport
        // - Interface with your teleport system
        
        llOwnerSay("Teleport System: Teleporting " + llKey2Name(userID) + " to position " + (string)pos);
        // Example: llTeleportAgent(userID, "", pos, ZERO_VECTOR);
        
    } else if (llSubStringIndex(teleportData, "LANDMARK:") == 0) {
        // Teleport to landmark
        string landmark = llGetSubString(teleportData, 9, -1);
        
        llOwnerSay("Teleport System: Teleporting " + llKey2Name(userID) + " to landmark " + landmark);
        // Your landmark teleport logic here
        
    } else {
        llInstantMessage(userID, "Teleport System: Invalid teleport destination configured.");
    }
}

processTeleportCommand(string command, key userID, string params) {
    if (command == "ADD_USER") {
        list paramList = llParseString2List(params, ["|"], []);
        string userType = llList2String(paramList, 0); // Should be "RENTER"
        string userName = llList2String(paramList, 1);
        string region = llList2String(paramList, 2);
        string teleportData = "";
        
        // Get teleport data if provided
        if (llGetListLength(paramList) > 3) {
            teleportData = llList2String(paramList, 3);
        }
        
        addUserToTeleport(userID, userName, teleportData);
        
    } else if (command == "REMOVE_USER") {
        list paramList = llParseString2List(params, ["|"], []);
        string userType = llList2String(paramList, 0); // Should be "RENTER"
        string userName = llList2String(paramList, 1);
        string reason = llList2String(paramList, 2);
        
        removeUserFromTeleport(userID, userName, reason);
        
    } else if (command == "TELEPORT_USER") {
        teleportUser(userID, params);
        
    } else if (command == "TEST") {
        llOwnerSay("Teleport System: Test command received from rental system - Connection OK");
        // Send test response back
        llRegionSay(TELEPORT_CHANNEL, TELEPORT_PASSWORD + "|TEST_RESPONSE|" + (string)userID + "|Connection successful");
        
    } else {
        llOwnerSay("Teleport System: Unknown command received: " + command);
    }
}

default {
    state_entry() {
        llOwnerSay("Teleport System Example: Listening on channel " + (string)TELEPORT_CHANNEL);
        llOwnerSay("Teleport System Example: Password configured: " + (TELEPORT_PASSWORD != "" ? "YES" : "NO"));
        
        // Listen for rental system integration commands
        llListen(TELEPORT_CHANNEL, "", NULL_KEY, "");
    }
    
    listen(integer channel, string name, key id, string message) {
        if (channel == TELEPORT_CHANNEL) {
            // Parse the message: PASSWORD|COMMAND|USERID|PARAMS
            list parts = llParseString2List(message, ["|"], []);
            
            if (llGetListLength(parts) >= 3) {
                string receivedPassword = llList2String(parts, 0);
                string command = llList2String(parts, 1);
                key userID = (key)llList2String(parts, 2);
                string params = "";
                
                // Rebuild params from remaining parts
                if (llGetListLength(parts) > 3) {
                    params = llDumpList2String(llList2Range(parts, 3, -1), "|");
                }
                
                // Verify password
                if (receivedPassword == TELEPORT_PASSWORD) {
                    processTeleportCommand(command, userID, params);
                } else {
                    llOwnerSay("Teleport System: Invalid password received from " + name + " (" + (string)id + ")");
                }
            }
        }
    }
    
    // Example: Manual teleport for authorized users
    touch_start(integer total_number) {
        integer i;
        for (i = 0; i < total_number; i++) {
            key toucher = llDetectedKey(i);
            
            if (llListFindList(authorizedTeleporters, [toucher]) != -1) {
                // Get user's teleport destination
                integer index = llListFindList(authorizedTeleporters, [toucher]);
                string teleportData = llList2String(teleportDestinations, index * 2 + 1);
                
                llInstantMessage(toucher, "Teleport System: Teleporting you to your rental property...");
                teleportUser(toucher, teleportData);
                
            } else if (toucher == llGetOwner()) {
                // Show owner status
                string status = "Teleport System Status:\n";
                status += "Authorized Users: " + (string)llGetListLength(authorizedTeleporters) + "\n";
                status += "Channel: " + (string)TELEPORT_CHANNEL + "\n";
                status += "Password: " + (TELEPORT_PASSWORD != "" ? "SET" : "NOT SET");
                llInstantMessage(toucher, status);
                
            } else {
                llInstantMessage(toucher, "Teleport System: You are not authorized for teleport access.");
            }
        }
    }
    
    on_rez(integer start_param) {
        llResetScript();
    }
} 