# Spy vs Spy Disassembly TODO

Goal: produce a single-file disassembled source that can run in jsA8E and behave like `Spy vs Spy (Title Version).xex`.
Target source file: `Spy vs Spy (Title Version).s`.
Exact byte-for-byte XEX identity is no longer the target during active disassembly; recovered code/data structure and behavior take priority.

Rules:
- Do not modify any git submodule contents.
- Keep the source runnable in jsA8E.
- Keep code as code and tables/music/graphics as data where possible.
- Prefer small, verifiable disassembly steps.

## Confirmed Areas
- Loader / bootstrap path: `$C290-$C4DA`
- Runtime setup and VBI install: `$EDE2-$EDF2`
- Main frame/state loop: `$E9B8-$EB85`
- Per-frame update helpers: `$EC04-$EDF2`
- Lower-bank frame/setup path: `$E98D-$E9B7`
- Lower-bank main decision loop: `$E9B8-$EA21`
- Lower-bank end-of-turn helper: `$EA22-$EA36`
- Lower-bank state init / Display List setup: `$EA37-$EAAC`
- Lower-bank display-list feed loop: `$EAAD-$EADA`
- Lower-bank NMI/VBI feed tail: `$EADB-$EAFC`
- Lower-bank VBI entry helper: `$EAFD-$EB27`
- Lower-bank IRQ/input tail: `$EB2C-$EB85`
- Lower-bank runtime setup helper: `$ECAF-$ECC7`
- Lower-bank coordinate decode helper: `$EC9A-$ECA8`
- Lower-bank coordinate/sprite setup helper: `$ECC8-$ECEF`
- Lower-bank position math helper: `$ECF1-$ED2D`
- Lower-bank clamp/helper stub: `$ED2E-$ED3C`
- Lower-bank IRQ/display-list poll helper: `$ED3D-$ED95`
- Lower-bank sprite restore tail: `$ED96-$EDC6`
- Lower-bank reset/cleanup tail: `$EDC7-$EDF2`
- Upper gameplay/runtime code: `$EF00-$FFD6`
- Top-bank runtime code: `$FC00-$FFD6`
- Upper-bank entry/helper block: `$EF00-$EF25`
- Upper-bank object/helper block: `$EF26-$EF8D`
- Upper-bank state setup / mode select: `$EF8E-$F153`
- Upper-bank turn/object logic: `$F154-$F25B`
- Upper-bank interaction loop: `$F25C-$F2FC`
- Upper-bank action decoder: `$F2FD-$F3DD`
- Upper-bank movement bounds / redraw logic: `$F3E0-$F59F`
- Upper-bank tile/object address helper: `$F420-$F44F`
- Upper-bank collision/transition logic: `$F450-$F4D2`
- Upper-bank object update logic: `$F4D5-$F509`
- Upper-bank draw/update logic: `$F50C-$F55E`
- Upper-bank position/occupancy helper: `$F565-$F59F`
- Upper-bank object state helper: `$F5A0-$F5AB`
- Upper-bank coordinate math helper: `$F5AC-$F609`
- Upper-bank collision/state helper: `$F60A-$F65E`
- Upper-bank object selection helper: `$F661-$F6C9`
- Upper-bank movement/search loop: `$F6CA-$F705`
- Upper-bank overlay helper: `$F718-$F731`
- Upper-bank flag/mask helpers: `$F73C-$F78D`
- Upper-bank copy/scroll helper: `$F78E-$F7BF`
- Upper-bank screen-scan helper: `$F7C2-$F7F6`
- Upper-bank collision map helper: `$F7F7-$F88D`
- Upper-bank position restore / compare helpers: `$F88E-$F9A5`
- Upper-bank state save helpers: `$F9A6-$F9FF`
- Top-bank interrupt/runtime entry: `$FC00-$FC8F`
- Top-bank state swap / IRQ tail: `$FC90-$FCD5`
- Top-bank menu/status helpers: `$FCDB-$FD7A`
- Top-bank screen/helper loop: `$FDFC-$FE8C`
- Top-bank helper lookup data: `$FE95-$FEA2`
- Top-bank copy/setup helper: `$FEA3-$FEC1`
- Top-bank emit loop: `$FECB-$FF13`
- Top-bank I/O setup helper: `$FF14-$FF43`
- Top-bank status helper: `$FF44-$FF6E`
- Top-bank ROM checksum routines: `$FF73-$FFD6`
- Routine pointer table: `$FB04-$FB3F`
- Packed lookup/data table (likely text/character map): `$FB40-$FBFF`
- Data/tables tail: `$FFD7-$FFF9`
- Vector tail: `$FFFA-$FFFF`
- Data/data-adjacent helper tail: `$ED20-$EDF2`
- Final helper tail: `$EDAD-$EDF2`

## Next Disassembly Targets
- Continue refining the remaining provisional disassembly blocks in the `$E9B8-$FE8C` runtime chain.
- Treat `$FB04-$FB3F` as routine pointers, `$FB40-$FBFF` as packed lookup data, `$FFD7-$FFF9` as tail data, and `$FFFA-$FFFF` as the vector tail.
- Mark graphics, music, and lookup tables explicitly as data in the final source.
- Follow the relocated runtime handoff path after the loader stub finishes copying state.

## Verification
- Re-run the game in jsA8E after each major chunk is recovered.
- Confirm that the disassembled source still boots and follows the same runtime path.
- Watch for accidental code/data misclassification around large table regions.
