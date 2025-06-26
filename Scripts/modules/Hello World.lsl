//Hello World Module v1.2 - Strict Channel Communication
//Demonstrates module basics with strict channel-only communication (no channel 0)

// Module information  
string MODULE_NAME = "Hello World";
list MODULE_CAPABILITIES = ["Example", "Learning"];

// Module communication channel (configurable)
integer moduleChannel = 0; // 0 = auto-assign random channel
integer assignedChannel = 0; // The actual channel we're using

// Module variables
integer listenHandle = 0;
integer clickCount = 0;

// Module channel management
assignModuleChannel() {
    if (moduleChannel == 0) {
        // Generate random channel between 1000 and 2147483647 (max positive integer)
        assignedChannel = 1000 + (integer)(llFrand(2147482647.0));
    } else {
        assignedChannel = moduleChannel;
    }
    
    llOwnerSay("Hello World: Using module channel " + (string)assignedChannel);
}

// Show owner menu with example options
showOwnerMenu(key userID) {
    list options = ["Say Hello", "Count Clicks", "Reset Count", "<< Back"];
    string text = "Hello World Module - Owner Menu\n";
    text += "This is an example module for learning.\n";
    text += "Current click count: " + (string)clickCount;
    
    llDialog(userID, text, options, -8675309);
    llListenRemove(listenHandle);
    listenHandle = llListen(-8675309, "", userID, "");
    llSetTimerEvent(30.0);
}

// Show renter menu with limited options
showRenterMenu(key userID) {
    list options = ["Say Hello", "View Count", "<< Back"];
    string text = "Hello World Module - Renter Menu\n";
    text += "Welcome, renter! This is a demo module.\n";
    text += "Total clicks so far: " + (string)clickCount;
    
    llDialog(userID, text, options, -8675309);
    llListenRemove(listenHandle);
    listenHandle = llListen(-8675309, "", userID, "");
    llSetTimerEvent(30.0);
}

// Example function - say hello to user
sayHello(key userID) {
    string name = llKey2Name(userID);
    if (name == "") name = "Unknown User";
    
    clickCount++;
    
    list greetings = [
        "Hello there, " + name + "!",
        "Greetings, " + name + "!",
        "Welcome to the Hello World module, " + name + "!",
        "Nice to see you, " + name + "!",
        "Hi " + name + ", thanks for trying the demo!"
    ];
    
    integer randomIndex = llFloor(llFrand(llGetListLength(greetings)));
    string greeting = llList2String(greetings, randomIndex);
    
    llInstantMessage(userID, greeting);
    llOwnerSay("Hello World: " + name + " was greeted (click #" + (string)clickCount + ")");
}

default {
    state_entry() {
        //sleeps for 1 second on rez or reset to allow the module_manager script to fully come on line and avoid clobbering.
        //Sleep timer is a precaution but not necessary, and I'd remove it if your module reads from notecards or implements any features that cause delays on rez or reset (IM, email, etc)
        llSleep(1.0);
        assignModuleChannel();
        // Register this module - send on channel 0 so all scripts receive it
        llMessageLinked(LINK_SET, 0, "Module:Register^" + MODULE_NAME + "^" + llDumpList2String(MODULE_CAPABILITIES, ",") + "^" + (string)assignedChannel, NULL_KEY);
        llOwnerSay("Hello World Module v1.2: Ready for strict channel communication on channel " + (string)assignedChannel + "!");
        
        // Initialize click counter
        clickCount = 0;
    }
    
    link_message(integer sender_num, integer num, string message, key id) {
        // Only process messages on our assigned channel (strict channel mode)
        if (num != assignedChannel) return;
        // Parse the incoming message
        list parts = llParseString2List(message, ["^"], []);
        string command = llList2String(parts, 0);
        
        // Handle module discovery - re-register when requested
        if (command == "Module:Discover") {
            llMessageLinked(LINK_SET, 0, "Module:Register^" + MODULE_NAME + "^" + llDumpList2String(MODULE_CAPABILITIES, ",") + "^" + (string)assignedChannel, NULL_KEY);
        }
        // Handle module routing - user selected this module
        else if (command == "Module:Route" && llList2String(parts, 1) == MODULE_NAME) {
            string action = llList2String(parts, 2);
            
            if (action == "ShowMenu") {
                // User wants to see this module's menu
                // First, check what role they have (owner/renter/other) - use our channel for response
                llMessageLinked(LINK_SET, assignedChannel, "Core:Action^CheckUserRole^" + (string)id, NULL_KEY);
            }
        }
        // Handle user role response from core
        else if (command == "Core:UserRole") {
            string role = llList2String(parts, 1);
            key userID = (key)llList2String(parts, 2);
            
            // Show appropriate menu based on user role
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
    }
    
    // Handle dialog responses
    listen(integer channel, string name, key id, string message) {
        if (channel == -8675309) {
            // Clean up the listener
            llListenRemove(listenHandle);
            listenHandle = 0;
            llSetTimerEvent(0);
            
            // Process the user's choice
            if (message == "Say Hello") {
                sayHello(id);
            }
            else if (message == "Count Clicks") {
                llInstantMessage(id, "Hello World Module: Total clicks recorded: " + (string)clickCount);
            }
            else if (message == "View Count") {
                llInstantMessage(id, "Hello World Module: You can see that " + (string)clickCount + " greetings have been given!");
            }
            else if (message == "Reset Count") {
                clickCount = 0;
                llInstantMessage(id, "Hello World Module: Click counter reset to zero.");
                llOwnerSay("Hello World: Click counter was reset by " + llKey2Name(id));
            }
            else if (message == "<< Back") {
                // Return to the modules menu
                llMessageLinked(LINK_SET, 0, "UI:ShowModulesMenu", id);
            }
        }
    }
    
    // Handle timer events (cleanup expired dialogs)
    timer() {
        if (listenHandle != 0) {
            llListenRemove(listenHandle);
            listenHandle = 0;
            llSetTimerEvent(0);
        }
    }
    
    // Handle script reset
    on_rez(integer start_param) {
        llResetScript();
    }
} 