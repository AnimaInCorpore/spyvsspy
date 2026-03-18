.ORG $FE95

FE95:
    ASL $0A19,X
    PHP
    LDA #$1E
    STA $0314
    RTS
    NOP
    .BYTE $02
    CPY #$03
    LDA #$04
    STA $02DF
    LDX $FE9F
    LDY $FEA0
    LDA #$53
    STA $0302
    STA $030A
    JSR $FF14
    JSR $E459
    BMI $FEC1
    JSR $FF44
    RTS
    JSR $FEA3
    LDA #$00
    STA $02DE
    RTS

FECB:
    PHA
    LDA $0341,X
    STA $21
    JSR $FF4B
    LDX $02DE
    PLA
    STA $03C0,X
    INX
    CPX $02DF
    BEQ $FEF6
    STX $02DE
    CMP #$9B
    BEQ $FEEB
    LDY #$01
    RTS

FEEB:
    LDA #$20
    STA $03C0,X
    INX
    CPX $02DF
    BNE $FEED

FEF6:
    LDA #$00
    STA $02DE
    LDX $FEA1
    LDY $FEA2
    JSR $FF14
    JMP $E459

FF07:
    JSR $FF4B
    LDA #$9B
    LDX $02DE
    BNE $FEED
    LDY #$01
    RTS

FF14:
    STX $0304
    STY $0305
    LDA #$40
    STA $0300
    LDA $21
    STA $0301
    LDA #$80
    LDX $0302
    CPX #$53
    BNE $FF2F
    LDA #$40
FF2F:
    STA $0303
    LDA $02DF
    STA $0308
    LDA #$00
    STA $0309
    LDA $0314
    STA $0306
    RTS

FF44:
    LDA $02EC
    STA $0314
    RTS

FF4B:
    LDY #$57
    LDA $2B
    CMP #$4E
    BNE $FF57
    LDX #$28
    BNE $FF65
FF57:
    CMP #$44
    BNE $FF5F
    LDX #$14
    BNE $FF65
FF5F:
    CMP #$53
    BNE $FF6F
    LDX #$1D
FF65:
    STX $02DF
    STY $0302
    STA $030A
    RTS

FF6F:
    LDA #$4E
    BNE $FF4F

