//Rental Core Script v3.1 - Memory Optimized
//Core rental logic only - UI handled by UI Manager
//Created by Wolf Starforge
//Version 3.1.0
//Date: 2025-06-26
//Open Source: See license file for more information.


// Core variables (reduced to essentials)
string myGroupName;
string myGroupID;
string emailForNotifications = "";
string configNotecardName = "_Settings";
string welcomeNotecard;
string tierName;
string infoNotecard = "Rent This Space Info";
string renterName;
string currentState = "initialize";

integer rentalCost;
integer primCount;
integer rentalVolume;
integer refundsEnabled = 0;
integer refundFee;
integer floatingTextEnabled = 0;
integer gracePeriod;
integer currentGracePeriod;
integer allowOwnerPayment;
integer allowGroupPayment;
integer count;
integer lineCount;

float updateInterval = 60.0;
float discountPercent = 0.0;
float rentalTime;
float discountTime;

key renterID;
key readKey;

vector initPos;
vector initScale;

// Constants
float ONE_WEEK = 604800.0;
float _48_HOURS = 172800.0;
float _24_HOURS = 86400.0;
float _6_HOURS = 21600.0;
float _1_HOUR = 3600.0;

// Reminder flags (reset on payment)
integer reminder48sent = FALSE;
integer reminder24sent = FALSE;
integer reminder6sent = FALSE;
integer reminder1sent = FALSE;

// Offline time tracking
integer lastUpdateTime;

// Adaptive timer intervals
float TIMER_URGENT = 60.0;      // 1 minute for ≤1 hour remaining
float TIMER_MODERATE = 900.0;   // 15 minutes for ≤1 day but >1 hour
float TIMER_RELAXED = 3600.0;  // 1 hour for >1 day

// Calculate appropriate timer interval based on time remaining
float getAdaptiveInterval(float timeRemaining) {
    if (timeRemaining <= 4500.0) {  // 75 minutes (1.25 hours)
        return TIMER_URGENT;    // 1 minute
    } else if (timeRemaining <= _24_HOURS) {
        return TIMER_MODERATE;  // 15 minutes
    } else {
        return TIMER_RELAXED;   // 4 hours
    }
}

// Update timer with adaptive interval
updateAdaptiveTimer() {
    float newInterval = getAdaptiveInterval(rentalTime);
    if (newInterval != updateInterval) {
        updateInterval = newInterval;
        llSetTimerEvent(updateInterval);
    }
}

// Force immediate rental time update (for touch events)
forceRentalUpdate() {
    float elapsed = llGetAndResetTime();
    if (elapsed > updateInterval * 4) elapsed = updateInterval;
    rentalTime -= elapsed;
    saveData();
    updateTimeDisp();
    updateAdaptiveTimer();
}

// Optimized functions
sendEmail(string subject, string msg) {
    if (emailForNotifications != "") llEmail(emailForNotifications, subject, msg);
}

dispString(string value) {
    if (floatingTextEnabled) {
        llSetText(value, <1, 1, 1>, 1);
    } else {
        llSetText("", ZERO_VECTOR, 1.0);
    }
}

saveData() {
    // Update timestamp for offline time tracking
    lastUpdateTime = llGetUnixTime();
    
    if (renterID != NULL_KEY) {
        llSetObjectDesc((string)renterID + "^" + renterName + "^" + (string)llRound(rentalTime));
    } else {
        llSetObjectDesc((string)llRound(rentalTime));
    }
    llMessageLinked(LINK_SET, 0, "Mesh:Update^" + (string)llRound(rentalTime), NULL_KEY);
}

parseSavedData() {
    string desc = llGetObjectDesc();
    if (desc != "") {
        list data = llParseString2List(desc, ["^"], []);
        if (llGetListLength(data) >= 3) {
            // Rental data format
            renterID = llList2Key(data, 0);
            renterName = llList2String(data, 1);
            rentalTime = llList2Float(data, 2);
        } else {
            // Just time remaining
            rentalTime = llList2Float(data, 0);
        }
    }
    // Initialize timestamp for offline tracking
    lastUpdateTime = llGetUnixTime();
}

string getTimeString(integer time) {
    integer days = time / 86400;
    time = time % 86400;
    integer hours = time / 3600;
    time = time % 3600;
    integer minutes = time / 60;
    return (string)days + " days, " + (string)hours + " hours, " + (string)minutes + " minutes";
}

