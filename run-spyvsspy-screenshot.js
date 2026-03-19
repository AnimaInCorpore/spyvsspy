"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { createHeadlessAutomation } = require("./A8E/jsA8E/headless");

const playgroundDir = path.resolve(__dirname, "playground");
fs.mkdirSync(playgroundDir, { recursive: true });

async function main() {
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

    const sourcePath = path.resolve(__dirname, "Spy vs Spy (Title Version).s");
    console.log("Assembling source...");
    const source = fs.readFileSync(sourcePath, "utf8");
    const build = await api.dev.assembleSource({
      name: path.basename(sourcePath),
      text: source,
    });

    if (!build.ok) {
      console.error("Assembly failed:", build.errors || build);
      process.exitCode = 1;
      return;
    }
    console.log(`Assembly ok — ${build.byteLength} bytes, runAddr=$${build.runAddr.toString(16).toUpperCase()}`);

    console.log("Launching XEX (portB=0xFE, awaitEntry=false)...");
    const result = await api.dev.runXex({
      build,
      resetOptions: { portB: 0xfe },
      awaitEntry: false,
    });
    console.log("runXex result:", {
      ok: result.ok,
      phase: result.phase,
      started: result.started,
    });

    // Wait for the game to boot and reach gameplay
    console.log("Waiting for game to reach gameplay (~30s real)...");
    await api.system.waitForTime({ ms: 30000, clock: "real" });

    const state = await api.getSystemState();
    console.log("System state:", {
      running: state.running,
      pc: "0x" + state.debugState.pc.toString(16).toUpperCase(),
    });

    console.log("Capturing screenshot...");
    const screenshot = await api.artifacts.captureScreenshot({ encoding: "bytes" });

    const outPath = path.join(playgroundDir, "spyvsspy-source-gameplay-shot.png");
    fs.writeFileSync(outPath, Buffer.from(screenshot.bytes));
    console.log(`Screenshot saved to ${outPath} (${screenshot.width}x${screenshot.height})`);

    if (state.debugState && state.debugState.fault) {
      console.error("Emulation fault detected:", state.debugState.fault);
      process.exitCode = 1;
    }
  } finally {
    await runtime.dispose();
  }
}

main().catch((err) => {
  console.error(err && err.stack ? err.stack : String(err));
  process.exitCode = 1;
});
