*-----------------------------------------------------------
* Title      : A Disassembler for the Motorola MC68000 Microprocessor
* Written by : Jakob Wilter & Scott Bryar
* Date       : March 12, 2020
* Description: CSS422 Final Project
*-----------------------------------------------------------
* The following program is a disassembler for EASy68K Assembler. This application
* translate machine language into assembly langauge (68K Instructions).
*-----------------------------------------------------------


*-----------------------------------------------------------
* Constants and Key Variable

    ORG    $1000

* Message displayed at bootup
SCN0     DC.B    '                  *********************************************',0
SCN1     DC.B    '                             CSS 422 Final Project             ',0
SCN2     DC.B    '                                68k Disassembler               ',0
SCN3     DC.B    '                     Written by: Jakob Wilter & Scott Bryar    ',0
SCN4     DC.B    '                  *********************************************',0
SCN5     DC.B    '                                                               ',0  

* Messages for input request of users
MSG_START   DC.B    'Please enter the starting address: ',0
MSG_END     DC.B    'Please enter the ending address: ',0
MSG_RETRY   DC.B    'Disassemble more code? (Y/N): ',0
MSG_E0      DC.B    'End address must be after the start address. Please try again.',0
MSG_E1      DC.B    'Address cannot be longer than longword. Please try again.',0
MSG_E2      DC.B    'Re-enter valid hex numbers.',0
MSG_E3      DC.B    'Address must be an even number.',0
MSG_CONT    DC.B    '>> Press enter to continue disassembly >>',0

* Instructions
C_JSR        DC.B    'JSR',0
C_BTST       DC.B    'BTST',0
C_ROL        DC.B    'ROL',0
C_ROR        DC.B    'ROR',0
C_LSL        DC.B    'LSL',0
C_LSR        DC.B    'LSR',0
C_NEGW       DC.B    'NEG.',0
C_DIVSW      DC.B    'DIVS.W',0
C_MULSW      DC.B    'MULS.W',0
C_MOVEB      DC.B    'MOVE.B',0
C_MOVEW       DC.B    'MOVE.W',0
C_MOVEL       DC.B    'MOVE.L',0
C_MOVEAW      DC.B    'MOVEA.W',0
C_MOVEAL      DC.B    'MOVEA.L',0
C_MOVEM       DC.B    'MOVEM.',0
C_ASL        DC.B    'ASL',0
C_ASR        DC.B    'ASR',0
C_DATA       DC.B    'DATA',0
C_SUB        DC.B    'SUB.',0
C_SUBA       DC.B    'SUBA.',0
C_AND        DC.B    'AND.',0
C_ADD        DC.B    'ADD.',0
C_SUBI       DC.B    'SUBI.',0
C_ORI        DC.B    'ORI.',0
C_NOT        DC.B    'NOT.',0
C_MUL        DC.B    'MULS.',0
C_NEG1        DC.B    'NEG',0
C_CMP        DC.B    'CMP.',0
C_CMPI       DC.B    'CMPI.',0
C_CMPA       DC.B    'CMPA.',0
C_EOR        DC.B    'EOR.',0
C_EORI       DC.B    'EORI.',0
C_ADDA       DC.B    'ADDA.',0
C_ADDQ       DC.B    'ADDQ.',0
C_BEQ        DC.B    'BEQ',0
C_BNE        DC.B    'BNE',0
C_BLT        DC.B    'BLT',0
C_BHI        DC.B    'BHI',0
C_BRA        DC.B    'BRA',0
C_NOP        DC.B    'NOP',0
C_RTS        DC.B    'RTS',0
C_LEA        DC.B    'LEA',0

CARRY       EQU     $0D
FEED_LN     EQU     $0A

* Letters
C_A       DC.B    'A',0
C_B       DC.B    'B',0
C_C       DC.B    'C',0
C_D       DC.B    'D',0
C_E       DC.B    'E',0
C_F       DC.B    'F',0

* Bytes & Symbols
C_DOT        DC.B    '.',0
C_HEX        DC.B    '$',0
C_BYTE       DC.B    'B ',0
C_WORD       DC.B    'W ',0
C_LONG       DC.B    'L ',0
C_DN         DC.B    'D',0
C_AN         DC.B    'A',0
SPACE       DC.B    ' ',0
NEWLINE     DC.B    '',CARRY,FEED_LN,0
C_TAB       DC.B    '   ',0
C_COMMA     DC.B    ',',0
C_OBRACK    DC.B    '(',0
C_CBRACK    DC.B    ')',0
C_PLUS      DC.B    '+',0
C_NEG       DC.B    '-',0
C_HASH      DC.B    '#',0
C_SLASH     DC.B    '/',0

H         DS.B    1

P1        DS.B    1 
P2        DS.B    1  
P3        DS.B    1    
P4        DS.B    1            

* Error and completion messages
MSG_CRASH      DC.B    'ERROR: Disassembly could not be completed. ',0
MSG_CMPLT      DC.B    'Disassembly complete.',0

DISPLAY_CT   DS.B    1          ; Line counter on display
NUM_LINES     EQU     30        ; Number of lines printed at a time

START_ADDR   DS.L    1          ; User will input starting address for disassembly
END_ADDR     DS.L    1          ; User will input ending address for disassembly
    
START:                          ; first instruction of program

*-----------------------------------------------------------
* Display Bootup Screen
BOOTSCREEN
        LEA     SCN0,A1             ; Uses messages frm SCN0 TO SCN5
        MOVE    #13,D0
        TRAP    #15
        LEA     SCN1,A1
        TRAP    #15
        LEA     SCN2,A1
        TRAP    #15
        LEA     SCN3,A1
        TRAP    #15
        LEA     SCN4,A1
        TRAP    #15
        LEA     SCN5,A1             ; Empty line
        LEA     NEWLINE,A1
        MOVE.B  #14,D0
        TRAP    #15

        *-----------------------------------------------------------
* Reads Start and End Addresse
* Request user for address
IO_BOOT
        LEA     MSG_START,A1        ; Request to retrieve first number
        BSR     IO_ADDRESS
        BTST    #0,D4               ; Test whether starting address is odd
        BNE     ERR3                ; Error if odd
        MOVE.L  D4,D7               ; Stores starting address in D7 temp
        LEA     MSG_END,A1          ; Reads end address
        BSR     IO_ADDRESS
        CMP.L   D7,D4               ; Check whether starting address is less than ending address
        BGT     D_ADDRESS           ; Run program if start < end
        BRA     ERR0                ; Throw error if start > end

IO_ADDRESS
        MOVEA.L A1,A3               ; Store error message
        MOVE.B  #14,D0              
        TRAP    #15                 
        CLR     D4                  ; Reset D4 register
        LEA     START_ADDR,A1       ; Store data to A1
        MOVE.B  #2,D0              
        TRAP    #15
        CMP.B   #8,D1               ; Error if input longer than longword
        BGT     ERR1
        MOVE.B  D1,D5               ; Store input length in D5

IO_BOOTLOOP
        LEA     START_ADDR,A2       ; Stores starting address in A2

IOLP
        MOVE.B  (A2)+,D2            ; Stores current addr to D2
        SUB.B   #1,D5               ; Counter--
        BSR     D2H             
        CMP.B   #$F,D1
        BEQ     ERR2
        MOVE.B  D5,D6               ; Count stored in D6
        MULS    #4,D6               ; Count of shift left
        LSL.L   D6,D3
        ADD.L   D3,D4               ; Add data to D4 from D3
        MOVE.L  #0,D3               ; Empty D3
        CMP.B   #0,D5 
        BNE     IOLP
        RTS

* Display error if start address > end address
ERR0
        LEA     MSG_E0,A1           ; Load error message into A1
        MOVE.B  #13,D0
        TRAP    #15
        BRA     IO_BOOT             ; Branch to start

* Display error if address too long
ERR1
        LEA     MSG_E1,A1           ; Load error message into A1
        MOVE.B  #13,D0
        TRAP    #15
        MOVEA.L A3,A1               ; Store address to A1 from A3
        BRA     IO_ADDRESS          ; Branch to IO

* Display error if invalid input
ERR2
        LEA     MSG_E2,A1           ; Load error message into A1
        MOVE.B  #13,D0
        TRAP    #15
        MOVEA.L A3,A1               ; Store address to A1 from A3
        BRA     IO_ADDRESS          ; Branch to IO

* Display error if odd
ERR3
        LEA     MSG_E3,A1           ; Load error message into A1
        MOVE.B  #13,D0 
        TRAP    #15
        BRA     IO_BOOT             ; Branch to IO

*-----------------------------------------------------------
* Display Current address OpCode disassembly
D_ADDRESS
        MOVE.L  D7,START_ADDR
        MOVE.L  D4,END_ADDR
        BSR     CLEAR_ALL
        MOVEA.L START_ADDR,A6       ; Store starting address in A6
        MOVE.B  #NUM_LINES,DISPLAY_CT

        LEA     NEWLINE,A1          ; New line in display
        MOVE.B  #14,D0
        TRAP    #15

NEW_ADDRESS
        MOVE.L  A6,D7               ; Store current address in D7
        CMP.L   END_ADDR,D7         ; Check that current address <= end address
        BGT     PRMPT_AGAIN0        ; End if current address if greater than end address
        LEA     D_ADDRESSEND,A2

*-----------------------------------------------------------
* Address displayed as a hexidecimal value
D_ADDRESSSTART
        MOVE.B  #2,D6               ; Sets D6 as loop counter 
        MOVE.L  D7,D2               ; Stores OpCode to D2 
        SWAP    D2                  ; Swap address so only first word is displayed
        BRA     D_ADDRESS2

D_ADDRESS1
        MOVE.W  D7,D2               ; Load data to D2 from D7
        
D_ADDRESS2
        MOVE.W  D2,D1               ; D1 stores first byte
        MOVE.W  D2,D3               ; D3 stores second byte
        MOVE.W  D2,D4               ; D4 stores third byte
        MOVE.W  D2,D5               ; D5 stores fourth byte
        LSR.W   #8,D1               ; Shift D1 right so first byte is placed in last byte of word
        LSR.W   #4,D1
        LSL.W   #4,D3               ; Shift D3 left to remove first byte
        LSR.W   #8,D3               ; Shift D3 right to place in last byte
        LSR.W   #4,D3
        LSL.W   #8,D4               ; Shift D4 left to remove two bytes of word
        LSR.W   #8,D4               ; Shift D4 right to place in last byte
        LSR.W   #4,D4
        LSL.W   #8,D5               ; Shifts D5 left to remove 3 bytes of word
        LSL.W   #4,D5               
        LSR.W   #8,D5
        LSR.W   #4,D5
        LEA     D_ADDRESS3,A3       ; Store address to A3
        CMP.B   #9,D1
        BGT     CONVERTER
        MOVE.B  #3,D0
        TRAP    #15
        
D_ADDRESS3   
        MOVE.B  D3,D1               
        * Digits to ASCII
        LEA     D_ADDRESS4,A3        ; Store address to A3
        CMP.B   #9,D1     
        BGT     CONVERTER  
        MOVE.B  #3,D0 
        TRAP    #15

D_ADDRESS4
        MOVE.B  D4,D1                ; Store data to D1 from D4 
        LEA     D_ADDRESS5,A3
        CMP.B   #9,D1
        BGT     CONVERTER        
        MOVE.B  #3,D0
        TRAP    #15

D_ADDRESS5
        MOVE.B  D5,D1                ; Store data to D1 from D5
        LEA     D_ADDRESS6,A3
        CMP.B   #9,D1
        BGT     CONVERTER
        MOVE.B  #3,D0
        TRAP    #15
        
D_ADDRESS6
        SUB.B   #1,D6
        CMP.B   #0,D6
        BNE     D_ADDRESS1
        JMP     (A2)                 ; Jump to A2

