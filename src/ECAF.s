.ORG $ECAF

LowerBankSetupHelper:
    LDX #$01
ECB1:
    LDY #$FF
ECB3:
    DEY
    BNE $ECB3
    DEX
    BNE $ECB1
    JSR $EA88
    LDY #$02
    LDX #$00
    JSR $EDE2
    JSR $EA37
    TYA
    RTS

ECC8:
    STA $0310
    STY $0311
    JSR $ED2E
    STA $0310
    LDA $030C
    JSR $ED2E
    STA $030C
    LDA $0310
    SEC
    SBC $030C
    STA $0312
    LDA $0311
    SEC
    SBC $030D
    TAY
    LDX $62
ECF1:
    LDA #$00
    SEC
    SBC $EE19,X
    CLC
    ADC $EE19,X
    DEY
    BPL $ECF7
    CLC
    ADC $0312
    TAY
    LSR A
    LSR A
    LSR A
    ASL A
    SEC
    SBC #$16
    TAX
    TYA
    AND #$07
    TAY
    LDA #$F5
    CLC
    ADC #$0B
    DEY
    BPL $ED11
    LDY #$00
    SEC
    SBC #$07
    BPL $ED1F
    DEY
ED1F:
    CLC
    ADC $EDF9,X
    STA $02EE
    TYA
    ADC $EDFA,X
    STA $02EF
    RTS

ED2E:
    CMP #$7C
    BMI $ED36
    SEC
    SBC #$7C
    RTS
ED36:
    CLC
    LDX $62
    ADC $EE1B,X
    RTS

ED3D:
    LDA $11
    BNE $ED44
    JMP $EDC7
ED44:
    SEI
    LDA $0317
    BNE $ED4C
    BEQ $ED71
ED4C:
    LDA $D20F
    AND #$10
    BNE $ED3D
    STA $0316
    LDX $D40B
    LDY $14
    STX $030C
    STY $030D
    LDX #$01
    STX $0315
    LDY #$0A
    LDA $11
    BEQ $EDC7
    LDA $0317
    BNE $ED75
ED71:
    CLI
    JMP $EB27
ED75:
    LDA $D20F
    AND #$10
    CMP $0316
    BEQ $ED68
    STA $0316
    DEY
    BNE $ED68
    DEC $0315
    BMI $ED96
    LDA $D40B
    LDY $14
    JSR $ECC8
    LDY #$09
    BNE $ED68
ED96:
    LDA $02EE
    STA $D204
    LDA $02EF
    STA $D206
    LDA #$00
    STA $D20F
    LDA $0232
    STA $D20F
EDAD:
    LDA #$55
    STA ($32),Y
    INY
    STA ($32),Y
    LDA #$AA
    STA $31
    CLC
    LDA $32
    ADC #$02
    STA $32
    LDA $33
    ADC #$00
    STA $33
    CLI
    RTS

EDC7:
    JSR $EC84
    LDA #$3C
    STA $D302
    LDA #$3C
    STA $D303
    LDA #$80
    STA $30
    LDX $0318
    TXS
    DEC $11
    CLI
    JMP $EA2A

; -----------------------------------------------------------------------------
; VBI runtime tail
; -----------------------------------------------------------------------------

