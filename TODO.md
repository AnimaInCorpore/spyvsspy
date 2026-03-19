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
- [ ] **Investigate VBI/Runtime handler segment**: the bytes at `$3D5F` are now identified as the recovered table-scan routine in `src/3ADD.s`; the remaining issue is the earlier runtime divergence that prevents the rebuilt image from following the original long-run title/game path.
- [ ] Finalize disassembly of the `$E9B8-$FE8C` runtime chain to match original execution.

## Next Disassembly Targets
- Trace the caller chain into the `$3D5D-$3DE0` table-scan routine.
- Verify the runtime transition after the loader stubs finish and reconcile the rebuilt runtime with the original long-run path.
- Continue refining provisional disassembly blocks in the runtime chain.

## Verification
- Re-run the game in jsA8E after each major chunk is recovered.
- Confirm the disassembled source boots and follows the original runtime path.

## Workspace Hygiene
- `playground/` is the scratch area for screenshots, hex dumps, and snapshot blobs.
- Automation scripts now write their generated outputs there instead of the repo root.
