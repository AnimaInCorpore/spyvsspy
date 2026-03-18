# Agent: Spy vs Spy (Title Version) Assembly Generator

This agent is responsible for generating a **single-file assembler source** that, when assembled with the **jsA8E automation API**, reproduces the original **Spy vs Spy (Title Version).xex** behavior and recovered structure.

## 🎯 Goal
Produce a one-file assembly source that, using the jsA8E automation API, preserves the original game's behavior and the recovered code/data layout.

## ✅ Rules
1. **Single-file output only**
   - Generate one assembly source file named `Spy vs Spy (Title Version).s` (no includes, no external modules).

2. **Use jsA8E automation API**
   - All assembly generation and output creation must be described as if emitted by the jsA8E automation API.
   - Assume the API provides directives for emitting bytes, labels, branches, and data.

3. **Preserve behavior and layout fidelity**
   - The generated source should preserve all code entry points, data tables, and embedded resources.
   - Exact byte-for-byte identity with the supplied `Spy vs Spy (Title Version).xex` is not required while disassembly is still in progress, but recovered regions should remain structurally faithful.

4. **No external dependencies in the output**
   - The resulting assembly file should not rely on external libraries or helpers.

5. **Preserve naming and structure fidelity**
   - Use descriptive labels matching original routines wherever possible.
   - If exact label names aren’t available, use consistent, clear names.

6. **Do not modify git submodules**
   - Keep all edits outside tracked submodule directories.
   - Treat submodule contents as read-only unless the user explicitly asks to change them.

## 📌 Notes for Future Execution
- The agent must assume it has access to the `Spy vs Spy (Title Version).xex` binary for comparison/verification.
- The goal is to recreate the game in a single assembly source file that a jsA8E pipeline can assemble into a faithful build of the game.
- During recovery work, temporary segmented source files may be kept in a separate working folder for readability and partial verification, but the final deliverable must always be consolidated into `Spy vs Spy (Title Version).s`.
- Do not introduce `include` directives or external dependencies into the final source file; segmentation is only a development aid.
- When disassembly is incomplete, temporary data scaffolding is acceptable, but recovered code should be rewritten as mnemonics as soon as the routine structure is known.
- When disassembling, add concise comments for Atari 8-bit hardware addresses and Atari-specific routines where it improves readability, especially for Display List access, interrupt vectors, memory-mapped registers, and other common 6502/Atari idioms.

---

*This file is intended for internal agent guidance and is not part of the game source itself.*
