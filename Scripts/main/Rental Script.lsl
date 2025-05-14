//Rental Mesh Script v2.3.b - Wolf Starforge 8/12/2024
//This script is provided Open Source and was a fork of a fork of a fork of a script originally created by Hank Ramos.
//This script is still provided full perm and Open Source. Any textures or meshes provided with this script are also considered the same.
//For notes and previous contributors to the Hank Ramos rental box system before it was forked, see notes contained in the RentalBox version.

//  - Easy setup via Notecard. Clean notecard reading to prevent errors because you added a space somewhere or hit enter.
//  - Optional Grace period: Set grace period in Hours or don't use
//  - lock and unavailable options: These do the same thing but allow for a different graphic/linked message. lock the box and prevent payment or refunds.
//  - allow payment from same group or payment by owner: Rental box and person paying must have the correct group enabled.
//      - Obviously refunds can't be given to anyone except the actual renter. Enable at your own risk. 
//  - Email payment and other events for easy tracking.
//  - "Easily" (depending on your own photoshop skills) make custom textures for the mesh rental system
//  - Option to turn floating text on or off
//  - auto invite to group after someone pays the rental box. This requires the group be open to join and basically provides a link.
//      - What I do is set my group to open with 'Everyone' having no permissions except set home point. I log in asap to give the renter a Tenant role.
//      - This can be turned off (comment it out) to save memory if you won't need this function. I may separate this into it's own script in a future version
//  - Reset Rental script without losing any renter info
//  - Ability to allow for refunds with a percentage fee, no fee, or no refunds
//  - Supports use of multiple notecards getting handed out. Use or don't use the ones you need
//  - Open Source: make any changes you need
//  - Other features i'm sure I've forgotten



//Use notecard named "Settings" to change rental variables. Be sure to reset the rental box afterwards!
//Add a notecard named "Rental Info" to give rental information/rules to tenants.
//Add a texture named "rentthisspace" for unrented texture.
//Add a texture named "infosign" for rented texture.

//Options
string myGroupName;
string myGroupID;
float  updateInterval = 60.0; //seconds
string infoNotecard   = "Rent This Space Info";
string emailForNotifications = "";
string configNotecardName = "_Settings";
string welcomeNotecard;

string  tierName;
integer rentalCost;
float discountPercent = 0.0; // default is 0.0 for no discount. set in the settings notcard to change this.
integer primCount;
integer rentalVolume;
integer refundsEnabled = 0;
integer refundFee;
key     renterID;
string  renterName;
float   rentalTime;
integer listenQueryID;
vector  initPos;    //Position when unrented
vector  initScale; //Scale when unrented
integer count;
integer lineCount;
key     readKey;
integer floatingTextEnabled = 0; // Default is 0 (false)
integer gracePeriod; //Grace Period in seconds
integer currentGracePeriod;
integer allowOwnerPayment;
integer allowGroupPayment;
//Constants
float ONE_WEEK = 604800.0;
float _48_HOURS  = 172800.0;//2*24*3600
float _24_HOURS  = 86400.0;//24*3600
float _6_HOURS=21600.0;//6*3600
float _1_HOUR = 3600.0;//60*60
float discountTime;

// Function to print available memory for debugging
//printMemory(string context) {
//    llOwnerSay("Memory available at " + context + ": " + (string)llGetFreeMemory() + " bytes");
//}


// Function to send a linked message to other scripts in the link set

sendLinkedMessage(string message) {
    llMessageLinked(LINK_SET, 0, message, NULL_KEY);
}

sendEmailNotification(string subject, string message) {
    if (emailForNotifications != "") {
        llEmail(emailForNotifications, subject, message);
    } else {
        //comment this out if you have no intention of using this feature
        llOwnerSay("Email for notifications is not configured.");
    }
}

sendGroupJoinDialog(key avatarID, string groupName, string groupID) {
 if(groupID != "" && groupID != "00000000-0000-0000-0000-000000000000") { // Check if groupID is set
        string dialogText = "Thank you for your payment! Click the link below to join " + groupName + ": \nsecondlife:///app/group/" + groupID + "/about";
        llInstantMessage(avatarID, "Click this link to join the group and access your rented property! Link: secondlife:///app/group/" + groupID + "/about"); 
        llDialog(avatarID, dialogText, ["OK"], -8675309); // Use a unique channel number
    } else {
        //comment this out if you have no intention of using this feature
        llOwnerSay("Group joining feature is not configured.");
    }
}



