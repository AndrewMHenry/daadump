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

;;; #defines

#define TABLE_SIZE      4096
#define NUM_FLAG_INPUTS 8


;;; HELPER ROUTINES

;old_genTableHelper:
;        ; input
;        ;   C       flag byte to use
;        ;   DE      pointer to table space
;        ;
;        ; output
;        ;   (DE)    filled with all DAA results for C value
;        ;
;        DI
;        PUSH    BC                      ; STACK: [PC BC]
;        PUSH    DE                      ; STACK: [PC BC DE]
;        PUSH    HL                      ; STACK: [PC BC DE HL]
;        LD      HL, 0                   ; HL = SP
;        ADD     HL, SP                  ;
;        INC     D                       ; SP = DE + 512
;        INC     D                       ;
;        EX      DE, HL                  ;
;        LD      SP, HL                  ;
;        EX      DE, HL                  ;
;        LD      D, $ff                  ; D (A input) = 0xff
;        LD      E, C                    ; E (F input) = C (flag byte)
;genTableHelper_loop:                    ; [loop]
;        PUSH    DE                      ; AF = DE (input)
;        POP     AF                      ;
;        DAA                             ; do it!
;        PUSH    AF                      ; put result in table
;        DEC     D                       ; decrement D (A input)
;        DJNZ    genTableHelper_loop     ; repeat loop if B nonzero
;        LD      SP, HL                  ; restore SP
;        POP     HL                      ; STACK: [PC BC DE]
;        POP     DE                      ; STACK: [PC BC]
;        POP     BC                      ; STACK: [PC]
;        EI                              ;
;        RET                             ; return


genTableHelper:
        ; input
        ;   C       flag byte to use
        ;   DE      pointer to table space
        ;
        ; output
        ;   (DE)    filled with all DAA results for C value
        ;
        PUSH    BC                      ; STACK: [PC BC]
        PUSH    DE                      ; STACK: [PC BC DE]
        PUSH    HL                      ; STACK: [PC BC DE HL]
        LD      B, 0                    ; B = 0
genTableHelper_loop:                    ; [loop]
        PUSH    BC                      ; AF = BC (input)
        POP     AF                      ;
        DAA                             ; do it!
        PUSH    AF                      ; HL = output
        POP     HL                      ;
        LD      A, L                    ; store output in table
        LD      (DE), A                 ;
        INC     DE                      ;
        LD      A, H                    ;
        LD      (DE), A                 ;
        INC     DE                      ;
        INC     B                       ; advance B (A input)
        INC     B                       ; repeat loop if B nonzero
        DJNZ    genTableHelper_loop     ;
        POP     HL                      ; STACK: [PC BC DE]
        POP     DE                      ; STACK: [PC BC]
        POP     BC                      ; STACK: [PC]
        RET                             ; return


genTable:
        ; input
        ;   DE -- pointer to table space
        ;
        ; output
        ;   (DE) -- table filled with DAA result
        ;
        PUSH    BC                  ; STACK: [PC BC]
        PUSH    DE                  ; STACK: [PC BC DE]
        PUSH    HL                  ; STACK: [PC BC DE HL]
        LD      B, NUM_FLAG_INPUTS  ; B (loop counter) = number of flag bytes
        LD      HL, flagInputs      ; HL = base of flag input table
genTable_loop:                      ; [loop]
        LD      C, (HL)             ; C = flag byte from table
        CALL    genTableHelper      ;
        INC     D                   ; DE += 512 (offset for next flag byte)
        INC     D                   ;
        INC     HL                  ; point HL to next flag byte
        DJNZ    genTable_loop       ; repeat loop if B (loop counter) nonzero
        POP     HL                  ; STACK: [PC BC DE]
        POP     DE                  ; STACK: [PC BC]
        POP     BC                  ; STACK: [PC]
        RET                         ; return

old_genTable:
        ; input
        ;   DE -- pointer to table space
        ;
        ; output
        ;   (DE) -- table filled with DAA result
        ;
        PUSH    BC                  ; STACK: [PC BC]
        PUSH    DE                  ; STACK: [PC BC DE]
        PUSH    HL                  ; STACK: [PC BC DE HL]
        PUSH    IX                  ; STACK: [PC BC DE HL IX]
        LD      BC, NUM_FLAG_INPUTS ; B = 0, C = outer flag counter
        PUSH    DE                  ; IX = table pointer
        POP     IX                  ;
        LD      D, 0                ; D (ACC input) = 0
genTable_outer:                     ; [outer loop]
        LD      HL, flagInputs      ; E = flag input
        ADD     HL, BC              ;
        LD      E, (HL)             ;
genTable_inner:                     ; [inner loop]
        PUSH    DE                  ; AF = DE
        POP     AF                  ;
        DAA                         ; do the DAA
        PUSH    AF                  ; HL = AF
        POP     HL                  ;
        LD      (IX), L             ; load HL into table and increment pointer
        INC     IX                  ;
        LD      (IX), H             ;
        INC     IX                  ;
        INC     D                   ; increment ACC byte
        DJNZ    genTable_inner      ; repeat inner loop if B nonzero
        DEC     C                   ;
        JR      NZ, genTable_outer  ; repeat outer loop if C nonzero
        POP     IX                  ; STACK: [PC BC DE HL]
        POP     HL                  ; STACK: [PC BC DE]
        POP     DE                  ; STACK: [PC BC]
        POP     BC                  ; STACK: [PC]
        RET                         ; return

flagInputs:
        .db     00000000b
        .db     00000001b
        .db     00000010b
        .db     00000011b
        .db     00010000b
        .db     00010001b
        .db     00010010b
        .db     00010011b

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
        ;;
        LD      BC, 9            ; put name in OP1
        LD      DE, OP1          ;
        LD      HL, varName      ;
        LDIR                     ;
        LD      HL, TABLE_SIZE   ; HL = size
        bcall(_CreateAppVar)     ; create the AppVar
        INC     DE               ; move DE past size bytes
        INC     DE               ;
        CALL    genTable         ; create table at DE in AppVar
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

