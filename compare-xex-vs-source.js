"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { createHeadlessAutomation } = require("./A8E/jsA8E/headless");

function hex(n, w) { return "$" + n.toString(16).toUpperCase().padStart(w || 4, "0"); }

const playgroundDir = path.resolve(__dirname, "playground");
fs.mkdirSync(playgroundDir, { recursive: true });

async function runAndCapture(label, launchFn, outPath) {
  const runtime = await createHeadlessAutomation({
    cwd: __dirname,
    roms: {
      os: path.resolve(__dirname, "ATARIXL.ROM"),
      basic: path.resolve(__dirname, "ATARIBAS.ROM"),
    },
    turbo: true,
    frameDelayMs: 0,
    optionOnStart: true,
  });

  try {
    const api = runtime.api;
    await launchFn(api);

    console.log(`[${label}] Waiting 30s (real) for title screen...`);
    await api.system.waitForTime({ ms: 30000, clock: "real" });

    const dbg = (await api.getSystemState()).debugState;
    const sdlistLo = await api.debug.readMemory(0x0230);
    const sdlistHi = await api.debug.readMemory(0x0231);
    const sdlist = sdlistLo | (sdlistHi << 8);
    const portb = await api.debug.readMemory(0xD301);
    const dmactl = await api.debug.readMemory(0xD400);
    const colbk = await api.debug.readMemory(0xD01A);
    console.log(`[${label}] PC=${hex(dbg.pc)} PORTB=${hex(portb,2)} DMACTL=${hex(dmactl,2)} SDLIST=${hex(sdlist)} COLBK=${hex(colbk,2)} instrs=${dbg.instructionCounter}`);

    // Show first 16 bytes of display list
    const dl = await api.debug.readRange(sdlist, 16);
    console.log(`[${label}] DL: ${Array.from(dl).map(b => hex(b,2)).join(" ")}`);

    // Disassemble around PC
    const dis = await api.debug.disassemble({ pc: dbg.pc, count: 5 });
    console.log(`[${label}] Disasm: ${dis.instructions.map(i => `${hex(i.address)}:${i.text}`).join("  ")}`);

    const shot = await api.artifacts.captureScreenshot({ encoding: "bytes" });
    fs.writeFileSync(outPath, Buffer.from(shot.bytes));
    console.log(`[${label}] Screenshot saved: ${path.basename(outPath)} (${shot.width}x${shot.height})`);
  } finally {
    await runtime.dispose();
  }
}

async function main() {
  // --- Run 1: original XEX ---
  await runAndCapture("XEX", async (api) => {
    const xexPath = path.resolve(__dirname, "Spy vs Spy (Title Version).xex");
    const xexData = fs.readFileSync(xexPath);
    console.log("[XEX] Launching original XEX (portB=0xFE, awaitEntry=false)...");
    await api.dev.runXex({ bytes: xexData, resetOptions: { portB: 0xfe }, awaitEntry: false });
  }, path.join(playgroundDir, "cmp-xex-30s.png"));

  // --- Run 2: assembled source ---
  await runAndCapture("SRC", async (api) => {
    const source = fs.readFileSync(path.resolve(__dirname, "Spy vs Spy (Title Version).s"), "utf8");
    console.log("[SRC] Assembling source...");
    const build = await api.dev.assembleSource({ name: "Spy vs Spy (Title Version).s", text: source });
    if (!build.ok) { console.error("Assembly failed:", build); throw new Error("assembly failed"); }
    console.log(`[SRC] Assembly ok — ${build.byteLength} bytes, runAddr=${hex(build.runAddr)}`);
    await api.dev.runXex({ build, resetOptions: { portB: 0xfe }, awaitEntry: false });
  }, path.join(playgroundDir, "cmp-src-30s.png"));
}

main().catch(err => { console.error(err && err.stack ? err.stack : String(err)); process.exitCode = 1; });