dispString(string value)
{
    if (floatingTextEnabled == 1) {
        llSetText(value, <1, 1, 1>, 1);
    } else{
        llSetText("", ZERO_VECTOR, 1.0);
    }
}
sendReminder(string message)
{ 
    llInstantMessage(renterID, "Current date and time: "+llGetTimestamp()+"\n"+"Your lease located in " + llGetRegionName() + " (" + (string)initPos.x + "," + (string)initPos.y + "," + (string)initPos.z + ") will expire " + message);
    sendEmailNotification("Reminder sent for" + renterName, "Current date and time: "+llGetTimestamp()+"\n"+"Your lease located in " + llGetRegionName() + " (" + (string)initPos.x + "," + (string)initPos.y + "," + (string)initPos.z + ") will expire " + message);

}
saveData()
{
    list saveData;
    vector storageVector;
    if (renterID != NULL_KEY) { // Check if the box is rented
        saveData += renterID;
        saveData += renterName;
    }
    saveData += llRound(rentalTime);
    llSetObjectDesc(llDumpList2String(saveData, "^"));
    sendLinkedMessage("Mesh:Update^" + (string)llRound(rentalTime));
    //printMemory("state_entry of default");
}
parseSavedData() {
    string desc = llGetObjectDesc();
    list parsedData = llParseString2List(desc, ["^"], []);
    // Assuming renterID is first, rentalTime is second in the saved description
    if (llList2String(parsedData, 0) != "") {
        renterID = llList2Key(parsedData, 0);
        renterName = llList2String(parsedData, 1);
        rentalTime = llList2Float(parsedData, 2);
    } else {
        // Handle the case where these values are not set (e.g., box is unrented)
        renterID = NULL_KEY;
        renterName = "";
        rentalTime = 0.0;
    }
}

string getTimeString(integer time)
{
    integer days;
    integer hours;
    integer minutes; 
    integer seconds;
    
    days = llRound(time / 86400);
    time = time % 86400;
    
    hours = (time / 3600);
    time  = time % 3600;

    minutes = time / 60;
    time    = time % 60;

    seconds = time;
    
    return (string)days + " days, " + (string)hours + " hours, " + (string)minutes + " minutes"; // + ":" + (string)seconds; 
}

integer setupDialogListen()
{
    integer chatChannel = (integer)llFrand(2000000);
    llListenRemove(listenQueryID);
    listenQueryID = llListen(chatChannel, "", NULL_KEY, "");
    return chatChannel;
}

updateTimeDisp()
{ 
    dispString("Leased by: " + renterName + "\nTime Remaining: " + getTimeString(llRound(rentalTime)));   
}

dispData()
{
    llSay(0, "========================");
    llSay(0, "Rental Space Information");
    llSay(0, "========================");
    llSay(0, "This space is currently leased by " + renterName);
    llSay(0, "The current rental price is L$" + (string)((integer)rentalCost) + " per week.");
    llSay(0, "The current parcel size is " + (string)rentalVolume + " and the Prim Count is " + (string)primCount + ".");
    llSay(0, "This space will be open for lease in " + getTimeString(llRound(rentalTime)) + "."); 
    //llSay(0, "Memory Free: " + (string)llGetFreeMemory());
}
default
{
    state_entry()
    {
        initPos = llGetPos();
        initScale = llGetScale();
        state initialize;
    }
}

state initialize
{
    state_entry()
    {
        llSetTimerEvent(300);
        llOwnerSay("Waiting to obtain Debit Permissions.");
        llRequestPermissions(llGetOwner(), PERMISSION_DEBIT);
    }
    run_time_permissions(integer permissions)
    {
        //Only wait for payment if the owner agreed to pay out money
        if (permissions & PERMISSION_DEBIT)
        {
            state loadSettings;
        }
    }    
    on_rez(integer start_param)
    {
        llResetScript();
    } 
    timer()
    {
        llRequestPermissions(llGetOwner(), PERMISSION_DEBIT);
    }
    touch_start(integer total_number)
    {
        integer x;
        for (x = 0; x < total_number; x += 1)
        {
            if (llDetectedKey(x) == llGetOwner())
            {
                llResetScript();
            }
        }
        llSay(0, "Waiting to obtain Debit Permissions from Owner.");
    }
    state_exit()
    {
        llSetTimerEvent(0);
        llSay(0, "Initialized.");
    }
}