updateTimeDisp() {
    dispString("Leased by: " + renterName + "\nTime Remaining: " + getTimeString(llRound(rentalTime)));
}

processAction(string action, key userID, string params, integer responseChannel) {
    if (action == "Info") {
        // Send info message
        string infoMsg = tierName + " - L$" + (string)rentalCost + "/week";
        llMessageLinked(LINK_SET, 0, "UI:Message^" + infoMsg, userID);
    } else if (action == "Lock") {
        currentState = "locked";
        llMessageLinked(LINK_SET, 0, "Core:ChangeState^locked", NULL_KEY);
        llMessageLinked(LINK_SET, 0, "Mesh:Locked", NULL_KEY);
    } else if (action == "Unlock") {
        llMessageLinked(LINK_SET, 0, "UI:ShowUnlockDialog", userID);
    } else if (action == "ConfirmUnlock") {
        currentState = "idle";
        llMessageLinked(LINK_SET, 0, "Core:ChangeState^idle", NULL_KEY);
        llMessageLinked(LINK_SET, 0, "Mesh:Idle", NULL_KEY);
    } else if (action == "Unavailable") {
        currentState = "unavailable";
        llMessageLinked(LINK_SET, 0, "Core:ChangeState^unavailable", NULL_KEY);
        llMessageLinked(LINK_SET, 0, "Mesh:Unavailable", NULL_KEY);
    } else if (action == "Available") {
        currentState = "idle";
        llMessageLinked(LINK_SET, 0, "Core:ChangeState^idle", NULL_KEY);
        llMessageLinked(LINK_SET, 0, "Mesh:Idle", NULL_KEY);
    } else if (action == "Reset") {
        llResetScript();
    } else if (action == "SetSpecificRenter") {
        renterName = params;
        currentState = "idle_SpecificRenter";
        llMessageLinked(LINK_SET, 0, "Core:ChangeState^idle_SpecificRenter", NULL_KEY);
    } else if (action == "CancelSpecificRenter") {
        renterName = "";
        currentState = "idle";
        llMessageLinked(LINK_SET, 0, "Core:ChangeState^idle", NULL_KEY);
    } else if (action == "Release") {
        // Stop timer to prevent interference with data clearing
        llSetTimerEvent(0);
        
        // Preserve renter info for final messages before clearing
        key tempRenterID = renterID;
        string tempRenterName = renterName;
        
        // Clear rental data first
        renterID = NULL_KEY;
        renterName = "";
        rentalTime = 0.0;
        saveData();
        
        // Send messages using preserved info
        llInstantMessage(llGetOwner(), "LEASE TERMINATED: " + tempRenterName + " - Refunded L$0.");
        sendEmail("LEASE TERMINATED", "Lease terminated for " + tempRenterName);
        
        // Update mesh and state
        llMessageLinked(LINK_SET, 0, "Mesh:Idle", NULL_KEY);
        currentState = "idle";
        llMessageLinked(LINK_SET, 0, "Core:ChangeState^idle", NULL_KEY);
    } else if (action == "Refund" && refundsEnabled) {
        llMessageLinked(LINK_SET, 0, "UI:ShowConfirmRefund^" + (string)refundFee, userID);
    } else if (action == "ConfirmRefund") {
        // Stop timer to prevent interference with data clearing
        llSetTimerEvent(0);
        
        // Preserve renter info for final messages before clearing
        key tempRenterID = renterID;
        string tempRenterName = renterName;
        
        // Calculate refund amount
        integer refundAmount = llRound((rentalTime / ONE_WEEK) * rentalCost - refundFee);
        
        // Clear rental data first
        renterID = NULL_KEY;
        renterName = "";
        rentalTime = 0.0;
        saveData(); // Save the cleared data
        
        // Process refund payment
        if (refundAmount > 0) {
            llInstantMessage(tempRenterID, "Refunding L$" + (string)refundAmount);
            llGiveMoney(tempRenterID, refundAmount);
        }
        
        // Send notifications using preserved info
        llInstantMessage(llGetOwner(), "LEASE REFUNDED: " + tempRenterName + " - L$" + (string)refundAmount);
        sendEmail("LEASE REFUNDED", "Lease refunded for " + tempRenterName + " - Amount: L$" + (string)refundAmount);
        
        // Update mesh and state
        llMessageLinked(LINK_SET, 0, "Mesh:Idle", NULL_KEY);
        currentState = "idle";
        llMessageLinked(LINK_SET, 0, "Core:ChangeState^idle", NULL_KEY);
    } else if (action == "CancelGrace") {
        llInstantMessage(llGetOwner(), "GRACE PERIOD CANCELLED: " + renterName + " - Lease terminated.");
        sendEmail("GRACE PERIOD CANCELLED", "Grace period cancelled for " + renterName);
        renterID = NULL_KEY;
        renterName = "";
        rentalTime = 0.0;
        currentGracePeriod = 0;
        saveData();
        llMessageLinked(LINK_SET, 0, "Mesh:Idle", NULL_KEY);
        currentState = "idle";
        llMessageLinked(LINK_SET, 0, "Core:ChangeState^idle", NULL_KEY);
    } else if (action == "CheckUserRole") {
        key userID = (key)params;
        string role = "other";
        if (userID == llGetOwner()) {
            role = "owner";
        } else if (userID == renterID) {
            role = "renter";
        }
        // Send response back on the same channel we received the request
        llMessageLinked(LINK_SET, responseChannel, "Core:UserRole^" + role + "^" + (string)userID, NULL_KEY);
    }
}

