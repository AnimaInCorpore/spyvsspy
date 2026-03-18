.ORG $FC00

FC00:
    ORA ($80),Y
    DOP #$80
    DOP #$FE
    DOP #$7D
    ISC $0806,X
    DOP $80
    STY $07
    SLO ($01),Y
    TOP $1E1D,X
    SLO $8F8E,X
    BCC $FBAA
    TXA
    PHA
    TYA
    PHA
    LDY $D301
    LDA $D209
    CMP $02F2
    BNE $FC2D
    LDX $02F1
    BNE $FC76
FC2D:
    LDX $026D
    CMP #$83
    BNE $FC47
    TXA
    EOR #$FF
    STA $026D
    BNE $FC41
    TYA
    ORA #$04
    BNE $FC44
FC41:
    TYA
    AND #$FB
FC44:
    TAY
    BCS $FC6D
FC47:
    TXA
    BNE $FC87
    LDA $D209
    TAX
    CMP #$9F
    BNE $FC5C
    LDA $02FF
    EOR #$FF
    STA $02FF
    BCS $FC6D
FC5C:
    AND #$3F
    CMP #$11
    BNE $FC90
    STX $02DC
    BEQ $FC6D
    STX $02FC
    STX $02F2
    LDA #$03
    STA $02F1
    LDA #$00
    STA $4D
    LDA $02D9
    STA $022B
    LDA $022F
    BNE $FC87
    LDA $02DD
    STA $022F
FC87:
    STY $D301
    PLA
    TAY
    PLA
    TAX
    PLA
    RTI

FC90:
    CPX #$84
    BEQ $FCB5
    CPX #$94
    BNE $FC67
    LDA $02F4
    LDX $026B
    STA $026B
    STX $02F4
    CPX #$CC
    BEQ $FCAE
    TYA
    ORA #$08
    TAY
    BNE $FC6D
FCAE:
    TYA
    AND #$F7
    TAY
    JMP $FC6D

FCB5:
    LDA $022F
    BEQ $FC87
    STA $02DD
    LDA #$00
    STA $022F
    BEQ $FC87
FCB9:
    PHA
    LDA $02C6
    EOR $004F
    AND $004E
    STA $D40A
    STA $D017
    PLA
    RTI

FCD6:
    BRK
    BRK
    JMP $F983
    LDA #$CC
    STA $02EE
    LDA #$05
    STA $02EF
    RTS

FCE6:
    LDA $2B
    STA $3E
    LDA $2A
    AND #$0C
    CMP #$04
    BEQ $FCF7
    CMP #$08
    BEQ $FD34
    RTS

FCF7:
    LDA #$00
    STA $0289
    STA $3F
    LDA #$01
    JSR $FDFC
    BMI $FD2E
    LDA #$34
    STA $D302
    LDX $62
    LDY $FE93,X
    LDA $FE91,X
    TAX
    LDA #$03
    STA $022A
    JSR $E45C
    LDA $022A
    BNE $FD1B
    LDA #$80
    STA $3D
    STA $028A
    JMP $FD77
FD2A:
    LDY #$80
    DEC $11
FD2E:
    LDA #$00
    STA $0289
    RTS

FD34:
    LDA #$80
    STA $0289
    LDA #$02
    JSR $FDFC
    BMI $FD2E
    LDA #$CC
    STA $D204
    LDA #$05
    STA $D206
    LDA #$60
    STA $0300
    JSR $E468
    LDA #$34
    STA $D302
    LDX $62
    LDY $FE8F,X
    LDA $FE8D,X
    TAX
    LDA #$03
    JSR $E45C
    LDA #$FF
    STA $022A
    LDA $11
    BEQ $FD2A
    LDA $022A
    BNE $FD6A
    LDA #$00
    STA $3D
FD77:
    LDY #$01
    RTS

FD7A:
    LDA $3F
    BMI $FDB1
    LDX $3D
    CPX $028A
    BEQ $FD8D
    LDA $0400,X
    INC $3D
    LDY #$01
    RTS
FD8D:
    LDA #$52
    JSR $FE3F
    TYA
    BMI $FD8C
    LDA #$00
    STA $3D
    LDX #$80
    LDA $03FF
    CMP #$FE
    BEQ $FDAF
    CMP #$FA
    BNE $FDA9
    LDX $047F
FDA9:
    STX $028A
    JMP $FD7A
FDAF:
    DEC $3F
FDB1:
    LDY #$88
    RTS

FDFC:
    STA $40
    LDA $14
    CLC
    LDX $62
    ADC $FE95,X
    TAX
    LDA #$FF
    STA $D01F
    LDA #$00
FE10:
    LDY #$F0
FE10Loop:
    DEY
    BNE FE10Loop
    STA $D01F
    LDY #$F0
FE18Loop:
    DEY
    BNE FE18Loop
    CPX $14
    BNE $FE07
    DEC $40
    BEQ $FE31
    TXA
    CLC
    LDX $62
    ADC $FE97,X
    TAX
    CPX $14
    BNE $FE2B
    BEQ $FDFE
FE31:
    JSR $FE36
    TYA
    RTS

FE36:
    LDA $E425
    PHA
    LDA $E424
    PHA
    RTS

FE3F:
    STA $0302
    LDA #$00
    STA $0309
    LDA #$83
    STA $0308
    LDA #$03
    STA $0305
    LDA #$FD
    STA $0304
    LDA #$60
    STA $0300
    LDA #$00
    STA $0301
    LDA #$23
    STA $0306
    LDA $0302
    LDY #$40
    CMP #$52
    BEQ $FE70
    LDY #$80
FE70:
    STY $0303
    LDA $3E
    STA $030B
    JSR $E459
    RTS

FE7C:
    STA $03FF
    LDA #$55
    STA $03FD
    STA $03FE
    LDA #$57
    JSR $FE3F
    RTS