state loadSettings
{
    state_entry()
    {
        integer found = FALSE;
        integer x;
        
        count = 0;
        lineCount = 0;
        for (x = 0; x < llGetInventoryNumber(INVENTORY_NOTECARD); x += 1)
        {
            if (llGetInventoryName(INVENTORY_NOTECARD, x) == configNotecardName)
            {
                found = TRUE; 
            }
        }
        if (found)
        {
            llOwnerSay("Reading Settings Notecard...");
            readKey = llGetNotecardLine(configNotecardName, lineCount); 
        }
        else
        {
            llOwnerSay("Settings Notecard Not Found.");
            llResetScript();
        }
    }
    dataserver(key requested, string data) {
        if (requested == readKey) {
            if (data != EOF) {
                // Ignore comments and empty lines
                string trimmedData = llStringTrim(data, STRING_TRIM);
                if (llGetSubString(trimmedData, 0, 0) != "#" && trimmedData != "") {
                    list tokens = llParseString2List(trimmedData, [":"], []);
                    string setting = llStringTrim(llList2String(tokens, 0), STRING_TRIM);
                    string value = llStringTrim(llList2String(tokens, 1), STRING_TRIM);

                    // Process each setting
                    if (setting == "Spot Name") {
                        tierName = value;
                    } else if (setting == "Rental Cost") {
                        rentalCost = (integer)value;
                    } else if (setting == "Discount Percent") {
                        discountPercent = (float)value;
                    } else if (setting == "Prim Count") {
                        primCount = (integer)value;
                    } else if (setting == "Rental Size") {
                        rentalVolume = (integer)value;
                    } else if (setting == "Refunds Enabled") {
                        refundsEnabled = (integer)value;
                    } else if (setting == "Refund Fee") {
                        refundFee = (integer)value;
                    } else if (setting == "Info Notecard Name") {
                        infoNotecard = value;
                    } else if (setting == "Floating Text Enabled") {
                        floatingTextEnabled = (integer)value;
                    } else if (setting == "Email for Notifications") {
                        emailForNotifications = value;
                    }else if (setting == "Welcome Notecard") {
                        welcomeNotecard = value;
                    }else if (setting == "Group Name") {
                        myGroupName = value;
                    }else if (setting == "Group UUID") {
                        myGroupID = value;
                    }else if (setting == "Grace Period") {
                        gracePeriod = (integer)value * 3600; // Convert hours to seconds
                    } else if (setting == "Allow Owner Payment") {
                        allowOwnerPayment = (integer)value;
                    } else if (setting == "Allow Group Payment") {
                        allowGroupPayment = (integer)value;
                    //Mesh Textures
                    }else if (setting == "For Rent Texture") {
                        sendLinkedMessage("Mesh:SetForRentTexture^" + value);
                    } else if (setting == "Rented Texture") {
                        sendLinkedMessage("Mesh:SetRentedTexture^" + value);
                    } else if (setting == "Overdue Texture") {
                        sendLinkedMessage("Mesh:SetOverdueTexture^" + value);                        
                    } else if (setting == "Locked Texture") {
                        sendLinkedMessage("Mesh:SetLockedTexture^" + value);
                    } else if (setting == "Unavailable Texture") {
                        sendLinkedMessage("Mesh:SetUnavailableTexture^" + value);
                    }else if (setting == "Mesh:Reserved Texture") {
                        sendLinkedMessage("Mesh:SetReservedTexture^" + value);
                    } else if (setting == "Mesh Alpha") {
                        sendLinkedMessage("Mesh:SetAlpha^" + value);
                    } else if (setting == "Mesh Glow") {
                        sendLinkedMessage("Mesh:SetGlow^" + value);
                    }// Add additional else if clauses for other settings as needed
                }
                // Proceed to the next line
                lineCount++;
                readKey = llGetNotecardLine(configNotecardName, lineCount);
            }
            else {
                // Finished reading the notecard
                if (allowOwnerPayment == 1 || allowGroupPayment == 1) {
                    refundsEnabled = 0;
                    llOwnerSay("Owner or Group Payment is enabled: disabling refunds for security.");
                }
                llOwnerSay("Settings Loaded");
                if(llGetObjectDesc() != "") {
                    parseSavedData();
                }
               // Perform any actions needed after settings are loaded, such as initializing the rental system
                if (rentalTime > 0 && renterID != NULL_KEY) {
                    // Conditions for being considered rented are met
                    llOwnerSay("box is rented, moving to state rented");
                    integer fourweekdiscount = (integer)(((float)rentalCost * 4.0) * (discountPercent / 100.0));
                    integer fourweekrentalprice = (integer)(((float)rentalCost * 4.0) - fourweekdiscount);
                    llSetPayPrice((integer)rentalCost, [ (integer)(rentalCost * 1.0), (integer)(rentalCost * 2.0), (integer)(rentalCost * 3.0), (integer)fourweekrentalprice]);
                    llSetTimerEvent(updateInterval);
                    state rented;
                } else {
                    // Not rented or conditions not met
                    llOwnerSay("box is NOT rented, moving to state idle");
                    state idle;
                    }
            }
            
        }
    }
}

