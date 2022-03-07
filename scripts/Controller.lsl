integer channel = 68;
integer PEG_CHAN=699;
integer TIMER_INTERVAL=5; // how often to run the timer
integer autoLoadOnReset=0;
string LASTNAME="(NPC)";


// Nothing to edit here, see https://github.com/opensimworld/active-npcs for configuration

list availableNames = [];
list lastNames = [];
// These will be loaded from notecards
list wNodes = [];
list wLinks = [];
list wNodeNames=[];

//  list of nodes for the "Flyaround" command
list flyTargets = [];

list menuItems = ["SaveNPC", "LoadNPC", "RemoveNPC", "RemoveAll", "LoadAll", "ReConfig","InitCmds",  "DumpData", "TimerOnOff", "Close"];

string userInputState ="";
integer gListener;
integer zListener;
integer howmany;
list avis;
integer curVisitors=1;
integer deflectToNode = -1; // if set, the NPCs will only run notecards at the specified waypoint

list aviUids;
list aviNames;
list aviNodes;
list aviPrevNodes;
list aviStatus;
list aviFollow;
list aviCurrentAnim;
list aviPath;
list aviAlarm;
list aviScriptIndex;
list aviScriptText;
list aviHttpId;
list aviTarget; // user we are interacting with
list scriptVars;
list aviScriptState;
list aviPrompts;
list cache;


integer aviIndex = -1;
list seenArchive;

list positionsList;
list greetedAvis;
integer timerRuns;
integer timerRunning;
integer curPoint;
integer prevPoint;
list wayPoints;
list wayNames;
list wayLinks;
list wayKeys;
string name;
key npc;

list candidateNode=[];



string vec2str(vector v)
{
    return "<"+v.x+","+v.y+","+v.z+">";
}

string GetLastName(string first)
{
    integer idx = llListFindList(availableNames, [first]);
    if (idx >=0) return llList2String(lastNames, idx);
    else return LASTNAME;
}

key getAgentByName(string firstName)
{
        firstName = llToLower(firstName);
        list ag = osGetAvatarList();
        integer howmany = llGetListLength(ag);
        integer i;
        for (i =0; i < howmany; i+=3)
        {
            string name = llList2String(ag, i+2);
            integer sep = llSubStringIndex(name, " ");
            if (llToLower(llGetSubString(name, 0,sep-1)) == firstName)
            {
                return llList2Key(ag, i);
            }
        }
    return NULL_KEY;            
}

string GetScriptVar(string cmd3)
{
    integer i;
    for (i=0; i < llGetListLength(scriptVars); i+=2)
    {
        if (llList2String(scriptVars,i) == cmd3 )
        {
            return llList2String(scriptVars, i+1);
        }
    }
    return ""; // default value;
}


integer ScriptJump(integer idx, string label, integer complain)
{
    // Jump to a label in the notecard
    integer foundLine = FindScriptLineAfter(llList2String(aviScriptText,idx), "@"+label,-1);
    if (foundLine == -1)
    {
        if (complain)  llOwnerSay("Error: @"+label+" label not found");
        return 0;
    }
    else
    {
        aviScriptIndex  = []+llListReplaceList(aviScriptIndex, [foundLine+1], idx, idx);
        return 1;
    }
}

list permList;
string permCache;

LoadPerms()
{
    permList=[];
    permCache = "";
    if (llGetInventoryType("__permissions")==INVENTORY_NOTECARD)
    {
        llOwnerSay("Loading Permissions...");
        list lines = llParseString2List(osGetNotecard("__permissions"), ["\n"], []);
        integer l;
        for (l=0;l<llGetListLength(lines);l++)
        {
            list tk = llParseString2List(llList2String(lines,l), [" "], []);
            if (llList2String(tk,2) == "=")
            {
                string kw = llList2String(tk,3);
                string rule=llToLower(llList2String(tk,0)+" "+llList2String(tk,1));
                string n= llToLower(llStringTrim(llList2String(tk,4)+ " " + llList2String(tk,5), STRING_TRIM));
                if (n == "" ) n= "*";
                string val=kw+"|"+n+"|";
                permList+=rule;
                permList+=kw;
                permList+=n;
                if (llSubStringIndex(permCache,rule)<0) permCache+= rule;
            }
        }
        llOwnerSay(llList2CSV(permList));
        llOwnerSay(llList2CSV(permCache));
    }
}


integer IsAllowed(string npc, string cmd, key uid)
{
    if (uid == llGetOwner() || llGetListLength(permList)==0) return 1;
    
    string ss = "* *";
    string ns = npc+" *";
    string sc = "* "+cmd;    
    string nc = npc+" "+cmd;
    
    if (llSubStringIndex(permCache, ss)<0 &&  llSubStringIndex(permCache, ns)<0 &&  llSubStringIndex(permCache, sc)<0 &&    llSubStringIndex(permCache, nc)<0 ) return 1;

    integer allow=1;
    string name = llToLower(llKey2Name(uid));
    integer k;
    for (k=0; k< llGetListLength(permList); k+=3)
    {
        string rule = llList2String(permList,k);
        if (rule==ss || rule==ns || rule==sc || rule==nc)
        {
            //llOwnerSay("R="+rule);
            string r = llList2String(permList, k+1);
            if (r =="ALLOW" || r == "DENY")
            {
                string who=llList2String(permList, k+2);
                if (who == "*" || who==name)
                {
                    if (r == "ALLOW") allow=1;
                    else allow=0;
                }
            }
            else if (r=="ALLOWID")
            {
                if ( uid == llList2Key(permList, k+2)) allow=1;
            }
            else if (r=="DENYID")
            {
                if ( uid == llList2Key(permList, k+2)) allow=0;
            }
            else if (r =="ALLOWSAMEGROUP") 
            {
                if ( llSameGroup(uid)) { 
                    allow=1;
                }
            }
        }
    }
    return allow;
}



ReloadConfig()
{
    availableNames = [];
    lastNames = [];
    list tk = llParseString2List(osGetNotecard("__npc_names"), ["\n"] , []);
    integer i=0;
    for (i=0; i < llGetListLength(tk); i++)
    {
        list t2 = llParseString2List(llList2String(tk,i), [" "] , []);
        string f = llList2String(t2, 0);
        string l = llList2String(t2, 1);
        if (l =="") l = LASTNAME;
        if (f != "")
        {
            availableNames += f;
            lastNames += l;
        }
    }
    llOwnerSay("npc_names: "+llList2CSV(availableNames));
        
    flyTargets = llParseString2List(osGetNotecard("__fly_targets"), [" ", "\n", ""] , []);

    string ncName = "__config";
    autoLoadOnReset=0;

    if (llGetInventoryType(ncName) == INVENTORY_NOTECARD)
    {
        list tok = llParseString2List(osGetNotecard("__config"), ["=", "\n"] , []);
        integer j;
        for (j=0; j < llGetListLength(tok); j+=2)
        {
            string opt = llList2String(tok,j);
            if (opt== "AutoLoadOnReset") autoLoadOnReset = (integer)llList2String(tok, j+1);
            else if (opt== "LastName") LASTNAME = llList2String(tok, j+1);
        }
    }
    if (LASTNAME == "") LASTNAME = "(NPC)";
    
    LoadPerms();

}


integer countVisitors()
{
    list avis = llGetAgentList(AGENT_LIST_REGION, []);
    integer howmany = llGetListLength(avis);
    integer i;
    integer nNew =0;
    for ( i = 0; i < howmany; i++ ) {
        if ( ! osIsNpc(llList2Key(avis, i)) )
        {
            nNew++; // only non-NPC's
            key uu = llList2Key(avis, i);
            string nm = llKey2Name(uu);
            if (nm != "")
            {
                integer fnd = llListFindList(seenArchive, [nm]);
                if (fnd >=0)
                    seenArchive = [] + llListReplaceList(seenArchive, [nm, llGetUnixTime()], fnd, fnd+1);
                else 
                    seenArchive = [] + seenArchive  + [nm, llGetUnixTime()];
            }
        }
    }
    return nNew;
}

doLoadNPC(string first, string last)
{                 
        integer idx =(GetNPCIndex(first));
        if (idx >=0)
        {
            llOwnerSay(first+ " is already in region, not loading");
            osNpcStand(llList2Key(aviUids, idx));
            return;
        }

        key unpc = osNpcCreate(first, last, llGetPos()+<0,0,3>, "APP_"+llToLower(first), OS_NPC_SENSE_AS_AGENT );
        if (unpc != NULL_KEY)
            doAddNpc(first, unpc);
}


