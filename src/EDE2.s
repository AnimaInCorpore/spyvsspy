.ORG $EDE2

VbiInstallTail:
    LDA #$11
    STA $0226
    LDA #$EC
    STA $0227
    LDA #$01
    SEI
    JSR $E45C
    LDA #$01
    STA $0317
    CLI
    RTS
    LDA #$01
    SEI
    JSR $E45C
    LDA #$01
    STA $0317
    CLI
    RTS

; -----------------------------------------------------------------------------
; Upper-bank gameplay/runtime entry
; -----------------------------------------------------------------------------

