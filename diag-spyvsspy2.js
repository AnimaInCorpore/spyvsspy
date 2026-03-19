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

    const source = fs.readFileSync(path.resolve(__dirname, "Spy vs Spy (Title Version).s"), "utf8");
    console.log("Assembling...");
    const build = await api.dev.assembleSource({ name: "Spy vs Spy (Title Version).s", text: source });
    if (!build.ok) { console.error("Assembly failed:", build); process.exitCode = 1; return; }
    console.log(`Assembly ok — runAddr=${hex(build.runAddr)}`);

    await api.dev.runXex({ build, resetOptions: { portB: 0xfe }, awaitEntry: false });

    // Let the game boot for 3 real seconds
    console.log("Waiting 3s for boot...");
    await api.system.waitForTime({ ms: 3000, clock: "real" });

    // Read display state
    const sdlistLo = await api.debug.readMemory(0x0230);
    const sdlistHi = await api.debug.readMemory(0x0231);
    const sdlist = sdlistLo | (sdlistHi << 8);
    const dmactl = await api.debug.readMemory(0xD400);
    const colbk = await api.debug.readMemory(0xD01A);  // background color
    const colpf2 = await api.debug.readMemory(0xD018); // playfield color 2
    console.log(`Display: DMACTL=${hex(dmactl,2)} SDLIST=${hex(sdlist)} COLBK=${hex(colbk,2)} COLPF2=${hex(colpf2,2)}`);

    // Read first 32 bytes of display list
    const dl = await api.debug.readRange(sdlist, 32);
    console.log("DL bytes:", Array.from(dl).map(b => hex(b,2)).join(" "));

    // Screenshot before input
    let shot = await api.artifacts.captureScreenshot({ encoding: "bytes" });
    fs.writeFileSync(path.resolve(__dirname, "spyvsspy-before-input.png"), Buffer.from(shot.bytes));
    console.log("Saved spyvsspy-before-input.png");

    // Press START to advance past any title/menu
    console.log("Pressing START...");
    await api.input.pressConsoleKey("start", { holdMs: 200, afterMs: 500 });

    await api.system.waitForTime({ ms: 3000, clock: "real" });
    shot = await api.artifacts.captureScreenshot({ encoding: "bytes" });
    fs.writeFileSync(path.resolve(__dirname, "spyvsspy-after-start.png"), Buffer.from(shot.bytes));
    console.log("Saved spyvsspy-after-start.png");

    // Try joystick fire button
    console.log("Pressing fire button...");
    await api.input.setJoystick({ trigger: true });
    await api.system.waitForTime({ ms: 300, clock: "real" });
    await api.input.setJoystick({ trigger: false });
    await api.system.waitForTime({ ms: 3000, clock: "real" });

    shot = await api.artifacts.captureScreenshot({ encoding: "bytes" });
    fs.writeFileSync(path.resolve(__dirname, "spyvsspy-after-fire.png"), Buffer.from(shot.bytes));
    console.log("Saved spyvsspy-after-fire.png");

    // Final state
    const dbg = (await api.getSystemState()).debugState;
    const sdlist2Lo = await api.debug.readMemory(0x0230);
    const sdlist2Hi = await api.debug.readMemory(0x0231);
    const sdlist2 = sdlist2Lo | (sdlist2Hi << 8);
    console.log(`Final PC=${hex(dbg.pc)} SDLIST=${hex(sdlist2)}`);

  } finally {
    await runtime.dispose();
  }
}

main().catch(err => { console.error(err && err.stack ? err.stack : String(err)); process.exitCode = 1; });
