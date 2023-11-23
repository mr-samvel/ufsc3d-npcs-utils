default
{
    state_entry()
    {
        // Set up the timer to trigger every 30 minutes
        llSetTimerEvent(1800.0); // 30 minutes in seconds
    }

    timer()
    {

        llRegionSay(68, "! 0000-0000-0000-0000 Name Name command");
        //llOwnerSay("Debug Event");
        
    }
}