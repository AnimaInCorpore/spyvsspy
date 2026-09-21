.ORG $E4DF

TitleHelperChain:
    STA $2F
    STX $2E
    TXA
    AND #$0F
    BNE $E4EC
    CPX #$80
    BCC $E4F1
    LDY #$86
    JMP $E670

E4F3:
    LDA $20
    CMP #$7F
    BNE $E50E
    LDA $22
    CMP #$0C
    BEQ $E570
    LDA $02E9
    BNE $E509
    LDY #$82
    JMP $E670
    JSR $CA29
    BMI $E506
    LDY #$84
    LDA $22
    CMP #$03
    BCC $E53B
    TAY
    CPY #$0E
    BCC $E51D
    LDY #$0E
    STY $17
    LDA $E72A,Y
    BEQ $E533
    CMP #$02
    BEQ $E570
    CMP #$08
    BCS $E58B
    CMP #$04
    BEQ $E5A6
    JMP $E61E
    LDA $20
    CMP #$FF
    BEQ $E53E
    LDY #$81
    JMP $E670
    LDA $02E9
    BNE $E56A
    JSR $E6FF
    BCS $E56A
    LDA #$00
    STA $02EA
    STA $02EB
    JSR $E695
    BCS $E53B
    JSR $E6EA
    LDA #$0B
    STA $17
    JSR $E695
    LDA $2C
    STA $26
    LDA $2D
    STA $27
    JMP $E672
    JSR $EEF9
    JMP $E670
    LDY #$01
    STY $23
    JSR $E695
    BCS $E57C
    JSR $E6EA
    LDA #$FF
    STA $20
    LDA #$E4
    STA $27
    LDA #$DB
    STA $26
    JMP $E672
    LDA $20
    CMP #$FF
    BNE $E596
    JSR $E6FF
    BCS $E53B
    JSR $E695
    JSR $E6EA
    LDX $2E
    LDA $0340,X
    STA $20
    JMP $E672
    LDA $22
    AND $2A
    BNE $E5B1
    LDY #$83
    JMP $E670
    JSR $E695
    BCS $E5AE
    LDA $28
    ORA $29
    BNE $E5C4
    JSR $E6EA
    STA $2F
    JMP $E672
    JSR $E6EA
    STA $2F
    BMI $E60C
    LDY #$00
    STA ($24),Y
    JSR $E6D1
    LDA $22
    AND #$02
    BNE $E5E4
    LDA $2F
    CMP #$9B
    BNE $E5E4
    JSR $E6BB
    JMP $E618
    JSR $E6BB
    BNE $E5C4
    LDA $22
    AND #$02
    BNE $E60C
    JSR $E6EA
    STA $00
    SLO ($CA,X)
    BPL $E5EF
    LDX $0312
    STX $030A
    INX
    STX $0312
    LDA $0313
    STA $0300
    JMP $E459
    ; $E603-$E60E is an inline data blob skipped by the jump above.
    .BYTE $00, $01, $26, $40, $FD, $03, $1E, $00, $80, $00, $00, $00
    STY $0312
    STA $0313
    LDA #$E9
    STA $4A
    LDA #$03
    STA $4B
    LDY #$12
    LDA ($4A),Y
    TAX
    INY
    LDA ($4A),Y
    CMP $0313
    BNE $E639
    CPX $0312
    BNE $E639
    CLC
    RTS
    CMP #$00
    BNE $E643
    CPX #$00
    BNE $E643
    SEC
    RTS
    STX $4A
    STA $4B
    JSR $CB56
    BNE $E641
    BEQ $E625
    SEC
    PHP
    BCS $E67A
    STA $02ED
    STY $02EC
    PHP
    LDA #$00
    TAY
    JSR $E85D
    BCS $E688
    LDY #$12
    LDA $02EC
    STA ($4A),Y
    TAX
    INY
    LDA $02ED
    STA ($4A),Y
    STX $4A
    STA $4B
    LDA #$00
    STA ($4A),Y
    DEY
    STA ($4A),Y
    JSR $E900
    BCC $E68B
    LDA $02ED
    LDY $02EC
    JSR $E915
    PLP
    SEC
    RTS
    PLP
    BCS $E697
    LDA #$00
    LDY #$10
    STA ($4A),Y
    INY
    STA ($4A),Y
    CLC
    LDY #$10
    LDA $02E7
    ADC ($4A),Y
    STA $02E7
    INY
    LDA $02E8
    ADC ($4A),Y
    STA $02E8
    LDY #$0F
    LDA #$00
    STA ($4A),Y
    JSR $CB56
    LDY #$0F
    STA ($4A),Y
    CLC
    RTS
    CLC
    LDA $4A
    ADC #$0C
    STA $0312
    LDA $4B
    ADC #$00
    STA $0313
    JMP ($0312)
    JMP $C272
    JSR $E85D
    BCS $E70F
    TAY
    LDA $4A
    PHA
    LDA $4B
    PHA
    STX $4A
    STY $4B
    LDA $0244
    BNE $E6F3
    LDY #$10
    CLC
    LDA ($4A),Y
    INY
    ADC ($4A),Y
    BNE $E70D
    JSR $CB56
    BNE $E70D