D_ADDRESSEND
        LEA     C_TAB,A1
        MOVE.B  #14,D0
        TRAP    #15

*-----------------------------------------------------------
* Pushes first byte of OpCode to Branch Table for decoding
        CLR.L   D1                  ; Clear Data Registers
        CLR.L   D2
        CLR.L   D3
        CLR.L   D4
        CLR.L   D5
        CLR.L   D6
        MOVE.W  (A6),D6             ; Load location of A6 to D6
        MOVE.B  (A6)+,D2            ; Load data from current to D1
        MOVE.B  D2,D7               ; Store data from D2 into D7
        LSL.W   #8,D7
        MOVE.B  D2,D3               ; Loads data to D3
        LSR.B   #4,D3               ; Shift right to remove ones place
        LSL.B   #4,D2               ; Shift left to remove tens place
        LSR.B   #4,D2               ; Reset
        MOVE.B  D2,D5
        MOVE.B  D3,H
        BRA     OPCODE_TABLE                ; Branch to Table
*-----------------------------------------------------------
* Picks OpCode to use for disassembly
OPCODE_TABLE    
        CMP.B   #$0,D3              ; Decode in immediate operation
        BEQ     ARTHM0
        CMP.B   #$4,D3              ; Decode miscellaneous
        BEQ     COMP_SIZE0
        CMP.B   #$5,D3
        BEQ     ADDQ                ; Decode ADDQ
        CMP.B   #$6,D3
        BEQ     BCC
        CMP.B   #$9,D3              ; Decode sub
        BEQ     SUB
        CMP.B   #$C,D3              ; Decode sub as AND
        BEQ     SUB
        CMP.B   #$D,D3              ; Decode sub as ADD
        BEQ     SUB
        CMP.B   #$B,D3              ; Decode sub as CMP / EOR
        BEQ     SUB
        CMP.B   #$1,D3
        BEQ     MOVEB               ; Decode MOVEB
        CMP.B   #$3,D3
        BEQ     MOVEW               ; Decode MOVEW
        CMP.B   #$2,D3
        BEQ     MOVEL               ; Decode MOVEL
        CMP.B   #$8,D3
        BEQ     DIVSW               ; Decode DIVSW
        CMP.B   #$E,D3
        BEQ     LSLLSR              ; Decode LSLLSR
        BRA     INC_OPCODE

*-----------------------------------------------------------
* Subroutines for instructions
MOVEW
        LSR.B   #1,D2
        MOVE.B  D2,P1             ; Store data from D2 into P1 to maintain original
        MOVE.B  (A6),D2           ; Load address of A6 into D2
        LSL.B   #5,D2
        LSR.B   #5,D2
        MOVE.B  D2,P4             ; Store manipulated data from D2 into P4
        MOVE.B  (A6)+,D2          ; Increment and load data from A6 into D2
        LSL.B   #2,D2
        LSR.B   #5,D2
        MOVE.B  D2,P3             ; After manipulation from shifts, load data from D2 to P3
        LSL.W   #7,D6
        LSR.W   #8,D6 
        LSR.W   #5,D6 
        MOVE.B  D6,P2             ; Load manipulated data from D6 into P2
        CMP.B   #$1,P2
        BEQ     MOVEAW
        LEA     C_MOVEW,A1
        MOVE.B  #14,D0
        TRAP    #15 
        CMP.B   #$0,P3           
        BEQ     MOVEB_DN0
        CMP.B   #$1,P3
        BEQ     MOVEA_0
        CMP.B   #$2,P3
        BEQ     MOVE_AN0
        CMP.B   #$3,P3
        BEQ     MOVE_AN1
        CMP.B   #$4,P3
        BEQ     MOVE_AND0
        CMP.B   #$7,P3
        BEQ     ADD_I

MOVEAW
        LEA     C_MOVEAW,A1
        MOVE.B  #14,D0
        TRAP    #15 
        CMP.B   #$0,P3           
        BEQ     MOVEB_DN0
        CMP.B   #$1,P3
        BEQ     MOVEA_0
        CMP.B   #$2,P3
        BEQ     MOVE_AN0
        CMP.B   #$3,P3
        BEQ     MOVE_AN1
        CMP.B   #$4,P3
        BEQ     MOVE_AND0
        CMP.B   #$7,P3
        BEQ     ADD_I

MOVEL
        LSR.B   #1,D2
        MOVE.B  D2,P1           ; Store data from original data from D2 to P1 as copy
        MOVE.B  (A6),D2         ; Load data to D2
        LSL.B   #5,D2
        LSR.B   #5,D2
        MOVE.B  D2,P4           ; Store data from D2 into P4
        
        MOVE.B  (A6)+,D2        ; Increment through A6 and store data to D2
        LSL.B   #2,D2
        LSR.B   #5,D2
        MOVE.B  D2,P3           ; Store data from D2 to P3
        
        LSL.W   #7,D6
        LSR.W   #8,D6 
        LSR.W   #5,D6 
        MOVE.B  D6,P2           ; Store contents of D6 into P2 after manipulation
        CMP.B   #$1,P2          ; Check against P2
        BEQ     MOVEAL          ; If successful, branch to MOVEAL
        LEA     C_MOVEL,A1      ; Load effective address into A1
        MOVE.B  #14,D0
        TRAP    #15 
        CMP.B   #$0,P3          ; Check against P3
        BEQ     MOVEB_DN0       ; If equal, branch
        CMP.B   #$1,P3
        BEQ     MOVEA_0
        CMP.B   #$2,P3
        BEQ     MOVE_AN0
        CMP.B   #$3,P3
        BEQ     MOVE_AN1
        CMP.B   #$4,P3
        BEQ     MOVE_AND0
        CMP.B   #$7,P3
        BEQ     ADD_I

MOVEAL
        LEA     C_MOVEAL,A1
        MOVE.B  #14,D0
        TRAP    #15 
        CMP.B   #$0,P3           
        BEQ     MOVEB_DN0
        CMP.B   #$1,P3
        BEQ     MOVEA_0
        CMP.B   #$2,P3
        BEQ     MOVE_AN0
        CMP.B   #$3,P3
        BEQ     MOVE_AN1
        CMP.B   #$4,P3
        BEQ     MOVE_AND0
        CMP.B   #$7,P3
        BEQ     ADD_I        

MOVEB
        LEA     C_MOVEB,A1
        MOVE.B  #14,D0
        TRAP    #15 
        LSR.B   #1,D2
        MOVE.B  D2,P1           ; Move data from D2
        MOVE.B  (A6),D2         ; Store data to D2
        LSL.B   #5,D2
        LSR.B   #5,D2
        MOVE.B  D2,P4           ; Then store data from D2 into P4
        MOVE.B  (A6)+,D2        ; Increment and load contents of A6 into D2
        LSL.B   #2,D2           ; Shift D2 left
        LSR.B   #5,D2           ; Then shift D2 right
        MOVE.B  D2,P3           ; Then load content of D2 into P3
        LSL.W   #7,D6
        LSR.W   #8,D6 
        LSR.W   #5,D6 
        MOVE.B  D6,P2           ; Store data from D6 into P2
        CLR.L   D5              ; Clear long data in D5
        CMP.B   #$0,P3           
        BEQ     MOVEB_DN0
        CMP.B   #$1,P3
        BEQ     MOVEA_0
        CMP.B   #$2,P3
        BEQ     MOVE_AN0
        CMP.B   #$3,P3
        BEQ     MOVE_AN1
        CMP.B   #$4,P3
        BEQ     MOVE_AND0
        CMP.B   #$7,P3
        BEQ     ADD_I
        BRA     OP_HELPER0      

JSR
        LEA     C_JSR,A1        ; Store ea in A1
        MOVE.B  #14,D0
        TRAP    #15 
        MOVE.B  D6,D2           ; Load data to D2 from D6
        LSL.B   #5,D2
        LSR.B   #5,D2
        MOVE.B  D2,P4           ; Load data to D2 from P4
        MOVE.B  D6,D2           ; Load data to D2 from D6
        LSL.B   #2,D2
        LSR.B   #5,D2
        MOVE.B  D2,P3           ; Load data into D2 from P3
        MOVE.B  #$3,D4
        CMP.B   #$2,P3
        BEQ     MOVE_AN0
        LEA     C_TAB,A1
        MOVE    #3,D1
        TRAP    #15
        CMP.B   #$7,P3          ; Check against value 7
        BEQ     ADD_IMD0
        
BTST 
        LEA C_BTST,A1
        MOVE.B  #14,D0
        TRAP    #15  
        MOVE.B  D6,D2           ; Load data to D2 from D6
        LSL.B   #5,D2
        LSR.B   #5,D2
        MOVE.B  D2,P1           ; Load data from D2 into P1
        MOVE.B  D6,D2           ; Load data to D2 from D6
        LSL.B   #2,D2
        LSR.B   #5,D2
        MOVE.B  D2,P2           ; Load data from D2 into P2
        MOVE.W  D6,D2           ; Load data to D2 from D6
        LSL.W   #4,D2
        LSR.W   #8,D2
        LSR.W   #5,D2
        MOVE.B  D2,P3
        MOVE.W  D6,D2           ; Load data to D2 from D6
        LSL.W   #7,D2
        LSR.W   #8,D2
        LSR.W   #7,D2
        MOVE.B  D2,H           ; Store data from manipulated D2 into H
        CMP.B   #0,H           ; Compare instruction on H
        BEQ     CHECK_BTST      ; If succesful, branch to CHECK_BTST
        LEA     C_TAB,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_D,A1
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B   #$4,D5         ; Load value 4 into D5
        MOVE.B  P3,D1           ; Store P3 data into D1
        MOVE.B  #3,D0
        TRAP    #15
        BRA     CHECK_D         ; Branch to test against numerical values
        
CHECK_BTST
        LEA     C_TAB,A1
        MOVE.B  #3,D1
        TRAP    #15
        MOVE.B  #$1,D4
        LEA     CHECK_D,A2
        BRA     PRINT_EA          ; Branch to display ea

ADD_I
    LEA     C_TAB,A1
    MOVE.B  #14,D0
    TRAP    #15
    CMP.B   #$0,P4              ; Check against 0
    BEQ     ADD_I0
    CMP.B   #$1,P4
    BEQ     ADD_I1
    CMP.B   #$4,P4
    BEQ     ADD_I2
ADD_I0
    MOVE.B  #$1,D4
    LEA     CHECK_D,A2
    BRA     PRINT_EA            ; Branch to EA_DISP
ADD_I1 
    MOVE.B  #$2,D4
    LEA     CHECK_D,A2
    BRA     PRINT_EA            ; Branch to EA_DISP
ADD_I2
    LEA     C_HASH,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    LEA     CHECK_D,A2
    BRA     PRINT_EA            ; Branch to EA_DISP
    
CHECK_D
    LEA     C_COMMA,A1
    MOVE.B  #14,D0
    TRAP    #15
    CMP.B   #$0,P2              ; Check against numerical values [START]
    BEQ     MOVEB_DN1
    CMP.B   #$1,P2
    BEQ     MOVE_AN2
    CMP.B   #$2,P2 
    BEQ     MOVE_AN3
    CMP.B   #$3,P2 
    BEQ     MOVE_AN4
    CMP.B   #$4,P2 
    BEQ     MOVE_IMD
    CMP.B   #$5,D5
    BEQ     MOVEB_DN1
    CMP.B   #$7,D5              ; Check against numerical values [END]
    BEQ     ADD_IMD0

ADD_IMD0
    CMP.B   #$0,P4
    BEQ     ADD_IMD1
    CMP.B   #$1,P4
    BEQ     ADD_IMD2
    CMP.B   #$4,P4
    BEQ     ADD_IMD3
    
