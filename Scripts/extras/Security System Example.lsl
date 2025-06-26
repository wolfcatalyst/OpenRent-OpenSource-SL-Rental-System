//Security System Example - Integration with OpenRent Modular System
//This is an EXAMPLE script showing how your existing security system can integrate
//Replace this with your actual security system logic

// Security settings
integer SECURITY_CHANNEL = -9876543; // Must match the channel in Security Integration module
string SECURITY_PASSWORD = "YourSecurityPassword123"; // Set this to match your integration module
list authorizedRenters = []; // List of currently authorized renter UUIDs

// Your existing security functions would go here
grantAccess(key userID, string userName, string region) {
    // Add to authorized list
    if (llListFindList(authorizedRenters, [userID]) == -1) {
        authorizedRenters += [userID];
    }
    
    // Your security logic here - examples:
    // - Add to access control list
    // - Enable door access
    // - Grant area permissions
    // - Add to security orb exceptions
    
    llOwnerSay("Security System: Granted access to " + userName + " (" + (string)userID + ") for region " + region);
    
    // Example: Send confirmation back to rental system (optional)
    llRegionSay(SECURITY_CHANNEL, SECURITY_PASSWORD + "|ACCESS_GRANTED|" + (string)userID + "|" + userName);
}

revokeAccess(key userID, string userName, string reason) {
    // Remove from authorized list
    integer index = llListFindList(authorizedRenters, [userID]);
    if (index != -1) {
        authorizedRenters = llDeleteSubList(authorizedRenters, index, index);
    }
    
    // Your security logic here - examples:
    // - Remove from access control list
    // - Disable door access
    // - Revoke area permissions
    // - Remove from security orb exceptions
    
    llOwnerSay("Security System: Revoked access from " + userName + " (" + (string)userID + ") - Reason: " + reason);
    
    // Example: Send confirmation back to rental system (optional)
    llRegionSay(SECURITY_CHANNEL, SECURITY_PASSWORD + "|ACCESS_REVOKED|" + (string)userID + "|" + userName);
}

sendAlert(string alertType, string message) {
    // Your alert/notification logic here - examples:
    // - Send email notifications
    // - Log to database
    // - Send to monitoring system
    // - Display on security HUD
    
    llOwnerSay("Security Alert [" + alertType + "]: " + message);
}

processSecurityCommand(string command, key userID, string params) {
    if (command == "GRANT_ACCESS") {
        list paramList = llParseString2List(params, ["|"], []);
        string userType = llList2String(paramList, 0); // Should be "RENTER"
        string userName = llList2String(paramList, 1);
        string region = llList2String(paramList, 2);
        
        grantAccess(userID, userName, region);
        
    } else if (command == "REVOKE_ACCESS") {
        list paramList = llParseString2List(params, ["|"], []);
        string userType = llList2String(paramList, 0); // Should be "RENTER"
        string userName = llList2String(paramList, 1);
        string reason = llList2String(paramList, 2);
        
        revokeAccess(userID, userName, reason);
        
    } else if (command == "ALERT") {
        list paramList = llParseString2List(params, ["|"], []);
        string alertType = llList2String(paramList, 0);
        string message = llList2String(paramList, 1);
        
        sendAlert(alertType, message);
        
    } else if (command == "TEST") {
        llOwnerSay("Security System: Test command received from rental system - Connection OK");
        // Send test response back
        llRegionSay(SECURITY_CHANNEL, SECURITY_PASSWORD + "|TEST_RESPONSE|" + (string)userID + "|Connection successful");
        
    } else {
        llOwnerSay("Security System: Unknown command received: " + command);
    }
}

default {
    state_entry() {
        llOwnerSay("Security System Example: Listening on channel " + (string)SECURITY_CHANNEL);
        llOwnerSay("Security System Example: Password configured: " + (SECURITY_PASSWORD != "" ? "YES" : "NO"));
        
        // Listen for rental system integration commands
        llListen(SECURITY_CHANNEL, "", NULL_KEY, "");
    }
    
    listen(integer channel, string name, key id, string message) {
        if (channel == SECURITY_CHANNEL) {
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
                if (receivedPassword == SECURITY_PASSWORD) {
                    processSecurityCommand(command, userID, params);
                } else {
                    llOwnerSay("Security System: Invalid password received from " + name + " (" + (string)id + ")");
                }
            }
        }
    }
    
    // Example: Check if a user has access (for your existing security logic)
    touch_start(integer total_number) {
        integer i;
        for (i = 0; i < total_number; i++) {
            key toucher = llDetectedKey(i);
            
            if (llListFindList(authorizedRenters, [toucher]) != -1) {
                llInstantMessage(toucher, "Access granted - you are an authorized renter.");
                // Your access logic here (open doors, etc.)
            } else if (toucher == llGetOwner()) {
                llInstantMessage(toucher, "Owner access granted.");
                // Owner always has access
            } else {
                llInstantMessage(toucher, "Access denied - you are not authorized.");
                // Your denial logic here (security alerts, etc.)
            }
        }
    }
    
    on_rez(integer start_param) {
        llResetScript();
    }
} 