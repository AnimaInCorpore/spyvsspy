"use strict";

const { assembleSource, captureScreenshot, hex, runBuild, withSpyAutomation } = require("./automation");

async function main() {
  await withSpyAutomation({}, async (api) => {
    console.log("Assembling...");
    const build = await assembleSource(api);
    if (!build.ok) { console.error("Assembly failed:", build); process.exitCode = 1; return; }
    console.log(`Assembly ok — ${build.byteLength} bytes, runAddr=${hex(build.runAddr)}`);

    if (build.segments) {
      console.log("Segments:", build.segments.map((s) => `${hex(s.start)}-${hex(s.end)}`).join(", "));
    }

    console.log("Launching XEX (portB=0xFE, awaitEntry=false)...");
    await runBuild(api, build, { resetOptions: { portB: 0xfe }, awaitEntry: false });

    for (const label of ["1s", "5s", "10s", "20s"]) {
      const waitMs = label === "1s" ? 1000 : label === "5s" ? 4000 : label === "10s" ? 5000 : 10000;
      await api.system.waitForTime({ ms: waitMs, clock: "real" });

      const dbg = (await api.getSystemState()).debugState;
      const dmactl = await api.debug.readMemory(0xD400);
      const sdlistLo = await api.debug.readMemory(0x0230);
      const sdlistHi = await api.debug.readMemory(0x0231);
      const portb = await api.debug.readMemory(0xD301);
      const consol = await api.debug.readMemory(0xD01F);
      const sdlist = sdlistLo | (sdlistHi << 8);

      console.log(`\n=== ${label} ===`);
      console.log(`  PC=${hex(dbg.pc)}  A=${hex(dbg.a,2)}  X=${hex(dbg.x,2)}  Y=${hex(dbg.y,2)}`);
      console.log(`  DMACTL=${hex(dmactl,2)}  SDLIST=${hex(sdlist)}  PORTB=${hex(portb,2)}  CONSOL=${hex(consol,2)}`);
      console.log(`  cycles=${dbg.cycleCounter}  instrs=${dbg.instructionCounter}`);

      const dis = await api.debug.disassemble({ pc: dbg.pc, count: 8 });
      console.log("  Disassembly:");
      dis.instructions.forEach((i) => console.log(`    ${hex(i.address)}: ${i.text}`));
    }

    console.log("\nCapturing screenshot...");
    const shot = await captureScreenshot(api, "spyvsspy-diag-shot.png");
    console.log(`Screenshot: ${shot.path} (${shot.width}x${shot.height})`);
  });
}

main().catch((err) => { console.error(err && err.stack ? err.stack : String(err)); process.exitCode = 1; });