ADD_IMD1
    MOVE.B  #$1,D4
    LEA     ENDNEWLINE,A2
    BRA     PRINT_EA            ; Branch to display EA
    
ADD_IMD2
    MOVE.B  #$2,D4
    LEA     ENDNEWLINE,A2
    BRA     PRINT_EA            ; Branch to display EA
    
ADD_IMD3    
    LEA     C_HASH,A1           ; Load ea to A1
    MOVE.B  #14,D0
    TRAP    #15
    
    LEA     ENDNEWLINE,A2
    BRA     PRINT_EA            ; Branch to display EA
        
MOVEA_0
    LEA C_TAB,A1
    MOVE.B  #14,D0
    TRAP    #15
    LEA C_A,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  P4,D1               ; Move contents of P4 into D1
    MOVE.B  #3,D0
    TRAP    #15
    LEA C_COMMA,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    CMP.B   #$0,P2
    BEQ     MOVEB_DN1
    CMP.B   #$1,P2
    BEQ     MOVE_AN2
    CMP.B   #$2,P2 
    BEQ     MOVE_AN3
    CMP.B   #$3,P2 
    BEQ     MOVE_AN4
    CMP.B   #$4,P2 
    BEQ     MOVE_IMD
    CMP.B   #$5,D5
    BEQ     MOVEB_DN1
    
MOVE_AN0
    LEA C_TAB,A1
    MOVE.B  #14,D0
    TRAP    #15
    LEA C_OBRACK,A1
    MOVE.B  #14,D0
    TRAP    #15
    LEA C_A,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  P4,D1               ; Move contents of P4 into D1
    MOVE.B  #3,D0
    TRAP    #15
    LEA C_CBRACK,A1
    MOVE.B  #14,D0
    TRAP    #15
    CMP.B   #$3,D4
    BEQ     ENDNEWLINE
    LEA C_COMMA,A1
    MOVE.B  #14,D0
    TRAP    #15
    CMP.B   #$0,P2
    BEQ     MOVEB_DN1
    CMP.B   #$1,P2
    BEQ     MOVE_AN2
    CMP.B   #$2,P2 
    BEQ     MOVE_AN3
    CMP.B   #$3,P2 
    BEQ     MOVE_AN4
    CMP.B   #$4,P2 
    BEQ     MOVE_IMD
    CMP.B   #$5,D5
    BEQ     MOVEB_DN1

MOVE_AN1
    LEA C_TAB,A1
    MOVE.B  #14,D0
    TRAP    #15
    LEA C_OBRACK,A1
    MOVE.B  #14,D0
    TRAP    #15
    LEA C_A,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  P4,D1               ; Load contents of P4 into D1
    MOVE.B  #3,D0
    TRAP    #15
    LEA C_CBRACK,A1
    MOVE.B  #14,D0
    TRAP    #15
    LEA C_PLUS,A1
    MOVE.B  #14,D0
    TRAP    #15
    CMP.B   #$3,D5              ; Test to D5
    BEQ     ENDNEWLINE          ; if equal, go to next Opcode
    CMP.B   #$4,D5              ; Test to D5
    BEQ     ENDNEWLINE          ; if equal, go to next Opcode
    LEA C_COMMA,A1
    MOVE.B  #14,D0
    TRAP    #15
    CMP.B   #$0,P2
    BEQ     MOVEB_DN1
    CMP.B   #$1,P2
    BEQ     MOVE_AN2
    CMP.B   #$2,P2 
    BEQ     MOVE_AN3
    CMP.B   #$3,P2 
    BEQ     MOVE_AN4
    CMP.B   #$4,P2 
    BEQ     MOVE_IMD
    CMP.B   #$5,D5
    BEQ     MOVEB_DN1

MOVE_AND0
    LEA     C_TAB,A1
    MOVE.B  #14,D0
    TRAP    #15
    LEA     C_NEG,A1
    MOVE.B  #14,D0
    TRAP    #15
    LEA     C_OBRACK,A1
    MOVE.B  #14,D0
    TRAP    #15
    LEA     C_A,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  P4,D1               ; Load data from P4 into D1
    MOVE.B  #3,D0
    TRAP    #15
    LEA C_CBRACK,A1
    MOVE.B  #14,D0
    TRAP    #15
    CMP.B   #$4,D5
    BEQ     ENDNEWLINE
    LEA C_COMMA,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    CMP.B   #$0,P2
    BEQ     MOVEB_DN1
    CMP.B   #$1,P2
    BEQ     MOVE_AN2
    CMP.B   #$2,P2 
    BEQ     MOVE_AN3
    CMP.B   #$3,P2 
    BEQ     MOVE_AN4
    CMP.B   #$4,P2 
    BEQ     MOVE_IMD
    CMP.B   #$5,D5
    BEQ     MOVEB_DN1

MOVEB_DN0
    LEA     C_TAB,A1
    MOVE.B  #14,D0
    TRAP    #15
    CMP.B   #$6,D5             ; D5 Register to store LSLLSR
    BEQ     SUB_LSLLSR0
    LEA     C_D,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  P4,D1              ; Load contents of P4 into D1
    MOVE.B  #3,D0
    TRAP    #15
    CMP.B   #$4,D5
    BEQ     CHECK_ENDLN        ; If equal, branch
    LEA     C_COMMA,A1
    MOVE.B  #14,D0
    TRAP    #15
    CMP.B   #$6,D5 
    BEQ     SUB_LSLLSR1
    CMP.B   #$0,P2
    BEQ     MOVEB_DN1
    CMP.B   #$1,P2
    BEQ     MOVE_AN2
    CMP.B   #$2,P2 
    BEQ     MOVE_AN3
    CMP.B   #$3,P2 
    BEQ     MOVE_AN4
    CMP.B   #$4,P2 
    BEQ     MOVE_IMD
    CMP.B   #$5,D5
    BEQ     MOVEB_DN1
    
SUB_LSLLSR0
    LEA     C_D,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  H,D1
    MOVE.B  #3,D0
    TRAP    #15    
    LEA     C_COMMA,A1
    MOVE.B  #14,D0
    TRAP    #15  
    BRA     SUB_LSLLSR1
    
SUB_LSLLSR1
    LEA     C_D,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  P4,D1
    MOVE.B  #3,D0
    TRAP    #15
    BRA     ENDNEWLINE       

MOVE_AN2
    LEA     C_A,A1              ; Load ea to A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  P1,D1
    MOVE.B  #3,D0
    TRAP    #15
    BRA     ENDNEWLINE          ; Go to next OpCode

MOVE_AN3
    LEA     C_OBRACK,A1         ; Load ea to A1
    MOVE.B  #14,D0
    TRAP    #15
    LEA     C_A,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  P1,D1
    MOVE.B  #3,D0
    TRAP    #15
    LEA     C_CBRACK,A1
    MOVE.B  #14,D0
    TRAP    #15
    BRA     ENDNEWLINE          ; Go to next OpCode

MOVE_AN4
    LEA     C_OBRACK,A1         ; Load ea to A1
    MOVE.B  #14,D0
    TRAP    #15
    LEA     C_A,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  P1,D1               ; Load contents of P1 into D1
    MOVE.B  #3,D0
    TRAP    #15
    LEA     C_CBRACK,A1             
    MOVE.B  #14,D0
    TRAP    #15
    LEA     C_PLUS,A1
    MOVE.B  #14,D0
    TRAP    #15
    BRA     ENDNEWLINE          ; Go to next OpCode

MOVE_IMD
    LEA     C_NEG,A1
    MOVE.B  #14,D0
    TRAP    #15    
    LEA     C_OBRACK,A1
    MOVE.B  #14,D0
    TRAP    #15
    LEA     C_A,A1
    MOVE.B  #14,D0
    TRAP    #15   
    MOVE.B  P1,D1               ; Store contents of P1 into D1
    MOVE.B  #3,D0
    TRAP    #15
    LEA     C_CBRACK,A1
    MOVE.B  #14,D0
    TRAP    #15
    BRA     ENDNEWLINE          ; Go to next OpCode

MOVEB_DN1
    LEA     C_D,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  P1,D1               ; Load contents of P1 into D1
    MOVE.B  #3,D0
    TRAP    #15   
    CMP.B   #$0,D4
    BEQ     ENDNEWLINE
    BRA     ENDNEWLINE          ; Go to next OpCode
    
CHECK_ENDLN
    BRA     ENDNEWLINE          ; Go to next OpCode


        
PRINTBYTE
    LEA     C_BYTE,A1
    MOVE    #14,D1
    TRAP    #15

    CMP.B   #$0,P3           
    BEQ     MOVEB_DN0
    CMP.B   #$1,P3
    BEQ     MOVEA_0
    CMP.B   #$2,P3
    BEQ     MOVE_AN0
    CMP.B   #$3,P3
    BEQ     MOVE_AN1
    CMP.B   #$4,P3
    BEQ     MOVE_AND0
    CMP.B   #$7,P3
    BEQ     ADD_IMD0
    
PRINTWORD
    LEA     C_WORD,A1
    MOVE    #14,D1
    TRAP    #15

    CMP.B   #$0,P3           
    BEQ     MOVEB_DN0
    CMP.B   #$1,P3
    BEQ     MOVEA_0
    CMP.B   #$2,P3
    BEQ     MOVE_AN0
    CMP.B   #$3,P3
    BEQ     MOVE_AN1
    CMP.B   #$4,P3
    BEQ     MOVE_AND0
    CMP.B   #$7,P3
    BEQ     ADD_IMD0
    
PRINTLONG
    LEA     C_LONG,A1                    ; Load ea to A1
    MOVE    #14,D1
    TRAP    #15
 
    CMP.B   #$0,P3           
    BEQ     MOVEB_DN0
    CMP.B   #$1,P3
    BEQ     MOVEA_0
    CMP.B   #$2,P3
    BEQ     MOVE_AN0
    CMP.B   #$3,P3
    BEQ     MOVE_AN1
    CMP.B   #$4,P3
    BEQ     MOVE_AND0
    CMP.B   #$7,P3
    BEQ     ADD_IMD0

PRINT_B  * Print Byte
        LEA C_DOT,A1
        MOVE    #14,D0
        TRAP    #15
        LEA C_BYTE,A1
        MOVE    #14,D0
        TRAP    #15
        MOVE #$6,D5
        CMP.B   #0,P3
        BEQ     DISP_LST_CT
        CMP.B   #1,P3
        BEQ     MOVEB_DN0

PRINT_W  * Print Word
        LEA     C_DOT,A1
        MOVE    #14,D0
        TRAP    #15
        LEA     C_WORD,A1
        MOVE    #14,D0
        TRAP    #15
        MOVE    #$6,D5               ; Move value 6 into D5
        CMP.B   #0,P3
        BEQ     DISP_LST_CT
        CMP.B   #1,P3
        BEQ     MOVEB_DN0

PRINT_L  * Print Long
        LEA     C_DOT,A1
        MOVE    #14,D0
        TRAP    #15
        LEA     C_LONG,A1
        MOVE    #14,D0
        TRAP    #15
        MOVE    #$6,D5              ; Check against size 6
        CMP.B   #0,P3
        BEQ     DISP_LST_CT
        CMP.B   #1,P3
        BEQ     MOVEB_DN0      