state idle
{
    state_entry()
    {        
        llSetObjectDesc("");
        sendLinkedMessage("Mesh:Idle");
        integer fourweekdiscount = (integer)(((float)rentalCost * 4.0) * (discountPercent / 100.0));
        integer fourweekrentalprice = (integer)(((float)rentalCost * 4.0) - fourweekdiscount);
        llSetPayPrice((integer)rentalCost, [ (integer)(rentalCost * 1.0), (integer)(rentalCost * 2.0), (integer)(rentalCost * 3.0), (integer)fourweekrentalprice]);
        llSetTimerEvent(updateInterval);

        dispString(tierName + "\nLease this space for L$" + (string)llRound(rentalCost) + " per week.\n" + (string)rentalVolume + " sq meters\n" + (string)primCount + " prims\nPay this Sign to begin your lease.");
        //printMemory("state_entry of default");
    }
    touch_start(integer num_detected)
    {
        integer x;
        integer chatChannel;

        for (x = 0; x < num_detected; x += 1) {
            if (llDetectedKey(x) == llGetOwner()) {
                list options = ["Info", "Reset", "Rented Position", "SpecifyRenter", "Lock", "Unavailable"];
                llDialog(llGetOwner(), "Owner Options:\n\n" +
                    "- Specificy Renter: Reserve for a specific Avatar.\n" +
                    "- Info: Receive Info Note.\n" +
                    "- Reset: Reset the rental box.\n" +
                    "- Rented Position: Edit the Rented position of the rental box when rented.\n" +
                    "- Lock: Marks Rental box as Locked.\n" +
                    "- Unavailable: Marks Rental box as Unavailable.\n" +
                    "Please select an option below:", options, setupDialogListen());
                return;
            }
        }

        llSay(0, "Lease this space for L$" + (string)llRound(rentalCost) + " per week. " + (string)rentalVolume + " sq meters. " + (string)primCount + " prims. Pay this Sign to begin your lease.");

        for (x = 0; x < num_detected; x += 1) {
            llGiveInventory(llDetectedKey(x), infoNotecard);
        }
    }
    listen(integer channel, string name, key id, string message)
    {   
        if (message == "Reset")
        {
            llResetScript();
        }
        else if (message == "Info")
        {
            llListenRemove(listenQueryID);
            dispData();
            llSay(0, "Lease this space for L$" + (string)llRound(rentalCost) + " per week. " + (string)rentalVolume + " sq meters. " + (string)primCount + " prims. Pay this Sign to begin your lease.");
            llGiveInventory(id, infoNotecard);
        }
        else if (message == "SpecifyRenter")
        {
            state idle_SpecificRenter;
        }
        else if (message == "Lock")
        {
            sendLinkedMessage("Mesh:Locked");
            state locked;
        }
        else if (message == "Unavailable")
        {
            sendLinkedMessage("Mesh:Unavailable");
            state locked;
        }
    }    
    money(key id, integer amount)
    {
        if (amount >= rentalCost)
        {
            renterID   = id;
            renterName = llKey2Name(renterID);
            integer fourweekdiscount = (integer)(((float)rentalCost * 4.0) * (discountPercent / 100.0));
            integer fourweekrentalprice = (integer)(((float)rentalCost * 4.0) - fourweekdiscount);
            if (fourweekrentalprice == amount)
            {
                rentalTime = ONE_WEEK * (rentalCost * 4) / rentalCost;
                discountTime = rentalTime;
            }
            else
            {
                rentalTime = ONE_WEEK * amount / rentalCost;
                discountTime = 0;
            }

            saveData();
            
            llSay(0, "Thank you " + renterName + " for leasing!  Your lease will expire in " + getTimeString((integer)rentalTime) + ".");
            if(welcomeNotecard != ""){
                llGiveInventory(id, welcomeNotecard);
            }
            sendGroupJoinDialog(id, myGroupName, myGroupID);
            state rented;
        }
        else
        {
            llSay(0, "This space costs L$" + (string)rentalCost + " to rent. Refunding paid balance.");
            llGiveMoney(id, amount);
        }
    }
}

