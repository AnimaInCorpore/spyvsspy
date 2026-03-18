.ORG $EF00

UpperBankInit:
    LDX $10E7,Y
    SLO ($A0,X)
    DOP #$60
    LDA #$7F
    STA $20
    LDA #$25
    STA $26
    LDA #$EF
    STA $27
    LDA $02EC
    LDX $002E
    STA $034D,X
    LDY #$00
    LDA ($24),Y
    STA $034C,X
    LDY #$01
    RTS

EF26:
    PHA
    TXA
    PHA
    AND #$0F
    BNE $EF3D
    CPX #$80
    BPL $EF3D
    LDA $02E9
    BNE $EF41
EF36:
    LDY #$82
    PLA
    PLA
    CPY #$00
    RTS
EF3D:
    LDY #$86
    BMI $EF38
EF41:
    STX $002E
    LDY #$00
    LDA $0340,X
    STA $0020,Y
    INX
    INY
    CPY #$0C
    BMI $EF46
    JSR $CA29
    BMI $EF38
    PLA
    TAX
    PLA
    TAY
    LDA $27
    PHA
    LDA $26
    PHA
    TYA
    LDY #$92
    RTS
EF65:
    BRK
    BRK
    BRK
    BRK
    BRK
    BRK
    JMP $FD05
    LDA #$FF
    STA $02FC
    LDA $02E4
    STA $6A
    LDA #$40
    STA $02BE
    LDA #$51
    STA $79
    LDA #$FB
    STA $7A
    LDA #$11
    STA $60
    LDA #$FC
    STA $61
    RTS

EF8E:
    LDA $2B
    AND #$0F
    BNE $EF9C
    LDA $2A
    AND #$0F
    STA $2A
    LDA #$00
EF9C:
    STA $57
    CMP #$10
    BCC $EFA7
    LDA #$91
    JMP $F154

EFA7:
    LDA #$E0
    STA $02F4
    LDA #$CC
    STA $026B
    LDA #$02
    STA $02F3
    STA $022F
    LDA #$01
    STA $4C
    LDA #$C0
    ORA $10
    STA $10
    STA $D20E
    LDA #$40
    STA $D40E
    BIT $026E
    BPL $EFDC
    LDA #$C4
    STA $0200
    LDA #$FC
    STA $0201
    LDA #$C0
EFDC:
    STA $D40E
    LDA #$00
    STA $0293
    STA $64
    STA $7B
    STA $02F0
    LDY #$0E
    LDA #$01
    STA $02A3,Y
    DEY
    BPL $EFEF
    LDX #$04
    LDA $FB08,X
    STA $02C4,X
    DEX
    BPL $EFF7
    LDY $6A
    DEY
    STY $0295
    LDA #$60
    STA $0294
    LDX $57
    LDA $EE4D,X
    STA $51
    LDA $6A
    STA $65
    LDY $EE1D,X
    LDA #$28
    JSR $F57A
    DEY
    BNE $F019
    LDA $026F
    AND #$3F
    STA $67
    TAY
    CPX #$08
    BCC $F04C
    CPX #$0F
    BEQ $F03E
    CPX #$0C
    BCS $F04C
    TXA
    ROR A
    ROR A
    ROR A
    AND #$C0
    ORA $67
    TAY
F03E:
    LDA #$10
    JSR $F57A
    CPX #$0B
    BNE $F04C
    LDA #$06
    STA $02C8

F04C:
    STY $026F
    LDA $64
    STA $58
    LDA $65
    STA $59
    LDA $D40B
    CMP #$7A
    BNE $F057
    JSR $F578
    LDA $EE5D,X
    BEQ $F06C
    LDA #$FF
    STA $64
    DEC $65
F06C:
    JSR $F565
    LDA $64
    STA $68
    LDA $65
    STA $69
    LDA #$41
    JSR $F570
    STX $66
    LDA #$18
    STA $02BF
    LDA $57
    CMP #$0C
    BCS $F08D
    CMP #$09
    BCS $F0C6
F08D:
    LDA $2A
    AND #$10
    BEQ $F0C6
    LDA #$04
    STA $02BF
    LDX #$02
    LDA $026E
    BEQ $F0A2
    JSR $F5A0
F0A2:
    LDA #$02
    JSR $F569
    DEX
    BPL $F0A2
    LDY $6A
    DEY
    TYA
    JSR $F570
    LDA #$60
    JSR $F570
    LDA #$42
    JSR $F569
    CLC
    LDA #$10
    ADC $66
    TAY
    LDX $EE2D,Y
    BNE $F0DB
F0C6:
    LDY $66
    LDX $EE2D,Y
    LDA $57
    BNE $F0DB
    LDA $026E
    BEQ $F0DB
    JSR $F5A0
    LDA #$22
    STA $51
F0DB:
    LDA $51
    JSR $F570
    DEX
    BNE $F0DB
    LDA $57
    CMP #$08
    BCC $F10F
    CMP #$0F
    BEQ $F0F1
    CMP #$0C
    BCS $F10F
F0F1:
    LDX #$5D
    LDA $6A
    SEC
    SBC #$10
    JSR $F570
    LDA #$00
    JSR $F570
    LDA $51
    ORA #$40
    JSR $F570
    LDA $51
    JSR $F570
    DEX
    BNE $F107