processPayment(key id, integer amount) {
    if (currentState == "idle" || currentState == "idle_SpecificRenter") {
        if (amount >= rentalCost) {
            if (currentState == "idle_SpecificRenter" && llKey2Name(id) != renterName) {
                llGiveMoney(id, amount);
                return;
            }
            
            renterID = id;
            renterName = llKey2Name(id);
            
            // Calculate rental time
            integer fourWeekPrice = llRound(rentalCost * 4.0 * (1.0 - discountPercent / 100.0));
            if (fourWeekPrice == amount) {
                rentalTime = ONE_WEEK * 4;
                discountTime = rentalTime;
            } else {
                rentalTime = ONE_WEEK * amount / rentalCost;
                discountTime = 0;
            }

            // Reset reminder flags for new rental
            reminder48sent = FALSE;
            reminder24sent = FALSE;
            reminder6sent = FALSE;
            reminder1sent = FALSE;
            
            saveData();
            llSay(0, "Thank you " + renterName + "! Lease expires in " + getTimeString((integer)rentalTime));
            
            if (welcomeNotecard != "") llGiveInventory(id, welcomeNotecard);
            if (myGroupID != "" && myGroupID != "00000000-0000-0000-0000-000000000000") {
                llInstantMessage(id, "Join group: secondlife:///app/group/" + myGroupID + "/about");
            }
            
            currentState = "rented";
            llMessageLinked(LINK_SET, 0, "Core:ChangeState^rented", NULL_KEY);
        } else {
            llGiveMoney(id, amount);
        }
    } else if (currentState == "rented") {
        if (id == renterID || (allowOwnerPayment && id == llGetOwner()) || (allowGroupPayment && llSameGroup(id))) {
            // Calculate rental time - check for 4-week package
            integer fourWeekPrice = llRound(rentalCost * 4.0 * (1.0 - discountPercent / 100.0));
            float addTime;
            if (fourWeekPrice == amount) {
                addTime = ONE_WEEK * 4;
            } else {
                addTime = ONE_WEEK * amount / rentalCost;
            }
            rentalTime += addTime;
            
            // Reset reminder flags when time is extended
            reminder48sent = FALSE;
            reminder24sent = FALSE;
            reminder6sent = FALSE;
            reminder1sent = FALSE;
            
            // Update system first for immediate responsiveness
            saveData();
            updateTimeDisp();
            updateAdaptiveTimer();
            
            // Then send notifications
            llInstantMessage(id, "Added " + getTimeString(llRound(addTime)) + ". Total: " + getTimeString(llRound(rentalTime)));
            llInstantMessage(llGetOwner(), "Rental Extension: " + renterName + " extended lease. New total: " + getTimeString(llRound(rentalTime)));
            sendEmail("Rental Extension", "Renter: " + renterName + " extended lease. New total: " + getTimeString(llRound(rentalTime)));
        } else {
            llGiveMoney(id, amount);
        }
    } else if (currentState == "grace" && id == renterID) {
        float addTime = ONE_WEEK * amount / rentalCost;
        rentalTime = addTime - currentGracePeriod;
        currentGracePeriod = 0;
        
        // Reset reminder flags when lease is extended from grace
        reminder48sent = FALSE;
        reminder24sent = FALSE;
        reminder6sent = FALSE;
        reminder1sent = FALSE;
        
        // Update system first for immediate responsiveness
        saveData();
        updateTimeDisp();
        updateInterval = getAdaptiveInterval(rentalTime);
        currentState = "rented";
        llMessageLinked(LINK_SET, 0, "Core:ChangeState^rented", NULL_KEY);
        
        // Then send notifications
        llInstantMessage(id, "Lease extended: " + getTimeString(llRound(rentalTime)));
        llInstantMessage(llGetOwner(), "Grace Recovery: " + renterName + " paid during grace period. New total: " + getTimeString(llRound(rentalTime)));
        sendEmail("Grace Recovery", "Renter: " + renterName + " paid during grace period. New total: " + getTimeString(llRound(rentalTime)));
    } else {
        llGiveMoney(id, amount);
    }
}

