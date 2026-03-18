.ORG $C90C

TitleRuntimeEntry:
    LDA #$01
    STA $0248
    LDA $0248
    STA $D1FF
    LDA $D803
    CMP #$80
    BNE TitleRuntimeExit
    LDA $D80B
    CMP #$91
    BNE TitleRuntimeExit
    JSR $D819
TitleRuntimeExit:
    ASL $0248
    BNE TitleRuntimeEntryContinue
    LDA #$00
    STA $D1FF
    RTS

TitleRuntimeEntryContinue:
    RTS

