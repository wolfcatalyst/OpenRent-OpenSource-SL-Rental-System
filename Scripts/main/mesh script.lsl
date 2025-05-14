// Mesh Script for Rental Box

// Variables
integer SIGN_FRONT = 2;
integer SIGN_BACK = 3; // The face for the floating sign
integer METER = 4; // The face for the meter showing remaining time
integer TIME_DISPLAY = 0; // the graphic with the 'Remaining time' graphic
integer BASE = 1; // just helps keep the time display graphic out of the ground. could also have graphics added

list floatingSignFaces = [SIGN_FRONT, SIGN_BACK];

// Textures
string forRentTexture = "for_rent_mesh";
string rentedTexture;
string overdueTexture = "overdue_mesh";
string lockedTexture = "locked_mesh";
string unavailableTexture = "tempunavailable_mesh";
string reservedTexture = "reserved_mesh";
string initializingTexture = "initializing_mesh";
// Settings
//integer rentedSignEnabled = 0; // Default is 0 (false)
float meshGlow = 0.1;
float meshTransparency = 0.8; // Default transparency level

// Meter textures based on time frames
list meterTextures = [];
list meterTimeFrames = []; // Corresponding time frames in seconds

string bestTexture;
float bestTimeFrame;
float offset;

// Function to apply textures with glow and transparency
applyTexture(list faces, string texture) {
    integer i;
    for (i = 0; i < llGetListLength(faces); i++) {
        integer face = llList2Integer(faces, i);
        llSetTexture(texture, face);
    }
}

// Function to apply alpha (transparency) to multiple faces
applyAlpha(list faces, float transparency) {
    integer i;
    for (i = 0; i < llGetListLength(faces); i++) {
        integer face = llList2Integer(faces, i);
        llSetAlpha(transparency, face);
    }
}

applyFullAlpha(list faces) {
    integer i;
    for (i = 0; i < llGetListLength(faces); i++) {
        integer face = llList2Integer(faces, i);
        llSetAlpha(0.0, face);
    }
}

// Function to apply glow to multiple faces
applyGlow(list faces, float glow) {
    integer i;
    for (i = 0; i < llGetListLength(faces); i++) {
        integer face = llList2Integer(faces, i);
        llSetPrimitiveParams([
            PRIM_GLOW, face, glow
        ]);
    }
}

// Function to update the meter based on remaining time
updateMeter(float remainingTime) {
    bestTimeFrame = 0.0; // Reset best time frame for new calculation
    bestTexture = ""; // Reset best texture for new calculation
    
    integer i;
    for (i = 0; i < llGetListLength(meterTimeFrames); i++) {
        float timeFrame = llList2Float(meterTimeFrames, i);
        if (remainingTime <= timeFrame && (bestTimeFrame == 0.0 || timeFrame < bestTimeFrame)) {
            bestTexture = llList2String(meterTextures, i);
            bestTimeFrame = timeFrame;
        }
    }

    // Default to the last texture if no suitable one was found
    if (bestTexture == "") {
        bestTexture = llList2String(meterTextures, -1);
        bestTimeFrame = llList2Float(meterTimeFrames, -1);
    }

    // Apply the best texture to the TIME_DISPLAY face without adjusting other settings
    llSetTexture(bestTexture, TIME_DISPLAY);

    // Calculate the horizontal offset for the meter
    if (bestTimeFrame != 0) {
        offset = (-0.500 / bestTimeFrame) * remainingTime;
    } else {
        offset = 0.0;
    }

    // Apply the horizontal offset to the METER face
    if (offset < -0.500) {
        offset = -0.500;
    }
    llOffsetTexture(offset, 0.0, METER);
    
    // Debug information
    //llOwnerSay("Calculated Offset: " + (string)offset);
    //llOwnerSay("Remaining Time: " + (string)remainingTime + ", Best Time Frame: " + (string)bestTimeFrame);
}