// States
default {
    state_entry() {
        initPos = llGetPos();
        initScale = llGetScale();
        currentState = "initialize";
        state initialize;
    }
}

state initialize {
    state_entry() {
        llMessageLinked(LINK_SET, 0, "Mesh:Initializing", NULL_KEY);
        llSetTimerEvent(300);
        llOwnerSay("Waiting for debit permissions...");
        llRequestPermissions(llGetOwner(), PERMISSION_DEBIT);
    }
    
    run_time_permissions(integer permissions) {
        if (permissions & PERMISSION_DEBIT) {
            currentState = "loadSettings";
            state loadSettings;
        }
    }
    
    on_rez(integer start_param) { llResetScript(); }
    timer() { llRequestPermissions(llGetOwner(), PERMISSION_DEBIT); }
    
    link_message(integer sender_num, integer num, string message, key id) {
        if (llList2String(llParseString2List(message, ["^"], []), 0) == "Core:Touch") {
            key user = (key)llList2String(llParseString2List(message, ["^"], []), 1);
            if (user == llGetOwner()) {
                llResetScript();
            } else {
                llSay(0, "Waiting for owner permissions...");
            }
        }
    }
    
    state_exit() {
        llSetTimerEvent(0);
        llSay(0, "Initialized.");
    }
}

state loadSettings {
    state_entry() {
        currentState = "loadSettings";
        count = 0;
        lineCount = 0;
        
        integer found = FALSE;
        integer x;
        for (x = 0; x < llGetInventoryNumber(INVENTORY_NOTECARD) && !found; x++) {
            if (llGetInventoryName(INVENTORY_NOTECARD, x) == configNotecardName) {
                found = TRUE;
            }
        }
        
        if (found) {
            llOwnerSay("Reading settings...");
            readKey = llGetNotecardLine(configNotecardName, lineCount);
        } else {
            llOwnerSay("Settings notecard not found!");
            llResetScript();
        }
    }
    
    dataserver(key requested, string data) {
        if (requested == readKey) {
            if (data != EOF) {
                string trimmed = llStringTrim(data, STRING_TRIM);
                if (llGetSubString(trimmed, 0, 0) != "#" && trimmed != "") {
                    list tokens = llParseString2List(trimmed, [":"], []);
                    string setting = llStringTrim(llList2String(tokens, 0), STRING_TRIM);
                    string value = llStringTrim(llList2String(tokens, 1), STRING_TRIM);

                    if (setting == "Spot Name") tierName = value;
                    else if (setting == "Rental Cost") rentalCost = (integer)value;
                    else if (setting == "Discount Percent") discountPercent = (float)value;
                    else if (setting == "Prim Count") primCount = (integer)value;
                    else if (setting == "Rental Size") rentalVolume = (integer)value;
                    else if (setting == "Refunds Enabled") refundsEnabled = (integer)value;
                    else if (setting == "Refund Fee") refundFee = (integer)value;
                    else if (setting == "Info Notecard Name") infoNotecard = value;
                    else if (setting == "Floating Text Enabled") floatingTextEnabled = (integer)value;
                    else if (setting == "Email for Notifications") emailForNotifications = value;
                    else if (setting == "Welcome Notecard") welcomeNotecard = value;
                    else if (setting == "Group Name") myGroupName = value;
                    else if (setting == "Group UUID") myGroupID = value;
                    else if (setting == "Grace Period") gracePeriod = (integer)value * 3600;
                    else if (setting == "Allow Owner Payment") allowOwnerPayment = (integer)value;
                    else if (setting == "Allow Group Payment") allowGroupPayment = (integer)value;
                    else {
                        // Mesh settings
                        llMessageLinked(LINK_SET, 0, "Mesh:Set" + setting + "^" + value, NULL_KEY);
                    }
                }
                lineCount++;
                readKey = llGetNotecardLine(configNotecardName, lineCount);
            } else {
                // Settings loaded
                if (allowOwnerPayment || allowGroupPayment) refundsEnabled = 0;
                
                llOwnerSay("Settings loaded.");
                if (llGetObjectDesc() != "") parseSavedData();
                
                // Set pay prices
                integer fourWeekPrice = llRound(rentalCost * 4.0 * (1.0 - discountPercent / 100.0));
                llSetPayPrice(rentalCost, [rentalCost, rentalCost * 2, rentalCost * 3, fourWeekPrice]);
                
                if (rentalTime > 0 && renterID != NULL_KEY) {
                    updateInterval = getAdaptiveInterval(rentalTime);
                    llSetTimerEvent(updateInterval);
                    state rented;
                } else {
                    state idle;
                }
            }
        }
    }
}

