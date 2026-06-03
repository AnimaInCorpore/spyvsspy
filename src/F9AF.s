.ORG $F9AF

F9AF:
    LDX #$00
    LDA $22
    CMP #$11
    BEQ $F9BF
    CMP #$12
    BEQ $F9BE
    LDY #$84
    RTS
F9BE:
    INX
F9BF:
    STX $02B7
    LDA $54
    STA $02F5
    LDA $55
    STA $02F6
    LDA $56
    STA $02F7
    LDA #$01
    STA $02F8
    STA $02F9
    SEC
    LDA $02F5
    SBC $5A
    STA $76
    BCS $F9F1
    LDA #$FF
    STA $02F8
    LDA $76
    EOR #$FF
    CLC
    ADC #$01
    STA $76
F9F1:
    SEC
    LDA $02F6
    SBC $5B
    STA $77
    LDA $02F7
    SBC $5C
    STA $78
    BCS $FA19
    LDA #$FF
    STA $02F9
    LDA $77
    EOR #$FF
    STA $77
    LDA $78
    EOR #$FF
    STA $78
    INC $77
    BNE $FA19
    INC $78
FA19:
    LDX #$02
    LDY #$00
    STY $73
    TYA
    STA $70,X
    LDA $5A,X
    STA $54,X
    DEX
    BPL $FA1F
    LDA $77
    INX
    TAY
    LDA $78
    STA $7F
    STA $75
    BNE $FA40
    LDA $77
    CMP $76
    BCS $FA40
    LDA $76
    LDX #$02
    TAY
FA40:
    TYA
    STA $7E
    STA $74
    PHA
    LDA $75
    LSR A
    PLA
    ROR A
    STA $70,X
    LDA $7E
    ORA $7F
    BNE $FA56
    JMP $FB01
FA56:
    CLC
    LDA $70
    ADC $76
    STA $70
    BCC $FA61
    INC $71
FA61:
    LDA $71
    CMP $75
    BCC $FA7C
    BNE $FA6F
    LDA $70
    CMP $74
    BCC $FA7C
FA6F:
    CLC
    LDA $54
    ADC $02F8
    STA $54
    LDX #$00
    JSR $F6AE
FA7C:
    CLC
    LDA $72
    ADC $77
    STA $72
    LDA $73
    ADC $78
    STA $73
    CMP $75
    BCC $FAB5
    BNE $FA95
    LDA $72
    CMP $74
    BCC $FAB5
FA95:
    BIT $02F9
    BPL $FAAA
    DEC $55
    LDA $55
    CMP #$FF
    BNE $FAB0
    LDA $56
    BEQ $FAB0
    DEC $56
    BPL $FAB0
FAAA:
    INC $55
    BNE $FAB0
    INC $56
FAB0:
    LDX #$02
    JSR $F6AE
FAB5:
    JSR $F6CA
    JSR $F1CA
    LDA $02B7
    BEQ $FAEF
    JSR $F94C
    LDA $02FB
    STA $02BC
    LDA $54
    PHA
    JSR $F612
    PLA
    STA $54
    JSR $F6CA
    JSR $F18F
    BNE $FAE6
    LDA $02FD
    STA $02FB
    JSR $F1CA
    JMP $FAC9
FAE6:
    LDA $02BC
    STA $02FB
    JSR $F957
FAEF:
    SEC
    LDA $7E
    SBC #$01
    STA $7E
    LDA $7F
    SBC #$00
    STA $7F
    BMI $FB01
    JMP $FA4D

FB01:
    JMP $F21E

; -----------------------------------------------------------------------------
; Upper-bank tables and lookup data
; -----------------------------------------------------------------------------