state rented
{
    state_entry()
    { 
        updateTimeDisp();
        llResetTime();
        llSetTimerEvent(updateInterval);
        llInstantMessage(llGetOwner(), "Rental Confirmed: " + renterName + " has rented the space for " + (string)rentalTime + " seconds.");
        sendEmailNotification("Rental Confirmed", "The space has been rented. Renter: " + renterName + ". Duration: " + (string)rentalTime + ".");
        //uncomment the following to make use of sendlinkedMessage function for API
        sendLinkedMessage("Rental Confirmed: " + renterName + " has rented the space for " + (string)rentalTime + " seconds.");
        sendLinkedMessage("Mesh:Rented");
    }
    touch_start(integer num_detected) {
        integer x;
        key detectedKey;

        for (x = 0; x < num_detected; x += 1) {
            detectedKey = llDetectedKey(x);
            if (detectedKey == llGetOwner()) {
                list options = ["Info", "Release", "Reset", "Lock", "Unavailable"];
                if (refundsEnabled) {
                    options += "Refund";
                }
                llDialog(detectedKey, "Lease Options. Select one of the options below...", options, setupDialogListen());
            } else if (detectedKey == renterID) {
                list options = ["Info"];
                if (refundsEnabled) {
                    options += "Refund";
                }
                llDialog(detectedKey, "Lease Options. Select one of the options below...", options, setupDialogListen());
            } else {
                dispData();
                llGiveInventory(detectedKey, infoNotecard);
            }
        }
    }

    money(key id, integer amount)
    {
        if ((id == renterID) || 
            (allowOwnerPayment == 1 && id == llGetOwner()) || 
            (allowGroupPayment == 1 && llSameGroup(id)))
        {
            float addTime;
            integer fourweekdiscount = (integer)(((float)rentalCost * 4.0) * (discountPercent / 100.0));
            integer fourweekrentalprice = (integer)(((float)rentalCost * 4.0) - fourweekdiscount);
            if (fourweekrentalprice == amount)
            {
                addTime = ONE_WEEK * 4;
                discountTime += addTime;
            }
            else
                addTime = ONE_WEEK * amount / rentalCost;

            rentalTime += addTime;
        
            llInstantMessage(id, "Adding " + getTimeString(llRound(addTime)) + " to the lease. Lease Time is Now: " + getTimeString(llRound(rentalTime)) + ".");
            llInstantMessage(llGetOwner(), "Rental Extension Confirmed: " + renterName + " has extended their lease. Time is Now: " + getTimeString(llRound(rentalTime)) + ".");
            sendEmailNotification("Rental Extension Confirmed", "The space has been rented. Renter: " + renterName + " has extended their lease. Time is Now: " + getTimeString(llRound(rentalTime)) + ".");
            sendLinkedMessage("Rental Extension Confirmed: " + "The space has been rented. Renter: " + renterName + " has extended their lease. Time is Now: " + getTimeString(llRound(rentalTime)) + ".");

            saveData();
            updateTimeDisp();
        }
        else
        {
            llInstantMessage(id, "Refunding Money...");
            llGiveMoney(id, amount);
            llInstantMessage(id, "This space is currently leased by " + renterName + ". This space will be open for lease in " + getTimeString(llRound(rentalTime)) + "."); 
        }
    }


    listen(integer channel, string name, key id, string message)
    {
        integer refundAmount;
        
        llListenRemove(listenQueryID);    
        if (message == "Info")
        {
            dispData();
            llGiveInventory(id, infoNotecard);
        }
        else if (message == "Refund" && refundsEnabled == 1)
        {
            llDialog(id, "Are you sure you want to TERMINATE your lease and refund your money, minus a L$" + (string)refundFee + " fee?", ["YES", "NO"], setupDialogListen());
        }
        else if (message == "YES")
        {
            float discount = (float)rentalCost * (discountPercent / 100.0);
            integer discountCost = (integer)((float)rentalCost - discount);
            refundAmount = llRound((((rentalTime - discountTime)/ ONE_WEEK) * rentalCost) + ((discountTime / ONE_WEEK) * discountCost) - refundFee);
    
            // Check if the refund amount is less than zero
            if (refundAmount < 0)
            {
                llOwnerSay("Refund amount is less than the refund fee. No funds will be refunded.");
                // Optionally set refundAmount to 0 if you want to proceed with other logic without refunding
                refundAmount = 0;
            }
            else
            {
                llInstantMessage(renterID, "Refunding L$" + (string)refundAmount + ", which includes a L$" + (string)refundFee + " termination fee.");
                llGiveMoney(renterID, refundAmount);
            }

            llInstantMessage(llGetOwner(), "LEASE REFUNDED: leased by " + renterName + " located in " + llGetRegionName() + " (" + (string)initPos.x + "," + (string)initPos.y + "," + (string)initPos.z + ") has ended. Refunded L$" + (string)refundAmount + ".");
            sendEmailNotification("LEASE REFUNDED", "LEASE REFUNDED: leased by " + renterName + " located in " + llGetRegionName() + " (" + (string)initPos.x + "," + (string)initPos.y + "," + (string)initPos.z + ") has ended. Refunded L$" + (string)refundAmount + ".");
            //uncomment the following to make use of sendlinkedMessage function for API
            sendLinkedMessage("LEASE REFUNDED: leased by " + renterName + " located in " + llGetRegionName() + " (" + (string)initPos.x + "," + (string)initPos.y + "," + (string)initPos.z + ") has ended. Refunded L$" + (string)refundAmount + ".");
            state idle;
        }
        else if (message == "Release")
        {
            llDialog(id, "Are you sure you want to TERMINATE this lease with NO REFUND?", ["Yes", "No"], setupDialogListen());
        }
        else if (message == "Yes")
        {
            llInstantMessage(llGetOwner(), "LEASE TERMINATED: leased by " + renterName + " located in " + llGetRegionName() + " (" + (string)initPos.x + "," + (string)initPos.y + "," + (string)initPos.z + ") has ended. Refunded L$0.");
            sendEmailNotification("LEASE TERMINATED", "LEASE TERMINATED: leased by " + renterName + " located in " + llGetRegionName() + " (" + (string)initPos.x + "," + (string)initPos.y + "," + (string)initPos.z + ") Refunded L$0.");
            //uncomment the following to make use of sendLinkedMessage function for API
            sendLinkedMessage( "LEASE TERMINATED: leased by " + renterName + " located in " + llGetRegionName() + " (" + (string)initPos.x + "," + (string)initPos.y + "," + (string)initPos.z + ") Refunded L$0.");
            state idle;            
        }
        else if (message == "Reset")
        {
            llResetScript();
        }
        else if (message == "Lock")
        {
            sendLinkedMessage("Mesh:Locked");
            state locked;
        }
        else if (message == "Unavailable")
        {
            sendLinkedMessage("Mesh:Unavailable");
            state locked;
        }
    }
    timer() {
        float timeElapsed = llGetAndResetTime();
        if (timeElapsed > (updateInterval * 4)) {
            timeElapsed = updateInterval;
        }
        rentalTime -= timeElapsed;

        saveData();
        updateTimeDisp();

        // Process Reminders
        if (rentalTime <= 0) {
            if (gracePeriod > 0) { // Check if grace period is set
                llInstantMessage(renterID, "Your lease has expired. You are now in the grace period.");
                llInstantMessage(llGetOwner(), "The lease for " + renterName + " has expired. The rental is now in the grace period.");
                sendEmailNotification("Grace Period Started", "The lease for " + renterName + " has expired. The rental is now in the grace period.");
                sendLinkedMessage("Grace Period Started: " + renterName + ".");
                state grace;
            } else {
                llInstantMessage(llGetOwner(), "LEASE EXPIRED: leased by " + renterName + " located in " + llGetRegionName() + " (" + (string)initPos.x + "," + (string)initPos.y + "," + (string)initPos.z + ") has expired.");
                sendEmailNotification("LEASE EXPIRED", "The space has been rented. Renter: " + renterName + ". Duration: " + (string)rentalTime + ".");
                sendLinkedMessage("LEASE EXPIRED: The space has been rented. Renter: " + renterName + ". Duration: " + (string)rentalTime + ".");
                state idle;
            }
        }
         
        if((rentalTime <= _48_HOURS)&&(rentalTime >= _48_HOURS - (updateInterval*2)))
        {
            sendReminder("in two days.");
        }              
        else if ((rentalTime <= _24_HOURS)&&(rentalTime >= _24_HOURS - (updateInterval*2)))
        {
            sendReminder("in one day.");
        }
        else if((rentalTime <= _6_HOURS)&&(rentalTime >= _6_HOURS - (updateInterval*2)))
        {
            sendReminder("in 6 hours.");
        }
        else if((rentalTime <= _1_HOUR)&&(rentalTime >= _1_HOUR - (updateInterval*2)))
        {
            sendReminder("in one hour.");
        }        
    }
}