F10F:
    LDA $59
    JSR $F570
    LDA $58
    JSR $F570
    LDA $51
    ORA #$40
    JSR $F570
    LDA #$70
    JSR $F570
    LDA #$70
    JSR $F570
    LDA $64
    STA $0230
    LDA $65
    STA $0231
    LDA #$70
    JSR $F570
    LDA $64
    STA $02E5
    LDA $65
    STA $02E6
    LDY #$01
    LDA $0230
    STA ($68),Y
    INY
    LDA $0231
    STA ($68),Y
    LDA $4C
    BPL $F164
    STA $03EC
    JSR $EF94
    LDA $03EC
    LDY #$00
    STY $03EC
    TAY
    RTS

F164:
    LDA $2A
    AND #$20
    BNE $F175
    JSR $F420
    STA $0290
    LDA $52
    STA $0291
F175:
    LDA #$22
    ORA $022F
    STA $022F
    JMP $F20B

F180:
    JSR $F6CA
    JSR $F18F
    JSR $F76A
    JSR $F60A
    JMP $F21E

F18F:
    JSR $F5AC
    LDA ($64),Y
    AND $02A0
    LSR $6F
    BCS $F19E
    LSR A
    BPL $F197
F19E:
    STA $02FA
    CMP #$00
    RTS

F1A4:
    STA $02FB
    CMP #$7D
    BNE $F1B1
    JSR $F420
    JMP $F20B

F1B1:
    JSR $F6CA
    LDA $02FB
    CMP #$9B
    BNE $F1C1
    JSR $F661
    JMP $F20B

F1C1:
    JSR $F1CA
    JSR $F60E
    JMP $F20B

F1CA:
    LDA $02FF
    BNE $F1CA
    LDX #$02
    LDA $54,X
    STA $5A,X
    DEX
    BPL $F1D1
    LDA $02FB
    TAY
    ROL A
    ROL A
    ROL A
    ROL A
    AND #$03
    TAX
    TYA
    AND #$9F
    ORA $FB49,X
    STA $02FA
    JSR $F5AC
    LDA $02FA
    LSR $6F
    BCS $F1FA
    ASL A
    JMP $F1F2

F1FA:
    AND $02A0
    STA $50
    LDA $02A0
    EOR #$FF
    AND ($64),Y
    ORA $50
    STA ($64),Y
    RTS

F20B:
    JSR $F18F
    STA $5D
    LDX $57
    BNE $F21E
    LDX $02F0
    BNE $F21E
    EOR #$80
    JSR $F1E9

F21E:
    LDY $4C
    JMP $F226

F223:
    JMP $C8FC

F226:
    LDA #$01
    STA $4C
    LDA $02FB
    RTS

F22E:
    BIT $026E
    BPL $F21E
    LDA #$40
    STA $D40E
    LDA #$00
    STA $026E
    LDA #$CE
    STA $0200
    LDA #$C0
    STA $0201
    JMP $EF94

F24A:
    JSR $F962
    JSR $F6BC
    LDA $6B
    BNE $F288
    LDA $54
    STA $6C
    LDA $55
    STA $6D
F25C:
    JSR $F2FD
    STY $4C
    LDA $02FB
    CMP #$9B
    BEQ $F27A
    JSR $F2BE
    JSR $F962
    LDA $63
    CMP #$71
    BNE $F277
    JSR $F556
F277:
    JMP $F25C

F27A:
    JSR $F718
    JSR $F8B1
    LDA $6C
    STA $54
    LDA $6D
    STA $55

F288:
    LDA $6B
    BEQ $F29D
    DEC $6B
    BEQ $F29D
    LDA $4C
    BMI $F28C
    JSR $F180
    STA $02FB
    JMP $F962

F29D:
    JSR $F661
    LDA #$9B
    STA $02FB
    JSR $F20B
    STY $4C
    JMP $F962

F2AD:
    JMP ($0064)

F2B0:
    STA $02FB
    JSR $F962
    JSR $F6BC
    LDA #$00
    STA $03E8
    JSR $F718
    JSR $F93C
    BEQ $F2CF
    ASL $02A2
    JSR $F1B4
    JMP $F962

F2CF:
    LDA $02FE
    ORA $02A2
    BNE $F2C6
    ASL $02A2
    INX
    LDA $03E8
    BEQ $F2E5
    TXA
    CLC
    ADC #$2D
    TAX
F2E5:
    LDA $FB0D,X
    STA $64
    LDA $FB0E,X
    STA $65
    JSR $F2AD
    JSR $F20B
    JMP $F962

F2F8:
    LDA #$FF
    STA $02FC

F2FD:
    LDA #$00
    STA $03E8
    LDA $2A
    LSR A
    BCS $F376
    LDA #$80
    LDX $11
    BEQ $F372
    LDA $02FC
    CMP #$FF
    BEQ $F2FD
    STA $7C
    LDX #$FF
    STX $02FC
    LDX $02DB
    BNE $F323
    JSR $F983
F323:
    TAY
    CPY #$C0
    BCS $F2F8
    LDA ($79),Y
    STA $02FB
    TAX
    BMI $F333
    JMP $F3B4
    CMP #$80
    BEQ $F2F8
    CMP #$81
    BNE $F345
    LDA $02B6
    EOR #$80
    STA $02B6
    BCS $F2F8
    CMP #$82
    BNE $F355
    LDA $02BE
    BEQ $F359
    LDA #$00
    STA $02BE
    BEQ $F2F8
    CMP #$83
    BNE $F360
    LDA #$40
    STA $02BE
    BNE $F2F8
    CMP #$84
    BNE $F36C
    LDA #$80
    STA $02BE
    JMP $F2F8
    CMP #$85
    BNE $F37B
    LDA #$88
    STA $4C
    STA $11
    LDA #$9B
    JMP $F3DA

