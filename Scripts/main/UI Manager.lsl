//UI Manager Script v2.0 - Memory Optimized with Module Pagination
//Handles all dialog interactions and user interface logic with pagination support

// Constants
integer DIALOG_CHANNEL_BASE = 1000000;
integer LISTEN_TIMEOUT = 300; // 5 minutes

// Variables
integer listenQueryID;
integer currentDialogChannel; // Track current dialog channel
string lastMenuContext = "";
key lastMenuUser = NULL_KEY;

// Module pagination variables
integer currentModulePage = 0;
integer totalModulePages = 0;
integer totalModules = 0;

// Core rental data (received from Rental Core)
string tierName;
integer rentalCost;
integer primCount;
integer rentalVolume;
integer refundsEnabled;
integer refundFee; // Add refund fee variable
key renterID;
string renterName;
float rentalTime;
string infoNotecard;
integer floatingTextEnabled = 0;

// Functions
integer setupDialogListen() {
    currentDialogChannel = DIALOG_CHANNEL_BASE + (integer)llFrand(999999);
    llListenRemove(listenQueryID);
    listenQueryID = llListen(currentDialogChannel, "", NULL_KEY, "");
    return currentDialogChannel;
}

requestRentalData() {
    llMessageLinked(LINK_SET, 0, "UI:RequestData", NULL_KEY);
}

string getTimeString(integer time) {
    integer days = llRound(time / 86400);
    time = time % 86400;
    integer hours = (time / 3600);
    time = time % 3600;
    integer minutes = time / 60;
    return (string)days + " days, " + (string)hours + " hours, " + (string)minutes + " minutes";
}

dispData() {
    llSay(0, "========================");
    llSay(0, "Rental Space Information");
    llSay(0, "========================");
    if (renterName != "") {
        llSay(0, "This space is currently leased by " + renterName);
        llSay(0, "This space will be open for lease in " + getTimeString(llRound(rentalTime)) + ".");
    } else {
        llSay(0, "This space is available for lease.");
    }
    llSay(0, "The current rental price is L$" + (string)rentalCost + " per week.");
    llSay(0, "The current parcel size is " + (string)rentalVolume + " and the Prim Count is " + (string)primCount + ".");
}

showOwnerMenuIdle(key id) {
    list options = ["Info", "Reset", "SpecifyRenter", "Lock", "Unavailable", "Modules"];
    lastMenuContext = "owner_idle";
    lastMenuUser = id;
    
    llDialog(id, "Owner Options:\n\n" +
        "- Specify Renter: Reserve for a specific Avatar.\n" +
        "- Info: Receive Info Note.\n" +
        "- Reset: Reset the rental box.\n" +
        "- Lock: Marks Rental box as Locked.\n" +
        "- Unavailable: Marks Rental box as Unavailable.\n" +
        "Please select an option below:", options, setupDialogListen());
}

showOwnerMenuRented(key id) {
    list options = ["Info", "Release", "Reset", "Lock", "Unavailable", "Modules"];
    if (refundsEnabled) {
        options += "Refund";
    }
    
    lastMenuContext = "owner_rented";
    lastMenuUser = id;
    
    llDialog(id, "Lease Options. Select one of the options below...", options, setupDialogListen());
}

showRenterMenu(key id) {
    list options = ["Info"];
    options += "Manage Lease";
    options += "Modules";
    
    lastMenuContext = "renter";
    lastMenuUser = id;
    
    llDialog(id, "Lease Options. Select one of the options below...", options, setupDialogListen());
}

showSpecificRenterDialog(key id) {
    lastMenuContext = "specific_renter";
    lastMenuUser = id;
    
    llTextBox(id, "Please enter the name of the specific renter in the text box below.\n\nClick 'Submit' to set the renter or 'Cancel' to abort.", setupDialogListen());
}

showModulesMenu(key id) {
    lastMenuContext = "modules";
    lastMenuUser = id;
    currentModulePage = 0; // Reset to first page
    
    // Request module list from Module Manager (page 0)
    llMessageLinked(LINK_SET, 0, "Module:GetList^0", id);
}

