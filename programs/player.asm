.NOLIST
#include "ti83plus.inc"
#define ProgStart $9D95
.LIST
.ORG ProgStart - 2
.DB t2ByteTok, tAsmCmp

    CALL Cls

    LD HL, vid
    b_call _Mov9ToOP1
    b_call _ChkFindSym

    LD A, (DE)
    LD C, A
    INC DE
    LD A, (DE)
    LD B, A
    INC DE

    JR C, NoFile

    EX DE, HL
    ;AppBackUpScreen = 9872
    LD (AppBackupScreen), HL
    LD A, 1 ; How many frames to draw 
    LD (AppBackupScreen + 2), A 
FrameStart:
    LD BC, 768
    LD HL, (AppBackupScreen)
    LD DE, PlotSScreen
    LDIR
    LD (AppBackupScreen), HL
    bcall (_GrBufCpy)

FrameDelay:
    LD B, 10
    NOP
    DJNZ FrameDelay

    LD A, (AppBackupScreen + 2)
    DEC A
    LD (AppBackupScreen + 2), A
    ;JR NZ, FrameStart
    
    RET

NoFile:
    b_call _ClrLCDFull
    ld    hl, 0
    ld    (PenCol), hl
    ld    hl, msg
    b_call _PutS
    b_call _NewLine
    RET

; Clear the graph buffer. Destroys HL, DE, BC
Cls:
    LD HL, 0
    LD (PlotSScreen), HL
    LD BC, 768
    LD HL, PlotSScreen
    LD DE, PlotSScreen + 1
    LDIR
    RET

vid: .DB AppVarObj, tV, tI, tD, t1, 0
msg: .DB "File Not Found", 0
.END