LSLLSR
        MOVE.B  (A6)+,D2            ; Increment and store data to D2
        LSL.B   #5,D2               ; Shift left
        LSR.B   #5,D2               ; Shift right
        MOVE.B  D2,P4               ; Store into P4
        MOVE.B  D6,D2               ; Load data to D2 from D6 for manipulation
        LSL.B   #2,D2               ; Shift left
        LSR.B   #7,D2               ; Shift right
        MOVE.B  D2,P3               ; Store data into P3
        MOVE.W  D6,D7               ; Load data to D7 from D6 for maniupulation
        LSL.W   #8,D7
        LSR.W   #8,D7 
        LSR.W   #6,D7 
        MOVE.B  D7,P2               ; Store data into P2 from D7 
        MOVE.W  D6,D7               ; Load data to D7 from D6
        LSL.W   #7,D7
        LSR.W   #8,D7 
        LSR.W   #7,D7
        MOVE.B  D7,P1               ; Store data into P1 from D7
        MOVE.B  D6,D4               ; Load data to D4 from D6
        MOVE.W  D6,D7               ; Load data to D7 from D6
        LSL.W   #4,D7               ; Shift left
        LSR.W   #8,D7               ; Shift right
        LSR.W   #5,D7               ; Shift right
        MOVE.B  D7,H               ; Store data from D7 into H
        MOVE.B  D6,D7               ; Load data to D7 from D6
        LSL.B   #4,D7               ; Shift D7 left
        LSR.B   #7,D7               ; Then shift D7 right 
        CMP.B   #3,P2
        BEQ     CHECK_LSLLSR
        CMP.B   #0,D7
        BEQ     CHECK_ASLASR
        MOVE.B  D6,D3               ; Load data from D6 into D3
        LSL.B   #3,D3
        LSR.B   #6,D3
        CMP.B   #3,D3
        BEQ     RORL
        CMP.B   #$1,P1
        BEQ     DISP_LSL
        CMP.B   #$0,P1
        BEQ     DISPLAY_LSR
        
CHECK_ASLASR
        MOVE.B  #4,D5
        CMP.B   #$1,P1
        BEQ     DISP_ASL
        CMP.B   #$0,P1
        BEQ     DISP_ASR
        
DISP_ASL
        LEA     C_ASL,A1
        MOVE    #14,D0
        TRAP    #15
        CMP.B   #$0,P2
        BEQ     PRINT_B
        CMP.B   #$1,P2
        BEQ     PRINT_W
        CMP.B   #$2,P2
        BEQ     PRINT_L
        BRA     SUB_LSLLSR2
        
DISP_ASR        
        LEA     C_ASR,A1            ; Load effective address into A1
        MOVE    #14,D0
        TRAP    #15
        CMP.B   #$0,P2
        BEQ     PRINT_B
        CMP.B   #$1,P2
        BEQ     PRINT_W
        CMP.B   #$2,P2
        BEQ     PRINT_L
        BRA     SUB_LSLLSR2
        
CHECK_LSLLSR
        MOVE.W  D6,D7               ; Load data to D7 from D6
        LSL.W   #6,D7
        LSR.W   #8,D7
        LSR.W   #7,D7
        CMP.B   #0,D7
        BEQ     CHECK_ASLASR
        MOVE.B  #4,D5
        CMP.B   #$1,P1
        BEQ     DISP_LSL
        CMP.B   #$0,P1
        BEQ     DISPLAY_LSR
RORL
        CMP.B   #$1,P1              ; Test P1
        BEQ     DISP_ROL            ; Branch if equal
        CMP.B   #$0,P1              ; Test P1 to 0
        BEQ     DISP_ROR            ; Branch to ROR
DISP_ROL
        LEA C_ROL,A1
        MOVE    #14,D0
        TRAP    #15
        CMP.B   #$0,P2
        BEQ     PRINT_B
        CMP.B   #$1,P2
        BEQ     PRINT_W
        CMP.B   #$2,P2
        BEQ     PRINT_L
        BRA     SUB_LSLLSR2
DISP_ROR
        LEA C_ROR,A1
        MOVE    #14,D1
        TRAP    #15
        CMP.B   #$0,P2
        BEQ     PRINT_B
        CMP.B   #$1,P2
        BEQ     PRINT_W
        CMP.B   #$2,P2
        BEQ     PRINT_L
        BRA     SUB_LSLLSR2
DISP_LSL
        LEA C_LSL,A1
        MOVE    #14,D0
        TRAP    #15
        CMP.B   #$0,P2
        BEQ     PRINT_B
        CMP.B   #$1,P2
        BEQ     PRINT_W
        CMP.B   #$2,P2
        BEQ     PRINT_L
        BRA     SUB_LSLLSR2
        
SUB_LSLLSR2
        LSL.B   #2,D4
        LSR.B   #5,D4
        MOVE.B  D4,P3                 ; Load data from D4 to P3
        MOVE.B  #$3,D4
        CMP.B   #$2,P3
        BEQ     MOVE_AN0
        CMP.B   #$3,P3
        BEQ     MOVE_AN1
        CMP.B   #$4,P3
        BEQ     MOVE_AND0
        LEA     C_TAB,A1
        MOVE.B  #3,D1
        TRAP    #15 
        CMP.B   #$7,P3
        BEQ     ADD_IMD0

DISP_LST_CT
        LEA     C_TAB,A1
        MOVE    #14,D0
        TRAP    #15
        LEA     C_HASH,A1
        MOVE    #14,D0
        TRAP    #15
        MOVE.B  H,D1
        MOVE    #3,D0
        TRAP    #15
        LEA     C_COMMA,A1
        MOVE    #14,D0
        TRAP    #15
        BRA     SUB_LSLLSR1
  
DISPLAY_LSR
        LEA     C_LSR,A1
        MOVE    #14,D1
        TRAP    #15
        CMP.B   #$0,P2
        BEQ     PRINT_B
        CMP.B   #$1,P2
        BEQ     PRINT_W
        CMP.B   #$2,P2
        BEQ     PRINT_L
        BRA     SUB_LSLLSR2

*-----------------------------------------------------------
* Subroutines: BRA, BSR, Bcc
BCC
        MOVE.B  D5,P1             ; Loads code to P1
        MOVE.B  (A6)+,D5            ; Load displacement to D5
        MOVE.B  D5,P2             ; Load displacement to P2
        MOVE.L  A6,D4               ; Store current D4
        CMP.B   #$0,D5              
        BEQ     BCC_W
        CMP.B   #$FF,D5
        BEQ     BCC_L
        ADD.B   D5,D4               ; Adds displacement to address
        BRA     BCC_N

* Computes 16 bit displacement
BCC_W
        MOVE.W  (A6)+,D5            ; Loads 16 bit to D5
        ADD.W   D5,D4               ; Sum D5 and D4, store in D4
        BRA     BCC_N
* Computes 32 bit displacement
BCC_L
        MOVE.L  (A6)+,D5            ; Loads 32 bit to D5
        ADD.L   D5,D4               ; Add contents of D5 to D4 
        BRA     BCC_N

BCC_N
        BSR     DISP_BCC
        LEA     ENDNEWLINE,A2
        MOVE.L  D4,D7               ; Move long size data from D4 into D7
        BRA     D_ADDRESSSTART      ; Branch to display address subroutines

* Determines which conditional to use
DISP_BCC
        CMP.B   #$0,D2
        BEQ     BCCBRA
        CMP.B   #$7,D2
        BEQ     BCCBEQ
        CMP.B   #$6,D2
        BEQ     BCCBNE
        CMP.B   #$D,D2
        BEQ     BCCBLT
        CMP.B   #$2,D2
        BEQ     BCCBHI
        BRA     OP_HELPER0

* Displays correct, manipulated code
BCCBRA
        LEA     C_BRA,A1
        BRA     BCCPRINT             ; Branch to print
BCCBEQ
        LEA     C_BEQ,A1
        BRA     BCCPRINT             ; Branch to print
BCCBNE
        LEA     C_BNE,A1
        BRA     BCCPRINT             ; Branch to print
BCCBLT
        LEA     C_BLT,A1
        BRA     BCCPRINT             ; Branch to print
BCCBHI
        LEA     C_BHI,A1
        BRA     BCCPRINT             ; Branch to print
BCCPRINT
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_TAB,A1
        TRAP    #15
        RTS

*-----------------------------------------------------------
* Arithmetic Operations
ARTHM0     MOVE.B  D5,P1               ; Store data from D5 into P1
        MOVE.B  D2,D1               ; Load data to D1 from D2
        MOVE.B  (A6)+,D2            ; Increment and store data from A6 to D2
        MOVE    D5,D4               ; Load data to D4 from D5
        AND.B   #$0001,D4
        CMP.B   #$1,D4              
        BEQ     BTST
        CMP.B   #8,D1
        BEQ     BTST
        ADD.B   D2,D7               ; Add contents of D2 and D7
        MOVE.B  D2,D3               ; Stores data to D3
        LSR.B   #4,D3               ; Shift right
        LSL.B   #4,D2               ; Shift left
        LSR.B   #4,D2               ; Shift to reset
        LSR.B   #1,D3
        BCC     ARTHM1
        ADD.B   #$2,D4

ARTHM1  LSR.B   #1,D3
        BCC     ARTHM2
        ADD.B   #$4,D4              ; Add 4 to D4
ARTHM2  CMP.B   #$7,D2
        BLT     ARTHM3
        ADD.B   #$1,D4
        SUB.B   #$8,D2
        
ARTHM3  MOVE.B  D3,P2               ; Load data from D3 into P2
        MOVE.B  D4,P3               ; Load data from D4 into P3
        MOVE.B  D2,P4               ; Load data from D2 into P4

*-----------------------------------------------------------
* Computes size of operation
        CMP.B   #$0,P2 
        BEQ     OPRTN_BYTE
        CMP.B   #$1,P2
        BEQ     OPRTN_WORD
        CMP.B   #$2,P2
        BEQ     OPRTN_LONG
        BRA     OP_HELPER0

*-----------------------------------------------------------
* Display OpCode
IMDPRINT
        CMP.B   #$0,P1
        BEQ     IMDPRINTORI
        CMP.B   #$4,P1
        BEQ     IMDPRINTSUBI
        CMP.B   #$A,P1
        BEQ     IMDPRINTEORI
        CMP.B   #$C,P1
        BEQ     IMDPRINTCMPI

IMDPRINTORI
        LEA     C_ORI,A1
        BRA     IMDPRINTEND           ; Branch to print subroutine

IMDPRINTSUBI
        LEA     C_SUBI,A1
        BRA     IMDPRINTEND           ; Branch to print subroutine

IMDPRINTEORI
        LEA     C_EORI,A1
        BRA     IMDPRINTEND           ; Branch to print subroutine

IMDPRINTCMPI
        LEA     C_CMPI,A1
        BRA     IMDPRINTEND           ; Branch to print subroutine

IMDPRINTEND
        MOVE.B  #14,D0
        TRAP    #15
        RTS

*-----------------------------------------------------------
* Byte operation
OPRTN_BYTE
        BSR     IMDPRINT
        LEA     C_BYTE,A1             ; Load EA to A1
        MOVE.B  #$1,D4
        BRA     IMDEA                 ; Branch to ea subroutines

*-----------------------------------------------------------
* Word operation
OPRTN_WORD
        BSR     IMDPRINT
        LEA     C_WORD,A1

        MOVE.B  D3,D4                 ; Load data from D4 to D3
        BRA     IMDEA


*-----------------------------------------------------------
* Long operation
OPRTN_LONG
        BSR     IMDPRINT
        LEA     C_LONG,A1             ; Load long effective address to A1
        MOVE.B  D3,D4                 ; Store data from D3 to D4

* Displays size
IMDEA
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_TAB,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_HASH,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     IMDEA2,A2
        BRA     PRINT_EA              ; Branch to display ea
IMDEA2
        LEA     C_COMMA,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     IMDEA3,A2
        BRA     EA_MODE               ; Branch to ea subroutines
IMDEA3
        BRA     ENDNEWLINE            ; Go to next OpCode