showManageLeaseMenu(key id) {
    list options = [];
    if (refundsEnabled) {
        options += "Req.Refund";
    }
    options += "End Lease (No Refund)";
    options += "<< Back";
    
    string dialogText = "Manage Your Lease:\n\n";
    if (refundsEnabled) {
        dialogText += "• Request Refund: End your lease and request a refund (L$" + (string)refundFee + " fee). The owner will review your request.\n\n";
    }
    dialogText += "• End Lease (No Refund): End your lease immediately with no refund.\n\n";
    dialogText += "Please select an option:";
    
    lastMenuContext = "manage_lease";
    lastMenuUser = id;
    
    llDialog(id, dialogText, options, setupDialogListen());
}

processMenuSelection(key id, string message) {
    // Common actions first
    if (message == "Info") {
        dispData();
        llGiveInventory(id, infoNotecard);
        llMessageLinked(LINK_SET, 0, "Core:Action^Info^" + (string)id, NULL_KEY);
        cleanupListeners();
        return;
    }
    
    if (message == "Reset") {
        llMessageLinked(LINK_SET, 0, "Core:Action^Reset^" + (string)id, NULL_KEY);
        cleanupListeners();
        return;
    }
    
    // Context-specific actions
    if (lastMenuContext == "owner_idle") {
        if (message == "SpecifyRenter") {
            showSpecificRenterDialog(id);
        } else if (message == "Lock") {
            llMessageLinked(LINK_SET, 0, "Core:Action^Lock^" + (string)id, NULL_KEY);
            cleanupListeners();
        } else if (message == "Unavailable") {
            llMessageLinked(LINK_SET, 0, "Core:Action^Unavailable^" + (string)id, NULL_KEY);
            cleanupListeners();
        } else if (message == "Modules") {
            showModulesMenu(id);
        }
    } else if (lastMenuContext == "owner_rented") {
        if (message == "Release") {
            llDialog(id, "Are you sure you want to TERMINATE this lease with NO REFUND?", ["Yes", "No"], setupDialogListen());
            lastMenuContext = "confirm_release";
            lastMenuUser = id;
            // Don't cleanup listeners here - wait for confirmation response
        } else if (message == "Refund") {
            llMessageLinked(LINK_SET, 0, "Core:Action^Refund^" + (string)id, NULL_KEY);
            cleanupListeners();
        } else if (message == "Lock") {
            llMessageLinked(LINK_SET, 0, "Core:Action^Lock^" + (string)id, NULL_KEY);
            cleanupListeners();
        } else if (message == "Unavailable") {
            llMessageLinked(LINK_SET, 0, "Core:Action^Unavailable^" + (string)id, NULL_KEY);
            cleanupListeners();
        } else if (message == "Modules") {
            showModulesMenu(id);
        }
    } else if (lastMenuContext == "renter") {
        if (message == "Manage Lease") {
            showManageLeaseMenu(id);
        } else if (message == "Modules") {
            showModulesMenu(id);
        }
    } else if (lastMenuContext == "confirm_refund") {
        if (message == "YES") {
            llMessageLinked(LINK_SET, 0, "Core:Action^ConfirmRefund^" + (string)id, NULL_KEY);
        }
        cleanupListeners();
        // If "NO", just ignore and let dialog timeout
    } else if (lastMenuContext == "confirm_release") {
        if (message == "Yes") {
            llMessageLinked(LINK_SET, 0, "Core:Action^Release^" + (string)id, NULL_KEY);
        } else if (message == "No") {
            // Return to rented menu
            llMessageLinked(LINK_SET, 0, "Core:Touch^" + (string)id, NULL_KEY);
        }
        cleanupListeners();
        // If neither, just ignore and let dialog timeout
    } else if (lastMenuContext == "confirm_unlock") {
        if (message == "Yes") {
            llMessageLinked(LINK_SET, 0, "Core:Action^Unlock^" + (string)id, NULL_KEY);
        }
        cleanupListeners();
        // If "No", just ignore and let dialog timeout
    } else if (lastMenuContext == "grace_options") {
        if (message == "Cancel Grace") {
            llDialog(id, "Are you sure you want to CANCEL the grace period and terminate the lease?", ["Yes", "No"], setupDialogListen());
            lastMenuContext = "confirm_cancel_grace";
            // Don't cleanup listeners here - wait for confirmation response
        } else if (message == "Info") {
            llMessageLinked(LINK_SET, 0, "Core:Action^Info^" + (string)id, NULL_KEY);
            cleanupListeners();
        }
        // If "Close", just ignore and let dialog timeout
    } else if (lastMenuContext == "confirm_cancel_grace") {
        if (message == "Yes") {
            llMessageLinked(LINK_SET, 0, "Core:Action^CancelGrace^" + (string)id, NULL_KEY);
        }
        cleanupListeners();
        // If "No", just ignore and let dialog timeout
    } else if (lastMenuContext == "specific_renter") {
        if (message == "Cancel") {
            llMessageLinked(LINK_SET, 0, "Core:Action^CancelSpecificRenter^" + (string)id, NULL_KEY);
            cleanupListeners();
        } else {
            // Handle text input from llTextBox
            if (message != "") {
                llMessageLinked(LINK_SET, 0, "Core:Action^SetSpecificRenter^" + message, id);
            }
            cleanupListeners();
        }
    } else if (lastMenuContext == "specific_renter_options") {
        if (message == "Info") {
            dispData();
            llGiveInventory(id, infoNotecard);
            llMessageLinked(LINK_SET, 0, "Core:Action^Info^" + (string)id, NULL_KEY);
            cleanupListeners();
        } else if (message == "Reset") {
            llMessageLinked(LINK_SET, 0, "Core:Action^Reset^" + (string)id, NULL_KEY);
            cleanupListeners();
        } else if (message == "Cancel Specific Renter") {
            llMessageLinked(LINK_SET, 0, "Core:Action^CancelSpecificRenter^" + (string)id, NULL_KEY);
            cleanupListeners();
        }
    } else if (lastMenuContext == "modules") {
        if (message == "<< Back") {
            // Return to appropriate owner menu based on current state
            llMessageLinked(LINK_SET, 0, "Core:Touch^" + (string)id, NULL_KEY);
        } else if (message == "<< Previous") {
            // Go to previous page
            currentModulePage--;
            if (currentModulePage < 0) currentModulePage = 0;
            llMessageLinked(LINK_SET, 0, "Module:GetList^" + (string)currentModulePage, id);
        } else if (message == "Next >>") {
            // Go to next page
            currentModulePage++;
            if (currentModulePage >= totalModulePages) currentModulePage = totalModulePages - 1;
            llMessageLinked(LINK_SET, 0, "Module:GetList^" + (string)currentModulePage, id);
        } else {
            // Route to specific module via Module Manager
            llMessageLinked(LINK_SET, 0, "Module:Request^" + message + "^ShowMenu", id);
        }
    } else if (lastMenuContext == "manage_lease") {
        if (message == "Request Refund") {
            llMessageLinked(LINK_SET, 0, "Core:Action^Refund", id);
            cleanupListeners();
        } else if (message == "End Lease (No Refund)") {
            llDialog(id, "Are you sure you want to END your lease with NO REFUND? This action cannot be undone.", ["Yes, End Lease", "Cancel"], setupDialogListen());
            lastMenuContext = "confirm_end_lease";
            lastMenuUser = id;
            // Don't cleanup listeners here - wait for confirmation response
        } else if (message == "<< Back") {
            llMessageLinked(LINK_SET, 0, "Core:Touch^" + (string)id, NULL_KEY);
            cleanupListeners();
        }
    } else if (lastMenuContext == "confirm_end_lease") {
        if (message == "Yes, End Lease") {
            llMessageLinked(LINK_SET, 0, "Core:Action^Release^" + (string)id, NULL_KEY);
        }
        cleanupListeners();
        // If "Cancel", just ignore and let dialog timeout
    }
}

