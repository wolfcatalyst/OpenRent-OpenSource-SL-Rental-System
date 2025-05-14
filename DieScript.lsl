//Be sure to uncomment the //llDie(); line or this script won't self delete the objects.  :)

integer channel = -121;
default
{
    state_entry()
    {
        // Start listening on the -1 channel
        llListen(channel, "", NULL_KEY, "");
    }
    
    listen(integer channel, string name, key id, string message)
    {
        llOwnerSay(message);
        // Check if the message is a 'die' message
        if (llGetSubString(message, 0, 3) == "die:") {
            // Extract the parcel name from the message
            string parcelName = llGetSubString(message, 4, -1);
            llOwnerSay(parcelName);
            // Get the name of the parcel this object is on
            list parcelDetails = llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_NAME]);
            string myParcelName = llList2String(parcelDetails, 0);

            // Check if the parcel names match
            if (parcelName == myParcelName) {
                // Delete this object
                //UNCOMMENT THIS LINE FOR IT TO WORK!!
                //llDie();
                llOwnerSay("Message received and on same parcel.");
            }
        }
    }
    
    on_rez(integer start_param)
    {
        llResetScript();
    }
    
    changed(integer change)
    {
        if (change & CHANGED_OWNER) {
            llResetScript();
        }
    }
}