*-----------------------------------------------------------
* Subroutines: Computing Size of Operations
COMP_SIZE0
        MOVE.B  D5,P1               ; Move data from D5 into P1
        MOVE.B  (A6)+,D2            ; Increment and store data from A6 to D2
        ADD.B   D2,D7               ; Sum contents of D2 and D7. Store in D7
        MOVE.B  D2,D3               ; Stores data to D3 from D2
        LSR.B   #4,D3               
        LSL.B   #4,D2 
        LSR.B   #4,D2 
        MOVE.W  D6,D4               ; Store data to D4 from D6
        LSL.W   #$4,D4
        LSR.W   #$8,D4
        LSR.W   #$2,D4
        MOVE.B  D4,P2               ; Load data from D4 into P2
        CMP.B   #$3A,P2
        BEQ     JSR
* Compute size of operation
        CMP.B   #$4,D5
        BEQ     NEGW                
        CMP.B   #$6,D5              ; Check if true, branch to NOT
        BEQ     SUB_NOT0
        CMP.B   #$E,D5              ; Checks for JSR / NOP
        BEQ     COMP_BIT0
        BRA     CHECK_4_LEA         ; Tests bits for LEA

COMP_BIT0
        CMP.B   #$7,D3              ; Branch to NOP
        BEQ     COMP_BIT1
        BRA     OP_HELPER0

COMP_BIT1
        CMP.B   #$1,D2              ; Branch to NOP
        BEQ     SUB_NOP
        CMP.B   #$5,D2              ; Branch to NOP
        BEQ     SUB_RTS
        BRA     OP_HELPER0

* Check for LEA
CHECK_4_LEA
        MOVE.B  D5,D4               ; Load data to D4 from D5
        AND.B   #$1,D4
        CMP.B   #$1,D4
        BNE     CHECK_4_MOVEM
        MOVE.B  D3,D4               ; Load data from D3 to D4
        AND.B   #$C,D4
        CMP.B   #$C,D4
        BNE     CHECK_4_MOVEM
        BRA     SUB_LEA0

* Check for MOVEM
CHECK_4_MOVEM
        MOVE.B  D5,D4               ; Load data from D5 to D4
        AND.B   #$8,D4
        CMP.B   #$8,D4
        BNE     OP_HELPER0
        MOVE.B  D3,D4               ; Load data from D4 to D3
        AND.B   #$8,D4
        CMP.B   #$8,D4
        BNE     OP_HELPER0
        BRA     SUB_MOVEM0

*-----------------------------------------------------------
* NOP
SUB_NOP
        LEA     C_NOP,A1         ; Store ea in A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     ENDNEWLINE      ; Go to next OpCode

SUB_LEA0
        LEA     C_LEA,A1         ; Store ea in A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_TAB,A1
        MOVE.B  #14,D0
        TRAP    #15        
        LSR.B   #1,D5
        MOVE.W  D2,D6           ; Stores D2 to D6
        LSL.B   #1,D3           ; Left shift
        AND.B   #$07,D3         ; Remove all bits except mode bits
        BCLR    #3,D2 
        BEQ     SUB_LEA1  
        ADD.B   #$1,D3

SUB_LEA1
        MOVE.B  D3,P3           ; Load contents of D3 into P3
        MOVE.B  D2,P4           ; Load contents of D2 into P4
        
LEA_MODE_0
        CMP.B   #7,D3
        BEQ     LEA_EA_AB0 
        
LEA_MODE_1
        CMP.B   #2,D3 
        BEQ     LEA_INDIR_AN
        BNE     OP_HELPER0

LEA_EA_AB0
        CMP.B   #$0,P4
        BEQ     LEA_I0
        CMP.B   #$1,P4
        BEQ     LEA_I1

LEA_I0
        MOVE.B  #$1,D4
        LEA     PRINT_LEA,A2        ; Load ea onto A2
        BRA     PRINT_EA            ; Branch to display ea subroutines
LEA_I1 
        MOVE.B  #$2,D4
        LEA     PRINT_LEA,A2        ; Load ea onto A2
        BRA     PRINT_EA            ; Branch to display ea subroutines
        
PRINT_LEA
        LEA     C_COMMA,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_A,A1              ; Load ea to A1 
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  D5,D1               ; Store data from D5 to D1
        MOVE.B  #3,D0
        TRAP    #15
        BRA     ENDNEWLINE          ; Go to next OpCode
        
LEA_INDIR_AN
        LEA     C_OBRACK,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_A,A1
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  D2,D1               ; Load data from D2 into D1
        MOVE.B  #3,D0
        TRAP    #15
        LEA     C_CBRACK,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_COMMA,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_A,A1
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  D5,D1
        MOVE.B  #3,D0
        TRAP    #15
        BRA     ENDNEWLINE           ; Go to next OpCode

*-----------------------------------------------------------
* Subroutine: RTS
SUB_RTS
        LEA     C_RTS,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     ENDNEWLINE      ; Goes to next opcode

*-----------------------------------------------------------
* Subroutine: NOT
SUB_NOT0
        CLR     D4              ; Clear contents of D4
        LSR.B   #1,D3
        BCC     SUB_NOT1
        ADD.B   #$2,D4          ; Add 2 to D4
SUB_NOT1   
        LSR.B   #1,D3
        BCC     SUB_NOT2
        ADD.B   #$4,D4          ; Add 4 to D4
SUB_NOT2   
        CMP.B   #$7,D2
        BLT     SUB_NOT3
        ADD.B   #$1,D4          ; Add 1 to D4
        SUB.B   #$8,D2
SUB_NOT3
        MOVE.B  D3,P2           ; Load contents of D3 into P2
        MOVE.B  D4,P3           ; Load contents of D4 into P3
        MOVE.B  D2,P4           ; Load contents of D2 into P4
        CMP.B   #$0,D3
        BEQ     OP_BYTE
        CMP.B   #$1,D3
        BEQ     OP_WORD
        CMP.B   #$2,D3
        BEQ     OP_LONG
        BRA     OP_HELPER0
        
*-----------------------------------------------------------
* Byte operation
OP_BYTE
        BSR     OP_PRINT
        LEA     C_BYTE,A1            ; Load byte into A1
        MOVE.B  #$1,D4
        BRA     OP_EA0

*-----------------------------------------------------------
* Word operation
OP_WORD
        BSR     OP_PRINT
        LEA     C_WORD,A1            ; Load word into A1
        MOVE.B  D3,D4               ; Load data to D4 from D3
        BRA     OP_EA0

*-----------------------------------------------------------
* Long operation
OP_LONG
        BSR     OP_PRINT
        LEA     C_LONG,A1
        MOVE.B  D3,D4               ; Load data to D4 from D3

OP_EA0
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_TAB,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     OP_EA1,A2
        BRA     EA_MODE             ; Branch to ea subroutines
OP_EA1
        BRA     ENDNEWLINE          ; Go to next OpCode

*-----------------------------------------------------------
* Display OpCode
OP_PRINT
        CMP.B   #$4,P1
        BEQ     OP_PRINT_MIN
        CMP.B   #$6,P1
        BEQ     OP_PRINT_NOT

OP_PRINT_NOT
        LEA     C_NOT,A1
        BRA     OP_PRINT_END

OP_PRINT_MIN
        LEA     C_NEG1,A1
        BRA     OP_PRINT_END

OP_PRINT_END
        MOVE.B  #14,D0
        TRAP    #15
        RTS

MULSW
        MOVE.B  D7,D2           ; Stores data from D7 to D2
        LSL.B   #5,D2
        LSR.B   #5,D2
        MOVE.B  D2,P4           ; Load contents of D2 into P4
        MOVE.B  D7,D2           ; Load contents of D7 into D2
        LSL.B   #2,D2           ; Shift D2 left 
        LSR.B   #5,D2           ; Shift D2 right
        MOVE.B  D2,P3           ; Load contents of D2 into P3
        MOVE.W  D7,D6           ; Load contents of D7 into D6
        LSL.W   #7,D6           ; Shift D6 left
        LSR.W   #8,D6           ; Then shift D6 right
        LSR.W   #5,D6 
        MOVE.B  D6,P2           ; Load contents of D6 into P2    
        LSL.W   #4,D7
        LSR.W   #8,D7 
        LSR.W   #5,D7 
        MOVE.B  D7,P1           ; Load contents of D7 into P1
        LEA     C_MULSW,A1       ; Load ea into A1 after manipulation
        MOVE    #14,D1
        TRAP    #15      
        MOVE.B  #$5,D5          ; Load 5 into D5
        CMP.B   #$0,P3           
        BEQ     MOVEB_DN0
        CMP.B   #$1,P3
        BEQ     MOVEA_0
        CMP.B   #$2,P3
        BEQ     MOVE_AN0
        CMP.B   #$3,P3
        BEQ     MOVE_AN1
        CMP.B   #$4,P3
        BEQ     MOVE_AND0
        CMP.B   #$7,P3
        BEQ     ADD_I

DIVSW               
        MOVE.B  (A6)+,D2        ; Increment and store data from A6 to D2
        LSL.B   #5,D2
        LSR.B   #5,D2
        MOVE.B  D2,P4
        
        MOVE.B  D6,D2           ; Load data from D6 to D2
        LSL.B   #2,D2
        LSR.B   #5,D2
        MOVE.B  D2,P3
        
        MOVE.W  D6,D7           ; Load data from D6 to D7
        LSL.W   #7,D7
        LSR.W   #8,D7 
        LSR.W   #5,D7 
        MOVE.B  D7,P2
        
        LSL.W   #4,D6
        LSR.W   #8,D6 
        LSR.W   #5,D6 
        MOVE.B  D6,P1
        
        LEA C_DIVSW,A1
        MOVE    #14,D1
        TRAP    #15
        
        MOVE.B  #$5,D5 
        MOVE.B  #$4,D4
        
        CMP.B   #$0,P3           
        BEQ     MOVEB_DN0
        CMP.B   #$1,P3
        BEQ     MOVEA_0
        CMP.B   #$2,P3
        BEQ     MOVE_AN0
        CMP.B   #$3,P3
        BEQ     MOVE_AN1
        CMP.B   #$4,P3
        BEQ     MOVE_AND0
        CMP.B   #$7,P3
        BEQ     ADD_I

NEGW
        MOVE.B  D6,D2           ; Load data from D6 to D2
        LSL.B   #5,D2
        LSR.B   #5,D2
        MOVE.B  D2,P4
        
        MOVE.B  D6,D2           ; Load data from D6 to D2
        LSL.B   #2,D2
        LSR.B   #5,D2
        MOVE.B  D2,P3
        
        MOVE.W  D6,D7           ; Load data from D6 to D7
        LSL.W   #8,D7
        LSR.W   #8,D7 
        LSR.W   #6,D7 
        MOVE.B  D7,P2
        
        LEA     C_NEGW,A1       ; Store EA in A1
        MOVE    #14,D1
        TRAP    #15
        
        MOVE.B  #$3,D4
        
        CMP.B   #$0,P2
        BEQ     PRINTBYTE
        CMP.B   #$1,P2
        BEQ     PRINTWORD
        CMP.B   #$2,P2
        BEQ     PRINTLONG

*-----------------------------------------------------------
* Subroutine: ADDQ 
ADDQ    
        MOVE.B  D5,P1               ; Load data from D5 into P1
        MOVE.B  (A6)+,D2            ; Increment and store data from A6 into D2
        ADD.B   D2,D7               ; Sum contents of D2 into D7
        MOVE.B  D2,D3               ; Store data to D3 from D2
        LSR.B   #4,D3               ; Shift right
        LSL.B   #4,D2               ; Shift left
        LSR.B   #4,D2               ; Shift right to reset
        MOVE.W  D3,D4               ; Load data from D3 into D4
        LSR.W   #$2,D4
        MOVE.B  D4,P2               ; Store contents of D4 into P2
        LEA     C_ADDQ,A1            ; Load effective address into A1
        MOVE.B  #14,D0
        TRAP    #15
        CMP.B   #$0,D4
        BEQ     ADDQ_B
        CMP.W   #$1,D4
        BEQ     ADDQ_W
        CMP.L   #$2,D4
        BEQ     ADDQ_L
        BRA     OP_HELPER0