state idle {
    state_entry() {
        currentState = "idle";
        llSetObjectDesc("");
        llMessageLinked(LINK_SET, 0, "Mesh:Idle", NULL_KEY);
        llSetTimerEvent(updateInterval);
        
        dispString(tierName + "\nL$" + (string)rentalCost + " per week\n" + (string)rentalVolume + " sq meters\n" + (string)primCount + " prims");
        
        // Send data to UI
        llMessageLinked(LINK_SET, 0, "UI:UpdateData^" + tierName + "^" + (string)rentalCost + "^" + (string)primCount + "^" + (string)rentalVolume + "^" + (string)refundsEnabled + "^" + (string)NULL_KEY + "^^0^" + infoNotecard + "^" + (string)floatingTextEnabled + "^" + (string)refundFee, NULL_KEY);
    }
    
    link_message(integer sender_num, integer num, string message, key id) {
        list parts = llParseString2List(message, ["^"], []);
        string command = llList2String(parts, 0);
        
        if (command == "Core:Touch") {
            key user = (key)llList2String(parts, 1);
            if (user == llGetOwner()) {
                llMessageLinked(LINK_SET, 0, "UI:ShowOwnerMenuIdle", user);
            } else {
                llSay(0, "Lease this space for L$" + (string)rentalCost + " per week. Pay this sign to begin.");
                llGiveInventory(user, infoNotecard);
            }
        } else if (command == "Core:Action") {
            processAction(llList2String(parts, 1), id, llList2String(parts, 2), num);
        } else if (command == "UI:RequestData") {
            llMessageLinked(LINK_SET, 0, "UI:UpdateData^" + tierName + "^" + (string)rentalCost + "^" + (string)primCount + "^" + (string)rentalVolume + "^" + (string)refundsEnabled + "^" + (string)NULL_KEY + "^^0^" + infoNotecard + "^" + (string)floatingTextEnabled + "^" + (string)refundFee, NULL_KEY);
        } else if (command == "Core:ChangeState") {
            string newState = llList2String(parts, 1);
            if (newState == "idle") {
                // Already in idle, just refresh
                state idle;
            } else if (newState == "rented") state rented;
            else if (newState == "idle_SpecificRenter") state idle_SpecificRenter;
            else if (newState == "grace") state grace;
            else if (newState == "locked") state locked;
        }
    }
    
    money(key id, integer amount) { processPayment(id, amount); }
}

