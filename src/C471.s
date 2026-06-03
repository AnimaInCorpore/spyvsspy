.ORG $C471

LoaderBootEntry:
    LDA $D013
    ROR A
    BCC LoaderBootSkipCheck
    LDA $BFFC
    BNE LoaderBootSkipCheck
    LDA $BFFD
    BPL LoaderBootSkipCheck
    JMP ($BFFE)

LoaderBootSkipCheck:
    JSR $C4DA
    LDA $D301
    ORA #$02
    STA $D301
    LDA $08
    BEQ LoaderOptionClear
    LDA $03F8
    BNE LoaderOptionOnStart
    BEQ LoaderOptionClear

LoaderOptionClear:
    LDA $D01F
    AND #$04
    BEQ LoaderOptionOnStart
    LDA $D301
    AND #$FD
    STA $D301

LoaderOptionOnStart:
    LDA #$00
    TAY
    STA $05
    LDA #$28
    STA $06

LoaderProbeLoop:
    LDA ($05),Y
    EOR #$FF
    STA ($05),Y
    CMP ($05),Y
    BNE LoaderProbeDone
    EOR #$FF
    STA ($05),Y
    CMP ($05),Y
    BNE LoaderProbeDone
    INC $06
    BNE LoaderProbeLoop

LoaderProbeDone:
    RTS

LoaderChecksumStart:
    LDA #$00
    TAX
    CLC

LoaderChecksumLoop:
    ADC $BFF0,X
    INX
    BNE LoaderChecksumLoop
    CMP $03EB
    STA $03EB
    RTS