* Subroutines: ADDQ  for byte, word, and long size
ADDQ_B
        LEA     C_BYTE,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     ADDQ_HELP0  
ADDQ_W
        LEA     C_WORD,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     ADDQ_HELP0
ADDQ_L        
        LEA     C_LONG,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     ADDQ_HELP0
        
ADDQ_HELP0        
        LEA     C_TAB,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_HASH,A1
        MOVE.B  #14,D0
        TRAP    #15
        LSR.B   #1,D5               ; Shift right for value of D5
        CMP.B   #$0,D5              ; Compare to 0
        BNE     ADDQ_HELP1           
        MOVE.B  #8,D5               ; If 0, set to 8

ADDQ_HELP1
        MOVE.B  D5,D1               ; Load data to D1 from D5
        MOVE.B  #3,D0
        TRAP    #15
        LEA     C_COMMA,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     ADDQ_EA0            ; Branch to ADDQ_EA
        
ADDQ_EA0
        LSL.B   #1,D3               ; Shift left
        AND.B   #$07,D3             ; Clears all except mode bits
        BCLR    #3,D2               ; Calears all except reg bits
        BEQ     ADDQ_EA1
        ADD.B   #$1,D3              ; if 1, add to mode

ADDQ_EA1
        MOVE.B  D2,P4               ; Load data from D2 into P4
        MOVE.B  D3,P3               ; Load data from D3 into P3
        MOVE.B  D4,P2               ; Load data from D4 into P2
        LEA     ENDNEWLINE,A2
        BRA     EA_MODE             ; Branch to select OpCode
        * Branch to Opcode based on EA_MODE
        CMP.B   #$0,D3
        BEQ     EAM_DN 
        CMP.B   #$1,D3
        BEQ     EAM_AN
        CMP.B   #$2,D3
        BEQ     EAM_INAN
        CMP.B   #$3,D3
        BEQ     EAM_INC
        CMP.B   #$4,D3
        BEQ     EAM_DEC
        CMP.B   #$7,D3
        BEQ     EA_AB0
        
EAM_DN
        LEA     C_D,A1
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  D2,D1
        MOVE.B  #3,D0
        TRAP    #15
        BRA     ENDNEWLINE          ; Go to next opcode
        
EAM_AN
        LEA     C_A,A1
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  D2,D1               ; Load data from D2 into D1
        MOVE.B  #3,D0
        TRAP    #15
        BRA     ENDNEWLINE          ; Go to next opcode
        
EAM_INAN
        LEA     C_OBRACK,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_A,A1
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  D2,D1               ; Load D2 into D1
        MOVE.B  #3,D0
        TRAP    #15
        LEA     C_CBRACK,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     ENDNEWLINE          ; Go to next opcode
        
EAM_INC
        LEA     C_OBRACK,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_A,A1
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.W  D2,D1               ; Load data to D1 from D2
        MOVE.B  #3,D0
        TRAP    #15
        LEA     C_CBRACK,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_PLUS,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     ENDNEWLINE          ; Go to next opcode
        
EAM_DEC
        LEA     C_NEG,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_OBRACK,A1          
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_A,A1
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  D2,D1               ; Load data to D1 from D2
        MOVE.B  #3,D0
        TRAP    #15
        LEA     C_CBRACK,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     ENDNEWLINE          ; Go to next opcode
        
EA_AB0  
        LEA     EA_AB1,A2           ; Load ea to A2
        BRA     PRINT_EA              ; Branch to print EA
        
EA_AB1
        BRA     ENDNEWLINE          ; Go to next opcode

*-----------------------------------------------------------
* Subroutines: MOVEM
SUB_MOVEM0
        MOVE.B  D5,D4               ; Retrieves data register and loads to D5
        CLR     D5                  ; Clear contents of D5
        BTST    #2,D4               ; Check bit at two
        BEQ     SUB_MOVEM1          ; If 1, load 1 to D5
        MOVE.B  #1,D5

SUB_MOVEM1
        CLR     D6                  ; Clear D6
        MOVE.B  D3,D4               ; Retrieve size and load to D6
        BTST    #2,D4 
        BEQ     SUB_MOVEM2 
        MOVE.B  #1,D6  

SUB_MOVEM2
        AND.B   #$3,D3              ; Remove first two bits
        LSL.B   #1,D3               ; Shift left
        BCLR    #3,D2               ; Set left bit to 0
        BEQ     SUB_MOVEM3
        BSET    #0,D3               ; If 1 add to mode

* Computes and prints size
SUB_MOVEM3
        MOVE.B  D5,P1                ; Load data from D5 to P1
        MOVE.B  D6,P2                ; Load data from D6 to P1
        MOVE.B  D3,P3                ; Load data from D3 to P3
        MOVE.B  D2,P4                ; Load data from D2 to P4
        LEA     C_MOVEM,A1            ; Load ea to A1
        MOVE.B  #14,D0
        TRAP    #15
        CMP.B   #1,D6
        BEQ     MOVEM_SIZEL
        LEA     C_WORD,A1            ; Load word to A1 
        BRA     MOVEM_PRINTSZ      ; Branch to print

MOVEM_SIZEL
        LEA     C_LONG,A1            ; Load long effective address into A1

MOVEM_PRINTSZ
        TRAP    #15
        LEA     C_TAB,A1
        TRAP    #15
        MOVE.W  (A6)+,D6             ; Increment and load data from A6 to D6
        CMP.B   #0,D5
        BEQ     CHECK_PRED_MOVEM
        BRA     PRINT_POST0

CHECK_PRED_MOVEM
        CMP.B   #$4,D3               ; Check D3 to 4
        BEQ     PRINT_PRE0
        BRA     CHECK_REG0

*-----------------------------------------------------------
* Print Register
PRINT_PRE0
* D7 is used as loop counter
        MOVE.B  D6,D4                ; Load data to D4 from D6
        MOVE.W  #8,D7
        MOVE.B  #$F,D1
        LEA     C_A,A4
        BSR     REG_PRINT0
        MOVE.W  D6,D4                ; Load contents of D6 into D4
        LSR.W   #8,D4
        MOVE.W  #8,D7
        LEA     C_D,A4               ; Load into A4
        BSR     REG_PRINT0
        BRA     PRINT_PRE1

PRINT_PRE1
        LEA     C_COMMA,A1
        MOVE.B  #14,D0
        TRAP    #15

        LEA     PRINT_PRE2,A2
        BRA     EA_MODE              ; Branch to EA subroutines
 
PRINT_PRE2
        BRA     ENDNEWLINE           ; Go to next opcode

REG_PRINT0
        LSL.B   #1,D4
        BCC     REG_PRINT2

        CMP.B   #$F,D1
        BEQ     REG_PRINT1
        JSR     DISPLAY_SLASH

REG_PRINT1
        MOVEA.L A4,A1                ; Move long sized contents of A4 into A1
        MOVE.B  #14,D0
        TRAP    #15
        BSR     PRINT_NUM

REG_PRINT2
        SUB.B   #1,D7
        CMP.B   #0,D7
        BNE     REG_PRINT0
        RTS

*-----------------------------------------------------------
PRINT_POST0
        LEA     PRINT_POST1,A2       ; Load effective address onto A2
        BRA     EA_MODE              ; Branch to EA subroutines 

PRINT_POST1
* D7 used as counter
        LEA     C_COMMA,A1
        MOVE.B  #14,D0
        TRAP    #15

        MOVE.W  D6,D4                ; Load data to D4 from D6
        LSR.W   #8,D4
        MOVE.W  #8,D7
        MOVE.B  #$F,D1               ; Store F into D1

        LEA     C_A,A4               ; Load into A4
        BSR     REG_PRINT3

        MOVE.B  D6,D4                ; Store data from D6 into D4
        MOVE.W  #8,D7
        LEA     C_D,A4               ; Load into A4
        BSR     REG_PRINT3
        BRA     PRINT_POST2

PRINT_POST2
        BRA     ENDNEWLINE           ; Go to next opcode

REG_PRINT3
        LSR.B   #1,D4
        BCC     REG_PRINT5
        CMP.B   #$F,D1
        BEQ     REG_PRINT4
        JSR     DISPLAY_SLASH

REG_PRINT4
        MOVEA.L A4,A1                ; Store the Long data of A4 into A1
        MOVE.B  #14,D0
        TRAP    #15
        BSR     PRINT_NUM

REG_PRINT5
        SUB.B   #1,D7
        CMP.B   #0,D7
        BNE     REG_PRINT3
        RTS

*-----------------------------------------------------------
CHECK_REG0
        MOVE.B  D6,D4                ; Store data from D6 to D4
        MOVE.W  #8,D7
        MOVE.B  #$F,D1
        LEA     C_D,A4               ; Load effective address to A4
        BSR     REG_PRINT3
        MOVE.W  D6,D4
        LSR.W   #8,D4
        MOVE.W  #8,D7
        LEA     C_A,A4               ; Load effective address to A4
        BSR     REG_PRINT3
        BRA     CHECK_REG1

CHECK_REG1
        LEA     C_COMMA,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     CHECK_REG2,A2
        BRA     EA_MODE              ; Branch to EA subroutines

CHECK_REG2
        BRA     ENDNEWLINE           ; Go to next opcode

DISP_REG0
        LSR.B   #1,D4
        BCC     REG_PRINT5
        CMP.B   #$F,D1
        BEQ     REG_PRINT4
        JSR     DISPLAY_SLASH

DISP_REG1
        MOVEA.L A4,A1                 ; Load long data from A4 into A1
        MOVE.B  #14,D0
        TRAP    #15
        BSR     PRINT_NUM

DISP_REG2
        SUB.B   #1,D7
        CMP.B   #0,D7
        BNE     REG_PRINT3
        RTS

*-----------------------------------------------------------
* Display Registers
PRINT_NUM
        MOVE.B  #8,D1
        SUB.B   D7,D1                ; sub contents of D7 to D1
        MOVE.B  #3,D0
        TRAP    #15
        RTS

DISPLAY_SLASH
        LEA     C_SLASH,A1
        MOVE.B  #14,D0
        TRAP    #15
        RTS

*-----------------------------------------------------------
* Subroutine: SUB
SUB     MOVE.B  (A6)+,D2            ; Increment and load contents of A6 to D2
        ADD.B   D2,D7               ; Sum contents of D2 and D7
        MOVE.B  D2,D3               ; Load data to D3 from D2
        LSR.B   #4,D3               ; Shift right
        LSL.B   #4,D2               ; Shift left
        LSR.B   #4,D2               ; Shift right to reset
        LSR.B   #1,D3
        BCC     SUB_1
        ADD.B   #$2,D4              ; Add 2 to D4
        
SUB_1   LSR.B   #1,D3
        BCC     SUB_2
        ADD.B   #$4,D4              ; Add 4 to D4
SUB_2   MOVE.B  D5,D1               ; Store data to D1 from D5
        LSR.B   #1,D1
        BCC     SUB_3
        ADD.B   #$4,D3              ; Add 4 to D3
SUB_3   CMP.B   #$7,D2
        BLT     SUB_4
        ADD.B   #$1,D4
        SUB.B   #$8,D2
SUB_4   MOVE.B  D1,P1               ; Load data from D1 into P1
        MOVE.B  D3,P2               ; Load data from D3 into P2
        MOVE.B  D4,P3               ; Load data from D4 into P3
        MOVE.B  D2,P4               ; Load data from D2 into P4
        CLR     D1                  ; Clear contents of D1
        MOVE.L  #0,D2
        MOVE.L  #0,D3
        MOVE.L  #0,D4
        MOVE.L  #0,D5
        MOVE.L  #0,D6

        