state rented {
    state_entry() {
        currentState = "rented";
        updateTimeDisp();
        llResetTime();
        updateInterval = getAdaptiveInterval(rentalTime);
        llSetTimerEvent(updateInterval);
        // Update mesh state and meter
        llMessageLinked(LINK_SET, 0, "Mesh:Rented", NULL_KEY);
        llMessageLinked(LINK_SET, 0, "Mesh:Update^" + (string)llRound(rentalTime), NULL_KEY);
        
        // Send data to UI
        llMessageLinked(LINK_SET, 0, "UI:UpdateData^" + tierName + "^" + (string)rentalCost + "^" + (string)primCount + "^" + (string)rentalVolume + "^" + (string)refundsEnabled + "^" + (string)renterID + "^" + renterName + "^" + (string)rentalTime + "^" + infoNotecard + "^" + (string)floatingTextEnabled + "^" + (string)refundFee, NULL_KEY);
        
        // Send notifications (after system updates)
        llInstantMessage(llGetOwner(), "Rental confirmed: " + renterName);
        sendEmail("Rental Confirmed", "Renter: " + renterName + ", Duration: " + (string)rentalTime);
    }
    on_rez(integer start_param) {
        // Calculate offline time using lastUpdateTime variable
        if (renterID != NULL_KEY && lastUpdateTime > 0) {
            integer currentTime = llGetUnixTime();
            integer offlineSeconds = currentTime - lastUpdateTime;
            
            // Only adjust if we've been offline for more than 1 minute
            if (offlineSeconds > 60) {
                float correctedTime = rentalTime - offlineSeconds;
                
                // Prevent negative time
                if (correctedTime < 0) correctedTime = 0;
                
                // Update rental time
                rentalTime = correctedTime;
                
                // Save the corrected data to object description
                saveData();
                
                // Log the offline correction for owner
                llOwnerSay("Offline Time Correction: " + renterName + " was offline for " + getTimeString(offlineSeconds) + ". Remaining time adjusted to " + getTimeString(llRound(correctedTime)));
                
                // Check if lease expired while offline
                if (correctedTime <= 0) {
                    llInstantMessage(llGetOwner(), "LEASE EXPIRED OFFLINE: " + renterName + " - Lease expired while rental box was in inventory");
                    sendEmail("LEASE EXPIRED OFFLINE", "Lease expired for " + renterName + " while rental box was in inventory. Rental is now available for new lease.");
                }
            }
        }
        llResetScript();
    }
    link_message(integer sender_num, integer num, string message, key id) {
        list parts = llParseString2List(message, ["^"], []);
        string command = llList2String(parts, 0);
        
        if (command == "Core:Touch") {
            key user = (key)llList2String(parts, 1);
            // Force immediate update of rental time and display on touch
            forceRentalUpdate();
            if (user == llGetOwner()) {
                llMessageLinked(LINK_SET, 0, "UI:ShowOwnerMenuRented", user);
            } else if (user == renterID) {
                llMessageLinked(LINK_SET, 0, "UI:ShowRenterMenu", user);
            } else {
                llSay(0, "Leased by " + renterName + ". Available in " + getTimeString(llRound(rentalTime)));
                llGiveInventory(user, infoNotecard);
            }
        } else if (command == "Core:Action") {
            processAction(llList2String(parts, 1), id, llList2String(parts, 2), num);
        } else if (command == "UI:RequestData") {
            llMessageLinked(LINK_SET, 0, "UI:UpdateData^" + tierName + "^" + (string)rentalCost + "^" + (string)primCount + "^" + (string)rentalVolume + "^" + (string)refundsEnabled + "^" + (string)renterID + "^" + renterName + "^" + (string)rentalTime + "^" + infoNotecard + "^" + (string)floatingTextEnabled + "^" + (string)refundFee, NULL_KEY);
        } else if (command == "Core:ChangeState") {
            string newState = llList2String(parts, 1);
            if (newState == "idle") state idle;
            else if (newState == "grace") state grace;
            else if (newState == "locked") state locked;
        }
    }
    
    money(key id, integer amount) { processPayment(id, amount); }
    
    timer() {
        float elapsed = llGetAndResetTime();
        if (elapsed > updateInterval * 4) elapsed = updateInterval;
        rentalTime -= elapsed;

        saveData();
        updateTimeDisp();

        if (rentalTime <= 0) {
            if (gracePeriod > 0) {
                // Preserve renter info for notifications
                string tempRenterName = renterName;
                key tempRenterID = renterID;
                
                llInstantMessage(tempRenterID, "Lease expired. Grace period started.");
                llInstantMessage(llGetOwner(), "Grace Period Started: " + tempRenterName + " - " + getTimeString(gracePeriod) + " grace period active");
                sendEmail("Grace Period Started", "Lease expired for " + tempRenterName + ". Grace period of " + getTimeString(gracePeriod) + " has started.");
                
                currentState = "grace";
                state grace;
            } else {
                // Preserve renter info for notifications before clearing
                string tempRenterName = renterName;
                
                llInstantMessage(llGetOwner(), "LEASE EXPIRED: " + tempRenterName + " - No grace period, rental now available");
                sendEmail("LEASE EXPIRED", "Lease expired for " + tempRenterName + ". Rental is now available for new lease.");
                
                renterID = NULL_KEY;
                renterName = "";
                rentalTime = 0.0;
                currentState = "idle";
                state idle;
            }
        }
        
        // Update timer interval based on remaining time
        updateAdaptiveTimer();
        
        // Single-fire reminders with proper range checking
        if (rentalTime <= _48_HOURS && rentalTime > _24_HOURS && !reminder48sent) {
            llInstantMessage(renterID, "Lease expires in 2 days");
            llInstantMessage(llGetOwner(), "Reminder Sent: " + renterName + " - 2 days remaining");
            sendEmail("Lease Reminder", "2-day reminder sent to " + renterName + ". Time remaining: " + getTimeString(llRound(rentalTime)));
            reminder48sent = TRUE;
        } else if (rentalTime <= _24_HOURS && rentalTime > _6_HOURS && !reminder24sent) {
            llInstantMessage(renterID, "Lease expires in 1 day");
            llInstantMessage(llGetOwner(), "Reminder Sent: " + renterName + " - 1 day remaining");
            sendEmail("Lease Reminder", "1-day reminder sent to " + renterName + ". Time remaining: " + getTimeString(llRound(rentalTime)));
            reminder24sent = TRUE;
        } else if (rentalTime <= _6_HOURS && rentalTime > _1_HOUR && !reminder6sent) {
            llInstantMessage(renterID, "Lease expires in 6 hours");
            llInstantMessage(llGetOwner(), "Reminder Sent: " + renterName + " - 6 hours remaining");
            sendEmail("Lease Reminder", "6-hour reminder sent to " + renterName + ". Time remaining: " + getTimeString(llRound(rentalTime)));
            reminder6sent = TRUE;
        } else if (rentalTime <= _1_HOUR && !reminder1sent) {
            llInstantMessage(renterID, "Lease expires in 1 hour");
            llInstantMessage(llGetOwner(), "Reminder Sent: " + renterName + " - 1 hour remaining");
            sendEmail("Lease Reminder", "1-hour reminder sent to " + renterName + ". Time remaining: " + getTimeString(llRound(rentalTime)));
            reminder1sent = TRUE;
        }
    }
}

