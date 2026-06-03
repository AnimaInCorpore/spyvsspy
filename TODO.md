# Spy vs Spy Disassembly TODO

Goal: produce a single-file disassembled source that can run in jsA8E and behave like `Spy vs Spy (Title Version).s`.

## Confirmed Areas
- Bootstrap / loader path: `$C290-$C4DA`
- Multi-stage XEX loader: Stages 1-7 (via `src/INIT_STAGE_*.s` and `src/D400.s`)
- Runtime setup and VBI install: `$EDE2-$EDF2`
- Main frame/state loop: `$E9B8-$EB85`
- Table scan / slot-fill routine: `$3D5D-$3DE0` in `src/3ADD.s`
- ... (many other segments already recovered)

## Pending / Issues
- [x] Correct INITAD/multi-stage loader replication.
- [x] Fix NMI disabling (D400.s included).
- [x] Fix RUNAD address ($C290).
- [ ] **Investigate runtime divergence after boot**: the old `$3D5F` hang is no longer the main symptom. The rebuilt source now boots, but it diverges from the original long-run path and lands at `PC=$C02D` with `SDLIST=$ACAA` and a blank blue screen instead of reaching the original title path.
- [ ] Finalize disassembly of the `$E9B8-$FE8C` runtime chain and the `C02C/C2AA` vector-handling path to match original execution.
- [ ] Treat adjacent bytes as code only when execution traces confirm it; this binary mixes routines, tables, strings, and vector data, so blind linear disassembly is not sufficient.

## Root Cause of Remaining Divergence (2026-06-03)

**The game streams runtime code from disk via SIO during gameplay.**

Key findings from deep diagnostic session:

1. **$C02C IRQ handler was wrong** → Fixed: created `src/C000.s` covering `$C000-$C28F` (NMI at `$C018`, DLI at `$C020`, IRQ at `$C02C`). Old `src/C02C.s` had garbage bytes.

2. **RUNAD was $B900 (disk loader)** → Changed RUNAD to `$C290` (game bootstrap entry) in `src/RUNAD.s`. `INIT_STAGE_6.s` removed from MANIFEST so B900 never runs.

3. **The game's main loop at `$EB16-$EB24` waits for SIO serial data** (`$39` to become `$FF`). In the original XEX, at ~2500ms jsA8E serves SIO data from the XEX-as-disk. This data includes:
   - The DLI handler at `$9F50` (first byte `$48` arrives at t=2500ms at PC=`$EB1D`)
   - Animation frame data
   - Sound data
   - These are NOT in the original XEX as standard XEX segments — they're in the disk sector data jsA8E serves during SIO reads.

4. **Our source XEX doesn't have this streaming data** at the right sector positions. So the SIO loop never receives data, `$9F50` stays `$00`, VDSLST is never set to `$9F50`, and the title screen never loads.

5. **`$9F50` starts as `$00` in BOTH original and source** at boot time. The original populates it at 2500ms via SIO. Our `src/9F50.s` static segment gets wiped by the OS boot init before the game runs.

## Next Disassembly Targets

**Critical**: Understand the SIO streaming data format and embed it correctly in the source XEX.

- The streaming data is served by jsA8E when running the original XEX. Capture the exact byte sequence that arrives at `$EB2C-$EB59` (serial IRQ receiver).
- The data stream loads code starting at `$9F50` and animation frames — these need to be part of the source XEX in jsA8E-compatible sector format.
- Alternative: modify the source's SIO loader to read from a static RAM buffer instead of the serial port, pre-populated at XEX load time.
- Trace `$E739` (TitleMenuFlow) to understand when/how it calls `$9F93` (which sets SDLIST=`$7F2E`, VDSLST=`$9F50`).

## Verification
- Re-run the game in jsA8E after each major chunk is recovered.
- Latest state (2026-06-03): source diverges at ~2500ms when original receives SIO streaming data and source does not. Original transitions to SDLIST=`$7F2E` at ~11s; source crashes to SDLIST=`$ACAA`.

## Workspace Hygiene
- `playground/` is the scratch area for screenshots, hex dumps, and snapshot blobs.
- Automation scripts now write their generated outputs there instead of the repo root.
- The JS automation entry points now share `scripts/automation.js` for runtime setup and file helpers.
- The helper scripts live under `scripts/` for a clearer project structure.
- Future automation work should preserve this split: `scripts/` for code, `playground/` for generated files, repo root for project sources and docs.