*-----------------------------------------------------------
* Determines operation for subroutine manipulation
        CMP.B   #$C,H               ; Store C into the first hex value of OpCode
        BNE     SUBA_CHECK          ; Check not equal, branch to SUBA_CHECK
        CMP.B   #$7,P2
        BEQ     MULSW

SUBA_CHECK
        CMP.B   #$3,P2
        BEQ     SUBA
        CMP.B   #$7,P2
        BEQ     SUBA
        CMP.B   #$0,P2
        BEQ     CHECK_S1_0
        CMP.B   #$1,P2
        BEQ     CHECK_S2_0
        CMP.B   #$2,P2
        BEQ     CHECK_S3_0
        CMP.B   #$4,P2
        BEQ     CHECK_S4_0
        CMP.B   #$5,P2
        BEQ     CHECK_S5_0
        CMP.B   #$6,P2
        BEQ     CHECK_S6_0
   
*-----------------------------------------------------------
* Display size and order of operation
CHECK_S1_0
        BSR     SUBPRINT
        LEA     C_BYTE,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_TAB,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     CHECK_S1_1,A2
        BRA     EA_MODE             ; Branch to EA subroutines
CHECK_S1_1
        LEA     CHECK_S1_2,A2
        LEA     C_COMMA,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     DN_SUB0
CHECK_S1_2
        BRA     ENDNEWLINE          ; Go to next opcode

*-----------------------------------------------------------
* |001 word|    |EA,DN|
CHECK_S2_0
        BSR     SUBPRINT
        LEA     C_WORD,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_TAB,A1
        MOVE.B  #14,D0
        TRAP    #15

        LEA     CHECK_S2_1,A2
        BRA     EA_MODE             ; Branch to EA subroutines
CHECK_S2_1
        LEA     CHECK_S2_2,A2
        LEA     C_COMMA,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     DN_SUB0             ; Branch to DN_SUB0
CHECK_S2_2
        BRA     ENDNEWLINE          ; Go to next opcode

*-----------------------------------------------------------
* |010 long|    |EA,DN|
CHECK_S3_0
        BSR     SUBPRINT
        LEA     C_LONG,A1           ; Load long effective address into A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_TAB,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     CHECK_S3_1,A2
        BRA     EA_MODE             ; Branch to ea subroutines
CHECK_S3_1
        LEA     CHECK_S3_2,A2       ; load 32 bit effective address into A2
        LEA     C_COMMA,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     DN_SUB0             ; Branch to DN_SUB0
CHECK_S3_2
        BRA     ENDNEWLINE          ; Go to next opcode

*-----------------------------------------------------------
*   |100 byte|    |DN,EA|
CHECK_S4_0
        BSR     SUBPRINT
        LEA     C_BYTE,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_TAB,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     CHECK_S4_1,A2
        BRA     DN_SUB0              ; Branch to SUB subroutines
CHECK_S4_1
        LEA     CHECK_S4_2,A2
        LEA     C_COMMA,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     EA_MODE              ; Branch to EA subroutines
CHECK_S4_2
        BRA     ENDNEWLINE           ; Go to next opcode

*-----------------------------------------------------------
*   |101 word|    |DN,EA|
CHECK_S5_0
        BSR     SUBPRINT
        LEA     C_WORD,A1            ; Load word effective address to A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_TAB,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     CHECK_S5_1,A2
        BRA     DN_SUB0              ; Branch to DN_SUB0
CHECK_S5_1
        LEA     CHECK_S5_2,A2
        LEA     C_COMMA,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     EA_MODE              ; Branch to EA subroutines
CHECK_S5_2
        BRA     ENDNEWLINE           ; Go to next opcode

*-----------------------------------------------------------
*   |110 long|    |DN,EA|
CHECK_S6_0
        BSR     SUBPRINT
        LEA     C_LONG,A1            ; Load effective address into A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_TAB,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     CHECK_S6_1,A2
        BRA     DN_SUB0             ; Branch to SUB subroutines
CHECK_S6_1
        LEA     CHECK_S6_2,A2
        LEA     C_COMMA,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     EA_MODE             ; Branch to EA subroutines
CHECK_S6_2
        BRA     ENDNEWLINE          ; Go to next opcode

*-----------------------------------------------------------
*   Subroutines: SUBA
SUBA
        CMP.B   #$9,H
        BEQ     PRINT_SUBA
        CMP.B   #$B,H
        BEQ     PRINT_CMPA
        CMP.B   #$D,H
        BEQ     PRINT_ADDA

PRINT_SUBA
        LEA     C_SUBA,A1 
        MOVE.B  #14,D0
        TRAP    #15
        BRA     SUBA_CT            ; Branch to SUB helper

PRINT_CMPA
        LEA     C_CMPA,A1 
        MOVE.B  #14,D0
        TRAP    #15
        BRA     SUBA_CT            ; Branch to SUB helper

PRINT_ADDA
        LEA     C_ADDA,A1 
        MOVE.B  #14,D0
        TRAP    #15
        BRA     SUBA_CT            ; Branch to SUB helper

* Retrieve count of SUBA instruction
SUBA_CT
        CMP.B   #$3,P2             ; Check whether larger than 3
        BEQ     CHECK_S7_0
        CMP.B   #$7,P2             ; Check whether larger than 7
        BEQ     CHECK_S8_0                

*-----------------------------------------------------------
*   |SUBA Word|   |ea,An|
CHECK_S7_0
        LEA     C_WORD,A1          ; Load effective address into A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_TAB,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     CHECK_S7_1,A2
        BRA     EA_MODE            ; Branch to ea subroutines
CHECK_S7_1
        LEA     CHECK_S7_2,A2
        LEA     C_COMMA,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     AN_SUB1            ; Branch to SUB
CHECK_S7_2
        BRA     ENDNEWLINE         ; Go to next opcode

*-----------------------------------------------------------
*   |SUBA longword|   |ea,An|
CHECK_S8_0
        LEA     C_LONG,A1          ; Load longword effective address into A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_TAB,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     CHECK_S7_1,A2
        BRA     EA_MODE             ; Branch to select effective address mode
CHECK_S8_1
        LEA     CHECK_S7_2,A2
        LEA     C_COMMA,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     AN_SUB1
CHECK_S8_2
        BRA     ENDNEWLINE           ; Go to next opcode

*-----------------------------------------------------------
* Jump to A2
JUMPTOA2
        JMP     (A2)

*-----------------------------------------------------------
SUBPRINT
        CMP.B   #$9,H                ; Print SUB to display
        BEQ     SUBPRINTSUB
        CMP.B   #$B,H                ; Print EOR / CMP to display
        BEQ     SUBPRINTB
        CMP.B   #$C,H                ; Print AND to display
        BEQ     SUBPRINTAND
        CMP.B   #$D,H                ; Print ADD to display
        BEQ     SUBPRINTADD

SUBPRINTSUB
        LEA     C_SUB,A1              ; Load ea to A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     SUBPRINTEND           ; Branch to next print subroutines

SUBPRINTAND  
        LEA     C_AND,A1              ; Load ea to A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     SUBPRINTEND           ; Branch to next print subroutines

SUBPRINTADD 
        LEA     C_ADD,A1              ; Load ea to A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     SUBPRINTEND           ; Branch to next print subroutines

SUBPRINTB
        CMP.B   #$4,P2
        BLT     SUBPRINTCMP

SUBPRINTEOR 
        LEA     C_EOR,A1              ; Load ea to A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     SUBPRINTEND

SUBPRINTCMP 
        LEA     C_CMP,A1              ; Load ea to A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     SUBPRINTEND

SUBPRINTEND
        RTS


*-----------------------------------------------------------
* Tests for DN to EA operations
ERRCHECKER0
        CMP.B   #0,P3
        BEQ     OP_HELPER0
        CMP.B   #1,P3
        BEQ     OP_HELPER0
        CMP.B   #7,P3
        BNE     ERRCHECKER1
        CMP.B   #0,P4
        BEQ     ERRCHECKER1
        CMP.B   #1,P4
        BEQ     ERRCHECKER1
        BRA     OP_HELPER0
        
ERRCHECKER1
        RTS

*-----------------------------------------------------------
* Subroutines for DN to EA operations
DN_SUB0
        LEA     C_DN,A1
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  P1,D1
        MOVE.B  #3,D0
        TRAP    #15
        BRA     JUMPTOA2        ; Branch to Jump to A2

DN_SUB1
        LEA     C_DN,A1
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  P4,D1
        MOVE.B  #3,D0
        TRAP    #15
        BRA     JUMPTOA2        ; Branch to Jump to A2

AN_SUB0
        LEA     C_AN,A1
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  P4,D1
        MOVE.B  #3,D0
        TRAP    #15
        BRA     JUMPTOA2        ; Branch to Jump to A2

AN_SUB1
        LEA     C_AN,A1
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  P1,D1
        MOVE.B  #3,D0
        TRAP    #15
        BRA     JUMPTOA2        ; Branch to Jump to A2

ANI_SUB
        LEA     C_OBRACK,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_AN,A1
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  P4,D1
        MOVE.B  #3,D0
        TRAP    #15
        LEA     C_CBRACK,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     JUMPTOA2        ; Branch to Jump to A2

ANPOS_SUB
        LEA     C_OBRACK,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_AN,A1
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  P4,D1
        MOVE.B  #3,D0
        TRAP    #15
        LEA     C_CBRACK,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_PLUS,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     JUMPTOA2        ; Branch to Jump to A2

ANNEG_SUB
        LEA     C_NEG,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_OBRACK,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_AN,A1
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  P4,D1           ; Store data from P4 into D1
        MOVE.B  #3,D0
        TRAP    #15
        LEA     C_CBRACK,A1     ; Load ea into A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     JUMPTOA2        ; Branch to Jump to A2

*-----------------------------------------------------------
* Print Effective Address using hexidecimal
* Determines effective address mode
EA_MODE
        CMP.B   #$0,P3
        BEQ     DN_SUB1
        CMP.B   #$1,P3
        BEQ     AN_SUB0
        CMP.B   #$2,P3
        BEQ     ANI_SUB
        CMP.B   #$3,P3
        BEQ     ANPOS_SUB
        CMP.B   #$4,P3
        BEQ     ANNEG_SUB
        CMP.B   #$5,P3
        BEQ     ERROR
        CMP.B   #$6,P3
        BEQ     ERROR
        CMP.B   #$7,P3
        BEQ     SUB_EA0

SUB_EA0
        CMP.B   #$4,P4
        BEQ     SUB_EA2
        
SUB_EA1
        LEA     C_HEX,A1
        MOVE.B  #14,D0
        TRAP    #15

        CMP.B   #$0,P4
        BEQ     EA_HEX0
        CMP.B   #$1,P4
        BEQ     EA_HEX1

        CMP.B   #$0,P2              ; Display byte as word
        BEQ     EA_HEX0
        CMP.B   #$4,P2  
        BEQ     EA_HEX0
        CMP.B   #$1,P2  
        BEQ     EA_HEX0
        CMP.B   #$5,P2 
        BEQ     EA_HEX0
        CMP.B   #$3,P2 
        BEQ     EA_HEX0
        CMP.B   #$2,P2  
        BEQ     EA_HEX1
        CMP.B   #$6,P2 
        BEQ     EA_HEX1
        CMP.B   #$7,P2  
        BEQ     EA_HEX1

SUB_EA2
        LEA     C_HASH,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     SUB_EA1

EA_HEX0  
        MOVE.B  #2,D7
        BRA     EA_HEX2
