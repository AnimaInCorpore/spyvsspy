.ORG $F3A5

F3A5:
    CMP #$92
    BCS $F3B4
    CMP #$8E
    BCC $F38C
    SBC #$72
    INC $03E8
    BNE $F3DA

F3B4:
    LDA $7C
    CMP #$40
    BCS $F3CF
    LDA $02FB
    CMP #$61
    BCC $F3CF
    CMP #$7B
    BCS $F3CF
    LDA $02BE
    BEQ $F3CF
    ORA $7C
    JMP $F323

F3CF:
    JSR $F93C
    BEQ $F3DD
    LDA $02FB
    EOR $02B6
    STA $02FB
F3DD:
    JMP $F21E

F3E0:
    LDA #$80
    STA $02A2
    RTS

F3E6:
    DEC $54
    BPL $F3F0
    LDX $02BF
    DEX
F3EE:
    STX $54
F3F0:
    JMP $F90C

F3F3:
    INC $54
    LDA $54
    CMP $02BF
    BCC $F3F0
    LDX #$00
    BEQ $F3EE

F400:
    DEC $55
    LDA $55
    BMI $F40A
    CMP $52
    BCS $F40E
F40A:
    LDA $53
F40C:
    STA $55
F40E:
    JMP $F88E

F411:
    INC $55
    LDA $55
    CMP $53
    BCC $F40E
    BEQ $F40E
    LDA $52
    JMP $F40C

F420:
    JSR $F9A6
    LDY $64
    LDA #$00
    STA $64
    STA ($64),Y
    INY
    BNE $F429
    INC $65
F429:
    LDX $65
    CPX $6A
    BCC $F429
    LDA #$FF
F438:
    STA $02B2,Y
    INY
    CPY #$04
    BCC $F438

F440:
    JSR $F997
    STA $63
    STA $6D
    LDA #$00
    STA $54
    STA $56
    STA $6C
    RTS

F450:
    LDA $63
    CMP $52
    BEQ $F477
    LDA $55
    CMP $52
    BNE $F45F
    JSR $F923
F45F:
    JSR $F400
    LDA $55
    CMP $53
    BNE $F46F
    LDA $54
    BEQ $F46F
    JSR $F3E6
F46F:
    LDA #$20
    STA $02FB
    JSR $F1CA
F477:
    JMP $F88E

F47A:
    JSR $F411
    LDA $55
    CMP $52
    BNE $F48B
    JSR $F665
    JSR $F758
    BCS $F492
F48B:
    LDA $63
    JSR $F75D
    BCC $F47A
F492:
    JMP $F88E

F495:
    LDA $63
    JMP $F73E

F49A:
    LDA $63
    JMP $F74A

F49F:
    JSR $F94C
    JSR $F18F
    STA $7D
    LDA #$00
    STA $02BB
F4AC:
    JSR $F1E9
    LDA $63
    PHA
    JSR $F612
    PLA
    CMP $63
    BCS $F4C6
    LDA $7D
    PHA
    JSR $F18F
    STA $7D
    PLA
    JMP $F4AC

F4C6:
    JSR $F957
    DEC $02BB
    BMI $F4D2
    DEC $54
    BNE $F4C9
F4D2:
    JMP $F88E

F4D5:
    JSR $F94C
F4D8:
    JSR $F5AC
    LDA $64
    STA $68
    LDA $65
    STA $69
    LDA $63
    PHA
    JSR $F60A
    PLA
    CMP $63
    BCS $F4FE
    LDA $54
    CMP $02BF
    BCS $F4FE
    JSR $F18F
    LDY #$00
    STA ($68),Y
    BEQ $F4D8
F4FE:
    LDY #$00
    TYA
    STA ($68),Y
    JSR $F918
    JSR $F957
    JMP $F88E

F50C:
    SEC
    JSR $F7C2
    LDA $52
    STA $55
    JSR $F5AC
    JSR $F78E
    JSR $F7E2
    JMP $F88E

F520:
    JSR $F88E
    LDY $51
    STY $54
F527:
    LDY $54
