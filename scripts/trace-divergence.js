"use strict";

const { assembleSource, buildBytes, hex, readBytes, runBuild, runXexBytes, withSpyAutomation } = require("./automation");

async function snapshot(api, label) {
  const dbg = (await api.getSystemState()).debugState;
  const sdlistLo = await api.debug.readMemory(0x0230);
  const sdlistHi = await api.debug.readMemory(0x0231);
  const sdlist = sdlistLo | (sdlistHi << 8);
  const portb = await api.debug.readMemory(0xD301);
  console.log(`  [${label}] PC=${hex(dbg.pc)} SDLIST=${hex(sdlist)} PORTB=${hex(portb, 2)} A=${hex(dbg.a, 2)} X=${hex(dbg.x, 2)} Y=${hex(dbg.y, 2)}`);
  return { pc: dbg.pc, sdlist };
}

async function run(api, bytes, label, milestones) {
  console.log(`\n=== ${label} ===`);
  await runXexBytes(api, bytes, { resetOptions: { portB: 0xfe }, awaitEntry: false });
  let prev = 0;
  for (const ms of milestones) {
    await api.system.waitForTime({ ms: ms - prev, clock: "real" });
    await snapshot(api, `${ms}ms`);
    prev = ms;
  }
}

async function main() {
  const milestones = [500, 1000, 2000, 3000, 5000, 10000, 20000, 30000];
  const origBytes = readBytes("Spy vs Spy (Title Version).xex");

  await withSpyAutomation({}, async (api) => {
    await run(api, origBytes, "ORIGINAL XEX", milestones);
  });

  await withSpyAutomation({}, async (api) => {
    console.log("\nAssembling source...");
    const build = await assembleSource(api);
    if (!build.ok) { console.error("Assembly failed:", build.errors); process.exitCode = 1; return; }
    const srcBytes = buildBytes(build);
    await run(api, srcBytes, "SOURCE XEX", milestones);
  });
}

main().catch((err) => { console.error(err && err.stack ? err.stack : String(err)); process.exitCode = 1; });
