"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { createHeadlessAutomation } = require("./A8E/jsA8E/headless");

function hex(n, w) { return "$" + n.toString(16).toUpperCase().padStart(w || 4, "0"); }

async function snapshot(label, api) {
  const dbg = (await api.getSystemState()).debugState;
  const sdlistLo = await api.debug.readMemory(0x0230);
  const sdlistHi = await api.debug.readMemory(0x0231);
  const sdlist = sdlistLo | (sdlistHi << 8);
  const portb = await api.debug.readMemory(0xD301);

  // Read $ACAA
  const acaa = await api.debug.readRange(0xAC00, 16);
  const acaa_data = Array.from(acaa).map(b => hex(b,2)).join(" ");

  // Read $7F00
  const mem7f00 = await api.debug.readRange(0x7F00, 8);
  const mem7f00_data = Array.from(mem7f00).map(b => hex(b,2)).join(" ");

  console.log(`[${label}] PC=${hex(dbg.pc)} PORTB=${hex(portb,2)} SDLIST=${hex(sdlist)}`);
  console.log(`[${label}] $AC00: ${acaa_data}`);
  console.log(`[${label}] $7F00: ${mem7f00_data}`);
}

async function run(label, launchFn, outPath) {
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

    // Snapshot immediately after launch
    await api.system.waitForTime({ ms: 500, clock: "real" });
    await snapshot(label + "@0.5s", api);

    await api.system.waitForTime({ ms: 4500, clock: "real" });
    await snapshot(label + "@5s", api);

    await api.system.waitForTime({ ms: 25000, clock: "real" });
    await snapshot(label + "@30s", api);

    const shot = await api.artifacts.captureScreenshot({ encoding: "bytes" });
    fs.writeFileSync(outPath, Buffer.from(shot.bytes));
    console.log(`[${label}] Screenshot: ${path.basename(outPath)}`);
  } finally {
    await runtime.dispose();
  }
}

async function main() {
  await run("XEX", async (api) => {
    const xex = fs.readFileSync(path.resolve(__dirname, "Spy vs Spy (Title Version).xex"));
    await api.dev.runXex({ bytes: xex, resetOptions: { portB: 0xfe }, awaitEntry: false });
  }, path.resolve(__dirname, "cmp-xex-30s.png"));

  await run("SRC", async (api) => {
    const source = fs.readFileSync(path.resolve(__dirname, "Spy vs Spy (Title Version).s"), "utf8");
    const build = await api.dev.assembleSource({ name: "Spy vs Spy (Title Version).s", text: source });
    if (!build.ok) throw new Error("Assembly failed: " + JSON.stringify(build.errors));
    console.log(`[SRC] Assembly ok — ${build.byteLength} bytes, runAddr=${hex(build.runAddr)}`);
    // Log segment coverage from build
    if (build.segments) {
      build.segments.forEach(s => console.log(`  seg: ${hex(s.start)}-${hex(s.end)} (${s.end - s.start + 1} bytes)`));
    }
    await api.dev.runXex({ build, resetOptions: { portB: 0xfe }, awaitEntry: false });
  }, path.resolve(__dirname, "cmp-src-30s.png"));
}

main().catch(err => { console.error(err && err.stack ? err.stack : String(err)); process.exitCode = 1; });
