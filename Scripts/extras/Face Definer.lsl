//This script simply gives me the face number when clicking around my mesh object. Useful for customizing scripts and custom mesh objects.

default
{
    touch_start(integer total_number)
    {
        integer face = llDetectedTouchFace(0);
        if (face == -1)
        {
            llOwnerSay("The object was clicked, but no specific face was detected.");
        }
        else
        {
            llOwnerSay("Face clicked: " + (string)face);
        }
    }
}
//front sign: 2
//Back sign: 3
//meter: 4
//base upper: 0
//base lower: 1