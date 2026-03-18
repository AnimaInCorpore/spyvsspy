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

