"use strict";

const { assembleSource, captureScreenshot, hex, runBuild, withSpyAutomation } = require("./automation");

async function main() {
  await withSpyAutomation({}, async (api) => {
    console.log("Assembling...");
    const build = await assembleSource(api);
    if (!build.ok) { console.error("Assembly failed:", build); process.exitCode = 1; return; }
    console.log(`Assembly ok — runAddr=${hex(build.runAddr)}`);

    await runBuild(api, build, { resetOptions: { portB: 0xfe }, awaitEntry: false });

    console.log("Waiting 3s for boot...");
    await api.system.waitForTime({ ms: 3000, clock: "real" });

    const sdlistLo = await api.debug.readMemory(0x0230);
    const sdlistHi = await api.debug.readMemory(0x0231);
    const sdlist = sdlistLo | (sdlistHi << 8);
    const dmactl = await api.debug.readMemory(0xD400);
    const colbk = await api.debug.readMemory(0xD01A);
    const colpf2 = await api.debug.readMemory(0xD018);
    console.log(`Display: DMACTL=${hex(dmactl,2)} SDLIST=${hex(sdlist)} COLBK=${hex(colbk,2)} COLPF2=${hex(colpf2,2)}`);

    const dl = await api.debug.readRange(sdlist, 32);
    console.log("DL bytes:", Array.from(dl).map((b) => hex(b,2)).join(" "));

    const beforeInput = await captureScreenshot(api, "spyvsspy-before-input.png");
    console.log(`Saved ${beforeInput.path}`);

    console.log("Pressing START...");
    await api.input.pressConsoleKey("start", { holdMs: 200, afterMs: 500 });

    await api.system.waitForTime({ ms: 3000, clock: "real" });
    const afterStart = await captureScreenshot(api, "spyvsspy-after-start.png");
    console.log(`Saved ${afterStart.path}`);

    console.log("Pressing fire button...");
    await api.input.setJoystick({ trigger: true });
    await api.system.waitForTime({ ms: 300, clock: "real" });
    await api.input.setJoystick({ trigger: false });
    await api.system.waitForTime({ ms: 3000, clock: "real" });

    const afterFire = await captureScreenshot(api, "spyvsspy-after-fire.png");
    console.log(`Saved ${afterFire.path}`);

    const dbg = (await api.getSystemState()).debugState;
    const sdlist2Lo = await api.debug.readMemory(0x0230);
    const sdlist2Hi = await api.debug.readMemory(0x0231);
    const sdlist2 = sdlist2Lo | (sdlist2Hi << 8);
    console.log(`Final PC=${hex(dbg.pc)} SDLIST=${hex(sdlist2)}`);
  });
}

main().catch((err) => { console.error(err && err.stack ? err.stack : String(err)); process.exitCode = 1; });