F529:
    TYA
    SEC
    JSR $F75B
    PHP
    TYA
    CLC
    ADC #$78
    PLP
    JSR $F73C
    INY
    CPY #$18
    BNE $F529
    LDA $02B4
    ORA #$01
    STA $02B4
    LDA #$00
    STA $55
    JSR $F5AC
    JSR $F82A
    JSR $F758
    BCC $F527
    JMP $F41B

F556:
    LDY #$20
    JSR $F983
    DEY
    BPL $F558
    RTS

F55F:
    JSR $F440
    JMP $F3E6

F565:
    LDA #$02
    BNE $F57A

F569:
    LDY $026E
    BEQ $F570
    ORA #$20

F570:
    LDY $4C
    BMI $F59F
    LDY #$00
    STA ($64),Y
    LDA #$01

F57A:
    STA $029E
    LDA $4C
    BMI $F59F
    LDA $64
    SEC
    SBC $029E
    STA $64
    BCS $F58D
    DEC $65
F58D:
    LDA $0F
    CMP $65
    BCC $F59F
    BNE $F59B
    LDA $0E
    CMP $64
    BCC $F59F
F59B:
    LDA #$93
    STA $4C
F59F:
    RTS

F5A0:
    LDA #$02
    JSR $F570
    LDA #$A2
    JSR $F570
    DEX
    RTS

F5AC:
    LDX #$01
    STX $66
    DEX
    STX $65
    LDA $54
    ASL A
    ROL $65
    ASL A
    ROL $65
    ADC $54
    STA $64
    BCC $F5C3
    INC $65
F5C3:
    LDY $57
    LDX $EE6D,Y
    ASL $64
    ROL $65
    DEX
    BNE $F5C8
    LDA $56
    LSR A
    LDA $55
    LDX $EE9D,Y
    BEQ $F5DF
    ROR A
    ASL $66
    DEX
    BNE $F5D9
F5DF:
    ADC $64
    BCC $F5E5
    INC $65
F5E5:
    CLC
    ADC $58
    STA $64
    STA $5E
    LDA $65
    ADC $59
    STA $65
    STA $5F
    LDX $EE9D,Y
    LDA $FB04,X
    AND $55
    ADC $66
    TAY
    LDA $EEAC,Y
    STA $02A0
    STA $6F
    LDY #$00
F609:
    RTS

F60A:
    LDA #$00
    BEQ $F610
    LDA #$9B
F610:
    STA $7D
    INC $63
    INC $55
    BNE $F61A
    INC $56
F61A:
    LDA $55
    LDX $57
    CMP $EE7D,X
    BEQ $F62D
    CPX #$00
    BNE $F609
    CMP $53
    BEQ $F609
    BCC $F609
F62D:
    CPX #$08
    BNE $F635
    LDA $56
    BEQ $F609
F635:
    LDA $57
    BNE $F665
    LDA $63
    CMP #$51
    BCC $F649
    LDA $7D
    BEQ $F665
    JSR $F661
    JMP $F6AB
F649:
    JSR $F665
    LDA $54
    CLC
    ADC #$78
    JSR $F75D
    BCC $F65E
    LDA $7D
    BEQ $F65E
    CLC
    JSR $F50D
F65E:
    JMP $F88E

F661:
    LDA #$9B
    STA $7D
F665:
    JSR $F997
    LDA #$00
    STA $56
    INC $54
    LDX $57
    LDY #$18
    BIT $7B
    BPL $F67B
    LDY #$04
    TYA
    BNE $F67E
F67B:
    LDA $EE8D,X
F67E:
    CMP $54
    BNE $F6AB
    STY $029D
    TXA
    BNE $F6AB
    LDA $7D
    BEQ $F6AB
    CMP #$9B
    BEQ $F691
    CLC
F691:
    JSR $F7F7
    INC $02BB
    DEC $6C
    BPL $F69D
    INC $6C
F69D:
    DEC $029D
    LDA $02B2
    SEC
    BPL $F691
    LDA $029D
    STA $54
F6AB:
    JMP $F88E

F6AE:
    SEC
    LDA $70,X
    SBC $74
    STA $70,X
    LDA $71,X
    SBC $75
    STA $71,X
    RTS

