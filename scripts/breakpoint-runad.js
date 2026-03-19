"use strict";

const { assembleSource, hex, runBuild, withSpyAutomation } = require("./automation");

async function main() {
  await withSpyAutomation({ optionOnStart: true }, async (api) => {
    const build = await assembleSource(api);
    if (!build.ok) throw new Error("Assembly failed");

    // Set breakpoint at RUNAD $C290
    await api.debug.setBreakpoints([0xC290]);

    await runBuild(api, build, { resetOptions: { portB: 0xfe }, awaitEntry: false });

    console.log("Waiting for breakpoint at $C290 (RUNAD)...");
    const stop = await api.debug.waitForBreakpoint({ timeoutMs: 15000 });
    if (!stop || !stop.ok) { console.error("Breakpoint not hit:", stop); process.exitCode = 1; return; }

    const dbg = stop.debugState || (await api.debug.getDebugState());
    console.log(`Breakpoint hit at PC=${hex(dbg.pc)}`);

    // Read memory state at the moment RUNAD fires
    const mem7f = await api.debug.readRange(0x7F00, 4);
    const memac = await api.debug.readRange(0xAC00, 8);
    const mem0244 = await api.debug.readMemory(0x0244);
    const mem03fa = await api.debug.readMemory(0x03FA);
    const portb = await api.debug.readMemory(0xD301);

    console.log(`$7F00: ${Array.from(mem7f).map(b => hex(b,2)).join(" ")} (expect: $A3 $16 $AD $00)`);
    console.log(`$AC00: ${Array.from(memac).map(b => hex(b,2)).join(" ")} (expect: $DD $DD $DD...)`);
    console.log(`$0244 (BASICF/COLDST): ${hex(mem0244, 2)} (expect: $00 for normal boot)`);
    console.log(`$03FA: ${hex(mem03fa, 2)}`);
    console.log(`PORTB: ${hex(portb, 2)}`);

    // Disassemble from C290 to see what boot code does
    const dis = await api.debug.disassemble({ pc: 0xC290, count: 10 });
    console.log("\nCode at $C290:");
    dis.instructions.forEach(i => console.log(`  ${hex(i.address)}: ${i.text}`));
  });
}

main().catch((err) => { console.error(err && err.stack ? err.stack : String(err)); process.exitCode = 1; });