EA_HEX1 
        MOVE.B  #4,D7
        BRA     EA_HEX2
EA_HEX2
        CMP.B   #0,D7               ; Check if current address = ending address
        BEQ     JUMPTOA2            ; if equal, end
        MOVE.B  (A6)+,D2            ; Load data to D1
        MOVE.B  D2,D3               ; Loads data to D3 from D2
        LSR.B   #4,D3               ; Shift right 
        LSL.B   #4,D2               ; Shift left 
        LSR.B   #4,D2               ; Shifts right to reset
        MOVE.B  D3,D1
        LEA     EA_HEX3,A3          ; Store address to A3
        CMP.B   #9,D1
        BGT     CONVERTER           ; If >9 Print ASCII conversion
        MOVE.B  #3,D0
        TRAP    #15
EA_HEX3    
        MOVE.B  D2,D1               ; Move contents of D2 into D1
        LEA     EA_HEX4,A3          ; Loads the next address to A3
        CMP.B   #9,D1               
        BGT     CONVERTER           ; If >9 Print ASCII conversion
        MOVE.B  #3,D0     
        TRAP    #15
EA_HEX4         
        SUB.B   #1,D7                       
        BRA     EA_HEX2             ; Go to next address

*-----------------------------------------------------------
* Prints EA in hexidecimal
PRINT_EA
        LEA     C_HEX,A1            ; Load ea to A1
        MOVE.B  #14,D0
        TRAP    #15
        CMP.B   #$2,D4              ; if size = 2, branch to longword
        BEQ     PRINT_EAL

PRINT_EAW
        MOVE.B  #2,D7
        BRA     PRINT_EA0             ; Branch to display ea subroutines
PRINT_EAL
        MOVE.B  #4,D7
        BRA     PRINT_EA0             ; Branch to display ea subroutines

PRINT_EA0
        CMP.B   #0,D7               ; Check if current address = ending address
        BEQ     JUMPTOA2            ; if equal, end
        MOVE.B  (A6)+,D2            ; Loads current address into D1
        MOVE.B  D2,D3               ; Load data from D2 to D3
        LSR.B   #4,D3
        LSL.B   #4,D2 
        LSR.B   #4,D2  
        MOVE.B  D3,D1               ; Load data from D3 to D1
        LEA     PRINT_EA1,A3          ; Load address into A3
        CMP.B   #9,D1               ; Test whether D1 is greater than or less than 9
        BGT     CONVERTER           ; Display ASCII conversion of number
        MOVE.B  #3,D0
        TRAP    #15
PRINT_EA1
        MOVE.B  D2,D1               ; Load data to D1 from D2
        LEA     PRINT_EA2,A3          ; Stores next address into A3
        CMP.B   #9,D1               
        BGT     CONVERTER 
        MOVE.B  #3,D0
        TRAP    #15
PRINT_EA2
        SUB.B   #1,D7                       
        BRA     PRINT_EA0             ; Go to next address

CLEAR_ALL                               
        CLR.L   D0                  ; Clear all data registers
        CLR.L   D1
        CLR.L   D2
        CLR.L   D3
        CLR.L   D4
        CLR.L   D5
        CLR.L   D6
        CLR.L   D7
        RTS

*-----------------------------------------------------------
* OpCode Error Handling
* Prints DATA YYYY
INC_OPCODE
        ADD.B   (A6)+,D7            ; Increment and load data to D7

* D6 is used as a loop counter
OP_HELPER0
        LEA     C_DATA,A1            ; Load ea to A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_TAB,A1
        MOVE.B  #14,D0
        TRAP    #15
        LEA     C_HEX,A1
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  #2,D6
        MOVE.W  D7,D2               ; Loads OpCode to D7
        LSR.W   #8,D2               ; Shift right
        BRA     OP_HELPER2 
OP_HELPER1
        MOVE.B  D7,D2               ; Load data to D2 from D7
OP_HELPER2
        MOVE.B  D2,D3               ; Load data to D3 from D2
        LSR.B   #4,D3               
        LSL.B   #4,D2               ; Shift left 
        LSR.B   #4,D2               ; Shifts right to reset
        MOVE.B  D3,D1               
        LEA     OP_HELPER3,A3 
        CMP.B   #9,D1  
        BGT     CONVERTER
        MOVE.B  #3,D0 
        TRAP    #15   
OP_HELPER3   
        MOVE.B  D2,D1               ; Load data to D1 from D1
        LEA     OP_HELPER4,A3       ; Loads next address to A3
        CMP.B   #9,D1               
        BGT     CONVERTER           ; Display ASCII conversion if > 9
        MOVE.B  #3,D0               ; Print number if < A
        TRAP    #15
OP_HELPER4
        SUB.B   #1,D6
        CMP.B   #0,D6
        BEQ     ENDNEWLINE
        BRA     OP_HELPER1          ; Go to next address

*-----------------------------------------------------------
* Prints new line after OpCode
ENDNEWLINE
        LEA     NEWLINE,A1
        MOVE.B  #14,D0
        TRAP    #15
        SUB.B   #1,DISPLAY_CT
        CMP.B   #0,DISPLAY_CT
        BNE     NEW_ADDRESS         ; Check if equal to new address
        LEA     NEWLINE,A1          ; Generate new line
        MOVE.B  #14,D0
        TRAP    #15
        LEA     MSG_CONT,A1 
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  #4,D0               ; Read input from user
        TRAP    #15
        CLR.L   D1                  ; Clear D1
        LEA     NEWLINE,A1          
        MOVE.B  #14,D0
        TRAP    #15
        MOVE.B  #NUM_LINES,DISPLAY_CT    ; Move the num line count of display to the DISPLAY_CT variable
        BRA     NEW_ADDRESS              ; Start over

*-----------------------------------------------------------
* Decimal to Hexidecimal Converter
CONVERTER    
         CMP.B   #10,D1             ; 10 = A
         BEQ     HEX_A
         CMP.B   #11,D1             ; 11 = B
         BEQ     HEX_B
         CMP.B   #12,D1             ; 12 = C
         BEQ     HEX_C
         CMP.B   #13,D1             ; 13 = D
         BEQ     HEX_D
         CMP.B   #14,D1             ; 14 = E
         BEQ     HEX_E
         CMP.B   #15,D1             ; 15 = F
         BEQ     HEX_F
HEX_A    LEA     C_A,A1 
         BRA     PRINT_H            ; Branch to print
HEX_B    LEA     C_B,A1 
         BRA     PRINT_H            ; Branch to print
HEX_C    LEA     C_C,A1 
         BRA     PRINT_H            ; Branch to print
HEX_D    LEA     C_D,A1 
         BRA     PRINT_H            ; Branch to print
HEX_E    LEA     C_E,A1 
         BRA     PRINT_H            ; Branch to print
HEX_F    LEA     C_F,A1  
         BRA     PRINT_H            ; Branch to print
PRINT_H  MOVE.B  #14,D0
         TRAP    #15                ; Display A1
         JMP     (A3)               ; Jump to A3

* Decimal to Hexidecimal conversion 
D2H
        CMP.B   #$30,D2             ; (0)
        BEQ     D2H_0
        CMP.B   #$31,D2             ; (1)
        BEQ     D2H_1
        CMP.B   #$32,D2             ; (2)
        BEQ     D2H_2
        CMP.B   #$33,D2             ; (3)
        BEQ     D2H_3
        CMP.B   #$34,D2             ; (4)
        BEQ     D2H_4
        CMP.B   #$35,D2             ; (5)
        BEQ     D2H_5
        CMP.B   #$36,D2             ; (6)
        BEQ     D2H_6
        CMP.B   #$37,D2             ; (7)
        BEQ     D2H_7
        CMP.B   #$38,D2             ; (8)
        BEQ     D2H_8
        CMP.B   #$39,D2             ; (9)
        BEQ     D2H_9
        CMP.B   #$41,D2             ; (A)
        BEQ     D2H_A
        CMP.B   #$42,D2             ; (B)
        BEQ     D2H_B
        CMP.B   #$43,D2             ; (C)
        BEQ     D2H_C
        CMP.B   #$44,D2             ; (D)
        BEQ     D2H_D
        CMP.B   #$45,D2             ; (E)
        BEQ     D2H_E
        CMP.B   #$46,D2             ; (F)
        BEQ     D2H_F
        CMP.B   #$61,D2             ; (A)
        BEQ     D2H_A
        CMP.B   #$62,D2             ; (B)
        BEQ     D2H_B
        CMP.B   #$63,D2             ; (C)
        BEQ     D2H_C
        CMP.B   #$64,D2             ; (D)
        BEQ     D2H_D
        CMP.B   #$65,D2             ; (E)
        BEQ     D2H_E
        CMP.B   #$66,D2             ; (F)
        BEQ     D2H_F
        MOVE.B  #$F,D1              ; Load 'F' to D1
        RTS

D2H_0 
        MOVE.B  #$0,D3              ; Stores hexidecimal in D3
        RTS
D2H_1
        MOVE.B  #$1,D3              ; Stores hexidecimal in D3
        RTS
D2H_2
        MOVE.B  #$2,D3              ; Stores hexidecimal in D3
        RTS
D2H_3
        MOVE.B  #$3,D3              ; Stores hexidecimal in D3
        RTS
D2H_4
        MOVE.B  #$4,D3              ; Stores hexidecimal in D3
        RTS
D2H_5
        MOVE.B  #$5,D3              ; Stores hexidecimal in D3
        RTS
D2H_6
        MOVE.B  #$6,D3              ; Stores hexidecimal in D3
        RTS
D2H_7
        MOVE.B  #$7,D3              ; Stores hexidecimal in D3
        RTS
D2H_8
        MOVE.B  #$8,D3              ; Stores hexidecimal in D3
        RTS
D2H_9
        MOVE.B  #$9,D3              ; Stores hexidecimal in D3
        RTS
D2H_A
        MOVE.B  #$A,D3              ; Stores hexidecimal in D3
        RTS
D2H_B
        MOVE.B  #$B,D3              ; Stores hexidecimal in D3
        RTS
D2H_C
        MOVE.B  #$C,D3              ; Stores hexidecimal in D3
        RTS
D2H_D
        MOVE.B  #$D,D3              ; Stores hexidecimal in D3
        RTS
D2H_E
        MOVE.B  #$E,D3              ; Stores hexidecimal in D3
        RTS
D2H_F
        MOVE.B  #$F,D3              ; Stores hexidecimal in D3
        RTS

*-----------------------------------------------------------
PRMPT_AGAIN0
        LEA     NEWLINE,A1          ; Generates new line
        MOVE.B  #14,D0
        TRAP    #15
PRMPT_AGAIN1
        LEA     MSG_RETRY,A1        ; Prompts user to restart or exit program
        MOVE.B  #14,D0
        TRAP    #15

        LEA     P4,A1               ; (Y) Program will restart
        MOVE.B  #2,D0               ; (N) Program will exit
        TRAP    #15

        MOVE.B  P4,D1               ; User input stored
        CMP.B   #$59,D1             ; Y / y user input
        BEQ     BOOTSCREEN
        CMP.B   #$79,D1
        BEQ     BOOTSCREEN
        
        CMP.B   #$4E,D1             ; N / n user input
        BEQ     FINISH
        CMP.B   #$6E,D1
        BEQ     FINISH
        BRA     PRMPT_AGAIN1        ; Re-request user input

*-----------------------------------------------------------
ERROR   LEA     MSG_CRASH,A1
        MOVE.B  #14,D0
        TRAP    #15
        BRA     EXIT                ; Branch to end program

FINISH  LEA     MSG_CMPLT,A1
        MOVE.B  #14,D0
        TRAP    #15

EXIT    MOVE.B  #9,D0               ; Stop program due to completion or error
        TRAP    #15

    END    START                ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