F6BC:
    LDA $02BF
    CMP #$04
    BEQ $F6CA
    LDA $57
    BEQ $F6CA
    JSR $EF94
F6CA:
    LDA #$27
    CMP $53
    BCS $F6D2
    STA $53
F6D2:
    LDX $57
    LDA $EE8D,X
    CMP $54
    BCC $F705
    BEQ $F705
    CPX #$08
    BNE $F6EB
    LDA $56
    BEQ $F6F8
    CMP #$01
    BNE $F705
    BEQ $F6EF
F6EB:
    LDA $56
    BNE $F705
F6EF:
    LDA $EE7D,X
    CMP $55
    BCC $F705
    BEQ $F705
F6F8:
    LDA #$01
    STA $4C
    LDA #$80
    LDX $11
    STA $11
    BEQ $F70A
    RTS
F705:
    JSR $F440
    LDA #$8D
F70A:
    STA $4C
    PLA
    PLA
    LDA $7B
    BPL $F715
    JMP $F962
F715:
    JMP $F21E

F718:
    LDY #$00
    LDA $5F
    BEQ $F722
    LDA $5D
    STA ($5E),Y
F722:
    RTS

F723:
    PHA
    AND #$07
    TAX
    LDA $EEB4,X
    STA $6E
    PLA
    LSR A
    LSR A
    LSR A
    TAX
    RTS

F732:
    ROL $02B4
    ROL $02B3
    ROL $02B2
    RTS

F73C:
    BCC $F74A
    JSR $F723
    LDA $02A3,X
    ORA $6E
    STA $02A3,X
    RTS
F74A:
    JSR $F723
    LDA $6E
    EOR #$FF
    AND $02A3,X
    STA $02A3,X
    RTS

F758:
    LDA $54
F75A:
    CLC
    ADC #$78
F75D:
    JSR $F723
    CLC
    LDA $02A3,X
    AND $6E
    BEQ $F769
    SEC
F769:
    RTS

F76A:
    LDA $02FA
    LDY $57
    CPY #$0E
    BCS $F78A
    CPY #$0C
    BCS $F77B
    CPY #$03
    BCS $F78A
F77B:
    ROL A
    ROL A
    ROL A
    ROL A
    AND #$03
    TAX
    LDA $02FA
    AND #$9F
    ORA $FB4D,X
F78A:
    STA $02FB
    RTS

F78E:
    LDX $6A
    DEX
    STX $69
    STX $67
    LDA #$B0
    STA $68
    LDA #$D8
    STA $66
    LDX $54
F79F:
    INX
    CPX $02BF
    BEQ $F78D
    LDY #$27
F7A7:
    LDA ($68),Y
    STA ($66),Y
    DEY
    BPL $F7A7
    SEC
    LDA $68
    STA $66
    SBC #$28
    STA $68
    LDA $69
    STA $67
    SBC #$00
    STA $69
    JMP $F79F

F7C2:
    PHP
    LDY #$16
F7C5:
    TYA
    JSR $F75A
    PHP
    TYA
    CLC
    ADC #$79
    PLP
    JSR $F73C
    DEY
    BMI $F7D9
    CPY $54
    BCS $F7C5
F7D9:
    LDA $54
    CLC
    ADC #$78
    PLP
    JMP $F73C

F7E2:
    LDA $52
    STA $55
    JSR $F5AC
    SEC
    LDA $53
    SBC $52
    TAY
    LDA #$00
    STA ($64),Y
    DEY
    BPL $F7F1
    RTS

F7F7:
    JSR $F732
    LDA $026E
    BEQ $F827
F7FF:
    LDA $026C
    BNE $F7FF
    LDA #$08
    STA $026C
F809:
    LDA $026C
    CMP #$01
    BNE $F809
F810:
    LDA $D40B
    CMP #$40
    BCS $F810
    LDX #$0D
    LDA $02BF
    CMP #$04
    BNE $F822
    LDX #$70
F822:
    CPX $D40B
    BCS $F822
