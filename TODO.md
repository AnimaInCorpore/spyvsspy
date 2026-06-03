# Spy vs Spy Disassembly TODO

Goal: produce a single-file disassembled source that assembles to a XEX which simply works like the original in jsA8E.

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
- [x] Fix XEX-as-ATR sector stream alignment for the title/DLI load. The recovered high/boot support segments (`$C000+`, `$E98D+`, etc.) are now loaded near the end of the XEX, before `RUNAD`, instead of being prepended ahead of the original early segments.
- [ ] **Verify post-title behavior**: the source now reaches the title screen (`SDLIST=$7F2E`, `VDSLST=$9F50`) and no longer crashes to `$3D5F`/`$C02D`. Runtime traces show the title/menu code path (`$E739/$E7CE/$E98D`) matches the original, but the title counter/state (`$030A/$023C`) can drift by a few frames under real-time sampling. The next useful target is the early boot/loader phase rather than the hot title routine itself.
- [ ] Finalize disassembly of the `$E9B8-$FE8C` OS/SIO/runtime chain and the `C02C/C2AA` vector-handling path only where it is genuinely part of the loaded program behavior; much of this range is OS ROM behavior observed during XEX loading.
- [ ] Treat adjacent bytes as code only when execution traces confirm it; this binary mixes routines, tables, strings, and vector data, so blind linear disassembly is not sufficient.

## Root Cause and Current Strategy (2026-06-03)

**jsA8E converts XEX files into bootable ATR images, and the original depends on the sector positions of bytes in that converted image.**

Key findings:

1. **$C02C IRQ handler was wrong** → Fixed: created `src/C000.s` covering `$C000-$C28F` (NMI at `$C018`, DLI at `$C020`, IRQ at `$C02C`). Old `src/C02C.s` had garbage bytes; the active handler now lives in `src/C000.s`, and any standalone `src/C02C.s` copy should stay out of the manifest.

2. **RUNAD was $B900 (disk loader)** → Changed RUNAD to `$C290` (game bootstrap entry) in `src/RUNAD.s`. `INIT_STAGE_6.s` removed from MANIFEST so B900 never runs.

3. **The XEX boot loader reads the mounted XEX as sequential ATR sectors via OS SIO.** The original XEX's sector stream includes:
   - The DLI handler at `$9F50` (first byte `$48`)
   - Animation frame data
   - Sound data
   - Later stage payloads whose sector positions matter

4. **The previous source prepended recovered high-memory support segments**, shifting `$9F50` from original sector `$3D` to source sector `$74`. The loader then consumed the wrong sector data and eventually crashed to the old `$3D5F`/`$C02D` path.

5. **Manifest reorder fix:** keep the original early segment stream first, then load recovered high-memory support segments near the end before `RUNAD`. After this change, `$9F50` is again reached at sector `$3D`, the DLI bytes match, and the title screen renders.

## Next Disassembly Targets

**Critical**: keep the generated XEX's normalized sector stream compatible with the original while still adding recovered support code needed for a monolithic working XEX.

- `src/E4DF.s` is now linearized. Continue the remaining title helper chain work in `src/E739.s`: the deeper helpers/tables at `E7BE+` and `E85D+` are mostly recovered, with one unsupported byte still left in the span.
- Compare normalized XEX offsets and ATR sectors after each manifest/source change, especially around `$9F50`, stage INITAD markers, and large `$2000+`/`$3ADD+` payloads.
- Continue tracing original/source after the title screen and verify START/fire handling, menu transition, and gameplay entry.
- If more sector-sensitive loads appear, fix segment ordering/padding first; only patch game logic if sector-compatible XEX layout cannot reasonably carry the data.
- The title/menu routine itself is now aligned enough to de-prioritize; trace the boot/loader phase around `$B900`/`$C290` if the frame-cadence skew needs to be eliminated.

## Verification
- Re-run the game in jsA8E after each major chunk is recovered.
- Latest state (2026-06-03): source assembles to 48,220 bytes and reaches the title screen. `node scripts/diag-source-vs-original.js` confirms matching `$9F50` bytes and `SDLIST=$7F2E`/`VDSLST=$9F50`. `node scripts/compare-state.js` confirms source/original both reach the title display state by ~3s. `node scripts/diag-spyvsspy2.js` captures a correct title screenshot. Current runtime tracing shows the title-loop code matches the original, and the remaining discrepancy is a small timing/phase skew in `$030A/$023C`, so the next investigation should focus on the boot/loader phase rather than the menu routine itself.

## Workspace Hygiene
- `playground/` is the scratch area for screenshots, hex dumps, and snapshot blobs.
- Automation scripts now write their generated outputs there instead of the repo root.
- The JS automation entry points now share `scripts/automation.js` for runtime setup and file helpers.
- The helper scripts live under `scripts/` for a clearer project structure.
- Future automation work should preserve this split: `scripts/` for code, `playground/` for generated files, repo root for project sources and docs.