doAddNpc(string name, string unpc)
{

        llOwnerSay( "Adding '"+name+"'");
        aviUids += unpc;
        aviNames += llToLower(name);
        aviNodes += 1;
        aviPrevNodes += 0;
        aviStatus += "";
        aviFollow += "";
        aviCurrentAnim += "";
        aviHttpId += "";
        aviAlarm += -1;
        aviScriptIndex += -1;
        aviScriptText += "";
        aviTarget += NULL_KEY;
        aviPath  += "";
        aviScriptState += "";
        aviPrompts += "";
        osNpcMoveToTarget(unpc, osNpcGetPos(unpc) + <1,0,0>, OS_NPC_NO_FLY );
}

doRemoveNpc(string who)
{
        integer idx = GetNPCIndex(who);
        if (idx <0) return;
        
        key u = llList2Key(aviUids, idx);
        aviNames =  [] + llDeleteSubList(aviNames, idx, idx);
        aviUids =  [] + llDeleteSubList(aviUids, idx, idx);
        aviNodes =  [] + llDeleteSubList(aviNodes, idx, idx);
        aviPrevNodes = [] + llDeleteSubList(aviNodes, idx, idx);
        aviFollow = [] + llDeleteSubList(aviFollow, idx, idx); [];
        aviStatus = [] + llDeleteSubList(aviStatus, idx, idx);
        aviCurrentAnim = [] + llDeleteSubList(aviCurrentAnim, idx, idx);
        aviPath = [] + llDeleteSubList(aviPath, idx, idx);
        aviHttpId = [] + llDeleteSubList(aviHttpId, idx, idx);
        aviAlarm = [] + llDeleteSubList(aviAlarm, idx, idx);
        aviScriptIndex = [] + llDeleteSubList(aviScriptIndex, idx, idx);
        aviScriptText = [] + llDeleteSubList(aviScriptText, idx, idx);
        aviTarget = [] + llDeleteSubList(aviTarget, idx, idx);
        aviScriptState = [] + llDeleteSubList(aviScriptState, idx, idx);
        aviPrompts = [] + llDeleteSubList(aviPrompts, idx, idx);
       
        llOwnerSay("Removing "+who + "");
        osNpcStand(u);
        osNpcRemove(u);
}

doLoadAll()
{
            integer i;
            for (i=0; i < llGetListLength(availableNames);i++)
            {
                doLoadNPC(llList2String(availableNames, i),  llList2String(lastNames, i));
            }
    
}


doInitCmds()
{
    string notecard= "__initcommands";
    integer i;
    for(i=0; i<=osGetNumberOfNotecardLines(notecard); i++) {        
        string line = llStringTrim(osGetNotecardLine(notecard, i), STRING_TRIM);
        if (llStringLength(line)>0 && line != "")
        {
            list l = llParseString2List(line, [" "], []);
            line = "! "+(string)NULL_KEY+" "+llList2String(l,0)+" "+ line;
            llOwnerSay("InitCmd="+line);
            ProcessNPCCommand(line);
        }
    }

}

setVar(string cmd2, string cmd3)
{
            integer i;
            for (i=0; i < llGetListLength(scriptVars); i+=2)
            {
                if (llList2String(scriptVars,i) == cmd2)
                { 
                    scriptVars = [] + llListReplaceList(scriptVars, [cmd3], i+1, i+1);
                    return;
                }
            }
            scriptVars += cmd2;
            scriptVars += cmd3;
}


integer RescanAvis()
{
        avis = osGetAvatarList();
        howmany = llGetListLength(avis);
        integer i;
        for (i =0; i < howmany; i+=3)
        {
            if (osIsNpc(llList2Key(avis, i)))
            {
                integer sep = llSubStringIndex(llList2Key(avis, i+2), " ");
                string nm = llGetSubString(llList2Key(avis, i+2), 0, sep-1 );
                doAddNpc(nm,  llList2Key(avis, i));
            }
        }
        llOwnerSay(llList2CSV(aviNames));
        llOwnerSay(llList2CSV(aviStatus));
        return llGetListLength(aviUids);
}


LoadMapData()
{
    integer tl = osGetNumberOfNotecardLines("__waypoints");
    integer i;
    wNodes = [];
    for (i=0; i < tl; i++)
    {
        string line = osGetNotecardLine("__waypoints",i);
        list tok = llParseStringKeepNulls(line, [","], []);
        float x = llList2Float(tok,0);
        if (x>0)
        {
            vector v = <llList2Float(tok,0), llList2Float(tok,1),llList2Float(tok,2)>;
            wNodes += v;
            wNodeNames += llList2String(tok,3);
        }
    }
    llOwnerSay("loaded "+(string)(llGetListLength(wNodes))+" waypoints");

    
    integer tnodes = llGetListLength(wNodes);
    wLinks = [];
    tl = osGetNumberOfNotecardLines("__links");
    for (i=0; i < tl; i++)
    {
        string line = osGetNotecardLine("__links",i);
        list tok = llParseString2List(line, [","],"");
        integer a= llList2Integer(tok,0);
        integer b = llList2Integer(tok,1);
        if (a !=b)
            wLinks += [a,b];
    }
    llOwnerSay("loaded "+(string)(llGetListLength(wLinks)/2)+" links");
    cache = [];
}


integer GetNPCIndex(string name) /// name is in lowercase
{
    return llListFindList(aviNames, [llToLower(name)]);
}


integer GetWalkTime(float distance)
{
    return llCeil(distance / 1.7);
}

integer GetNearestNode(vector pos)
{
    integer i;
    float min = 9999991.;
    integer l =-1;
    for (i=0;i < llGetListLength(wNodes); i++)
    {
        float dist = llVecDist(pos, llList2Vector(wNodes,i));
        if (dist < min)
        {
            min = dist;
            l=i;
        }
    }
    return l;
}

list foundPaths;
// Get  path through LSL -- Slow
integer GenPaths(integer a, integer tgt, string path,  integer depth)
{
    if (depth > 17) 
    {
        //llOwnerSay("Bailing at " + path);
        return 0;
    }
    integer i;
    for (i=0; i < llGetListLength(wLinks); i+=2)
    {
        integer ca = llList2Integer(wLinks, i);
        integer cb = llList2Integer(wLinks, i+1);
        integer fn = -1;
        if (cb == a || ca == a)
        {
            if (cb == a)
                fn = ca;
            else if (ca == a)
                fn = cb;
            if (llSubStringIndex(path, ":"+fn+":")<0)
            {
                if (fn == tgt)
                {
                    path += ""+fn+":";
                    foundPaths += (path);
                    return 1;
                }
                else
                {
                  
                    GenPaths(fn, tgt, path+fn+":",   depth+1);
                }
            }
        }
        
        if (llGetListLength(foundPaths)>30)
            return 2;
    }
    return 0;
}





string GetGotoPath(integer nodeA, integer nodeB)
{
    integer i;
    integer ww;
 
    
    string tmpPath = ":"+(string)nodeA+":";
    
    foundPaths = [];
    GenPaths(nodeA, nodeB, tmpPath, 0);
    //llOwnerSay(llList2CSV(foundPaths));
    if (llGetListLength(foundPaths) ==0)
        return "";
    integer min = 99999;
    string least = "";
    for (i=0; i < llGetListLength(foundPaths); i++)
    {
        ww = llStringLength(llList2String(foundPaths, i));
        if (ww < min)
        {
            min = ww;
            least = llList2String(foundPaths, i);
        }
    }
    //llOwnerSay(least);
    return least;
}



integer GetNPCIndexByUid(key name)
{
    return llListFindList(aviUids, [name]);
}


string GetScriptLine(string scriptData, integer line)
{
    list scriptLines = llParseStringKeepNulls(scriptData, ["\n",";"], []);
    return llList2String(scriptLines, line-1);
}

integer FindScriptLineAfter(string scriptData, string lineToFind, integer afterLine)
{
    integer endIdx;
    list scriptLines = llParseStringKeepNulls(scriptData, ["\n",";"], []);
    string toFind = llToLower(lineToFind);
    integer foundLine = -1;
    string line;
    for  (endIdx = afterLine+1;endIdx < llGetListLength(scriptLines); endIdx++)
    {
        line = llList2String(scriptLines, endIdx);
        if (llStringTrim(line, STRING_TRIM) == toFind)
        {
            foundLine =endIdx;
            jump _foundIdxOut;
        }
    }
    @_foundIdxOut;
    return foundLine;
}


