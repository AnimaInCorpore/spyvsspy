# Agents Guide: Spy vs Spy Disassembly

This guide helps agents maintain continuity on the disassembly project.

## Project Status (As of 2026-03-19)
The project aims to replicate `Spy vs Spy (Title Version).xex` as an assembly source (`Spy vs Spy (Title Version).s`). 
- **Loader:** Multi-stage loader (7 stages) is now fully replicated using `src/INIT_STAGE_*.s` and `src/D400.s`.
- **Initialization:** The loader successfully handles memory filling and initialization before handing off to the runtime code.
- **Current Blocker:** The game boots but enters an infinite loop/hang at `PC=$3D5F` (uninitialized memory), which indicates an incorrect runtime handoff or a missing segment that contains the VBI handler/runtime support.

## Handover Instructions for Incoming Agents
1.  **Check the `TODO.md` file:** It is the canonical source of truth for the project state and the immediate next steps.
2.  **Verify the environment:**
    *   Use `.\scripts\rebuild-spyvsspy.ps1` to re-assemble.
    *   Use `node scripts/run-spyvsspy-headless.js` or `node scripts/diag-spyvsspy2.js` to inspect runtime behavior.
3.  **Investigate the `$3D5F` hang:**
    *   The `PC` points to `$3D5F`, which is currently just `$00` (BRK). 
    *   Use the `jsA8E` debugger to trace why the jump to this location occurs.
    *   Compare memory segments between the original XEX and the assembled output (`xex_dump.txt` analysis) to identify missing data slices.
4.  **Documentation:** Always update `TODO.md` with any findings or changes to the plan before completing your session.