state idle_SpecificRenter {
    state_entry() {
        currentState = "idle_SpecificRenter";
        llMessageLinked(LINK_SET, 0, "Mesh:Reserved", NULL_KEY);
    }
    
    link_message(integer sender_num, integer num, string message, key id) {
        list parts = llParseString2List(message, ["^"], []);
        string command = llList2String(parts, 0);
        
        if (command == "Core:Touch") {
            key user = (key)llList2String(parts, 1);
            if (user == llGetOwner()) {
                llMessageLinked(LINK_SET, 0, "UI:ShowSpecificRenterOptions", user);
            } else {
                llInstantMessage(user, "Reserved for " + renterName);
            }
        } else if (command == "Core:Action") {
            processAction(llList2String(parts, 1), id, llList2String(parts, 2), num);
        } else if (command == "Core:ChangeState") {
            string newState = llList2String(parts, 1);
            if (newState == "rented") state rented;
            else if (newState == "idle") state idle;
            else if (newState == "grace") state grace;
            else if (newState == "locked") state locked;
        }
    }
    
    money(key id, integer amount) { processPayment(id, amount); }
}

state grace {
    state_entry() {
        currentState = "grace";
        currentGracePeriod = gracePeriod;
        llInstantMessage(renterID, "Grace period started");
        llInstantMessage(llGetOwner(), "Grace period for " + renterName);
        llMessageLinked(LINK_SET, 0, "Mesh:Grace", NULL_KEY);
        // Grace periods are typically short, so use urgent timing
        updateInterval = TIMER_URGENT;
        llSetTimerEvent(updateInterval);
    }
    
    timer() {
        float elapsed = llGetAndResetTime();
        if (elapsed > updateInterval * 4) elapsed = updateInterval;
        currentGracePeriod -= llRound(elapsed);
        saveData();
        
        if (currentGracePeriod <= 0) {
            // Preserve renter info for notifications before clearing
            string tempRenterName = renterName;
            
            llInstantMessage(llGetOwner(), "Grace Period Ended: " + tempRenterName + " - Rental now available for new lease");
            sendEmail("Grace Period Ended", "Grace period ended for " + tempRenterName + ". Rental is now available for new lease.");
            
            renterID = NULL_KEY;
            renterName = "";
            rentalTime = 0.0;
            currentState = "idle";
            state idle;
        }
    }
    
    link_message(integer sender_num, integer num, string message, key id) {
        list parts = llParseString2List(message, ["^"], []);
        string command = llList2String(parts, 0);
        
        if (command == "Core:Touch") {
            key user = (key)llList2String(parts, 1);
            // Update grace period time on touch
            float elapsed = llGetAndResetTime();
            if (elapsed > updateInterval * 4) elapsed = updateInterval;
            currentGracePeriod -= llRound(elapsed);
            saveData();
            if (user == llGetOwner()) {
                llMessageLinked(LINK_SET, 0, "UI:ShowGraceDialog^" + getTimeString(currentGracePeriod), user);
            } else {
                llInstantMessage(user, "Grace period: " + getTimeString(currentGracePeriod));
            }
        } else if (command == "Core:Action") {
            processAction(llList2String(parts, 1), id, llList2String(parts, 2), num);
        } else if (command == "Core:ChangeState") {
            string newState = llList2String(parts, 1);
            if (newState == "rented") state rented;
            else if (newState == "idle") state idle;
            else if (newState == "locked") state locked;
        }
    }
    
    money(key id, integer amount) { processPayment(id, amount); }
}

