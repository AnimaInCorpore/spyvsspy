"use strict";

const { assembleSource, captureScreenshot, hex, runBuild, withSpyAutomation } = require("./automation");

async function main() {
  await withSpyAutomation({ optionOnStart: true }, async (api) => {
    console.log("Assembling source...");
    const build = await assembleSource(api);

    if (!build.ok) {
      console.error("Assembly failed:", build.errors || build);
      process.exitCode = 1;
      return;
    }
    console.log(`Assembly ok — ${build.byteLength} bytes, runAddr=${hex(build.runAddr)}`);

    console.log("Launching XEX (portB=0xFE, awaitEntry=false)...");
    const result = await runBuild(api, build, {
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
    const shot = await captureScreenshot(api, "spyvsspy-source-gameplay-shot.png");
    console.log(`Screenshot saved to ${shot.path} (${shot.width}x${shot.height})`);

    if (state.debugState && state.debugState.fault) {
      console.error("Emulation fault detected:", state.debugState.fault);
      process.exitCode = 1;
    }
  });
}

main().catch((err) => {
  console.error(err && err.stack ? err.stack : String(err));
  process.exitCode = 1;
});
