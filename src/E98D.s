.ORG $E98D

LowerBankFrameEntry:
    LDA #$0D
    STA $029C
    LDA #$28
    STA $D204
    LDA #$00
    STA $D206
    CLC
    LDA $0300
    ADC $0301
    ADC #$FF
    STA $023A
    LDA $0302
    STA $023B
    LDA $030A
    STA $023C
    LDA $030B
    STA $023D
    CLC
    LDA #$3A
    STA $32
    ADC #$04
    STA $34
    LDA #$02
    STA $33
    STA $35
    LDA #$34
    STA $D303
    JSR $ECAF
    LDA $023F
    BNE LowerBankIdleTick
    TYA
    BNE LowerBankAdvanceTurn
LowerBankIdleTick:
    DEC $029C
    BPL LowerBankFrameEntry
    JMP $EA22
LowerBankAdvanceTurn:
    LDA $0303
    BPL LowerBankInputReady
    LDA #$0D
    STA $029C
    JSR $EB87
    JSR $ECAF
    BEQ $EA22
LowerBankInputReady:
    JSR $EC9A
    LDA #$00
    STA $023F
    JSR $ECC0
    BEQ LowerBankAfterMove
    BIT $0303
    BVS LowerBankActionPath
    LDA $023F
    BNE $EA22
    BEQ $EA2A
LowerBankActionPath:
    JSR $EB87
    JSR $EAFD
LowerBankAfterMove:
    LDA $023F
    BEQ LowerBankTurnCheck
    LDA $0319
    STA $30
LowerBankTurnCheck:
    LDA $30
    CMP #$01
    BEQ $EA2A
    DEC $02BD
    BMI $EA2A
    JMP $E98D

EA22:
    DEC $02BD
    BMI $EA2A
    JMP $E98D

EA2A:
    JSR $EC84
    LDA #$00
    STA $42
    LDY $30
    STY $0303
    RTS

EA37:
    LDA #$00
    STA $023F
    CLC
    LDA #$3E
    STA $32
    ADC #$01
    STA $34
    LDA #$02
    STA $33
    STA $35
    LDA #$FF
    STA $3C
    JSR $EAFD
    LDY #$FF
    LDA $30
    CMP #$01
    BNE EA73
    LDA $023E
    CMP #$41
    BEQ EA82
    CMP #$43
    BEQ EA82
    CMP #$45
    BNE EA6F
    LDA #$90
    STA $30
    BNE EA73
EA6F:
    LDA #$8B
    STA $30
EA73:
    LDA $30
    CMP #$8A
    BEQ EA80
    LDA #$FF
    STA $023F
    BNE EA82
EA80:
    LDY #$00
EA82:
    LDA $30
    STA $0319
    RTS

EA88:
    LDA #$01
    STA $30
    JSR $EC17
    LDY #$00
    STY $31
    STY $3B
    STY $3A
    LDA ($32),Y
    STA $D20D
    STA $31
    LDA $11
    BNE $EAA5
    JMP $EDC7
EAA5:
    LDA $3A
    BEQ $EA9E
    JSR $EC84
EAAC:
    RTS

EAAD:
    TYA
    PHA
    INC $32
    BNE $EAB5
    INC $33
EAB5:
    LDA $32
    CMP $34
    LDA $33
    SBC $35
    BCC $EADB
    LDA $3B
    BNE $EACE
    LDA $31
    STA $D20D
    LDA #$FF
    STA $3B
    BNE $EAD7
EACE:
    LDA $10
    ORA #$08
    STA $10
    STA $D20E
EAD7:
    PLA
    TAY
    PLA
    RTI
EADB:
    LDY #$00
    LDA ($32),Y
    STA $D20D
    CLC
    ADC $31
    ADC #$00
    STA $31
    JMP $EAD7
EAEC:
    LDA $3B
    BEQ $EAFB
    STA $3A
    LDA $10
    AND #$F7
    STA $10
    STA $D20E
EAFB:
    PLA
EAFC:
    RTI

EAFD:
    LDA #$00
EAFF:
    LDY $030F
    BNE $EB06
    STA $31
EB06:
    STA $38
    STA $39
    LDA #$01
    STA $30
    JSR $EC40
    LDA #$3C
    STA $D303
    LDA $11
    BNE $EB1D
    JMP $EDC7
EB1D:
    LDA $0317
    BEQ $EB27
    LDA $39
    BEQ $EB16
    RTS
EB27:
    LDA #$8A
    STA $30
    RTS
EB2C:
    TYA
    PHA
    LDA $D20F
    STA $D20A
    BMI $EB3A
    LDY #$8C
    STY $30
EB3A:
    AND #$20
    BNE $EB42
    LDY #$8E
    STY $30
EB42:
    LDA $38
    BEQ $EB59
    LDA $D20D
    CMP $31
    BEQ $EB51
    LDY #$8F
    STY $30
EB51:
    LDA #$FF
    STA $39
    PLA
    TAY
    PLA
    RTI
EB59:
    LDA $D20D
    LDY #$00
    STA ($32),Y
    CLC
    ADC $31
    ADC #$00
    STA $31
    INC $32
    BNE $EB6D
    INC $33
EB6D:
    LDA $32
    CMP $34
    LDA $33
    SBC $35
    BCC $EB55
    LDA $3C
EB79:
    BEQ $EB79
    LDA #$00
    STA $3C
    BEQ $EB51
EB81:
    LDA #$FF
    STA $38
    BNE $EB55
