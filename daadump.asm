;;; APP BOILERPLATE

#define APP_NAME                "DAADump "
#include "app.asm"


;;; LIBRARY INCLUSIONS

#define screenData              saveSScreen
#define drawData                screenDataEnd
#define writeData               drawDataEnd
#define interruptData           writeDataEnd
#define keyboardData            interruptDataEnd

#include "screen.asm"
#include "draw.asm"
#include "write.asm"
#include "interrupt.asm"
#include "keyboard.asm"

#include "fontFBF.asm"

;;; APP-SPECIFIC DATA FILES

;;; HELPER ROUTINES

genTable:
        ; input
        ;   DE -- pointer to table space
        ;
        ; output
        ;   (DE) -- table filled with DAA result
        ;
        PUSH    BC
        PUSH    DE
        PUSH    HL
        LD      L, E
        LD      H, D
        LD      (HL), $AA
        INC     DE
        LD      BC, 4095
        LDIR
        POP     HL
        POP     DE
        POP     BC
        RET


;;; APPLICATION CODE

appMain:
        PUSH    DE               ; STACK: [PC DE]
        PUSH    HL               ; STACK: [PC DE HL]
        CALL    screenInit       ; initialize screen library
        CALL    drawInit         ; initialize draw library
        CALL    writeInit        ; initialize write library
        LD      HL, fontFBF      ; set font to FBF font
        CALL    writeSetFont     ;
        CALL    interruptInit    ; initialize interrupt library
        CALL    keyboardInit     ; initialize keyboard library
        EI                       ; enable interrupts
        LD      BC, 9
        LD      DE, OP1
        LD      HL, varName
        LDIR
        LD      HL, (1 << 11) * 2
        bcall(_CreateAppVar)
        INC     DE
        INC     DE
        CALL    genTable
        ;;
        CALL    keyboardExit     ; de-initialize the keyboard library
        CALL    interruptExit    ; de-initialize the interrupt library
        CALL    writeExit        ; de-initialize the write library
        CALL    drawExit         ; de-initialize the draw library
        CALL    screenExit       ; de-initialize the screen library
        POP     HL               ; STACK: [PC DE]
        POP     DE               ; STACK: [PC]
        RET                      ; return




varName:
        .db     AppVarObj, "DAATable", 0

