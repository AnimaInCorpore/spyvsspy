.ORG $E739

TitleMenuFlow:
    LDA $08
    BEQ $E762
    LDA #$E9
    STA $4A
    LDA #$03
    STA $4B
    LDY #$12
    CLC
    LDA ($4A),Y
    TAX
    INY
    ADC ($4A),Y
    BEQ $E776
    LDA ($4A),Y
    STA $4B
    STX $4A
    JSR $CB56
    BNE $E776
    JSR $E894
    BCS $E776
    BCC $E745
    LDA #$00
    STA $03FB
    STA $03FC
    LDA #$4F
    BNE $E79B
    LDA #$00
    TAY
    JSR $E7BE
    BPL $E777
    RTS
E777:
    ISC $02
    ADC $02EA
    STA $0312
    LDA $02E8
    ADC $02EB
    STA $0313
    SEC
    LDA $02E5
    SBC $0312
    LDA $02E6
    SBC $0313
    BCS $E7A0
    LDA #$4E
    TAY
    JSR $E7BE
    JMP $E76E
    LDA $02EC
    LDX $02E7
    STX $02EC
    LDX $02E8
    STX $02ED
    JSR $E7DE
    BMI $E797
    SEC
    JSR $E89E
    BCS $E797
    BCC $E76C
    PHA
    LDX #$09
    LDA $E7D4,X
    STA $0300,X
    DEX
    BPL $E7BF
    STY $030B
    PLA
    STA $030A
    JMP $E459
    SRE $4001
    RTI
    NOP
    .BYTE $02
    ASL $0400,X
    BRK
    STA $0313
    LDX #$00
    STX $0312
    DEX
    STX $0315
    LDA $02EC
    ROR A
    BCC $E7F6
    INC $02EC
    BNE $E7F6
    INC $02ED
    LDA $02EC
    STA $02D1
    LDA $02ED
    STA $02D2
    LDA #$16
    STA $02CF
    LDA #$E8
    STA $02D0
    LDA #$80
    STA $02D3
    JMP $C745
    LDX $0315
    INX
    STX $0315
    BEQ $E825
    LDX $0315
    LDA $037D,X
    CLC
    RTS
    LDA #$80
    STA $0315
    JSR $E833
    BPL $E81D
    SEC
    RTS
    LDX #$0B
    LDA $E851,X
    STA $0300,X
    DEX
    BPL $E833
    LDX $0312
    STX $030A
    INX
    STX $0312
    LDA $0313
    STA $0300
    JMP $E459
    BRK
    ORA ($26,X)
    RTI
    SBC $1E03,X
    BRK
    DOP #$00
    BRK
    BRK
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
    BNE $E87D
    CPX $0312
    BNE $E87D
    CLC
    RTS
    CMP #$00
    BNE $E887
    CPX #$00
    BNE $E887
    SEC
    RTS
    STX $4A
    STA $4B
    JSR $CB56
    BNE $E885
    BEQ $E869
    SEC
    PHP
    BCS $E8BE
    STA $02ED
    STY $02EC
    PHP
    LDA #$00
    TAY
    JSR $E85D
    BCS $E8CC
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
    BCC $E8CF
    LDA $02ED
    LDY $02EC
    JSR $E915
    PLP
    SEC
    RTS
    PLP
    BCS $E8DB
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
    BCS $E953
    TAY
    LDA $4A
    PHA
    LDA $4B
    PHA
    STX $4A
    STY $4B
    LDA $0244
    BNE $E937
    LDY #$10
    CLC
    LDA ($4A),Y
    INY
    ADC ($4A),Y
    BNE $E951
    JSR $CB56
    BNE $E951
