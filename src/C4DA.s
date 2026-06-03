.ORG $C4DA

ResetDisplayTail:
    LDA #$00
    TAX
    STA $D303
    STA $D000,X
    STA $D400,X
    STA $D200,X
    CPX #$01
    BEQ ResetDisplayNext
    STA $D300,X

ResetDisplayNext:
    INX
    BNE ResetDisplayTail
    LDA #$3C
    STA $D303
    LDA #$FF
    STA $D301
    LDA #$38
    STA $D302
    STA $D303
    LDA #$00
    STA $D300
    LDA #$FF
    STA $D301
    LDA #$3C
    STA $D302
    STA $D303
    LDA $D301
    LDA $D300
    LDA #$22
    STA $D20F
    LDA #$A0
    STA $D205
    STA $D207
    LDA #$28
    STA $D208
    LDA #$FF
    STA $D20D
    RTS

; -----------------------------------------------------------------------------
; Runtime setup helper
; -----------------------------------------------------------------------------