integer FindMatchingEndif(string scriptData, integer afterLine)
{
    integer endIdx;
    list scriptLines = llParseStringKeepNulls(scriptData, ["\n",";"], []);
    string toFind = "end-if";
    integer foundLine = -1;
    string line;
    integer ifLevel=1;
    for  (endIdx = afterLine+1;endIdx < llGetListLength(scriptLines); endIdx++)
    {
        line = llStringTrim(llList2String(scriptLines, endIdx), STRING_TRIM);
        if (llGetSubString(line, 0, 1) == "if")
        {
            ifLevel++;
        }
        else if (line == "end-if")
        {
            ifLevel--;
            if (ifLevel==0)
            {
                foundLine =endIdx;
                jump _foundEIIdxOut;
            }
        }
    }
    @_foundEIIdxOut;
    return foundLine;
}

integer GetNodeIndexByName(string nodeName)
{
    integer i;     
    nodeName = llToLower(nodeName);
    for (i=0; i < llGetListLength(wNodeNames); i++)
    {
        if (llToLower(llList2String(wNodeNames, i)) == nodeName)
        {
            return i;
        }
    }
    return -1;
}

SetScriptAlarm(integer aviId, integer time)
{
    aviAlarm = [] + llListReplaceList(aviAlarm, [llGetUnixTime() + time], aviId, aviId);
}


doStopNpc(integer idx, key uNPC)
{
    aviStatus = [] + llListReplaceList(aviStatus, [""], idx, idx);
    SetScriptAlarm(idx, 0);
    list anToStop=llGetAnimationList(uNPC);
    integer stop=llGetListLength(anToStop);
    while (--stop>=0) { osNpcStopAnimation(uNPC,llList2Key(anToStop,stop)); }
    osNpcStopMoveToTarget(uNPC);
    osNpcStand(uNPC);
}

