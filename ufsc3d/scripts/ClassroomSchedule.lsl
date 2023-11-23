// Caller especifico para controle de eventos com cronograma
// Organizado para controlar as aulas que ocorrem em uma sala

list events = [];

// Paramentros:
//    id   - identificador do evento.
//    time - tempo em que o evento vai executar.
//    data - qualquer informacao desejada passar ao handler.
scheduleEvent(integer id, integer time, string data) {
    events = llListSort((events = []) + events + [time, id, data], 3, TRUE);
    setTimer(FALSE);
}

// Configura o timer para os eventos
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

// Handler dos eventos
handleEvent(integer id, string data) {
    
    // X = ID do professor, Y = ID do estudante, SX = ID da sala
    // Estrutura pode ser expandida para quantas aulas forem necessarias para a sala
    if (id == 1) {
        llOwnerSay(data);
        llRegionSay(68, "! 0000-0000-0000-0000 ProfessorX ProfessorX run-notecard AulaProfessorSX.scr");
        llRegionSay(68, "! 0000-0000-0000-0000 EstudanteY EstudanteY run-notecard AulaEstudanteSX.scr");
        llRegionSay(68, "! 0000-0000-0000-0000 EstudanteY EstudanteY run-notecard AulaEstudanteSX.scr");
        scheduleEvent(2, llGetUnixTime() + 60, "Transicao1");
    } else if (id == 2) {
        llOwnerSay(data)
        llRegionSay(68, "! 0000-0000-0000-0000 ProfessorX ProfessorX run-notecard AulaFimSX.scr");
        llRegionSay(68, "! 0000-0000-0000-0000 EstudanteX EstudanteX run-notecard AulaFimSX.scr");
        llRegionSay(68, "! 0000-0000-0000-0000 EstudanteX EstudanteX run-notecard AulaFimSX.scr");
        scheduleEvent(3, llGetUnixTime() + 30, "Aula 2");
    } else if (id == 3) {
        llOwnerSay(data)
        llRegionSay(68, "! 0000-0000-0000-0000 ProfessorX ProfessorX run-notecard AulaProfessorSX.scr");
        llRegionSay(68, "! 0000-0000-0000-0000 EstudanteY EstudanteY run-notecard AulaEstudanteSX.scr");
        llRegionSay(68, "! 0000-0000-0000-0000 EstudanteY EstudanteY run-notecard AulaEstudanteSX.scr");
        scheduleEvent(4, llGetUnixTime() + 60, "Transicao2");
    } else if (id == 4) {
        llOwnerSay(data)
        llRegionSay(68, "! 0000-0000-0000-0000 ProfessorX ProfessorX run-notecard AulaFimSX.scr");
        llRegionSay(68, "! 0000-0000-0000-0000 EstudanteY EstudanteY run-notecard AulaFimSX.scr");
        llRegionSay(68, "! 0000-0000-0000-0000 EstudanteY EstudanteY run-notecard AulaFimSX.scr");
        scheduleEvent(1, llGetUnixTime() + 30, "Aula 1");
    }
}

default {
    state_entry() {
        scheduleEvent(1, llGetUnixTime() + 10, "Aula 1");
    }

    timer() {
        llSetTimerEvent(0.0);
        do {
            // Dispara o evento
            handleEvent(llList2Integer(events, 1), llList2String(events, 2));
        
            // Remove o evento disparado
            integer l = events != [];
            if (l > 0) {
                if (l > 3)
                    events = llList2List((events = []) + events, 3, -1);
                else events = [];
            }

            // Prepara o timer pro proximo evento
        } while (setTimer(TRUE));
    }
}