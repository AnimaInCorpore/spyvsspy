.ORG $FFA9

FFA9: ; GETCKS
    LDY #$00
FFAB:
    LDA $FFD7,X
    STA $9E,Y
    INX
    INY
    CPY #$04
    BNE FFAB
    LDY #$00
FFB9:
    CLC
    LDA ($9E),Y
    ADC $8B
    STA $8B
    BCC FFC4
    INC $8C
FFC4:
    INC $9E
    BNE FFCA
    INC $9F
FFCA:
    LDA $9E
    CMP $A0
    BNE FFB9
    LDA $9F
    CMP $A1
    BNE FFB9
    RTS

