integer k = 0; // Int de estados
default
{
    state_entry()
    {
        // Timer inicial para o script comecar
        llSetTimerEvent(30.0);
    }

    timer()
    {
        // Estado 0: Inicio Primeira Aula
        if (k == 0) {
            llOwnerSay("Aula 1 na SalaX Iniciando");
            llRegionSay(68, "! 0000-0000-0000-0000 ProfessorX ProfessorX run-notecard AulaProfessorSX.scr");
            llSleep(1.0); // Sleep para tempo de processamento do NPC Controller
            llRegionSay(68, "! 0000-0000-0000-0000 Estudantey Estudantey run-notecard AulaEstudanteSX.scr");
            llSleep(1.0);
            llRegionSay(68, "! 0000-0000-0000-0000 EstudanteY EstudanteY run-notecard AulaEstudanteSX.scr");
            llSetTimerEvent(300.0); // Define a duracao da aula
            k = 1; // Muda para o próximo estado
        } 
        // Estado 1: Termino da Primeira Aula
        else if (k == 1) {
            llOwnerSay("Aula 1 na SalaX Finalizada");
            llRegionSay(68, "! 0000-0000-0000-0000 ProfessorX ProfessorX run-notecard AulaFimSX.scr");
            llRegionSay(68, "! 0000-0000-0000-0000 EstudanteY EstudanteY run-notecard AulaFimSX.scr");
            llRegionSay(68, "! 0000-0000-0000-0000 EstudanteY EstudanteY run-notecard AulaFimSX.scr");
            llSetTimerEvent(90.0); // Define o intervalo até a proxima aula iniciar
            k = 0; // Muda para o proximo estado, neste caso reiniciando o ciclo
        }
    }

}