F827:
    JSR $F9A6
    LDA $64
    LDX $65
    INX
    CPX $6A
    BEQ $F839
    SEC
    SBC #$10
    JMP $F82E
F839:
    ADC #$27
    BNE $F847
    LDX $65
    INX
    CPX $6A
    BEQ $F87C
    CLC
    ADC #$10
F847:
    TAY
    STA $7E
    SEC
    LDA $64
    SBC $7E
    STA $64
    BCS $F855
    DEC $65
F855:
    LDA $64
    CLC
    ADC #$28
    STA $7E
    LDA $65
    ADC #$00
    STA $7F
    LDA ($7E),Y
    STA ($64),Y
    INY
    BNE $F862
    LDY #$10
    LDA $64
    CMP #$D8
    BEQ $F87C
    CLC
    ADC #$F0
    STA $64
    BCC $F855
    INC $65
    BNE $F855
F87C:
    LDX $6A
    DEX
    STX $7F
    LDX #$D8
    STX $7E
    LDA #$00
    LDY #$27
    STA ($7E),Y
    DEY
    BPL $F889

F88E:
    LDA #$00
    STA $63
    LDA $54
    STA $51
F896:
    LDA $51
    JSR $F75A
    BCS $F8A9
    LDA $63
    ADC #$28
    STA $63
    DEC $51
    JMP $F896
F8A9:
    CLC
    LDA $63
    ADC $55
    STA $63
    RTS

F8B1:
    JSR $F94C
    LDA $63
    PHA
    LDA $6C
    STA $54
    LDA $6D
    STA $55
    LDA #$01
    STA $6B
    LDX #$17
    LDA $7B
    BPL $F8CB
    LDX #$03
F8CB:
    CPX $54
    BNE $F8DA
    LDA $55
    CMP $53
    BNE $F8DA
    INC $6B
    JMP $F8EA
F8DA:
    JSR $F60A
    INC $6B
    LDA $63
    CMP $52
    BNE $F8C3
    DEC $54
    JSR $F400
F8EA:
    JSR $F18F
    BNE $F906
    DEC $6B
    LDA $63
    CMP $52
    BEQ $F906
    JSR $F400
    LDA $55
    CMP $53
    BNE $F902
    DEC $54
F902:
    LDA $6B
    BNE $F8EA
F906:
    PLA
    STA $63
    JMP $F957

F90C:
    JSR $F88E
    LDA $51
    STA $6C
    LDA $52
    STA $6D
    RTS

F918:
    LDA $63
    CMP $52
    BNE $F920
    DEC $54
F920:
    JSR $F88E

F923:
    LDA $63
    CMP $52
    BEQ $F917
    JSR $F5AC
    LDA $53
    SEC
    SBC $52
    TAY
    LDA ($64),Y

F93C:
    LDX #$2D
F93E:
    LDA $FB0D,X
    CMP $02FB
    BEQ $F94B
    DEX
    DEX
    DEX
    BPL $F93E
F94B:
    RTS

F94C:
    LDX #$02
F94E:
    LDA $54,X
    STA $02B8,X
    DEX
    BPL $F94E
    RTS

F957:
    LDX #$02
F959:
    LDA $02B8,X
    STA $54,X
    DEX
    BPL $F959
    RTS

F962:
    LDA $02BF
    CMP #$18
    BEQ $F980
    LDX #$0B
F96B:
    LDA $54,X
    PHA
    LDA $0290,X
    STA $54,X
    PLA
    STA $0290,X
    DEX
    BPL $F96B
    LDA $7B
    EOR #$FF
    STA $7B
F980:
    JMP $F21E

F983:
    LDX #$7E
F985:
    PHA
    STX $D01F
    LDA $D40B
F98C:
    CMP $D40B
    BEQ $F98C
    DEX
    DEX
    BPL $F986
    PLA
    RTS

F997:
    LDA #$00
    LDX $7B
    BNE $F9A1
    LDX $57
    BNE $F9A3
F9A1:
    LDA $52
F9A3:
    STA $55
    RTS

F9A6:
    LDA $58
    STA $64
    LDA $59
    STA $65
    RTS

