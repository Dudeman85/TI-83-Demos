.NOLIST
#include "ti83plus.inc"
#define    ProgStart    $9D95
.LIST
.ORG    ProgStart - 2
.DB    t2ByteTok, tAsmCmp
    LD HL, $FF
    LD (PlotSScreen), HL
    LD BC, 768
    LD HL, PlotSScreen
    LD DE, PlotSScreen + 1
    LDIR
    bcall(_GrBufCpy)
.END
