// Caller genérico para eventos pontuais

default
{
    state_entry()
    {
        llSetTimerEvent(1800.0); // 30 minutos em segundos
    }

    timer()
    {
        // Executa qualquer comando unico
        llRegionSay(68, "! 0000-0000-0000-0000 Name Name command");
        // Executa um script de note-card
        //llRegionSay(68, "! 0000-0000-0000-0000 Name Name run-notecard script.scr");
        llOwnerSay("Ocorreu evento");
        
    }
}