state idle_SpecificRenter
{
    state_entry()
    {
        llListenRemove(listenQueryID); // Remove any previous listen to avoid duplicates
        listenQueryID = llListen(0, "", llGetOwner(), ""); // Listen for owner's chat on channel 0
        
        // Show dialog box with instructions and a cancel option
        llDialog(llGetOwner(), "Please type the name of the specific renter in chat, using proper capitalization, etc. Click 'Cancel' to abort.", ["Cancel"], -8675309);
    }

    listen(integer channel, string name, key id, string message)
    {
        if (message == "Cancel")
        {
            // Owner chose to cancel, move back to idle state
            llListenRemove(listenQueryID); // Stop listening to avoid unwanted chat captures
            state idle;
        }
        else if (message == "Cancel Specific Renter" && id == llGetOwner())
        {
            llListenRemove(listenQueryID); // Clean up the listener
            state idle; // Move back to the general idle state
        }
        else if (message == "Reset")
        {
            llResetScript();
        }
        else if (message == "Done")
        {
            llListenRemove(listenQueryID); // Stop listening
        }
        else if (message == "Info")
        {
            llListenRemove(listenQueryID); // Stop listening
            llSay(0, "This rental space is currently pending rental for " + renterName + " and is unavailable. Please check back later.");
        }
        else if (id == llGetOwner())
        {
            // Assuming the owner typed the name of the renter
            renterName = message; // Set the specified renter's name
            llListenRemove(listenQueryID); // Stop listening
            llOwnerSay("The rental box is now set for " + renterName + " only. Reset or use 'Cancel Specific Renter' from the menu to revert.");

            // Optionally, show a dialog with the option to cancel this mode
            llDialog(llGetOwner(), "Rental box is now in specific renter mode for: " + renterName + ". To cancel, Open the menu and choose 'Cancel Specific Renter'.", ["Done"], -8675309);
            sendLinkedMessage("Mesh:Reserved");
        }
    }

    touch_start(integer num_detected)
    {
        integer i;
        for (i = 0; i < num_detected; i++)
        {
            key detectedKey = llDetectedKey(i);
            if (detectedKey == llGetOwner())
            {
                // Show owner-specific options
                llDialog(llGetOwner(), 
                    "Owner Options:\n\n" +
                    "- Reset: Reset the rental box.\n" +
                    "- Cancel Specific Renter: Remove the restriction for a specific renter.\n\n" +
                    "Please select an option below:",
                    ["Info", "Reset", "Cancel Specific Renter"], setupDialogListen());
            }
            else
            {
                // Inform others that the rental is pending for a specific renter and currently unavailable
                llInstantMessage(detectedKey, "This rental space is currently pending rental for " + renterName + " and is unavailable. Please check back later.");
            }
        }
    }

    money(key id, integer amount)
    {
        // Check if the person trying to rent is the specified renter
        if (llKey2Name(id) == renterName && amount >= rentalCost)
        {
            renterID   = id;
            renterName = llKey2Name(renterID);
            integer fourweekdiscount = (integer)(((float)rentalCost * 4.0) * (discountPercent / 100.0));
            integer fourweekrentalprice = (integer)(((float)rentalCost * 4.0) - fourweekdiscount);
            if (fourweekrentalprice == amount)
            {
                rentalTime = ONE_WEEK * (rentalCost * 4) / rentalCost;
                discountTime = rentalTime;
            }
            else
            {
                rentalTime = ONE_WEEK * amount / rentalCost;
                discountTime = 0;
            }

            saveData();
            
            llSay(0, "Thank you " + renterName + " for leasing!  Your lease will expire in " + getTimeString((integer)rentalTime) + ".");
            llGiveInventory(id, welcomeNotecard);
            sendGroupJoinDialog(id, myGroupName, myGroupID);
            state rented;
        }
        else
        {
            llSay(0, "This rental box is reserved and costs L$" + (string)rentalCost + " to rent  Refunding payment.");
            llGiveMoney(id, amount);
        }
    }
}