cleanupListeners() {
    llListenRemove(listenQueryID);
    llSetTimerEvent(0);
}

default {
    state_entry() {
        requestRentalData();
    }
    
    touch_start(integer num_detected) {
        integer x;
        for (x = 0; x < num_detected; x++) {
            key detectedKey = llDetectedKey(x);
            llMessageLinked(LINK_SET, 0, "Core:Touch^" + (string)detectedKey, NULL_KEY);
        }
    }
    
    listen(integer channel, string name, key id, string message) {
        if (channel >= DIALOG_CHANNEL_BASE) {
            // Handle all other menu selections normally
            processMenuSelection(id, message);
            // Cleanup is now handled within processMenuSelection based on context
        }
    }
    
    link_message(integer sender_num, integer num, string message, key id) {
        list parts = llParseString2List(message, ["^"], []);
        string command = llList2String(parts, 0);
        
        if (command == "UI:UpdateData") {
            // Receive rental data from core
            tierName = llList2String(parts, 1);
            rentalCost = (integer)llList2String(parts, 2);
            primCount = (integer)llList2String(parts, 3);
            rentalVolume = (integer)llList2String(parts, 4);
            refundsEnabled = (integer)llList2String(parts, 5);
            renterID = (key)llList2String(parts, 6);
            renterName = llList2String(parts, 7);
            rentalTime = (float)llList2String(parts, 8);
            infoNotecard = llList2String(parts, 9);
            floatingTextEnabled = (integer)llList2String(parts, 10);
            refundFee = (integer)llList2String(parts, 11);
        }
        else if (command == "UI:ShowOwnerMenuIdle") {
            showOwnerMenuIdle(id);
        }
        else if (command == "UI:ShowOwnerMenuRented") {
            showOwnerMenuRented(id);
        }
        else if (command == "UI:ShowRenterMenu") {
            showRenterMenu(id);
        }
        else if (command == "UI:ShowConfirmRefund") {
            string refundFee = llList2String(parts, 1);
            llDialog(id, "Are you sure you want to TERMINATE your lease and refund your money, minus a L$" + refundFee + " fee?", ["YES", "NO"], setupDialogListen());
            lastMenuContext = "confirm_refund";
            lastMenuUser = id;
        }
        else if (command == "UI:Message") {
            string messageText = llList2String(parts, 1);
            if (id != NULL_KEY) {
                llInstantMessage(id, messageText);
            } else {
                llSay(0, messageText);
            }
        }
        else if (command == "UI:ShowSpecificRenterOptions") {
            list options = ["Info", "Reset", "Cancel Specific Renter"];
            llDialog(id, "Owner Options:\n\n- Reset: Reset the rental box.\n- Cancel Specific Renter: Remove the restriction for a specific renter.\n\nPlease select an option below:", options, setupDialogListen());
            lastMenuContext = "specific_renter_options";
            lastMenuUser = id;
        }
        else if (command == "UI:ShowUnlockDialog") {
            llDialog(id, "Unlock this rental box?", ["Yes", "No"], setupDialogListen());
            lastMenuContext = "confirm_unlock";
            lastMenuUser = id;
        }
        else if (command == "UI:ShowGraceDialog") {
            string graceTime = llList2String(parts, 1);
            llDialog(id, "Grace Period Active\nRemaining: " + graceTime + "\n\nOptions:", ["Cancel Grace", "Info", "Close"], setupDialogListen());
            lastMenuContext = "grace_options";
            lastMenuUser = id;
        }
        else if (command == "UI:ShowModulesMenu") {
            showModulesMenu(id);
        }
        else if (command == "Module:List") {
            string moduleList = llList2String(parts, 1);
            currentModulePage = (integer)llList2String(parts, 2);
            totalModulePages = (integer)llList2String(parts, 3);
            totalModules = (integer)llList2String(parts, 4);
            
            if (moduleList == "") {
                llInstantMessage(lastMenuUser, "No modules available.");
                return;
            }
            
            list modules = llParseString2List(moduleList, [","], []);
            list options = modules;
            
            // Add navigation buttons if needed
            if (currentModulePage > 0) {
                options += ["<< Previous"];
            }
            if (currentModulePage < totalModulePages - 1) {
                options += ["Next >>"];
            }
            options += ["<< Back"];
            
            // Build dialog text with page info
            string dialogText = "Available Modules:";
            if (totalModulePages > 1) {
                dialogText += "\n\nPage " + (string)(currentModulePage + 1) + " of " + (string)totalModulePages;
                dialogText += " (" + (string)totalModules + " total modules)";
            }
            
            llDialog(lastMenuUser, dialogText, options, setupDialogListen());
        }
    }
    
    timer() {
        // Cleanup expired listeners
        cleanupListeners();
    }
} 