list events = [];

// PARAMS:
//    id     - the unique, positive id you associate with your event, use of global variables is recommended here.
//    time - the time at which you want the event to try and execute.
//    data - a piece of data you want passed to your handler when the event executes.
scheduleEvent(integer id, integer time, string data) {
    events = llListSort((events = []) + events + [time, id, data], 3, TRUE);
    setTimer(FALSE);
}

// This function sets the timer correctly for the next scheduled event, or de-activates the timer 
// if there are no event remaining
integer setTimer(integer executing) {
    if ((events != []) > 0) { // Are there any list items?
        integer time = llList2Integer(events, 0);

        float t = (float)(time - llGetUnixTime());
        if (t <= 0.0) {
            if (executing) return TRUE;
            else t = 0.01;
        }
        llSetTimerEvent(t);
    } else { llSetTimerEvent(0.0); }
    return FALSE;
}

// Place your event handling code in here
handleEvent(integer id, string data) {
    
    if (id == 1) {
        llOwnerSay(data);
        scheduleEvent(2, llGetUnixTime() + 10, "Done");
    } else if (id == 2) llOwnerSay(data);
}

default {
    state_entry() {
        scheduleEvent(1, llGetUnixTime() + 10, "Half-way there");
    }

    timer() {
        // Clear timer or it might fire again before we're done
        llSetTimerEvent(0.0);
        
        do {
            // Fire the event
            handleEvent(llList2Integer(events, 1), llList2String(events, 2));
        
            // Get rid of the first item as we've executed it
            integer l = events != [];
            if (l > 0) {
                if (l > 3)
                    events = llList2List((events = []) + events, 3, -1);
                else events = [];
            }

            // Prepare the timer for the next event
        } while (setTimer(TRUE));
    }
}