state grace {
    state_entry() {
        currentGracePeriod = gracePeriod;
        // Notify the owner and renter about the grace period start
        llInstantMessage(renterID, "Your lease has expired. You are now in the grace period.");
        llInstantMessage(llGetOwner(), "The lease for " + renterName + " has expired. The rental is now in the grace period.");
        sendEmailNotification("Grace Period Started", "The lease for " + renterName + " has expired. The rental is now in the grace period.");
        sendLinkedMessage("Grace Period Started: " + renterName + ".");
        sendLinkedMessage("Mesh:Grace");
        // Set timer to track grace period
        llSetTimerEvent(updateInterval);
    }
    timer() {
        float timeElapsed = llGetAndResetTime();
        if (timeElapsed > (updateInterval * 4)) {
            timeElapsed = updateInterval;
        }
        currentGracePeriod -= llRound(timeElapsed);
        saveData();
        if (currentGracePeriod <= 0) {
            // Notify expiration and transition to idle
            llInstantMessage(llGetOwner(), "Grace period for " + renterName + " has ended. The rental is now available.");
            sendEmailNotification("Grace Period Ended", "Grace period for " + renterName + " has ended. The rental is now available.");
            sendLinkedMessage("Grace Period Ended: " + renterName + ".");
            state idle;
        }
    }
    touch_start(integer total_number) {
        integer i;
        for (i = 0; i < total_number; i++) {
            key detectedKey = llDetectedKey(i);
            if (detectedKey == llGetOwner()) {
                llDialog(detectedKey, "Cancel Grace Period on this rental box?", ["Yes", "No"], setupDialogListen());
            } else {
                // Message for others
                llInstantMessage(detectedKey, "This rental box is in the grace period.\n" +
                    "Remaining grace period: " + getTimeString(llRound(currentGracePeriod)) + "\n" +
                    "Contact the owner for more information.");
            }
        }
    }
    money(key id, integer amount) {
        if (id == renterID) {
            float addTime;
            integer fourweekdiscount = (integer)(((float)rentalCost * 4.0) * (discountPercent / 100.0));
            integer fourweekrentalprice = (integer)(((float)rentalCost * 4.0) - fourweekdiscount);
            if (fourweekrentalprice == amount) {
                addTime = ONE_WEEK * 4; // Adding 4 weeks
            } else {
                addTime = ONE_WEEK * amount / rentalCost;
            }

            rentalTime = addTime - currentGracePeriod; // Adjust the rental time by subtracting the remaining grace period
            currentGracePeriod = 0; // Reset grace period

            llInstantMessage(renterID, "Thank you for your payment. Your lease has been extended. Lease Time is Now: " + getTimeString(llRound(rentalTime)) + ".");
            llInstantMessage(llGetOwner(), "Rental Extension Confirmed: " + renterName + " has extended their lease. Time is Now: " + getTimeString(llRound(rentalTime)) + ".");
            sendEmailNotification("Rental Extension Confirmed", "The space has been rented. Renter: " + renterName + " has extended their lease. Time is Now: " + getTimeString(llRound(rentalTime)) + ".");
            sendLinkedMessage("Rental Extension Confirmed: " + "The space has been rented. Renter: " + renterName + " has extended their lease. Time is Now: " + getTimeString(llRound(rentalTime)) + ".");
            
            saveData();
            updateTimeDisp();
            state rented;
        } else {
            llInstantMessage(id, "This rental box is in the grace period. Only the current renter can make payments. Contact the owner for more information.");
            llGiveMoney(id, amount); // Refund money to others
        }
    }
}