state locked {
    state_entry() {
        currentState = "locked";
        dispString("Rental Box Locked");
        if (llGetObjectDesc() == "") {
            llSetTimerEvent(0);
        } else {
            updateInterval = getAdaptiveInterval(rentalTime);
            llSetTimerEvent(updateInterval);
        }
    }
    
    link_message(integer sender_num, integer num, string message, key id) {
        list parts = llParseString2List(message, ["^"], []);
        string command = llList2String(parts, 0);
        
        if (command == "Core:Touch") {
            key user = (key)llList2String(parts, 1);
            // Update rental time if there's an active rental
            if (rentalTime > 0) {
                float elapsed = llGetAndResetTime();
                if (elapsed > updateInterval * 4) elapsed = updateInterval;
                rentalTime -= elapsed;
                saveData();
                updateAdaptiveTimer();
            }
            if (user == llGetOwner()) {
                llMessageLinked(LINK_SET, 0, "UI:ShowUnlockDialog", user);
            } else {
                llInstantMessage(user, "Rental box locked by owner");
            }
        } else if (command == "Core:Action") {
            if (llList2String(parts, 1) == "Unlock") {
                if (rentalTime > 0) {
                    currentState = "rented";
                    state rented;
                } else {
                    currentState = "idle";
                    state idle;
                }
            } else {
                // Handle other actions that might need channel response
                processAction(llList2String(parts, 1), id, llList2String(parts, 2), num);
            }
        } else if (command == "Core:ChangeState") {
            string newState = llList2String(parts, 1);
            if (newState == "rented") state rented;
            else if (newState == "idle") state idle;
            else if (newState == "grace") state grace;
        }
    }
    
    timer() {
        float elapsed = llGetAndResetTime();
        if (elapsed > updateInterval * 4) elapsed = updateInterval;
        rentalTime -= elapsed;
        saveData();
        
        // Update timer interval based on remaining time
        updateAdaptiveTimer();
        
        if (rentalTime <= 0) {
            // Preserve renter info for notifications before clearing
            string tempRenterName = renterName;
            
            llInstantMessage(llGetOwner(), "Lease Expired (Locked): " + tempRenterName + " - Box remains locked");
            sendEmail("Lease Expired (Locked)", "Lease expired for " + tempRenterName + ". Rental box remains locked by owner.");
            
            rentalTime = 0;
            llSetObjectDesc("");
            llSetTimerEvent(0);
        }
    }
} 