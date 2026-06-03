.ORG $C535

RuntimeSetup:
    DEC $11
    LDA #$92
    STA $0236
    LDA #$C0
    STA $0237
    LDA $06
    STA $02E4
    STA $02E6
    LDA #$00
    STA $02E5
    LDA #$00
    STA $02E7
    LDA #$07
    STA $02E8
    JSR $E40C
    JSR $E41C
    JSR $E42C
    JSR $E43C
    JSR $E44C
    JSR $E46E
    JSR $E465
    JSR $E46B
    JSR $E450
    LDA #$6E
    STA $0238
    LDA #$C9
    STA $0239
    JSR $E49B
    LDA $D01F
    AND #$01
    EOR #$01
    STA $03E9
    RTS

BootMenuEntry:
    LDA $08
    BEQ BootMenuInit
    LDA $09
    AND #$01
    BEQ BootMenuAbort
    JMP $C63B

BootMenuInit:
    LDA #$01
    STA $0301
    LDA #$53
    STA $0302
    JSR $E453
    BMI BootMenuAbort
    LDA #$00
    STA $030B

BootMenuAbort:
    JMP $C63B