// This state is both for locked and unavailable.
// The intent for both options is to allow for the rental box to handle the messages differently (ex: diffent graphics)
state locked {
    state_entry() {
        // Display locked status
        dispString("Rental Box Locked\nLease will not auto-terminate.");
        // Track time but do not transition to idle
        if(llGetObjectDesc() == ""){
            llSetTimerEvent(0);
        }else{
            llSetTimerEvent(updateInterval);
        }
        
    }
    touch_start(integer total_number) {
        integer i;
        for (i = 0; i < total_number; i++) {
            key detectedKey = llDetectedKey(i);
            if (detectedKey == llGetOwner()) {
                // Unlock option
                llDialog(detectedKey, "Unlock this rental box?", ["Yes", "No"], setupDialogListen());
            } else {
                // Message for others
                llInstantMessage(detectedKey, "This rental box is currently locked by the owner.\n" +
                    "Remaining lease time: " + getTimeString(llRound(rentalTime)) + "\n" +
                    "The lease cannot be extended or modified while the box is locked. Contact management for more information.");
            }
        }
    }
    listen(integer channel, string name, key id, string message) {
        if (message == "Yes" && id == llGetOwner()) {
            // Unlock and transition to appropriate state
            if (rentalTime > 0) {
                state rented;
            } else {
                state idle;
            }
        }
    }
    timer() {
        // Track remaining time
        rentalTime -= llGetAndResetTime();
        saveData();
        if (rentalTime <= 0) {
            // Notify expiration but remain in locked state
            llInstantMessage(llGetOwner(), "LEASE EXPIRED: " + renterName + "'s lease has expired. Box remains locked.");
            sendEmailNotification("LEASE EXPIRED", "The lease has expired. Renter: " + renterName + ".");
            sendLinkedMessage("LEASE EXPIRED: " + renterName + ".");
            rentalTime = 0; // Ensure time doesn't go negative
            llSetObjectDesc("");
            llSetTimerEvent(0);
        }
    }
}

