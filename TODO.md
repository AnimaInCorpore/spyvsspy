# Spy vs Spy Disassembly TODO

Goal: produce a single-file disassembled source that can run in jsA8E and behave like `Spy vs Spy (Title Version).s`.

## Confirmed Areas
- Bootstrap / loader path: `$C290-$C4DA`
- Multi-stage XEX loader: Stages 1-7 (via `src/INIT_STAGE_*.s` and `src/D400.s`)
- Runtime setup and VBI install: `$EDE2-$EDF2`
- Main frame/state loop: `$E9B8-$EB85`
- ... (many other segments already recovered)

## Pending / Issues
- [x] Correct INITAD/multi-stage loader replication.
- [x] Fix NMI disabling (D400.s included).
- [x] Fix RUNAD address ($C290).
- [ ] **Investigate VBI/Runtime handler segment**: Execution halts at `$3D5F` (uninitialized memory), suggesting a missing segment or a faulty runtime handoff.
- [ ] Finalize disassembly of the `$E9B8-$FE8C` runtime chain to match original execution.

## Next Disassembly Targets
- Locate and recover the data block/code segment corresponding to `$3D5F`.
- Verify the runtime transition after the loader stubs finish.
- Continue refining provisional disassembly blocks in the runtime chain.

## Verification
- Re-run the game in jsA8E after each major chunk is recovered.
- Confirm the disassembled source boots and follows the original runtime path.
