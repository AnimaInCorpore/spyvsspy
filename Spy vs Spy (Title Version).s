; Spy vs Spy (Title Version)
; Partial mnemonic-first disassembly scaffold.
; Recovered bootstrap/runtime fragments are represented as code;
; opaque tables remain as data until the surrounding routines are finished.
;
; jsA8E boot note:
; this XEX needs PORTB=$FE at reset so OS/BASIC/FP ROMs are hidden while
; the C290+ segments are loaded into RAM.

; -----------------------------------------------------------------------------
; Bootstrap / loader path
; -----------------------------------------------------------------------------

.ORG $C290

BootEntry:
    SEI
    LDA $D013
    CMP $03FA
    BNE BootFail
    ROR A
    BCC BootCheckBasic
    JSR $C4C9
    BNE BootFail

BootCheckBasic:
    LDA $0244
    BNE BootFail
    LDA #$FF
    BNE BootStart

BootFail:
    SEI
    LDX #$8C

BootDelay:
    DEY
    BNE BootDelay
    DEX
    BNE BootDelay
    LDA $033D
    CMP #$5C
    BNE BootFailClear
    LDA $033E
    CMP #$93
    BNE BootFailClear
    LDA $033F
    CMP #$25
    BEQ BootEntry

BootFailClear:
    LDA #$00

BootStart:
    STA $08
    SEI
    CLD
    LDX #$FF
    TXS
    JSR $C471
    LDA #$01
    STA $01
    LDA $08
    BNE BootAltPath

    LDA #$00
    LDY #$08
    STA $04
    STA $05

BootProbeLoop:
    LDA #$FF
    STA ($04),Y
    CMP ($04),Y
    BEQ BootProbeZero
    LSR $01

BootProbeZero:
    LDA #$00
    STA ($04),Y
    CMP ($04),Y
    BEQ BootProbeNext
    LSR $01

BootProbeNext:
    INY
    BNE BootProbeLoop
    INC $05
    LDX $05
    CPX $06
    BNE BootProbeLoop
    LDA #$23
    STA $0A
    LDA #$F2
    STA $0B
    LDA $D301
    AND #$7F
    STA $D301
    JSR $FF73
    BCS BootProbeSkip
    JSR $FF92
    BCC BootProbeDone

BootProbeSkip:
    LSR $01

BootProbeDone:
    LDA $D301
    ORA #$80
    STA $D301
    LDA #$FF
    STA $0244
    BNE BootInitDisplay

BootAltPath:
    LDX #$00
    LDA $03EC
    BEQ BootClearState
    STX $000E
    STX $000F
    TXA

BootClearState:
    STA $0200,X
    CPX #$ED
    BCS BootClearHigh
    STA $0300,X

BootClearHigh:
    DEX
    BNE BootClearState
    LDX #$10

BootClearShadow:
    STA $00,X
    INX
    BPL BootClearShadow

BootInitDisplay:
    LDX #$00
    LDA $D301
    AND #$02
    BEQ BootSelectMode
    INX

BootSelectMode:
    STX $03F8
    LDA #$5C
    STA $033D
    LDA #$93
    STA $033E
    LDA #$25
    STA $033F
    LDA #$02
    STA $52
    LDA #$27
    STA $53
    LDA $D014
    AND #$0E
    BNE BootModeHi

    LDA #$05
    LDX #$01
    LDY #$28
    BNE BootModeStore

BootModeHi:
    LDA #$06
    LDX #$00
    LDY #$30

BootModeStore:
    STA $02DA
    STX $62
    STY $02D9
    LDX #$25

BootCopyLoop1:
    LDA $C44B,X
    STA $0200,X
    DEX
    BPL BootCopyLoop1

    LDX #$0E

BootCopyLoop2:
    LDA $C42E,X
    STA $031A,X
    DEX
    BPL BootCopyLoop2

    JSR $C535
    CLI
    LDA $01
    BNE BootContinue
    LDA $D301
    AND #$7F
    STA $D301
    LDA #$02
    STA $02F3
    LDA #$E0
    STA $02F4
    JMP $5003

BootContinue:
    LDX #$00
    STX $06
    LDX $02E4
    CPX #$B0
    BCS BootDisplayDone
    LDX $BFFC
    BNE BootDisplayDone
    INC $06
    JSR $C4C9
    JSR $C429

BootDisplayDone:
    LDA #$03
    LDX #$00
    STA $0342,X
    LDA #$48
    STA $0344,X
    LDA #$C4
    STA $0345,X
    LDA #$0C
    STA $034A,X
    JSR $E456
    BPL BootDelayExit
    JMP $C2AA

BootDelayExit:
    INX
    BNE BootDelayExit
    INY
    BPL BootDelayExit
    JSR $C66E
    LDA $06
    BEQ BootAfterDelay
    LDA $BFFD
    ROR A
    BCC BootAfterDelayCheck

BootAfterDelay:
    JSR $C58B
    JSR $E739

BootAfterDelayCheck:
    LDA #$00
    STA $0244
    LDA $06
    BEQ BootInitVbi
    LDA $BFFD
    AND #$04
    BEQ BootInitVbi
    JMP ($BFFA)

BootInitVbi:
    JMP ($000A)

    JMP ($BFFE)

    CLC
    RTS

; -----------------------------------------------------------------------------
; Local bootstrap tables
; -----------------------------------------------------------------------------

.ORG $C42E

BootTextAndVectors:
    .BYTE $50, $30, $E4, $43, $40, $E4, $45, $00, $E4, $53, $10, $E4, $4B, $20, $E4, $42
    .BYTE $4F, $4F, $54, $20, $45, $52, $52, $4F, $52, $9B, $45, $3A, $9B, $CE, $C0, $CD
    .BYTE $C0, $CD, $C0, $CD, $C0, $19, $FC, $2C, $EB, $AD, $EA, $EC, $EA, $CD, $C0, $CD
    .BYTE $C0, $CD, $C0, $30, $C0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $E2

; -----------------------------------------------------------------------------
; Reset / display tail
; -----------------------------------------------------------------------------

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

.ORG $E98D

LowerBankFrameEntry:
    LDA #$0D
    STA $029C
    LDA #$28
    STA $D204
    LDA #$00
    STA $D206
    CLC
    LDA $0300
    ADC $0301
    ADC #$FF
    STA $023A
    LDA $0302
    STA $023B
    LDA $030A
    STA $023C
    LDA $030B
    STA $023D
    CLC
    LDA #$3A
    STA $32
    ADC #$04
    STA $34
    LDA #$02
    STA $33
    STA $35
    LDA #$34
    STA $D303
    JSR $ECAF
    LDA $023F
    BNE LowerBankIdleTick
    TYA
    BNE LowerBankAdvanceTurn
LowerBankIdleTick:
    DEC $029C
    BPL LowerBankFrameEntry
    JMP $EA22
LowerBankAdvanceTurn:
    LDA $0303
    BPL LowerBankInputReady
    LDA #$0D
    STA $029C
    JSR $EB87
    JSR $ECAF
    BEQ $EA22
LowerBankInputReady:
    JSR $EC9A
    LDA #$00
    STA $023F
    JSR $ECC0
    BEQ LowerBankAfterMove
    BIT $0303
    BVS LowerBankActionPath
    LDA $023F
    BNE $EA22
    BEQ $EA2A
LowerBankActionPath:
    JSR $EB87
    JSR $EAFD
LowerBankAfterMove:
    LDA $023F
    BEQ LowerBankTurnCheck
    LDA $0319
    STA $30
LowerBankTurnCheck:
    LDA $30
    CMP #$01
    BEQ $EA2A
    DEC $02BD
    BMI $EA2A
    JMP $E98D

EA22:
    DEC $02BD
    BMI $EA2A
    JMP $E98D

EA2A:
    JSR $EC84
    LDA #$00
    STA $42
    LDY $30
    STY $0303
    RTS

EA37:
    LDA #$00
    STA $023F
    CLC
    LDA #$3E
    STA $32
    ADC #$01
    STA $34
    LDA #$02
    STA $33
    STA $35
    LDA #$FF
    STA $3C
    JSR $EAFD
    LDY #$FF
    LDA $30
    CMP #$01
    BNE EA73
    LDA $023E
    CMP #$41
    BEQ EA82
    CMP #$43
    BEQ EA82
    CMP #$45
    BNE EA6F
    LDA #$90
    STA $30
    BNE EA73
EA6F:
    LDA #$8B
    STA $30
EA73:
    LDA $30
    CMP #$8A
    BEQ EA80
    LDA #$FF
    STA $023F
    BNE EA82
EA80:
    LDY #$00
EA82:
    LDA $30
    STA $0319
    RTS

EA88:
    LDA #$01
    STA $30
    JSR $EC17
    LDY #$00
    STY $31
    STY $3B
    STY $3A
    LDA ($32),Y
    STA $D20D
    STA $31
    LDA $11
    BNE $EAA5
    JMP $EDC7
EAA5:
    LDA $3A
    BEQ $EA9E
    JSR $EC84
EAAC:
    RTS

EAAD:
    TYA
    PHA
    INC $32
    BNE $EAB5
    INC $33
EAB5:
    LDA $32
    CMP $34
    LDA $33
    SBC $35
    BCC $EADB
    LDA $3B
    BNE $EACE
    LDA $31
    STA $D20D
    LDA #$FF
    STA $3B
    BNE $EAD7
EACE:
    LDA $10
    ORA #$08
    STA $10
    STA $D20E
EAD7:
    PLA
    TAY
    PLA
    RTI
EADB:
    LDY #$00
    LDA ($32),Y
    STA $D20D
    CLC
    ADC $31
    ADC #$00
    STA $31
    JMP $EAD7
EAEC:
    LDA $3B
    BEQ $EAFB
    STA $3A
    LDA $10
    AND #$F7
    STA $10
    STA $D20E
EAFB:
    PLA
EAFC:
    RTI

EAFD:
    LDA #$00
EAFF:
    LDY $030F
    BNE $EB06
    STA $31
EB06:
    STA $38
    STA $39
    LDA #$01
    STA $30
    JSR $EC40
    LDA #$3C
    STA $D303
    LDA $11
    BNE $EB1D
    JMP $EDC7
EB1D:
    LDA $0317
    BEQ $EB27
    LDA $39
    BEQ $EB16
    RTS
EB27:
    LDA #$8A
    STA $30
    RTS
EB2C:
    TYA
    PHA
    LDA $D20F
    STA $D20A
    BMI $EB3A
    LDY #$8C
    STY $30
EB3A:
    AND #$20
    BNE $EB42
    LDY #$8E
    STY $30
EB42:
    LDA $38
    BEQ $EB59
    LDA $D20D
    CMP $31
    BEQ $EB51
    LDY #$8F
    STY $30
EB51:
    LDA #$FF
    STA $39
    PLA
    TAY
    PLA
    RTI
EB59:
    LDA $D20D
    LDY #$00
    STA ($32),Y
    CLC
    ADC $31
    ADC #$00
    STA $31
    INC $32
    BNE $EB6D
    INC $33
EB6D:
    LDA $32
    CMP $34
    LDA $33
    SBC $35
    BCC $EB55
    LDA $3C
    BEQ $EB81
    LDA #$00
    STA $3C
    BEQ $EB51
EB81:
    LDA #$FF
    STA $38
    BNE $EB55

.ORG $ECAF

LowerBankSetupHelper:
    LDX #$01
ECB1:
    LDY #$FF
ECB3:
    DEY
    BNE $ECB3
    DEX
    BNE $ECB1
    JSR $EA88
    LDY #$02
    LDX #$00
    JSR $EDE2
    JSR $EA37
    TYA
    RTS

ECC8:
    STA $0310
    STY $0311
    JSR $ED2E
    STA $0310
    LDA $030C
    JSR $ED2E
    STA $030C
    LDA $0310
    SEC
    SBC $030C
    STA $0312
    LDA $0311
    SEC
    SBC $030D
    TAY
    LDX $62
ECF1:
    LDA #$00
    SEC
    SBC $EE19,X
    CLC
    ADC $EE19,X
    DEY
    BPL $ECF7
    CLC
    ADC $0312
    TAY
    LSR A
    LSR A
    LSR A
    ASL A
    SEC
    SBC #$16
    TAX
    TYA
    AND #$07
    TAY
    LDA #$F5
    CLC
    ADC #$0B
    DEY
    BPL $ED11
    LDY #$00
    SEC
    SBC #$07
    BPL $ED1F
    DEY
ED1F:
    CLC
    ADC $EDF9,X
    STA $02EE
    TYA
    ADC $EDFA,X
    STA $02EF
    RTS

ED2E:
    CMP #$7C
    BMI $ED36
    SEC
    SBC #$7C
    RTS
ED36:
    CLC
    LDX $62
    ADC $EE1B,X
    RTS

ED3D:
    LDA $11
    BNE $ED44
    JMP $EDC7
ED44:
    SEI
    LDA $0317
    BNE $ED4C
    BEQ $ED71
ED4C:
    LDA $D20F
    AND #$10
    BNE $ED3D
    STA $0316
    LDX $D40B
    LDY $14
    STX $030C
    STY $030D
    LDX #$01
    STX $0315
    LDY #$0A
    LDA $11
    BEQ $EDC7
    LDA $0317
    BNE $ED75
ED71:
    CLI
    JMP $EB27
ED75:
    LDA $D20F
    AND #$10
    CMP $0316
    BEQ $ED68
    STA $0316
    DEY
    BNE $ED68
    DEC $0315
    BMI $ED96
    LDA $D40B
    LDY $14
    JSR $ECC8
    LDY #$09
    BNE $ED68
ED96:
    LDA $02EE
    STA $D204
    LDA $02EF
    STA $D206
    LDA #$00
    STA $D20F
    LDA $0232
    STA $D20F
EDAD:
    LDA #$55
    STA ($32),Y
    INY
    STA ($32),Y
    LDA #$AA
    STA $31
    CLC
    LDA $32
    ADC #$02
    STA $32
    LDA $33
    ADC #$00
    STA $33
    CLI
    RTS

EDC7:
    JSR $EC84
    LDA #$3C
    STA $D302
    LDA #$3C
    STA $D303
    LDA #$80
    STA $30
    LDX $0318
    TXS
    DEC $11
    CLI
    JMP $EA2A

; -----------------------------------------------------------------------------
; VBI runtime tail
; -----------------------------------------------------------------------------

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

.ORG $EF00

UpperBankInit:
    LDX $10E7,Y
    SLO ($A0,X)
    DOP #$60
    LDA #$7F
    STA $20
    LDA #$25
    STA $26
    LDA #$EF
    STA $27
    LDA $02EC
    LDX $002E
    STA $034D,X
    LDY #$00
    LDA ($24),Y
    STA $034C,X
    LDY #$01
    RTS

EF26:
    PHA
    TXA
    PHA
    AND #$0F
    BNE $EF3D
    CPX #$80
    BPL $EF3D
    LDA $02E9
    BNE $EF41
EF36:
    LDY #$82
    PLA
    PLA
    CPY #$00
    RTS
EF3D:
    LDY #$86
    BMI $EF38
EF41:
    STX $002E
    LDY #$00
    LDA $0340,X
    STA $0020,Y
    INX
    INY
    CPY #$0C
    BMI $EF46
    JSR $CA29
    BMI $EF38
    PLA
    TAX
    PLA
    TAY
    LDA $27
    PHA
    LDA $26
    PHA
    TYA
    LDY #$92
    RTS
EF65:
    BRK
    BRK
    BRK
    BRK
    BRK
    BRK
    JMP $FD05
    LDA #$FF
    STA $02FC
    LDA $02E4
    STA $6A
    LDA #$40
    STA $02BE
    LDA #$51
    STA $79
    LDA #$FB
    STA $7A
    LDA #$11
    STA $60
    LDA #$FC
    STA $61
    RTS

EF8E:
    LDA $2B
    AND #$0F
    BNE $EF9C
    LDA $2A
    AND #$0F
    STA $2A
    LDA #$00
EF9C:
    STA $57
    CMP #$10
    BCC $EFA7
    LDA #$91
    JMP $F154

EFA7:
    LDA #$E0
    STA $02F4
    LDA #$CC
    STA $026B
    LDA #$02
    STA $02F3
    STA $022F
    LDA #$01
    STA $4C
    LDA #$C0
    ORA $10
    STA $10
    STA $D20E
    LDA #$40
    STA $D40E
    BIT $026E
    BPL $EFDC
    LDA #$C4
    STA $0200
    LDA #$FC
    STA $0201
    LDA #$C0
EFDC:
    STA $D40E
    LDA #$00
    STA $0293
    STA $64
    STA $7B
    STA $02F0
    LDY #$0E
    LDA #$01
    STA $02A3,Y
    DEY
    BPL $EFEF
    LDX #$04
    LDA $FB08,X
    STA $02C4,X
    DEX
    BPL $EFF7
    LDY $6A
    DEY
    STY $0295
    LDA #$60
    STA $0294
    LDX $57
    LDA $EE4D,X
    STA $51
    LDA $6A
    STA $65
    LDY $EE1D,X
    LDA #$28
    JSR $F57A
    DEY
    BNE $F019
    LDA $026F
    AND #$3F
    STA $67
    TAY
    CPX #$08
    BCC $F04C
    CPX #$0F
    BEQ $F03E
    CPX #$0C
    BCS $F04C
    TXA
    ROR A
    ROR A
    ROR A
    AND #$C0
    ORA $67
    TAY
F03E:
    LDA #$10
    JSR $F57A
    CPX #$0B
    BNE $F04C
    LDA #$06
    STA $02C8

F04C:
    STY $026F
    LDA $64
    STA $58
    LDA $65
    STA $59
    LDA $D40B
    CMP #$7A
    BNE $F057
    JSR $F578
    LDA $EE5D,X
    BEQ $F06C
    LDA #$FF
    STA $64
    DEC $65
F06C:
    JSR $F565
    LDA $64
    STA $68
    LDA $65
    STA $69
    LDA #$41
    JSR $F570
    STX $66
    LDA #$18
    STA $02BF
    LDA $57
    CMP #$0C
    BCS $F08D
    CMP #$09
    BCS $F0C6
F08D:
    LDA $2A
    AND #$10
    BEQ $F0C6
    LDA #$04
    STA $02BF
    LDX #$02
    LDA $026E
    BEQ $F0A2
    JSR $F5A0
F0A2:
    LDA #$02
    JSR $F569
    DEX
    BPL $F0A2
    LDY $6A
    DEY
    TYA
    JSR $F570
    LDA #$60
    JSR $F570
    LDA #$42
    JSR $F569
    CLC
    LDA #$10
    ADC $66
    TAY
    LDX $EE2D,Y
    BNE $F0DB
F0C6:
    LDY $66
    LDX $EE2D,Y
    LDA $57
    BNE $F0DB
    LDA $026E
    BEQ $F0DB
    JSR $F5A0
    LDA #$22
    STA $51
F0DB:
    LDA $51
    JSR $F570
    DEX
    BNE $F0DB
    LDA $57
    CMP #$08
    BCC $F10F
    CMP #$0F
    BEQ $F0F1
    CMP #$0C
    BCS $F10F
F0F1:
    LDX #$5D
    LDA $6A
    SEC
    SBC #$10
    JSR $F570
    LDA #$00
    JSR $F570
    LDA $51
    ORA #$40
    JSR $F570
    LDA $51
    JSR $F570
    DEX
    BNE $F107
F10F:
    LDA $59
    JSR $F570
    LDA $58
    JSR $F570
    LDA $51
    ORA #$40
    JSR $F570
    LDA #$70
    JSR $F570
    LDA #$70
    JSR $F570
    LDA $64
    STA $0230
    LDA $65
    STA $0231
    LDA #$70
    JSR $F570
    LDA $64
    STA $02E5
    LDA $65
    STA $02E6
    LDY #$01
    LDA $0230
    STA ($68),Y
    INY
    LDA $0231
    STA ($68),Y
    LDA $4C
    BPL $F164
    STA $03EC
    JSR $EF94
    LDA $03EC
    LDY #$00
    STY $03EC
    TAY
    RTS

F164:
    LDA $2A
    AND #$20
    BNE $F175
    JSR $F420
    STA $0290
    LDA $52
    STA $0291
F175:
    LDA #$22
    ORA $022F
    STA $022F
    JMP $F20B

F180:
    JSR $F6CA
    JSR $F18F
    JSR $F76A
    JSR $F60A
    JMP $F21E

F18F:
    JSR $F5AC
    LDA ($64),Y
    AND $02A0
    LSR $6F
    BCS $F19E
    LSR A
    BPL $F197
F19E:
    STA $02FA
    CMP #$00
    RTS

F1A4:
    STA $02FB
    CMP #$7D
    BNE $F1B1
    JSR $F420
    JMP $F20B

F1B1:
    JSR $F6CA
    LDA $02FB
    CMP #$9B
    BNE $F1C1
    JSR $F661
    JMP $F20B

F1C1:
    JSR $F1CA
    JSR $F60E
    JMP $F20B

F1CA:
    LDA $02FF
    BNE $F1CA
    LDX #$02
    LDA $54,X
    STA $5A,X
    DEX
    BPL $F1D1
    LDA $02FB
    TAY
    ROL A
    ROL A
    ROL A
    ROL A
    AND #$03
    TAX
    TYA
    AND #$9F
    ORA $FB49,X
    STA $02FA
    JSR $F5AC
    LDA $02FA
    LSR $6F
    BCS $F1FA
    ASL A
    JMP $F1F2

F1FA:
    AND $02A0
    STA $50
    LDA $02A0
    EOR #$FF
    AND ($64),Y
    ORA $50
    STA ($64),Y
    RTS

F20B:
    JSR $F18F
    STA $5D
    LDX $57
    BNE $F21E
    LDX $02F0
    BNE $F21E
    EOR #$80
    JSR $F1E9

F21E:
    LDY $4C
    JMP $F226

F223:
    JMP $C8FC

F226:
    LDA #$01
    STA $4C
    LDA $02FB
    RTS

F22E:
    BIT $026E
    BPL $F21E
    LDA #$40
    STA $D40E
    LDA #$00
    STA $026E
    LDA #$CE
    STA $0200
    LDA #$C0
    STA $0201
    JMP $EF94

F24A:
    JSR $F962
    JSR $F6BC
    LDA $6B
    BNE $F288
    LDA $54
    STA $6C
    LDA $55
    STA $6D
F25C:
    JSR $F2FD
    STY $4C
    LDA $02FB
    CMP #$9B
    BEQ $F27A
    JSR $F2BE
    JSR $F962
    LDA $63
    CMP #$71
    BNE $F277
    JSR $F556
F277:
    JMP $F25C

F27A:
    JSR $F718
    JSR $F8B1
    LDA $6C
    STA $54
    LDA $6D
    STA $55

F288:
    LDA $6B
    BEQ $F29D
    DEC $6B
    BEQ $F29D
    LDA $4C
    BMI $F28C
    JSR $F180
    STA $02FB
    JMP $F962

F29D:
    JSR $F661
    LDA #$9B
    STA $02FB
    JSR $F20B
    STY $4C
    JMP $F962

F2AD:
    JMP ($0064)

F2B0:
    STA $02FB
    JSR $F962
    JSR $F6BC
    LDA #$00
    STA $03E8
    JSR $F718
    JSR $F93C
    BEQ $F2CF
    ASL $02A2
    JSR $F1B4
    JMP $F962

F2CF:
    LDA $02FE
    ORA $02A2
    BNE $F2C6
    ASL $02A2
    INX
    LDA $03E8
    BEQ $F2E5
    TXA
    CLC
    ADC #$2D
    TAX
F2E5:
    LDA $FB0D,X
    STA $64
    LDA $FB0E,X
    STA $65
    JSR $F2AD
    JSR $F20B
    JMP $F962

F2F8:
    LDA #$FF
    STA $02FC

F2FD:
    LDA #$00
    STA $03E8
    LDA $2A
    LSR A
    BCS $F376
    LDA #$80
    LDX $11
    BEQ $F372
    LDA $02FC
    CMP #$FF
    BEQ $F2FD
    STA $7C
    LDX #$FF
    STX $02FC
    LDX $02DB
    BNE $F323
    JSR $F983
F323:
    TAY
    CPY #$C0
    BCS $F2F8
    LDA ($79),Y
    STA $02FB
    TAX
    BMI $F333
    JMP $F3B4
    CMP #$80
    BEQ $F2F8
    CMP #$81
    BNE $F345
    LDA $02B6
    EOR #$80
    STA $02B6
    BCS $F2F8
    CMP #$82
    BNE $F355
    LDA $02BE
    BEQ $F359
    LDA #$00
    STA $02BE
    BEQ $F2F8
    CMP #$83
    BNE $F360
    LDA #$40
    STA $02BE
    BNE $F2F8
    CMP #$84
    BNE $F36C
    LDA #$80
    STA $02BE
    JMP $F2F8
    CMP #$85
    BNE $F37B
    LDA #$88
    STA $4C
    STA $11
    LDA #$9B
    JMP $F3DA

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

.ORG $F9AF

F9AF:
    LDX #$00
    LDA $22
    CMP #$11
    BEQ $F9BF
    CMP #$12
    BEQ $F9BE
    LDY #$84
    RTS
F9BE:
    INX
F9BF:
    STX $02B7
    LDA $54
    STA $02F5
    LDA $55
    STA $02F6
    LDA $56
    STA $02F7
    LDA #$01
    STA $02F8
    STA $02F9
    SEC
    LDA $02F5
    SBC $5A
    STA $76
    BCS $F9F1
    LDA #$FF
    STA $02F8
    LDA $76
    EOR #$FF
    CLC
    ADC #$01
    STA $76
F9F1:
    SEC
    LDA $02F6
    SBC $5B
    STA $77
    LDA $02F7
    SBC $5C
    STA $78
    BCS $FA19
    LDA #$FF
    STA $02F9
    LDA $77
    EOR #$FF
    STA $77
    LDA $78
    EOR #$FF
    STA $78
    INC $77
    BNE $FA19
    INC $78
FA19:
    LDX #$02
    LDY #$00
    STY $73
    TYA
    STA $70,X
    LDA $5A,X
    STA $54,X
    DEX
    BPL $FA1F
    LDA $77
    INX
    TAY
    LDA $78
    STA $7F
    STA $75
    BNE $FA40
    LDA $77
    CMP $76
    BCS $FA40
    LDA $76
    LDX #$02
    TAY
FA40:
    TYA
    STA $7E
    STA $74
    PHA
    LDA $75
    LSR A
    PLA
    ROR A
    STA $70,X
    LDA $7E
    ORA $7F
    BNE $FA56
    JMP $FB01
FA56:
    CLC
    LDA $70
    ADC $76
    STA $70
    BCC $FA61
    INC $71
FA61:
    LDA $71
    CMP $75
    BCC $FA7C
    BNE $FA6F
    LDA $70
    CMP $74
    BCC $FA7C
FA6F:
    CLC
    LDA $54
    ADC $02F8
    STA $54
    LDX #$00
    JSR $F6AE
FA7C:
    CLC
    LDA $72
    ADC $77
    STA $72
    LDA $73
    ADC $78
    STA $73
    CMP $75
    BCC $FAB5
    BNE $FA95
    LDA $72
    CMP $74
    BCC $FAB5
FA95:
    BIT $02F9
    BPL $FAAA
    DEC $55
    LDA $55
    CMP #$FF
    BNE $FAB0
    LDA $56
    BEQ $FAB0
    DEC $56
    BPL $FAB0
FAAA:
    INC $55
    BNE $FAB0
    INC $56
FAB0:
    LDX #$02
    JSR $F6AE
FAB5:
    JSR $F6CA
    JSR $F1CA
    LDA $02B7
    BEQ $FAEF
    JSR $F94C
    LDA $02FB
    STA $02BC
    LDA $54
    PHA
    JSR $F612
    PLA
    STA $54
    JSR $F6CA
    JSR $F18F
    BNE $FAE6
    LDA $02FD
    STA $02FB
    JSR $F1CA
    JMP $FAC9
FAE6:
    LDA $02BC
    STA $02FB
    JSR $F957
FAEF:
    SEC
    LDA $7E
    SBC #$01
    STA $7E
    LDA $7F
    SBC #$00
    STA $7F
    BMI $FB01
    JMP $FA4D

FB01:
    JMP $F21E

; -----------------------------------------------------------------------------
; Upper-bank tables and lookup data
; -----------------------------------------------------------------------------

.ORG $FB04

FB04Table:
    .BYTE $00, $01, $03, $07, $28, $CA, $94, $46, $00, $1B, $E0, $F3, $1C, $E6, $F3, $1D
    .BYTE $F3, $F3, $1E, $00, $F4, $1F, $11, $F4, $7D, $20, $F4, $7E, $50, $F4, $7F, $7A
    .BYTE $F4, $9B, $61, $F6, $9C, $20, $F5, $9D, $0C, $F5, $9E, $9A, $F4, $9F, $95, $F4
    .BYTE $FD, $56, $F5, $FE, $D5, $F4, $FF, $9F, $F4, $1C, $40, $F4

.ORG $FB40

FB40Lookup:
    .BYTE $1D, $5F, $F5, $1E, $1B, $F4, $1F, $0A, $F4, $40, $00, $20, $60, $20, $40, $00
    .BYTE $60, $6C, $6A, $3B, $8A, $8B, $6B, $2B, $2A, $6F, $80, $70, $75, $9B, $69, $2D
    .BYTE $3D, $76, $80, $63, $8C, $8D, $62, $78, $7A, $34, $80, $33, $36, $1B, $35, $32
    .BYTE $31, $2C, $20, $2E, $6E, $80, $6D, $2F, $81, $72, $80, $65, $79, $7F, $74, $77
    .BYTE $71, $39, $80, $30, $37, $7E, $38, $3C, $3E, $66, $68, $64, $80, $82, $67, $73
    .BYTE $61, $4C, $4A, $3A, $8A, $8B, $4B, $5C, $5E, $4F, $80, $50, $55, $9B, $49, $5F
    .BYTE $7C, $56, $80, $43, $8C, $8D, $42, $58, $5A, $24, $80, $23, $26, $1B, $25, $22
    .BYTE $21, $5B, $20, $5D, $4E, $80, $4D, $3F, $81, $52, $80, $45, $59, $9F, $54, $57
    .BYTE $51, $28, $80, $29, $27, $9C, $40, $7D, $9D, $46, $48, $44, $80, $83, $47, $53
    .BYTE $41, $0C, $0A, $7B, $80, $80, $0B, $1E, $1F, $0F, $80, $10, $15, $9B, $09, $1C
    .BYTE $1D, $16, $80, $03, $89, $80, $02, $18, $1A, $80, $80, $85, $80, $1B, $80, $FD
    .BYTE $80, $00, $20, $60, $0E, $80, $0D, $80, $81, $12, $80, $05, $19, $9E, $14, $17

.ORG $FC00

FC00:
    ORA ($80),Y
    DOP #$80
    DOP #$FE
    DOP #$7D
    ISC $0806,X
    DOP $80
    STY $07
    SLO ($01),Y
    TOP $1E1D,X
    SLO $8F8E,X
    BCC $FBAA
    TXA
    PHA
    TYA
    PHA
    LDY $D301
    LDA $D209
    CMP $02F2
    BNE $FC2D
    LDX $02F1
    BNE $FC76
FC2D:
    LDX $026D
    CMP #$83
    BNE $FC47
    TXA
    EOR #$FF
    STA $026D
    BNE $FC41
    TYA
    ORA #$04
    BNE $FC44
FC41:
    TYA
    AND #$FB
FC44:
    TAY
    BCS $FC6D
FC47:
    TXA
    BNE $FC87
    LDA $D209
    TAX
    CMP #$9F
    BNE $FC5C
    LDA $02FF
    EOR #$FF
    STA $02FF
    BCS $FC6D
FC5C:
    AND #$3F
    CMP #$11
    BNE $FC90
    STX $02DC
    BEQ $FC6D
    STX $02FC
    STX $02F2
    LDA #$03
    STA $02F1
    LDA #$00
    STA $4D
    LDA $02D9
    STA $022B
    LDA $022F
    BNE $FC87
    LDA $02DD
    STA $022F
FC87:
    STY $D301
    PLA
    TAY
    PLA
    TAX
    PLA
    RTI

FC90:
    CPX #$84
    BEQ $FCB5
    CPX #$94
    BNE $FC67
    LDA $02F4
    LDX $026B
    STA $026B
    STX $02F4
    CPX #$CC
    BEQ $FCAE
    TYA
    ORA #$08
    TAY
    BNE $FC6D
FCAE:
    TYA
    AND #$F7
    TAY
    JMP $FC6D

FCB5:
    LDA $022F
    BEQ $FC87
    STA $02DD
    LDA #$00
    STA $022F
    BEQ $FC87
FCB9:
    PHA
    LDA $02C6
    EOR $004F
    AND $004E
    STA $D40A
    STA $D017
    PLA
    RTI

FCD6:
    BRK
    BRK
    JMP $F983
    LDA #$CC
    STA $02EE
    LDA #$05
    STA $02EF
    RTS

FCE6:
    LDA $2B
    STA $3E
    LDA $2A
    AND #$0C
    CMP #$04
    BEQ $FCF7
    CMP #$08
    BEQ $FD34
    RTS

FCF7:
    LDA #$00
    STA $0289
    STA $3F
    LDA #$01
    JSR $FDFC
    BMI $FD2E
    LDA #$34
    STA $D302
    LDX $62
    LDY $FE93,X
    LDA $FE91,X
    TAX
    LDA #$03
    STA $022A
    JSR $E45C
    LDA $022A
    BNE $FD1B
    LDA #$80
    STA $3D
    STA $028A
    JMP $FD77
FD2A:
    LDY #$80
    DEC $11
FD2E:
    LDA #$00
    STA $0289
    RTS

FD34:
    LDA #$80
    STA $0289
    LDA #$02
    JSR $FDFC
    BMI $FD2E
    LDA #$CC
    STA $D204
    LDA #$05
    STA $D206
    LDA #$60
    STA $0300
    JSR $E468
    LDA #$34
    STA $D302
    LDX $62
    LDY $FE8F,X
    LDA $FE8D,X
    TAX
    LDA #$03
    JSR $E45C
    LDA #$FF
    STA $022A
    LDA $11
    BEQ $FD2A
    LDA $022A
    BNE $FD6A
    LDA #$00
    STA $3D
FD77:
    LDY #$01
    RTS

FD7A:
    LDA $3F
    BMI $FDB1
    LDX $3D
    CPX $028A
    BEQ $FD8D
    LDA $0400,X
    INC $3D
    LDY #$01
    RTS
FD8D:
    LDA #$52
    JSR $FE3F
    TYA
    BMI $FD8C
    LDA #$00
    STA $3D
    LDX #$80
    LDA $03FF
    CMP #$FE
    BEQ $FDAF
    CMP #$FA
    BNE $FDA9
    LDX $047F
FDA9:
    STX $028A
    JMP $FD7A
FDAF:
    DEC $3F
FDB1:
    LDY #$88
    RTS

FDFC:
    STA $40
    LDA $14
    CLC
    LDX $62
    ADC $FE95,X
    TAX
    LDA #$FF
    STA $D01F
    LDA #$00
FE10:
    LDY #$F0
FE10Loop:
    DEY
    BNE FE10Loop
    STA $D01F
    LDY #$F0
FE18Loop:
    DEY
    BNE FE18Loop
    CPX $14
    BNE $FE07
    DEC $40
    BEQ $FE31
    TXA
    CLC
    LDX $62
    ADC $FE97,X
    TAX
    CPX $14
    BNE $FE2B
    BEQ $FDFE
FE31:
    JSR $FE36
    TYA
    RTS

FE36:
    LDA $E425
    PHA
    LDA $E424
    PHA
    RTS

FE3F:
    STA $0302
    LDA #$00
    STA $0309
    LDA #$83
    STA $0308
    LDA #$03
    STA $0305
    LDA #$FD
    STA $0304
    LDA #$60
    STA $0300
    LDA #$00
    STA $0301
    LDA #$23
    STA $0306
    LDA $0302
    LDY #$40
    CMP #$52
    BEQ $FE70
    LDY #$80
FE70:
    STY $0303
    LDA $3E
    STA $030B
    JSR $E459
    RTS

FE7C:
    STA $03FF
    LDA #$55
    STA $03FD
    STA $03FE
    LDA #$57
    JSR $FE3F
    RTS

.ORG $FE8D

FE8DTable:
    .BYTE $04, $03, $80, $C0, $02, $01, $40, $E0

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

.ORG $FF73

FF73: ; CKROM1
    LDX #$00
    STX $8B
    STX $8C
FF79:
    JSR $FFA9
    CPX #$0C
    BNE FF79
    LDA $C000
    LDX $C001
FF86:
    CMP $8B
    BNE FF90
    CPX $8C
    BNE FF90
    CLC
    RTS
FF90:
    SEC
    RTS

FF92: ; CKROM2
    LDX #$00
    STX $8B
    STX $8C
    LDX #$0C
    JSR $FFA9
    JSR $FFA9
    LDA $FFF8
    LDX $FFF9
    JMP FF86

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

.ORG $FFD7

CKSTAB:
    .WORD $C002, $D000, $5000, $5800, $D800, $E000, $E000, $FFF8, $FFFA, $0000

.ORG $FFF8

CHSRO2:
    .WORD $6C8C

.ORG $FFFA

FFFAVectors:
    .WORD $C018, $C2AA, $C02C

; Remaining verification work is in the earlier recovered gameplay blocks.

; -----------------------------------------------------------------------------
; Original XEX data / graphics / lookup segments
; -----------------------------------------------------------------------------

.ORG $2020

XEX_2020_000:
    .BYTE $46, $69, $6C, $65, $76, $65, $72, $73, $69, $6F, $6E, $20, $62, $79, $20, $48
    .BYTE $4F, $4D, $45, $53, $4F, $46, $54, $20, $3A, $20, $20

.ORG $0244

XEX_0244_001:
    .BYTE $01

.ORG $022F

XEX_022F_002:
    .BYTE $00

.ORG $7F00

XEX_7F00_003:
    .BYTE $A3, $16, $AD, $00, $7F, $8D, $10, $7F, $AC, $01, $7F, $A2, $00, $8A, $9D, $00
    .BYTE $00, $E8, $D0, $FA, $EE, $10, $7F, $88, $D0, $F4, $60

.ORG $02E2

XEX_02E2_004:
    .BYTE $02, $7F

.ORG $7F21

XEX_7F21_005:
    .BYTE $2C, $0F, $D4, $10, $03, $6C, $00, $02, $D8, $8D, $0F, $D4, $40, $F0, $70, $30
    .BYTE $4E, $10, $80, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
    .BYTE $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $8E, $0E
    .BYTE $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
    .BYTE $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
    .BYTE $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $8E, $0E, $0E
    .BYTE $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
    .BYTE $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $4E, $00, $90, $0E, $0E, $0E, $0E, $0E
    .BYTE $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
    .BYTE $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
    .BYTE $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $8E
    .BYTE $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
    .BYTE $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
    .BYTE $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $41, $2E, $7F

.ORG $8013

XEX_8013_006:
    .BYTE $0F, $F0, $FF, $03, $FC, $3F, $C0, $00, $03, $FC, $0F, $F0, $00, $3F, $C0, $3F
    .BYTE $F0

.ORG $803B

XEX_803B_007:
    .BYTE $3E, $BF, $EB, $CF, $AF, $FA, $F0, $00, $0F, $AF, $3E, $BC, $00, $FA, $F3, $FA
    .BYTE $BF, $C0

.ORG $805C

XEX_805C_008:
    .BYTE $03, $FC

.ORG $8063

XEX_8063_009:
    .BYTE $3A, $AA, $AA, $CE, $AA, $AA, $B0, $00, $0E, $AB, $FA, $AC, $00, $EA, $BF, $AA
    .BYTE $AA, $FC, $00, $03, $FC, $3F, $C3, $F0, $3F, $FC, $0F, $C3, $FF, $FF, $FF, $CF
    .BYTE $FF, $FF, $5C

.ORG $808B

XEX_808B_010:
    .BYTE $3A, $AA, $AA, $CE, $AA, $AA, $B0, $00, $0E, $AA, $AA, $AC, $00, $EA, $AA, $AA
    .BYTE $AA, $AF, $00, $03, $5C, $35, $CF, $7C, $F5, $5F, $3D, $F3, $55, $5D, $75, $FD
    .BYTE $75, $57, $5C

.ORG $80B3

XEX_80B3_011:
    .BYTE $3B, $AA, $AE, $CE, $EA, $AA, $B0, $00, $0E, $AA, $AA, $AC, $00, $EA, $AA, $FF
    .BYTE $AA, $AB, $00, $03, $5F, $F5, $CD, $5C, $D5, $57, $35, $73, $55, $5D, $75, $7D
    .BYTE $75, $57, $FF, $FC, $00, $00, $00, $00, $3F, $AA, $AF, $CF, $EA, $AF, $B0, $00
    .BYTE $0E, $EA, $AA, $EC, $00, $EE, $AB, $C3, $FA, $AB, $C0, $03, $57, $D5, $FD, $5F
    .BYTE $D7, $D7, $F5, $7F, $FD, $7D, $75, $7D, $75, $FF, $F5, $5F, $00, $00, $00, $00
    .BYTE $03, $AA, $AC, $00, $EA, $AF, $F0, $00, $0F, $EA, $AA, $FC, $00, $FE, $AB, $00
    .BYTE $3E, $AA, $C0, $03, $57, $D5, $F5, $57, $D7, $FF, $D5, $5C, $35, $7D, $75, $5D
    .BYTE $75, $FC, $D5, $57, $00, $00, $00, $00, $03, $AA, $AF, $03, $EA, $AC, $00, $00
    .BYTE $00, $EA, $AA, $C0, $00, $0E, $AB, $00, $0E, $AA, $F0, $03, $55, $55, $F5, $D7
    .BYTE $D7, $FF, $D7, $5F, $F5, $FD, $75, $55, $75, $5C, $D7, $FF, $00, $00, $00, $00
    .BYTE $03, $AA, $AB, $03, $AA, $AC, $00, $00, $03, $EA, $AA, $F0, $00, $0E, $AB, $00
    .BYTE $0F, $AA, $B0, $03, $55, $55, $D5, $D5, $D7, $57, $57, $57, $D5, $CD, $75, $55
    .BYTE $75, $5C, $D5, $5F, $00, $00, $00, $00, $0F, $AA, $AB, $03, $AA, $AF, $00, $00
    .BYTE $03, $AA, $EA, $B0, $00, $0E, $AB, $00, $03, $AA, $B0, $03, $5D, $75, $D7, $F5
    .BYTE $D7, $57, $5F, $D7, $D7, $CD, $75, $D5, $75, $FC, $F5, $57, $00, $00, $00, $00
    .BYTE $0E, $AA, $AB, $CF, $AA, $AB, $00, $00, $03, $AA, $EA, $B0, $00, $0E, $AB, $00
    .BYTE $03, $AA, $BC, $03, $5D, $75, $55, $55, $57, $D5, $55, $55, $57, $FD, $75, $F5
    .BYTE $75, $FF, $FF, $D7, $00, $00, $00, $00, $0E, $AA, $AA, $CE, $AA, $AB, $00, $00
    .BYTE $0F, $AB, $FA, $BC, $00, $0E, $AB, $00, $03, $EA, $AC, $03, $5F, $F5, $55, $55
    .BYTE $55, $55, $55, $55, $55, $5D, $75, $F5, $75, $57, $D5, $57, $00, $00, $00, $00
    .BYTE $3E, $AA, $AA, $CE, $AA, $AB, $C0, $00, $0E, $AB, $3A, $AC, $00, $0E, $AB, $00
    .BYTE $00, $EA, $AC, $03, $5C, $35, $5F, $FD, $75, $5D, $7F, $F5, $55, $5D, $75, $FD
    .BYTE $75, $57, $F5, $5F, $00, $00, $00, $00, $3A, $AB, $AA, $FE, $AE, $AA, $C0, $00
    .BYTE $0E, $AB, $3A, $AC, $00, $0E, $AB, $00, $00, $EA, $AC, $03, $FC, $3F, $FC, $0F
    .BYTE $FF, $FF, $F0, $3F, $FF, $FF, $FF, $CF, $FF, $FF, $3F, $FC, $00, $00, $00, $00
    .BYTE $3A, $AB, $AA, $BA, $AE, $AA, $C0, $00, $3E, $AF, $3E, $AF, $00, $0E, $AB, $00
    .BYTE $00, $EA, $AC

.ORG $826B

XEX_826B_012:
    .BYTE $FA, $AF, $EA, $AA, $BF, $AA, $F0, $00, $3A, $AC, $0E, $AB, $00, $0E, $AB, $00
    .BYTE $00, $EA, $AC

.ORG $8293

XEX_8293_013:
    .BYTE $EA, $AC, $EA, $AA, $B3, $AA, $B0, $00, $3A, $AC, $0E, $AB, $00, $0E, $AB, $00
    .BYTE $00, $EA, $AC, $00, $00, $3F, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $C3, $F0
    .BYTE $FF

.ORG $82BB

XEX_82BB_014:
    .BYTE $EA, $AC, $EA, $AA, $B3, $AA, $B0, $00, $FA, $BC, $0F, $AB, $C0, $0E, $AB, $00
    .BYTE $03, $EA, $AC, $00, $00, $F5, $57, $D5, $57, $55, $5D, $7D, $55, $F5, $CF, $7C
    .BYTE $D7

.ORG $82E2

XEX_82E2_015:
    .BYTE $03, $EA, $BC, $FA, $AA, $F3, $EA, $BC, $00, $EA, $BF, $FF, $AA, $C0, $0E, $AB
    .BYTE $00, $03, $AA, $AC, $00, $00, $D5, $55, $D5, $57, $55, $5D, $75, $55, $75, $CD
    .BYTE $5C, $D7

.ORG $830A

XEX_830A_016:
    .BYTE $03, $AA, $B0, $3A, $AA, $C0, $EA, $AC, $00, $EA, $AA, $AA, $AA, $C0, $0E, $AB
    .BYTE $00, $03, $AA, $BC, $00, $00, $D7, $F5, $D7, $FF, $5F, $FD, $75, $FD, $75, $FD
    .BYTE $5F, $D7

.ORG $8332

XEX_8332_017:
    .BYTE $03, $AA, $B0, $3A, $AA, $C0, $EA, $AC, $03, $EA, $AA, $AA, $AA, $F0, $0E, $AB
    .BYTE $00, $0F, $AA, $B0, $00, $00, $D7, $35, $D7, $03, $5C, $0D, $75, $CF, $F5, $F5
    .BYTE $57, $D7

.ORG $835A

XEX_835A_018:
    .BYTE $0F, $AA, $F0, $3E, $AB, $C0, $FA, $AF, $03, $AA, $AA, $AA, $AA, $B0, $0E, $AB
    .BYTE $00, $0E, $AA, $B0, $FC, $00, $D7, $35, $D7, $FF, $5F, $FD, $75, $C0, $35, $F5
    .BYTE $D7, $D7

.ORG $8382

XEX_8382_019:
    .BYTE $0E, $AA, $C0, $0E, $AB, $00, $3A, $AB, $03, $AB, $FF, $FF, $EA, $B0, $0E, $AB
    .BYTE $00, $3E, $AA, $F3, $03, $00, $D7, $35, $D5, $5F, $55, $7D, $75, $C0, $35, $D5
    .BYTE $D5, $D7

.ORG $83AA

XEX_83AA_020:
    .BYTE $0E, $AA, $C0, $0E, $AB, $00, $3A, $AB, $CF, $AB, $00, $00, $EA, $BC, $3E, $AB
    .BYTE $C3, $FA, $AA, $CC, $F0, $C0, $D7, $35, $D5, $5F, $55, $7D, $75, $CF, $F5, $D7
    .BYTE $F5, $D7

.ORG $83D1

XEX_83D1_021:
    .BYTE $03, $FE, $AA, $FC, $0F, $AF, $03, $FA, $AA, $FE, $AB, $C0, $03, $EA, $AF, $FA
    .BYTE $AA, $FF, $AA, $AB, $CC, $CC, $C0, $D7, $F5, $D7, $FF, $5F, $FD, $75, $FD, $75
    .BYTE $55, $55, $57, $FF, $00, $00, $00, $00, $03, $BE, $AA, $EC, $03, $AC, $03, $BA
    .BYTE $AA, $AA, $AA, $C0, $03, $AA, $AA, $AA, $AA, $AA, $AA, $AB, $0C, $F0, $C0, $D5
    .BYTE $55, $D7, $03, $5C, $0D, $75, $55, $75, $55, $55, $55, $57, $00, $00, $00, $00
    .BYTE $03, $AA, $AA, $AC, $03, $AC, $03, $AA, $AA, $AA, $AA, $C0, $03, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AF, $0C, $CC, $C0, $F5, $57, $D7, $03, $5C, $0D, $7D, $55, $F5
    .BYTE $5F, $FD, $55, $57, $00, $00, $00, $00, $03, $AA, $AA, $AC, $03, $FC, $03, $AA
    .BYTE $AA, $AA, $AA, $C0, $03, $AA, $FE, $AA, $FE, $AA, $AA, $FC, $03, $03, $00, $3F
    .BYTE $FF, $FF, $03, $FC, $0F, $FF, $FF, $FF, $FC, $0F, $FF, $FF, $00, $00, $00, $00
    .BYTE $03, $EB, $FE, $BC, $00, $F0, $03, $EB, $FE, $BF, $EB, $C0, $03, $EB, $CF, $AB
    .BYTE $CF, $EA, $BF, $C0, $00, $FC

.ORG $849A

XEX_849A_022:
    .BYTE $FF, $0F, $F0, $00, $00, $00, $FF, $0F, $F0, $FF, $00, $00, $FF, $03, $FF, $00
    .BYTE $FF, $F0

.ORG $84C5

XEX_84C5_023:
    .BYTE $03, $FF, $00, $0F, $FF, $C0, $00, $03

.ORG $84ED

XEX_84ED_024:
    .BYTE $3D, $55, $F0, $35, $55, $7F, $00, $0D, $C0, $00, $03, $C0, $00, $00, $0F, $FC
    .BYTE $03, $FF, $F0, $00, $00, $C0, $00, $00, $30

.ORG $8515

XEX_8515_025:
    .BYTE $D5, $55, $5C, $35, $55, $55, $F0, $0D, $70, $00, $03, $70, $00, $00, $FF, $FF
    .BYTE $C3, $FF, $FF, $C0, $00, $F0, $00, $00, $30

.ORG $853C

XEX_853C_026:
    .BYTE $03, $55, $55, $57, $0F, $D5, $55, $5C, $0F, $70, $00, $03, $70, $00, $03, $FF
    .BYTE $FF, $F0, $0F, $FF, $FC, $00, $30, $00, $00, $30, $00, $3F, $C0

.ORG $8564

XEX_8564_027:
    .BYTE $0D, $55, $55, $55, $C0, $D7, $F5, $57, $03, $5C, $00, $0D, $70, $00, $0F, $FF
    .BYTE $FF, $FC, $0F, $03, $FF, $00, $3C, $00, $00, $F0, $00, $30, $C0

.ORG $858C

XEX_858C_028:
    .BYTE $0D, $55, $55, $55, $C0, $D7, $3F, $55, $C3, $5C, $00, $0D, $70, $00, $0F, $FF
    .BYTE $FF, $FC, $0F, $00, $3F, $C0, $3C, $00, $00, $F0, $00, $30, $FF, $FF, $F0

.ORG $85B4

XEX_85B4_029:
    .BYTE $35, $55, $55, $55, $70, $D7, $03, $D5, $70, $D7, $00, $0D, $70, $00, $3F, $FF
    .BYTE $FF, $FF, $0F, $00, $03, $F0, $0F, $00, $00, $F0, $00, $30, $0F, $0C, $30

.ORG $85DC

XEX_85DC_030:
    .BYTE $35, $55, $55, $55, $70, $D7, $00, $35, $5C, $D7, $00, $35, $C0, $00, $3F, $FF
    .BYTE $FF, $FF, $0F, $00, $00, $FC, $0F, $00, $03, $C0, $00, $30, $03, $0C, $30

.ORG $8604

XEX_8604_031:
    .BYTE $35, $55, $55, $55, $70, $D7, $00, $0D, $57, $D5, $C0, $35, $C0, $00, $3F, $FF
    .BYTE $FF, $FF, $0F, $00, $00, $3F, $0F, $C0, $03, $C0, $00, $30, $C3, $0C, $30

.ORG $862C

XEX_862C_032:
    .BYTE $D5, $55, $55, $55, $5C, $D7, $00, $03, $57, $D5, $C0, $35, $C0, $00, $FF, $FF
    .BYTE $FF, $FF, $CF, $00, $00, $3F, $0F, $C0, $03, $C0, $00, $30, $03, $00, $30

.ORG $8654

XEX_8654_033:
    .BYTE $D5, $55, $55, $55, $5C, $D7, $00, $03, $55, $F5, $70, $35, $C0, $00, $FF, $FF
    .BYTE $FF, $FF, $CF, $00, $00, $3F, $C3, $F0, $03, $C0, $00, $30, $0F, $C0, $30

.ORG $867C

XEX_867C_034:
    .BYTE $D5, $55, $55, $55, $5C, $D7, $00, $00, $D5, $F5, $70, $D5, $C0, $00, $FF, $FF
    .BYTE $FF, $FF, $CF, $00, $00, $0F, $C3, $F0, $0F, $C0, $00, $3F, $FC, $FC, $30

.ORG $86A4

XEX_86A4_035:
    .BYTE $D5, $55, $55, $55, $5C, $D7, $00, $00, $D5, $75, $5C, $D5, $C0, $00, $FF, $FF
    .BYTE $FF, $FF, $CF, $00, $00, $0F, $F3, $FC, $0F, $C0, $00, $00, $00, $C0, $F0

.ORG $86CB

XEX_86CB_036:
    .BYTE $03, $55, $55, $55, $55, $5C, $D7, $00, $00, $D5, $7D, $5C, $D5, $C0, $03, $FF
    .BYTE $FF, $FF, $FF, $CF, $00, $00, $0F, $F0, $FC, $0F, $C0, $00, $00, $00, $FF, $C0

.ORG $86F3

XEX_86F3_037:
    .BYTE $03, $55, $55, $5F, $D5, $5C, $D7, $00, $00, $D5, $7D, $57, $D7, $00, $03, $FF
    .BYTE $FF, $C0, $FF, $CF, $00, $00, $0F, $F0, $FF, $0F, $00, $00, $3F, $CF, $F0

.ORG $871B

XEX_871B_038:
    .BYTE $03, $55, $55, $70, $35, $70, $D7, $00, $00, $35, $7D, $57, $57, $00, $03, $FF
    .BYTE $FF, $00, $3F, $0F, $00, $00, $03, $F0, $FF, $3F, $00, $00, $35, $FD, $7F, $FF
    .BYTE $FF, $FF, $C0

.ORG $8743

XEX_8743_039:
    .BYTE $03, $55, $55, $70, $0D, $70, $D5, $C0, $00, $35, $73, $57, $57, $00, $03, $FF
    .BYTE $FF, $00, $0F, $0F, $C0, $00, $03, $F0, $3F, $3F, $00, $00, $35, $FD, $75, $D7
    .BYTE $D7, $55, $C0

.ORG $876B

XEX_876B_040:
    .BYTE $03, $55, $55, $C0, $0D, $C0, $D5, $C0, $00, $35, $5F, $55, $57, $00, $03, $FF
    .BYTE $FC, $00, $0C, $0F, $C0, $00, $03, $FC, $3F, $FF, $00, $00, $35, $75, $75, $D7
    .BYTE $57, $55, $C0

.ORG $8793

XEX_8793_041:
    .BYTE $03, $55, $55, $C0, $0D, $C0, $D5, $C0, $00, $35, $5F, $55, $57, $00, $03, $FF
    .BYTE $FC, $00, $0C, $0F, $C0, $00, $03, $FC, $3F, $FF, $00, $00, $35, $55, $75, $D5
    .BYTE $5F, $5F, $C0

.ORG $87BB

XEX_87BB_042:
    .BYTE $03, $55, $55, $C0, $37, $00, $D5, $C0, $00, $35, $5F, $55, $57, $00, $03, $FF
    .BYTE $FC, $00, $30, $0F, $C0, $00, $03, $FC, $3F, $FF, $00, $00, $35, $55, $75, $D5
    .BYTE $7F, $57

.ORG $87E3

XEX_87E3_043:
    .BYTE $03, $55, $55, $C0, $3C, $00, $D5, $C0, $00, $35, $5C, $D5, $57, $00, $03, $FF
    .BYTE $FC, $00, $00, $0F, $C0, $00, $03, $FC, $0F, $FF, $00, $00, $35, $55, $75, $D5
    .BYTE $7F, $57

.ORG $880B

XEX_880B_044:
    .BYTE $03, $55, $55, $C0, $00, $00, $D5, $C0, $00, $35, $5C, $D5, $57, $00, $03, $FF
    .BYTE $FC, $00, $00, $0F, $C0, $00, $03, $FC, $0F, $FF, $00, $00, $35, $DD, $75, $D5
    .BYTE $5F, $5F, $C0

.ORG $8834

XEX_8834_045:
    .BYTE $D5, $55, $C0, $00, $00, $D5, $C0, $00, $35, $5C, $D5, $5C, $00, $00, $FF, $FC
    .BYTE $00, $00, $0F, $C0, $00, $03, $FC, $0F, $FC, $00, $00, $35, $FD, $75, $D7, $57
    .BYTE $55, $C0

.ORG $885C

XEX_885C_046:
    .BYTE $D5, $55, $C0, $00, $00, $D5, $70, $00, $D5, $5C, $35, $5C, $00, $00, $FF, $FC
    .BYTE $00, $00, $0F, $F0, $00, $0F, $FC, $03, $FC, $00, $00, $35, $FD, $75, $D7, $D7
    .BYTE $55, $C0

.ORG $8884

XEX_8884_047:
    .BYTE $D5, $55, $C0, $00, $00, $D5, $70, $00, $D5, $5C, $35, $5C, $00, $00, $FF, $FC
    .BYTE $00, $00, $0F, $F0, $00, $0F, $FC, $03, $FC, $00, $00, $3F, $CF, $FF, $FF, $FF
    .BYTE $FF, $C0

.ORG $88AC

XEX_88AC_048:
    .BYTE $D5, $55, $C0, $00, $00, $D5, $70, $00, $D5, $5C, $37, $F0, $00, $03, $FF, $FC
    .BYTE $00, $00, $0F, $F0, $00, $0F, $FC, $03, $FC, $00, $00, $3F, $03, $CF, $3C, $3C
    .BYTE $FF

.ORG $88D4

XEX_88D4_049:
    .BYTE $D5, $55, $70, $00, $00, $D5, $70, $00, $D5, $5C, $FF, $FC, $0F, $F3, $FF, $FF
    .BYTE $00, $00, $0F, $F0, $00, $0F, $FC, $0F, $FC, $03, $FF, $C0

.ORG $88FC

XEX_88FC_050:
    .BYTE $35, $55, $70, $00, $00, $D5, $70, $03, $55, $70, $DE, $AC, $0E, $AE, $AA, $FF
    .BYTE $00, $00, $0F, $F0, $00, $3F, $F0, $0F, $FC, $03, $55, $F0

.ORG $8924

XEX_8924_051:
    .BYTE $35, $55, $70, $00, $00, $D5, $70, $03, $55, $70, $DE, $AC, $0E, $AE, $AA, $BF
    .BYTE $00, $00, $0F, $F0, $00, $3F, $F0, $0F, $FC, $03, $55, $7F, $FF, $FF, $FF, $FF
    .BYTE $FF

.ORG $894C

XEX_894C_052:
    .BYTE $35, $55, $70, $00, $00, $D5, $70, $0D, $55, $70, $DE, $AC, $0E, $AA, $AA, $AF
    .BYTE $00, $00, $0F, $F0, $00, $FF, $F0, $0F, $FC, $03, $5D, $75, $D5, $75, $5F, $55
    .BYTE $D7

.ORG $8974

XEX_8974_053:
    .BYTE $35, $55, $70, $00, $00, $D5, $70, $0D, $55, $70, $DE, $AC, $0E, $AA, $AA, $AF
    .BYTE $00, $00, $0F, $F0, $00, $FF, $F0, $0F, $F0, $03, $5D, $75, $D5, $75, $57, $55
    .BYTE $D7

.ORG $899C

XEX_899C_054:
    .BYTE $0D, $55, $70, $00, $00, $D5, $5C, $35, $55, $C3, $5E, $AB, $3A, $AA, $BE, $AF
    .BYTE $00, $00, $0F, $FC, $03, $FF, $C0, $3F, $F0, $03, $5D, $75, $D7, $F5, $D7, $5F
    .BYTE $D7

.ORG $89C4

XEX_89C4_055:
    .BYTE $0D, $55, $70, $00, $00, $D5, $5C, $D5, $55, $C3, $5E, $AB, $3A, $AA, $BF, $FF
    .BYTE $00, $00, $0F, $FC, $0F, $FF, $C0, $3F, $F0, $03, $55, $75, $D5, $F5, $D7, $57
    .BYTE $D7

.ORG $89EC

XEX_89EC_056:
    .BYTE $0D, $55, $70, $00, $00, $D5, $5F, $55, $55, $C3, $57, $AB, $3A, $BA, $BF, $FF
    .BYTE $00, $00, $0F, $FC, $3F, $FF, $C0, $3F, $F0, $03, $55, $F5, $D5, $F5, $D7, $57
    .BYTE $D7

.ORG $8A14

XEX_8A14_057:
    .BYTE $0D, $55, $70, $00, $00, $D5, $55, $55, $55, $C3, $57, $AB, $3A, $BA, $AA, $FF
    .BYTE $00, $00, $0F, $FF, $FF, $FF, $C0, $3F, $F0, $03, $5D, $75, $D7, $F5, $D7, $5F
    .BYTE $D7, $F0

.ORG $8A3C

XEX_8A3C_058:
    .BYTE $03, $55, $5C, $00, $00, $D5, $55, $55, $57, $03, $57, $AB, $FA, $BA, $AA, $BF
    .BYTE $C0, $00, $0F, $FF, $FF, $FF, $00, $3F, $F0, $03, $5D, $75, $D5, $75, $57, $55
    .BYTE $D5, $70

.ORG $8A64

XEX_8A64_059:
    .BYTE $03, $55, $5C, $00, $00, $D5, $55, $55, $57, $0D, $57, $AA, $EA, $BE, $AA, $AF
    .BYTE $C0, $00, $0F, $FF, $FF, $FF, $00, $FF, $F0, $03, $5D, $75, $D5, $75, $5F, $55
    .BYTE $D5, $70

.ORG $8A8C

XEX_8A8C_060:
    .BYTE $03, $55, $5C, $00, $00, $D5, $55, $55, $57, $0D, $57, $AA, $EA, $3F, $AA, $AF
    .BYTE $C0, $00, $0F, $FF, $FF, $FF, $00, $FF, $F0, $03, $FF, $FF, $FF, $FF, $FF, $FF
    .BYTE $FF, $F0

.ORG $8AB4

XEX_8AB4_061:
    .BYTE $03, $55, $5C, $00, $00, $D5, $55, $55, $5C, $0D, $55, $EA, $EA, $FF, $FE, $AF
    .BYTE $C0, $00, $0F, $FF, $FF, $FC, $00, $FF, $F0, $03, $F3, $CF, $3F, $CF, $F0, $FF
    .BYTE $3F, $C0

.ORG $8ADD

XEX_8ADD_062:
    .BYTE $D5, $5C, $00, $00, $D5, $55, $55, $5C, $0D, $55, $EA, $EA, $FF, $FE, $AF, $C0
    .BYTE $00, $0F, $FF, $FF, $FC, $00, $FF, $C0

.ORG $8B05

XEX_8B05_063:
    .BYTE $D5, $5C, $00, $00, $D5, $55, $55, $70, $35, $55, $EA, $AA, $FA, $BE, $AF, $C0
    .BYTE $00, $0F, $FF, $FF, $F0, $03, $FF, $C0

.ORG $8B2D

XEX_8B2D_064:
    .BYTE $D5, $5C, $00, $00, $D5, $55, $55, $C0, $35, $55, $FA, $AB, $FA, $AA, $AF, $C0
    .BYTE $00, $0F, $FF, $FF, $C0, $03, $FF, $C0

.ORG $8B55

XEX_8B55_065:
    .BYTE $D5, $5C, $00, $00, $D5, $55, $57, $00, $35, $55, $FA, $AB, $3A, $AA, $AF, $C0
    .BYTE $00, $0F, $FF, $FF, $00, $03, $FF, $C0

.ORG $8B7D

XEX_8B7D_066:
    .BYTE $35, $57, $00, $00, $D5, $55, $5C, $00, $35, $55, $FA, $AB, $3A, $AA, $BF, $F0
    .BYTE $00, $0F, $FF, $FC, $00, $03, $FF, $C0

.ORG $8BA5

XEX_8BA5_067:
    .BYTE $35, $57, $00, $00, $D5, $55, $B0, $00, $35, $55, $FE, $AF, $3E, $AA, $FF, $F0
    .BYTE $00, $0F, $FF, $F0, $00, $03, $FF, $C0

.ORG $8BCD

XEX_8BCD_068:
    .BYTE $35, $57, $00, $00, $D5, $55, $C0, $00, $D5, $55, $CF, $FC, $0F, $FF, $FF, $F0
    .BYTE $00, $0F, $FF, $C0, $00, $0F, $FF, $C0

.ORG $8BF5

XEX_8BF5_069:
    .BYTE $35, $57, $00, $00, $D5, $55, $C0, $00, $D5, $55, $C3, $F0, $03, $FF, $3F, $F0
    .BYTE $00, $0F, $FF, $C0, $00, $0F, $FF, $C0, $00, $3F, $3F, $FC, $FC, $FF, $CF, $C0

.ORG $8C1D

XEX_8C1D_070:
    .BYTE $0D, $57, $00, $00, $D5, $55, $C0, $00, $D5, $55, $C0, $00, $00, $00, $0F, $F0
    .BYTE $00, $0F, $FF, $C0, $00, $0F, $FF, $C0, $00, $FB, $EA, $AB, $EF, $EA, $BE, $B3
    .BYTE $C0

.ORG $8C45

XEX_8C45_071:
    .BYTE $0D, $57, $00, $00, $D5, $55, $C0, $00, $D5, $57, $00, $00, $00, $00, $0F, $F0
    .BYTE $00, $0F, $FF, $C0, $00, $0F, $FF, $00, $03, $EA, $EA, $AB, $AB, $EA, $AE, $B3
    .BYTE $30

.ORG $8C6D

XEX_8C6D_072:
    .BYTE $0D, $57, $00, $00, $D5, $55, $C0, $03, $55, $57, $00, $00, $00, $00, $0F, $F0
    .BYTE $00, $0F, $FF, $C0, $00, $3F, $FF, $00, $03, $AA, $BE, $BE, $AA, $EB, $AE, $B3
    .BYTE $C0

.ORG $8C95

XEX_8C95_073:
    .BYTE $0D, $57, $00, $00, $D5, $55, $C0, $03, $55, $57, $00, $00, $00, $00, $0F, $F0
    .BYTE $00, $0F, $FF, $C0, $00, $3F, $FF, $00, $03, $AE, $BE, $BE, $BA, $EB, $AE, $B3
    .BYTE $30

.ORG $8CBD

XEX_8CBD_074:
    .BYTE $03, $55, $C0, $00, $D5, $55, $70, $03, $55, $57, $00, $00, $00, $00, $03, $FC
    .BYTE $00, $0F, $FF, $F0, $00, $3F, $FF, $00, $03, $AE, $BE, $BE, $BA, $EA, $AE, $B0

.ORG $8CE5

XEX_8CE5_075:
    .BYTE $03, $55, $C0, $00, $D5, $55, $70, $03, $55, $57, $00, $00, $00, $00, $03, $FC
    .BYTE $00, $0F, $FF, $F0, $00, $3F, $FF, $00, $03, $AA, $BE, $BE, $AA, $EA, $BE, $B0

.ORG $8D0D

XEX_8D0D_076:
    .BYTE $C3, $55, $C0, $00, $D5, $55, $70, $03, $55, $57, $00, $00, $00, $00, $03, $FC
    .BYTE $00, $0F, $FF, $F0, $00, $3F, $FF, $00, $03, $AA, $BE, $BE, $AA, $EB, $AE, $B0

.ORG $8D34

XEX_8D34_077:
    .BYTE $03, $73, $55, $C0, $00, $D5, $55, $70, $0D, $55, $57, $00, $00, $00, $03, $03
    .BYTE $FC, $00, $0F, $FF, $F0, $00, $FF, $FF, $00, $03, $AE, $BE, $BE, $BA, $EB, $AE
    .BYTE $B0

.ORG $8D5C

XEX_8D5C_078:
    .BYTE $03, $70, $D5, $C0, $00, $D5, $55, $70, $0D, $55, $57, $00, $00, $00, $03, $00
    .BYTE $FC, $00, $0F, $FF, $F0, $00, $FF, $FF, $00, $03, $FF, $FF, $FF, $FF, $FF, $FF
    .BYTE $F0

.ORG $8D84

XEX_8D84_079:
    .BYTE $0D, $C0, $D5, $C0, $00, $D5, $55, $70, $0D, $55, $57, $00, $00, $00, $0C, $00
    .BYTE $FC, $00, $0F, $FF, $F0, $00, $FF, $FF, $00, $03, $F3, $C3, $C3, $CF, $3C, $F3
    .BYTE $C0

.ORG $8DAC

XEX_8DAC_080:
    .BYTE $0D, $C0, $D5, $C0, $00, $D5, $55, $70, $0D, $55, $5C, $00, $00, $00, $0C, $00
    .BYTE $FC, $00, $0F, $FF, $F0, $00, $FF, $FC

.ORG $8DD4

XEX_8DD4_081:
    .BYTE $0D, $C0, $D5, $C0, $00, $D5, $55, $70, $35, $55, $5C, $00, $00, $00, $0C, $00
    .BYTE $FC, $00, $0F, $FF, $F0, $03, $FF, $FC, $00, $03, $FF, $FF, $FF, $FF, $3F, $CF
    .BYTE $CF, $F3, $F3, $FC, $00, $00, $00, $00, $0D, $7F, $55, $C0, $00, $D5, $55, $70
    .BYTE $35, $55, $5C, $00, $00, $00, $0F, $03, $FC, $00, $0F, $FF, $F0, $03, $FF, $FC
    .BYTE $00, $03, $AE, $BA, $AE, $AB, $FA, $BE, $BE, $AF, $AF, $AC, $00, $00, $00, $00
    .BYTE $0D, $55, $55, $C0, $00, $D5, $54, $70, $35, $55, $5C, $00, $00, $00, $0F, $FF
    .BYTE $FC, $00, $0F, $FF, $F0, $03, $3F, $FC, $00, $03, $AE, $BA, $AE, $AA, $EA, $AE
    .BYTE $BA, $AB, $AF, $AC, $00, $00, $00, $00, $0D, $65, $55, $C0, $00, $D5, $55, $F0
    .BYTE $35, $55, $5C, $00, $0C, $00, $0F, $FF, $CC, $00, $0F, $FF, $F0, $0D, $FF, $FC
    .BYTE $00, $03, $AE, $BA, $FE, $BA, $EB, $FE, $BA, $EB, $AB, $AC, $00, $00, $00, $00
    .BYTE $0F, $55, $57, $C0, $00, $D5, $55, $7F, $B5, $55, $70, $00, $3C, $00, $03, $FF
    .BYTE $97, $00, $0F, $FF, $C0, $F7, $FF, $F0, $00, $03, $AE, $BA, $BE, $BA, $EA, $BE
    .BYTE $BA, $EB, $AA, $AC, $00, $00, $00, $00, $03, $65, $57, $00, $00, $35, $55, $CF
    .BYTE $FC, $55, $70, $00, $FF, $00, $03, $FF, $15, $C0, $0F, $FF, $CC, $5F, $FF, $F0
    .BYTE $00, $03, $AA, $BA, $BE, $AA, $FA, $AE, $BA, $EB, $AA, $AC, $00, $00, $00, $00
    .BYTE $03, $65, $57, $00, $00, $35, $55, $C3, $FF, $C5, $70, $0B, $FF, $00, $03, $FF
    .BYTE $15, $70, $03, $FF, $C5, $73, $FF, $F0, $00, $03, $AA, $BA, $FE, $AB, $FF, $AE
    .BYTE $BA, $EB, $AA, $AC

.ORG $8EED

XEX_8EED_082:
    .BYTE $D5, $5C, $00, $00, $35, $57, $00, $FF, $FE, $70, $23, $FF, $C0, $00, $FF, $95
    .BYTE $5C, $03, $FE, $55, $C0, $FF, $F0, $00, $03, $EA, $FA, $AE, $BA, $EA, $AE, $BA
    .BYTE $AB, $AE, $AC

.ORG $8F15

XEX_8F15_083:
    .BYTE $35, $70, $00, $00, $0D, $5C, $00, $3F, $FF, $F0, $C4, $FF, $C0, $00, $3F, $55
    .BYTE $4F, $83, $E5, $57, $00, $FF, $C0, $00, $03, $FB, $FA, $AE, $BA, $FA, $BE, $BE
    .BYTE $AF, $AF, $AC

.ORG $8F3D

XEX_8F3D_084:
    .BYTE $2F, $C0, $00, $00, $03, $F0, $00, $0F, $FF, $FF, $15, $FF, $F0, $00, $03, $55
    .BYTE $7F, $FD, $55, $5C, $00, $3F, $00, $00, $00, $FF, $3F, $FF, $FF, $FF, $FF, $FF
    .BYTE $FF, $FF, $FC

.ORG $8F65

XEX_8F65_085:
    .BYTE $10

.ORG $8F6C

XEX_8F6C_086:
    .BYTE $03, $FF, $FF, $55, $3F, $F0, $00, $03, $55, $3F, $D5, $55, $70

.ORG $8F7E

XEX_8F7E_087:
    .BYTE $3C, $0F, $F3, $CF, $0F, $C3, $C3, $F0, $F0, $F0

.ORG $8F95

XEX_8F95_088:
    .BYTE $FF, $FF, $D5, $7F, $F0, $00, $03, $55, $FF, $D5, $55, $C0

.ORG $8FB3

XEX_8FB3_089:
    .BYTE $04, $00, $00, $00, $40

.ORG $8FBD

XEX_8FBD_090:
    .BYTE $3F, $FF, $F5, $4F, $C0, $00, $03, $54, $FF, $55, $57

.ORG $8FD4

XEX_8FD4_091:
    .BYTE $0F, $F0

.ORG $8FDD

XEX_8FDD_092:
    .BYTE $10

.ORG $8FE5

XEX_8FE5_093:
    .BYTE $0F, $FF, $FD, $5F, $C0, $00, $00, $D7, $FD, $55, $5C

.ORG $8FFC

XEX_8FFC_094:
    .BYTE $0C, $30

.ORG $900D

XEX_900D_095:
    .BYTE $03, $FF, $FF, $53, $C0, $00, $00, $D3, $F1, $55, $78

.ORG $9024

XEX_9024_096:
    .BYTE $0C, $3F, $FF, $FC

.ORG $902D

XEX_902D_097:
    .BYTE $10

.ORG $9035

XEX_9035_098:
    .BYTE $0F, $FF, $FF, $97, $00, $00, $00, $DF, $F5, $55, $FC

.ORG $904C

XEX_904C_099:
    .BYTE $0C, $03, $C3, $0C, $00, $00, $00, $00, $10, $00, $10

.ORG $905D

XEX_905D_100:
    .BYTE $0C, $3F, $FF, $D7, $00, $00, $00, $3F, $D5, $57, $0C

.ORG $9074

XEX_9074_101:
    .BYTE $0C, $00, $C3, $0C

.ORG $907D

XEX_907D_102:
    .BYTE $10

.ORG $9085

XEX_9085_103:
    .BYTE $32, $0F, $FF, $F7, $00, $00, $00, $3F, $15, $5C, $AB

.ORG $909C

XEX_909C_104:
    .BYTE $0C, $30, $C3, $0C

.ORG $90A5

XEX_90A5_105:
    .BYTE $10

.ORG $90AD

XEX_90AD_106:
    .BYTE $3A, $A3, $FF, $FC, $00, $00, $00, $3F, $55, $72, $AB

.ORG $90C4

XEX_90C4_107:
    .BYTE $0C, $00, $C0, $0C, $00, $00, $00, $00, $01, $11

.ORG $90D5

XEX_90D5_108:
    .BYTE $EB, $F8, $FF, $FC, $00, $00, $00, $3D, $55, $CB, $FA, $C0

.ORG $90EC

XEX_90EC_109:
    .BYTE $0C, $03, $F0, $0C

.ORG $90F5

XEX_90F5_110:
    .BYTE $54

.ORG $90FD

XEX_90FD_111:
    .BYTE $EF, $EA, $3F, $FF, $00, $00, $00, $35, $57, $2A, $FE, $C0

.ORG $910E

XEX_910E_112:
    .BYTE $03, $FC, $00, $00, $00, $00, $0F, $FF, $3F, $0C, $00, $00, $10, $45, $55, $65
    .BYTE $55, $10, $40, $00, $00, $00, $03, $BD, $EA, $8F, $FF, $C0, $00, $00, $D5, $5E
    .BYTE $AA, $EF, $B0

.ORG $9136

XEX_9136_113:
    .BYTE $03, $5F, $FF, $CF, $F0, $00, $00, $00, $30, $3C

.ORG $9145

XEX_9145_114:
    .BYTE $58

.ORG $914C

XEX_914C_115:
    .BYTE $03, $E5, $EA, $E3, $FF, $C0, $00, $00, $15, $7A, $AA, $D7, $F0

.ORG $915E

XEX_915E_116:
    .BYTE $03, $5D, $75, $FD, $70, $00, $00, $00, $3F, $F0, $00, $00, $00, $00, $01, $19

.ORG $9174

XEX_9174_117:
    .BYTE $03, $F6, $A8, $F8, $FF, $F0, $00, $03, $55, $FA, $EA, $A7, $F0

.ORG $9186

XEX_9186_118:
    .BYTE $03, $5D, $75, $FD, $70

.ORG $9195

XEX_9195_119:
    .BYTE $1E

.ORG $919C

XEX_919C_120:
    .BYTE $03, $F3, $AA, $CA, $3F, $FC, $00, $0D, $57, $CA, $FA, $B3, $F8

.ORG $91AE

XEX_91AE_121:
    .BYTE $03, $5D, $75, $75, $70

.ORG $91BD

XEX_91BD_122:
    .BYTE $1D

.ORG $91C4

XEX_91C4_123:
    .BYTE $0F, $CE, $A3, $7A, $BF, $FC, $00, $01, $5F, $E8, $2F, $AE, $FC, $00, $00, $00
    .BYTE $00, $03, $FF, $5D, $75, $55, $70

.ORG $91E4

XEX_91E4_124:
    .BYTE $10, $1B, $10

.ORG $91EC

XEX_91EC_125:
    .BYTE $0C, $FA, $AC, $B2, $B3, $FF, $00, $35, $7D, $EB, $AE, $AB, $CC, $00, $00, $00
    .BYTE $00, $03, $5F, $5D, $75, $55, $70

.ORG $920D

XEX_920D_126:
    .BYTE $1B, $80

.ORG $9214

XEX_9214_127:
    .BYTE $30, $AA, $A3, $6E, $BC, $FF, $C0, $D5, $CD, $EB, $4E, $AA, $03, $00, $00, $00
    .BYTE $00, $03, $5F, $5D, $75, $DD, $70

.ORG $9235

XEX_9235_128:
    .BYTE $03, $C0

.ORG $923C

XEX_923C_129:
    .BYTE $32, $AA, $A3, $AE, $FC, $3F, $C0, $17, $0D, $EB, $AE, $AA, $A3, $00, $00, $00
    .BYTE $00, $03, $55, $5D, $75, $FD, $70

.ORG $925D

XEX_925D_130:
    .BYTE $12, $E0

.ORG $9264

XEX_9264_131:
    .BYTE $CA, $AA, $83, $6E, $FC, $0F, $F3, $5C, $0D, $EB, $4C, $AA, $A8, $C0, $00, $00
    .BYTE $00, $03, $D5, $7D, $75, $FD, $70

.ORG $9283

XEX_9283_132:
    .BYTE $04, $00, $12, $F0, $40, $00, $00, $00, $00, $EA, $AA, $83, $A2, $FF, $03, $FD
    .BYTE $70, $35, $6B, $AC, $AA, $AA, $C0, $00, $00, $00, $00, $FF, $FF, $FF, $CF, $F0

.ORG $92AD

XEX_92AD_133:
    .BYTE $02, $F8, $00, $00, $00, $00, $03, $AA, $AA, $0F, $FB, $FF, $00, $F5, $C0, $36
    .BYTE $7A, $CC, $2A, $AA, $30, $00, $00, $00, $00, $3F, $C3, $CF, $03, $C0

.ORG $92D5

XEX_92D5_134:
    .BYTE $10, $F8, $00, $00, $00, $00, $03, $AA, $AA, $30, $3F, $FF, $00, $37, $00, $35
    .BYTE $BA, $C3, $2A, $AA, $B0

.ORG $92FE

XEX_92FE_135:
    .BYTE $FC, $00, $00, $00, $00, $0C, $AA, $A8, $C0, $3F, $FF, $00, $DF, $C0, $35, $6F
    .BYTE $00, $CA, $AA, $8C, $00, $00, $FF, $FF

.ORG $9325

XEX_9325_136:
    .BYTE $10, $BE, $00, $00, $00, $00, $0E, $AA, $A3, $00, $3F, $FF, $C2, $73, $C0, $D5
    .BYTE $5B, $00, $32, $AA, $AC, $00, $00, $D7, $D7, $3F, $3F, $3F, $3F, $FC, $3F, $3F
    .BYTE $3F, $3F, $F0

.ORG $934E

XEX_934E_137:
    .BYTE $3E, $00, $00, $00, $00, $32, $AA, $8C, $00, $3F, $FF, $C3, $C0, $F0, $D5, $57
    .BYTE $C0, $0C, $AA, $AB, $00, $00, $D7, $D7, $F7, $F5, $F5, $F5, $5F, $F7, $F5, $F5
    .BYTE $F5, $70

.ORG $9376

XEX_9376_138:
    .BYTE $3F, $00, $00, $00, $00, $3A, $AA, $30, $00, $3F, $FF, $C3, $00, $30, $D5, $55
    .BYTE $C0, $03, $AA, $AB, $00, $00, $D5, $D7, $D5, $F5, $F5, $D5, $57, $D5, $F5, $F5
    .BYTE $D5, $5C

.ORG $939D

XEX_939D_139:
    .BYTE $10, $3F, $80, $00, $00, $00, $CA, $A8, $C0, $00, $FF, $FF, $C0, $00, $00, $D5
    .BYTE $55, $C0, $00, $EA, $A8, $C0, $00, $D5, $57, $55, $75, $75, $D7, $D7, $55, $75
    .BYTE $75, $D5, $5C

.ORG $93C6

XEX_93C6_140:
    .BYTE $2F, $80, $00, $00, $00, $EA, $A3, $00, $00, $FF, $FF, $F0, $00, $03, $55, $55
    .BYTE $C0, $00, $3A, $AA, $C0, $00, $D5, $57, $5D, $75, $55, $D7, $FF, $5D, $75, $55
    .BYTE $D7, $5C

.ORG $93EE

XEX_93EE_141:
    .BYTE $0F, $F0, $00, $00, $03, $2A, $8C, $00, $00, $FF, $FF, $F0, $00, $03, $55, $55
    .BYTE $70, $00, $0E, $AA, $30, $00, $D5, $57, $5D, $75, $55, $D7, $57, $5D, $75, $55
    .BYTE $D7, $5C

.ORG $9416

XEX_9416_142:
    .BYTE $0F, $E0, $00, $00, $03, $2A, $30, $00, $03, $FF, $FF, $F0, $00, $03, $55, $55
    .BYTE $70, $00, $03, $AA, $B0, $00, $D7, $57, $55, $75, $55, $D7, $D7, $55, $75, $55
    .BYTE $D7, $5C

.ORG $943E

XEX_943E_143:
    .BYTE $0F, $E0, $00, $00, $0C, $A8, $C0, $00, $03, $FF, $FF, $F0, $00, $03, $55, $55
    .BYTE $70, $00, $00, $EA, $8C, $00, $D7, $D7, $55, $75, $D5, $D5, $57, $55, $75, $D5
    .BYTE $D5, $5C

.ORG $9465

XEX_9465_144:
    .BYTE $10, $0B, $FC, $00, $00, $0C, $A3, $00, $00, $03, $FF, $FF, $FC, $00, $0D, $55
    .BYTE $55, $70, $00, $00, $3A, $8C, $00, $D7, $D7, $5D, $75, $F5, $F5, $5F, $5D, $75
    .BYTE $F5, $F5, $7C

.ORG $948D

XEX_948D_145:
    .BYTE $10, $03, $F8, $02, $C0, $32, $8C, $00, $00, $0F, $FF, $FF, $FC, $00, $0D, $54
    .BYTE $55, $5C, $00, $00, $0E, $A3, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .BYTE $FF, $FF, $F0

.ORG $94B6

XEX_94B6_146:
    .BYTE $03, $FB, $2F, $00, $32, $30, $00, $00, $0F, $FF, $3F, $FC, $00, $0D, $54, $15
    .BYTE $5C, $00, $00, $03, $A3, $00, $FC, $3C, $F3, $CF, $0F, $0F, $F0, $F3, $CF, $0F
    .BYTE $0F, $C0

.ORG $94DD

XEX_94DD_147:
    .BYTE $10, $02, $FC, $FC, $00, $C8, $C0, $00, $00, $0F, $FF, $FF, $FC, $00, $0D, $55
    .BYTE $45, $5C, $00, $00, $00, $E8, $C0

.ORG $9506

XEX_9506_148:
    .BYTE $02, $F3, $F0, $00, $CB, $00, $00, $00, $3F, $FC, $FF, $FF, $00, $31, $55, $45
    .BYTE $57, $00, $00, $00, $3A, $C0

.ORG $952F

XEX_952F_149:
    .BYTE $CF, $F0, $03, $AC, $00, $00, $00, $3F, $F3, $FF, $FF, $00, $35, $55, $51, $57
    .BYTE $00, $00, $00, $0E, $B0

.ORG $9557

XEX_9557_150:
    .BYTE $FF, $30, $03, $30, $00, $00, $00, $FF, $F3, $FF, $FF, $00, $35, $55, $54, $55
    .BYTE $C0, $00, $00, $03, $B0

.ORG $957E

XEX_957E_151:
    .BYTE $03, $FC, $EC, $0E, $C0, $00, $00, $00, $FF, $CF, $FF, $FF, $00, $35, $55, $55
    .BYTE $15, $C0, $00, $00, $00, $EC

.ORG $95A6

XEX_95A6_152:
    .BYTE $0F, $C3, $EB, $0F, $00, $00, $00, $03, $FF, $3F, $FF, $FF, $00, $35, $55, $55
    .BYTE $15, $70, $00, $00, $00, $3C

.ORG $95CE

XEX_95CE_153:
    .BYTE $3F, $F2, $A8, $00, $00, $00, $00, $03, $FC, $FF, $FF, $FF, $C0, $C5, $55, $55
    .BYTE $45, $7C

.ORG $95E5

XEX_95E5_154:
    .BYTE $03, $E0, $00, $00, $70

.ORG $95F6

XEX_95F6_155:
    .BYTE $F0, $E8, $AA, $C0, $00, $00, $00, $0F, $FC, $FF, $FC, $FF, $C0, $D5, $55, $55
    .BYTE $51, $5C

.ORG $960D

XEX_960D_156:
    .BYTE $02, $FF, $FF, $FF, $FC

.ORG $961F

XEX_961F_157:
    .BYTE $FE, $AA, $FC, $00, $00, $02, $CF, $F3, $FF, $FF, $FF, $C0, $D5, $05, $55, $54
    .BYTE $5F

.ORG $9635

XEX_9635_158:
    .BYTE $33, $D5, $10, $00, $14

.ORG $9647

XEX_9647_159:
    .BYTE $CA, $AA, $BF, $C0, $00, $38, $3F, $CF, $FF, $CF, $FF, $C0, $D5, $40, $55, $54
    .BYTE $53, $C0, $00, $00, $00, $00, $3F, $FF, $FF, $FF, $FC

.ORG $966F

XEX_966F_160:
    .BYTE $3C, $AA, $BF, $FC, $00, $CA, $AF, $3F, $FF, $33, $FF, $C0, $D5, $54, $15, $55
    .BYTE $14, $FC, $00, $00, $00, $00, $3C, $CF, $FF, $FF, $FC

.ORG $9697

XEX_9697_161:
    .BYTE $32, $2A, $FF, $FF, $C3, $EA, $2B, $FF, $FF, $0C, $FF, $C0, $D5, $55, $45, $55
    .BYTE $77, $2B, $00, $00, $00, $00, $FC, $CF, $FF, $FF, $BC

.ORG $96BF

XEX_96BF_162:
    .BYTE $0F, $2A, $FF, $FF, $FF, $A8, $BB, $FF, $FC, $FF, $FF, $E0, $15, $55, $51, $55
    .BYTE $5F, $AA, $C0, $00, $00, $03, $3F, $FF, $FF, $FF, $C0

.ORG $96E7

XEX_96E7_163:
    .BYTE $0E, $AB, $FF, $FF, $FF, $E2, $2F, $FF, $F3, $FF, $FF, $F3, $55, $55, $54, $55
    .BYTE $50, $AA, $00, $00, $00, $0E, $BF, $FF, $FC

.ORG $970F

XEX_970F_164:
    .BYTE $03, $FF, $3F, $FF, $FF, $EB, $8B, $FF, $CF, $FF, $FF, $FB, $55, $55, $55, $15
    .BYTE $57, $AA, $B0, $00, $00, $0E, $8F, $2B, $30

.ORG $9738

XEX_9738_165:
    .BYTE $BF, $03, $FF, $FF, $FA, $EF, $FF, $3F, $FF, $FF, $F3, $55, $55, $55, $45, $57
    .BYTE $8A, $AC, $00, $00, $3A, $80, $A3, $30

.ORG $9760

XEX_9760_166:
    .BYTE $BF, $00, $3F, $FF, $FE, $BF, $FC, $FF, $FF, $7F, $FB, $55, $55, $55, $51, $57
    .BYTE $B8, $AF, $FF, $FF, $FA, $AA, $BF, $30

.ORG $9788

XEX_9788_167:
    .BYTE $3E, $00, $03, $FF, $FF, $FF, $F3, $FF, $FF, $7F, $FB, $55, $55, $55, $54, $57
    .BYTE $BB, $AD, $55, $53, $EA, $AB, $30, $F0

.ORG $97B0

XEX_97B0_168:
    .BYTE $28, $00, $00, $3F, $FF, $FF, $CF, $FF, $FD, $7F, $FB, $55, $55, $55, $55, $D4
    .BYTE $FB, $B5, $55, $57, $AA, $A2, $FF, $C0

.ORG $97DB

XEX_97DB_169:
    .BYTE $03, $FF, $FF, $3F, $FF, $FD, $7F, $CC, $55, $55, $55, $55, $75, $3B, $85, $55
    .BYTE $57, $AA, $AE, $C0

.ORG $9804

XEX_9804_170:
    .BYTE $3F, $FC, $FF, $FF, $F5, $7F, $B1, $15, $55, $55, $55, $4D, $53, $15, $55, $57
    .BYTE $AA, $88, $C0

.ORG $982C

XEX_982C_171:
    .BYTE $02, $FB, $FF, $FF, $F5, $7F, $EC, $55, $55, $55, $55, $5F, $55, $55, $55, $53
    .BYTE $F0, $A3, $C0

.ORG $9855

XEX_9855_172:
    .BYTE $03, $B2, $23, $95, $60, $B1, $11, $55, $55, $55, $40, $F0, $00, $00, $0F, $03
    .BYTE $FF

.ORG $9873

XEX_9873_173:
    .BYTE $3F, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $D5, $7F, $FF
    .BYTE $FF, $FF, $FF, $FF, $FF, $BF, $FF, $FF, $FE, $FF, $FB, $FF, $FF, $FF, $FF, $FF
    .BYTE $FF, $FF, $F0

.ORG $989B

XEX_989B_174:
    .BYTE $C0

.ORG $98A8

XEX_98A8_175:
    .BYTE $55, $40

.ORG $98BD

XEX_98BD_176:
    .BYTE $0C

.ORG $98C3

XEX_98C3_177:
    .BYTE $C0

.ORG $98D0

XEX_98D0_178:
    .BYTE $55, $40, $00, $03, $FC, $F3, $FF, $03, $FC, $FF, $F3, $FF, $FF, $FF, $FF, $FF
    .BYTE $FF, $FF, $FF, $FF, $FF, $FC

.ORG $98EB

XEX_98EB_179:
    .BYTE $C0

.ORG $98F5

XEX_98F5_180:
    .BYTE $01, $55, $55, $55, $55, $55, $5F, $FC, $F3, $FF, $CF, $FC, $FF, $F3, $FF, $FF
    .BYTE $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FC

.ORG $9913

XEX_9913_181:
    .BYTE $C0

.ORG $991E

XEX_991E_182:
    .BYTE $55, $55, $55, $55, $55, $0F, $FC, $F3, $FF, $CF, $FC, $FF, $F3, $FF, $FF, $FF
    .BYTE $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FC

.ORG $993B

XEX_993B_183:
    .BYTE $C0

.ORG $9946

XEX_9946_184:
    .BYTE $15, $55, $55, $55, $50, $0F, $00, $F3, $C3, $CF, $00, $0F

.ORG $995D

XEX_995D_185:
    .BYTE $0C

.ORG $9963

XEX_9963_186:
    .BYTE $C0

.ORG $996E

XEX_996E_187:
    .BYTE $05, $55, $55, $55, $00, $0F, $00, $F3, $C3, $CF, $FF, $0F

.ORG $9985

XEX_9985_188:
    .BYTE $0C

.ORG $998B

XEX_998B_189:
    .BYTE $C0

.ORG $9996

XEX_9996_190:
    .BYTE $01, $55, $55, $54, $00, $0F, $00, $F3, $C3, $CF, $FF, $CF

.ORG $99AD

XEX_99AD_191:
    .BYTE $0C

.ORG $99B3

XEX_99B3_192:
    .BYTE $C0

.ORG $99BF

XEX_99BF_193:
    .BYTE $55, $55, $52, $AA, $8F, $F0, $F3, $FF, $C3, $FF, $CF, $2A, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AC

.ORG $99DB

XEX_99DB_194:
    .BYTE $C0

.ORG $99E7

XEX_99E7_195:
    .BYTE $55, $55, $4A, $AA, $8F, $F0, $F3, $FF, $00, $03, $CF, $2A, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AC

.ORG $9A03

XEX_9A03_196:
    .BYTE $C0

.ORG $9A0F

XEX_9A0F_197:
    .BYTE $55, $55, $4A, $AA, $8F, $F0, $F3, $FF, $F3, $FF, $CF, $2A, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AC

.ORG $9A2B

XEX_9A2B_198:
    .BYTE $C0

.ORG $9A36

XEX_9A36_199:
    .BYTE $01, $55, $55, $2A, $80, $0F, $00, $F3, $C3, $F3, $FF, $CF

.ORG $9A4D

XEX_9A4D_200:
    .BYTE $0C

.ORG $9A53

XEX_9A53_201:
    .BYTE $C0

.ORG $9A5E

XEX_9A5E_202:
    .BYTE $01, $55, $55, $2A, $00, $0F, $00, $F3, $C3, $F3, $FF, $0F

.ORG $9A75

XEX_9A75_203:
    .BYTE $0C

.ORG $9A7B

XEX_9A7B_204:
    .BYTE $C0

.ORG $9A86

XEX_9A86_205:
    .BYTE $05, $55, $FF, $2A

.ORG $9A9D

XEX_9A9D_206:
    .BYTE $0C

.ORG $9AA3

XEX_9AA3_207:
    .BYTE $C0

.ORG $9AAE

XEX_9AAE_208:
    .BYTE $05, $43, $FF, $EA, $2A, $AA, $AA, $0A, $AA, $02, $AA, $A8

.ORG $9AC5

XEX_9AC5_209:
    .BYTE $0C

.ORG $9ACB

XEX_9ACB_210:
    .BYTE $C0

.ORG $9AD6

XEX_9AD6_211:
    .BYTE $14, $0F, $FF, $CA, $8A, $AA, $AA, $2A, $AA, $82, $AA, $AA

.ORG $9AED

XEX_9AED_212:
    .BYTE $0C

.ORG $9AF3

XEX_9AF3_213:
    .BYTE $C0, $00, $00, $0F, $F0

.ORG $9AFE

XEX_9AFE_214:
    .BYTE $40, $0F, $FF, $FA, $8A, $AA, $AA, $2A, $AA, $82, $AA, $AA

.ORG $9B15

XEX_9B15_215:
    .BYTE $0C

.ORG $9B1B

XEX_9B1B_216:
    .BYTE $C0, $00, $00, $3C, $3C, $0C, $FC, $FC, $C0, $00, $00, $00, $3F, $C5, $C2, $A0
    .BYTE $0A, $00, $A8, $02, $A2, $80, $0A, $80

.ORG $9B3D

XEX_9B3D_217:
    .BYTE $0C

.ORG $9B43

XEX_9B43_218:
    .BYTE $C0, $00, $00, $33, $CC, $0C, $CC, $CC, $CC, $00, $00, $00, $3F, $01, $02, $A8
    .BYTE $0A, $00, $A0, $00, $A2, $80, $02, $80

.ORG $9B65

XEX_9B65_219:
    .BYTE $0C

.ORG $9B6B

XEX_9B6B_220:
    .BYTE $C0, $00, $00, $33, $0C, $0C, $FC, $FC, $CC, $00, $00, $00, $3F, $01, $40, $A8
    .BYTE $0A, $00, $A0, $00, $A2, $80, $02, $80

.ORG $9B8D

XEX_9B8D_221:
    .BYTE $0C

.ORG $9B93

XEX_9B93_222:
    .BYTE $C0, $00, $00, $33, $CC, $0C, $0C, $CC, $FC, $00, $00, $00, $3F, $00, $40, $AA
    .BYTE $0A, $00, $A0, $00, $A2, $80, $0A, $80

.ORG $9BB5

XEX_9BB5_223:
    .BYTE $0C

.ORG $9BBB

XEX_9BBB_224:
    .BYTE $C0, $00, $00, $3C, $3C, $0C, $3C, $FC, $0C, $00, $00, $00, $0F, $C0, $00, $2A
    .BYTE $0A, $00, $A0, $00, $A2, $AA, $AA

.ORG $9BDD

XEX_9BDD_225:
    .BYTE $0C

.ORG $9BE3

XEX_9BE3_226:
    .BYTE $C0, $00, $00, $0F, $F0

.ORG $9BEF

XEX_9BEF_227:
    .BYTE $0F, $C0, $00, $0A, $8A, $00, $AA, $AA, $A2, $AA, $AA

.ORG $9C05

XEX_9C05_228:
    .BYTE $0C

.ORG $9C0B

XEX_9C0B_229:
    .BYTE $C0

.ORG $9C17

XEX_9C17_230:
    .BYTE $03, $F0, $00, $0A, $8A, $00, $AA, $AA, $A2, $AA, $A8

.ORG $9C2D

XEX_9C2D_231:
    .BYTE $0C

.ORG $9C33

XEX_9C33_232:
    .BYTE $C0

.ORG $9C3F

XEX_9C3F_233:
    .BYTE $03, $FC, $00, $2A, $8A, $00, $AA, $AA, $A2, $80, $A0

.ORG $9C55

XEX_9C55_234:
    .BYTE $0C

.ORG $9C5B

XEX_9C5B_235:
    .BYTE $EA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $A8, $FC, $AA, $AA
    .BYTE $8A, $00, $A0, $00, $A2, $80, $A0

.ORG $9C7D

XEX_9C7D_236:
    .BYTE $0C

.ORG $9C83

XEX_9C83_237:
    .BYTE $EA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $A8, $FF, $AA, $AA
    .BYTE $0A, $00, $A0, $00, $A2, $80, $AA, $A2, $A2, $02

.ORG $9CA5

XEX_9CA5_238:
    .BYTE $0C

.ORG $9CAB

XEX_9CAB_239:
    .BYTE $EA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $3F, $2A, $A8
    .BYTE $0A, $00, $A0, $00, $A2, $80, $AA, $A0, $82, $8A

.ORG $9CCD

XEX_9CCD_240:
    .BYTE $0C

.ORG $9CD3

XEX_9CD3_241:
    .BYTE $C0

.ORG $9CE0

XEX_9CE0_242:
    .BYTE $3F

.ORG $9CE9

XEX_9CE9_243:
    .BYTE $2A, $A0, $82, $22

.ORG $9CF5

XEX_9CF5_244:
    .BYTE $0C

.ORG $9CFB

XEX_9CFB_245:
    .BYTE $C0

.ORG $9D08

XEX_9D08_246:
    .BYTE $3F, $3F, $3F, $3F, $30, $33, $F3, $F3, $C0

.ORG $9D1D

XEX_9D1D_247:
    .BYTE $0C

.ORG $9D23

XEX_9D23_248:
    .BYTE $C0

.ORG $9D30

XEX_9D30_249:
    .BYTE $FC, $33, $3F, $3F, $30, $33, $F3, $F3

.ORG $9D45

XEX_9D45_250:
    .BYTE $0C

.ORG $9D4B

XEX_9D4B_251:
    .BYTE $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FC, $33, $30
    .BYTE $0C, $33, $33, $33, $33, $CC, $FC, $F0

.ORG $9D6D

XEX_9D6D_252:
    .BYTE $0C

.ORG $9D73

XEX_9D73_253:
    .BYTE $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F0, $3F, $3F
    .BYTE $0C, $3F, $F3, $F3, $C3, $0C, $CC, $C0

.ORG $9D95

XEX_9D95_254:
    .BYTE $0C

.ORG $9D9B

XEX_9D9B_255:
    .BYTE $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $C0, $3F, $30
    .BYTE $0C, $3C, $F3, $33, $33, $CC, $CC, $F0

.ORG $9DBD

XEX_9DBD_256:
    .BYTE $0C

.ORG $9DC3

XEX_9DC3_257:
    .BYTE $C0

.ORG $9DE5

XEX_9DE5_258:
    .BYTE $0C

.ORG $9DEB

XEX_9DEB_259:
    .BYTE $3F, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .BYTE $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .BYTE $FF, $FF, $F0

.ORG $9E60

XEX_9E60_260:
    .BYTE $FC, $FC, $FC, $FC, $C0

.ORG $9E7C

XEX_9E7C_261:
    .BYTE $0C, $00, $00, $00, $3F, $3F, $3F, $3F, $30, $0C, $C3, $3F, $CC, $30, $CC, $CC
    .BYTE $C0, $33, $C0, $0F, $C0, $3F, $3F, $3F, $0C, $F0, $FC, $FC, $FC, $FC, $F0, $0F
    .BYTE $CF, $CF, $CF, $0F, $CC, $0C, $FC, $FC, $CC, $03, $F3, $F0, $33, $0C, $33, $33
    .BYTE $30, $0C, $F3, $30, $CC, $30, $CC, $CC, $C0, $33, $F0, $0C, $C0, $33, $30, $30
    .BYTE $0C, $FC, $30, $C0, $CC, $C0, $CC, $03, $0C, $CC, $CC, $CC, $0F, $3C, $CC, $CC
    .BYTE $F0, $03, $33, $00, $33, $0C, $33, $33, $30, $0C, $FF, $30, $FC, $30, $FC, $F0
    .BYTE $C0, $30, $30, $0F, $C0, $3C, $3C, $33, $CC, $0C, $30, $F0, $F0, $F0, $CC, $03
    .BYTE $0F, $0F, $CC, $CF, $0F, $FC, $FC, $F0, $CC, $03, $33, $C0, $3F, $0C, $3F, $3C
    .BYTE $30, $0C, $CF, $30, $CC, $30, $CC, $CC, $C0, $33, $F0, $0C, $C0, $33, $3F, $3F
    .BYTE $CC, $FC, $30, $FC, $CC, $FC, $F0, $03, $0C, $CC, $CF, $0F, $CC, $CC, $CC, $CC
    .BYTE $CC, $03, $F3, $00, $33, $0C, $33, $33, $30, $0C, $C3, $3F

.ORG $9F31

XEX_9F31_262:
    .BYTE $03

.ORG $9F38

XEX_9F38_263:
    .BYTE $0C, $00, $00, $00, $00, $C0

.ORG $9F43

XEX_9F43_264:
    .BYTE $0C

.ORG $9F50

XEX_9F50_265:
    .BYTE $48, $AD, $0B, $D4, $8D, $0A, $D4, $C9, $50, $90, $0C, $A9, $42, $8D, $17, $D0
    .BYTE $A9, $82, $8D, $18, $D0, $68, $40, $C9, $28, $90, $07, $A9, $47, $8D, $17, $D0
    .BYTE $68, $40, $C9, $10, $90, $0C, $A9, $0D, $8D, $16, $D0, $A9, $C6, $8D, $17, $D0
    .BYTE $68, $40, $A9, $DA, $8D, $16, $D0, $A9, $42, $8D, $17, $D0, $A9, $01, $8D, $18
    .BYTE $D0, $68, $40, $78, $A9, $00, $8D, $0E, $D4, $8D, $00, $D4, $8D, $2F, $02, $A9
    .BYTE $FE, $8D, $01, $D3, $A9, $21, $8D, $FA, $FF, $A9, $7F, $8D, $FB, $FF, $A9, $FF
    .BYTE $8D, $01, $D3, $A9, $2E, $8D, $30, $02, $A9, $7F, $8D, $31, $02, $A9, $04, $8D
    .BYTE $C8, $02, $A9, $50, $8D, $00, $02, $A9, $9F, $8D, $01, $02, $A9, $C0, $8D, $0E
    .BYTE $D4, $58, $A9, $22, $8D, $2F, $02, $A5, $14, $C5, $14, $F0, $FC, $60

.ORG $2000

XEX_2000_266:
    .BYTE $78, $A9, $80, $8D, $0E, $D4, $A9, $FE, $8D, $01, $D3, $A2, $00, $BD, $36, $20
    .BYTE $9D, $00, $BC, $E8, $D0, $F7, $EE, $0F, $20, $AC, $12, $20, $C8, $C0, $D0, $D0
    .BYTE $02, $A0, $E4, $8C, $12, $20, $C0, $00, $D0, $E3, $A9, $FF, $8D, $01, $D3, $A9
    .BYTE $C0, $8D, $0E, $D4, $58, $60, $78, $A9, $00, $8D, $0E, $D4, $D8, $A2, $FF, $9A
    .BYTE $A2, $12, $B5, $30, $9D, $00, $01, $CA, $10, $F8, $20, $27, $2F, $A9, $01, $8D
    .BYTE $4F, $03, $8D, $4D, $03, $8D, $53, $03, $8D, $51, $03, $A9, $00, $8D, $77, $03
    .BYTE $20, $94, $2F, $A2, $00, $A9, $00, $F0, $0F, $BD, $A1, $56, $DD, $80, $BB, $F0
    .BYTE $07, $86, $F0, $20, $62, $29, $A6, $F0, $BD, $A1, $56, $9D, $80, $BB, $E8, $E0
    .BYTE $42, $90, $E2, $A9, $01, $8D, $30, $0C, $20, $25, $29, $A2, $00, $86, $FC, $20
    .BYTE $F2, $23, $E6, $FC, $20, $F2, $23, $A2, $02, $20, $C2, $29, $A9, $01, $8D, $77
    .BYTE $03, $20, $A9, $89, $20, $C5, $2E, $20, $00, $82, $20, $11, $36, $A9, $01, $8D
    .BYTE $7D, $03, $8D, $7E, $03, $A9, $00, $8D, $9B, $B6, $A9, $10, $8D, $9C, $B6, $A9
    .BYTE $00, $8D, $9D, $03, $AD, $9D, $B6, $C9, $01, $A9, $00, $B0, $0B, $AD, $4E, $03
    .BYTE $C9, $02, $A9, $00, $B0, $02, $A9, $01, $8D, $9E, $03, $A9, $02, $8D, $77, $03
    .BYTE $AD, $9D, $B6, $F0, $3C, $10, $24, $A2, $00, $86, $55, $8E, $A0, $B6, $8E, $A1
    .BYTE $B6, $8E, $A2, $B6, $8E, $A3, $B6, $20, $06, $0E, $B1, $55, $9D, $A4, $B6, $E8
    .BYTE $20, $06, $0E, $B1, $55, $9D, $A4, $B6, $4C, $EB, $0C, $A9, $FF, $8D, $A0, $B6
    .BYTE $8D, $A1, $B6, $8D, $A2, $B6, $8D, $A3, $B6, $A9, $00, $8D, $9E, $B6, $8D, $9F
    .BYTE $B6, $AD, $81, $03, $F0, $05, $AD, $82, $03, $D0, $5F, $AD, $9D, $B6, $D0, $2D
    .BYTE $AD, $9B, $03, $29, $1F, $C9, $1F, $D0, $1A, $AD, $9C, $03, $29, $1F, $C9, $1F
    .BYTE $D0, $11, $AD, $99, $03, $D0, $16, $CE, $9B, $B6, $D0, $11, $CE, $9C, $B6, $D0
    .BYTE $0C, $F0, $37, $A9, $00, $8D, $9B, $B6, $A9, $10, $8D, $9C, $B6, $2C, $99, $03
    .BYTE $30, $28, $50, $2F, $A9, $00, $8D, $7D, $03, $8D, $7E, $03, $2C, $99, $03, $30
    .BYTE $19, $70, $F9, $2C, $99, $03, $30, $12, $50, $F9, $2C, $99, $03, $30, $0B, $70
    .BYTE $F9, $EE, $7D, $03, $EE, $7E, $03, $4C, $5D, $0D, $A9, $FF, $85, $AE, $85, $AF
    .BYTE $4C, $25, $0C, $A5, $76, $85, $77, $49, $01, $85, $76, $A5, $78, $30, $0D, $AA
    .BYTE $49, $01, $A8, $B5, $8C, $D9, $8C, $00, $8A, $B0, $01, $98, $85, $78, $A6, $76
    .BYTE $20, $6D, $37, $A9, $FF, $85, $3F, $BD, $3F, $03, $F0, $03, $DE, $3F, $03, $A9
    .BYTE $00, $85, $55, $AD, $9D, $B6, $30, $05, $D0, $2B, $4C, $13, $0E, $20, $F9, $0D
    .BYTE $B1, $55, $95, $FD, $38, $BD, $A4, $B6, $E9, $01, $B0, $13, $FE, $A0, $B6, $D0
    .BYTE $03, $FE, $A2, $B6, $20, $06, $0E, $B1, $55, $9D, $A4, $B6, $4C, $97, $0D, $9D
    .BYTE $A4, $B6, $4C, $13, $0E, $BD, $9B, $03, $29, $1F, $85, $12, $DD, $9E, $B6, $F0
    .BYTE $1C, $9D, $9E, $B6, $FE, $A0, $B6, $D0, $03, $FE, $A2, $B6, $20, $F9, $0D, $A5
    .BYTE $12, $91, $55, $20, $06, $0E, $A9, $01, $91, $55, $4C, $F6, $0D, $20, $06, $0E
    .BYTE $18, $B1, $55, $69, $01, $90, $03, $4C, $CE, $0D, $91, $55, $4C, $13, $0E, $18
    .BYTE $BD, $A3, $67, $7D, $A2, $B6, $85, $56, $BC, $A0, $B6, $60, $18, $BD, $A5, $67
    .BYTE $7D, $A2, $B6, $85, $56, $BC, $A0, $B6, $60, $BD, $9D, $03, $F0, $0E, $AD, $D7
    .BYTE $03, $D0, $03, $20, $36, $39, $BD, $9F, $03, $4C, $2E, $0E, $BD, $9B, $03, $AC
    .BYTE $9D, $B6, $30, $02, $95, $FD, $EA, $BD, $81, $03, $F0, $08, $A0, $10, $20, $94
    .BYTE $2E, $4C, $21, $17, $BD, $2C, $03, $F0, $4A, $A9, $00, $95, $CC, $A0, $10, $20
    .BYTE $94, $2E, $DE, $66, $03, $D0, $39, $A9, $00, $9D, $2C, $03, $95, $8A, $95, $88
    .BYTE $9D, $46, $03, $95, $A8, $A9, $FF, $95, $A6, $20, $37, $2B, $A9, $0E, $95, $35
    .BYTE $95, $37, $A9, $0C, $95, $8C, $18, $75, $CA, $95, $31, $95, $33, $A9, $00, $A4
    .BYTE $77, $D9, $90, $00, $D0, $02, $A9, $01, $95, $90, $20, $8F, $25, $4C, $8D, $0E
    .BYTE $4C, $EB, $0C, $BD, $7F, $03, $F0, $0D, $10, $03, $4C, $2D, $0F, $A9, $81, $9D
    .BYTE $7F, $03, $4C, $E4, $0E, $BD, $4A, $03, $F0, $13, $DE, $4A, $03, $BD, $48, $03
    .BYTE $D5, $90, $D0, $09, $BD, $4A, $03, $C9, $01, $F0, $2A, $D0, $12, $A4, $77, $B9
    .BYTE $48, $03, $D5, $90, $D0, $3A, $B9, $4A, $03, $F0, $35, $C9, $01, $F0, $16, $85
    .BYTE $12, $29, $03, $C9, $03, $D0, $29, $A5, $12, $4A, $4A, $29, $01, $18, $69, $12
    .BYTE $95, $00, $4C, $FA, $0E, $A9, $04, $20, $72, $2A, $A9, $C0, $95, $B6, $A9, $00
    .BYTE $9D, $57, $03, $A9, $01, $95, $B4, $20, $95, $38, $20, $8F, $25, $4C, $2D, $0F
    .BYTE $BD, $57, $03, $F0, $1D, $B5, $FD, $29, $10, $D0, $0C, $9D, $57, $03, $20, $8F
    .BYTE $25, $20, $83, $2B, $4C, $1C, $0F, $A0, $0B, $20, $94, $2E, $20, $3B, $2C, $4C
    .BYTE $21, $17, $B5, $B4, $10, $0D, $A0, $0A, $20, $94, $2E, $A9, $00, $8D, $0E, $36
    .BYTE $4C, $BB, $37, $B5, $B6, $85, $12, $24, $12, $30, $05, $D0, $06, $4C, $62, $11
    .BYTE $4C, $E7, $0F, $C9, $02, $90, $30, $D6, $BA, $10, $1C, $A9, $03, $95, $BA, $D6
    .BYTE $BC, $10, $08, $D6, $B6, $20, $8F, $25, $4C, $71, $0F, $B4, $BC, $B9, $21, $51
    .BYTE $95, $BE, $B9, $2A, $51, $95, $00, $B5, $BC, $0A, $85, $12, $18, $8A, $65, $12
    .BYTE $A8, $B9, $33, $51, $4C, $79, $16, $D6, $BA, $10, $06, $A9, $01, $95, $BA, $D6
    .BYTE $8A, $38, $B5, $CA, $E9, $0E, $85, $12, $18, $B5, $CA, $75, $8C, $18, $75, $8A
    .BYTE $C5, $12, $B0, $4A, $18, $B5, $8C, $69, $0E, $20, $71, $38, $A9, $00, $95, $B6
    .BYTE $20, $58, $1C, $A5, $77, $85, $FC, $20, $F2, $23, $A6, $76, $A9, $FF, $85, $FC
    .BYTE $A9, $90, $9D, $66, $03, $FE, $2C, $03, $BD, $7F, $03, $F0, $1E, $9D, $81, $03
    .BYTE $A0, $12, $BD, $61, $67, $85, $2E, $A9, $14, $85, $2F, $A9, $67, $85, $1C, $A9
    .BYTE $67, $85, $1D, $AC, $75, $67, $20, $B6, $23, $A6, $76, $4C, $21, $17, $A9, $10
    .BYTE $95, $00, $B5, $BA, $29, $01, $18, $7D, $11, $51, $4C, $79, $16, $70, $03, $4C
    .BYTE $73, $10, $B5, $B6, $29, $BF, $95, $B6, $BD, $9F, $64, $95, $AE, $A9, $08, $95
    .BYTE $BC, $A9, $0C, $95, $BA, $A5, $FC, $30, $28, $B5, $F8, $D0, $06, $A6, $77, $B5
    .BYTE $F8, $F0, $03, $20, $11, $25, $A2, $00, $86, $F8, $86, $F9, $E8, $86, $F7, $A6
    .BYTE $78, $20, $98, $1C, $A5, $78, $49, $01, $AA, $20, $98, $1C, $A6, $76, $4C, $41
    .BYTE $10, $A6, $76, $B5, $F8, $F0, $10, $20, $11, $25, $20, $98, $1C, $A6, $76, $A9
    .BYTE $00, $95, $F8, $A9, $01, $85, $F7, $B5, $B6, $29, $07, $C9, $01, $D0, $0E, $18
    .BYTE $B5, $7A, $69, $06, $95, $7A, $A9, $02, $95, $BA, $4C, $4D, $11, $20, $EF, $20
    .BYTE $A0, $00, $A5, $FC, $30, $0D, $B5, $B6, $29, $07, $C9, $02, $90, $05, $C9, $05
    .BYTE $B0, $01, $C8, $8C, $62, $03, $4C, $4D, $11, $D6, $BA, $30, $03, $4C, $4D, $11
    .BYTE $B5, $AE, $30, $20, $A4, $77, $A9, $28, $99, $3F, $03, $A9, $FF, $95, $AE, $B5
    .BYTE $B6, $29, $07, $A8, $B9, $D4, $59, $95, $00, $C0, $01, $D0, $07, $D6, $BC, $A9
    .BYTE $FF, $4C, $B7, $13, $B5, $B6, $29, $07, $C9, $01, $D0, $26, $A9, $00, $95, $BA
    .BYTE $B5, $BC, $C9, $07, $D0, $03, $4C, $EE, $13, $A9, $0F, $95, $00, $A9, $84, $85
    .BYTE $BE, $38, $B5, $7A, $E9, $06, $95, $7A, $A9, $00, $95, $9A, $20, $99, $37, $4C
    .BYTE $E9, $10, $D6, $BC, $10, $25, $A9, $00, $8D, $62, $03, $B5, $B6, $29, $07, $C9
    .BYTE $02, $D0, $0C, $A9, $04, $95, $BE, $A9, $08, $95, $BC, $A9, $02, $D0, $02, $A9
    .BYTE $01, $95, $B6, $95, $BA, $20, $8F, $25, $4C, $4D, $11, $A9, $02, $95, $BA, $B5
    .BYTE $B6, $29, $07, $C9, $03, $D0, $0A, $B5, $BC, $29, $01, $F0, $04, $A9, $09, $95
    .BYTE $00, $B5, $B6, $29, $07, $D0, $04, $A0, $82, $84, $BE, $0A, $0A, $0A, $18, $75
    .BYTE $BC, $A8, $A9, $00, $85, $5A, $85, $16, $85, $17, $C0, $20, $90, $17, $C0, $28
    .BYTE $B0, $13, $B9, $EA, $59, $85, $16, $B9, $F2, $59, $85, $17, $98, $29, $01, $F0
    .BYTE $04, $A9, $09, $95, $00, $B5, $88, $85, $2F, $B5, $8C, $85, $30, $B9, $DA, $59
    .BYTE $20, $B3, $22, $B5, $7A, $C9, $04, $90, $02, $A9, $01, $18, $7D, $0D, $51, $A8
    .BYTE $B9, $03, $51, $95, $98, $4C, $79, $16, $BD, $3F, $03, $F0, $0A, $29, $02, $4A
    .BYTE $18, $7D, $13, $51, $4C, $79, $16, $B5, $CC, $F0, $0E, $D5, $7A, $D0, $03, $4C
    .BYTE $EE, $13, $95, $7A, $A9, $FF, $4C, $B7, $13, $B5, $28, $D0, $04, $A9, $01, $95
    .BYTE $B4, $B5, $28, $10, $35, $B5, $FD, $29, $10, $D0, $39, $A9, $01, $95, $28, $A5
    .BYTE $FC, $30, $03, $4C, $38, $13, $B5, $AE, $C9, $FF, $D0, $17, $B5, $FD, $29, $0F
    .BYTE $A8, $B9, $E3, $50, $C9, $FF, $D0, $0B, $D6, $B4, $10, $18, $A9, $80, $95, $B4
    .BYTE $4C, $BB, $37, $A9, $01, $95, $B4, $4C, $CE, $11, $B5, $FD, $29, $10, $F0, $04
    .BYTE $A9, $80, $95, $28, $BD, $2E, $03, $C9, $0A, $90, $1B, $A9, $00, $9D, $2E, $03
    .BYTE $A9, $05, $20, $72, $2A, $A6, $77, $A9, $28, $9D, $3F, $03, $A9, $00, $20, $72
    .BYTE $2A, $A6, $76, $4C, $E9, $10, $B5, $A6, $10, $1B, $BD, $2E, $03, $F0, $0B, $D6
    .BYTE $A2, $D0, $07, $DE, $2E, $03, $A9, $19, $95, $A2, $A5, $FC, $30, $04, $B5, $28
    .BYTE $10, $03, $4C, $38, $13, $18, $A5, $88, $69, $19, $85, $15, $18, $A5, $89, $69
    .BYTE $19, $38, $E5, $15, $85, $02, $B0, $0B, $A9, $02, $85, $AA, $A9, $00, $85, $AB
    .BYTE $4C, $35, $12, $A9, $00, $85, $AA, $A9, $02, $85, $AB, $A5, $02, $10, $05, $49
    .BYTE $FF, $18, $69, $01, $85, $02, $B5, $A6, $10, $15, $B5, $28, $29, $01, $F0, $0F
    .BYTE $A9, $00, $95, $28, $A9, $FF, $85, $12, $A9, $01, $95, $A4, $4C, $F0, $12, $A9
    .BYTE $00, $95, $9A, $B5, $AA, $95, $7A, $B5, $A6, $30, $14, $D6, $A8, $F0, $05, $B5
    .BYTE $A6, $4C, $13, $13, $A9, $FF, $95, $A6, $B5, $28, $10, $03, $4C, $38, $13, $B5
    .BYTE $FD, $29, $0F, $A8, $B9, $45, $51, $85, $12, $F0, $69, $D5, $A4, $F0, $65, $B4
    .BYTE $A4, $95, $A4, $38, $98, $F0, $5D, $F5, $A4, $B0, $04, $49, $FF, $69, $01, $C9
    .BYTE $02, $D0, $51, $B5, $A4, $F0, $4D, $0A, $0A, $18, $75, $AA, $86, $15, $18, $65
    .BYTE $15, $A8, $B9, $69, $51, $C9, $FF, $F0, $3B, $85, $15, $B9, $7D, $51, $85, $17
    .BYTE $20, $16, $13, $90, $2F, $A4, $77, $B9, $A6, $00, $C5, $15, $F0, $26, $A5, $15
    .BYTE $99, $A6, $00, $A9, $06, $99, $A8, $00, $A9, $19, $99, $A2, $00, $A9, $0F, $99
    .BYTE $00, $00, $18, $B9, $2E, $03, $69, $01, $99, $2E, $03, $A6, $77, $A9, $07, $20
    .BYTE $72, $2A, $A6, $76, $A5, $12, $0A, $0A, $18, $75, $AA, $86, $15, $18, $65, $15
    .BYTE $A8, $B9, $55, $51, $D5, $A0, $F0, $11, $A5, $12, $30, $06, $F0, $09, $A9, $0E
    .BYTE $95, $00, $B9, $55, $51, $95, $A0, $B5, $A0, $4C, $79, $16, $A4, $77, $38, $B5
    .BYTE $8C, $F9, $8C, $00, $B0, $04, $49, $FF, $69, $01, $C9, $03, $B0, $0E, $B5, $8C
    .BYTE $4A, $29, $FE, $05, $17, $A8, $B9, $91, $51, $C5, $02, $60, $18, $60, $B5, $FD
    .BYTE $29, $0F, $A8, $B9, $E3, $50, $C9, $FF, $F0, $17, $85, $12, $A9, $01, $95, $B4
    .BYTE $A5, $12, $D5, $7A, $D0, $47, $B4, $9A, $F0, $43, $A9, $FF, $95, $98, $4C, $EE
    .BYTE $13, $B5, $7A, $C9, $04, $90, $02, $A9, $01, $18, $7D, $0D, $51, $A8, $B9, $03
    .BYTE $51, $95, $98, $95, $39, $B5, $88, $85, $CE, $85, $2A, $B5, $8C, $85, $D0, $85
    .BYTE $2B, $B5, $8A, $85, $CF, $20, $DF, $36, $C9, $85, $D0, $0E, $29, $07, $85, $14
    .BYTE $AC, $72, $57, $B1, $20, $10, $03, $4C, $65, $15, $4C, $7B, $16, $B4, $7A, $95
    .BYTE $7A, $A9, $FF, $C0, $04, $B0, $16, $98, $0A, $0A, $18, $75, $7A, $A8, $B9, $F3
    .BYTE $50, $C9, $FF, $F0, $08, $18, $7D, $0D, $51, $A8, $B9, $03, $51, $85, $3F, $A9
    .BYTE $FF, $95, $98, $95, $9A, $18, $B4, $7A, $B9, $B3, $51, $85, $18, $B9, $BF, $51
    .BYTE $85, $19, $A0, $00, $B1, $18, $95, $7C, $A9, $00, $95, $7E, $C8, $18, $B1, $18
    .BYTE $7D, $0B, $51, $95, $80, $C8, $B1, $18, $95, $82, $C8, $B1, $18, $95, $84, $C8
    .BYTE $B1, $18, $95, $86, $B5, $98, $C9, $FF, $F0, $03, $4C, $79, $16, $A5, $3F, $C9
    .BYTE $FF, $F0, $03, $4C, $79, $16, $D6, $7E, $10, $04, $B5, $7C, $95, $7E, $B4, $86
    .BYTE $B9, $43, $52, $85, $18, $B9, $48, $52, $85, $19, $B4, $7E, $18, $B5, $8C, $71
    .BYTE $18, $10, $04, $A9, $00, $F0, $06, $C9, $19, $90, $02, $A9, $18, $85, $D0, $B4
    .BYTE $82, $B9, $07, $52, $85, $18, $B9, $0C, $52, $85, $19, $B4, $7E, $18, $B5, $88
    .BYTE $71, $18, $10, $1B, $C9, $E7, $B0, $32, $AC, $6D, $57, $A9, $15, $85, $CE, $20
    .BYTE $40, $1B, $D0, $28, $A9, $0E, $20, $84, $38, $20, $B3, $1B, $4C, $76, $14, $C9
    .BYTE $1A, $90, $17, $AC, $6E, $57, $A9, $EB, $85, $CE, $20, $40, $1B, $D0, $0D, $A9
    .BYTE $F2, $20, $84, $38, $20, $B3, $1B, $4C, $76, $14, $85, $CE, $B4, $84, $B9, $25
    .BYTE $52, $85, $18, $B9, $2A, $52, $85, $19, $B4, $7E, $18, $B5, $8A, $71, $18, $B4
    .BYTE $CC, $F0, $28, $85, $12, $A9, $04, $24, $12, $30, $02, $A9, $05, $95, $9E, $A5
    .BYTE $12, $C0, $05, $F0, $3C, $A8, $30, $06, $C9, $05, $B0, $77, $90, $5E, $C9, $F2
    .BYTE $90, $0C, $AC, $71, $57, $B1, $20, $10, $0D, $A5, $12, $4C, $1D, $15, $AC, $71
    .BYTE $57, $20, $40, $1B, $F0, $0B, $A9, $05, $95, $CC, $A5, $12, $85, $CF, $4C, $1F
    .BYTE $15, $20, $B3, $1B, $A9, $01, $9D, $46, $03, $A9, $18, $20, $6A, $38, $4C, $1D
    .BYTE $15, $A8, $10, $06, $C9, $FD, $90, $3B, $B0, $22, $C9, $18, $90, $35, $AC, $72
    .BYTE $57, $20, $40, $1B, $F0, $07, $A9, $04, $95, $CC, $4C, $1F, $15, $20, $B3, $1B
    .BYTE $A9, $00, $9D, $46, $03, $A9, $F2, $20, $6A, $38, $D0, $17, $18, $A5, $D0, $69
    .BYTE $05, $C9, $19, $90, $02, $A9, $18, $85, $D0, $A9, $01, $95, $7A, $A9, $00, $95
    .BYTE $CC, $95, $9A, $85, $CF, $20, $5B, $1B, $A5, $CE, $85, $2A, $A5, $D0, $85, $2B
    .BYTE $20, $DF, $36, $85, $12, $B5, $CC, $F0, $03, $4C, $47, $16, $A9, $FF, $95, $9E
    .BYTE $A5, $12, $F0, $24, $10, $1F, $C9, $FF, $F0, $1B, $C9, $80, $90, $17, $29, $07
    .BYTE $C9, $06, $F0, $14, $A8, $84, $14, $B9, $6D, $57, $A8, $B1, $20, $30, $0C, $A4
    .BYTE $14, $C0, $04, $B0, $03, $4C, $1F, $16, $4C, $36, $16, $A4, $14, $98, $95, $9E
    .BYTE $C0, $02, $B0, $03, $4C, $08, $16, $C0, $04, $90, $47, $A5, $FC, $30, $0A, $A4
    .BYTE $77, $B9, $CC, $00, $F0, $1A, $4C, $1F, $16, $B9, $6D, $57, $A8, $B1, $20, $29
    .BYTE $7F, $A4, $77, $D9, $90, $00, $D0, $08, $B9, $CC, $00, $F0, $03, $4C, $1F, $16
    .BYTE $B5, $7A, $C9, $06, $B0, $F7, $B5, $CC, $F0, $03, $4C, $47, $16, $A5, $14, $95
    .BYTE $CC, $A8, $B9, $E3, $56, $85, $D0, $B9, $73, $57, $A8, $B1, $20, $85, $CE, $4C
    .BYTE $47, $16, $C0, $02, $D0, $29, $B5, $90, $CD, $63, $03, $D0, $22, $B5, $AE, $C9
    .BYTE $0A, $D0, $0D, $A0, $04, $B9, $3A, $03, $30, $06, $88, $D0, $F8, $4C, $36, $17
    .BYTE $A9, $C1, $95, $B6, $9D, $64, $03, $A9, $04, $20, $72, $2A, $4C, $1F, $16, $B9
    .BYTE $9D, $57, $85, $D0, $B9, $6D, $57, $A8, $20, $40, $1B, $D0, $28, $20, $B3, $1B
    .BYTE $18, $A5, $D0, $75, $CA, $69, $0A, $95, $31, $95, $33, $4C, $47, $16, $C0, $01
    .BYTE $B9, $79, $57, $A8, $B1, $20, $90, $08, $18, $69, $04, $95, $94, $4C, $47, $16
    .BYTE $95, $92, $4C, $47, $16, $B5, $7A, $C9, $06, $90, $02, $D6, $BC, $18, $B5, $7A
    .BYTE $7D, $0D, $51, $A8, $B9, $03, $51, $95, $98, $4C, $79, $16, $A9, $00, $95, $94
    .BYTE $95, $92, $20, $73, $37, $F0, $06, $20, $8F, $25, $20, $6D, $37, $A5, $CE, $95
    .BYTE $88, $A5, $CF, $95, $8A, $A5, $D0, $95, $8C, $B4, $80, $B9, $61, $52, $85, $18
    .BYTE $B9, $6D, $52, $85, $19, $B4, $7E, $C0, $04, $F0, $08, $C0, $03, $F0, $04, $C0
    .BYTE $01, $D0, $0A, $B5, $00, $C9, $12, $F0, $04, $A9, $01, $95, $00, $B1, $18, $95
    .BYTE $39, $B5, $F8, $F0, $0B, $20, $11, $25, $A9, $00, $95, $F8, $A9, $01, $85, $F7
    .BYTE $B5, $B6, $10, $1C, $29, $07, $C9, $01, $D0, $48, $38, $B5, $7A, $E9, $06, $29
    .BYTE $07, $0A, $86, $12, $18, $65, $12, $A8, $B9, $15, $51, $95, $39, $4C, $AA, $16
    .BYTE $B5, $8A, $F0, $0B, $C9, $80, $A9, $00, $B0, $05, $18, $B5, $CA, $69, $11, $95
    .BYTE $96, $B5, $AE, $C9, $08, $D0, $12, $B5, $B0, $95, $D9, $38, $B5, $B2, $E9, $0D
    .BYTE $95, $DD, $A9, $0A, $95, $00, $20, $3C, $21, $20, $98, $1C, $AD, $D7, $03, $F0
    .BYTE $01, $60, $A6, $76, $B5, $B6, $30, $3E, $B5, $88, $85, $CE, $B5, $8C, $85, $D0
    .BYTE $B5, $28, $29, $01, $F0, $10, $20, $43, $17, $F0, $2B, $20, $43, $17, $F0, $26
    .BYTE $20, $95, $38, $4C, $20, $17, $20, $43, $17, $F0, $05, $20, $43, $17, $D0, $12
    .BYTE $B5, $9C, $D0, $12, $A9, $01, $95, $9C, $A9, $06, $95, $00, $A9, $02, $95, $BE
    .BYTE $D0, $04, $A9, $00, $95, $9C, $EA, $A5, $F7, $D0, $0A, $A0, $03, $A2, $00, $CA
    .BYTE $D0, $FD, $88, $D0, $FA, $A9, $00, $85, $F7, $4C, $EB, $0C, $A6, $76, $20, $C2
    .BYTE $29, $A2, $03, $20, $C2, $29, $4C, $29, $7A, $B4, $7A, $18, $A5, $CE, $79, $9F
    .BYTE $51, $85, $CE, $18, $69, $19, $10, $02, $A9, $00, $C9, $33, $90, $02, $A9, $32
    .BYTE $85, $2F, $18, $A5, $D0, $79, $A9, $51, $85, $D0, $10, $02, $A9, $00, $C9, $19
    .BYTE $90, $02, $A9, $18, $85, $30, $A9, $00, $85, $1E, $18, $A9, $92, $75, $8E, $85
    .BYTE $1F, $A4, $2F, $B9, $B5, $68, $A8, $18, $B9, $9E, $68, $A4, $30, $79, $85, $68
    .BYTE $A8, $B1, $1E, $9D, $A1, $03, $F0, $0F, $C9, $FF, $F0, $0B, $85, $14, $B5, $28
    .BYTE $29, $01, $D0, $06, $A9, $00, $60, $A9, $01, $60, $A5, $14, $C9, $80, $B0, $07
    .BYTE $A4, $FC, $10, $F3, $4C, $45, $19, $29, $07, $A8, $C0, $06, $90, $01, $88, $84
    .BYTE $14, $B9, $6D, $57, $A8, $B1, $20, $C9, $80, $29, $7F, $A8, $20, $1A, $29, $90
    .BYTE $03, $4C, $8C, $18, $A4, $14, $C0, $02, $D0, $2C, $B5, $90, $CD, $63, $03, $D0
    .BYTE $25, $B5, $AE, $C9, $0A, $D0, $0D, $A0, $04, $B9, $3A, $03, $30, $06, $88, $D0
    .BYTE $F8, $4C, $F3, $18, $A9, $C1, $95, $B6, $9D, $64, $03, $20, $95, $38, $A9, $04
    .BYTE $20, $72, $2A, $4C, $F3, $18, $A4, $14, $B9, $7F, $57, $A8, $B1, $20, $29, $F0
    .BYTE $F0, $4B, $85, $12, $C9, $60, $D0, $08, $B5, $AE, $C9, $02, $D0, $10, $F0, $20
    .BYTE $B5, $AE, $B0, $06, $C9, $01, $D0, $06, $F0, $16, $C9, $03, $F0, $12, $A5, $12
    .BYTE $4A, $4A, $4A, $4A, $38, $E9, $04, $09, $C0, $95, $B6, $A9, $04, $20, $72, $2A
    .BYTE $B1, $20, $29, $0F, $91, $20, $A4, $14, $B9, $97, $57, $A8, $B1, $22, $29, $0F
    .BYTE $91, $22, $20, $95, $38, $A9, $03, $20, $72, $2A, $4C, $F3, $18, $A4, $14, $C0
    .BYTE $04, $B0, $2F, $B5, $AE, $C9, $08, $F0, $04, $C9, $06, $D0, $25, $0A, $0A, $0A
    .BYTE $0A, $85, $12, $B9, $7F, $57, $A8, $B1, $20, $05, $12, $91, $20, $A4, $14, $B9
    .BYTE $97, $57, $A8, $B1, $22, $05, $12, $91, $22, $20, $95, $38, $20, $EC, $38, $4C
    .BYTE $12, $1A, $B5, $90, $CD, $63, $03, $D0, $2B, $A4, $14, $C0, $02, $D0, $25, $B5
    .BYTE $AE, $C9, $0A, $D0, $0D, $A0, $04, $B9, $3A, $03, $30, $06, $88, $D0, $F8, $4C
    .BYTE $F3, $18, $A9, $C1, $95, $B6, $9D, $64, $03, $20, $95, $38, $A9, $04, $20, $72
    .BYTE $2A, $4C, $F3, $18, $B5, $9E, $C5, $14, $D0, $03, $4C, $42, $19, $A5, $FC, $30
    .BYTE $08, $A4, $77, $B9, $9E, $00, $4C, $EB, $18, $A4, $14, $B9, $6D, $57, $A8, $B1
    .BYTE $20, $29, $7F, $A4, $77, $D9, $90, $00, $D0, $0B, $B9, $9E, $00, $A8, $B9, $A3
    .BYTE $57, $C5, $14, $F0, $53, $A9, $02, $95, $00, $A4, $14, $C0, $02, $D0, $07, $B5
    .BYTE $90, $CD, $63, $03, $F0, $0A, $B9, $85, $57, $A8, $B1, $22, $49, $80, $91, $22
    .BYTE $A4, $14, $B9, $6D, $57, $A8, $B1, $20, $49, $80, $91, $20, $29, $7F, $A4, $77
    .BYTE $D9, $90, $00, $D0, $23, $B9, $2C, $03, $19, $81, $03, $19, $57, $03, $D0, $18
    .BYTE $A5, $FC, $10, $14, $A4, $14, $C0, $02, $D0, $07, $B5, $90, $CD, $63, $03, $F0
    .BYTE $07, $A6, $77, $20, $8F, $25, $A6, $76, $4C, $12, $1A, $A8, $88, $84, $14, $B9
    .BYTE $69, $57, $A8, $B1, $20, $10, $38, $29, $07, $38, $E9, $04, $C9, $04, $90, $02
    .BYTE $E9, $01, $D5, $AE, $D0, $0F, $A9, $00, $91, $20, $20, $95, $38, $A9, $03, $20
    .BYTE $72, $2A, $4C, $DC, $19, $B1, $20, $38, $29, $07, $E9, $04, $09, $C0, $95, $B6
    .BYTE $A9, $00, $91, $20, $20, $95, $38, $A9, $04, $20, $72, $2A, $4C, $12, $1A, $B5
    .BYTE $AE, $30, $4F, $C9, $07, $F0, $30, $C9, $04, $F0, $32, $C9, $05, $F0, $2E, $A4
    .BYTE $14, $8C, $41, $03, $B9, $66, $57, $A8, $B1, $20, $29, $03, $C9, $02, $D0, $09
    .BYTE $B5, $AE, $C9, $0A, $90, $0B, $4C, $12, $1A, $20, $1D, $1A, $30, $03, $4C, $12
    .BYTE $1A, $20, $95, $38, $4C, $DC, $19, $20, $01, $37, $4C, $12, $1A, $A4, $14, $B9
    .BYTE $69, $57, $A8, $B5, $AE, $09, $80, $91, $20, $20, $95, $38, $20, $EC, $38, $4C
    .BYTE $12, $1A, $A4, $14, $B9, $66, $57, $A8, $B1, $20, $85, $12, $49, $80, $91, $20
    .BYTE $A5, $14, $8D, $41, $03, $20, $1D, $1A, $30, $03, $4C, $09, $1A, $A5, $12, $29
    .BYTE $03, $F0, $11, $C9, $02, $D0, $0D, $A5, $12, $4A, $4A, $29, $03, $95, $AE, $A9
    .BYTE $04, $4C, $10, $1A, $A9, $03, $95, $00, $20, $8F, $25, $20, $6D, $37, $A9, $00
    .BYTE $95, $28, $60, $A0, $00, $B5, $90, $D9, $30, $03, $D0, $08, $AD, $41, $03, $D9
    .BYTE $35, $03, $F0, $10, $C8, $C0, $05, $90, $EC, $B5, $AE, $30, $04, $C9, $0A, $B0
    .BYTE $70, $A9, $FF, $60, $98, $8D, $42, $03, $D0, $10, $A0, $04, $B9, $3A, $03, $30
    .BYTE $03, $20, $5A, $1A, $88, $D0, $F5, $4C, $85, $1A, $20, $5A, $1A, $4C, $85, $1A
    .BYTE $8C, $43, $03, $88, $B5, $AC, $19, $9B, $64, $95, $AC, $A6, $77, $B5, $AC, $39
    .BYTE $9B, $64, $F0, $0D, $49, $FF, $35, $AC, $95, $AC, $A6, $76, $A9, $02, $20, $72
    .BYTE $2A, $A6, $76, $AC, $43, $03, $60, $A9, $04, $95, $00, $A9, $04, $95, $00, $B4
    .BYTE $AE, $30, $07, $C0, $0A, $B0, $1A, $20, $95, $38, $18, $AD, $42, $03, $69, $0A
    .BYTE $95, $AE, $AC, $42, $03, $8A, $09, $80, $99, $35, $03, $20, $29, $1B, $A9, $01
    .BYTE $60, $38, $B5, $AE, $E9, $0A, $A8, $B5, $90, $99, $30, $03, $AD, $41, $03, $99
    .BYTE $35, $03, $20, $C9, $1A, $20, $29, $1B, $A9, $FF, $95, $AE, $A9, $01, $60, $A0
    .BYTE $04, $AD, $30, $03, $D9, $30, $03, $D0, $0D, $AD, $35, $03, $D9, $35, $03, $D0
    .BYTE $05, $A9, $01, $99, $3A, $03, $88, $D0, $E8, $A0, $04, $B9, $3A, $03, $30, $3E
    .BYTE $88, $D0, $F8, $AC, $63, $03, $B9, $C9, $57, $85, $55, $B9, $ED, $57, $85, $56
    .BYTE $AC, $6F, $57, $B1, $55, $C9, $FF, $D0, $25, $AD, $63, $03, $91, $55, $A5, $FC
    .BYTE $10, $1C, $A4, $77, $B9, $81, $03, $19, $2C, $03, $19, $57, $03, $D0, $0F, $B9
    .BYTE $90, $00, $CD, $63, $03, $D0, $07, $A6, $77, $20, $8F, $25, $A6, $76, $60, $A0
    .BYTE $04, $B9, $3A, $03, $30, $0C, $AD, $30, $03, $99, $30, $03, $AD, $35, $03, $99
    .BYTE $35, $03, $88, $D0, $EC, $60, $84, $14, $A4, $77, $B9, $2C, $03, $19, $81, $03
    .BYTE $D0, $62, $A4, $14, $B1, $20, $29, $7F, $A4, $77, $D9, $90, $00, $F0, $08, $D0
    .BYTE $53, $84, $14, $A5, $FC, $30, $4D, $B5, $B6, $F0, $08, $10, $47, $29, $07, $C9
    .BYTE $01, $F0, $41, $A4, $77, $18, $A5, $CE, $69, $19, $85, $2F, $18, $B9, $88, $00
    .BYTE $69, $19, $85, $13, $38, $A5, $2F, $E5, $13, $B0, $04, $49, $FF, $69, $01, $C9
    .BYTE $05, $B0, $21, $38, $A5, $D0, $F9, $8C, $00, $B0, $04, $49, $FF, $69, $01, $C9
    .BYTE $02, $B0, $11, $B5, $88, $85, $CE, $B5, $8C, $85, $D0, $B5, $8A, $85, $CF, $A4
    .BYTE $14, $A9, $01, $60, $A4, $14, $A9, $00, $60, $B5, $AE, $C9, $08, $D0, $09, $A9
    .BYTE $FF, $95, $AE, $95, $D1, $20, $3C, $21, $B1, $20, $29, $7F, $95, $90, $20, $4F
    .BYTE $2B, $BD, $E4, $69, $85, $1A, $BD, $E6, $69, $85, $1B, $B4, $90, $A9, $01, $91
    .BYTE $1A, $A4, $77, $B5, $90, $D9, $90, $00, $D0, $0D, $B9, $2C, $03, $D0, $08, $BD
    .BYTE $2C, $03, $D0, $03, $4C, $FA, $1B, $20, $58, $1C, $20, $8F, $25, $4C, $6D, $37
    .BYTE $A5, $77, $85, $FC, $A2, $00, $20, $95, $38, $A2, $01, $20, $95, $38, $A9, $01
    .BYTE $85, $B4, $85, $B5, $A9, $00, $85, $28, $85, $29, $8D, $57, $03, $8D, $58, $03
    .BYTE $85, $F8, $85, $F9, $A6, $76, $20, $90, $24, $20, $F2, $23, $A6, $76, $20, $8F
    .BYTE $25, $A4, $77, $A6, $76, $B9, $8E, $00, $95, $8E, $B9, $81, $68, $95, $CA, $18
    .BYTE $B5, $31, $7D, $83, $68, $95, $31, $18, $B5, $33, $7D, $83, $68, $95, $33, $A5
    .BYTE $8C, $C5, $8D, $A9, $00, $B0, $02, $A9, $01, $85, $78, $85, $79, $60, $A5, $FC
    .BYTE $10, $01, $60, $C5, $76, $D0, $07, $A6, $77, $A9, $00, $4C, $6C, $1C, $A6, $76
    .BYTE $A9, $01, $85, $12, $A9, $FF, $85, $78, $85, $FC, $BD, $81, $68, $95, $CA, $8A
    .BYTE $95, $8E, $38, $B5, $31, $FD, $83, $68, $95, $31, $38, $B5, $33, $FD, $83, $68
    .BYTE $95, $33, $A5, $12, $F0, $02, $A6, $77, $20, $8F, $25, $A6, $76, $60, $A5, $78
    .BYTE $10, $03, $4C, $83, $1D, $C5, $79, $F0, $2F, $85, $79, $A8, $8A, $48, $B9, $35
    .BYTE $00, $85, $3B, $B9, $37, $00, $85, $3C, $B9, $31, $00, $85, $3D, $B9, $33, $00
    .BYTE $85, $3E, $A9, $07, $85, $12, $B9, $CA, $00, $C9, $64, $90, $02, $A9, $FF, $85
    .BYTE $13, $98, $AA, $20, $38, $20, $68, $AA, $E4, $78, $D0, $01, $60, $A9, $38, $8D
    .BYTE $97, $1F, $A9, $B8, $8D, $98, $1F, $A9, $07, $8D, $8F, $1F, $B5, $CA, $C9, $64
    .BYTE $90, $0D, $A9, $D8, $8D, $9C, $1F, $A9, $B7, $8D, $9D, $1F, $4C, $03, $1D, $A9
    .BYTE $98, $8D, $9C, $1F, $A9, $B8, $8D, $9D, $1F, $B5, $35, $85, $3B, $B5, $37, $85
    .BYTE $3C, $B5, $31, $85, $3D, $B5, $33, $85, $3E, $20, $A2, $1D, $20, $31, $1E, $A5
    .BYTE $3B, $D5, $35, $90, $02, $B5, $35, $85, $3B, $A5, $3C, $D5, $37, $B0, $02, $B5
    .BYTE $37, $85, $3C, $A6, $78, $20, $A2, $1D, $8A, $A8, $49, $01, $AA, $B9, $37, $00
    .BYTE $C5, $3B, $90, $34, $A5, $3C, $D9, $35, $00, $90, $2D, $38, $B9, $35, $00, $E5
    .BYTE $3B, $F0, $16, $90, $14, $85, $12, $18, $65, $42, $85, $42, $06, $12, $06, $12
    .BYTE $06, $12, $38, $A5, $40, $E5, $12, $85, $40, $38, $A5, $3C, $F9, $37, $00, $F0
    .BYTE $07, $90, $05, $18, $65, $43, $85, $43, $A6, $78, $AD, $62, $03, $D0, $03, $20
    .BYTE $86, $1D, $A9, $FF, $85, $12, $4C, $32, $20, $20, $A2, $1D, $A9, $70, $8D, $97
    .BYTE $1F, $A9, $B7, $8D, $98, $1F, $A9, $FF, $8D, $8F, $1F, $A9, $38, $8D, $9C, $1F
    .BYTE $A9, $B8, $8D, $9D, $1F, $4C, $31, $1E, $18, $B5, $8C, $75, $CA, $75, $8A, $85
    .BYTE $2E, $95, $B2, $B5, $88, $10, $05, $49, $FF, $18, $69, $01, $A8, $B9, $32, $6A
    .BYTE $85, $24, $B9, $4C, $6A, $85, $25, $B4, $8C, $B5, $88, $C9, $80, $A9, $39, $B0
    .BYTE $05, $71, $24, $4C, $D2, $1D, $F1, $24, $85, $4D, $95, $B0, $B4, $39, $B9, $C1
    .BYTE $52, $85, $24, $B9, $06, $53, $85, $25, $A0, $00, $84, $42, $B1, $24, $4A, $85
    .BYTE $12, $38, $A5, $4D, $E5, $12, $85, $44, $4A, $4A, $85, $12, $D5, $35, $90, $06
    .BYTE $F0, $04, $F5, $35, $85, $42, $A5, $12, $95, $35, $38, $E5, $42, $0A, $0A, $0A
    .BYTE $85, $40, $84, $43, $18, $A5, $44, $71, $24, $85, $45, $4A, $4A, $85, $12, $D5
    .BYTE $37, $B0, $07, $38, $B5, $37, $E5, $12, $85, $43, $A5, $12, $95, $37, $38, $F5
    .BYTE $35, $18, $69, $01, $85, $48, $60, $A9, $00, $85, $14, $8D, $D0, $1F, $85, $46
    .BYTE $85, $47, $A9, $BF, $85, $5B, $B5, $96, $F0, $02, $85, $5B, $38, $B5, $92, $F0
    .BYTE $30, $E5, $44, $90, $67, $85, $12, $B5, $92, $29, $03, $A8, $B9, $5C, $68, $85
    .BYTE $46, $D0, $06, $A4, $12, $C8, $4C, $6D, $1E, $A5, $12, $F9, $60, $68, $F0, $4C
    .BYTE $90, $4A, $A8, $18, $B9, $6C, $68, $8D, $D0, $1F, $65, $42, $85, $42, $4C, $AE
    .BYTE $1E, $B5, $94, $F0, $37, $38, $A5, $45, $F5, $94, $90, $30, $85, $12, $B5, $94
    .BYTE $29, $03, $A8, $B9, $64, $68, $85, $47, $D0, $06, $A4, $12, $C8, $4C, $A6, $1E
    .BYTE $C6, $48, $A5, $12, $F9, $68, $68, $F0, $13, $90, $11, $A8, $18, $B9, $6C, $68
    .BYTE $65, $43, $85, $43, $38, $A5, $48, $F9, $6C, $68, $85, $48, $A0, $02, $38, $A5
    .BYTE $2E, $E9, $0C, $18, $71, $24, $85, $4C, $D5, $31, $90, $0F, $F0, $0D, $F5, $31
    .BYTE $E9, $01, $85, $14, $B5, $31, $85, $4C, $20, $13, $1F, $A5, $4C, $95, $31, $A0
    .BYTE $01, $B1, $24, $85, $4E, $A0, $03, $B1, $24, $85, $EF, $C8, $B1, $24, $85, $14
    .BYTE $C8, $A5, $44, $29, $03, $85, $12, $B1, $24, $85, $F0, $20, $26, $1F, $C6, $4E
    .BYTE $D0, $E9, $A5, $4C, $48, $D5, $33, $B0, $0C, $38, $B5, $33, $E5, $4C, $E9, $01
    .BYTE $85, $14, $20, $13, $1F, $68, $95, $33, $60, $86, $4F, $84, $50, $A2, $00, $86
    .BYTE $F0, $A9, $00, $85, $12, $A9, $04, $85, $4A, $4C, $4C, $1F, $86, $4F, $84, $50
    .BYTE $AA, $0A, $A8, $B9, $1D, $56, $4A, $4A, $85, $4A, $A5, $EF, $C9, $02, $D0, $12
    .BYTE $B9, $1D, $56, $29, $03, $49, $03, $85, $15, $38, $A5, $12, $E5, $15, $29, $03
    .BYTE $85, $12, $A4, $12, $B9, $48, $68, $85, $51, $B9, $4C, $68, $85, $52, $B9, $50
    .BYTE $68, $85, $53, $B9, $54, $68, $85, $54, $20, $53, $29, $BD, $99, $55, $8D, $BA
    .BYTE $1F, $BD, $DB, $55, $8D, $BB, $1F, $A2, $00, $86, $13, $18, $90, $09, $E6, $4C
    .BYTE $C6, $14, $10, $03, $4C, $2D, $20, $A5, $48, $85, $49, $A4, $4C, $C4, $5B, $B0
    .BYTE $ED, $B9, $A8, $B6, $29, $FF, $85, $55, $29, $07, $85, $57, $B9, $FF, $FF, $85
    .BYTE $56, $B9, $FF, $FF, $85, $58, $A4, $40, $A6, $42, $F0, $0B, $B1, $57, $91, $55
    .BYTE $98, $69, $08, $A8, $CA, $D0, $F5, $84, $41, $A6, $13, $A0, $00, $84, $4B, $BD
    .BYTE $FF, $FF, $99, $F1, $00, $E8, $C8, $C4, $4A, $90, $F4, $F0, $F2, $18, $A9, $00
    .BYTE $99, $F1, $00, $86, $13, $A2, $FF, $F0, $06, $B4, $F0, $B1, $53, $85, $4B, $A5
    .BYTE $46, $F0, $0D, $85, $59, $B4, $F1, $B1, $51, $05, $4B, $25, $59, $4C, $F0, $1F
    .BYTE $B4, $F1, $B1, $51, $05, $4B, $85, $59, $B1, $53, $85, $4B, $A4, $59, $B9, $00
    .BYTE $BA, $A4, $41, $31, $57, $05, $A2, $03, $B5, $00, $9D, $00, $E3, $CA, $10, $F8
    .BYTE $AD, $04, $03, $85, $00, $AD, $05, $03, $85, $01, $A2, $00, $AD, $0A, $03, $DD
    .BYTE $70, $E4, $F0, $03, $E8, $D0, $F8, $BD, $75, $E4, $85, $02, $BD, $7A, $E4, $85
    .BYTE $03, $20, $47, $E4, $C6, $13, $D0, $F9, $A2, $03, $BD, $00, $E3, $95, $00, $CA
    .BYTE $10, $F8, $A0, $01, $8C, $03, $03, $60, $41, $E4, $00, $00, $00, $A0, $7F, $B1
    .BYTE $02, $91, $00, $88, $10, $F9, $18, $A9, $80, $65, $00, $85, $00, $90, $02, $E6
    .BYTE $01, $18, $A9, $80, $65, $02, $85, $02, $90, $02, $E6, $03, $60

.ORG $34A6

XEX_34A6_267:
    .BYTE $45, $45, $0F, $57, $33, $80, $80, $00, $80, $00, $E4, $E4, $EB, $F6, $FB, $00
    .BYTE $30, $C0, $00, $03, $DD, $DD, $DD, $00, $05, $DD, $DD, $DD, $3F, $D7, $D7, $3F
    .BYTE $FF, $FF, $F3, $CF, $C0, $70, $70, $C0, $F0, $FD, $3D, $FD, $00, $05, $DD, $DD
    .BYTE $DD, $00, $05, $DD, $DD, $DD, $00, $05, $DD, $DD, $DD, $00, $05, $DD, $DD, $DD
    .BYTE $00, $05, $DD, $DD, $DD, $00, $05, $DD, $DF, $FF, $00, $03, $03, $0D, $F7, $FF
    .BYTE $57, $00, $01, $0F, $35, $D5, $57, $FD, $57, $FF, $D7, $57, $55, $55, $FF, $55
    .BYTE $FF, $BB, $75, $75, $D5, $55, $FD, $57, $FD, $BB, $55, $55, $55, $55, $55, $FF
    .BYTE $55, $FF, $55, $55, $55, $55, $55, $55, $FD, $57, $55, $55, $55, $55, $55, $55
    .BYTE $55, $D5, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $57, $5D
    .BYTE $77, $DE, $57, $5D, $77, $DE, $7E, $EE, $EF, $EE, $70, $F0, $F0, $F0, $F0, $FD
    .BYTE $FD, $FD, $00, $05, $DD, $DD, $DD, $00, $05, $DD, $DD, $DD, $00, $05, $DD, $DD
    .BYTE $DD, $0C, $03, $00, $03, $DD, $DD, $DD, $DD, $DD, $DD, $00, $05, $DD, $DD, $DD
    .BYTE $00, $03, $03, $03, $F3, $CF, $F3, $CF, $F3, $CF, $33, $C3, $CD, $3D, $CD, $3C
    .BYTE $CC, $33, $CF, $33, $DD, $DD, $DD, $00, $05, $DD, $DD, $DD, $00, $05, $DD, $DD
    .BYTE $DD, $00, $05, $DD, $DD, $DD, $00, $05, $DD, $DF, $F7, $3F, $3B, $3B, $3B, $3B
    .BYTE $F7, $7F, $FB, $AB, $BB, $BB, $BB, $BB, $FF, $BB, $FF, $FF, $EE, $EB, $EE, $FA
    .BYTE $BB, $BB, $FF, $FF, $FF, $FF, $FF, $FF, $FB, $BB, $FF, $FF, $FF, $FF, $FF, $FF
    .BYTE $FB, $BB, $FF, $FF, $FF, $FF, $FF, $FF, $BB, $BB, $FF, $FF, $FE, $FE, $FF, $FF
    .BYTE $FF, $BB, $FF, $FF, $AF, $EF, $EF, $BF, $7D, $F7, $BF, $BB, $BB, $BF, $BB, $BB
    .BYTE $57, $DD, $77, $DE, $BE, $BF, $BF, $FF, $7E, $EE, $EE, $FE, $EF, $EE, $EE, $FE
    .BYTE $EE, $EE, $FF, $FE, $FE, $EE, $EF, $EE, $FD, $FD, $FD, $F0, $F0, $F0, $F0, $F0
    .BYTE $DD, $DD, $DD, $00, $05, $DD, $DD, $DD, $00, $05, $DD, $DD, $DD, $00, $05, $DD
    .BYTE $DD, $DD, $00, $0D, $03, $03, $03, $03, $0C, $0F, $0C, $0C, $33, $0F, $33, $C3
    .BYTE $33, $0F, $F3, $F3, $0F, $33, $C3, $33, $0C, $33, $F3, $3C, $00, $03, $C0, $C0
    .BYTE $C0, $C0, $C0, $00, $18, $3B, $3B, $3B, $3B, $3B, $3B, $3B, $3B, $FB, $BB, $BB
    .BYTE $BB, $BF, $BB, $BB, $BB, $EA, $FB, $EB, $EB, $EE, $EE, $EA, $EE, $FF, $FF, $FF
    .BYTE $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .BYTE $FF, $FF, $FF, $FF, $FF, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE, $AF, $EF, $AF
    .BYTE $BF, $EF, $EF, $AF, $FF, $BF, $BF, $BF, $BB, $BB, $BB, $BF, $BF, $BE, $BE, $BE
    .BYTE $BF, $FF, $FF, $FE, $BE, $EF, $EE, $EE, $FE, $EE, $EE, $EE, $FF, $FE, $EE, $EF
    .BYTE $EC, $FC, $F0, $C0, $00, $01, $F0, $C0, $00, $2E, $0F, $0C, $0C, $00, $05, $0F
    .BYTE $03, $03, $00, $05, $C0, $00, $27, $3B, $3B, $3B, $3B, $3B, $3B, $3B, $3F, $BB
    .BYTE $BB, $BB, $BB, $AB, $BB, $BB, $FF, $FB, $EB, $EA, $EE, $FA, $EE, $FF, $22, $FF
    .BYTE $FF, $FF, $FF, $FF, $FF, $FF, $22, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $22, $FF
    .BYTE $FF, $FF, $FF, $FF, $FF, $FF, $22, $FE, $FF, $FF, $FE, $FE, $FE, $FF, $22, $BF
    .BYTE $AF, $BF, $AF, $EF, $EF, $FF, $0C, $BF, $BB, $BB, $BB, $BF, $BB, $BB, $CF, $BF
    .BYTE $BF, $BF, $FE, $BE, $BF, $BC, $30, $EF, $EC, $F0, $C0, $C0, $00, $78, $02, $08
    .BYTE $22, $00, $01, $02, $08, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22
    .BYTE $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22
    .BYTE $88, $22, $88, $22, $88, $22, $88, $22, $88, $20, $88, $22, $88, $20, $80, $00
    .BYTE $03, $80, $00, $84, $02, $08, $22, $00, $01, $02, $08, $22, $88, $22, $88, $22
    .BYTE $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22
    .BYTE $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22
    .BYTE $88, $22, $88, $22, $88, $20, $80, $00, $01, $80, $20, $80, $00, $6C, $02, $00
    .BYTE $03, $02, $08, $22, $88, $22, $00, $02, $08, $22, $88, $22, $88, $22, $00, $02
    .BYTE $88, $22, $88, $22, $88, $22, $00, $01, $02, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $20, $88, $22, $88, $22, $88, $22, $00
    .BYTE $02, $88, $22, $88, $22, $88, $22, $00, $02, $88, $22, $88, $22, $88, $22, $00
    .BYTE $02, $88, $22, $88, $22, $88, $22, $00, $02, $88, $22, $88, $22, $88, $22, $00
    .BYTE $02, $88, $22, $88, $22, $88, $22, $00, $02, $88, $22, $88, $22, $88, $22, $00
    .BYTE $02, $88, $22, $88, $22, $88, $22, $00, $02, $88, $22, $88, $22, $88, $22, $00
    .BYTE $02, $88, $22, $88, $22, $88, $22, $00, $02, $88, $22, $88, $22, $88, $22, $00
    .BYTE $02, $88, $22, $88, $22, $88, $22, $00, $02, $88, $22, $88, $22, $88, $22, $00
    .BYTE $02, $88, $22, $88, $22, $88, $22, $00, $03, $02, $08, $22, $88, $22, $08, $22
    .BYTE $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22
    .BYTE $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22
    .BYTE $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22
    .BYTE $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22
    .BYTE $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22
    .BYTE $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22
    .BYTE $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22
    .BYTE $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22
    .BYTE $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22
    .BYTE $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22
    .BYTE $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22
    .BYTE $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22
    .BYTE $08, $22, $00, $04, $88, $22, $88, $22, $00, $04, $88, $22, $88, $22, $00, $04
    .BYTE $88, $22, $88, $22, $00, $04, $88, $22, $88, $22, $00, $04, $88, $22, $88, $22
    .BYTE $00, $04, $88, $22, $88, $22, $00, $04, $88, $22, $88, $22, $00, $04, $88, $22
    .BYTE $88, $22, $00, $04, $88, $22, $88, $22, $00, $04, $88, $22, $88, $22, $00, $04
    .BYTE $88, $22, $88, $22, $00, $04, $88, $22, $88, $22, $00, $04, $88, $22, $88, $22
    .BYTE $00, $04, $88, $22, $88, $22, $00, $04, $88, $22, $88, $22, $00, $04, $88, $22
    .BYTE $88, $22, $00, $04, $88, $22, $88, $22, $00, $04, $88, $22, $88, $22, $00, $04
    .BYTE $88, $22, $88, $22, $00, $04, $88, $22, $88, $22, $00, $04, $88, $22, $88, $22
    .BYTE $00, $04, $88, $22, $88, $22, $00, $04, $88, $22, $88, $22, $00, $04, $88, $22
    .BYTE $88, $22, $00, $06, $87, $87, $00, $00, $00, $3F

.ORG $3988

XEX_3988_268:
    .BYTE $D5, $FF

.ORG $3990

XEX_3990_269:
    .BYTE $03, $55, $55, $C0

.ORG $3999

XEX_3999_270:
    .BYTE $0D, $55, $57, $C0

.ORG $39A2

XEX_39A2_271:
    .BYTE $35, $55, $5D, $C0

.ORG $39AB

XEX_39AB_272:
    .BYTE $FF, $55, $77

.ORG $39B4

XEX_39B4_273:
    .BYTE $D5, $FD, $DF

.ORG $39BD

XEX_39BD_274:
    .BYTE $FF, $F7, $77

.ORG $39C6

XEX_39C6_275:
    .BYTE $03, $FF, $FF

.ORG $39CF

XEX_39CF_276:
    .BYTE $03, $77, $5D, $C0

.ORG $39D8

XEX_39D8_277:
    .BYTE $03, $55, $7D, $C0

.ORG $39E1

XEX_39E1_278:
    .BYTE $03, $D5, $5D, $C0

.ORG $39EA

XEX_39EA_279:
    .BYTE $03, $55, $77, $F0

.ORG $39F3

XEX_39F3_280:
    .BYTE $03, $DD, $57, $70

.ORG $39FC

XEX_39FC_281:
    .BYTE $0F, $FD, $DF, $70

.ORG $3A05

XEX_3A05_282:
    .BYTE $0D, $5F, $FF, $5F, $FF, $FF, $FF, $FF, $FC, $0D, $75, $75, $F7, $FF, $FF, $55
    .BYTE $75, $57, $0D, $D5, $DD, $7F, $FF, $FF, $55, $DD, $57, $0D, $D7, $75, $57, $FF
    .BYTE $FD, $55, $D5, $57, $0D, $D7, $55, $55, $55, $75, $7F, $F5, $5C, $0F, $D7, $75
    .BYTE $FF, $FF, $FF, $D7, $55, $5C, $00, $37, $55, $D5, $D5, $75, $57, $75, $7F, $00
    .BYTE $0F, $77, $57, $55, $F5, $57, $55, $F7, $00, $00, $DF, $FF, $FF, $75, $57, $77
    .BYTE $FF, $00, $00, $35, $5D, $5F, $5D, $55, $FC, $3C, $00, $00, $35, $75, $77, $5D
    .BYTE $55, $F0, $00, $00, $00, $D5, $D5, $D7, $57, $7F, $00, $00, $00, $03, $FF, $F7
    .BYTE $77, $7F, $C0, $00, $00, $00, $0D, $5D, $5D, $F7, $DC, $00, $00, $00, $00, $0D
    .BYTE $5D, $7D, $DF, $DC, $00, $00, $00, $00, $35, $75, $DD, $F0, $37, $00, $00, $00
    .BYTE $00, $35, $DF, $7F, $00, $37, $00, $00, $00, $00, $3F, $F5, $F0, $00, $DC, $00
    .BYTE $00, $00, $00, $35, $5F, $00, $00, $FC, $00, $00, $00, $00, $0F, $F0, $00, $03
    .BYTE $FF

.ORG $3ABD

XEX_3ABD_283:
    .BYTE $03, $DF

.ORG $3AC6

XEX_3AC6_284:
    .BYTE $03, $FF

.ORG $3AD0

XEX_3AD0_285:
    .BYTE $FC

.ORG $3ADD

XEX_3ADD_286:
    .BYTE $04, $14, $00, $1D, $40, $00, $35, $B0, $00, $16, $BC, $00, $5A, $EF, $00, $7E
    .BYTE $EA, $C0, $F7, $EA, $B0, $F7, $7E, $AC, $77, $73, $EB, $BB, $7F, $FF, $DF, $FA
    .BYTE $CF, $D5, $5A, $CF, $FF, $FF, $FF, $0C, $3F, $00, $3F, $F0, $00, $3F, $E0, $00
    .BYTE $0F, $BC, $00, $3E, $AF, $00, $FA, $EA, $C0, $CF, $EA, $B0, $FF, $FE, $AC, $7F
    .BYTE $F3, $EB, $FF, $FF, $FF, $FF, $EA, $CF, $FF, $FB, $CF, $FF, $FF, $00, $19, $0F
    .BYTE $15, $12, $20, $12, $01, $0E, $0B, $09, $0E, $AD, $4C, $03, $29, $07, $AA, $BD
    .BYTE $5A, $58, $8D, $61, $03, $BD, $12, $58, $85, $18, $BD, $1A, $58, $85, $19, $BD
    .BYTE $62, $58, $85, $57, $BD, $6A, $58, $85, $58, $20, $E0, $2E, $29, $03, $A8, $B1
    .BYTE $57, $8D, $63, $03, $BC, $42, $58, $84, $11, $88, $8C, $45, $03, $A9, $00, $85
    .BYTE $90, $85, $91, $8D, $46, $03, $8D, $47, $03, $A8, $A9, $01, $99, $68, $B5, $99
    .BYTE $98, $B5, $A2, $00, $86, $0E, $20, $F9, $28, $A0, $00, $B1, $18, $AC, $6D, $57
    .BYTE $91, $20, $A0, $01, $B1, $18, $AC, $6E, $57, $91, $20, $A0, $02, $AD, $63, $03
    .BYTE $C5, $0E, $D0, $03, $4C, $70, $82, $B1, $18, $AC, $6F, $57, $91, $20, $A0, $03
    .BYTE $B1, $18, $AC, $70, $57, $91, $20, $A0, $04, $B1, $18, $AC, $71, $57, $91, $20
    .BYTE $A0, $05, $B1, $18, $AC, $72, $57, $91, $20, $C9, $FF, $A9, $0F, $90, $02, $A9
    .BYTE $8F, $85, $15, $20, $E0, $2E, $29, $1F, $A8, $B9, $A9, $57, $25, $15, $AC, $6C
    .BYTE $57, $91, $20, $A2, $05, $A9, $80, $BC, $73, $57, $91, $20, $A9, $04, $BC, $7F
    .BYTE $57, $91, $20, $CA, $10, $EF, $18, $A5, $18, $6D, $11, $58, $85, $18, $A5, $19
    .BYTE $69, $00, $85, $19, $A6, $0E, $E8, $E4, $11, $B0, $03, $4C, $4B, $82, $A2, $00
    .BYTE $86, $0E, $20, $F9, $28, $A2, $05, $BC, $73, $57, $B1, $20, $C9, $80, $D0, $4C
    .BYTE $A9, $00, $85, $15, $E0, $02, $D0, $09, $A5, $0E, $CD, $63, $03, $D0, $02, $E6
    .BYTE $15, $BC, $6D, $57, $B1, $20, $C9, $FF, $F0, $32, $29, $7F, $A8, $20, $1A, $29
    .BYTE $20, $E0, $2E, $29, $03, $BC, $7F, $57, $91, $20, $A4, $15, $D0, $05, $BC, $97
    .BYTE $57, $91, $22, $A8, $B9, $FB, $56, $E0, $02, $90, $03, $B9, $FF, $56, $BC, $73
    .BYTE $57, $91, $20, $A4, $15, $D0, $05, $BC, $8B, $57, $91, $22, $CA, $10, $A8, $A2
    .BYTE $05, $BC, $73, $57, $B1, $20, $20, $C1, $28, $29, $FC, $BC, $79, $57, $91, $20
    .BYTE $CA, $10, $EE, $A6, $0E, $E8, $E4, $11, $B0, $03, $4C, $D7, $82, $A2, $00, $86
    .BYTE $0E, $20, $F9, $28, $A9, $00, $85, $0F, $A2, $02, $86, $13, $BD, $06, $57, $85
    .BYTE $1C, $BD, $09, $57, $85, $1D, $BC, $7F, $57, $E0, $02, $D0, $12, $B1, $20, $C9
    .BYTE $04, $D0, $0C, $BC, $81, $57, $B1, $20, $C9, $04, $D0, $03, $BC, $82, $57, $B1
    .BYTE $20, $0A, $0A, $E0, $02, $D0, $01, $0A, $85, $12, $20, $E0, $2E, $3D, $03, $57
    .BYTE $18, $65, $12, $A8, $B1, $1C, $C9, $FF, $F0, $5A, $85, $12, $AD, $68, $03, $3D
    .BYTE $03, $57, $18, $7D, $78, $59, $A8, $84, $14, $B9, $7B, $59, $85, $1C, $B9, $8C
    .BYTE $59, $85, $1D, $A0, $00, $B1, $1C, $E0, $02, $B0, $08, $85, $2F, $A5, $12, $85
    .BYTE $30, $90, $06, $85, $30, $A5, $12, $85, $2F, $A6, $0F, $BC, $5D, $57, $A5, $14
    .BYTE $91, $20, $BC, $60, $57, $A5, $2F, $91, $20, $BC, $63, $57, $A5, $30, $91, $20
    .BYTE $A4, $14, $B9, $67, $59, $BC, $66, $57, $91, $20, $BC, $69, $57, $A9, $00, $91
    .BYTE $20, $E8, $86, $0F, $A6, $13, $CA, $30, $03, $4C, $61, $83, $A5, $0F, $AC, $5C
    .BYTE $57, $91, $20, $AA, $CA, $30, $0A, $BC, $66, $57, $B1, $20, $F0, $08, $CA, $10
    .BYTE $F6, $A6, $0E, $4C, $56, $83, $A6, $0E, $E8, $E4, $11, $B0, $03, $4C, $56, $83
    .BYTE $A0, $04, $A9, $FF, $99, $30, $03, $88, $10, $FA, $A9, $00, $85, $14, $A2, $00
    .BYTE $86, $0E, $A0, $04, $A5, $0E, $D9, $30, $03, $F0, $3C, $88, $10, $F8, $20, $F9
    .BYTE $28, $AC, $5C, $57, $B1, $20, $AA, $CA, $30, $2D, $BC, $5D, $57, $B1, $20, $C9
    .BYTE $FF, $F0, $21, $BC, $66, $57, $B1, $20, $D0, $1A, $20, $E0, $2E, $29, $1F, $CD
    .BYTE $61, $03, $B0, $10, $A4, $14, $A5, $0E, $99, $30, $03, $8A, $99, $35, $03, $E6
    .BYTE $14, $4C, $7E, $84, $CA, $10, $D3, $A5, $14, $C9, $05, $B0, $0A, $A6, $0E, $E8
    .BYTE $E4, $11, $90, $AC, $4C, $27, $84, $AD, $52, $03, $D0, $0D, $AC, $63, $03, $20
    .BYTE $04, $29, $AC, $6F, $57, $A9, $FF, $91, $20, $AD, $9D, $B6, $10, $05, $A2, $04
    .BYTE $20, $C2, $29, $60, $02, $01, $FF, $FF, $FF, $FF, $00, $03, $FF, $FF, $FF, $FF
    .BYTE $04, $00, $FF, $FF, $FF, $FF, $01, $17, $14, $19, $FF, $FF, $09, $02, $05, $0C
    .BYTE $FF, $FF, $06, $FF, $FF, $04, $FF, $FF, $07, $05, $FF, $FF, $FF, $FF, $FF, $06
    .BYTE $FF, $FF, $0D, $FF, $FF, $FF, $FF, $0A, $FF, $FF, $FF, $04, $FF, $FF, $10, $FF
    .BYTE $FF, $0B, $08, $FF, $FF, $FF, $0A, $0C, $FF, $FF, $FF, $FF, $0B, $FF, $04, $FF
    .BYTE $FF, $FF, $FF, $0E, $FF, $0F, $FF, $07, $0D, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .BYTE $0D, $12, $FF, $FF, $FF, $11, $FF, $13, $FF, $09, $10, $FF, $FF, $FF, $FF, $FF
    .BYTE $FF, $13, $0F, $FF, $FF, $FF, $12, $FF, $10, $FF, $FF, $FF, $FF, $15, $FF, $03
    .BYTE $FF, $FF, $14, $16, $FF, $FF, $FF, $FF, $15, $FF, $FF, $FF, $1D, $FF, $03, $FF
    .BYTE $FF, $FF, $1F, $FF, $FF, $FF, $FF, $1B, $FF, $FF, $FF, $1A, $03, $FF, $FF, $FF
    .BYTE $19, $1B, $FF, $FF, $FF, $FF, $1A, $FF, $18, $FF, $FF, $FF, $FF, $1D, $FF, $FF
    .BYTE $FF, $FF, $1C, $FF, $FF, $20, $FF, $16, $FF, $1F, $FF, $FF, $FF, $FF, $1E, $FF
    .BYTE $FF, $21, $FF, $17, $FF, $FF, $1D, $22, $FF, $FF, $FF, $22, $1F, $FF, $FF, $FF
    .BYTE $21, $FF, $20, $FF, $FF, $FF, $FF, $FF, $05, $01, $FF, $FF, $0A, $FF, $00, $FF
    .BYTE $FF, $FF, $FF, $03, $FF, $04, $FF, $FF, $02, $FF, $FF, $FF, $FF, $FF, $FF, $05
    .BYTE $02, $FF, $FF, $FF, $04, $FF, $FF, $00, $17, $FF, $FF, $07, $FF, $FF, $FF, $FF
    .BYTE $06, $FF, $FF, $09, $FF, $FF, $FF, $09, $FF, $0F, $22, $FF, $08, $FF, $07, $FF
    .BYTE $FF, $FF, $FF, $01, $FF, $0B, $FF, $FF, $FF, $FF, $0A, $0C, $FF, $FF, $FF, $0E
    .BYTE $0B, $FF, $FF, $FF, $FF, $FF, $FF, $0E, $1A, $FF, $0C, $FF, $0D, $FF, $FF, $FF
    .BYTE $FF, $FF, $08, $10, $FF, $FF, $FF, $11, $0F, $FF, $FF, $FF, $10, $FF, $FF, $12
    .BYTE $FF, $FF, $FF, $FF, $11, $13, $FF, $FF, $15, $FF, $12, $FF, $FF, $FF, $FF, $FF
    .BYTE $FF, $15, $1F, $FF, $FF, $13, $14, $FF, $FF, $FF, $17, $FF, $FF, $FF, $FF, $FF
    .BYTE $FF, $16, $FF, $18, $FF, $05, $FF, $FF, $17, $19, $FF, $FF, $FF, $FF, $18, $FF
    .BYTE $FF, $FF, $FF, $1B, $FF, $FF, $FF, $0D, $1A, $1C, $FF, $FF, $FF, $FF, $1B, $1D
    .BYTE $FF, $FF, $FF, $FF, $1C, $1E, $FF, $FF, $FF, $FF, $1D, $1F, $FF, $FF, $FF, $FF
    .BYTE $1E, $FF, $FF, $FF, $FF, $14, $FF, $FF, $21, $FF, $FF, $FF, $FF, $FF, $22, $20
    .BYTE $FF, $FF, $23, $FF, $FF, $21, $FF, $08, $FF, $22, $FF, $FF, $FF, $FF, $05, $01
    .BYTE $FF, $FF, $FF, $FF, $00, $FF, $02, $FF, $FF, $FF, $03, $FF, $FF, $01, $FF, $FF
    .BYTE $04, $02, $FF, $FF, $FF, $FF, $FF, $03, $FF, $05, $FF, $FF, $FF, $00, $04, $FF
    .BYTE $FF, $FF, $0D, $01, $09, $11, $FF, $FF, $00, $0E, $FF, $FF, $FF, $FF, $FF, $03
    .BYTE $FF, $07, $FF, $FF, $02, $04, $FF, $08, $FF, $FF, $03, $FF, $FF, $09, $FF, $FF
    .BYTE $FF, $06, $FF, $FF, $FF, $FF, $05, $FF, $FF, $0B, $FF, $FF, $FF, $08, $02, $FF
    .BYTE $FF, $FF, $07, $FF, $03, $FF, $FF, $FF, $FF, $FF, $04, $00, $FF, $FF, $FF, $0B
    .BYTE $FF, $FF, $FF, $FF, $0A, $FF, $06, $0E, $FF, $FF, $FF, $0D, $FF, $FF, $FF, $FF
    .BYTE $0C, $00, $FF, $FF, $FF, $FF, $01, $FF, $0B, $FF, $FF, $FF, $FF, $10, $FF, $FF
    .BYTE $FF, $FF, $0F, $FF, $FF, $15, $FF, $FF, $FF, $FF, $00, $16, $FF, $FF, $FF, $13
    .BYTE $FF, $17, $FF, $FF, $12, $FF, $FF, $FF, $19, $FF, $FF, $15, $FF, $FF, $FF, $FF
    .BYTE $14, $16, $10, $FF, $FF, $FF, $15, $17, $11, $FF, $FF, $FF, $16, $18, $12, $FF
    .BYTE $FF, $FF, $17, $FF, $FF, $FF, $1C, $FF, $FF, $1A, $FF, $FF, $FF, $13, $19, $1B
    .BYTE $FF, $FF, $FF, $FF, $1A, $FF, $FF, $1E, $FF, $FF, $FF, $1D, $FF, $FF, $FF, $18
    .BYTE $1C, $FF, $FF, $20, $FF, $FF, $FF, $FF, $1B, $21, $FF, $FF, $FF, $20, $FF, $FF
    .BYTE $FF, $FF, $1F, $FF, $1D, $FF, $FF, $FF, $FF, $FF, $1E, $FF, $FF, $FF, $FF, $FF
    .BYTE $01, $0A, $FF, $FF, $03, $04, $FF, $00, $FF, $FF, $FF, $03, $FF, $06, $FF, $FF
    .BYTE $02, $01, $FF, $FF, $FF, $FF, $01, $05, $FF, $FF, $FF, $FF, $04, $FF, $FF, $07
    .BYTE $FF, $FF, $FF, $FF, $02, $08, $FF, $FF, $FF, $FF, $05, $0C, $FF, $FF, $FF, $09
    .BYTE $06, $FF, $FF, $FF, $08, $0A, $FF, $FF, $FF, $FF, $09, $0B, $00, $FF, $FF, $FF
    .BYTE $0A, $0C, $FF, $FF, $FF, $FF, $0B, $FF, $07, $FF, $FF, $FF, $06, $FF, $FF, $FF
    .BYTE $FF, $FF, $FF, $07, $FF, $FF, $FF, $FF, $FF, $03, $FF, $06, $FF, $FF, $02, $04
    .BYTE $FF, $FF, $0D, $FF, $03, $05, $FF, $FF, $0E, $FF, $04, $FF, $FF, $07, $FF, $FF
    .BYTE $FF, $00, $02, $08, $FF, $FF, $01, $FF, $05, $0B, $FF, $FF, $FF, $09, $06, $FF
    .BYTE $FF, $FF, $08, $0A, $FF, $FF, $FF, $FF, $09, $0B, $FF, $FF, $FF, $FF, $0A, $FF
    .BYTE $07, $FF, $FF, $FF, $FF, $0D, $FF, $10, $FF, $FF, $0C, $0E, $FF, $FF, $FF, $03
    .BYTE $0D, $0F, $FF, $FF, $FF, $04, $0E, $FF, $FF, $13, $FF, $FF, $FF, $11, $0C, $FF
    .BYTE $FF, $FF, $10, $12, $FF, $FF, $FF, $FF, $11, $13, $FF, $FF, $FF, $FF, $12, $FF
    .BYTE $0F, $FF, $FF, $FF, $02, $01, $FF, $FF, $FF, $FF, $00, $FF, $FF, $04, $FF, $FF
    .BYTE $FF, $00, $FF, $03, $FF, $FF, $FF, $FF, $02, $05, $FF, $FF, $FF, $FF, $01, $07
    .BYTE $FF, $FF, $FF, $06, $03, $FF, $FF, $FF, $05, $07, $FF, $08, $FF, $FF, $06, $FF
    .BYTE $04, $FF, $FF, $FF, $FF, $FF, $06, $1E, $FF, $FF, $FF, $0A, $FF, $0F, $FF, $FF
    .BYTE $09, $0B, $FF, $FF, $FF, $FF, $0A, $0C, $FF, $FF, $FF, $FF, $0B, $0D, $FF, $FF
    .BYTE $FF, $FF, $0C, $FF, $FF, $10, $FF, $FF, $FF, $0F, $FF, $12, $FF, $FF, $0E, $FF
    .BYTE $09, $FF, $FF, $FF, $FF, $11, $0D, $FF, $FF, $FF, $10, $FF, $FF, $13, $FF, $FF
    .BYTE $FF, $FF, $0E, $14, $FF, $FF, $FF, $FF, $11, $15, $FF, $FF, $FF, $FF, $12, $16
    .BYTE $FF, $FF, $FF, $FF, $13, $17, $FF, $FF, $FF, $FF, $14, $18, $FF, $FF, $FF, $FF
    .BYTE $15, $1B, $FF, $FF, $FF, $19, $16, $FF, $FF, $FF, $18, $FF, $FF, $1C, $FF, $FF
    .BYTE $FF, $1B, $FF, $20, $FF, $FF, $1A, $FF, $17, $FF, $FF, $FF, $FF, $1D, $19, $FF
    .BYTE $FF, $FF, $1C, $1E, $FF, $FF, $FF, $FF, $1D, $1F, $08, $FF, $FF, $FF, $1E, $20
    .BYTE $FF, $FF, $FF, $FF, $1F, $FF, $1A, $FF, $FF, $FF, $06, $07, $01, $FF, $FF, $FF
    .BYTE $04, $05, $FF, $00, $FF, $FF, $FF, $FF, $FF, $04, $FF, $FF, $FF, $FF, $FF, $05
    .BYTE $FF, $FF, $FF, $01, $02, $06, $FF, $FF, $01, $FF, $03, $07, $FF, $FF, $FF, $00
    .BYTE $04, $08, $FF, $FF, $00, $FF, $05, $09, $FF, $FF, $FF, $FF, $06, $0A, $FF, $FF
    .BYTE $FF, $FF, $07, $0C, $FF, $FF, $FF, $0B, $08, $0D, $FF, $FF, $0A, $0C, $FF, $0E
    .BYTE $20, $FF, $0B, $FF, $09, $0F, $FF, $FF, $FF, $0E, $0A, $10, $FF, $FF, $0D, $0F
    .BYTE $0B, $FF, $FF, $FF, $0E, $FF, $0C, $11, $FF, $FF, $FF, $FF, $0D, $FF, $FF, $FF
    .BYTE $FF, $FF, $0F, $FF, $FF, $FF, $FF, $13, $FF, $FF, $FF, $FF, $12, $14, $FF, $19
    .BYTE $FF, $FF, $13, $15, $FF, $1A, $FF, $FF, $14, $16, $FF, $FF, $FF, $FF, $15, $17
    .BYTE $FF, $1B, $FF, $FF, $16, $18, $FF, $1C, $FF, $FF, $17, $FF, $FF, $FF, $FF, $FF
    .BYTE $FF, $1A, $13, $1E, $FF, $FF, $19, $FF, $14, $1F, $FF, $FF, $FF, $1C, $16, $21
    .BYTE $FF, $FF, $1B, $FF, $17, $22, $FF, $FF, $FF, $1E, $FF, $FF, $FF, $FF, $1D, $1F
    .BYTE $19, $FF, $FF, $FF, $1E, $20, $1A, $FF, $FF, $FF, $1F, $21, $FF, $FF, $FF, $0B
    .BYTE $20, $22, $1B, $FF, $FF, $FF, $21, $23, $1C, $FF, $FF, $FF, $22, $FF, $FF, $FF
    .BYTE $FF, $FF, $A9, $00, $85, $FC, $20, $F2, $23, $E6, $FC, $20, $F2, $23, $A9, $02
    .BYTE $85, $2E, $A2, $00, $86, $0E, $BD, $C1, $78, $85, $1C, $BD, $E0, $78, $85, $1D
    .BYTE $BD, $FF, $78, $A8, $88, $98, $18, $69, $02, $85, $2F, $20, $B6, $23, $E6, $2E
    .BYTE $A6, $0E, $E0, $08, $D0, $04, $A9, $0E, $85, $2E, $E8, $E0, $12, $B0, $03, $4C
    .BYTE $BB, $89, $A9, $00, $85, $14, $A9, $00, $8D, $9D, $B6, $A9, $04, $85, $02, $20
    .BYTE $5E, $8B, $A9, $03, $8D, $9C, $B6, $A9, $58, $8D, $9B, $B6, $A5, $02, $D0, $43
    .BYTE $A0, $C8, $20, $94, $2E, $AD, $9B, $03, $29, $1F, $C9, $1F, $D0, $39, $AD, $9C
    .BYTE $03, $29, $1F, $C9, $1F, $D0, $30, $AD, $99, $03, $30, $21, $20, $5E, $8B, $A0
    .BYTE $14, $20, $94, $2E, $20, $5E, $8B, $A0, $14, $20, $94, $2E, $CE, $9B, $B6, $D0
    .BYTE $D4, $CE, $9C, $B6, $D0, $CF, $A9, $FF, $8D, $9D, $B6, $30, $03, $4C, $A9, $89
    .BYTE $4C, $11, $8B, $C6, $02, $A9, $FD, $85, $12, $20, $5E, $8B, $A5, $12, $29, $10
    .BYTE $F0, $EE, $A5, $12, $29, $03, $A8, $18, $A5, $14, $79, $89, $8B, $30, $08, $C9
    .BYTE $04, $90, $06, $A9, $00, $F0, $02, $A9, $03, $48, $C5, $14, $F0, $05, $A9, $04
    .BYTE $4C, $7C, $8A, $A9, $11, $85, $00, $68, $85, $14, $20, $5E, $8B, $A4, $14, $B9
    .BYTE $81, $8B, $85, $1C, $B9, $85, $8B, $85, $1D, $A0, $00, $A5, $12, $4A, $4A, $29
    .BYTE $03, $AA, $18, $B1, $1C, $7D, $89, $8B, $A6, $14, $C9, $01, $90, $0B, $DD, $8D
    .BYTE $8B, $90, $09, $F0, $07, $A9, $01, $D0, $03, $BD, $8D, $8B, $91, $1C, $48, $18
    .BYTE $A9, $04, $65, $14, $A8, $68, $A2, $00, $20, $ED, $2A, $A4, $14, $C0, $01, $F0
    .BYTE $03, $4C, $F9, $89, $AE, $4D, $03, $CA, $BD, $42, $58, $A0, $08, $20, $F3, $8A
    .BYTE $AE, $4D, $03, $CA, $BD, $42, $58, $0A, $A0, $0A, $20, $F3, $8A, $AE, $4D, $03
    .BYTE $CA, $BD, $AF, $67, $A0, $0C, $20, $F3, $8A, $4C, $F9, $89, $84, $17, $A0, $FF
    .BYTE $38, $E9, $0A, $C8, $B0, $FA, $84, $11, $69, $0A, $A2, $00, $A4, $17, $20, $ED
    .BYTE $2A, $A5, $11, $A4, $17, $C8, $20, $ED, $2A, $60, $A9, $00, $85, $FC, $20, $F2
    .BYTE $23, $E6, $FC, $20, $F2, $23, $AD, $9D, $B6, $F0, $1A, $A0, $00, $8C, $4C, $03
    .BYTE $B9, $A7, $67, $85, $C6, $85, $C7, $A9, $00, $8D, $52, $03, $A9, $02, $8D, $4E
    .BYTE $03, $8D, $50, $03, $60, $AC, $4D, $03, $88, $8C, $4C, $03, $B9, $A7, $67, $85
    .BYTE $C6, $85, $C7, $AC, $53, $03, $88, $8C, $52, $03, $AD, $4F, $03, $8D, $4E, $03
    .BYTE $AD, $51, $03, $8D, $50, $03, $60, $A4, $14, $B9, $79, $8B, $85, $55, $B9, $7D
    .BYTE $8B, $85, $56, $A2, $01, $BC, $91, $8B, $B1, $55, $49, $FF, $91, $55, $CA, $10
    .BYTE $F4, $60, $48, $C8, $08, $48, $97, $98, $9A, $9B, $4F, $4D, $51, $53, $03, $03
    .BYTE $03, $03, $00, $01, $FF, $00, $02, $08, $05, $02, $06, $07, $0E, $0F, $00, $67
    .BYTE $3F, $00, $78, $78, $0E, $15, $0D, $02, $05, $12, $20, $0F, $06, $20, $10, $0C
    .BYTE $01, $19, $05, $12, $13, $2E, $2E, $2E, $2E, $2E, $2E, $32, $0C, $05, $16, $05
    .BYTE $0C, $20, $0F, $06, $20, $04, $09, $06, $06, $09, $03, $15, $0C, $14, $19, $2E
    .BYTE $2E, $2E, $2E, $31, $03, $0F, $0D, $10, $15, $14, $05, $12, $20, $09, $11, $20
    .BYTE $28, $31, $20, $10, $0C, $01, $19, $05, $12, $29, $2E, $31, $08, $09, $04, $05
    .BYTE $20, $01, $09, $12, $10, $0F, $12, $14, $20, $14, $09, $0C, $0C, $20, $05, $0E
    .BYTE $04, $2E, $2E, $19, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D
    .BYTE $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D, $03, $15, $12
    .BYTE $12, $05, $0E, $14, $20, $0C, $05, $16, $05, $0C, $22, $14, $0F, $14, $01, $0C
    .BYTE $20, $0E, $15, $0D, $02, $05, $12, $20, $0F, $06, $20, $12, $0F, $0F, $0D, $13
    .BYTE $2E, $2E, $30, $36, $14, $0F, $14, $01, $0C, $20, $14, $12, $01, $10, $13, $20
    .BYTE $01, $16, $01, $09, $0C, $01, $02, $0C, $05, $2E, $2E, $31, $32, $0D, $09, $0E
    .BYTE $15, $14, $05, $13, $20, $0F, $0E, $20, $14, $08, $05, $20, $03, $0C, $0F, $03
    .BYTE $0B, $2E, $2E, $2E, $30, $37, $15, $10, $2F, $04, $0F, $17, $0E, $20, $0D, $0F
    .BYTE $16, $05, $13, $20, $14, $08, $05, $20, $03, $15, $12, $13, $0F, $12, $0C, $05
    .BYTE $06, $14, $2F, $12, $09, $07, $08, $14, $20, $01, $0C, $14, $05, $12, $13, $20
    .BYTE $13, $05, $14, $14, $09, $0E, $07, $08, $09, $14, $20, $0F, $10, $14, $09, $0F
    .BYTE $0E, $20, $14, $0F, $20, $01, $02, $0F, $12, $14, $20, $07, $01, $0D, $05, $05
    .BYTE $13, $03, $01, $10, $05, $20, $0B, $05, $19, $20, $10, $01, $15, $13, $05, $13
    .BYTE $20, $07, $01, $0D, $05, $15, $13, $05, $20, $0A, $0F, $19, $13, $14, $09, $03
    .BYTE $0B, $20, $31, $20, $06, $0F, $12, $20, $17, $08, $09, $14, $05, $20, $13, $10
    .BYTE $19, $20, $0F, $12, $20, $13, $09, $0E, $07, $0C, $05, $20, $10, $0C, $01, $19
    .BYTE $05, $12, $20, $01, $0E, $04, $20, $0A, $0F, $19, $13, $14, $09, $03, $0B, $20
    .BYTE $32, $20, $06, $0F, $12, $20, $02, $0C, $01, $03, $0B, $20, $13, $10, $19, $20
    .BYTE $06, $09, $12, $05, $20, $02, $15, $14, $14, $0F, $0E, $20, $14, $0F, $20, $13
    .BYTE $14, $01, $12, $14, $20, $07, $01, $0D, $05, $20, $85, $F7, $4C, $EB, $0C, $A6
    .BYTE $76, $20, $C2, $29, $A2, $03, $20, $C2, $29, $4C, $29, $7A, $B4, $7A, $18, $A5
    .BYTE $CE, $79, $9F, $51, $85, $CE, $18, $69, $19, $10, $02, $A9, $00, $C9, $33, $90
    .BYTE $02, $A9, $32, $85, $2F, $18, $A5, $D0, $79, $A9, $51, $85, $D0, $10, $02, $A9
    .BYTE $00, $C9, $19, $90, $02, $A9, $18, $85, $30, $A9, $00, $85, $1E, $18, $A9, $92
    .BYTE $75, $8E, $85, $1F, $A4, $2F, $B9, $B5, $68, $A6, $76, $86, $FC, $A9, $00, $8D
    .BYTE $7D, $03, $8D, $7E, $03, $20, $F2, $23, $A6, $77, $86, $FC, $20, $F2, $23, $A6
    .BYTE $76, $A9, $C3, $9D, $75, $03, $A0, $00, $98, $99, $00, $92, $99, $00, $93, $88
    .BYTE $D0, $F7, $AD, $81, $68, $85, $CA, $AD, $82, $68, $85, $CB, $A9, $00, $85, $8E
    .BYTE $A9, $01, $85, $8F, $A9, $01, $9D, $9D, $03, $A9, $03, $95, $7A, $A9, $00, $95
    .BYTE $90, $9D, $3F, $03, $9D, $7F, $03, $8D, $4A, $03, $8D, $4B, $03, $9D, $2E, $03
    .BYTE $95, $9A, $95, $F8, $95, $8A, $85, $AC, $85, $AD, $A9, $80, $95, $28, $A9, $FF
    .BYTE $95, $AE, $95, $A6, $9D, $9F, $03, $85, $FC, $85, $78, $85, $79, $20, $E0, $7B
    .BYTE $A6, $76, $A9, $17, $95, $8C, $A9, $0E, $95, $88, $A9, $00, $8D, $62, $03, $BD
    .BYTE $0F, $51, $95, $39, $A9, $0C, $8D, $D8, $03, $B5, $CA, $8D, $D9, $03, $20, $A1
    .BYTE $7D, $A9, $80, $8D, $D7, $03, $A6, $76, $20, $79, $7C, $20, $04, $7C, $20, $D1
    .BYTE $24, $A9, $00, $85, $02, $A6, $76, $BD, $3F, $03, $D0, $23, $A5, $02, $D0, $12
    .BYTE $B5, $88, $30, $0E, $C9, $04, $B0, $0A, $E6, $02, $A9, $14, $9D, $3F, $03, $4C
    .BYTE $FF, $7A, $B5, $88, $10, $04, $C9, $F1, $90, $10, $A9, $FB, $9D, $9F, $03, $20
    .BYTE $65, $0D, $A0, $18, $20, $94, $2E, $4C, $D5, $7A, $20, $E0, $7B, $20, $2C, $7C
    .BYTE $A6, $76, $20, $D3, $7C, $20, $04, $7C, $20, $D1, $24, $20, $A1, $7D, $A9, $81
    .BYTE $8D, $D7, $03, $A9, $00, $85, $00, $85, $01, $A0, $50, $20, $94, $2E, $A9, $20
    .BYTE $8D, $00, $D2, $85, $03, $A9, $80, $8D, $01, $D2, $85, $04, $A9, $01, $20, $A9
    .BYTE $2E, $A2, $FF, $18, $A5, $03, $69, $02, $85, $03, $29, $0F, $09, $83, $8D, $01
    .BYTE $D2, $A5, $04, $69, $00, $85, $04, $A0, $06, $20, $94, $2E, $CA, $D0, $E4, $A9
    .BYTE $70, $85, $02, $EE, $D8, $03, $AD, $D8, $03, $C9, $24, $90, $07, $29, $03, $D0
    .BYTE $03, $CE, $D9, $03, $20, $A1, $7D, $A0, $12, $38, $A5, $02, $E9, $64, $90, $11
    .BYTE $4A, $69, $12, $A8, $18, $A5, $03, $69, $11, $85, $03, $A5, $04, $69, $00, $85
    .BYTE $04, $A9, $0D, $8D, $01, $D2, $20, $94, $2E, $C6, $02, $D0, $C6, $A0, $9B, $20
    .BYTE $94, $2E, $8A, $29, $0F, $09, $03, $8D, $01, $D2, $CA, $10, $F0, $A6, $76, $A9
    .BYTE $00, $9D, $9D, $03, $A2, $00, $8E, $01, $D2, $AD, $9B, $03, $29, $10, $F0, $0F
    .BYTE $AD, $9C, $03, $29, $10, $F0, $08, $A0, $1A, $20, $94, $2E, $CA, $D0, $EA, $A6
    .BYTE $77, $86, $FC, $20, $F2, $23, $A6, $76, $86, $FC, $20, $F2, $23, $4C, $54, $0D
    .BYTE $A6, $76, $BD, $C3, $6F, $8D, $75, $28, $8D, $A5, $28, $BD, $C5, $6F, $8D, $76
    .BYTE $28, $8D, $A6, $28, $A9, $00, $BC, $63, $2A, $A2, $09, $20, $53, $28, $A6, $76
    .BYTE $20, $11, $25, $60, $A6, $76, $BD, $63, $67, $85, $2E, $A9, $1A, $85, $2F, $A0
    .BYTE $13, $20, $9F, $23, $BD, $65, $67, $85, $2E, $A9, $1A, $85, $2F, $BD, $D3, $03
    .BYTE $4A, $4A, $4A, $4A, $18, $69, $14, $A8, $20, $9F, $23, $60, $A6, $76, $BD, $F8
    .BYTE $7C, $8D, $51, $7C, $BD, $FA, $7C, $18, $7D, $63, $2A, $8D, $52, $7C, $A9, $01
    .BYTE $8D, $54, $7C, $A9, $05, $18, $7D, $63, $2A, $8D, $55, $7C, $A2, $0C, $A0, $02
    .BYTE $B9, $FF, $FF, $99, $FF, $FF, $88, $10, $F7, $AD, $51, $7C, $18, $69, $03, $8D
    .BYTE $51, $7C, $90, $03, $EE, $52, $7C, $AD, $54, $7C, $18, $69, $09, $8D, $54, $7C
    .BYTE $90, $03, $EE, $55, $7C, $CA, $10, $D6, $60, $86, $05, $84, $06, $B5, $C6, $85
    .BYTE $12, $15, $C4, $F0, $40, $B5, $C4, $85, $15, $F8, $38, $A5, $15, $E9, $01, $85
    .BYTE $15, $B0, $04, $A9, $59, $85, $15, $A5, $12, $E9, $00, $85, $12, $90, $26, $18
    .BYTE $BD, $D1, $03, $69, $07, $9D, $D1, $03, $BD, $D3, $03, $69, $00, $9D, $D3, $03
    .BYTE $90, $D8, $BD, $D5, $03, $30, $07, $A9, $99, $9D, $D3, $03, $D0, $CC, $A9, $00
    .BYTE $9D, $D5, $03, $F0, $C5, $D8, $BD, $D5, $03, $10, $08, $A9, $00, $9D, $D1, $03
    .BYTE $9D, $D3, $03, $A0, $00, $BD, $D1, $03, $20, $ED, $2A, $A0, $01, $BD, $D1, $03
    .BYTE $20, $E9, $2A, $A0, $02, $BD, $D3, $03, $20, $ED, $2A, $A0, $03, $BD, $D3, $03
    .BYTE $20, $E9, $2A, $A6, $05, $A4, $06, $60, $27, $4E, $06, $06, $19, $0F, $15, $12
    .BYTE $20, $12, $01, $0E, $0B, $09, $0E, $07, $22, $01, $20, $0B, $0E, $05, $05, $20
    .BYTE $08, $09, $07, $08, $20, $13, $10, $19, $01, $20, $13, $0D, $01, $0C, $0C, $20
    .BYTE $06, $12, $19, $20, $13, $10, $19, $01, $16, $05, $12, $01, $07, $05, $20, $07
    .BYTE $15, $19, $20, $13, $10, $19, $13, $10, $19, $20, $13, $10, $19, $20, $01, $07
    .BYTE $01, $09, $0E, $20, $20, $19, $0F, $15, $20, $13, $10, $19, $20, $08, $01, $12
    .BYTE $04, $05, $12, $20, $11, $15, $09, $14, $05, $20, $01, $20, $13, $0C, $19, $20
    .BYTE $13, $10, $19, $01, $20, $17, $09, $13, $05, $20, $07, $15, $19, $20, $13, $10
    .BYTE $19, $20, $17, $08, $01, $14, $20, $01, $20, $07, $15, $19, $20, $13, $10, $19
    .BYTE $20, $01, $20, $13, $0B, $19, $20, $08, $09, $07, $08, $20, $13, $10, $19, $20
    .BYTE $07, $12, $01, $0E, $04, $20, $0D, $01, $13, $14, $05, $12, $20, $13, $10, $19
    .BYTE $20, $86, $4F, $84, $50, $A6, $76, $A9, $C8, $8D, $30, $7E, $A9, $04, $18, $7D
    .BYTE $63, $2A, $8D, $31, $7E, $AD, $D9, $03, $85, $4C, $A9, $26, $85, $17, $18, $AD
    .BYTE $D8, $03, $29, $03, $69, $23, $4A, $4A, $85, $48, $38, $AD, $D8, $03, $E9, $04
    .BYTE $29, $FC, $0A, $85, $40, $C9, $D8, $90, $01, $60, $C9, $90, $90, $07, $C6, $48
    .BYTE $E9, $08, $4C, $DA, $7D, $AD, $D8, $03, $29, $03, $A8, $B9, $48, $68, $85, $51
    .BYTE $B9, $4C, $68, $85, $52, $B9, $50, $68, $85, $53, $B9, $54, $68, $85, $54, $A2
    .BYTE $00, $86, $16, $18, $A5, $48, $85, $49, $A4, $4C, $B9, $A8, $B6, $85, $55, $29
    .BYTE $07, $85, $57, $B9, $70, $B7, $85, $56, $B9, $38, $B8, $85, $58, $A4, $40, $B1
    .BYTE $57, $91, $55, $98, $18, $69, $08, $85, $41, $A2, $00, $A0, $00, $84, $4B, $BD
    .BYTE $FF, $FF, $99, $48, $B5, $E8, $C8, $C0, $09, $90, $F4, $A9, $00, $99, $48, $B5
    .BYTE $AD, $30, $7E, $18, $69, $09, $8D, $30, $7E, $90, $03, $EE, $31, $7E, $A2, $00
    .BYTE $BC, $48, $B5, $B1, $51, $05, $4B, $85, $59, $B1, $53, $85, $4B, $A4, $59, $B9
    .BYTE $00, $BA, $A4, $41, $31, $57, $05, $59, $91, $55, $98, $18, $69, $08, $85, $41
    .BYTE $E8, $C6, $49, $10, $DB, $E6, $4C, $C6, $17, $10, $89, $A6, $4F, $A4, $50, $60
    .BYTE $FF, $FF, $FF, $FF, $00, $FF, $02, $FF, $FF, $FF, $03, $FF, $FF, $01, $FF, $FF
    .BYTE $04, $02, $FF, $FF, $FF, $FF, $FF, $03, $FF, $05, $FF, $FF, $FF, $00, $04, $FF
    .BYTE $FF, $FF, $0D, $01, $09, $11, $FF, $FF, $00, $1F, $17, $07, $0F, $0B, $0F, $07
    .BYTE $0F, $0B, $0F, $1F, $0B, $0F, $0B, $0F, $0B, $0F, $07, $0F, $0B, $0F, $07, $0F
    .BYTE $0B, $0F, $05, $0D, $0F, $07, $0F, $0B, $0F, $07, $0F, $0B, $0F, $07, $0B, $0F
    .BYTE $07, $0F, $1F, $0F, $1F, $0F, $1F, $1D, $1F, $1D, $1F, $1D, $1F, $1D, $1F, $1B
    .BYTE $1F, $1B, $1F, $0F, $1F, $1B, $1F, $0F, $1F, $19, $1D, $1F, $1B, $1F, $1E, $1A
    .BYTE $1F, $1B, $1F, $1B, $0B, $1B, $1F, $1B, $1A, $1F, $0F, $1F, $0F, $1F, $1D, $1F
    .BYTE $0F, $1F, $1E, $1B, $1F, $1E, $0E, $0F, $1F, $1B, $1E, $0E, $1E, $1F, $1D, $1F
    .BYTE $17, $1F, $1B, $1F, $17, $07, $17, $1F, $1B, $1A, $1E, $16, $17, $16, $1E, $0E
    .BYTE $1E, $0E, $1F, $1B, $1A, $1E, $0E, $1E, $76, $88, $4C, $4F, $41, $44, $53, $50
    .BYTE $52, $54, $2A, $76, $88, $4C, $44, $53, $50, $52, $47, $45, $54, $6A, $76, $88
    .BYTE $4C, $44, $53, $50, $52, $50, $55, $54, $6D, $76, $88, $4C, $44, $53, $50, $52
    .BYTE $50, $54, $32, $73, $76, $88, $4C, $44, $53, $50, $52, $54, $58, $54, $7D, $76
    .BYTE $88, $44, $49, $53, $50, $49, $4E, $56, $53, $7E, $76, $88, $46, $4C, $53, $48
    .BYTE $49, $4E, $56, $41, $9D, $76, $08, $46, $4C, $53, $48, $49, $4E, $56, $53, $A2
    .BYTE $76, $88, $46, $4C, $53, $48, $49, $4E, $56, $31, $A8, $76, $88, $46, $4C, $53
    .BYTE $48, $49, $4E, $56, $32, $C3, $76, $88, $4E, $4F, $46, $4C, $53, $48, $49, $4E
    .BYTE $C6, $76, $88, $50, $4C, $4F, $54, $49, $4E, $06, $01, $04, $02, $03, $01, $03
    .BYTE $01, $03, $02, $07, $05, $04, $04, $02, $04, $02, $02, $01, $03, $01, $03, $01
    .BYTE $02, $01, $01, $03, $2A, $03, $01, $02, $01, $03, $01, $03, $01, $02, $02, $01
    .BYTE $03, $17, $C2, $03, $01, $04, $02, $02, $07, $01, $03, $02, $03, $03, $05, $02
    .BYTE $01, $01, $05, $01, $C6, $01, $03, $02, $06, $0C, $04, $01, $02, $03, $01, $03
    .BYTE $04, $04, $04, $08, $02, $08, $01, $01, $07, $02, $09, $05, $04, $04, $05, $03
    .BYTE $04, $03, $08, $04, $01, $09, $01, $01, $03, $0C, $0A, $01, $04, $67, $03, $01
    .BYTE $06, $8D, $0F, $03, $29, $01, $03, $04, $17, $03, $0C, $03, $01, $08, $0C, $02
    .BYTE $08, $03, $03, $09, $01, $0A, $01, $01

.ORG $4D36

XEX_4D36_287:
    .BYTE $1F, $0F, $0B, $0F, $07, $0F, $0B, $0F, $07, $0F, $0B, $1B, $1F, $17, $1F, $0B
    .BYTE $0F, $07, $0F, $0B, $0F, $07, $0F, $0B, $0F, $07, $0F, $0B, $0F, $07, $0F, $0E
    .BYTE $0F, $0D, $0F, $0E, $0F, $0D, $0F, $0E, $0F, $0D, $0F, $0D, $0F, $0E, $0F, $0D
    .BYTE $0F, $0E, $0F, $0D, $0F, $0E, $0F, $0D, $0F, $0E, $0F, $0D, $0F, $0E, $0F, $0D
    .BYTE $0F, $1F, $1D, $1F, $17, $07, $17, $16, $1E, $0E, $1F, $1B, $1A, $1E, $0E, $1E
    .BYTE $17, $16, $1E, $0E, $1E, $1F, $0F, $1F, $15, $17, $15, $1D, $17, $07, $17, $07
    .BYTE $1F, $1B, $0B, $1B, $19, $1D, $1F, $17, $16, $1E, $1F, $0F, $1D, $1B, $1E, $1B
    .BYTE $0B, $1B, $1E, $16, $17, $07, $17, $1F, $0F, $07, $1F, $1B, $1F, $0F, $1F, $0F
    .BYTE $1F, $0F, $1F, $1D, $1F, $1B, $1F, $0F, $1B, $1F, $0F, $1F, $1B, $1D, $1F, $17
    .BYTE $16, $1E, $1F, $0F, $1F, $1D, $1F, $17, $07, $1F, $1D, $1B, $0B, $1B, $1F, $1B
    .BYTE $1F, $0F, $1F, $1B, $19, $1D, $0D, $1D, $1F

.ORG $4E36

XEX_4E36_288:
    .BYTE $08, $01, $03, $01, $03, $01, $03, $01, $03, $01, $02, $06, $01, $03, $01, $03
    .BYTE $01, $03, $01, $03, $01, $03, $01, $03, $01, $02, $01, $04, $01, $02, $01, $02
    .BYTE $01, $04, $01, $01, $01, $04, $01, $02, $01, $04, $03, $04, $01, $02, $01, $04
    .BYTE $02, $02, $01, $03, $16, $02, $02, $03, $01, $02, $01, $01, $01, $02, $02, $04
    .BYTE $01, $1D, $03, $02, $13, $02, $1A, $01, $10, $01, $03, $08, $01, $05, $02, $07
    .BYTE $05, $01, $0B, $02, $02, $02, $02, $03, $01, $06, $01, $03, $0E, $01, $03, $01
    .BYTE $01, $40, $04, $02, $01, $01, $07, $0C, $06, $0A, $02, $03, $07, $0A, $02, $0C
    .BYTE $02, $0D, $04, $01, $0A, $01, $01, $06, $01, $01, $03, $14, $06, $03, $04, $02
    .BYTE $02, $03, $01, $04, $0C, $04, $15, $01, $02, $9E, $01, $01, $09, $03, $02, $07
    .BYTE $02, $0A, $01, $04, $04, $01, $02, $18, $02, $01, $06, $2A, $02, $14, $03, $07
    .BYTE $07, $02, $02, $05, $01, $0C, $02, $0D, $DC

.ORG $4F36

XEX_4F36_289:
    .BYTE $08, $01, $03, $01, $03, $01, $03, $01, $03, $01, $02, $06, $01, $03, $01, $03
    .BYTE $01, $03, $01, $03, $01, $03, $01, $03, $01, $02, $01, $04, $01, $02, $01, $02
    .BYTE $01, $04, $01, $01, $01, $04, $01, $02, $01, $04, $03, $04, $01, $02, $01, $04
    .BYTE $02, $02, $01, $03, $16, $02, $02, $03, $01, $02, $01, $01, $01, $02, $02, $04
    .BYTE $01, $1D, $03, $02, $13, $02, $1A, $01, $10, $01, $03, $08, $01, $05, $02, $07
    .BYTE $05, $01, $0B, $02, $02, $02, $02, $03, $01, $06, $01, $03, $0E, $01, $03, $01
    .BYTE $01, $40, $04, $02, $01, $01, $07, $0C, $06, $0A, $02, $03, $07, $0A, $02, $0C
    .BYTE $02, $0D, $04, $01, $0A, $01, $01, $06, $01, $01, $03, $14, $06, $03, $04, $02
    .BYTE $2C, $0F, $D4, $10, $03, $6C, $00, $02, $D8, $48, $8A, $48, $98, $48, $8D, $0F
    .BYTE $D4, $6C, $22, $02, $A5, $10, $8D, $0E, $D2, $40

.ORG $5030

XEX_5030_290:
    .BYTE $21, $7F, $AA, $C2, $94, $FF

.ORG $47EB

XEX_47EB_291:
    .BYTE $0F, $0D, $5F, $0F, $35, $CD, $75, $F7, $0D, $CD, $FD, $DC, $37, $75, $C3, $5C
    .BYTE $DC, $D7, $00, $F0, $F0, $3C, $00, $00, $00, $03, $FF, $00, $0F, $FF, $FF, $FC
    .BYTE $00, $03, $FF, $00, $00, $54, $00, $05, $55, $40, $16, $AA, $50, $0E, $EE, $C0
    .BYTE $0E, $EE, $C0, $0E, $AA, $C0, $37, $AB, $70, $37, $AB, $70, $37, $67, $70, $37
    .BYTE $67, $70, $DD, $65, $DC, $DD, $55, $DC, $D6, $9A, $5C, $3E, $9A, $F0, $0D, $55
    .BYTE $C0, $0F, $D5, $C0, $0D, $D5, $C0, $0D, $FF, $00, $0F, $F7, $00, $0D, $FF, $00
    .BYTE $03

.ORG $4854

XEX_4854_292:
    .BYTE $03, $FF, $00, $0F, $FF, $C0, $03, $FF, $00, $0D, $55, $C0, $0D, $55, $C0, $03
    .BYTE $FF, $00, $03, $77, $00, $03, $77, $00, $03, $77, $00, $03, $FF, $00, $03, $77
    .BYTE $00, $0F, $FF, $C0, $03, $FF, $00, $00, $00, $00, $0D, $5F, $C0, $0D, $5D, $C0
    .BYTE $03, $FD, $C0, $03, $7F, $C0, $03, $FD, $C0, $00, $03

.ORG $4896

XEX_4896_293:
    .BYTE $03, $FF, $00, $0F, $FF, $C0, $03, $FF, $00, $00, $54, $00, $05, $FD, $40, $15
    .BYTE $55, $50, $05, $55, $40, $0F, $57, $C0, $0D, $FD, $C0, $37, $57, $70, $37, $57
    .BYTE $70, $37, $57, $70, $37, $57, $70, $DD, $55, $DC, $DD, $55, $DC, $DD, $55, $DC
    .BYTE $3D, $55, $F0, $0D, $55, $C0, $0F, $D5, $C0, $0D, $D5, $C0, $0F, $FF, $00, $0D
    .BYTE $F7, $00, $0D, $FF, $00, $03

.ORG $48E4

XEX_48E4_294:
    .BYTE $03, $FF, $00, $0F, $FF, $C0, $03, $FF, $00, $0D, $55, $C0, $0D, $55, $C0, $03
    .BYTE $FF, $00, $03, $77, $00, $03, $77, $00, $03, $77, $00, $03, $FF, $00, $03, $77
    .BYTE $00, $0F, $FF, $C0, $03, $FF, $00, $00, $00, $00, $0D, $5F, $C0, $0D, $5D, $C0
    .BYTE $03, $FF, $C0, $03, $7D, $C0, $03, $FD, $C0, $00, $03

.ORG $4926

XEX_4926_295:
    .BYTE $03, $FF, $00, $0F, $FF, $C0, $03, $FF, $00, $00, $30, $FC, $00, $00, $FF, $C0
    .BYTE $00, $00, $FF, $80, $00, $00, $3E, $F0, $00, $00, $FA, $BC, $00, $03, $CB, $AB
    .BYTE $00, $0F, $3F, $AA, $C0, $0C, $3F, $FA, $B0, $00, $3F, $CF, $AC, $00, $FF, $C0
    .BYTE $FC, $00, $FF, $C0, $00, $03, $CF, $C0, $00, $03, $CF, $E8, $00, $0F, $FF, $F8
    .BYTE $00, $0F, $FA, $C0, $00, $00, $3E, $C0, $00, $3C, $3F, $C0, $00, $0F, $3F, $F0
    .BYTE $00, $3F, $FC, $FC, $0C, $F3, $F0, $3F, $0C, $C0, $C0, $0F, $FC, $00, $00, $03
    .BYTE $C0, $00, $00, $00, $F0, $00, $FF, $F0, $00, $3F, $FF, $FF, $C0, $03, $FF, $FC
    .BYTE $00, $0F, $FA, $00, $00, $00, $FE, $00, $00, $00, $FF, $00, $00, $00, $FF, $00
    .BYTE $00, $00, $3F, $00, $00, $00, $3C, $00, $00, $00, $3C, $00, $00, $00, $3C, $00
    .BYTE $00, $00, $3C, $00, $00, $00, $3F, $00, $00, $00, $33, $C0

.ORG $49C7

XEX_49C7_296:
    .BYTE $0F, $FA, $C0, $00, $00, $3E, $C0, $00, $00, $3F, $C0, $00, $F0, $3F, $F0, $00
    .BYTE $3C, $FC, $FC, $0C, $FF, $FC, $3F, $0C, $CF, $F0, $0F, $FC, $C3, $C0, $03, $C0
    .BYTE $00, $00, $00, $F0, $00, $FF, $F0, $00, $3F, $FF, $FF, $C0, $03, $FF, $FC, $00
    .BYTE $00, $CC, $00, $00, $FC, $00, $3F, $FF, $F0, $FF, $FF, $FC, $02, $EE, $00, $3E
    .BYTE $EE, $F0, $3E, $AA, $F0, $0F, $AB, $C0, $3F, $AB, $F0, $3F, $EF, $F0, $3F, $EF
    .BYTE $F0, $FF, $FF, $FC, $F3, $FF, $3C, $F3, $FF, $3C, $3F, $FF, $F0, $0E, $FE, $C0
    .BYTE $02, $BA, $00, $03, $FF, $00, $03, $FF, $00, $0C, $CF, $00, $0F, $C0, $00, $03
    .BYTE $C0, $00, $00, $C0

.ORG $4A45

XEX_4A45_297:
    .BYTE $03, $FF, $00, $00, $CC, $00, $00, $CC, $00, $00, $CC, $00, $03, $CF, $00, $0F
    .BYTE $03, $C0, $00, $00, $00, $03, $CC, $C0, $00, $0F, $C0, $00, $0F, $00, $00, $0C

.ORG $4A70

XEX_4A70_298:
    .BYTE $CC, $00, $00, $FC, $00, $3F, $FF, $F0, $FF, $FF, $FC, $00, $A8, $00, $0C, $FC
    .BYTE $C0, $03, $FF, $00, $03, $FF, $00, $0F, $FF, $C0, $0F, $FF, $C0, $3F, $FF, $F0
    .BYTE $3F, $FF, $F0, $F3, $FF, $3C, $F3, $FF, $3C, $3F, $FF, $F0, $0F, $FF, $C0, $03
    .BYTE $FF, $00, $03, $FF, $00, $03, $FF, $00, $00, $FF, $00, $00, $CF, $00, $03, $C0
    .BYTE $00, $03, $00, $00, $00, $FF, $00, $0F, $FF, $C0, $03, $C0, $00, $03, $FF, $00
    .BYTE $00, $CC, $00, $00, $CC, $00, $00, $CC, $00, $03, $CF, $00, $0C, $FC, $C0, $03
    .BYTE $FF, $00, $03, $FC, $00, $03, $CC, $00, $00, $0F, $00, $00, $03, $00, $03, $FC
    .BYTE $00, $0F, $FF, $C0, $00, $0F, $00, $01, $05, $00, $07, $50, $00, $0D, $6C, $00
    .BYTE $05, $AF, $00, $16, $BB, $00, $1F, $BA, $80, $47, $FA, $A0, $37, $FF, $A8, $37
    .BYTE $EF, $FA, $37, $6A, $CF, $37, $DF, $00, $00, $00, $00, $01, $05, $00, $07, $50
    .BYTE $00, $0D, $6C, $00, $05, $AF, $00, $17, $BB, $00, $1F, $BA, $80, $77, $FA, $A0
    .BYTE $37, $EF, $A8, $37, $6A, $FA, $37, $DF, $0F, $37, $7C, $00, $35, $DC, $00, $37
    .BYTE $5C, $00, $0D, $5C, $00, $35, $5C, $00, $3F, $FC, $00, $0D, $70, $00, $0D, $70
    .BYTE $00, $03, $5C, $00, $03, $5C, $00, $03, $5C, $00, $03, $70, $00, $0D, $DF, $00
    .BYTE $3F, $FC, $00, $03, $0F, $C0, $0F, $FC, $00, $0F, $F8, $00, $03, $EF, $00, $0F
    .BYTE $BB, $C0, $3C, $BA, $B0, $F3, $FA, $AC, $C3, $FF, $AB, $03, $EC, $FA, $03, $EA
    .BYTE $0F, $0F, $E8, $00, $00, $00, $00, $03, $0F, $C0, $0F, $FC, $00, $0F, $F8, $00
    .BYTE $03, $EF, $00, $0F, $BB, $C0, $3C, $BA, $B0, $F3, $FA, $AC, $C3, $EF, $AB, $03
    .BYTE $EA, $FA, $0F, $E8, $0F, $0F, $FC, $00, $0F, $FC, $00, $0F, $FC, $00, $0F, $FC
    .BYTE $00, $03, $FC, $00, $0F, $FC, $00, $0F, $FC, $00, $03, $FC, $00, $03, $C0, $00
    .BYTE $03, $C0, $00, $03, $C0, $00, $03, $C0, $00, $03, $F0, $00, $03, $3C, $00, $00
    .BYTE $00, $00, $54, $00, $00, $01, $01, $00, $11, $40, $54, $00, $44, $10, $00, $01
    .BYTE $01, $10, $A8, $01, $01, $1A, $AA, $04, $01, $5A, $EE, $04, $05, $0A, $EE, $10
    .BYTE $54, $1A, $AA, $45, $10, $50, $A8, $50, $40, $50, $A8, $01, $00, $50, $A8, $01
    .BYTE $00, $50, $20, $00, $00, $00, $54, $00, $00, $01, $01, $00, $00, $00, $54

.ORG $4C04

XEX_4C04_299:
    .BYTE $14, $50, $A8, $00, $41, $1A, $AA, $01, $01, $5A, $EE, $01, $05, $0A, $EE, $04
    .BYTE $54, $1A, $AA, $05, $10, $50, $A8, $14, $40, $50, $A8, $51, $00, $50, $A8, $41
    .BYTE $00, $50, $20, $04, $41, $50, $20, $04, $14, $54, $00, $04, $10, $15, $00, $01
    .BYTE $10, $06, $00, $51, $10, $02, $80, $55, $10, $00, $A0, $45, $40

.ORG $4C46

XEX_4C46_300:
    .BYTE $FC, $00, $00, $03, $03, $00, $33, $C0, $FC, $00, $CC, $30, $00, $03, $03, $30
    .BYTE $A8, $03, $03, $3A, $AA, $0C, $03, $FA, $EE, $0C, $0F, $0A, $EE, $30, $FC, $3A
    .BYTE $AA, $CF, $30, $F0, $A8, $F0, $C0, $F0, $A8, $03, $00, $F0, $A8, $03, $00, $F0
    .BYTE $20, $00, $00, $00, $FC, $00, $00, $03, $03, $00, $00, $00, $FC

.ORG $4C88

XEX_4C88_301:
    .BYTE $3C, $F0, $A8, $00, $C3, $3A, $AA, $03, $03, $FA, $EE, $03, $0F, $0A, $EE, $0C
    .BYTE $FC, $3A, $AA, $0F, $30, $F0, $A8, $3C, $C0, $F0, $A8, $F3, $00, $F0, $A8, $C3
    .BYTE $00, $F0, $20, $0C, $C3, $F0, $20, $0C, $3C, $FC, $00, $0C, $30, $3F, $00, $03
    .BYTE $30, $0E, $00, $F3, $30, $02, $80, $FF, $30, $00, $A0, $CF, $C0, $00, $00, $0D
    .BYTE $6C, $37, $00, $05, $AF, $37, $00, $16, $BB, $E8, $00, $1F, $FF, $70, $00, $4D
    .BYTE $55, $70, $00, $0D, $55, $E8, $00, $0F, $FF, $FA, $00, $0D, $5C, $0F, $00, $0D
    .BYTE $5C, $00, $00, $0D, $5C

.ORG $4CF2

XEX_4CF2_302:
    .BYTE $0D, $01, $05, $00, $37, $07, $50, $00, $DC, $0D, $6C, $03, $70, $05, $AF, $0D
    .BYTE $C0, $16, $BB, $27, $00, $1F, $BB, $E8, $00, $4D, $FD, $7C, $00, $0D, $75, $E8
    .BYTE $00, $0F, $57, $FA, $00, $0D, $DC, $0F, $00, $0D, $7C, $00, $00, $0D, $5C, $00
    .BYTE $00, $0D, $FF, $A8, $0F, $0D, $7C, $FF, $F5, $0F, $5F, $E9, $5F, $0D, $D5, $6F
    .BYTE $F0, $0D, $7F, $F0, $00, $0D, $5C, $00, $00, $0D, $5C, $00, $00, $0D, $5C, $00
    .BYTE $00, $35, $5C, $00, $00, $3F, $FC, $00, $00, $0D, $7F, $00, $00, $0F, $57, $C0
    .BYTE $00, $0D, $F5, $C0, $00, $F5, $CD, $C0, $00, $57, $0D, $C0, $00, $DC, $0D, $70
    .BYTE $00, $D7, $FD, $DC, $00, $FF, $FF, $FF, $00, $01, $05, $00, $00, $07, $50, $00
    .BYTE $00, $0D, $6C, $00, $00, $05, $AF, $00, $00, $16, $BB, $00, $00, $1F, $BA, $80
    .BYTE $00, $4D, $FA, $A0, $00, $0D, $DF, $A8, $00, $0D, $7C, $FA, $00, $0F, $7C, $0F
    .BYTE $00, $0F, $5C, $00, $00, $0D, $DC, $00, $00, $0D, $D7, $FF, $FF, $0D, $75, $E9
    .BYTE $55, $0D, $5F, $FF, $FF, $35, $DC, $FA, $00, $37, $5C, $0F, $00, $D7, $5C, $00
    .BYTE $00, $DD, $5C, $00, $00, $D7, $FF, $FF, $F0, $35, $E9, $55, $50, $0F, $FF, $FF
    .BYTE $F0, $01, $05, $00, $07, $50, $00, $0D, $6C, $00, $05, $AF, $00, $16, $AB, $00
    .BYTE $1F, $BE, $80, $4F, $FF, $A0, $0D, $CF, $A8, $0D, $70, $FA, $37, $5C, $0F, $35
    .BYTE $D7, $00, $35, $F5, $C0, $D5, $CD, $70, $D5, $C3, $E0, $D5, $70, $E8, $35, $70
    .BYTE $08, $3F, $F0, $00, $0D, $5C, $00, $03, $57, $30, $00, $F5, $DC, $00, $0D, $5C
    .BYTE $00, $03, $70, $00, $00, $C0, $0F, $FF, $F0, $03, $FF, $FC, $01, $05, $00, $07
    .BYTE $50, $00, $0D, $40, $00, $05, $AC, $00, $16, $AF, $00, $1F, $AB, $00, $4F, $BA
    .BYTE $00, $0D, $FA, $80, $0D, $DE, $80, $0D, $DE, $A0, $0D, $DC, $A0, $0D, $7C, $20
    .BYTE $0F, $5C, $00, $0D, $D7, $C0, $0D, $75, $EA, $35, $5F, $E8, $3F, $FC, $00, $0D
    .BYTE $7C, $00, $03, $57, $0C, $00, $F5, $F7, $00, $0F, $5F, $00, $00, $F7, $00, $00
    .BYTE $0F, $0F, $FF, $FC, $0F, $FF, $FF, $0F, $F8, $0C, $00, $03, $EF, $0C, $00, $0F
    .BYTE $AB, $E8, $00, $3C, $BB, $FC, $00, $F3, $FF, $FC, $00, $C3, $FF, $EB, $00, $03
    .BYTE $FF, $3A, $C0, $03, $FC, $0F, $C0, $00, $00, $00, $0F, $03, $0F, $C0, $3C, $0F
    .BYTE $FC, $00, $F0, $0F, $F8, $03, $C0, $03, $EF, $0F, $00, $0F, $AB, $EC, $00, $3C
    .BYTE $BA, $F8, $00, $F3, $FB, $FC, $00, $C3, $FF, $FB, $00, $03, $FF, $FA, $C0, $03
    .BYTE $FF, $0F, $C0, $03, $FC, $00, $00, $03, $FC, $00, $00, $03, $FC, $00, $00, $03
    .BYTE $FC, $00, $00, $03, $FC, $00, $00, $0F, $FF, $00, $00, $0F, $FC, $00, $00, $03
    .BYTE $FF, $00, $00, $03, $FF, $C0, $00, $03, $CF, $C0, $00, $0F, $C3, $C0, $00, $3F
    .BYTE $C3, $C0, $00, $FF, $03, $C0, $00, $3C, $FF, $F0, $00, $FF, $FF, $3C, $00, $03
    .BYTE $FC, $FA, $0F, $03, $FC, $0F, $FF, $03, $FF, $FA, $F0, $03, $FF, $F8, $00, $03
    .BYTE $FF, $C0, $00, $03, $FC, $00, $00, $03, $FC, $00, $00, $03, $0F, $C0, $00, $0F
    .BYTE $FC, $00, $00, $0F, $F8, $00, $00, $03, $EF, $00, $00, $0F, $AB, $C0, $00, $3C
    .BYTE $BA, $B0, $00, $F3, $FA, $AC, $00, $C3, $FF, $AB, $00, $03, $FC, $FA, $C0, $03
    .BYTE $FC, $0F, $C0, $03, $FC, $00, $00, $03, $FF, $00, $00, $03, $FF, $C0, $00, $03
    .BYTE $FF, $FA, $FF, $03, $FC, $FB, $FF, $0F, $FC, $FA, $C0, $0F, $FC, $0F, $C0, $3F
    .BYTE $FC, $00, $00, $3F, $FC, $00, $00, $3F, $FC, $00, $00, $0F, $FA, $FF, $F0, $03
    .BYTE $FB, $FF, $F0, $03, $0F, $C0, $0F, $FC, $00, $0F, $F8, $00, $03, $EF, $00, $0F
    .BYTE $AB, $C0, $3C, $BE, $B0, $F3, $EF, $AC, $CF, $FB, $AB, $0F, $FC, $FA, $3F, $FC
    .BYTE $0F, $3F, $FF, $00, $3F, $CF, $C0, $FF, $03, $F0, $FF, $00, $FA, $FF, $C0, $02
    .BYTE $3F, $C0, $00, $3F, $F0, $00, $0F, $FC, $00, $00, $FF, $30, $00, $0F, $F0, $00
    .BYTE $03, $C0, $00, $00, $C0, $00, $00, $00, $0F, $FF, $F0, $03, $FF, $FC, $03, $0F
    .BYTE $C0, $0F, $FC, $00, $0F, $F0, $00, $03, $EC, $00, $0F, $AF, $00, $3F, $AB, $00
    .BYTE $F3, $BA, $00, $C3, $FA, $80, $03, $FE, $80, $03, $FE, $A0, $03, $FC, $A0, $03
    .BYTE $FC, $20, $03, $FF, $00, $03, $FF, $C0, $03, $FF, $E8, $0F, $FC, $C8, $0F, $F0
    .BYTE $00, $03, $FC, $00, $00, $FF, $00, $00, $0F, $CC, $00, $03, $F0, $00, $00, $FC
    .BYTE $00, $00, $00, $0F, $FF, $FC, $0F, $FF, $FF, $00, $03, $F0, $00, $00, $35, $57
    .BYTE $00, $00, $17, $75, $00, $00, $1F, $7D, $00, $00, $1F, $7D, $00, $00, $35, $57
    .BYTE $00, $00, $DD, $5D, $C0, $03, $7D, $5F, $70, $0D, $DF, $7D, $DC, $37, $03, $F0
    .BYTE $37, $37, $05, $D4, $37, $DC, $0F, $7C, $0D, $DC, $05, $D4, $0D, $74, $0F, $7C
    .BYTE $05, $DC, $01, $D0, $0D, $30, $03, $70, $03, $00, $01, $D0, $00, $00, $0D, $5F
    .BYTE $00, $00, $D7, $75, $C0, $03, $7F, $FF, $70, $1D, $C0, $00, $DD, $37, $00, $00
    .BYTE $37, $00, $04, $04, $00, $00, $11, $11, $10, $00, $40, $40, $44, $00, $40, $00
    .BYTE $01, $01, $03, $F0, $01, $04, $35, $57, $04, $10, $17, $75, $01, $04, $1F, $7D
    .BYTE $04, $01, $1F, $7D, $10, $04, $35, $57, $15, $10, $DD, $5D, $C1, $43, $7D, $5F
    .BYTE $71, $4D, $DF, $7D, $DC, $37, $03, $F0, $37, $37, $05, $D4, $37, $DC, $0F, $7C
    .BYTE $0D, $DC, $45, $D4, $4D, $74, $4F, $7C, $45, $DC, $11, $D1, $0D, $30, $43, $70
    .BYTE $43, $41, $01, $D0, $10, $14, $0D, $5F, $05, $37, $57, $70, $35, $FD, $70, $0F
    .BYTE $FF, $C0, $0D, $75, $C0, $03, $CF

.ORG $50B0

XEX_50B0_303:
    .BYTE $03, $FF, $00, $0F, $FF, $C0, $03, $CF, $00, $03, $57, $00, $00, $FC

.ORG $50CB

XEX_50CB_304:
    .BYTE $03, $CF, $00, $0F, $FF, $C0, $03, $FF, $00, $0C, $FC, $C0, $0F, $CF, $C0, $03
    .BYTE $CF, $00, $00, $CC, $00, $00, $FC, $00, $FF, $FF, $FF, $FF, $FF, $00, $00, $00
    .BYTE $FF, $02, $02, $02, $FF, $01, $03, $FF, $FF, $FF, $01, $FF, $FF, $FF, $FF, $02
    .BYTE $03, $FF, $FF, $FF, $FF, $00, $FF, $FF, $02, $05, $08, $0B, $0E, $11, $14, $17
    .BYTE $00, $06, $00, $04, $05, $11, $1D, $1F, $19, $1B, $26, $2D, $41, $43, $34, $3B
    .BYTE $42, $44, $42, $44, $42, $44, $00, $00, $03, $00, $00, $03, $00, $00, $03, $00
    .BYTE $0B, $00, $00, $0B, $00, $00, $0B, $00, $3E, $3E, $3D, $3D, $05, $11, $3E, $3E
    .BYTE $3D, $3D, $05, $11, $3E, $3E, $3D, $3D, $05, $11

.ORG $514A

XEX_514A_305:
    .BYTE $01, $01, $01, $00, $03, $03, $03, $00, $02, $04, $00, $21, $28, $2F, $36, $24
    .BYTE $2B, $33, $3A, $23, $2A, $31, $38, $25, $2C, $32, $39, $22, $29, $30, $37, $FF
    .BYTE $FF, $FF, $FF, $3B, $34, $FF, $FF, $3C, $35, $2E, $27, $FF, $FF, $2D, $26, $FF
    .BYTE $FF, $FF, $FF, $00, $00, $00, $00, $01, $01

.ORG $518B

XEX_518B_306:
    .BYTE $01, $01, $00, $00, $00, $00, $0C, $09, $0C, $09, $0A, $07, $0A, $07, $09, $06
    .BYTE $08, $06, $08, $06, $01, $00, $FF

.ORG $51AA

XEX_51AA_307:
    .BYTE $01, $00, $FF

.ORG $51B3

XEX_51B3_308:
    .BYTE $CB, $D0, $D5, $DA, $DF, $E4, $E9, $EE, $F3, $F8, $FD, $02, $51, $51, $51, $51
    .BYTE $51, $51, $51, $51, $51, $51, $51, $52, $05, $00, $00, $00, $00, $05, $01, $01
    .BYTE $00, $01, $05, $02, $02, $00, $00, $05, $03, $01, $00, $02, $05, $04, $01, $01
    .BYTE $00, $05, $05, $01, $02, $00, $00, $02, $04, $00, $00, $00, $03, $01, $00, $04
    .BYTE $00, $00, $03, $00, $00, $00, $01, $01, $00, $03, $00, $04, $01, $03, $00, $00
    .BYTE $05, $01, $04, $00, $11, $17, $1D, $23, $24, $52, $52, $52, $52, $52, $01, $01
    .BYTE $01, $01, $01, $01

.ORG $521D

XEX_521D_309:
    .BYTE $FF, $FF, $FF, $FF, $FF, $FF, $02, $FE, $2F, $35, $3B, $41, $42, $52, $52, $52
    .BYTE $52, $52

.ORG $5235

XEX_5235_310:
    .BYTE $FF, $FF, $FF, $FF, $FF, $FF, $01, $01, $01, $01, $01, $01, $02, $FE, $4D, $53
    .BYTE $59, $5F, $60, $52, $52, $52, $52, $52

.ORG $5253

XEX_5253_311:
    .BYTE $02, $03, $02, $02, $03, $02, $FE, $FF, $FE, $FE, $FF, $FE, $01, $FF, $79, $7F
    .BYTE $85, $8B, $91, $97, $9D, $A3, $A9, $AF, $B5, $BB, $52, $52, $52, $52, $52, $52
    .BYTE $52, $52, $52, $52, $52, $52, $01, $02, $03, $03, $02, $01, $04, $05, $06, $06
    .BYTE $05, $04, $07, $08, $09, $09, $08, $07, $0A, $0B, $0C, $0C, $0B, $0A, $0A, $0B
    .BYTE $0C, $0C, $0B, $0A, $0A, $0B, $0C, $0C, $0B, $0A, $0D, $0E, $0F, $0F, $0E, $0D
    .BYTE $10, $11, $12, $12, $11, $10, $13, $14, $15, $15, $14, $13, $16, $17, $18, $18
    .BYTE $17, $16, $16, $17, $18, $18, $17, $16, $16, $17, $18, $18, $17, $16, $4B, $53
    .BYTE $5B, $63, $6B, $73, $7B, $83, $8B, $93, $9B, $A3, $AB, $B3, $BB, $C3, $CB, $D3
    .BYTE $DB, $E3, $EB, $F3, $FB, $03, $0B, $13, $1B, $23, $2B, $33, $3B, $43, $4B, $53
    .BYTE $5F, $69, $75, $7D, $87, $8D, $93, $9F, $A9, $B3, $BB, $C5, $CB, $D1, $DD, $E7
    .BYTE $F3, $FB, $05, $0B, $11, $1D, $27, $31, $39, $43, $49, $4F, $59, $61, $69, $71
    .BYTE $7B, $85, $8F, $53, $53, $53, $53, $53, $53, $53, $53, $53, $53, $53, $53, $53
    .BYTE $53, $53, $53, $53, $53, $53, $53, $53, $53, $53, $54, $54, $54, $54, $54, $54
    .BYTE $54, $54, $54, $54, $54, $54, $54, $54, $54, $54, $54, $54, $54, $54, $54, $54
    .BYTE $54, $54, $54, $54, $54, $54, $54, $55, $55, $55, $55, $55, $55, $55, $55, $55
    .BYTE $55, $55, $55, $55, $55, $55, $55, $55, $0A, $02, $00, $03, $0E, $05, $0A, $07
    .BYTE $0F, $02, $00, $01, $10, $01, $08, $02, $0F, $02, $00, $01, $10, $01, $08, $03
    .BYTE $0F, $02, $00, $01, $10, $01, $08, $04, $0A, $02, $00, $03, $0E, $05, $0A, $06
    .BYTE $0A, $02, $00, $03, $0E, $05, $0A, $07, $0A, $02, $00, $03, $0E, $05, $0A, $08
    .BYTE $0F, $02, $00, $02, $10, $01, $08, $02, $0F, $02, $00, $02, $10, $01, $08, $03
    .BYTE $0F, $02, $00, $02, $10, $01, $08, $04, $0A, $02, $00, $03, $0E, $09, $0A, $0A
    .BYTE $0A, $02, $00, $03, $0E, $09, $0A, $0B, $0A, $02, $00, $03, $0E, $09, $0A, $0C
    .BYTE $0F, $02, $00, $01, $0D, $0D, $0B, $0E, $0F, $02, $00, $01, $0D, $0D, $0B, $0F
    .BYTE $0F, $02, $00, $01, $0D, $0D, $0B, $10, $0A, $02, $00, $03, $12, $11, $06, $12
    .BYTE $0A, $02, $00, $03, $12, $11, $06, $13, $0A, $02, $00, $03, $12, $11, $06, $14
    .BYTE $0F, $02, $00, $02, $0D, $0D, $0B, $0E, $0F, $02, $00, $02, $0D, $0D, $0B, $0F
    .BYTE $0F, $02, $00, $02, $0D, $0D, $0B, $10, $0A, $02, $00, $03, $12, $15, $06, $16
    .BYTE $0A, $02, $00, $03, $12, $15, $06, $17, $0A, $02, $00, $03, $12, $15, $06, $18
    .BYTE $0B, $02, $00, $03, $0A, $19, $0D, $1B, $0B, $02, $00, $03, $0A, $1A, $0D, $1B
    .BYTE $0B, $02, $00, $03, $0A, $1C, $0D, $1E, $0B, $02, $00, $03, $0A, $1D, $0D, $1E
    .BYTE $0F, $02, $00, $03, $0C, $1F, $06, $21, $0F, $02, $00, $03, $0C, $20, $06, $21
    .BYTE $0F, $02, $00, $03, $0C, $22, $06, $24, $0F, $02, $00, $03, $0C, $23, $06, $24
    .BYTE $0F, $04, $00, $01, $01, $2A, $09, $25, $02, $28, $09, $29, $0F, $03, $FF, $01
    .BYTE $0C, $26, $02, $28, $09, $29, $0F, $04, $00, $01, $06, $2A, $04, $27, $02, $28
    .BYTE $09, $29, $0F, $02, $00, $01, $0E, $2A, $09, $29, $0F, $03, $00, $01, $07, $2A
    .BYTE $06, $2B, $09, $29, $0B, $01, $00, $01, $18, $2C, $0B, $01, $00, $01, $18, $2D
    .BYTE $0F, $04, $00, $01, $01, $33, $07, $2E, $04, $31, $09, $32, $0F, $03, $FF, $01
    .BYTE $0A, $2F, $04, $31, $09, $32, $0F, $03, $00, $01, $07, $33, $06, $30, $09, $32
    .BYTE $0F, $02, $00, $01, $0E, $33, $09, $32, $0F, $03, $00, $01, $07, $33, $06, $34
    .BYTE $09, $32, $0B, $01, $00, $01, $18, $35, $0A, $01, $00, $01, $18, $36, $0F, $04
    .BYTE $00, $02, $01, $2A, $09, $25, $02, $28, $09, $29, $0F, $03, $FF, $02, $0C, $26
    .BYTE $02, $28, $09, $29, $0F, $04, $00, $02, $06, $2A, $04, $27, $02, $28, $09, $29
    .BYTE $0F, $02, $00, $02, $0E, $2A, $09, $29, $0F, $03, $00, $02, $07, $2A, $06, $2B
    .BYTE $09, $29, $0B, $01, $00, $02, $18, $2C, $0B, $01, $00, $02, $18, $2D, $0F, $04
    .BYTE $00, $02, $01, $33, $07, $2E, $04, $31, $09, $32, $0F, $03, $FF, $02, $0A, $2F
    .BYTE $04, $31, $09, $32, $0F, $03, $00, $02, $07, $33, $06, $30, $09, $32, $0F, $02
    .BYTE $00, $02, $0E, $33, $09, $32, $0F, $03, $00, $02, $07, $33, $06, $34, $09, $32
    .BYTE $0B, $01, $00, $02, $18, $35, $0A, $01, $00, $02, $18, $36, $0F, $03, $FC, $03
    .BYTE $03, $00, $11, $37, $03, $39, $0F, $02, $FC, $03, $15, $38, $03, $39, $0F, $02
    .BYTE $05, $01, $0D, $01, $06, $3A, $0F, $02, $05, $01, $0D, $0D, $06, $3B, $0A, $03
    .BYTE $00, $03, $0E, $05, $05, $3C, $03, $40, $0A, $03, $00, $03, $0E, $09, $02, $3D
    .BYTE $05, $41, $0A, $03, $00, $03, $11, $11, $03, $3E, $03, $40, $0A, $03, $00, $03
    .BYTE $12, $15, $00, $3F, $05, $41, $00, $5F, $A3, $C7, $EB, $0F, $3C, $5D, $7E, $9F
    .BYTE $CC, $ED, $0E, $2F, $67, $97, $C7, $F7, $30, $45, $5A, $6F, $A8, $BD, $D2, $E7
    .BYTE $08, $29, $53, $74, $95, $BF, $F3, $27, $43, $77, $AB, $C7, $EF, $23, $37, $43
    .BYTE $6B, $A7, $C3, $0E, $59, $79, $E1, $A5, $B9, $FD, $39, $55, $A0, $EB, $43, $33
    .BYTE $00, $00, $9B, $B9, $D4, $E0, $AD, $C2, $BB, $47, $47, $47, $47, $48, $48, $48
    .BYTE $48, $48, $48, $48, $49, $49, $49, $49, $49, $49, $4A, $4A, $4A, $4A, $4A, $4A
    .BYTE $4A, $4A, $4B, $4B, $4B, $4B, $4B, $4B, $4B, $4C, $4C, $4C, $4C, $4C, $4C, $4D
    .BYTE $4D, $4D, $4D, $4D, $4D, $4E, $4E, $4E, $4E, $4E, $4E, $4E, $4F, $4F, $4F, $4F
    .BYTE $50, $50, $00, $00, $50, $50, $50, $50, $50, $50, $00, $00, $0F, $10, $0F, $08
    .BYTE $0F, $08, $0F, $08, $0A, $0E, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0E, $0A, $0A
    .BYTE $0A, $0A, $0A, $0A, $0F, $0D, $0F, $0B, $0F, $0B, $0F, $0B, $0A, $12, $0A, $06
    .BYTE $0A, $06, $0A, $06, $0A, $12, $0A, $06, $0A, $06, $0A, $06, $0B, $0A, $0B, $0A
    .BYTE $0B, $0D, $0B, $0A, $0B, $0A, $0B, $0D, $0F, $0C, $0F, $0C, $0F, $06, $0F, $0C
    .BYTE $0F, $0C, $0F, $06, $0F, $09, $0F, $0C, $0F, $04, $0F, $02, $0F, $09, $0F, $0E
    .BYTE $0F, $06, $0B, $18, $0B, $18, $0F, $07, $0F, $0A, $0F, $06, $0F, $04, $0F, $09
    .BYTE $0F, $0E, $0F, $06, $0B, $18, $0A, $18, $0F, $11, $0F, $15, $0F, $03, $0F, $06
    .BYTE $0F, $06, $0A, $05, $0A, $02, $0A, $03, $0A, $00, $0A, $03, $0A, $05, $03, $01
    .BYTE $01, $01, $01, $03, $03, $03, $03, $03, $03, $03, $03, $01, $01, $01, $01, $03
    .BYTE $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03
    .BYTE $03, $03, $03, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
    .BYTE $01, $01, $01, $01, $01, $03, $03, $03, $01, $01, $03, $03, $03, $03, $03, $03
    .BYTE $E8, $18, $00, $18, $00, $00, $E7, $19, $00, $18, $00, $00, $00, $00, $03, $03
    .BYTE $00, $00, $FE, $FE, $00, $00, $00, $02, $08, $0E, $14, $14, $F6, $02, $08, $F6
    .BYTE $03, $03, $07, $0C, $20, $34, $57, $57, $57, $FF, $14, $FF, $14, $FF, $FF, $FF
    .BYTE $FF, $02, $02, $02, $02, $02, $02, $02, $02, $02, $0E, $02, $14, $FF, $FF, $FF
    .BYTE $13, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $0D, $01
    .BYTE $07, $07, $02, $02, $07, $07, $02, $02, $07, $F0, $F0, $0E, $F3, $F0, $F0, $0E
    .BYTE $F3, $F0, $F0, $F9, $F9, $F0, $F0, $F9, $F9, $07, $02, $02, $07, $07, $02, $02
    .BYTE $07, $F9, $05, $05, $F9, $F9, $F9, $05, $F9, $18, $19, $1E, $23, $1A, $1F, $24
    .BYTE $1B, $20, $25, $1C, $21, $26, $1D, $22, $27, $28, $00, $04, $08, $0C, $10, $14
    .BYTE $01, $05, $09, $0D, $11, $15, $02, $06, $0A, $0E, $12, $16, $03, $07, $0B, $0F
    .BYTE $13, $17, $04, $00, $0C, $08, $14, $10, $05, $01, $0D, $09, $15, $11, $06, $02
    .BYTE $0E, $0A, $16, $12, $07, $03, $0F, $0B, $17, $13, $15, $EB, $17, $01, $00, $00
    .BYTE $01, $00, $03, $02, $05, $04, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A
    .BYTE $81, $82, $83, $84, $85, $86, $87, $88, $89, $8A, $03, $04, $05, $06, $08, $09
    .BYTE $83, $84, $85, $86, $88, $89, $00, $29, $52, $7B, $A4, $CD, $F6, $1F, $48, $71
    .BYTE $9A, $C3, $EC, $15, $3E, $67, $90, $B9, $E2, $0B, $34, $5D, $86, $AF, $D8, $01
    .BYTE $2A, $53, $7C, $A5, $CE, $F7, $20, $49, $72, $9B, $7A, $7A, $7A, $7A, $7A, $7A
    .BYTE $7A, $7B, $7B, $7B, $7B, $7B, $7B, $7C, $7C, $7C, $7C, $7C, $7C, $7D, $7D, $7D
    .BYTE $7D, $7D, $7D, $7E, $7E, $7E, $7E, $7E, $7E, $7E, $7F, $7F, $7F, $7F, $06, $55
    .BYTE $45, $93, $0B, $AB, $D1, $79, $7D, $86, $87, $87, $88, $84, $88, $86, $85, $D9
    .BYTE $01, $0E, $22, $92, $43, $DF, $B5, $58, $59, $59, $59, $58, $59, $58, $58, $58
    .BYTE $48, $50, $38, $28, $38, $50, $38, $30, $28, $28, $18, $28, $18, $18, $18, $06
    .BYTE $0D, $14, $21, $23, $24, $22, $24, $02, $04, $03, $06, $08, $06, $06, $07, $01
    .BYTE $02, $02, $06, $02, $06, $05, $05, $08, $06, $04, $02, $02, $02, $02, $02, $72
    .BYTE $76, $7A, $7E, $82, $86, $8A, $8E, $58, $58, $58, $58, $58, $58, $58, $58, $02
    .BYTE $03, $03, $04, $02, $03, $04, $05, $02, $05, $0C, $0F, $09, $0A, $0B, $0C, $06
    .BYTE $15, $0E, $1C, $02, $03, $14, $16, $02, $05, $1A, $1B, $06, $07, $16, $23, $14
    .BYTE $15, $13, $16, $12, $02, $01, $00, $10, $11, $20, $21, $22, $80, $81, $90, $91
    .BYTE $92, $A0, $A1, $06, $07, $08, $17, $18, $26, $27, $28, $87, $88, $96, $97, $98
    .BYTE $A7, $A8, $21, $31, $00, $01, $10, $11, $06, $07, $16, $17, $30, $40, $50, $41
    .BYTE $51, $26, $36, $37, $47, $57, $46, $56, $92, $91, $A1, $B1, $C1, $C2, $C3, $C4
    .BYTE $C5, $C6, $B6, $A6, $96, $95, $11, $12, $02, $01, $00, $10, $22, $23, $00, $01
    .BYTE $02, $03, $04, $10, $11, $12, $13, $14, $20, $21, $24, $30, $31, $32, $33, $34
    .BYTE $40, $41, $42, $43, $44, $B4, $B5, $B6, $C4, $C5, $C6, $D4, $D5, $D6, $12, $02
    .BYTE $00, $01, $03, $04, $10, $14, $20, $21, $22, $23, $24, $11, $12, $00, $01, $02
    .BYTE $03, $10, $13, $20, $21, $22, $23, $80, $81, $82, $83, $90, $91, $92, $93, $23
    .BYTE $24, $22, $32, $34, $42, $43, $44, $53, $01, $02, $03, $04, $05, $10, $11, $15
    .BYTE $16, $20, $26, $30, $36, $40, $46, $50, $51, $55, $56, $61, $62, $63, $64, $65
    .BYTE $23, $13, $02, $04, $12, $14, $22, $24, $32, $34, $42, $43, $44, $52, $53, $54
    .BYTE $62, $64, $A0, $A1, $A2, $A3, $A4, $A5, $A6, $B1, $B2, $B4, $B5, $C0, $C1, $C2
    .BYTE $C3, $C4, $C5, $C6, $00, $00, $02, $00, $02, $00, $06, $00, $06, $00, $00, $0E
    .BYTE $00, $00, $0A, $00, $00, $01, $05, $09, $00, $9D, $A2, $9D, $A2, $A7, $AC, $A7
    .BYTE $AC, $B1, $B6, $BB, $C0, $C5, $CA, $CF, $C5, $00, $59, $59, $59, $59, $59, $59
    .BYTE $59, $59, $59, $59, $59, $59, $59, $59, $59, $59, $E8, $05, $04, $0C, $0D, $E8
    .BYTE $03, $04, $12, $13, $17, $84, $06, $0E, $0F, $17, $82, $04, $1C, $1D, $00, $0C
    .BYTE $00, $10, $11, $00, $0B, $03, $14, $15, $00, $03, $01, $16, $17, $00, $0A, $03
    .BYTE $1E, $1F, $00, $08, $01, $20, $21, $00, $03, $03, $22, $23, $00, $08, $00, $24
    .BYTE $25, $08, $0D, $0C, $09, $09, $08, $1B, $19, $1A, $1A, $19, $1A, $19, $18

.ORG $59EA

XEX_59EA_312:
    .BYTE $2D, $2C, $2B, $2A, $29, $28, $27, $26

.ORG $59FA

XEX_59FA_313:
    .BYTE $2F, $2E, $2F, $2E, $2F, $2E, $2F, $2E, $1B, $18, $19, $1A, $19, $1A, $19, $18
    .BYTE $00, $00, $08, $08, $00, $00, $00, $00, $F4, $F4, $F9, $F9, $FE, $FE, $03, $03
    .BYTE $52, $9E, $19, $91, $09, $60, $B7, $BF, $C7, $C7, $11, $47, $67, $67, $B2, $B2
    .BYTE $F7, $F7, $5B, $5B, $83, $83, $DD, $F9, $23, $73, $CF, $00, $2B, $4F, $73, $BE
    .BYTE $09, $09, $33, $71, $CE, $CE, $06, $12, $2A, $63, $8D, $00, $B1, $C9, $D7, $00
    .BYTE $E9, $60, $E9, $40, $5B, $5B, $5C, $5C, $5D, $5D, $5D, $5D, $5D, $5D, $5E, $5E
    .BYTE $5E, $5E, $5E, $5E, $5E, $5E, $5F, $5F, $5F, $5F, $5F, $5F, $60, $60, $60, $BB
    .BYTE $61, $61, $61, $61, $62, $62, $62, $62, $62, $62, $63, $63, $63, $63, $63, $BB
    .BYTE $63, $63, $63, $BB, $63, $5D, $63, $64, $02, $03, $03, $03, $03, $03, $04, $04
    .BYTE $02, $02, $06, $04, $03, $03, $03, $03, $05, $05, $02, $02, $05, $05, $02, $03
    .BYTE $04, $04, $04, $04, $02, $02, $03, $03, $03, $03, $02, $03, $04, $04, $02, $03
    .BYTE $03, $03, $03, $03, $02, $02, $02, $02, $03, $03, $03, $03, $25, $28, $27, $27
    .BYTE $1C, $1C, $01, $01, $11, $24, $08, $07, $14, $18, $16, $16, $0E, $13, $0E, $13
    .BYTE $11, $11, $0D, $0D, $16, $16, $16, $16, $11, $11, $18, $18, $0D, $0D, $1E, $1E
    .BYTE $0D, $0D, $05, $07, $12, $19, $0B, $07, $0B, $06, $08, $08, $1C, $1C, $1C, $1C
    .BYTE $00, $00, $FA, $FA, $00, $00, $00, $00, $FC, $FC, $F4, $F8, $00, $00, $FC, $FC
    .BYTE $00, $00, $FC, $FC, $00, $00, $00, $FC, $F8, $F8, $F8, $F8, $00, $00, $04, $00
    .BYTE $00, $00, $00, $FC, $FC, $FC, $04

.ORG $5B18

XEX_5B18_314:
    .BYTE $FC, $FC, $00, $00, $00, $00, $E7, $E4, $E7, $E7, $EE, $EE, $0E, $0E, $E7, $E7
    .BYTE $0B, $0B, $FA, $F6, $FE, $FA, $F1, $EC, $F2, $ED, $FE, $00, $F6, $F6, $F4, $F4
    .BYTE $F4, $F4, $F2, $F2, $F5, $F5, $01, $FC, $F1, $F1, $F0, $EC, $E8, $E8, $E8, $E8
    .BYTE $01, $EE, $01, $01, $00, $00, $EE, $EE, $EE, $EE, $00, $30, $00, $F0, $03, $B0
    .BYTE $0E, $B0, $3A, $B0, $EA, $B0, $EA, $B0, $EA, $B0, $EA, $B0, $EA, $B0, $EA, $B0
    .BYTE $EA, $B0, $EA, $B0, $EA, $B0, $EA, $B0, $EA, $B0, $EA, $B0, $EA, $B0, $EA, $B0
    .BYTE $EE, $B0, $FE, $B0, $EE, $B0, $EA, $B0, $EA, $B0, $EA, $B0, $EA, $B0, $EA, $B0
    .BYTE $EA, $B0, $EA, $B0, $EA, $B0, $EA, $B0, $EA, $80, $EA, $00, $EA, $00, $E8, $00
    .BYTE $E0, $00, $E0, $00, $C0, $00, $00, $00, $30, $00, $00, $F0, $00, $03, $B0, $00
    .BYTE $3E, $B0, $00, $FA, $B0, $03, $3A, $B0, $0F, $3A, $B0, $33, $3A, $B0, $C3, $3A
    .BYTE $B0, $C3, $3A, $B0, $C3, $3A, $B0, $C3, $3A, $B0, $C3, $3A, $B0, $C3, $3A, $B0
    .BYTE $C3, $3A, $F0, $C3, $3A, $F0, $C3, $3A, $F0, $C3, $3A, $B0, $C3, $3A, $B0, $C3
    .BYTE $3A, $B0, $C3, $3A, $B0, $C3, $3A, $B0, $C3, $3A, $B0, $C3, $3A, $B0, $C3, $3A
    .BYTE $B0, $C3, $3A, $B0, $C3, $3A, $B0, $C3, $3A, $B0, $C3, $3A, $B0, $C3, $3A, $B0
    .BYTE $C3, $3A, $C0, $C3, $3B, $00, $C3, $3C, $00, $C3, $30, $00, $C3, $00, $00, $C3
    .BYTE $00, $00, $CC, $00, $00, $F0, $00, $00, $F0, $00, $00, $C0, $00, $00, $C0, $00
    .BYTE $00, $03, $00, $00, $03, $C0, $00, $03, $B0, $00, $03, $AC, $00, $03, $AB, $00
    .BYTE $03, $AA, $C0, $03, $AA, $C0, $03, $AA, $C0, $03, $AA, $C0, $03, $AA, $C0, $03
    .BYTE $AA, $C0, $03, $AA, $C0, $03, $AA, $C0, $03, $AA, $C0, $03, $AA, $C0, $03, $AA
    .BYTE $C0, $03, $AA, $C0, $03, $AA, $C0, $03, $AA, $C0, $03, $AA, $C0, $03, $AE, $C0
    .BYTE $03, $AF, $C0, $03, $AE, $C0, $03, $AA, $C0, $03, $AA, $C0, $03, $AA, $C0, $03
    .BYTE $AA, $C0, $03, $AA, $C0, $03, $AA, $C0, $03, $AA, $C0, $03, $AA, $C0, $03, $AA
    .BYTE $C0, $03, $AA, $C0, $00, $EA, $C0, $00, $3A, $C0, $00, $3A, $C0, $00, $0E, $C0
    .BYTE $00, $03, $C0, $00, $03, $C0, $00, $00, $C0, $03, $00, $00, $03, $C0, $00, $03
    .BYTE $30, $00, $03, $3C, $00, $03, $33, $00, $03, $30, $C0, $03, $30, $C0, $03, $30
    .BYTE $C0, $03, $30, $C0, $03, $30, $C0, $03, $30, $C0, $03, $30, $C0, $03, $30, $C0
    .BYTE $03, $30, $C0, $03, $30, $C0, $03, $30, $C0, $03, $30, $C0, $03, $30, $C0, $03
    .BYTE $30, $C0, $03, $30, $C0, $03, $30, $C0, $03, $30, $C0, $03, $30, $C0, $03, $30
    .BYTE $C0, $03, $30, $C0, $03, $30, $C0, $03, $30, $C0, $03, $30, $C0, $03, $30, $C0
    .BYTE $03, $30, $C0, $03, $30, $C0, $03, $30, $C0, $03, $30, $C0, $00, $CC, $C0, $00
    .BYTE $3C, $C0, $00, $33, $C0, $00, $0C, $C0, $00, $03, $C0, $00, $03, $C0, $00, $00
    .BYTE $C0, $FF, $FF, $FF, $FF, $FF, $FF, $EA, $AA, $AB, $EA, $AA, $AB, $EA, $AA, $AB
    .BYTE $EA, $AA, $AB, $EA, $AA, $AB, $EA, $AA, $AB, $EA, $AA, $AB, $EA, $AA, $AB, $EA
    .BYTE $AA, $AB, $EA, $AA, $AB, $EA, $AA, $AB, $EA, $AA, $AB, $EF, $AA, $AB, $EF, $AA
    .BYTE $AB, $EA, $AA, $AB, $EA, $AA, $AB, $EA, $AA, $AB, $EA, $AA, $AB, $EA, $AA, $AB
    .BYTE $EA, $AA, $AB, $EA, $AA, $AB, $EA, $AA, $AB, $EA, $AA, $AB, $EA, $AA, $AB, $EA
    .BYTE $AA, $AB, $EA, $AA, $AB, $EA, $AA, $AB, $FF, $FF, $FF, $FF, $FF, $FF, $C0, $00
    .BYTE $03, $C0, $00, $03, $C0, $00, $03, $C0, $00, $03, $C0, $00, $03, $C0, $00, $03
    .BYTE $C0, $00, $03, $C0, $00, $03, $C0, $00, $03, $C0, $00, $03, $C0, $00, $03, $C0
    .BYTE $00, $03, $C0, $00, $03, $C0, $00, $03, $C0, $00, $03, $C0, $00, $03, $C0, $00
    .BYTE $03, $C0, $00, $03, $C0, $00, $03, $C0, $00, $03, $C0, $00, $03, $C0, $00, $03
    .BYTE $C0, $00, $03, $C0, $00, $03, $C0, $00, $03, $C0, $00, $03, $C0, $00, $03, $EA
    .BYTE $AA, $AA, $AB, $EA, $AA, $AA, $AB, $C0, $00, $00, $03, $C0, $00, $00, $03, $C0
    .BYTE $0C, $C0, $0C, $FF, $FC, $C0, $0C, $C0, $0C, $C0, $0C, $FF, $FC, $C0, $0C, $C0
    .BYTE $0C, $C0, $0C, $FF, $FC, $C0, $0C, $C0, $0C, $C0, $0C, $FF, $FC, $C0, $0C, $C0
    .BYTE $0C, $C0, $0C, $FF, $FC, $C0, $0C, $C0, $0C, $C0, $0C, $FF, $FC, $C0, $0C, $C0
    .BYTE $0C, $C0, $0C, $FF, $FC, $C0, $0C, $C0, $0C, $C0, $0C, $FF, $FC, $C0, $0C, $C0
    .BYTE $0C, $C0, $0C, $FF, $FC, $C0, $0C, $C0, $0C, $03, $FF, $FF, $FF, $FC, $00, $0C
    .BYTE $88, $88, $88, $8B, $00, $0E, $22, $22, $22, $23, $00, $0C, $88, $88, $88, $8B
    .BYTE $00, $32, $22, $22, $22, $22, $C0, $38, $88, $88, $88, $88, $C0, $32, $22, $22
    .BYTE $22, $22, $C0, $C8, $88, $88, $88, $88, $B0, $E2, $22, $22, $22, $22, $30, $00
    .BYTE $FF, $F0, $00, $0F, $00, $0F, $00, $30, $00, $00, $C0, $C0, $FF, $F0, $30, $CF
    .BYTE $FF, $FF, $30, $3F, $FF, $FF, $C0, $0F, $FF, $FF, $00, $00, $FF, $F0, $00, $03
    .BYTE $FF, $C0, $0F, $FF, $C0, $3F, $FE, $C0, $FF, $FA, $C0, $FF, $EA, $C0, $FF, $EA
    .BYTE $C0, $FF, $FF, $C0, $FF, $EE, $C0, $FF, $FA, $C0, $FF, $EA, $C0, $FF, $EA, $C0
    .BYTE $FF, $FF, $C0, $FF, $EE, $C0, $FF, $FA, $C0, $FF, $EA, $C0, $FF, $EA, $C0, $FF
    .BYTE $FF, $C0, $FF, $EB, $00, $FF, $EC, $00, $FF, $F0, $00, $FF, $C0, $00, $00, $3F
    .BYTE $00, $0F, $FC, $00, $3F, $F0, $00, $FF, $C0, $00, $FF, $FC, $00, $D5, $57, $00
    .BYTE $F5, $55, $C0, $DD, $55, $70, $D7, $55, $5C, $D5, $FF, $FF, $D5, $D5, $57, $DD
    .BYTE $D5, $57, $D5, $D5, $57, $D5, $D5, $57, $F5, $D5, $57, $DD, $D5, $57, $DD, $D5
    .BYTE $57, $D7, $D5, $57, $D5, $D5, $57, $D5, $D5, $57, $DD, $D5, $57, $D5, $D5, $57
    .BYTE $35, $D5, $57, $0D, $D5, $57, $03, $D5, $57, $00, $D5, $57, $00, $3F, $FF, $00
    .BYTE $02, $AA, $80, $00, $AA, $AA, $AA, $AA, $AA, $A5, $55, $55, $55, $5A, $A5, $57
    .BYTE $55, $55, $5A, $A5, $57, $55, $75, $5A, $A7, $DF, $D5, $F5, $5A, $A7, $DF, $D5
    .BYTE $F7, $DA, $A7, $DF, $D5, $F7, $DA, $A7, $DF, $FD, $F7, $DA, $A7, $DF, $FD, $FF
    .BYTE $DA, $AF, $DF, $FD, $FF, $DA, $AF, $FF, $FF, $FF, $FA, $AF, $FF, $FF, $FF, $FA
    .BYTE $AF, $FF, $FF, $FF, $FA, $AA, $AA, $AA, $AA, $AA, $33, $00, $00, $00, $CC, $33
    .BYTE $00, $00, $00, $CC, $33, $FF, $FF, $FF, $CC, $3C, $00, $00, $00, $3C, $3F, $FF
    .BYTE $FF, $FF, $FC, $00, $0F, $00, $3B, $00, $EF, $03, $FB, $03, $BB, $03, $BB, $03
    .BYTE $BB, $03, $BB, $03, $BB, $03, $BB, $03, $BB, $03, $BB, $03, $BB, $03, $BC, $03
    .BYTE $F0, $03, $F0, $03, $F0, $03, $F0, $03, $C0, $03, $00, $0F, $FF, $FF, $FC, $00
    .BYTE $3F, $FF, $FF, $FF, $00, $3F, $FF, $FF, $FF, $00, $FF, $FF, $FF, $FF, $C0, $EA
    .BYTE $AA, $AE, $AA, $C0, $EA, $BE, $AE, $BA, $C0, $EA, $AA, $AE, $AA, $C0, $FF, $FF
    .BYTE $FF, $FF, $C0, $CC, $00, $0E, $AA, $C0, $CC, $00, $0E, $BA, $C0, $CC, $00, $0E
    .BYTE $AA, $C0, $CC, $00, $0E, $BA, $C0, $CC, $00, $0F, $FF, $C0, $CC, $00, $0E, $AA
    .BYTE $C0, $CC, $00, $0E, $BA, $C0, $C0, $00, $0E, $AA, $C0, $C0, $00, $0E, $AA, $C0
    .BYTE $C0, $00, $0F, $FF, $C0, $15, $55, $FF, $FF, $55, $55, $55, $55, $56, $95, $56
    .BYTE $95, $56, $95, $6A, $A9, $6A, $A9, $56, $95, $56, $95, $56, $95, $55, $55, $55
    .BYTE $55, $15, $55, $00, $FF, $FF, $00, $55, $55, $FF, $55, $55, $03, $56, $95, $03
    .BYTE $56, $95, $03, $56, $95, $03, $6A, $A9, $03, $6A, $A9, $03, $56, $95, $03, $56
    .BYTE $95, $03, $56, $95, $FF, $55, $55, $00, $55, $55

.ORG $6040

XEX_6040_315:
    .BYTE $0C, $C0, $00, $00, $0F, $BC, $00, $00, $CE, $B0, $00, $00, $3A, $AC, $00, $00
    .BYTE $39, $B0, $00, $00, $EA, $AC, $00, $00, $3A, $B0, $00, $00, $FE, $C0, $00, $00
    .BYTE $33, $30

.ORG $6081

XEX_6081_316:
    .BYTE $C0, $00, $00, $33, $7C, $00, $00, $DE, $AB, $00, $00, $EA, $AC, $00, $03, $BA
    .BYTE $BB, $00, $0D, $AE, $AA, $C0, $03, $EB, $BA, $70, $00, $ED, $DE, $C0, $03, $9B
    .BYTE $7B, $00, $0E, $9D, $7A, $F0, $03, $AB, $EB, $C0, $00, $EA, $9A, $70, $03, $AE
    .BYTE $BE, $C0, $0D, $AE, $AB, $00, $03, $BA, $BF, $00, $00, $CD, $C0, $00, $00, $03

.ORG $60D0

XEX_60D0_317:
    .BYTE $C0, $F0, $00, $03, $73, $5C, $C0, $0D, $AE, $A7, $70, $0D, $AB, $AB, $5C, $03
    .BYTE $AB, $AE, $54, $0E, $EE, $95, $64, $3A, $AA, $96, $B0, $DB, $BD, $A5, $AC, $DE
    .BYTE $DD, $69, $67, $3A, $F5, $5B, $7C, $0E, $E5, $96, $F0, $3A, $99, $65, $AC, $DA
    .BYTE $57, $55, $BB, $E9, $65, $D6, $E4, $3E, $59, $6E, $B7, $37, $96, $59, $AC, $D5
    .BYTE $A5, $69, $EC, $59, $69, $BA, $B0, $15, $5E, $AE, $B0, $05, $96, $AE, $9C, $0D
    .BYTE $5A, $AE, $9C, $0E, $7A, $B3, $70, $0D, $CD, $C0, $C0, $FC, $00, $F7, $00, $DD
    .BYTE $C0, $D7, $70, $D5, $FC, $D5, $DC, $D5, $DC, $D5, $DC, $F5, $DC, $D5, $DC, $D5
    .BYTE $DC, $D5, $DC, $D5, $DC, $D5, $DC, $35, $DC, $0D, $DC, $03, $DC, $00, $FC, $FC
    .BYTE $00, $F7, $00, $FD, $C0, $FF, $70, $FF, $FC, $55, $DC, $55, $DC, $55, $DC, $55
    .BYTE $DC, $55, $DC, $D5, $DC, $55, $DC, $55, $DC, $55, $DC, $55, $DC, $55, $DC, $55
    .BYTE $DC, $FF, $FC, $00, $00, $00, $0F, $FF, $F0, $35, $55, $F0, $FF, $FF, $70, $D5
    .BYTE $57, $70, $D5, $57, $70, $D7, $D7, $70, $D5, $57, $70, $D5, $57, $70, $D5, $57
    .BYTE $70, $FF, $FF, $70, $D5, $57, $70, $D5, $57, $70, $D7, $D7, $70, $D5, $57, $70
    .BYTE $D5, $57, $70, $D5, $57, $70, $FF, $FF, $70, $D5, $57, $70, $D5, $57, $70, $D7
    .BYTE $D7, $70, $D5, $57, $70, $D5, $57, $70, $D5, $57, $C0, $FF, $FF, $00, $00, $0F
    .BYTE $C0, $00, $F5, $C0, $0F, $7F, $70, $37, $D7, $70, $FD, $57, $70, $D5, $D7, $70
    .BYTE $D7, $57, $5C, $D5, $57, $5C, $D5, $5F, $DC, $F5, $F5, $DC, $3F, $55, $DC, $35
    .BYTE $55, $D7, $35, $5D, $D7, $35, $75, $77, $3D, $55, $77, $0D, $57, $F7, $0D, $7D
    .BYTE $75, $0F, $D5, $75, $0D, $55, $5D, $0D, $57, $5F, $03, $5D, $5F, $03, $55, $5C
    .BYTE $03, $55, $F0, $03, $5F, $FF, $03, $FF, $FC, $2A, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AB, $FE, $BA, $AF, $FF, $AA, $AF, $FF, $BA, $AF, $FF, $AA, $AF, $FF
    .BYTE $BA, $AF, $FF, $AA, $AB, $FE, $AA, $AA, $AA, $AA, $AE, $EE, $AA, $AA, $AA, $A8
    .BYTE $30, $00, $30, $03, $00, $0F, $C0, $03, $00, $CF, $CC, $33, $30, $23, $10, $23
    .BYTE $14, $23, $54, $23, $54, $A3, $54, $AB, $54, $AB, $54, $AB, $54, $AB, $50, $AB
    .BYTE $50, $AB, $50, $AB, $40, $AB, $40, $AB, $00, $AB, $00, $AB, $00, $8B, $00, $8B
    .BYTE $00, $0B, $00, $0B, $00, $03, $00, $33, $30, $CF, $CC, $0F, $C0, $30, $30, $30
    .BYTE $30, $00, $30, $00, $00, $3C, $00, $00, $F0, $00, $00, $3C, $C0, $0C, $F3, $00
    .BYTE $03, $31, $00, $02, $31, $40, $02, $35, $40, $02, $35, $40, $02, $35, $40, $0A
    .BYTE $0D, $40, $0A, $8D, $40, $0A, $8D, $40, $0A, $8D, $00, $0A, $8D, $00, $0A, $8D
    .BYTE $00, $0A, $8C, $00, $0A, $8C, $00, $0A, $8C, $00, $0A, $8C, $00, $0A, $8C, $00
    .BYTE $0A, $83, $00, $08, $83, $00, $08, $83, $00, $00, $83, $00, $00, $83, $30, $00
    .BYTE $33, $CC, $00, $CF, $C0, $00, $0F, $30, $00, $C0, $30, $00, $C0, $00, $55, $55
    .BYTE $55, $54, $40, $00, $00, $04, $40, $3F, $F0, $04, $43, $FF, $FF, $04, $43, $AA
    .BYTE $AB, $04, $42, $BE, $FA, $04, $42, $AB, $AA, $04, $42, $AF, $EA, $04, $40, $B9
    .BYTE $B8, $04, $40, $AA, $A8, $04, $40, $0A, $80, $04, $40, $56, $54, $04, $41, $55
    .BYTE $55, $04, $55, $55, $55, $54, $03, $F0, $30, $F0, $30, $F0, $03, $F0, $03, $F0
    .BYTE $03, $F0, $00, $00, $C0, $00, $1F, $C0, $00, $5F, $F0, $00, $5F, $F0, $00, $53
    .BYTE $F0, $01, $53, $C0, $01, $40, $00, $00, $40, $00, $00, $03, $00, $00, $0F, $C0
    .BYTE $00, $7F, $F0, $01, $4F, $FC, $01, $43, $F0, $01, $40, $C0, $01, $40, $00, $01
    .BYTE $40, $00, $01, $40, $00, $01, $40, $00, $05, $40, $00, $05, $40, $00, $01, $40
    .BYTE $00, $01, $40, $00, $11, $40, $00, $11, $40, $00, $01, $00, $00, $05, $00, $00
    .BYTE $00, $40

.ORG $6367

XEX_6367_318:
    .BYTE $0F, $C0, $00, $0F, $FC, $00, $3F, $FC, $00, $3F, $F0, $00, $03, $F0, $00, $40

.ORG $637C

XEX_637C_319:
    .BYTE $40, $00, $00, $00, $00, $04, $00, $00, $04, $40, $00, $04, $40, $00, $04, $40
    .BYTE $00, $05, $40, $00, $05, $40, $00, $05, $40, $00, $05, $40, $00, $05, $40, $00
    .BYTE $05, $40, $00, $15, $40, $00, $55, $00, $00, $51, $40, $00, $11, $40, $00, $11
    .BYTE $04, $00, $45, $41, $80, $00, $40, $04, $40, $04, $00, $05, $00, $05, $00, $05
    .BYTE $40, $05, $40, $05, $11, $01, $10, $51, $14, $11, $55, $45, $45, $00, $40, $00
    .BYTE $40

.ORG $63D2

XEX_63D2_320:
    .BYTE $01, $05, $55, $54, $54, $0C, $C0, $0F, $7C, $CD, $70, $35, $5C, $34, $70, $D5
    .BYTE $5C, $D5, $70, $FD, $C0, $33, $30, $FF, $FF, $FF, $EA, $AA, $AB, $EA, $AA, $AB
    .BYTE $EA, $AA, $AB, $EA, $AA, $AB, $EA, $AF, $AB, $EA, $BE, $BB, $EB, $FF, $FB, $EF
    .BYTE $FF, $EB, $EA, $BE, $AB, $EA, $AF, $AB, $EA, $AA, $AB, $EA, $AA, $AB, $EA, $A5
    .BYTE $AB, $EA, $96, $9B, $E9, $55, $5B, $E5, $55, $6B, $EA, $96, $AB, $EA, $A5, $AB
    .BYTE $EA, $AA, $AB, $EA, $AA, $AB, $EA, $AA, $AB, $EA, $AA, $AB, $EA, $AA, $AB, $EA
    .BYTE $AA, $AB, $EA, $AA, $AB, $EA, $AA, $AB, $EA, $AA, $AB, $EA, $AA, $AB, $FF, $FF
    .BYTE $FF, $C0, $00, $03, $C0, $FF, $C3, $C0, $EA, $C3, $C3, $AA, $B3, $C3, $BB, $B3
    .BYTE $C3, $AE, $B3, $CE, $BF, $AF, $CE, $E6, $EF, $FE, $AA, $AF, $D7, $AA, $B7, $FD
    .BYTE $FF, $DF, $FA, $A6, $AB, $FA, $E6, $EB, $FA, $A6, $AB, $FA, $A6, $AB, $CE, $E6
    .BYTE $EF, $CE, $A6, $AF, $CD, $55, $5F, $CE, $AE, $AF, $CE, $AE, $AF, $CE, $BF, $AF
    .BYTE $CE, $F3, $EF, $C3, $F3, $F3, $C0, $F3, $C3, $C0, $F3, $C3, $C0, $F3, $C3, $C3
    .BYTE $33, $33, $C0, $00, $03, $08, $04, $02, $01, $01, $02, $04, $08, $0F, $10, $00
    .BYTE $00, $9F, $AF, $19, $27, $31, $37, $66, $66, $66, $66, $BD, $D9, $ED, $F9, $64
    .BYTE $64, $64, $64, $CB, $E3, $F3, $07, $64, $64, $64, $65, $74, $75, $76, $77, $F0
    .BYTE $F1, $F2, $7C, $7D, $7E, $7F, $F8, $F9, $FA, $00, $00, $00, $00, $01, $01, $01
    .BYTE $00, $00, $00, $00, $01, $01, $01, $85, $86, $87, $00, $01, $8D, $8E, $8F, $08
    .BYTE $09, $00, $00, $00, $02, $02, $00, $00, $00, $02, $02, $96, $97, $10, $9E, $9F
    .BYTE $18, $00, $00, $02, $00, $00, $02, $A6, $A7, $20, $21, $22, $23, $24, $AE, $AF
    .BYTE $28, $29, $2A, $2B, $2C, $00, $00, $02, $02, $02, $02, $02, $00, $00, $02, $02
    .BYTE $02, $02, $02, $0E, $0A, $06, $0E, $55, $55, $55, $55, $55, $55, $55, $55, $55
    .BYTE $55, $55, $55, $55, $55, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A
    .BYTE $0B, $0B, $0B, $0B, $0C, $0D, $00, $32, $98, $54, $C6, $94, $F6, $D6, $C8, $84
    .BYTE $08, $01, $00, $FF, $00, $00, $01, $00, $FF, $02, $00, $01, $02, $00, $01, $00
    .BYTE $01, $00, $04, $07, $05, $09, $06, $09, $A3, $B0, $BD, $3E, $51, $FF, $00, $01
    .BYTE $04, $64, $80, $83, $86, $89, $8C, $8F, $92, $95, $98, $9B, $9E, $A1, $A4, $A7
    .BYTE $65, $65, $65, $65, $65, $65, $65, $65, $65, $65, $65, $65, $65, $65, $EB, $1B
    .BYTE $34, $EB, $1B, $08, $F7, $08, $00, $EB, $1B, $00, $EB, $1B, $00, $EB, $1B, $00
    .BYTE $EB, $1B, $00, $EB, $1B, $00, $EB, $19, $00, $EB, $1B, $00, $EB, $1B, $06, $EB
    .BYTE $19, $0A, $ED, $01, $0A, $ED, $01, $00, $00, $00, $F2, $F1, $01, $01, $02, $02
    .BYTE $E0, $E0, $97, $9B, $E0, $E0, $9F, $A3, $19, $27, $31, $37, $45, $5F, $6F, $7D
    .BYTE $9D, $AB, $B9, $C7, $D7, $E1, $F5, $0D, $1D, $31, $49, $66, $66, $66, $66, $66
    .BYTE $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $67, $67, $67, $67, $02, $02
    .BYTE $02, $02, $03, $02, $03, $03, $03, $02, $01, $02, $02, $02, $01, $02, $02, $02
    .BYTE $02, $07, $06, $05, $09, $0D, $08, $07, $10, $07, $07, $07, $08, $05, $0A, $0C
    .BYTE $08, $0A, $0C, $0C, $00, $00, $00, $00, $08, $00, $00, $08, $08

.ORG $6619

XEX_6619_321:
    .BYTE $45, $41, $43, $43, $43, $53, $55, $45, $05, $05, $05, $05, $15, $55, $FF, $FD
    .BYTE $DD, $FD, $FF, $FF, $7F, $77, $7F, $FF, $59, $66, $59, $69, $AA, $55, $55, $55
    .BYTE $56, $5A, $6A, $6A, $59, $65, $A9, $A9, $A5, $95, $55, $55, $02, $07, $0F, $1F
    .BYTE $3F, $7F, $FF, $07, $07, $0F, $1F, $3F, $3F, $00, $00, $80, $C0, $E0, $F0, $F8
    .BYTE $00, $00, $80, $C0, $E0, $E0, $30, $48, $84, $FC, $84, $84, $84, $78, $00, $00
    .BYTE $00, $00, $78, $78, $78, $00, $64, $9A, $65, $97, $65, $9A, $64, $00, $64, $1A
    .BYTE $08, $1A, $64, $00, $04, $1F, $7F, $FF, $95, $04, $04, $04, $04, $04, $04, $04
    .BYTE $04, $04, $04, $04, $00, $00, $C0, $E0, $20

.ORG $669D

XEX_669D_322:
    .BYTE $40, $A0, $F7, $18, $F8, $A7, $40

.ORG $66AB

XEX_66AB_323:
    .BYTE $18, $20, $70, $F8, $F8, $F8, $70

.ORG $66B9

XEX_66B9_324:
    .BYTE $60, $10, $60, $90, $60, $90, $60

.ORG $66C7

XEX_66C7_325:
    .BYTE $70, $88, $88, $70, $70, $70, $70, $70

.ORG $66D7

XEX_66D7_326:
    .BYTE $F8, $78, $E0, $C0, $C0

.ORG $66E1

XEX_66E1_327:
    .BYTE $20, $40, $8C, $92, $62, $04, $18, $60, $80, $60

.ORG $66F5

XEX_66F5_328:
    .BYTE $20, $40, $20, $40, $A0, $E0, $E0, $E0, $E0, $E0, $E0, $40

.ORG $670D

XEX_670D_329:
    .BYTE $0C, $12, $21, $42, $84, $88, $50, $20, $30, $4C, $5E, $3C, $78, $70, $20, $00
    .BYTE $28, $54, $28, $38, $54, $44, $82, $82, $44, $38, $00, $28, $10, $00, $28, $38
    .BYTE $7C, $7C, $38, $00, $3C, $42, $89, $99, $5D, $2A, $34, $54, $28, $10, $00, $00
    .BYTE $00, $3C, $76, $66, $22, $10, $08, $28, $10, $00, $10, $10

.ORG $6756

XEX_6756_330:
    .BYTE $3C, $76, $66, $22, $10, $08, $28, $10, $00, $10, $10, $06, $12, $06, $12, $07
    .BYTE $13, $0F, $15, $14, $20, $0F, $06, $20, $14, $09, $0D, $05, $2E, $2E, $2E, $0D
    .BYTE $FC, $CC, $CC, $CC, $FC, $CC, $CC, $CC, $CC, $FC, $FC, $30, $30, $30, $30, $FC
    .BYTE $C0, $F0, $C0, $C0, $FC, $30, $30, $30, $FC, $CC, $FC, $CC, $CC, $CC, $FC, $C0
    .BYTE $F0, $C0, $FC

.ORG $67A1

XEX_67A1_331:
    .BYTE $30, $30, $7B, $7D, $7C, $7E, $07, $12, $15, $20, $22, $24, $24, $24, $07, $0C
    .BYTE $0F, $14, $16, $18, $18, $18, $00, $0D, $0A, $06, $03, $02, $00, $09, $00, $03
    .BYTE $06, $00, $01, $02, $02, $03, $02, $01, $01, $01, $02, $03, $02, $02, $03, $02
    .BYTE $01, $01, $01, $02, $03, $02, $00, $0F, $1E, $00, $05, $0A, $00, $01, $02, $03
    .BYTE $04, $02, $01, $01, $01, $01, $02, $02, $02, $04, $05, $02, $02, $01, $04, $06
    .BYTE $02, $02, $02, $02, $06, $06, $06, $06, $06, $06, $02, $02, $02, $03, $06, $01
    .BYTE $01, $01, $01, $06, $04, $04, $04, $04, $06, $01, $01, $01, $06, $06, $01, $00
    .BYTE $FF, $00, $02, $00, $FE, $00, $00, $00, $01, $00, $FF, $00, $02, $00, $FE, $00
    .BYTE $F7, $FD, $FB, $FE, $F7, $FD, $FB, $FE, $FF, $FB, $F7, $FE, $FD, $FE, $FE, $FE
    .BYTE $FE, $FF, $F7, $FB, $FD, $FE, $FD, $FD, $FD, $FD, $FF, $00, $01, $02, $00, $01
    .BYTE $02, $00, $00, $00, $01, $01, $01, $00, $00, $00, $00, $04, $05, $06, $07, $00
    .BYTE $00, $00, $00, $08, $09, $0A, $0B, $C0, $30, $0C, $03, $3F, $0F, $03, $00, $00
    .BYTE $01, $02, $FF, $00, $C0, $F0, $FC, $FF, $02, $01, $00, $00, $01, $01, $01, $01
    .BYTE $02, $02, $02, $02, $03, $03, $03, $03, $04, $04, $04, $04, $05, $05, $05, $05
    .BYTE $2C, $8C, $60, $A0, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $05
    .BYTE $06, $06, $06, $07, $07, $07, $08, $08, $08, $09, $09, $09, $0A, $00, $0B, $16
    .BYTE $21, $2C, $37, $42, $4D, $58, $63, $6E, $79, $84, $8F, $9A, $A5, $B0, $BB, $C6
    .BYTE $D1, $DC, $E7, $F2, $00, $00, $00, $00, $01, $01, $02, $02, $03, $03, $04, $04
    .BYTE $05, $05, $06, $06, $07, $07, $08, $08, $09, $09, $0A, $0A, $0B, $0B, $0B, $0C
    .BYTE $0C, $0D, $0D, $0E, $0E, $0F, $0F, $10, $10, $11, $11, $12, $12, $13, $13, $14
    .BYTE $14, $15, $15, $16, $16, $16, $16, $48, $58, $B5, $B5, $A8, $A8, $A2, $B2, $01
    .BYTE $00, $03, $02, $05, $04, $04, $0E, $18, $22, $2C, $36, $40, $69, $69, $69, $69
    .BYTE $69, $69, $69, $A6, $9A, $55, $9A, $A6, $AA, $AA, $5A, $AA, $AA, $A9, $AA, $55
    .BYTE $AA, $A9, $AA, $6A, $5A, $6A, $AA, $A9, $A5, $99, $A9, $A9, $AA, $6A, $9A, $AA
    .BYTE $AA, $A9, $A9, $99, $A5, $A9, $AA, $AA, $9A, $6A, $AA, $A6, $A5, $A6, $A5, $A6
    .BYTE $6A, $6A, $6A, $6A, $6A, $A9, $A6, $A6, $A6, $A9, $6A, $9A, $9A, $9A, $6A, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $80, $30, $60, $40, $80, $20, $70

.ORG $6956

XEX_6956_332:
    .BYTE $80, $80, $80, $00, $00, $F6, $00, $F6, $EC, $F6, $F1, $FD, $48, $40, $38, $30
    .BYTE $48, $C8, $08, $48, $50, $48, $D0, $C8, $10, $08, $9B, $9B, $9B, $9B, $97, $98
    .BYTE $9A, $9B, $9F, $9F, $A0, $A0, $A2, $A2, $48, $40, $38, $30, $AB, $AB, $AB, $AB
    .BYTE $70, $78, $89, $91, $A2, $AA, $97, $97, $97, $97, $97, $97, $70, $78, $89, $91
    .BYTE $A2, $AA, $A7, $A7, $A7, $A7, $A7, $A7, $B2, $B7, $BC, $C1, $C6, $CB, $D0, $D5
    .BYTE $DA, $DF, $69, $69, $69, $69, $69, $69, $69, $69, $69, $69, $EA, $EE, $EE, $EE
    .BYTE $EA, $FB, $FB, $FB, $FB, $FB, $EA, $FE, $EA, $EF, $EA, $EA, $FE, $EA, $FE, $EA
    .BYTE $EE, $EE, $EA, $FE, $FE, $EA, $EF, $EA, $FE, $EA, $EA, $EF, $EA, $EE, $EA, $EA
    .BYTE $FE, $FE, $FE, $FE, $EA, $EE, $EA, $EE, $EA, $EA, $EE, $EA, $FE, $FE, $68, $98
    .BYTE $B5, $B5, $F2, $02, $12, $22, $69, $6A, $6A, $6A, $00, $60, $FF, $D5, $D5, $D5
    .BYTE $D5, $D5, $D5, $FF, $FF, $57, $57, $57, $57, $57, $57, $FF, $FF, $EA, $EA, $EA
    .BYTE $EA, $EA, $EA, $FF, $FF, $AB, $AB, $AB, $AB, $AB, $AB, $FF, $FF, $D5, $D5, $D7
    .BYTE $D7, $D5, $D5, $FF, $FF, $57, $57, $D7, $D7, $57, $57, $FF, $FF, $EA, $EA, $EB
    .BYTE $EB, $EA, $EA, $FF, $FF, $AB, $AB, $EB, $EB, $AB, $AB, $FF, $D7, $BE, $A5, $8C
    .BYTE $73, $5A, $41, $28, $0F, $F6, $DD, $C4, $AB, $92, $79, $60, $47, $2E, $15, $FC
    .BYTE $E3, $CA, $B1, $98, $7F, $66, $6C, $6C, $6C, $6C, $6C, $6C, $6C, $6C, $6C, $6B
    .BYTE $6B, $6B, $6B, $6B, $6B, $6B, $6B, $6B, $6B, $6A, $6A, $6A, $6A, $6A, $6A, $6A
    .BYTE $21, $22, $23, $23, $24, $25, $25, $26, $27, $28, $28, $29, $2A, $2A, $2B, $2C
    .BYTE $2C, $2D, $2E, $2F, $2F, $30, $31, $31, $32, $20, $20, $21, $22, $22, $23, $24
    .BYTE $24, $25, $26, $26, $27, $28, $28, $29, $2A, $2A, $2B, $2C, $2C, $2D, $2E, $2E
    .BYTE $2F, $30, $1F, $1F, $20, $20, $21, $22, $22, $23, $24, $24, $25, $26, $26, $27
    .BYTE $28, $28, $29, $29, $2A, $2B, $2B, $2C, $2D, $2D, $2E, $1D, $1E, $1E, $1F, $20
    .BYTE $20, $21, $22, $22, $23, $23, $24, $25, $25, $26, $26, $27, $28, $28, $29, $2A
    .BYTE $2A, $2B, $2B, $2C, $1C, $1C, $1D, $1E, $1E, $1F, $1F, $20, $21, $21, $22, $22
    .BYTE $23, $24, $24, $25, $25, $26, $26, $27, $28, $28, $29, $29, $2A, $1B, $1B, $1C
    .BYTE $1C, $1D, $1D, $1E, $1E, $1F, $20, $20, $21, $21, $22, $22, $23, $24, $24, $25
    .BYTE $25, $26, $26, $27, $27, $28, $19, $1A, $1A, $1B, $1B, $1C, $1C, $1D, $1D, $1E
    .BYTE $1F, $1F, $20, $20, $21, $21, $22, $22, $23, $23, $24, $24, $25, $25, $26, $18
    .BYTE $18, $19, $19, $1A, $1A, $1B, $1B, $1C, $1C, $1D, $1D, $1E, $1E, $1F, $1F, $20
    .BYTE $20, $21, $21, $22, $22, $23, $23, $24, $17, $17, $18, $18, $18, $19, $19, $1A
    .BYTE $1A, $1B, $1B, $1C, $1C, $1D, $1D, $1E, $1E, $1F, $1F, $20, $20, $21, $21, $22
    .BYTE $22, $15, $16, $16, $17, $17, $17, $18, $18, $19, $19, $1A, $1A, $1B, $1B, $1C
    .BYTE $1C, $1C, $1D, $1D, $1E, $1E, $1F, $1F, $20, $20, $14, $14, $15, $15, $16, $16
    .BYTE $16, $17, $17, $18, $18, $19, $19, $19, $1A, $1A, $1B, $1B, $1B, $1C, $1C, $1D
    .BYTE $1D, $1E, $1E, $13, $13, $13, $14, $14, $15, $15, $15, $16, $16, $17, $17, $17
    .BYTE $18, $18, $18, $19, $19, $1A, $1A, $1A, $1B, $1B, $1C, $1C, $11, $12, $12, $12
    .BYTE $13, $13, $13, $14, $14, $15, $15, $15, $16, $16, $16, $17, $17, $17, $18, $18
    .BYTE $19, $19, $19, $1A, $1A, $10, $10, $11, $11, $11, $12, $12, $12, $13, $13, $13
    .BYTE $14, $14, $14, $15, $15, $15, $16, $16, $16, $17, $17, $17, $18, $18, $0F, $0F
    .BYTE $0F, $10, $10, $10, $10, $11, $11, $11, $12, $12, $12, $13, $13, $13, $14, $14
    .BYTE $14, $14, $15, $15, $15, $16, $16, $0D, $0E, $0E, $0E, $0E, $0F, $0F, $0F, $10
    .BYTE $10, $10, $10, $11, $11, $11, $11, $12, $12, $12, $13, $13, $13, $13, $14, $14
    .BYTE $0C, $0C, $0C, $0D, $0D, $0D, $0D, $0E, $0E, $0E, $0E, $0F, $0F, $0F, $0F, $10
    .BYTE $10, $10, $10, $11, $11, $11, $11, $12, $12, $0B, $0B, $0B, $0B, $0C, $0C, $0C
    .BYTE $0C, $0C, $0D, $0D, $0D, $0D, $0E, $0E, $0E, $0E, $0E, $0F, $0F, $0F, $0F, $10
    .BYTE $10, $10, $09, $09, $0A, $0A, $0A, $0A, $0A, $0B, $0B, $0B, $0B, $0B, $0C, $0C
    .BYTE $0C, $0C, $0C, $0D, $0D, $0D, $0D, $0D, $0E, $0E, $0E, $08, $08, $08, $08, $09
    .BYTE $09, $09, $09, $09, $09, $0A, $0A, $0A, $0A, $0A, $0A, $0B, $0B, $0B, $0B, $0B
    .BYTE $0B, $0C, $0C, $0C, $07, $07, $07, $07, $07, $07, $07, $08, $08, $08, $08, $08
    .BYTE $08, $08, $09, $09, $09, $09, $09, $09, $09, $0A, $0A, $0A, $0A, $05, $05, $06
    .BYTE $06, $06, $06, $06, $06, $06, $06, $06, $07, $07, $07, $07, $07, $07, $07, $07
    .BYTE $07, $08, $08, $08, $08, $08, $04, $04, $04, $04, $04, $04, $04, $05, $05, $05
    .BYTE $05, $05, $05, $05, $05, $05, $05, $05, $05, $06, $06, $06, $06, $06, $06, $03
    .BYTE $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $04
    .BYTE $04, $04, $04, $04, $04, $04, $04, $04, $01, $01, $01, $01, $01, $01, $01, $02
    .BYTE $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
    .BYTE $02

.ORG $6CF1

XEX_6CF1_333:
    .BYTE $2C, $30, $4C, $5C, $7B, $7C, $92, $A5, $C4, $E9, $ED, $F1, $19, $41, $60, $73
    .BYTE $7A, $7E, $82, $00, $6D, $6D, $6D, $6D, $6D, $6D, $6D, $6D, $6D, $6D, $6D, $6D
    .BYTE $6E, $6E, $6E, $6E, $6E, $6E, $6E, $00, $00, $01, $02, $04, $03, $06, $05, $07
    .BYTE $07, $06, $07, $07, $07, $05, $06, $04, $05, $06, $06, $C0, $25, $01, $FF, $FC
    .BYTE $8F, $09, $FC, $88, $01, $FC, $87, $01, $FC, $86, $01, $FC, $85, $01, $FC, $84
    .BYTE $01, $FC, $83, $01, $FC, $82, $01, $FC, $81, $01, $FF, $03, $81, $01, $03, $83
    .BYTE $01, $03, $85, $01, $03, $87, $01, $03, $89, $06, $FF, $1E, $A5, $01, $1E, $A9
    .BYTE $06, $1E, $A8, $01, $1E, $A7, $01, $1E, $A6, $01, $1E, $A5, $01, $1E, $A4, $01
    .BYTE $1E, $A3, $01, $1E, $A2, $01, $1E, $A1, $01, $FF, $FF, $0F, $E5, $01, $0F, $E6
    .BYTE $02, $0F, $E5, $02, $0F, $E4, $01, $0F, $E3, $01, $0F, $E2, $01, $0F, $E1, $01
    .BYTE $FF, $25, $ED, $01, $25, $EE, $03, $25, $E9, $02, $25, $E8, $01, $25, $E7, $01
    .BYTE $25, $E6, $01, $FF, $74, $8A, $01, $74, $8B, $01, $74, $8C, $01, $74, $8D, $0B
    .BYTE $73, $89, $04, $73, $87, $04, $73, $85, $04, $73, $83, $08, $73, $82, $01, $73
    .BYTE $81, $01, $FF, $0A, $8E, $06, $0A, $8B, $05, $0A, $0A, $03, $0A, $09, $03, $0A
    .BYTE $08, $03, $0A, $07, $03, $0A, $06, $04, $0A, $05, $01, $0A, $04, $01, $0A, $03
    .BYTE $01, $0A, $02, $01, $0A, $01, $01, $FF, $C7, $C9, $03, $FF, $14, $68, $17, $FF
    .BYTE $0D, $81, $02, $0D, $82, $02, $0D, $83, $02, $0D, $84, $02, $0D, $88, $02, $0D
    .BYTE $89, $02, $0E, $8C, $11, $0E, $8A, $02, $0E, $88, $02, $0D, $87, $02, $0D, $86
    .BYTE $06, $0D, $84, $03, $0D, $82, $03, $FF, $E4, $A4, $02, $E4, $A8, $02, $E4, $A9
    .BYTE $02, $E4, $AC, $09, $E4, $AA, $02, $E4, $A8, $02, $E4, $A7, $02, $E4, $A8, $04
    .BYTE $E4, $A7, $02, $E4, $A6, $02, $E4, $A5, $02, $E4, $A4, $02, $E4, $A2, $02, $FF
    .BYTE $08, $81, $01, $08, $83, $01, $08, $85, $01, $08, $87, $01, $08, $89, $03, $08
    .BYTE $88, $02, $08, $87, $02, $08, $86, $02, $08, $85, $02, $08, $83, $04, $FF, $3F
    .BYTE $8E, $06, $3F, $87, $02, $3F, $86, $02, $3F, $85, $02, $3F, $84, $02, $3F, $83
    .BYTE $02, $FF, $08, $A9, $01, $FF, $AA, $01, $FF, $90, $A6, $06, $FF, $72, $A6, $0A
    .BYTE $FF, $32, $A6, $0A, $FF, $A0, $6E, $A3, $6E, $A6, $6E, $A9, $6E, $B8, $6E, $C5
    .BYTE $6E, $D2, $6E, $DF, $6E, $EC, $6E, $F9, $6E, $06, $6F, $13, $6F, $1C, $6F, $A0
    .BYTE $0A, $00, $A0, $0F, $00, $A0, $14, $00, $AC, $02, $AB, $01, $A7, $01, $A6, $01
    .BYTE $A5, $01, $A3, $01, $A0, $03, $00, $88, $02, $84, $04, $83, $02, $82, $02, $81
    .BYTE $02, $80, $08, $00, $A8, $01, $A7, $02, $A6, $02, $A5, $02, $A4, $02, $A3, $47
    .BYTE $00, $A8, $01, $A7, $02, $A6, $02, $A5, $02, $A4, $02, $A3, $33, $00, $A8, $01
    .BYTE $A7, $02, $A6, $02, $A5, $02, $A4, $02, $A3, $1F, $00, $A8, $01, $A7, $02, $A6
    .BYTE $02, $A5, $02, $A4, $02, $A3, $1A, $00, $A8, $01, $A7, $02, $A6, $02, $A5, $02
    .BYTE $A4, $02, $A3, $06, $00, $A8, $01, $A7, $02, $A6, $02, $A5, $02, $A4, $02, $A3
    .BYTE $01, $00, $A8, $01, $A7, $01, $A5, $01, $A3, $02, $00, $A3, $50, $00, $23, $6F
    .BYTE $5E, $6F, $D9, $03, $6C, $03, $48, $03, $35, $03, $D9, $03, $6C, $03, $1C, $04
    .BYTE $88, $03, $44, $03, $2D, $03, $21, $03, $88, $03, $44, $03, $1C, $04, $A2, $03
    .BYTE $51, $03, $35, $03, $28, $03, $A2, $03, $51, $03, $1C, $04, $79, $03, $3C, $03
    .BYTE $25, $03, $1D, $03, $90, $03, $48, $03, $2F, $03, $23, $03, $FF, $16, $06, $00
    .BYTE $02, $1A, $07, $00, $02, $16, $09, $21, $07, $00, $02, $1D, $0B, $21, $0B, $23
    .BYTE $06, $00, $02, $2D, $05, $2D, $0C, $00, $02, $28, $0A, $00, $00, $21, $08, $00
    .BYTE $00, $28, $0A, $00, $00, $23, $06, $00, $00, $D9, $03, $6C, $03, $48, $03, $35
    .BYTE $03, $D9, $03, $6C, $03, $1C, $04, $D9, $03, $6C, $03, $48, $03, $35, $03, $D9
    .BYTE $03, $6C, $03, $1C, $04, $D9, $03, $6C, $03, $48, $03, $35, $03, $D9, $03, $6C
    .BYTE $03, $1C, $04, $D9, $03, $6C, $03, $48, $03, $35, $03, $D9, $03, $6C, $03, $1C
    .BYTE $04, $FF, $10, $10, $80, $89, $77, $F7, $71, $71, $BA, $EA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AB, $AC, $B0, $C3, $FF, $CC, $F0, $C3, $0F, $33
    .BYTE $C3, $03, $FF, $00, $01, $FF, $FF, $00, $04, $FF, $00, $01, $FF, $FF, $00, $04
    .BYTE $FF, $00, $01, $FF, $FF, $00, $04, $FF, $00, $01, $FF, $FF, $00, $04, $FF, $00
    .BYTE $01, $FF, $FF, $00, $04, $FF, $00, $01, $FF, $FF, $00, $04, $FF, $00, $01, $FF
    .BYTE $FF, $00, $04, $FF, $00, $01, $FF, $FF, $00, $04, $FF, $00, $01, $FF, $FF, $00
    .BYTE $04, $FF, $00, $01, $FF, $FF, $00, $04, $FF, $00, $01, $FF, $FF, $00, $04, $FF
    .BYTE $00, $01, $FF, $FF, $00, $04, $FF, $00, $01, $FF, $FF, $00, $04, $FF, $00, $01
    .BYTE $FF, $FF, $00, $04, $FF, $00, $01, $FF, $FF, $00, $04, $FF, $33, $0F, $C3, $F0
    .BYTE $CC, $C3, $C0, $AA, $AA, $AA, $AA, $EA, $3A, $0E, $C3, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AE, $AB, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AB
    .BYTE $AC, $B0, $C3, $FF, $CC, $F0, $C3, $0C, $30, $C0, $00, $01, $0C, $30, $C0, $00
    .BYTE $05, $03, $03, $03, $03, $03, $03, $03, $03, $00, $78, $C0, $C0, $C0, $C0, $C0
    .BYTE $C0, $C0, $C0, $30, $0C, $03, $00, $05, $FF, $33, $0F, $C3, $30, $0C, $03, $00
    .BYTE $01, $AA, $AA, $AA, $AA, $EA, $3A, $0E, $C3, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $FF, $CC, $F0, $C3, $0C, $F0, $30, $30, $0C, $30, $C0, $00, $15, $03, $03
    .BYTE $03, $03, $03, $03, $03, $03, $00, $78, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0
    .BYTE $00, $10, $30, $0C, $03, $00, $05, $FF, $33, $0F, $C3, $30, $0F, $0C, $0C, $30
    .BYTE $30, $30, $30, $30, $30, $30, $30, $00, $18, $03, $03, $03, $03, $03, $03, $03
    .BYTE $03, $00, $78, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $00, $18, $0C, $0C, $0C
    .BYTE $0C, $0C, $0C, $0C, $0C, $30, $30, $30, $30, $30, $30, $30, $30, $00, $18, $03
    .BYTE $03, $03, $03, $03, $03, $03, $03, $00, $07, $FF, $00, $07, $FF, $00, $07, $FF
    .BYTE $00, $07, $FF, $00, $07, $FF, $00, $07, $FF, $00, $07, $FF, $00, $07, $FF, $00
    .BYTE $07, $FF, $00, $07, $FF, $00, $07, $FF, $00, $07, $FF, $00, $07, $FF, $00, $07
    .BYTE $FF, $00, $07, $FF, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $00, $18, $0C, $0C
    .BYTE $0C, $0C, $0C, $0C, $0C, $0C, $30, $30, $30, $30, $30, $30, $30, $30, $00, $15
    .BYTE $03, $0C, $0C, $0C, $0C, $30, $C0, $C0, $00, $7B, $30, $30, $0C, $03, $03, $00
    .BYTE $08, $C0, $30, $30, $00, $10, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $30, $30
    .BYTE $30, $30, $30, $30, $30, $30, $00, $0B, $03, $0C, $0C, $30, $C0, $30, $C0, $C0
    .BYTE $00, $8D, $0C, $03, $03, $00, $08, $C0, $30, $30, $0C, $03, $00, $08, $0C, $0C
    .BYTE $0C, $0C, $0C, $0C, $0C, $0C, $30, $30, $30, $30, $30, $30, $30, $33, $00, $01
    .BYTE $03, $0C, $0C, $30, $C0, $C0, $00, $01, $C0, $00, $9F, $03, $00, $08, $C0, $30
    .BYTE $30, $0C, $03, $03, $00, $01, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $CC, $FF, $FF
    .BYTE $00, $00, $FF, $AA, $AA, $AA, $30, $30, $30, $30, $30, $30, $30, $30, $00, $15
    .BYTE $03, $0C, $0E, $0C, $0E, $38, $E2, $C8, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $B0, $30, $8C, $23, $8B, $22, $88, $22, $00, $05, $C0, $B0, $30
    .BYTE $00, $10, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $30, $30, $30, $30, $30, $30
    .BYTE $30, $30, $00, $0B, $03, $0C, $0E, $38, $E2, $38, $E2, $C8, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $8C, $23, $8B, $22, $88, $22, $88
    .BYTE $22, $00, $03, $C0, $B0, $30, $8C, $23, $00, $08, $0C, $0C, $0C, $0C, $0C, $0C
    .BYTE $0C, $0C, $30, $30, $30, $30, $30, $30, $30, $33, $00, $01, $03, $0C, $0E, $38
    .BYTE $E2, $C8, $22, $C8, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88, $22, $88
    .BYTE $22, $88, $22, $8B, $22, $88, $22, $88, $22, $88, $22, $00, $01, $C0, $B0, $30
    .BYTE $8C, $23, $8B, $22, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $CC, $48, $A9, $94, $8D
    .BYTE $0A, $D4, $8D, $09, $D4, $A9, $30, $8D, $00, $02, $A9, $00, $4C, $4C, $30, $48
    .BYTE $A9, $98, $8D, $0A, $D4, $8D, $09, $D4, $A9, $40, $8D, $00, $02, $68, $40, $48
    .BYTE $A9, $9C, $8D, $0A, $D4, $8D, $09, $D4, $A9, $50, $8D, $00, $02, $68, $40, $48
    .BYTE $A9, $A0, $8D, $0A, $D4, $8D, $09, $D4, $A9, $60, $8D, $00, $02, $68, $40, $48
    .BYTE $A9, $A4, $8D, $0A, $D4, $8D, $09, $D4, $A9, $73, $8D, $00, $02, $A9, $01, $4C
    .BYTE $4C, $30, $48, $A9, $A8, $8D, $0A, $D4, $8D, $09, $D4, $A9, $83, $8D, $00, $02
    .BYTE $68, $40, $48, $A9, $AC, $8D, $0A, $D4, $8D, $09, $D4, $A9, $93, $8D, $00, $02
    .BYTE $68, $40, $48, $A9, $B0, $8D, $0A, $D4, $8D, $09, $D4, $A9, $A3, $8D, $00, $02
    .BYTE $68, $40, $48, $A9, $B4, $8D, $0A, $D4, $8D, $09, $D4, $A9, $34, $8D, $1A, $D0
    .BYTE $20, $3A, $30, $A9, $1D, $8D, $00, $02, $68, $40, $58, $A9, $34, $8D, $1A, $D0
    .BYTE $A9, $1D, $8D, $00, $02, $A9, $74, $8D, $01, $02, $A9, $C0, $8D, $0E, $D4, $A9
    .BYTE $3B, $8D, $00, $D4, $20, $78, $76, $D0, $03, $20, $95, $76, $20, $43, $34, $AD
    .BYTE $77, $03, $29, $0F, $D0, $07, $A9, $80, $8D, $77, $03, $30, $65, $A9, $03, $8D
    .BYTE $0F, $D2, $A9, $00, $8D, $08, $D2, $AD, $E7, $03, $8D, $0F, $75, $8D, $12, $75
    .BYTE $AD, $E8, $03, $8D, $15, $75, $8D, $18, $75, $A0, $0F, $A9, $00, $99, $00, $BC
    .BYTE $99, $00, $BD, $99, $00, $BC, $99, $00, $BD, $88, $10, $F1, $A2, $00, $20, $59
    .BYTE $75, $A2, $01, $20, $59, $75, $A2, $00, $20, $AD, $75, $A2, $01, $20, $AD, $75
    .BYTE $AD, $D7, $03, $30, $0A, $A2, $00, $20, $E9, $31, $A2, $01, $20, $E9, $31, $A2
    .BYTE $00, $20, $FA, $32, $A2, $01, $20, $FA, $32, $20, $91, $35, $20, $98, $76, $20
    .BYTE $EA, $34, $68, $A8, $68, $AA, $68, $40, $B4, $AE, $30, $4F, $B9, $27, $65, $D5
    .BYTE $70, $F0, $48, $95, $70, $18, $69, $05, $A8, $B9, $BA, $65, $8D, $9A, $75, $B9
    .BYTE $CD, $65, $8D, $9B, $75, $B9, $F3, $65, $0A, $8D, $DD, $03, $BD, $B2, $65, $8D
    .BYTE $9D, $75, $BD, $B4, $65, $8D, $9E, $75, $BD, $B6, $65, $8D, $A3, $75, $BD, $B8
    .BYTE $65, $8D, $A4, $75, $A0, $00, $A2, $00, $B9, $FF, $FF, $9D, $FF, $FF, $20, $DD
    .BYTE $32, $9D, $FF, $FF, $E8, $C8, $CE, $DD, $03, $D0, $ED, $60, $B5, $AC, $8D, $E0
    .BYTE $03, $8E, $DC, $03, $BD, $7D, $03, $F0, $3B, $CE, $79, $03, $D0, $0D, $AD, $78
    .BYTE $03, $49, $01, $8D, $78, $03, $A9, $14, $8D, $79, $03, $AD, $78, $03, $F0, $24
    .BYTE $B5, $AC, $F0, $20, $A0, $03, $B9, $36, $03, $10, $16, $C9, $FF, $F0, $12, $29
    .BYTE $01, $CD, $DC, $03, $D0, $0B, $B9, $9B, $64, $49, $FF, $2D, $E0, $03, $8D, $E0
    .BYTE $03, $88, $10, $E2, $AD, $E0, $03, $29, $0F, $DD, $DE, $03, $D0, $01, $60, $AD
    .BYTE $E0, $03, $9D, $DE, $03, $A9, $00, $8D, $DB, $03, $AC, $DB, $03, $6E, $E0, $03
    .BYTE $90, $0E, $B9, $A5, $64, $8D, $62, $76, $B9, $A9, $64, $8D, $63, $76, $D0, $0A
    .BYTE $A9, $19, $8D, $62, $76, $A9, $65, $8D, $63, $76, $B9, $15, $65, $8D, $DD, $03
    .BYTE $B9, $AD, $64, $8D, $53, $76, $B9, $B1, $64, $8D, $54, $76, $B9, $B5, $64, $8D
    .BYTE $5C, $76, $B9, $B9, $64, $8D, $5D, $76, $A0, $00, $AE, $DC, $03, $BD, $A1, $64
    .BYTE $18, $79, $FF, $FF, $8D, $65, $76, $BD, $A3, $64, $79, $FF, $FF, $8D, $66, $76
    .BYTE $B9, $FF, $FF, $8D, $FF, $FF, $C8, $CE, $DD, $03, $D0, $E1, $EE, $DB, $03, $AD
    .BYTE $DB, $03, $C9, $04, $90, $94, $60, $AC, $18, $02, $D0, $08, $AC, $19, $02, $F0
    .BYTE $10, $CE, $19, $02, $CE, $18, $02, $D0, $08, $AC, $19, $02, $D0, $03, $A9, $00
    .BYTE $60, $A9, $FF, $60, $6C, $26, $02, $A0, $04, $A9, $AA, $99, $71, $96, $88, $10
    .BYTE $FA, $A0, $04, $A9, $AA, $99, $71, $A6, $88, $10, $FA, $60, $70, $70, $B0, $54
    .BYTE $DE, $76, $14, $94, $54, $DE, $76, $14, $94, $54, $DE, $76, $14, $94, $54, $DE
    .BYTE $76, $14, $94, $54, $DE, $76, $14, $94, $54, $DE, $76, $14, $94, $54, $DE, $76
    .BYTE $14, $94, $54, $DE, $76, $14, $94, $54, $6E, $77, $41, $AD, $76, $78, $78, $78
    .BYTE $78, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E
    .BYTE $0F, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1A, $1B, $1C, $1D, $1E
    .BYTE $1F, $20, $21, $22, $23, $24, $25, $26, $27, $78, $78, $78, $78, $78, $78, $78
    .BYTE $78, $28, $29, $2A, $2B, $2C, $2D, $2E, $2F, $30, $31, $32, $33, $34, $35, $36
    .BYTE $37, $38, $39, $3A, $3B, $3C, $3D, $3E, $3F, $40, $41, $42, $43, $44, $45, $46
    .BYTE $47, $48, $49, $4A, $4B, $4C, $4D, $4E, $4F, $78, $78, $78, $78, $78, $78, $78
    .BYTE $78, $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5A, $5B, $5C, $5D, $5E
    .BYTE $5F, $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $6A, $6B, $6C, $6D, $6E
    .BYTE $6F, $70, $71, $72, $73, $74, $75, $76, $77, $78, $78, $78, $78, $28, $28, $28
    .BYTE $28, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E
    .BYTE $0F, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1A, $1B, $1C, $1D, $1E
    .BYTE $1F, $20, $21, $22, $23, $24, $25, $26, $27, $28, $28, $28, $28, $00, $12, $17
    .BYTE $1C, $21, $94, $85, $26, $2B, $8A, $30, $35, $3A, $8F, $3F, $76, $44, $49, $4E
    .BYTE $53, $80, $7B, $58, $5D, $62, $67, $6C

.ORG $77BE

XEX_77BE_334:
    .BYTE $99, $00, $85, $00, $00, $00, $71, $00, $76, $7B, $00, $00, $00, $80, $9E, $8A
    .BYTE $8F, $94, $99, $9E, $A3, $A8, $AD, $B2, $B7, $BC, $00, $78, $78, $78, $78, $67
    .BYTE $67, $78, $78, $67, $78, $78, $78, $67, $78, $67, $78, $78, $78, $78, $67, $67
    .BYTE $78, $78, $78, $78, $78

.ORG $77F8

XEX_77F8_335:
    .BYTE $67, $00, $78, $00, $00, $00, $78, $00, $78, $78, $00, $00, $00, $78, $67, $78
    .BYTE $78, $78, $78, $78, $78, $78, $78, $78, $78, $78, $30, $CC, $FC, $CC, $CC, $FC
    .BYTE $CC, $FC, $CC, $FC, $FC, $C0, $C0, $C0, $FC, $F0, $CC, $CC, $CC, $F0, $FC, $C0
    .BYTE $CC, $CC, $FC, $CC, $CC, $FC, $CC, $CC, $0C, $0C, $0C, $CC, $FC, $CC, $CC, $F0
    .BYTE $CC, $CC, $C0, $C0, $C0, $C0, $FC, $F0, $CC, $CC, $CC, $CC, $FC, $CC, $FC, $C0
    .BYTE $C0, $30, $CC, $CC, $CC, $3F, $F0, $CC, $CC, $F0, $CC, $3C, $C0, $FC, $0C, $F0
    .BYTE $CC, $CC, $CC, $CC, $30, $CC, $CC, $CC, $FC, $CC, $CC, $CC, $30, $CC, $CC, $CC
    .BYTE $CC, $30, $30, $30, $FC, $03, $0C, $30, $FC, $3C, $30, $FC, $30, $30, $30, $C0
    .BYTE $C0, $C0, $30, $30, $0C, $0C, $0C, $30, $00, $00, $FC, $00, $00, $00, $30, $00
    .BYTE $30, $00, $0C, $0C, $30, $C0, $C0, $FC, $CC, $CC, $CC, $FC, $F0, $30, $30, $30
    .BYTE $FC, $FC, $0C, $FC, $C0, $FC, $FC, $0C, $FC, $0C, $FC, $CC, $CC, $FC, $0C, $0C
    .BYTE $FC, $C0, $F0, $0C, $F0, $FC, $C0, $FC, $CC, $FC, $FC, $0C, $30, $30, $30, $FC
    .BYTE $CC, $FC, $CC, $FC, $FC, $CC, $FC, $0C, $0C, $9B, $B3, $CB, $E3, $FB, $14, $22
    .BYTE $3B, $54, $6D, $85, $9E, $B6, $CC, $E4, $FD, $16, $17, $30, $FC, $09, $18, $27
    .BYTE $36, $45, $54, $63, $72, $81, $90, $A0, $8B, $8B, $8B, $8B, $8B, $8C, $8C, $8C
    .BYTE $8C, $8C, $8C, $8C, $8C, $8C, $8C, $8C, $8D, $8D, $8D, $7C, $7D, $7D, $7D, $7D
    .BYTE $7D, $7D, $7D, $7D, $7D, $7D, $7D, $18, $18, $18, $18, $19, $0E, $19, $19, $19
    .BYTE $18, $19, $18, $16, $18, $19, $19, $01, $19, $CC, $0D, $0F, $0F, $0F, $0F, $0F
    .BYTE $0F, $0F, $0F, $0F, $10, $6D, $84, $53, $4E, $44, $37, $92, $6D, $84, $53, $4E
    .BYTE $44, $38, $A5, $6D, $84, $53, $4E, $44, $39, $C4, $6D, $85, $53, $4E, $44, $31
    .BYTE $30, $E9, $6D, $85, $53, $4E, $44, $31, $31, $ED, $6D, $85, $53, $4E, $44, $31
    .BYTE $32, $F1, $6D, $85, $53, $4E, $44, $31, $33, $19, $6E, $85, $53, $4E, $44, $31
    .BYTE $34, $41, $6E, $85, $53, $4E, $44, $31, $35, $60, $6E, $85, $53, $4E, $44, $31
    .BYTE $36, $73, $6E, $85, $53, $4E, $44, $31, $37, $7A, $6E, $85, $53, $4E, $44, $31
    .BYTE $38, $7E, $6E, $85, $53, $4E, $44, $31, $39, $82, $6E, $84, $41, $44, $53, $52
    .BYTE $86, $6E, $85, $45, $4E, $56, $30, $31, $A0, $6E, $85, $45, $4E, $56, $30, $32
    .BYTE $A3, $6E, $85, $45, $4E, $56, $30, $33, $A6, $6E, $85, $45, $4E, $56, $30, $34
    .BYTE $A9, $6E, $85, $45, $4E, $56, $30, $35, $B8, $6E, $85, $45, $4E, $56, $30, $36
    .BYTE $C5, $6E, $85, $45, $4E, $56, $30, $37, $D2, $6E, $85, $45, $4E, $56, $30, $38
    .BYTE $DF, $6E, $85, $45, $4E, $56, $30, $39, $EC, $6E, $85, $45, $4E, $56, $31, $30
    .BYTE $F9, $6E, $85, $45, $4E, $56, $31, $31, $06, $6F, $85, $45, $4E, $56, $31, $32
    .BYTE $13, $6F, $85, $45, $4E, $56, $31, $33, $1C, $6F, $87, $4D, $55, $53, $4E, $4F
    .BYTE $54, $45, $1F, $6F, $88, $4D, $55, $53, $AA, $AA, $AA, $AA, $AA, $AB, $AD, $B5
    .BYTE $AA, $AB, $AD, $B5, $D5, $55, $55, $55, $D5, $55, $55, $55, $55, $55, $55, $55
    .BYTE $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
    .BYTE $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
    .BYTE $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
    .BYTE $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
    .BYTE $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
    .BYTE $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
    .BYTE $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
    .BYTE $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
    .BYTE $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
    .BYTE $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
    .BYTE $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
    .BYTE $55, $55, $55, $55, $55, $55, $55, $55, $57, $55, $55, $55, $55, $55, $55, $55
    .BYTE $AA, $EA, $7A, $5E, $57, $55, $55, $55, $AA, $AA, $AA, $AA, $AA, $EA, $7A, $5E
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $FF, $D5, $DF, $DD, $DD, $DD, $DD, $DD
    .BYTE $FF, $55, $FF, $55, $55, $55, $57, $5E, $FF, $55, $FF, $55, $7F, $EE, $BB, $EE
    .BYTE $FF, $55, $FF, $55, $FF, $EE, $BA, $AA, $FF, $55, $FF, $55, $FF, $EE, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $AA, $AA, $AA, $FF, $55, $FF, $55, $FF, $AA, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $AA, $AA, $AA, $FF, $55, $FF, $55, $FF, $AA, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $AA, $AA, $AA, $FF, $55, $FF, $55, $FF, $AA, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $AA, $AA, $AA, $FF, $55, $FF, $55, $FF, $AA, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $AA, $AA, $AA, $FF, $55, $FF, $55, $FF, $AA, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $AA, $AA, $AA, $FF, $55, $FF, $55, $FF, $AA, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $AA, $AA, $AA, $FF, $55, $FF, $55, $FF, $AA, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $AA, $AA, $AA, $FF, $55, $FF, $55, $FF, $AA, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $AA, $AA, $AA, $FF, $55, $FF, $55, $FF, $AA, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $AA, $AA, $AA, $FF, $55, $FF, $55, $FF, $BB, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $BB, $AE, $AA, $FF, $55, $FF, $55, $FD, $BB, $EE, $BB
    .BYTE $FF, $55, $FF, $55, $55, $55, $D5, $B5, $FF, $57, $F7, $77, $77, $77, $77, $77
    .BYTE $AA, $AA, $AA, $AA, $AB, $AF, $B0, $CF, $AA, $AA, $AA, $FF, $00, $FF, $00, $FF
    .BYTE $AA, $AA, $AA, $FF, $00, $FF, $00, $FF, $AA, $AA, $AA, $FF, $00, $F0, $0F, $F0
    .BYTE $AA, $AA, $AA, $AA, $FF, $00, $FF, $00, $AA, $AA, $AA, $AA, $FF, $00, $FF, $00
    .BYTE $AA, $AA, $AA, $AA, $FF, $00, $FC, $03, $AA, $AA, $AA, $AA, $EA, $3F, $00, $FF
    .BYTE $AA, $AB, $AB, $AB, $AB, $FF, $03, $FF, $FF, $AA, $AA, $AA, $AA, $AA, $FF, $F0
    .BYTE $AA, $EA, $EA, $EA, $EA, $FA, $CE, $03, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD
    .BYTE $5F, $7E, $7B, $7E, $FA, $EE, $FA, $EA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $F5, $BD, $ED, $BD, $AF, $BB, $AF, $AB, $77, $77, $77, $77, $77, $77, $77, $77
    .BYTE $3F, $3F, $3A, $3F, $3F, $3F, $00, $FF, $EA, $EE, $EE, $EE, $EA, $FF, $00, $FF
    .BYTE $EA, $EE, $EE, $EE, $EA, $FF, $00, $FF, $FF, $FF, $FB, $FF, $FB, $FF, $0F, $F0
    .BYTE $FF, $EA, $EE, $EE, $EE, $EA, $FF, $00, $FF, $EA, $EE, $EE, $EE, $EA, $FF, $00
    .BYTE $FC, $FF, $FF, $FB, $FF, $FB, $FF, $03, $00, $FF, $EA, $EE, $EE, $EE, $EA, $FF
    .BYTE $00, $FF, $EA, $EE, $EE, $EE, $EA, $FF, $0C, $C3, $F0, $F0, $F0, $F0, $F0, $F0
    .BYTE $0F, $33, $C3, $C3, $C3, $C3, $C3, $C3, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $0C, $12, $21, $42, $84, $88, $50, $20
    .BYTE $30, $4C, $5E, $3C, $78, $70, $20, $00, $7C, $7C, $38

.ORG $7E00

XEX_7E00_336:
    .BYTE $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $FA, $EA, $FA, $EA, $EA, $EA, $EA, $EA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AF, $AB, $AF, $AB, $AB, $AB, $AB, $AB
    .BYTE $77, $77, $77, $77, $77, $77, $77, $77, $00, $03, $0D, $3F, $D5, $57, $5D, $75
    .BYTE $00, $FF, $55, $FF, $55, $D5, $75, $FD, $00, $FC, $57, $D5, $75, $5D, $5D, $5D

.ORG $A000

XEX_A000_337:
    .BYTE $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $EA, $EA, $EA, $EA, $EA, $EA, $EA, $EA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AB, $AB, $AB, $AB, $AB, $AB, $AB, $AB
    .BYTE $77, $77, $77, $77, $77, $77, $77, $77, $0F, $0F, $0F, $CF, $F3, $B0, $AC, $AB
    .BYTE $55, $55, $55, $FF, $FF, $00, $00, $FF, $55, $55, $55, $FF, $FF, $00, $00, $FF
    .BYTE $55, $55, $55, $F5, $FF, $0F, $00, $F0, $55, $55, $55, $55, $FF, $FF, $00, $00
    .BYTE $55, $55, $55, $55, $FF, $FF, $00, $00, $55, $55, $55, $55, $F5, $FF, $0F, $00
    .BYTE $55, $55, $55, $55, $55, $FF, $FF, $00, $55, $55, $55, $55, $55, $FF, $FF, $00
    .BYTE $70, $70, $70, $70, $70, $F0, $C0, $03, $C3, $C3, $C3, $C3, $CE, $FA, $EA, $AA
    .BYTE $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $EA, $EA, $EA, $EA, $EA, $FA, $7A, $7A
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AB, $AB, $AB, $AB, $AB, $AF, $AD, $AD
    .BYTE $77, $77, $77, $77, $77, $77, $77, $77, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AF, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $FF, $B0, $BF, $B0, $BF, $B0, $FC, $C3
    .BYTE $FF, $0E, $CE, $3E, $0E, $CE, $3E, $3A, $F0, $AF, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $00, $FF, $AA, $AA, $AA, $AA, $AA, $AA, $00, $FF, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $0E, $FA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $7E, $5F, $5E, $57, $55, $55, $55, $55
    .BYTE $AA, $AA, $EA, $BB, $EE, $7F, $55, $55, $AA, $AA, $AA, $BA, $EE, $FF, $55, $55
    .BYTE $AA, $AA, $AA, $AA, $EA, $FF, $55, $55, $AA, $AA, $AA, $AA, $AA, $FF, $55, $55
    .BYTE $AA, $AA, $AA, $AA, $AA, $FF, $55, $55, $AA, $AA, $AA, $AA, $AA, $FF, $55, $55
    .BYTE $AA, $AA, $AA, $AA, $AA, $FF, $55, $55, $AA, $AA, $AA, $AA, $AA, $FF, $55, $55
    .BYTE $AA, $AA, $AA, $AA, $AA, $FF, $55, $55, $AA, $AA, $AA, $AA, $AA, $F7, $77, $77
    .BYTE $AA, $AA, $AA, $AA, $AA, $FF, $7F, $77, $AA, $AA, $AA, $AA, $AA, $FF, $77, $77
    .BYTE $AA, $AA, $AA, $AA, $AA, $FF, $77, $77, $AA, $AA, $AA, $AA, $AA, $FF, $57, $DF
    .BYTE $AA, $AA, $AA, $AA, $AA, $FF, $57, $7F, $AA, $AA, $AA, $AA, $AA, $7F, $75, $75
    .BYTE $AA, $AA, $AA, $AA, $AA, $FF, $55, $55, $AA, $AA, $AA, $AA, $AA, $FF, $55, $55
    .BYTE $AA, $AA, $AA, $AA, $AA, $FF, $55, $55, $AA, $AA, $AA, $AA, $AA, $FF, $55, $55
    .BYTE $AA, $AA, $AA, $AA, $AA, $FF, $55, $55, $AA, $AA, $AA, $AA, $AA, $FF, $55, $55
    .BYTE $AA, $AA, $AA, $AA, $AA, $FF, $55, $55, $AA, $AA, $AA, $AE, $BB, $FF, $55, $55
    .BYTE $AA, $AA, $AB, $EE, $BB, $FD, $55, $55, $BD, $F5, $B5, $D5, $55, $55, $55, $55
    .BYTE $77, $77, $77, $77, $77, $77, $77, $77, $AA, $AA, $AA, $BF, $8C, $8C, $8C, $8C
    .BYTE $AA, $AA, $AA, $FF, $CC, $CC, $CC, $CC, $AA, $AA, $AA, $FF, $CC, $CC, $C3, $33
    .BYTE $AB, $AF, $F0, $CC, $C3, $33, $30, $0F, $33, $0C, $CC, $33, $33, $0E, $FA, $AA
    .BYTE $3A, $EA, $EA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA

.ORG $A3E0

XEX_A3E0_338:
    .BYTE $3C, $42, $89, $99, $5D, $2A, $34, $54, $28, $10, $00, $00, $00, $3C, $76, $66
    .BYTE $22, $10, $08, $28, $10, $00, $10, $10

.ORG $A400

XEX_A400_339:
    .BYTE $DD, $DF, $D5, $BF, $AA, $AB, $AD, $B5, $55, $FF, $55, $FF, $D5, $55, $55, $55
    .BYTE $55, $FF, $55, $FF, $55, $55, $55, $55, $55, $FF, $55, $FF, $55, $55, $55, $55
    .BYTE $55, $FF, $55, $FF, $55, $55, $55, $55, $55, $FF, $55, $FF, $55, $55, $55, $55
    .BYTE $55, $FF, $55, $FF, $55, $55, $55, $55, $55, $FF, $55, $FF, $55, $55, $55, $55
    .BYTE $55, $FF, $55, $FF, $55, $55, $55, $55, $55, $FF, $55, $FF, $55, $55, $55, $55
    .BYTE $55, $FF, $55, $FF, $55, $55, $55, $55, $77, $F7, $77, $F7, $55, $55, $55, $55
    .BYTE $77, $77, $DD, $FF, $55, $55, $55, $55, $75, $77, $F7, $FF, $55, $55, $55, $55
    .BYTE $77, $77, $77, $FF, $55, $55, $55, $55, $DF, $DF, $DF, $FF, $55, $55, $55, $55
    .BYTE $5F, $7F, $57, $FF, $55, $55, $55, $55, $75, $7F, $75, $7F, $55, $55, $55, $55
    .BYTE $55, $FF, $55, $FF, $55, $55, $55, $55, $55, $FF, $55, $FF, $55, $55, $55, $55
    .BYTE $55, $FF, $55, $FF, $55, $55, $55, $55, $55, $FF, $55, $FF, $55, $55, $55, $55
    .BYTE $55, $FF, $55, $FF, $55, $55, $55, $55, $55, $FF, $55, $FF, $55, $55, $55, $55
    .BYTE $55, $FF, $55, $FF, $55, $55, $55, $55, $55, $FF, $55, $FF, $55, $55, $55, $55
    .BYTE $55, $FF, $55, $FF, $55, $55, $55, $55, $55, $FF, $55, $FF, $57, $55, $55, $55
    .BYTE $77, $F7, $57, $FF, $AA, $EA, $7A, $5E, $8C, $BF, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $CF, $FF, $AA, $AA, $AA, $AA, $AA, $AA, $33, $FE, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $FA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $FF, $D5, $DF, $DD, $DD, $DD, $DD, $DD, $FF, $55, $FF, $55, $55, $55, $57, $5E
    .BYTE $FF, $55, $FF, $55, $7F, $EE, $BB, $EE, $FF, $55, $FF, $55, $FF, $EE, $BA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $EE, $AA, $AA, $FF, $55, $FF, $55, $FF, $AA, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $AA, $AA, $AA, $FF, $55, $FF, $55, $FF, $AA, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $AA, $AA, $AA, $FF, $55, $FF, $55, $FF, $AA, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $AA, $AA, $AA, $FF, $55, $FF, $55, $FF, $AA, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $AA, $AA, $AA, $FF, $55, $FF, $55, $FF, $AA, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $AA, $AA, $AA, $FF, $55, $FF, $55, $FF, $AA, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $AA, $AA, $AA, $FF, $55, $FF, $55, $FF, $AA, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $AA, $AA, $AA, $FF, $55, $FF, $55, $FF, $AA, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $AA, $AA, $AA, $FF, $55, $FF, $55, $FF, $AA, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $AA, $AA, $AA, $FF, $55, $FF, $55, $FF, $AA, $AA, $AA
    .BYTE $FF, $55, $FF, $55, $FF, $BB, $AA, $AA, $FF, $55, $FF, $55, $FF, $BB, $AE, $AA
    .BYTE $FF, $55, $FF, $55, $FD, $BB, $EE, $BB, $FF, $55, $FF, $55, $55, $55, $D5, $B5
    .BYTE $FF, $57, $F7, $77, $77, $77, $77, $77, $AA, $AA, $AA, $AA, $AB, $AF, $B0, $CF
    .BYTE $AA, $AA, $AA, $FF, $00, $FF, $00, $FF, $AA, $AA, $AA, $FF, $00, $FF, $00, $FF
    .BYTE $AA, $AA, $AA, $FF, $00, $F0, $0F, $F0, $AA, $AA, $AA, $AA, $FF, $00, $FF, $00
    .BYTE $AA, $AA, $AA, $AA, $FF, $00, $FF, $00, $AA, $AA, $AA, $AA, $FF, $00, $FC, $03
    .BYTE $AA, $AA, $AA, $AA, $EA, $3F, $00, $FF, $AA, $AB, $AB, $AB, $AB, $FF, $03, $FF
    .BYTE $FF, $AA, $AA, $AA, $AA, $AA, $FF, $F0, $AA, $EA, $EA, $EA, $EA, $FA, $CE, $03
    .BYTE $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $5F, $7E, $7B, $7E, $FA, $EE, $FA, $EA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $F5, $BD, $ED, $BD, $AF, $BB, $AF, $AB
    .BYTE $77, $77, $77, $77, $77, $77, $77, $77, $3F, $3F, $3A, $3F, $3F, $3F, $00, $FF
    .BYTE $EA, $EE, $EE, $EE, $EA, $FF, $00, $FF, $EA, $EE, $EE, $EE, $EA, $FF, $00, $FF
    .BYTE $FF, $FF, $FB, $FF, $FB, $FF, $0F, $F0, $FF, $EA, $EE, $EE, $EE, $EA, $FF, $00
    .BYTE $FF, $EA, $EE, $EE, $EE, $EA, $FF, $00, $FC, $FF, $FF, $FB, $FF, $FB, $FF, $03
    .BYTE $00, $FF, $EA, $EE, $EE, $EE, $EA, $FF, $00, $FF, $EA, $EE, $EE, $EE, $EA, $FF
    .BYTE $0C, $C3, $F0, $F0, $F0, $F0, $F0, $F0, $0F, $33, $C3, $C3, $C3, $C3, $C3, $C3
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA

.ORG $A7D0

XEX_A7D0_340:
    .BYTE $ED, $ED, $19, $E7, $E7

.ORG $A800

XEX_A800_341:
    .BYTE $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $FA, $EA, $FA, $EA, $EA, $EA, $EA, $EA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AF, $AB, $AF, $AB, $AB, $AB, $AB, $AB
    .BYTE $77, $77, $77, $77, $77, $77, $77, $77, $00, $03, $0D, $3F, $D5, $57, $5D, $75
    .BYTE $00, $FF, $55, $FF, $55, $D5, $75, $FD, $00, $FC, $57, $D5, $75, $5D, $5D, $5D
    .BYTE $0F, $00, $00, $C3, $CF, $F5, $D5, $D7, $FF, $00, $FF, $55, $FF, $55, $FF, $55
    .BYTE $FF, $00, $FF, $55, $F5, $5D, $57, $57, $FC, $03, $00, $C0, $70, $73, $7D, $75
    .BYTE $00, $FF, $00, $3F, $D5, $FF, $55, $7F, $00, $FF, $00, $FF, $55, $FD, $57, $D5
    .BYTE $00, $FF, $00, $C0, $70, $5C, $5C, $DC, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3
    .BYTE $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $EA, $EA, $EA, $EA, $EA, $EA, $EA, $EA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AB, $AB, $AB, $AB, $AB, $AB, $AB, $AB
    .BYTE $77, $77, $77, $77, $77, $77, $77, $77, $55, $57, $5F, $5F, $5F, $5F, $5F, $57
    .BYTE $DD, $FF, $F7, $DD, $F7, $FF, $FF, $FF, $5D, $5D, $DD, $DD, $DD, $DD, $DD, $5D
    .BYTE $DD, $DF, $DD, $D7, $DD, $DD, $D7, $DD, $FF, $55, $55, $55, $FF, $55, $55, $FF
    .BYTE $57, $D7, $77, $D7, $77, $77, $D7, $57, $75, $77, $77, $77, $77, $75, $75, $75
    .BYTE $D5, $55, $7F, $D5, $FF, $FF, $FD, $F7, $75, $5D, $DD, $7D, $FD, $75, $F5, $F5
    .BYTE $DC, $DC, $DC, $DC, $DC, $DC, $DC, $DC, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3
    .BYTE $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $EA, $EA, $EA, $EA, $EA, $EA, $EA, $EA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AB, $AB, $AB, $AB, $AB, $AB, $AB, $AB
    .BYTE $77, $77, $77, $77, $77, $77, $77, $77, $55, $55, $D5, $3F, $00, $0F, $0D, $3F
    .BYTE $FD, $55, $55, $FF, $00, $FF, $55, $FF, $5D, $5F, $7C, $F0, $00, $FC, $57, $D5
    .BYTE $DD, $D7, $D5, $35, $0F, $00, $00, $C3, $55, $55, $FF, $55, $FF, $00, $FF, $55
    .BYTE $57, $D7, $57, $5F, $FC, $00, $FF, $55, $75, $75, $F5, $35, $0D, $03, $00, $C0
    .BYTE $FD, $F7, $DF, $FF, $55, $FF, $00, $3F, $F5, $F5, $F5, $F5, $57, $FF, $00, $FF
    .BYTE $DC, $DC, $DC, $F0, $C0, $00, $00, $C0, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA

.ORG $ABD0

XEX_ABD0_342:
    .BYTE $04, $04, $12, $12, $06

.ORG $AC00

XEX_AC00_343:
    .BYTE $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $EA, $EA, $EA, $EA, $EA, $EA, $EA, $EA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AB, $AB, $AB, $AB, $AB, $AB, $AB, $AB
    .BYTE $77, $77, $77, $77, $77, $77, $77, $77, $D5, $5D, $5F, $5F, $5F, $7F, $7D, $7D
    .BYTE $55, $55, $FF, $FF, $75, $F5, $5F, $55, $75, $5D, $DD, $DD, $5D, $5D, $5D, $DD
    .BYTE $CF, $F5, $D5, $D5, $D7, $D7, $D5, $D7, $FF, $55, $55, $F7, $D5, $7F, $D7, $55
    .BYTE $F5, $5D, $57, $D7, $F7, $77, $D7, $F7, $70, $73, $7D, $75, $75, $77, $77, $77
    .BYTE $D5, $FF, $55, $75, $FD, $F7, $F5, $F5, $55, $FD, $57, $55, $5D, $7D, $DD, $DD
    .BYTE $70, $5C, $5C, $DC, $DC, $DC, $DC, $DC, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3
    .BYTE $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $EA, $EA, $EA, $EA, $EA, $EA, $EA, $EA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AB, $AB, $AB, $AB, $AB, $AB, $AB, $AB
    .BYTE $77, $77, $77, $77, $77, $77, $77, $77, $55, $55, $5F, $75, $5F, $55, $D5, $3F
    .BYTE $57, $7D, $D5, $55, $55, $FD, $55, $FF, $5D, $5D, $5D, $5D, $5D, $5F, $7C, $F0
    .BYTE $D7, $D7, $D7, $D5, $D5, $D7, $D5, $35, $5F, $75, $55, $D7, $FF, $55, $55, $55
    .BYTE $F7, $F7, $F7, $D7, $57, $D7, $57, $5F, $77, $77, $77, $77, $77, $77, $F5, $35
    .BYTE $F5, $F5, $F5, $F5, $DD, $57, $55, $55, $DD, $DD, $DD, $DD, $DD, $F5, $D5, $55
    .BYTE $DC, $DC, $DC, $DC, $DC, $DC, $DC, $F0, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3
    .BYTE $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $EA, $EA, $EA, $EA, $EA, $EA, $EA, $EA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AB, $AB, $AB, $AB, $AB, $AB, $AB, $AB
    .BYTE $77, $77, $77, $77, $77, $77, $77, $77, $00, $00, $03, $0F, $0F, $0F, $0F, $0F
    .BYTE $00, $00, $FF, $55, $55, $55, $55, $55, $00, $00, $FF, $55, $55, $55, $55, $55
    .BYTE $0F, $00, $F0, $5F, $55, $55, $55, $55, $FF, $00, $00, $FF, $55, $55, $55, $55
    .BYTE $FC, $00, $00, $FF, $55, $55, $55, $55, $0D, $03, $00, $F0, $5F, $55, $55, $55
    .BYTE $55, $FF, $00, $00, $FF, $55, $55, $55, $57, $FF, $00, $00, $FF, $55, $55, $55
    .BYTE $C0, $00, $00, $00, $C0, $70, $70, $70, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA

.ORG $AFD0

XEX_AFD0_344:
    .BYTE $02, $02, $03

.ORG $B000

XEX_B000_345:
    .BYTE $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $EA, $EA, $EA, $EA, $EA, $EA, $EA, $EA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AB, $AB, $AB, $AB, $AB, $AB, $AB, $AB
    .BYTE $77, $77, $77, $77, $77, $77, $77, $77, $0F, $0F, $0F, $CF, $F3, $B0, $AC, $AB
    .BYTE $55, $55, $55, $FF, $FF, $00, $00, $FF, $55, $55, $55, $FF, $FF, $00, $00, $FF
    .BYTE $55, $55, $55, $F5, $FF, $0F, $00, $F0, $55, $55, $55, $55, $FF, $FF, $00, $00
    .BYTE $55, $55, $55, $55, $FF, $FF, $00, $00, $55, $55, $55, $55, $F5, $FF, $0F, $00
    .BYTE $55, $55, $55, $55, $55, $FF, $FF, $00, $55, $55, $55, $55, $55, $FF, $FF, $00
    .BYTE $70, $70, $70, $70, $70, $F0, $C0, $03, $C3, $C3, $C3, $C3, $CE, $FA, $EA, $AA
    .BYTE $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $EA, $EA, $EA, $EA, $EA, $FA, $7A, $7A
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AB, $AB, $AB, $AB, $AB, $AF, $AD, $AD
    .BYTE $77, $77, $77, $77, $77, $77, $77, $77, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AF, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $FF, $B0, $BF, $B0, $BF, $B0, $FC, $C3
    .BYTE $FF, $0E, $CE, $3E, $0E, $CE, $3E, $3A, $F0, $AF, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $00, $FF, $AA, $AA, $AA, $AA, $AA, $AA, $00, $FF, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $0E, $FA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $7E, $5F, $5E, $57, $55, $55, $55, $55
    .BYTE $AA, $AA, $EA, $BB, $EE, $7F, $55, $55, $AA, $AA, $AA, $BA, $EE, $FF, $55, $55
    .BYTE $AA, $AA, $AA, $AA, $EA, $FF, $55, $55, $AA, $AA, $AA, $AA, $AA, $FF, $55, $55
    .BYTE $AA, $AA, $AA, $AA, $AA, $FF, $55, $55, $AA, $AA, $AA, $AA, $AA, $FF, $55, $55
    .BYTE $AA, $AA, $AA, $AA, $AA, $FF, $55, $55, $AA, $AA, $AA, $AA, $AA, $FF, $55, $55
    .BYTE $AA, $AA, $AA, $AA, $AA, $FF, $55, $55, $AA, $AA, $AA, $AA, $AA, $FD, $5D, $5D
    .BYTE $AA, $AA, $AA, $AA, $AA, $55, $FD, $DD, $AA, $AA, $AA, $AA, $AA, $55, $D5, $D5
    .BYTE $AA, $AA, $AA, $AA, $AA, $55, $FD, $DD, $AA, $AA, $AA, $AA, $AA, $55, $FD, $D5
    .BYTE $AA, $AA, $AA, $AA, $AA, $55, $D7, $DD, $AA, $AA, $AA, $AA, $AA, $7F, $75, $75
    .BYTE $AA, $AA, $AA, $AA, $AA, $FF, $55, $55, $AA, $AA, $AA, $AA, $AA, $FF, $55, $55
    .BYTE $AA, $AA, $AA, $AA, $AA, $FF, $55, $55, $AA, $AA, $AA, $AA, $AA, $FF, $55, $55
    .BYTE $AA, $AA, $AA, $AA, $AA, $FF, $55, $55, $AA, $AA, $AA, $AA, $AA, $FF, $55, $55
    .BYTE $AA, $AA, $AA, $AA, $AA, $FF, $55, $55, $AA, $AA, $AA, $AE, $BB, $FF, $55, $55
    .BYTE $AA, $AA, $AB, $EE, $BB, $FD, $55, $55, $BD, $F5, $B5, $D5, $55, $55, $55, $55
    .BYTE $77, $77, $77, $77, $77, $77, $77, $77, $AA, $AA, $AA, $BF, $8C, $8C, $8C, $8C
    .BYTE $AA, $AA, $AA, $FF, $CC, $CC, $CC, $CC, $AA, $AA, $AA, $FF, $CC, $CC, $C3, $33
    .BYTE $AB, $AF, $F0, $CC, $C3, $33, $30, $0F, $33, $0C, $CC, $33, $33, $0E, $FA, $AA
    .BYTE $3A, $EA, $EA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA

.ORG $B3D0

XEX_B3D0_346:
    .BYTE $03, $03, $81, $80, $80

.ORG $B400

XEX_B400_347:
    .BYTE $DD, $DF, $D5, $FF, $AA, $AA, $AA, $AA, $55, $FF, $55, $FF, $AA, $AA, $AA, $AA
    .BYTE $55, $FF, $55, $FF, $AB, $AA, $AA, $AA, $55, $FF, $55, $FF, $FE, $AA, $AA, $AA
    .BYTE $55, $FF, $55, $FF, $AA, $AA, $AA, $AA, $55, $FF, $55, $FF, $AA, $AA, $AA, $AA
    .BYTE $55, $FF, $55, $FF, $AA, $AA, $AA, $AA, $55, $FF, $55, $FF, $AA, $AA, $AA, $AA
    .BYTE $55, $FF, $55, $FF, $AA, $AA, $AA, $AA, $55, $FF, $55, $FF, $AA, $AA, $AA, $AA
    .BYTE $55, $FF, $55, $FF, $AA, $AA, $AA, $AA, $5D, $FD, $5D, $FD, $AA, $AA, $AA, $AA
    .BYTE $FD, $DD, $FD, $55, $AA, $AA, $AA, $AA, $D5, $D5, $FD, $55, $AA, $AA, $AA, $AA
    .BYTE $FD, $DD, $DD, $55, $AA, $AA, $AA, $AA, $D5, $D5, $FD, $55, $AA, $AA, $AA, $AA
    .BYTE $F5, $DD, $D7, $55, $AA, $AA, $AA, $AA, $75, $7F, $75, $7F, $AA, $AA, $AA, $AA
    .BYTE $55, $FF, $55, $FF, $AA, $AA, $AA, $AA, $55, $FF, $55, $FF, $AA, $AA, $AA, $AA
    .BYTE $55, $FF, $55, $FF, $AA, $AA, $AA, $AA, $55, $FF, $55, $FF, $AA, $AA, $AA, $AA
    .BYTE $55, $FF, $55, $FF, $AA, $AA, $AA, $AA, $55, $FF, $55, $FF, $AA, $AA, $AA, $AA
    .BYTE $55, $FF, $55, $FF, $AA, $AA, $AA, $AA, $55, $FF, $55, $FF, $AF, $AA, $AA, $AA
    .BYTE $55, $FF, $55, $FF, $FA, $AA, $AA, $AA, $55, $FF, $55, $FF, $AA, $AA, $AA, $AA
    .BYTE $77, $F7, $57, $FF, $AA, $AA, $AA, $AA, $8C, $BF, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $CF, $FF, $AA, $AA, $AA, $AA, $AA, $AA, $33, $FE, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $FA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $FF, $00, $03, $01, $FF, $FF, $FF, $FF
    .BYTE $FF, $FF

.ORG $B558

XEX_B558_348:
    .BYTE $FF, $01, $03, $00, $00, $FF, $FF, $FF, $FF, $FF

.ORG $B569

XEX_B569_349:
    .BYTE $01, $01, $01, $01, $01

.ORG $B580

XEX_B580_350:
    .BYTE $0F, $00, $00, $C3, $CF, $F5, $D5, $D7, $FF, $00, $FF, $55, $FF, $55, $FF, $55
    .BYTE $FF, $00, $FF, $55, $F5, $5D, $57, $57, $FC, $03, $00, $C0, $70, $73, $7D, $75
    .BYTE $00, $FF, $00, $3F, $D5, $FF, $55, $7F, $00, $FF, $00, $FF, $55, $FD, $57, $D5
    .BYTE $00, $FF, $00, $C0, $70, $5C, $5C, $DC, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3
    .BYTE $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $EA, $EA, $EA, $EA, $EA, $EA, $EA, $EA
    .BYTE $AB, $AB, $AB, $AB, $AB, $AB, $AB, $AB, $77, $77, $77, $77, $77, $77, $77, $77
    .BYTE $55, $57, $5F, $5F, $5F, $5F, $5F, $57, $DD, $FF, $F7, $DD, $F7, $FF, $FF, $FF
    .BYTE $5D, $5D, $DD, $DD, $DD, $DD, $DD, $5D, $DD, $DF, $DD, $D7, $DD, $DD, $D7, $DD
    .BYTE $FF, $55, $55, $55, $FF, $55, $55, $FF, $57, $D7, $77, $D7, $77, $77, $D7, $57
    .BYTE $75, $77, $77, $77, $77, $75, $75, $75, $D5, $55, $7F, $D5, $FF, $FF, $FD, $F7
    .BYTE $75, $5D, $DD, $7D, $FD, $75, $F5, $F5, $DC, $DC, $DC, $DC, $DC, $DC, $DC, $DC
    .BYTE $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD
    .BYTE $EA, $EA, $EA, $EA, $EA, $EA, $EA, $EA, $AB, $AB, $AB, $AB, $AB, $AB, $AB, $AB
    .BYTE $77, $77, $77, $77, $77, $77, $77, $77, $55, $55, $D5, $3F, $00, $0F, $0D, $3F
    .BYTE $FD, $55, $55, $FF, $00, $FF, $55, $FF, $5D, $5F, $7C, $F0, $00, $FC, $57, $D5
    .BYTE $DD, $D7, $D5, $35, $0F, $00, $00, $C3, $55, $55, $FF, $55, $FF, $00, $FF, $55
    .BYTE $57, $D7, $57, $5F, $FC, $00, $FF, $55, $75, $75, $F5, $35, $0D, $03, $00, $C0
    .BYTE $FD, $F7, $DF, $FF, $55, $FF, $00, $3F, $F5, $F5, $F5, $F5, $57, $FF, $00, $FF
    .BYTE $DC, $DC, $DC, $F0, $C0, $00, $00, $C0, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3
    .BYTE $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA

.ORG $B6D0

XEX_B6D0_351:
    .BYTE $3C, $42, $91, $99, $BA, $54, $2C, $2A, $14, $08, $00, $00, $00, $3C, $6E, $66
    .BYTE $44, $08, $10, $14, $08, $00, $08, $08

.ORG $B6F0

XEX_B6F0_352:
    .BYTE $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $EA, $EA, $EA, $EA, $EA, $EA, $EA, $EA
    .BYTE $AB, $AB, $AB, $AB, $AB, $AB, $AB, $AB, $77, $77, $77, $77, $77, $77, $77, $77
    .BYTE $D5, $5D, $5F, $5F, $5F, $7F, $7D, $7D, $55, $55, $FF, $FF, $75, $F5, $5F, $55
    .BYTE $75, $5D, $DD, $DD, $5D, $5D, $5D, $DD, $CF, $F5, $D5, $D5, $D7, $D7, $D5, $D7
    .BYTE $FF, $55, $55, $F7, $D5, $7F, $D7, $55, $F5, $5D, $57, $D7, $F7, $77, $D7, $F7
    .BYTE $70, $73, $7D, $75, $75, $77, $77, $77, $D5, $FF, $55, $75, $FD, $F7, $F5, $F5
    .BYTE $55, $FD, $57, $55, $5D, $7D, $DD, $DD, $70, $5C, $5C, $DC, $DC, $DC, $DC, $DC
    .BYTE $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD
    .BYTE $EA, $EA, $EA, $EA, $EA, $EA, $EA, $EA, $AB, $AB, $AB, $AB, $AB, $AB, $AB, $AB
    .BYTE $77, $77, $77, $77, $77, $77, $77, $77, $55, $55, $5F, $75, $5F, $55, $D5, $3F
    .BYTE $57, $7D, $D5, $55, $55, $FD, $55, $FF, $5D, $5D, $5D, $5D, $5D, $5F, $7C, $F0
    .BYTE $D7, $D7, $D7, $D5, $D5, $D7, $D5, $35, $5F, $75, $55, $D7, $FF, $55, $55, $55
    .BYTE $F7, $F7, $F7, $D7, $57, $D7, $57, $5F, $77, $77, $77, $77, $77, $77, $F5, $35
    .BYTE $F5, $F5, $F5, $F5, $DD, $57, $55, $55, $DD, $DD, $DD, $DD, $DD, $F5, $D5, $55
    .BYTE $DC, $DC, $DC, $DC, $DC, $DC, $DC, $F0, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3
    .BYTE $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $EA, $EA, $EA, $EA, $EA, $EA, $EA, $EA
    .BYTE $AB, $AB, $AB, $AB, $AB, $AB, $AB, $AB, $77, $77, $77, $77, $77, $77, $77, $77
    .BYTE $00, $00, $03, $0F, $0F, $0F, $0F, $0F, $00, $00, $FF, $55, $55, $55, $55, $55
    .BYTE $00, $00, $FF, $55, $55, $55, $55, $55, $0F, $00, $F0, $5F, $55, $55, $55, $55
    .BYTE $FF, $00, $00, $FF, $55, $55, $55, $55, $FC, $00, $00, $FF, $55, $55, $55, $55
    .BYTE $0D, $03, $00, $F0, $5F, $55, $55, $55, $55, $FF, $00, $00, $FF, $55, $55, $55
    .BYTE $57, $FF, $00, $00, $FF, $55, $55, $55, $C0, $00, $00, $00, $C0, $70, $70, $70
    .BYTE $C3, $C3, $C3, $C3, $C3, $C3, $C3, $C3, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA

.ORG $B878

XEX_B878_353:
    .BYTE $30, $48, $84, $42, $21, $11, $0A, $04, $0C, $32, $7A, $3C, $1E, $0E, $04, $00
    .BYTE $3E, $3E, $1C

.ORG $B900

XEX_B900_354:
    .BYTE $78, $A9, $80, $8D, $0E, $D4, $A9, $FE, $8D, $01, $D3, $A0, $13, $A2, $00, $BD
    .BYTE $00, $BC, $9D, $00, $0C, $A9, $00, $9D, $00, $BC, $E8, $D0, $F2, $EE, $11, $B9
    .BYTE $EE, $14, $B9, $EE, $19, $B9, $88, $10, $E6, $8C, $01, $D3, $A9, $C0, $8D, $0E
    .BYTE $D4, $58, $A9, $06, $8D, $C8, $02, $8C, $FC, $02, $A6, $13, $E8, $E8, $AD, $84
    .BYTE $02, $F0, $09, $E4, $13, $F0, $05, $CC, $FC, $02, $F0, $F2, $8C, $FC, $02, $C8
    .BYTE $A2, $23, $BD, $17, $BA, $9D, $20, $01, $CA, $10, $F7, $8C, $2F, $02, $8C, $C8
    .BYTE $02, $A9, $41, $8D, $30, $02, $A9, $01, $8D, $31, $02, $A5, $14, $C5, $14, $F0
    .BYTE $FC, $8C, $0E, $D4, $A0, $05, $A2, $00, $BD, $00, $7A, $9D, $00, $94, $E8, $D0
    .BYTE $F7, $EE, $7A, $B9, $EE, $7D, $B9, $88, $D0, $EE, $A0, $07, $A9, $AA, $9D, $00
    .BYTE $99, $E8, $D0, $FA, $EE, $90, $B9, $88, $D0, $F4, $BD, $05, $BA, $8D, $B6, $B9
    .BYTE $BD, $0B, $BA, $8D, $B2, $B9, $BD, $11, $BA, $8D, $B3, $B9, $A0, $00, $B9, $80
    .BYTE $B5, $99, $FF, $FF, $C8, $C0, $FF, $D0, $F5, $98, $18, $6D, $AF, $B9, $8D, $AF
    .BYTE $B9, $AD, $B0, $B9, $69, $00, $8D, $B0, $B9, $E8, $E0, $06, $90, $CC, $A2, $00
    .BYTE $8A, $9D, $00, $7A, $E8, $D0, $FA, $AC, $D3, $B9, $C8, $C0, $94, $D0, $04, $A2
    .BYTE $80, $A0, $B5, $8C, $D3, $B9, $C0, $B9, $D0, $E7, $78, $A2, $FE, $8E, $01, $D3
    .BYTE $E8, $A9, $80, $8D, $FA, $FF, $8E, $FB, $FF, $8E, $01, $D3, $A9, $40, $8D, $0E
    .BYTE $D4, $58, $4C, $00, $0C, $50, $78, $B8, $78, $78, $A8, $00, $18, $58, $D8, $18
    .BYTE $58, $99, $9A, $9B, $9C, $9E, $9F, $A9, $FE, $8D, $01, $D3, $20, $00, $E4, $A9
    .BYTE $FF, $8D, $01, $D3, $A9, $C0, $8D, $0E, $D4, $98, $60, $AC, $09, $D2, $10, $06
    .BYTE $C0, $FF, $F0, $02, $38, $60, $18, $60, $41, $41, $01

; -----------------------------------------------------------------------------
; Recovered runtime entry stubs
; -----------------------------------------------------------------------------

.ORG $E40C

TopBankDispatch:
    .BYTE $4C, $6E, $EF, $00, $8D, $EF, $2D, $F2, $7F, $F1, $A3, $F1, $1D, $F2, $AE, $F9
    .BYTE $4C, $6E, $EF, $00, $1D, $F2, $1D, $F2, $FC, $F2, $2C, $F2, $1D, $F2, $2C, $F2
    .BYTE $4C, $6E, $EF, $00, $C1, $FE, $06, $FF, $C0, $FE, $CA, $FE, $A2, $FE, $C0, $FE
    .BYTE $4C, $99, $FE, $00, $E5, $FC, $CE, $FD, $79, $FD, $B3, $FD, $CB, $FD, $E4, $FC
    .BYTE $4C, $DB, $FC, $00, $4C, $A3, $C6, $4C, $B3, $C6, $4C, $DF, $E4, $4C, $33, $C9
    .BYTE $4C, $72, $C2, $4C, $E2, $C0, $4C, $8A, $C2, $4C, $5C, $E9, $4C, $17, $EC, $4C
    .BYTE $0C, $C0, $4C, $C1, $E4, $4C, $23, $F2, $4C, $90, $C2, $4C, $C8, $C2, $4C, $8D
    .BYTE $FD, $4C, $F7, $FC, $4C, $23, $F2, $4C, $00, $50, $4C, $BC, $EE, $4C, $15, $E9
    .BYTE $4C, $98, $E8, $90, $C9, $95, $C9, $9A, $C9, $9F, $C9, $A4, $C9, $A9, $C9, $4C

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

.ORG $E739

TitleMenuFlow:
    .BYTE $A5, $08, $F0, $25, $A9, $E9, $85, $4A, $A9, $03, $85, $4B, $A0, $12, $18, $B1
    .BYTE $4A, $AA, $C8, $71, $4A, $F0, $26, $B1, $4A, $85, $4B, $86, $4A, $20, $56, $CB
    .BYTE $D0, $1B, $20, $94, $E8, $B0, $16, $90, $E3, $A9, $00, $8D, $FB, $03, $8D, $FC
    .BYTE $03, $A9, $4F, $D0, $2D, $A9, $00, $A8, $20, $BE, $E7, $10, $01, $60, $18, $AD
    .BYTE $E7, $02, $6D, $EA, $02, $8D, $12, $03, $AD, $E8, $02, $6D, $EB, $02, $8D, $13
    .BYTE $03, $38, $AD, $E5, $02, $ED, $12, $03, $AD, $E6, $02, $ED, $13, $03, $B0, $09
    .BYTE $A9, $4E, $A8, $20, $BE, $E7, $4C, $6E, $E7, $AD, $EC, $02, $AE, $E7, $02, $8E
    .BYTE $EC, $02, $AE, $E8, $02, $8E, $ED, $02, $20, $DE, $E7, $30, $E3, $38, $20, $9E
    .BYTE $E8, $B0, $DD, $90, $B0, $48, $A2, $09, $BD, $D4, $E7, $9D, $00, $03, $CA, $10
    .BYTE $F7, $8C, $0B, $03, $68, $8D, $0A, $03, $4C, $59, $E4, $4F, $01, $40, $40, $EA
    .BYTE $02, $1E, $00, $04, $00, $8D, $13, $03, $A2, $00, $8E, $12, $03, $CA, $8E, $15
    .BYTE $03, $AD, $EC, $02, $6A, $90, $08, $EE, $EC, $02, $D0, $03, $EE, $ED, $02, $AD
    .BYTE $EC, $02, $8D, $D1, $02, $AD, $ED, $02, $8D, $D2, $02, $A9, $16, $8D, $CF, $02
    .BYTE $A9, $E8, $8D, $D0, $02, $A9, $80, $8D, $D3, $02, $4C, $45, $C7, $AE, $15, $03
    .BYTE $E8, $8E, $15, $03, $F0, $08, $AE, $15, $03, $BD, $7D, $03, $18, $60, $A9, $80
    .BYTE $8D, $15, $03, $20, $33, $E8, $10, $EE, $38, $60, $A2, $0B, $BD, $51, $E8, $9D
    .BYTE $00, $03, $CA, $10, $F7, $AE, $12, $03, $8E, $0A, $03, $E8, $8E, $12, $03, $AD
    .BYTE $13, $03, $8D, $00, $03, $4C, $59, $E4, $00, $01, $26, $40, $FD, $03, $1E, $00
    .BYTE $80, $00, $00, $00, $8C, $12, $03, $8D, $13, $03, $A9, $E9, $85, $4A, $A9, $03
    .BYTE $85, $4B, $A0, $12, $B1, $4A, $AA, $C8, $B1, $4A, $CD, $13, $03, $D0, $07, $EC
    .BYTE $12, $03, $D0, $02, $18, $60, $C9, $00, $D0, $06, $E0, $00, $D0, $02, $38, $60
    .BYTE $86, $4A, $85, $4B, $20, $56, $CB, $D0, $F5, $F0, $D7, $38, $08, $B0, $28, $8D
    .BYTE $ED, $02, $8C, $EC, $02, $08, $A9, $00, $A8, $20, $5D, $E8, $B0, $27, $A0, $12
    .BYTE $AD, $EC, $02, $91, $4A, $AA, $C8, $AD, $ED, $02, $91, $4A, $86, $4A, $85, $4B
    .BYTE $A9, $00, $91, $4A, $88, $91, $4A, $20, $00, $E9, $90, $0C, $AD, $ED, $02, $AC
    .BYTE $EC, $02, $20, $15, $E9, $28, $38, $60, $28, $B0, $09, $A9, $00, $A0, $10, $91
    .BYTE $4A, $C8, $91, $4A, $18, $A0, $10, $AD, $E7, $02, $71, $4A, $8D, $E7, $02, $C8
    .BYTE $AD, $E8, $02, $71, $4A, $8D, $E8, $02, $A0, $0F, $A9, $00, $91, $4A, $20, $56
    .BYTE $CB, $A0, $0F, $91, $4A, $18, $60, $18, $A5, $4A, $69, $0C, $8D, $12, $03, $A5
    .BYTE $4B, $69, $00, $8D, $13, $03, $6C, $12, $03, $4C, $72, $C2, $20, $5D, $E8, $B0
    .BYTE $3B, $A8, $A5, $4A, $48, $A5, $4B, $48, $86, $4A, $84, $4B, $AD, $44, $02, $D0
    .BYTE $0F, $A0, $10, $18, $B1, $4A, $C8, $71, $4A, $D0, $1F, $20, $56, $CB, $D0, $1A

.ORG $E4DF

TitleHelperChain:
    .BYTE $85, $2F, $86, $2E, $8A, $29, $0F, $D0, $04, $E0, $80, $90, $05, $A0, $86, $4C
    .BYTE $70, $E6, $A0, $00, $BD, $40, $03, $99, $20, $00, $E8, $C8, $C0, $0C, $90, $F4
    .BYTE $A5, $20, $C9, $7F, $D0, $15, $A5, $22, $C9, $0C, $F0, $71, $AD, $E9, $02, $D0
    .BYTE $05, $A0, $82, $4C, $70, $E6, $20, $29, $CA, $30, $F8, $A0, $84, $A5, $22, $C9
    .BYTE $03, $90, $25, $A8, $C0, $0E, $90, $02, $A0, $0E, $84, $17, $B9, $2A, $E7, $F0
    .BYTE $0F, $C9, $02, $F0, $48, $C9, $08, $B0, $5F, $C9, $04, $F0, $76, $4C, $1E, $E6
    .BYTE $A5, $20, $C9, $FF, $F0, $05, $A0, $81, $4C, $70, $E6, $AD, $E9, $02, $D0, $27
    .BYTE $20, $FF, $E6, $B0, $22, $A9, $00, $8D, $EA, $02, $8D, $EB, $02, $20, $95, $E6
    .BYTE $B0, $E6, $20, $EA, $E6, $A9, $0B, $85, $17, $20, $95, $E6, $A5, $2C, $85, $26
    .BYTE $A5, $2D, $85, $27, $4C, $72, $E6, $20, $F9, $EE, $4C, $70, $E6, $A0, $01, $84
    .BYTE $23, $20, $95, $E6, $B0, $03, $20, $EA, $E6, $A9, $FF, $85, $20, $A9, $E4, $85
    .BYTE $27, $A9, $DB, $85, $26, $4C, $72, $E6, $A5, $20, $C9, $FF, $D0, $05, $20, $FF
    .BYTE $E6, $B0, $A5, $20, $95, $E6, $20, $EA, $E6, $A6, $2E, $BD, $40, $03, $85, $20
    .BYTE $4C, $72, $E6, $A5, $22, $25, $2A, $D0, $05, $A0, $83, $4C, $70, $E6, $20, $95
    .BYTE $E6, $B0, $F8, $A5, $28, $05, $29, $D0, $08, $20, $EA, $E6, $85, $2F, $4C, $72
    .BYTE $E6, $20, $EA, $E6, $85, $2F, $30, $41, $A0, $00, $91, $24, $20, $D1, $E6, $A5
    .BYTE $22, $29, $02, $D0, $0C, $A5, $2F, $C9, $9B, $D0, $06, $20, $BB, $E6, $4C, $18
    .BYTE $E6, $20, $BB, $E6, $D0, $DB, $A5, $22, $29, $02, $D0, $1D, $20, $EA, $E6, $85
    .BYTE $00, $03, $CA, $10, $F7, $AE, $12, $03, $8E, $0A, $03, $E8, $8E, $12, $03, $AD
    .BYTE $13, $03, $8D, $00, $03, $4C, $59, $E4, $00, $01, $26, $40, $FD, $03, $1E, $00
    .BYTE $80, $00, $00, $00, $8C, $12, $03, $8D, $13, $03, $A9, $E9, $85, $4A, $A9, $03
    .BYTE $85, $4B, $A0, $12, $B1, $4A, $AA, $C8, $B1, $4A, $CD, $13, $03, $D0, $07, $EC
    .BYTE $12, $03, $D0, $02, $18, $60, $C9, $00, $D0, $06, $E0, $00, $D0, $02, $38, $60
    .BYTE $86, $4A, $85, $4B, $20, $56, $CB, $D0, $F5, $F0, $D7, $38, $08, $B0, $28, $8D
    .BYTE $ED, $02, $8C, $EC, $02, $08, $A9, $00, $A8, $20, $5D, $E8, $B0, $27, $A0, $12
    .BYTE $AD, $EC, $02, $91, $4A, $AA, $C8, $AD, $ED, $02, $91, $4A, $86, $4A, $85, $4B
    .BYTE $A9, $00, $91, $4A, $88, $91, $4A, $20, $00, $E9, $90, $0C, $AD, $ED, $02, $AC
    .BYTE $EC, $02, $20, $15, $E9, $28, $38, $60, $28, $B0, $09, $A9, $00, $A0, $10, $91
    .BYTE $4A, $C8, $91, $4A, $18, $A0, $10, $AD, $E7, $02, $71, $4A, $8D, $E7, $02, $C8
    .BYTE $AD, $E8, $02, $71, $4A, $8D, $E8, $02, $A0, $0F, $A9, $00, $91, $4A, $20, $56
    .BYTE $CB, $A0, $0F, $91, $4A, $18, $60, $18, $A5, $4A, $69, $0C, $8D, $12, $03, $A5
    .BYTE $4B, $69, $00, $8D, $13, $03, $6C, $12, $03, $4C, $72, $C2, $20, $5D, $E8, $B0
    .BYTE $3B, $A8, $A5, $4A, $48, $A5, $4B, $48, $86, $4A, $84, $4B, $AD, $44, $02, $D0
    .BYTE $0F, $A0, $10, $18, $B1, $4A, $C8, $71, $4A, $D0, $1F, $20, $56, $CB, $D0, $1A
