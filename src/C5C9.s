.ORG $C5C9

MenuContinueCopy:
    LDX #$03

MenuCopyShadow:
    LDA $0400,X
    STA $0240,X
    DEX
    BPL MenuCopyShadow
    LDA $0242
    STA $04
    LDA $0243
    STA $05
    LDA $0404
    STA $0C
    LDA $0405
    STA $0D
    LDY #$7F

MenuCopyLoop:
    LDA $0400,Y
    STA ($04),Y
    DEY
    BPL MenuCopyLoop
    CLC
    LDA $04
    ADC #$80
    STA $04
    LDA $05
    ADC #$00
    STA $05
    DEC $0241
    BEQ MenuCopyDone
    INC $030A
    JSR $C659
    BPL MenuCopyLoop
    JSR $C63E
    LDA $03EA
    BNE MenuCopyAbort
    BEQ MenuCopyResume

MenuCopyDone:
    LDA $03EA
    BEQ MenuInitPath
    JSR $C659

MenuInitPath:
    JSR $C629
    BCS MenuCopyAbort
    JSR $C63B
    INC $09
    RTS

MenuCopyResume:
    LDA $03EA
    BNE MenuCopyAbort
    BEQ MenuContinuePath

MenuCopyAbort:
    RTS

MenuContinuePath:
    LDA $03EA
    BEQ MenuContinueGo
    JSR $C659

MenuContinueGo:
    JSR $C629
    BCS MenuCopyAbort
    JSR $C63B
    INC $09
    RTS

MenuFinalize:
    CLC
    LDA $0242
    ADC #$06
    STA $04
    LDA $0243
    ADC #$00
    STA $05
    JMP ($0004)

MenuAbortJump:
    JMP ($000C)

MenuSaveState:
    LDX #$3D
    LDY #$C4
    TXA
    LDX #$00
    STA $0344,X
    TYA
    STA $0345,X
    LDA #$09
    STA $0342,X
    LDA #$FF
    STA $0348,X
    JMP $E456

MenuCheckState:
    LDA $03EA
    BEQ MenuCheckDefault
    JMP $E47A

MenuCheckDefault:
    LDA #$52
    STA $0302
    LDA #$01
    STA $0301
    JMP $E453

MenuCheckBank:
    LDA $08
    BEQ MenuCheckStart
    LDA $09
    AND #$02
    BEQ MenuCheckReset
    JMP $C6A0

MenuCheckStart:
    LDA $03E9
    BEQ MenuCheckReset
    LDA #$80
    STA $3E
    INC $03EA
    JSR $E47D
    JSR $C5BB
    LDA #$00
    STA $03EA
    STA $03E9
    ASL $09
    LDA $0C
    STA $02
    LDA $0D
    STA $03
    RTS

MenuCheckReset:
    JMP ($0002)

MenuSetMode:
    LDA #$A0
    STA $0246
    LDA #$80
    STA $02D5
    LDA #$00
    STA $02D6
    RTS

MenuModeOne:
    LDA #$31
    STA $0300
    LDA $0246
    LDX $0302
    CPX #$21
    BEQ MenuModeOneDone
    LDA #$07

MenuModeOneDone:
    STA $0306
    LDX #$40
    LDA $0302
    CMP #$50
    BEQ MenuModeOneAlt
    CMP #$57
    BNE MenuModeOneSkip

MenuModeOneAlt:
    LDX #$80

MenuModeOneSkip:
    CMP #$53
    BNE MenuModeOneTail
    LDA #$EA
    STA $0304
    LDA #$02
    STA $0305
    LDY #$04
    LDA #$00
    BEQ MenuModeOneStore

MenuModeOneTail:
    LDY $02D5
    LDA $02D6

MenuModeOneStore:
    STX $0303
    STY $0308
    STA $0309
    JSR $E459
    BPL MenuModeOneExit
    RTS

MenuModeOneExit:
    LDA $0302
    CMP #$53
    BNE MenuModeOneName
    JSR $C73A
    LDY #$02
    LDA ($15),Y
    STA $0246

MenuModeOneName:
    LDA $0302
    CMP #$21
    BNE MenuModeOnePlayer
    JSR $C73A
    LDY #$FE
    INY
    INY
    LDA ($15),Y
    CMP #$FF
    BNE MenuModeOneName
    INY
    LDA ($15),Y
    INY
    CMP #$FF
    BNE MenuModeOneName
    DEY
    DEY
    STY $0308
    LDA #$00
    STA $0309

MenuModeOnePlayer:
    LDY $0303
    RTS

MenuModeOnePtr:
    LDA $0304
    STA $15
    LDA $0305
    STA $16
    RTS

; Remaining code blocks in the $C5xx-$FFD6 runtime chain are still pending.

; -----------------------------------------------------------------------------
; Lower-bank main/runtime chain
; -----------------------------------------------------------------------------

