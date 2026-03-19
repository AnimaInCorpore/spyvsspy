"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { createHeadlessAutomation } = require("./A8E/jsA8E/headless");

function hex(n, w) { return "$" + n.toString(16).toUpperCase().padStart(w || 4, "0"); }

async function main() {
  const runtime = await createHeadlessAutomation({
    cwd: __dirname,
    roms: {
      os: path.resolve(__dirname, "ATARIXL.ROM"),
      basic: path.resolve(__dirname, "ATARIBAS.ROM"),
    },
    turbo: true,
    frameDelayMs: 0,
  });

  try {
    const api = runtime.api;

    const sourcePath = path.resolve(__dirname, "Spy vs Spy (Title Version).s");
    const source = fs.readFileSync(sourcePath, "utf8");
    console.log("Assembling...");
    const build = await api.dev.assembleSource({ name: path.basename(sourcePath), text: source });
    if (!build.ok) { console.error("Assembly failed:", build); process.exitCode = 1; return; }
    console.log(`Assembly ok — ${build.byteLength} bytes, runAddr=${hex(build.runAddr)}`);

    // Log XEX segments from build symbols if available
    if (build.segments) {
      console.log("Segments:", build.segments.map(s => `${hex(s.start)}-${hex(s.end)}`).join(", "));
    }

    console.log("Launching XEX (portB=0xFE, awaitEntry=false)...");
    await api.dev.runXex({ build, resetOptions: { portB: 0xfe }, awaitEntry: false });

    // Sample state at 1s, 5s, 10s intervals
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

      // Disassemble around current PC
      const dis = await api.debug.disassemble({ pc: dbg.pc, count: 8 });
      console.log("  Disassembly:");
      dis.instructions.forEach(i => console.log(`    ${hex(i.address)}: ${i.text}`));
    }

    // Take screenshot
    console.log("\nCapturing screenshot...");
    const shot = await api.artifacts.captureScreenshot({ encoding: "bytes" });
    const outPath = path.resolve(__dirname, "spyvsspy-diag-shot.png");
    fs.writeFileSync(outPath, Buffer.from(shot.bytes));
    console.log(`Screenshot: ${outPath} (${shot.width}x${shot.height})`);

  } finally {
    await runtime.dispose();
  }
}

main().catch(err => { console.error(err && err.stack ? err.stack : String(err)); process.exitCode = 1; });