// Function to handle link messages
handleLinkMessage(string message) {
    list messageParts = llParseString2List(message, ["^"], []);
    string command = llList2String(messageParts, 0);
 
    if (command == "Mesh:SetForRentTexture") {
        forRentTexture = llList2String(messageParts, 1);
    }else if (command == "Mesh:SetRentedTexture") {
        rentedTexture = llList2String(messageParts, 1);
    }else if (command == "Mesh:SetOverdueTexture") {
        overdueTexture = llList2String(messageParts, 1);
    }else if (command == "Mesh:SetLockedTexture") {
        lockedTexture = llList2String(messageParts, 1);
    }else if (command == "Mesh:SetUnavailableTexture") {
        unavailableTexture = llList2String(messageParts, 1);
    }else if (command == "Mesh:Reserved Texture") {
        reservedTexture = llList2String(messageParts, 1);
    }else if (command == "Mesh:Initializing Texture") {
        initializingTexture = llList2String(messageParts, 1);
    }else if (command == "Mesh:SetAlpha") {
        meshTransparency = (float)llList2String(messageParts, 1);
    }else if (command == "Mesh:SetGlow") {
        meshGlow = (float)llList2String(messageParts, 1);
           
    }else if (command == "Mesh:Idle") {
        // Set the floating sign to "For Rent"
        // Reset meter face
        applyTexture(floatingSignFaces, forRentTexture);
        applyAlpha(floatingSignFaces, meshTransparency);
        applyGlow(floatingSignFaces, meshGlow);
        // Set meter texture offset to 0
        updateMeter(0.0);
    } else if (command == "Mesh:Rented") {
        // Set the floating sign to "rentedTexture" or transparent
        if (rentedTexture != "") {
            applyTexture(floatingSignFaces, rentedTexture);
            applyAlpha(floatingSignFaces, meshTransparency);
            applyGlow(floatingSignFaces, meshGlow);
        } else {
            applyFullAlpha(floatingSignFaces);
        }
    } else if (command == "Mesh:Grace") {
        // Set the floating sign to "Overdue"
        applyTexture(floatingSignFaces, overdueTexture);
        applyAlpha(floatingSignFaces, meshTransparency);
        applyGlow(floatingSignFaces, meshGlow);
    } else if (command == "Mesh:Initializing") {
        // Set the floating sign to "Initializing"
        applyTexture(floatingSignFaces, initializingTexture);
        applyAlpha(floatingSignFaces, meshTransparency);
        applyGlow(floatingSignFaces, 0.0);    
    } else if (command == "Mesh:Locked") {
        // Set the floating sign to "Locked"
        applyTexture(floatingSignFaces, lockedTexture);
        applyAlpha(floatingSignFaces, meshTransparency);
        applyGlow(floatingSignFaces, meshGlow);
        
    } else if (command == "Mesh:Unavailable") {
        // Set the floating sign to "Unavailable"
        applyTexture(floatingSignFaces, unavailableTexture);
        applyAlpha(floatingSignFaces, meshTransparency);
        applyGlow(floatingSignFaces, meshGlow);
        
    } else if (command == "Mesh:Update") {
        // Update meter face based on the remaining time
        float remainingTime = (float)llList2String(messageParts, 1); // Extract remaining time
        updateMeter(remainingTime);
    }
}

// Function to initialize meter textures and time frames
initializeMeterTextures() {
    integer numTextures = llGetInventoryNumber(INVENTORY_TEXTURE);
    integer i;
    for (i = 0; i < numTextures; i++) {
        string textureName = llGetInventoryName(INVENTORY_TEXTURE, i);
        list nameParts = llParseString2List(textureName, ["_"], []);
        
        if (llList2String(nameParts, 0) == "timeframetexture") {
            llOwnerSay("Texture Found: " + textureName);
            string unit = llList2String(nameParts, 1);
            integer amount = (integer)llList2String(nameParts, 2);
            float timeFrame;
    
            if (unit == "days") {
                timeFrame = amount * 86400.0;
            } else if (unit == "weeks") {
                timeFrame = amount * 604800.0;
            } else if (unit == "months") {
                timeFrame = amount * 2419200.0; // Assuming 4 weeks per month
            } else {
                // Skip if the unit is not recognized
                timeFrame = -1; // Set to an invalid value
            }

            // Only add to lists if the timeFrame is valid
            if (timeFrame != -1) {
                meterTextures += [textureName];
                meterTimeFrames += [timeFrame];
            }
        }

    }
}

// Default state
default {
    state_entry() {
        initializeMeterTextures(); // Initialize meter textures and time frames
        llListen(LINK_SET, "", NULL_KEY, "");
    }

    link_message(integer sender_num, integer num, string message, key id){
        handleLinkMessage(message);
    }
    
    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            llOwnerSay("Inventory changed, resetting script to look for new textures.");
            llResetScript();
        }
    }

}
