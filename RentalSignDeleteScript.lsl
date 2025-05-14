//Combine this with the DieScript. Put the DieScript into your signs, etc., and when property is rented, they will automatically delete themselves.

integer channel = -121;
default
{
    link_message(integer sender_num, integer num, string message, key id)
    {
        //Debugging code: repeats all linked messages
        //llOwnerSay(message);
        // Check if the message indicates a rental confirmation
        if (llGetSubString(message, 0, 15) == "Rental Confirmed") {
            // Get the parcel name
            list parcelDetails = llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_NAME]);
            string parcelName = llList2String(parcelDetails, 0);

            // Send the 'die' message with the parcel name
            llRegionSay(channel, "die:" + parcelName);
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
