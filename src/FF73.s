.ORG $FF73

FF73: ; CKROM1
    LDX #$00
    STX $8B
    STX $8C
FF79:
    JSR $FFA9
    CPX #$0C
    BNE FF79
    LDA $C000
    LDX $C001
FF86:
    CMP $8B
    BNE FF90
    CPX $8C
    BNE FF90
    CLC
    RTS
FF90:
    SEC
    RTS

FF92: ; CKROM2
    LDX #$00
    STX $8B
    STX $8C
    LDX #$0C
    JSR $FFA9
    JSR $FFA9
    LDA $FFF8
    LDX $FFF9
    JMP FF86