// Handler for all commands coming from chat
integer ProcessNPCCommand(string inputString)
{

    list tokens = llParseString2List(inputString, [" "], []);
    // first token should be just "!"

    //llOwnerSay("<<"  + inputString);
    key sendUid = llList2Key(tokens,1);
    string npcName = llToLower(llList2String(tokens,2));
    string name2 = llToLower(llList2String(tokens,3));
    //if (npcName != name2)     npcName = name2;

    integer idx = GetNPCIndex(npcName);
    if (idx <0)
    {
        return 1;
    }

    key uNPC= llList2Key(aviUids, idx);
    if (uNPC == NULL_KEY)
    {
        return 1;
    }
    
    
    
    if (llSubStringIndex(inputString, "$")>=0) //substiute variables
    {
        integer i;
        for (i=4; i < llGetListLength(tokens); i++)
        {
            string st = llList2String(tokens,i);
            if (llSubStringIndex(st, "$")==0)
            {
                tokens = [] + llListReplaceList(tokens, [ GetScriptVar(llGetSubString(st,1,-1) ) ],   i , i);
            }
        }
    }
   
    string cmd1= llList2String(tokens,4);
    string cmd2= llList2String(tokens,5);
    list userData;
    
    if (sendUid!= NULL_KEY && (llGetAgentSize(sendUid) != ZERO_VECTOR))
    {
        if (!IsAllowed(npcName, cmd1, sendUid)) 
        {
            llOwnerSay("Denied '"+cmd1+"' to "+(string)sendUid+" "+llKey2Name(sendUid));
            return 1;
        }
    }

    
    if (llList2String(aviStatus, idx) == "prompt")
    {
        aviStatus =  []+llListReplaceList(aviStatus, [""], idx, idx); // Turn off prompt in sync with the listener
        if (npcName != name2 ) // it (probably) a response to the prompt, rather than a command given to the npc
        {
            integer i;
            for (i=3; i < llGetListLength(tokens); i++)
            {
                
                if ( llSubStringIndex(llList2String(aviPrompts, idx), "["+llToLower(llList2String(tokens, i))+"]" ) > 0) // label existed in prompt
                {
                    aviTarget =  []+llListReplaceList(aviTarget, [sendUid], idx, idx);
                    ScriptJump(idx, llToLower(llList2String(tokens, i)) , 1);
                    return 1;
                }
            }
            return 1; 
        }
    }
    
    
    if (cmd1 == "stop")
    {
        doStopNpc(idx, uNPC);
    }
    else if (cmd1 == "come")
    {
        doStopNpc(idx, uNPC);
        userData=llGetObjectDetails((key)sendUid, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
        osNpcStopMoveToTarget(uNPC);
        osTeleportAgent(uNPC, llList2Vector(userData, 1) + <1, 0, 0>, <1,1,1>);
        if (sendUid != NULL_KEY) // NOTE: a real avatar sent this command - stop processing our script
             aviScriptIndex  =  []+llListReplaceList(aviScriptIndex, -1, idx, idx);
    }
    else if (cmd1 == "stand")
    {
        aviStatus =  []+llListReplaceList(aviStatus, [""], idx, idx);
        osNpcStand(uNPC);
        osNpcStopMoveToTarget(uNPC);
    }
    else if (cmd1 == "moveto" || cmd1 == "movetov" || cmd1 == "runtovr"|| cmd1 == "movetovr" || cmd1 == "flytov" || cmd1 == "runtov" || cmd1=="walk" )
    {
        // Walk to the specified waypoint or vector
        vector v;
        string anim =""; // Specify an animation to play while walking
        if  (cmd1 == "runtovr"||cmd1 == "movetovr")
        {
            // run to somewhere within the volume enclosed by v1 and v2
            vector v1 = (vector) cmd2;
            vector v2 = (vector) llList2String(tokens, 6);
            v.x= v1.x + llFrand(v2.x-v1.x);
            v.y= v1.y + llFrand(v2.y-v1.y);
            v.z= v1.z + llFrand(v2.z-v1.z);
            anim = llList2String(tokens, 7);
        }
        else if (cmd1 == "movetov" || cmd1 == "flytov" ||cmd1 == "runtov" || cmd1 =="walk")
        {
            v = (vector)cmd2;
            if (v == ZERO_VECTOR)
            {
                llOwnerSay(npcName + ": "+cmd2+" is not a good position. I am not going there!");
                return 1;
            }
            anim = llList2String(tokens, 6);
        }
        else
            v = llList2Vector(wNodes, (integer)cmd2);
        
        float dist = llVecDist(osNpcGetPos(uNPC), v);        
        
        if (cmd1 == "runtovr"|| cmd1 == "runtov")
        {
            osSetSpeed(uNPC, 1.0);
            osNpcMoveToTarget(uNPC, v + <0,0,1>, OS_NPC_NO_FLY | OS_NPC_RUNNING);
            SetScriptAlarm(idx, (integer)(GetWalkTime(dist)/2.));
        }
        else
        {
            if (anim == "")
                osNpcStand(uNPC);
            osNpcStopMoveToTarget(uNPC);
            osSetSpeed(uNPC, 0.5);
            if (cmd1 == "flytov")
                osNpcMoveToTarget(uNPC, v + <0,0,1>, OS_NPC_FLY );
            else
                osNpcMoveToTarget(uNPC, v + <0,0,1>, OS_NPC_NO_FLY);
            if (anim)
            {
                llSleep(0.5);
                osNpcPlayAnimation(uNPC, anim);
            }
            
            SetScriptAlarm(idx, GetWalkTime(dist));
        }
    }
    else if (cmd1 == "setvar")
    {
            string cmd3 = llList2String(tokens,6);
            setVar(cmd2, cmd3);
            return 0;
    }
    else if (cmd1 == "if" || cmd1 == "if-not" || cmd1=="if-prob")
    {
        integer res = 0;
        if (cmd1 == "if-prob")
        {
            if (llFrand(1.0)<(float)cmd2)
                res = 1;
        }
        else if (cmd2 == "name-is")
        {
            integer k;
            res=0;
            for (k=6; k < llGetListLength(tokens); k++)
            {
                if (llToLower(npcName) == llToLower(llList2String(tokens,k)))
                {
                    setVar("_found", npcName);
                    res=1;
                }
            }
        }
        else if (cmd2 == "var-is")
        {
            integer k;
            res=0;
            for (k=6; k < llGetListLength(tokens); k+=2)
            {
                string nm = llList2String(tokens,k);
                if (nm == "")  jump varIsBreak;
                string val = llList2String(tokens,k+1);
                if (GetScriptVar(nm) == val)
                        res =1;
                else 
                {
                    res=0;
                    jump varIsBreak;
                }
            }
            @varIsBreak;
        }
        else if (cmd2 == "state-is")
        {
            // If state-is <avi-name> <state-value>
            integer nwho = GetNPCIndex(llList2String(tokens,6));
            if (nwho >=0)
            {
                string what = llList2String(aviScriptState,nwho);
                integer k;
                for (k=7; k < llGetListLength(tokens); k++)
                {
                    if (what == llList2String(tokens,k))
                                      res=1;
                }
            }
        }
        
        if (cmd1 == "if-not")
            res = !res;
            
        integer scrline = llList2Integer(aviScriptIndex, idx);
        if (scrline <0) 
        {
            return 1; // wtf
        }

        if (!res)
        {
            integer foundLine = FindMatchingEndif(llList2String(aviScriptText,idx), scrline-1); /// this used to skip a line
            if (foundLine == -1)
            {
                llOwnerSay("Error: end-if not found afterr "+cmd1 + " "+cmd2 + "...");
            }
            else
            {
                aviScriptIndex  =  []+llListReplaceList(aviScriptIndex, [foundLine+1], idx, idx);// Go past the end-if -- runs notecards faster 
            }
        }
        return 0;
    }
    else if (cmd1 == "end-if")
    {
        // Do nothing
        return 0;
    }
    else if (cmd1 == "prompt")
    { 
        string prompt = llDumpList2String(llList2List(tokens, 5, -1), " ");
        aviStatus =  []+llListReplaceList(aviStatus, ["prompt"], idx, idx);
        osNpcSay(uNPC, prompt);
        aviPrompts = []+llListReplaceList(aviPrompts, [llToLower(inputString)], idx, idx);
        aviTarget =  []+llListReplaceList(aviTarget, [NULL_KEY], idx, idx);
        osMessageAttachments(uNPC, "prompt", [ATTACH_RIGHT_PEC], 0);
    }
    else if (cmd1 == "jump")
    {
        // Jump to a label in the notecard
        ScriptJump(idx, llToLower(cmd2), 1);
        return 0; // process next cmd immediately
    }
    else if ((cmd1 == "go" && cmd2 == "to")   || cmd1 == "goto")
    {
        // Pathfinding command
        integer nearest = GetNearestNode(osNpcGetPos(uNPC));
        integer foundId =-1;        
        if (cmd1 == "goto")
        {
            foundId = (integer) cmd2;
        }
        else
        {
            string where = llToLower(llStringTrim(llList2String(tokens,6) +" "+ llList2String(tokens,7) +" "+ llList2String(tokens,8), STRING_TRIM));
            integer i;
            if (where != "")
                foundId = GetNodeIndexByName(where);

            if (foundId <0)
            {
                list tmp;
                for (i=0; i < llGetListLength(wNodeNames); i++) 
                    if (llList2String(wNodeNames,i) != "")  
                        tmp += llList2String(wNodeNames, i);
                osNpcSay(uNPC, "Sorry i dont know how to get to the "+where+ ". Here's some of the places i know: " +llList2CSV(tmp));
                return 1;
            }
        }
        
        osNpcSay(uNPC, "Let me think... ");
        string cachekey = "f,"+(string)nearest+","+(string)foundId;
        string gotoPath ="";
        integer fidx = llListFindList(cache, [cachekey]);
        if (fidx>=0)
        {
            gotoPath = llList2String(cache, fidx+1);
        }
        else
        {
            gotoPath = GetGotoPath(nearest, foundId);
            if (gotoPath != "")
            {
                cache += cachekey;
                cache += gotoPath;
            }
        }
        if (gotoPath == "")
        {
            osNpcSay(uNPC, "I 'm dumb. i don't know how to get there ... ");
            return 1;
        }
        osNpcSay(uNPC, "If you want to go there, follow me.");
        SetScriptAlarm(idx, 0);
        aviPath = []+ llListReplaceList(aviPath, [gotoPath], idx, idx);
        aviStatus =  []+llListReplaceList(aviStatus, ["pathf"], idx, idx);
    }
    else if (cmd1 == "setpath")
    {
        //Path must be in format 2:4:63:22:1 where the numbers are the waypoints numbers
        aviPath = []+ llListReplaceList(aviPath, [cmd2], idx, idx);
        SetScriptAlarm(idx, 0);
        aviStatus =  []+llListReplaceList(aviStatus, ["pathf"], idx, idx);
    }
    else if (cmd1 == "waitvar")
    {
            // Wait until the value of variable named cmd2 reaches the value cmd3
            string cmd3 = llList2String(tokens,6);
            string vval = GetScriptVar(cmd2);

            if (vval == cmd3)
            {
                    return 1; /// OK continue with the next line
            }
            else if (cmd3 == "NONEMPTY" && vval != "")
            {
                return 1;
            }

            integer scriptIndex = llList2Integer(aviScriptIndex, idx);
            if  (scriptIndex>0)
            {
                aviScriptIndex = []+llListReplaceList(aviScriptIndex, [scriptIndex-1], idx, idx);
            }
    }
    else if  (cmd1 == "increase" || cmd1 == "decrease" || cmd1 == "zero")
    {
        integer v = (integer)GetScriptVar(cmd2);
        if (cmd1=="increase") v++;
        else if (cmd1 == "decrease") v--;
        else v=0;
        setVar(cmd2, (string)v);
        return 1;
    }
    else if (cmd1 == "wait")
    {
        integer tm = (integer)cmd2;
        integer tm2 = (integer)llList2String(tokens,6);
        if (tm2>0)
            tm = (integer)(tm + llFrand(tm2));
        SetScriptAlarm(idx,  tm);
    }
    else if (cmd1 == "say" || cmd1 == "shout")
    {
        // Say something on chat
        string txt = "";
        integer i;
        for (i=5; i < llGetListLength(tokens); i++)
            txt += llList2String(tokens,i) + " ";
        if (cmd1 == "shout")
            osNpcShout(uNPC, 0, txt);
        else
            osNpcSay(uNPC, txt);
        return 0;
    }
    else if (cmd1 == "saych")
    {
        // Say something on channel
        string txt = "";
        integer i;
        for (i=6; i < llGetListLength(tokens); i++)
            txt += llList2String(tokens,i) + " ";
        osNpcSay(uNPC,  llList2Integer(tokens,5), txt);
    }
    else if (cmd1 == "loadnpc")
    {
        doLoadNPC(cmd2, llList2String(tokens, 6));
    }
    else if (cmd1 == "removenpc")
    {
        doRemoveNpc(cmd2);
    }
    else if (cmd1 == "exec")
    {
        list tok2 = ["!", (string)NULL_KEY, cmd2] + llList2List(tokens, 5, -1);
        //llOwnerSay(llList2CSV(tok2));
        ProcessNPCCommand(llDumpList2String(tok2, " "));
    }

    else if (cmd1 == "msgatt")
    {

        list points = [];
        integer i;
        for (i=6; i < llGetListLength(tokens); i++)
        {
            if (llList2Integer(tokens, i)>0)
                points += llList2Integer(tokens,i);
        }
        osMessageAttachments(uNPC, cmd2, points, 0);
    }
    else if (cmd1 == "teleport")
    {
        vector w = (vector) cmd2;
        if (w == ZERO_VECTOR)
        {
            integer where = GetNodeIndexByName(cmd2);
            if (where >=0)
            {
                w = llList2Vector(wNodes, where);
                osTeleportAgent(uNPC, w, <0,0,0>);
            }
        }
        else osTeleportAgent(uNPC, w, <0,0,0>);
    }
    else if (cmd1 == "use")
    {
        // Sit-on-a-poseball command
        string cmd = llStringTrim(cmd2+" "+llList2String(tokens, 6)+" "+llList2String(tokens,7), STRING_TRIM);
        osMessageAttachments(uNPC, "do "+cmd, [ATTACH_RIGHT_PEC], 0);
    }
    else if  (cmd1 == "lookat")
    {
        vector v;
        if (cmd2=="me")
        {
            userData=llGetObjectDetails((key)sendUid, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
            v = llList2Vector(userData,1);
        }
        else
        {
            v = (vector)cmd2;
            if  (v == ZERO_VECTOR)
            {
                integer midx = GetNodeIndexByName(llToLower(cmd2));
                if (midx >=0)
                {
                    v = llList2Vector(wNodes, midx);
                }
            }
        }
        osNpcSetRot(uNPC, llRotBetween(<1,0,0>, v-osNpcGetPos(uNPC)));//llEuler2Rot(<0,0,ang>)); 
    }
    else if (cmd1 == "anim")
    {
        osNpcStopAnimation(uNPC, llList2String(aviCurrentAnim, idx));
        aviCurrentAnim = llListReplaceList(aviCurrentAnim, [cmd2], idx, idx);
        osNpcPlayAnimation(uNPC, cmd2);
    }
    else if (cmd1 == "give")
    {
        if (llGetInventoryType(cmd2) == INVENTORY_OBJECT)
            llGiveInventory(sendUid, cmd2);
    }
    else if (cmd1 == "light")
        osMessageAttachments(uNPC, "light", [ATTACH_RIGHT_PEC], 0);
    else if (cmd1 == "sound")
        osMessageAttachments(uNPC, "sound " + cmd2+" "+llList2String(tokens, 6) , [ATTACH_RIGHT_PEC], 0);
    else if (cmd1 == "batch")
    {
        // Run multiple commands from the chat, separated by ";"   --- replaces any running script
        string str = llDumpList2String(llList2List(tokens, 5, llGetListLength(tokens))," ");
        aviScriptText =  []+llListReplaceList(aviScriptText, str, idx, idx);
        aviScriptIndex =  []+llListReplaceList(aviScriptIndex, [1], idx, idx);
        aviStatus =  []+llListReplaceList(aviStatus, "", idx, idx);
        SetScriptAlarm(idx, 0);
    }
    else if (cmd1 == "follow")
    {
        aviStatus =  []+llListReplaceList(aviStatus, ["follow"], idx, idx);
        if (cmd2=="me" || cmd2=="")
        {
            userData=llGetObjectDetails((key)sendUid, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
            aviFollow =  []+llListReplaceList(aviFollow, [(key)sendUid], idx, idx);
            osNpcSay(uNPC, "Following you "+ llList2String(userData, 0));
        }
        else
        {
            key who = getAgentByName(cmd2);
            if (who != NULL_KEY)
            {
                    aviFollow =  []+llListReplaceList(aviFollow, [who], idx, idx);
                    osNpcSay(uNPC, "Following " + cmd2);
            }
        }

    }
    else if (cmd1 == "set-state") // set a variable that indicates the current state of an NPC -- useful for scripts
    {
        aviScriptState=  []+llListReplaceList(aviScriptState, [cmd2], idx, idx);
        return 0;
    }
    else if (cmd1 == "debug")
    {
        integer dd = llList2Integer(aviScriptIndex, idx);
        string scr;
        if  (dd >=0)
        {
            scr = GetScriptLine(llList2String(aviScriptText,idx) , dd-1);
        }
        llOwnerSay("Status="+llList2String(aviStatus, idx)+" node = "+llList2Integer(aviNodes, idx)+
            " follow="+llList2String(aviFollow, idx)+" Alarm = "+(string)(llList2Integer(aviAlarm,idx)-llGetUnixTime())+
            " scriptIndex="+llList2Integer(aviScriptIndex, idx)+" scriptText " +scr );
    }
    else if (cmd1 == "fly" && cmd2=="with")  // "fly with me" "fly with Foo"
    {
        string who = llList2String(tokens, 6);
        if (who == "me")
        {
            aviFollow =  []+llListReplaceList(aviFollow, [(key)sendUid], idx, idx);
        }
        else
        {
            key w = getAgentByName(who);
            if (w != NULL_KEY)
            {
                aviFollow =  []+llListReplaceList(aviFollow, [w], idx, idx);

            }
        }
        aviStatus = llListReplaceList(aviStatus, ["flyfollow"], idx, idx);
        osNpcSay(uNPC, "Flying ");
    }
    else if (cmd1 == "leave")
    {
        // Start wandering between waypoints
        osNpcStand(uNPC);
        aviNodes =  []+llListReplaceList(aviNodes, [GetNearestNode(osNpcGetPos(uNPC))], idx, idx);
        aviStatus =  []+llListReplaceList(aviStatus, ["wander"], idx, idx);
        aviPrevNodes =  []+llListReplaceList(aviPrevNodes, [-1], idx, idx);
    }
    else if (cmd1 == "flyaround")
    {
        // Start flying about between the waypoints in the "flyTargets" list -- useful for birds
        aviStatus =  []+llListReplaceList(aviStatus, ["godfly"], idx, idx);
        osNpcSay(uNPC, "Flying like an eagle!!");

    }
    else if (cmd1 == "run-notecard")
    {
        // Run the script contained in the notecard <argument>
        string stext= osGetNotecard(cmd2 );
        aviStatus=  []+llListReplaceList(aviStatus, "", idx, idx);
        if (stext == "ERROR")
        {
            llOwnerSay("Notecard error "+cmd2);
            return 1;
        }
        aviScriptText =  []+llListReplaceList(aviScriptText, stext, idx, idx);
        aviScriptIndex =  []+llListReplaceList(aviScriptIndex, [1], idx, idx);
        SetScriptAlarm(idx, 0);
    }
    else if (cmd1 == "stop-script")
    {
        // Stop executing the script and exit
        aviScriptIndex =  []+llListReplaceList(aviScriptIndex, [-1], idx, idx);
        SetScriptAlarm(idx, 0);
    }
    else if (cmd1 == "dress")
    {
        string suff = "";
        if (cmd2 != "") suff += "_"+cmd2;
        string nm = llList2String(aviNames, idx);
        llOwnerSay("Loading appearance "+"APP_"+nm+suff);
        osNpcLoadAppearance(uNPC, "APP_"+nm+suff);
    }
    else if (cmd1 == "touch")
    {
        osNpcTouch(uNPC, (key)cmd2, LINK_ROOT);
    }
    else if (cmd1 == "seen")
    {
        integer i;
        if (cmd2 == "all")
        {
            for (i=0; i < llGetListLength(seenArchive); i+=2)
                osNpcSay(uNPC, "I saw "+ llList2String(seenArchive,i) + "  "  + TimeAgo(llList2Integer(seenArchive,i+1) ));
            return 1;
        }
        else
        {
            for (i=0; i < llGetListLength(seenArchive); i+=2)
            {
                if (llSubStringIndex(llToLower(llList2String(seenArchive,i)), llToLower(cmd2))>=0)
                {
                    osNpcSay(uNPC, "I saw "+ llList2String(seenArchive,i) + " around "  + TimeAgo(llList2Integer(seenArchive,i+1) ));
                    return 1;
                }
            }
        }
        osNpcSay(uNPC, "I haven't seen "+ cmd2 + " around");
    }
    else if (cmd1 == "nearest")
    {
        integer n = GetNearestNode(osNpcGetPos(uNPC));
        osNpcSay(uNPC, "Nearest waypoint is #"+n); 
    }
    else if (llGetSubString(cmd1,0,0) == "@")
        return 0;
    else if (cmd1 != "")
    {
       
        {
            if (llGetInventoryType(cmd1+".scr") == INVENTORY_NOTECARD)
            {
                ExecScriptLine(npcName , "run-notecard "+cmd1+".scr");
            }
            else
                llMessageLinked(LINK_THIS, -1, inputString, uNPC);
        }
    }            
    return 1; // 1 means that wait until next timer tick for next notecard command 
}

integer FindNewTarget(integer curNode, integer prevNode)
{
    integer total=llGetListLength(wLinks);
    candidateNode = [];
    integer i;
    integer a;
    integer b;
    for (i=0; i< total; i+=2)
    {
        a = llList2Integer(wLinks,i);
        b = llList2Integer(wLinks,i+1);
        if (a == curNode && prevNode != b) /// dont go back where we came from
            candidateNode += b;
        else if (b == curNode && prevNode !=a)
            candidateNode += a;
    }
    
    integer  l = llGetListLength(candidateNode);
    if (l>0)
    {
        return llList2Integer(candidateNode, (integer)llFrand((float)l));
    }
    else 
        return prevNode; // go back to where we came from if there is no other option
}


integer MoveToNewTarget(integer idx)
{
    integer curNode = llList2Integer(aviNodes,idx);
    integer prevNode = llList2Integer(aviPrevNodes,idx);

    key uuid = llList2Key(aviUids, idx);
    if (uuid == NULL_KEY)  return 1;
    vector pos = osNpcGetPos(uuid);
    osNpcStand(uuid);
    
    vector wp = llList2Vector(wNodes, curNode);
    float dist = llVecDist(pos, wp);
    if (dist>10) osTeleportAgent(uuid,  wp, <1,1, 7.1>);

    integer nt = FindNewTarget(curNode, prevNode);
    if (nt <0) return 0;
    vector tgt = llList2Vector(wNodes, nt);
    // Try to stay in the right 'lane'
    vector rr = 0.5*llVecNorm(tgt - pos)*llEuler2Rot(<0,0,-PI/2>);
    tgt += rr;
    osSetSpeed(uuid, 0.5);
    osNpcMoveToTarget(uuid, tgt, OS_NPC_NO_FLY);
    SetScriptAlarm(idx,  GetWalkTime( llVecDist(wp, tgt) )+4);
    aviNodes = []+llListReplaceList(aviNodes, [nt], idx, idx);
    aviPrevNodes = []+llListReplaceList(aviPrevNodes, [curNode], idx, idx);
    return 0;
}


integer ExecScriptLine(string aviName, string scriptline)
{
    // The token list expects the name of the avi twice. we use 0000 as the sending-uid identifier
    string command = "! "+ (string)NULL_KEY +" " + aviName +" "+ aviName +" "+ scriptline;
   // list tokens = llParseString2List(command, [" "], [] );
    return ProcessNPCCommand(command);
}



string TimeAgo(integer time)
{
    // time difference in seconds
    integer now = llGetUnixTime();
    integer timeDifference = now - time;
    // small bug fix for when timeDifference is 0
    if (timeDifference == 0)
        return "just now";
 
    list periods = ["second",        "minute",        "hour",        "day",        "week",        "month",        "year",        "decade"];
 
    //the number equivalent to periods
    list lenghts = [1,        60,        3600,        86400,        604800,        2630880,        31570560,        315705600];
 
    integer v = llGetListLength(lenghts) - 1;
    integer no;
 
    while((0 <= v) && (no = timeDifference/llList2Integer(lenghts, v) <= 1))    --v; 
    string output = llList2String(periods, v);
 
    //this will get the correct time in periods, then divide the timeDifference
    integer ntime = timeDifference / llList2Integer(lenghts, llListFindList(periods, [output]));
 
    //if integer 'no' is not equal to 1 then it should have an s at the end
    if(no != 1)
        output += "s";
 
    //This produces the finished output
    output = (string)ntime + " "+ output + " ago";
    return output;
}

giveCommands(integer n)
{
    integer i;
    string lstr = "";
    string kstr = "";
    list lnks;
    for (i=0; i < llGetListLength(wayLinks); i+=2)
    {
        integer a = llList2Integer(wayLinks,i);
        integer b = llList2Integer(wayLinks,i+1);
        if (a == n)
        {
            lstr += (string)b+",";
            lnks += (string)llList2Key(wayKeys,b);
        }
        else if (b == n)
        {
            lstr += (string)a+",";
            lnks += (string)llList2Key(wayKeys,a);
        }
    }
    
    string wstr = (string)n+"|SETDATA|"+vec2str(llList2Vector(wayPoints, n));
    wstr += "|"+llList2String(wayNames, n)+"|"+lstr+"|0|"+llList2CSV(lnks);
    //llOwnerSay(wstr);
    llRegionSay(PEG_CHAN, wstr);
}



default
{

    state_entry()
    {
        llSetText("NPCs", <1,1,1>,1.0);
        llListenRemove(gListener);
        gListener = llListen(channel, "", "", "");
        llOwnerSay("Listening on channel "+channel);
        ReloadConfig();
        LoadMapData();
        timerRuns=0;
        RescanAvis();
        greetedAvis = [];
        scriptVars = [];
        
        if (autoLoadOnReset)
        {
            llSleep(10);
            doLoadAll();
            llSleep(10); // Need to wait for their listeners attachments to start
            doInitCmds();
            llSleep(10);
        }
        
        llSetTimerEvent(TIMER_INTERVAL);
    }
    
    touch_start(integer num)
    {
        
        if (llDetectedKey(0) != llGetOwner()) return;
        llDialog(llGetOwner(), "Welcome", menuItems, channel);
    }
    

    // This checks the statuses of all avis and performs commands accordingly
    timer()
    {
        integer total = llGetListLength(aviUids);
        integer g;
        integer advanceScript;
        list startedScripts = [];
        if (curVisitors>0)
        for (g=0; g < total ; g++)
        {
                advanceScript =0;
                aviIndex = g;
                npc = llList2Key(aviUids, g);
                string status = llList2String(aviStatus, g); 

                if (status == "follow" || status == "flyfollow")
                {
                    // This NPC is following someone
                    integer stat=llGetAgentInfo(npc);
                    if (stat & AGENT_SITTING)
                    {
                        // We 've been sat. stop following
                        return;
                    }
                    
                    key who = llList2Key(aviFollow, g);
                    list userData = llGetObjectDetails(who, [OBJECT_POS, OBJECT_ROT]);
                    if (llGetListLength(userData) ==0)
                    {
                        // User left or died
                        aviStatus=  []+llListReplaceList(aviStatus, [ "" ], g, g);
                        return;
                        
                    }
                    
                    rotation rot = llList2Rot(userData,1);
                    float ang = llFrand(1.0);
                    vector v = llList2Vector(userData,0) + <-1.9,0,0>*rot;
                    float dist = llVecDist(osNpcGetPos(npc), v);

                    if  (status == "follow" && dist>50.)
                    {
                        osTeleportAgent(npc, v, <1,1,1>);
                    }
                    else if  (dist>4)
                    {
                        //osNpcStopMoveToTarget(npc);
                        if (osIsNpc(who))
                            osSetSpeed(npc, .47);
                        else osSetSpeed(npc, 1.0);
                        if (status == "flyfollow")                
                           osNpcMoveToTarget(npc, v+<0,0,2.>, OS_NPC_FLY );
                        else
                            osNpcMoveToTarget(npc, v, OS_NPC_NO_FLY );
                    }
                }
                else if (status == "wander")
                {
                    if (llGetUnixTime()  > llList2Integer(aviAlarm, g) +1)
                    {
                            integer curNode = llList2Integer(aviNodes, g);
                            integer i;
                            integer shouldMove =1;
                            llMessageLinked(LINK_THIS, -1, "WAYPOINT " + (string)curNode+" "+llList2String(aviNames, g), npc);
                            // avoid looping back to the same script while we are about to leave                            
                            if (llList2Integer(aviPrevNodes, g)>=0)
                            {
                                if (llListFindList(startedScripts, curNode)>=0)
                                {
                                    // dont start the same script simultaneously
                                }
                                else
                                {
                                    string ncName = "_"+curNode+".scr";
                                    if (llGetInventoryType(ncName) == INVENTORY_NOTECARD)
                                    {
                                            startedScripts+= curNode;
                                            ExecScriptLine(llList2String(aviNames, g), "run-notecard "+ncName);
                                            shouldMove =0;
                                    }                                
                                }
                            }
                            
                            if (shouldMove>0)
                            {
                               MoveToNewTarget(g);
                            }
                    }
                }
                else if (status == "godfly")
                {
                    // This NPC is flying around
                    if (llGetUnixTime()  > llList2Integer(aviAlarm, g) +1)
                    {
                        vector nd = (vector)llList2String(flyTargets, (integer)llFrand(llGetListLength(flyTargets)));
                        integer flag = OS_NPC_FLY;
                        osSetSpeed(npc, 0.5);
                        integer theight = 10;
                        vector p = osNpcGetPos(npc);
                        SetScriptAlarm(g, GetWalkTime(llVecDist(p, nd))/2);
                        osNpcMoveToTarget(npc, nd +  <llFrand(1),llFrand(1),theight>, flag);
                        
                    }
                }
                else if (status == "pathf")
                {
                    // Pathfinding - this NPC is following the path to a destination
                    integer avits = llList2Integer(aviAlarm, g);
                    if (llGetUnixTime() > avits)
                    {
                    
                        vector p = osNpcGetPos(npc);
                        string path = llList2String(aviPath, g);
                        llOwnerSay("Path="+path);
                        list pnodes = llParseString2List(path, [":"], []);
                        if (llGetListLength(pnodes)<1)
                        {
                            osNpcSay(npc, "I have arrived");
                            aviStatus =  []+llListReplaceList(aviStatus, [ "" ], g, g);
                            // continue the script (if any), since we reached our destination
                            SetScriptAlarm(g, 0); 
                        }
                        else
                        {
                            integer nextTgt = llList2Integer(pnodes, 0);
                            string ndleft = ":"+llDumpList2String( llList2List(pnodes, 1, llGetListLength(pnodes)), ":");
                            aviPath =  []+llListReplaceList(aviPath, [ ndleft ], g, g);
                            vector v = llList2Vector(wNodes, nextTgt);              
                            SetScriptAlarm(g, GetWalkTime(llVecDist(p, v)));
                            osNpcMoveToTarget(npc, v + <llFrand(1.0),llFrand(1.0), 0.1> , OS_NPC_NO_FLY );
                        }
                    }
                    return;
                }
                else if (status == "prompt")
                {
                    // do nothing
                    jump nexttick;
                }

                
                // Execute the next script line if a script is active
                integer stopNow=0;
                integer k;
                integer scriptIndex = llList2Integer(aviScriptIndex, g);
                while ( scriptIndex>0  && stopNow==0 &&  k++<5) // execute up to 10 lines at once if possible
                {

                    //llOwnerSay("scriptIndex = "+ (string)scriptIndex);
                        integer tsAlarm = llList2Integer(aviAlarm, g);
                        if (tsAlarm >0 && llGetUnixTime() >= tsAlarm ) // The script should continue now
                        {
                            string scriptData = llList2String(aviScriptText, g);
                            string scriptline = GetScriptLine(scriptData, scriptIndex);
                            if (scriptline == "") // End of script
                            {
                                    // This will prevent any further execution
                                    aviScriptIndex =  []+llListReplaceList(aviScriptIndex, [-1], g, g);
                            }
                            else
                            {
                                // Substitute sender with the prompt target, if any
                                string cmd = "! "+ (string)llList2Key(aviTarget, g) +" "+ llList2String(aviNames, g) +" "+ llList2String(aviNames, g) + " "+ scriptline; 
                                stopNow = ProcessNPCCommand(cmd);
                                // Advance script pointer 
                                scriptIndex = llList2Integer(aviScriptIndex, g); 
                                aviScriptIndex =  []+llListReplaceList(aviScriptIndex, [scriptIndex+1], g,g);
                            }
                        }
                        scriptIndex = llList2Integer(aviScriptIndex, g);
                }
                
                @nexttick;
                
                llParticleSystem(
                [
                    PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_EXPLODE,
                    PSYS_SRC_BURST_RADIUS,0,
                    PSYS_SRC_ANGLE_BEGIN,0,
                    PSYS_SRC_ANGLE_END,0,
                    PSYS_SRC_TARGET_KEY,llGetKey(),
                    PSYS_PART_START_COLOR,<1.000000,0.000000,0.000000>,
                    PSYS_PART_END_COLOR,<1.000000,0.000000,0.000000>,
                    PSYS_PART_START_ALPHA,1,
                    PSYS_PART_END_ALPHA,0,
                    PSYS_PART_START_GLOW,0,
                    PSYS_PART_END_GLOW,0,
                    PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                    PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,
                    PSYS_PART_START_SCALE,<0.500000,0.500000,0.000000>,
                    PSYS_PART_END_SCALE,<4.000000,4.000000,0.000000>,
                    PSYS_SRC_TEXTURE,"",
                    PSYS_SRC_MAX_AGE,0.5,
                    PSYS_PART_MAX_AGE,2,
                    PSYS_SRC_BURST_RATE,1,
                    PSYS_SRC_BURST_PART_COUNT,1,
                    PSYS_SRC_ACCEL,<0.000000,0.000000,0.000000>,
                    PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
                    PSYS_SRC_BURST_SPEED_MIN,0,
                    PSYS_SRC_BURST_SPEED_MAX,0,
                    PSYS_PART_FLAGS,
                        0 |
                        PSYS_PART_EMISSIVE_MASK |
                        PSYS_PART_INTERP_COLOR_MASK |
                        PSYS_PART_INTERP_SCALE_MASK
                ]);
                
        }
        
        timerRuns++;
        if (timerRuns%20==0)
        {
            curVisitors = countVisitors();
        }
    }

    listen(integer chan, string name, key id, string str) {    // WARNING "id" is not the uid of the NPC-sender

        string mes = str;                                
        integer x = llSubStringIndex(str, " ");
        if (x >=0)    mes = llGetSubString(str, 0,x-1);

        if (!(osIsNpc(llGetOwnerKey(id)) || llGetOwnerKey(id)==llGetOwner())) 
        {
            llOwnerSay("Denied access to "+llKey2Name(id)); 
            return; 
        }

        //llOwnerSay("<<" + str);
        if (mes == "!") // Something that has been sent from a Listener of attached to an NPC
        {
            ProcessNPCCommand(str);
            return;
        }   
        else if (mes =="FBALL")
        {
            // A poseball has been found. We have to check if it is transparent. If it is not, then we sit the NPC on it
            list tok = llParseString2List(str, [" "] , [""]);
            string npcname= llList2String( tok, 1);
            integer  idx = GetNPCIndex(npcname);
            if (idx<0) return;
            key unpc = llList2Key(aviUids, idx);
            integer i;
            key ball;
            for (i=2; i < llGetListLength(tok);i++)
            {
                ball = llList2String(tok, i);
                list prop = osGetPrimitiveParams(ball, [PRIM_COLOR, 0]); /// This only works we own the poseball
                float alpha = 1.0;
                if (llGetListLength(prop)>0)  alpha = llList2Float(prop, 1);
                if (alpha >0)
                {
                        jump ballFound;
                }
            } 
            //llOwnerSay(npcname + ": All balls transparent");  
            @ballFound;
            if (ball != NULL_KEY)
            {
                    osNpcStand(unpc);
                    osNpcStopMoveToTarget(unpc);
                    osNpcSit(unpc, ball, OS_NPC_SIT_NOW);
                    aviStatus =  []+llListReplaceList(aviStatus, ["sitting"], idx, idx);
            }
        }
        else if (mes == "SETVAR")
        {
            list tok = llParseString2List(str, [" "] , [""]);
            setVar(llList2String(tok,1), llList2String(tok,2));
        }
        else if (llGetSubString(mes, 0, 7) == "CLICKED|")// Message from map editor HUD
        {
            list ll = llParseString2List(str, ["|"] ,[]);
            string cmd1 = llList2String(ll, 0);
            integer num = llList2Integer(ll, 1);
            if (curPoint!= num)
            {
                prevPoint = curPoint;
                curPoint = num;
            }

             list btns = ["Close", "LinkPegs", "UnlinkPegs", "SetName"];
            llDialog(llGetOwner(), "Current peg: "+ (string)curPoint+ " Previous: "+(string)prevPoint, btns, channel);
            return;
        }
        else if  (llGetSubString(mes, 0, 6) == "MRKKEY|")
        {
            list ll = llParseStringKeepNulls(str, ["|"] ,[]);
            integer num = llList2Integer(ll, 1);
            key k = llList2Key(ll, 2);
            wayKeys = [] + llListReplaceList(wayKeys, [k], num,num);

        }
        else if  (llGetSubString(mes, 0, 6) == "MARKER|")
        {
            list ll = llParseStringKeepNulls(str, ["|"] ,[]);
            string cmd1 = llList2String(ll, 0);
            integer num = llList2Integer(ll, 1);
            vector pos = llList2Vector(ll, 2);
            key tk = llList2Key(ll, 4);
            wayPoints = llListReplaceList(wayPoints, [pos], num,num);

            return;
        }
        else if (mes == "ShowPegDialog")
        {
              list btns = ["Close", "RezPegs", "SaveCards", "AddPeg", "DeletePeg", "LinkPegs", "UnlinkPegs", "ScanPegs", "ClearPegs", "SetName"];
              llDialog(llGetOwner(), "First peg: "+ (string)curPoint+ " Second peg: "+(string)prevPoint, btns, 68);
              return;
        }

        
        if (id != llGetOwner()) return; // Admin commands follow

        if  (mes == "SaveNPC")
        {
            llDialog(llGetOwner(), "Select NPC to save your appearance", llList2List(availableNames, 0,10)+ "more", channel);       

            userInputState = "WAIT_APPNAME";
        }
        else if (mes == "LoadNPC")
        {
            llDialog(llGetOwner(), "Select an NPC to load", llList2List(availableNames, 0,10)+"more", channel);     
            userInputState = "WAIT_AVINAME";
        }
        else if (mes == "RemoveNPC")
        {
            llDialog(llGetOwner(), "Select an NPC to delete",  llList2List(availableNames, 0,10)+ "more", channel); 
            userInputState = "WAIT_REMOVEAVI";
        }
        else if (mes == "UpdateNPC")
        {
            llDialog(llGetOwner(), "Select an NPC to re-save appearance ", llList2List(availableNames, 0,10)+"more", channel);     
            userInputState = "WAIT_UPDATE";
        }
        else if (mes == "RemoveAll")
        {
            avis = osGetAvatarList();
            llSay(0, llList2CSV(avis));
            howmany = llGetListLength(avis);
            integer i;
            for (i =0; i < howmany; i+=3)
            {
                if (osIsNpc(llList2Key(avis, i)))
                {
                    list p = llParseString2List(llKey2Name(llList2Key(avis,i)), [" "], []);
                    doRemoveNpc(llList2String(p, 0));
                    //osNpcStand(llList2Key(avis, i));
                    //osNpcRemove(llList2Key(avis, i));
                }
            }
            aviUids = [];
            aviNames = [];
        }
        else if (mes == "LoadAll")
        {
            llSetTimerEvent(0);
            doLoadAll();
            llSetTimerEvent(TIMER_INTERVAL); 
        }
        else if (mes == "InitCmds")
        {    
            llSetTimerEvent(0);
            doInitCmds();
            llSetTimerEvent(TIMER_INTERVAL);    
        }
        else if (mes == "TimerOnOff")
        {
            timerRunning = !timerRunning;
            llSetTimerEvent(TIMER_INTERVAL*timerRunning);
            llOwnerSay("Timer="+(string)timerRunning);
        }
        else if (mes == "DumpData")
        {
            llOwnerSay("Names="+llList2CSV(aviNames));
            llOwnerSay("Status="+llList2CSV(aviStatus));
            llOwnerSay("Nodes="+llList2CSV(aviNodes));
            llOwnerSay("PrevNodes="+llList2CSV(aviPrevNodes));            
            llOwnerSay("ScriptIndex="+llList2CSV(aviScriptIndex));
            llOwnerSay("Alarm="+llList2CSV(aviAlarm));
            llOwnerSay("Curvisitors="+(string)(curVisitors)+ " Timer=" +timerRunning+" timerRuns="+(string)timerRuns);        
            llOwnerSay("Vars="+llList2CSV(scriptVars));
        }
        else if (mes == "ReConfig")
        {
            ReloadConfig();
            LoadMapData();
        }
        else if (mes == "deflectTo")
        {
            list tok = llParseString2List(str, [" "] , [""]);
            deflectToNode = GetNodeIndexByName(llToLower(llList2String(tok,1)));
            llOwnerSay("Deflecting to #"+(string)deflectToNode);
        }
        else if (mes == "AddPeg")
        {
            vector v = llGetPos();
            list res = llGetObjectDetails(llGetOwner(), [OBJECT_POS]);
            wayPoints += llList2Vector(res, 0);
            llOwnerSay("Added point " + (string)(llGetListLength(wayPoints)));
            llRezObject("peg", v, ZERO_VECTOR, ZERO_ROTATION, llGetListLength(wayPoints)-1);
            giveCommands( llGetListLength(wayPoints)-1);
            return;
        }
        else if (mes == "LinkPegs")
        {
            
            integer i;
            for (i=0; i < llGetListLength(wayLinks); i+=2)
            {
                integer a = llList2Integer(wayLinks,i);
                integer b = llList2Integer(wayLinks,i+1);
                if ((a == curPoint && b == prevPoint ) || (b == curPoint && a== prevPoint ))
                {
                    llOwnerSay("Link exists");
                    return;
                }
            }
            wayLinks += curPoint;
            wayLinks += prevPoint;
            giveCommands(curPoint);
            giveCommands(prevPoint);
        }
        else if (mes == "UnlinkPegs")
        {
            
            integer i;
            for (i=0; i < llGetListLength(wayLinks); i+=2)
            {
                integer a = llList2Integer(wayLinks,i);
                integer b = llList2Integer(wayLinks,i+1);
                if ((a == curPoint && b == prevPoint ) || (b == curPoint && a== prevPoint ))
                {
                    wayLinks = llListReplaceList(wayLinks, [], i, i+1);
                    giveCommands(a);
                    giveCommands(b);
                }
            }
        }
        else if (mes == "ClearPegs")
        {
            llRegionSay(PEG_CHAN, "die");
        }
        else if (mes == "ScanPegs")
        {
            llOwnerSay("Scanning pegs ordered");
            llRegionSay(PEG_CHAN, "REPORT");
        }
        else if (mes == "SetName")
        {
            llTextBox(llGetOwner(), "Set Peg #"+(string)curPoint + " name to: ", channel);
            userInputState="WAIT_PEGNAME";
        }
        else if (mes == "RezPegs")
        {
            list lines = llParseString2List(osGetNotecard("__waypoints"), ["\n"], []);
            integer i;
            wayPoints =[];
            wayNames = [];
            for (i=0; i < llGetListLength(lines); i++)
            {
                list line = llParseString2List(llList2String(lines, i), [","], []);
                vector v =  < llList2Float(line, 0), llList2Float(line, 1), llList2Float(line, 2) >;
                string nname = llList2String(line, 3);
                if (v != ZERO_VECTOR)
                {
                    wayPoints += v;
                    wayNames += nname;
                }
            }
            wayLinks = llParseString2List( llStringTrim(osGetNotecard("__links"), STRING_TRIM)  , ["\n", ","], [" "]);
            llOwnerSay(llList2CSV(wayLinks));
            llRegionSay(PEG_CHAN, "die");
            llSleep(0.5);
            vector pos = llGetPos();
            for (i=0; i < llGetListLength(wayPoints); i++)
                llRezObject("peg", pos, ZERO_VECTOR, ZERO_ROTATION, i);
            llSleep(0.5);
            for (i=0; i < llGetListLength(wayPoints); i++)
                     giveCommands(i);
        }
        else if (mes == "UpdatePegs")
        {
            integer i;
             for (i=0; i < llGetListLength(wayPoints); i++)
                     giveCommands(i);
        }
        else if (mes == "SaveCards")
        {
            integer i=0;
            string scriptText = "";
            if (llGetListLength(wayLinks)==0)
            {
                llOwnerSay("No links created! Not saving cards!");
                return;
            }
            for (i=0; i <  llGetListLength(wayPoints); i++)
            {
                vector v = llList2Vector(wayPoints,i);
                scriptText += (string)v.x+","+(string)v.y+","+(string)v.z +  "," + llList2String(wayNames, i) + "\n";
            }

            string cardName = "__waypoints";
            if (llGetInventoryType(cardName)==INVENTORY_NOTECARD)
            {
                llRemoveInventory(cardName);
                llSleep(0.5);
            }
            osMakeNotecard(cardName,scriptText);
            llOwnerSay(cardName +" Saved");
            cardName = "__links";
            if (llGetInventoryType(cardName)==INVENTORY_NOTECARD)
            {
                llRemoveInventory(cardName);
                llSleep(0.5);
            }
            scriptText = "";
            for (i=0; i <  llGetListLength(wayLinks); i+=2)
                scriptText += llList2String(wayLinks,i)+ ","+llList2String(wayLinks,i+1)+ ",\n";
            osMakeNotecard(cardName,scriptText);
            llOwnerSay(cardName +" Saved");
            llSleep(1);
            LoadMapData();
        }
        else if (userInputState != "" && mes != "")//  Process dialog commands
        {
            if (mes == "more")
            {
                 llDialog(llGetOwner(), "Select an NPC", llList2List(availableNames, 11,-1), channel);
            }
            else
            {
                if (userInputState == "WAIT_APPNAME")
                {
                    osAgentSaveAppearance(llGetOwner(), "APP_"+llToLower(mes));
                    llSay(0,  "Saved Appearance " + llGetOwner() + " -> APP_"+llToLower(mes));
                }
                else if (userInputState == "WAIT_PEGNAME")
                {
                    wayNames = [] + llListReplaceList(wayNames, [llStringTrim(mes, STRING_TRIM)],curPoint, curPoint);
                    giveCommands(curPoint);
                    llOwnerSay("Waypoint  " +(string)curPoint+ " name='"+mes+"'");
                }
                else if (userInputState == "WAIT_AVINAME")
                {
                    doLoadNPC(mes, GetLastName(mes));

                }
                else if (userInputState == "WAIT_UPDATE")
                {
                    integer idx = GetNPCIndex(mes);
                    if (idx >=0)
                    {
                        key uu = llList2Key(aviUids, idx);
                        osNpcSaveAppearance(uu, "APP_"+llToLower(mes));
                        llOwnerSay("Updating  APP_"+llToLower(mes) );
                    }
                    else llOwnerSay("Not found "+mes);
                }
                else if (userInputState == "WAIT_REMOVEAVI")
                {
                    doRemoveNpc(mes);
                }

                userInputState="";
            }
        }
    }
    
    
    link_message(integer lnk, integer num, string command, key npc) // This script is in the object too.
    {
        if (num != -1) // -1 means we sent it
        {
            ProcessNPCCommand(command);
        }
    }

    changed(integer change)
    {
        if (change & (CHANGED_REGION_START | CHANGED_OWNER | CHANGED_REGION))
        {
            llResetScript();
        }
    }    

}

