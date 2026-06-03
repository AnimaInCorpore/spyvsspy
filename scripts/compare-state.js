"use strict";

const { assembleSource, buildBytes, hex, readBytes, runBuild, runXexBytes, withSpyAutomation } = require("./automation");

async function readState(api, label) {
  const dbg = (await api.getSystemState()).debugState;
  const reads = await Promise.all([
    api.debug.readMemory(0x0230), api.debug.readMemory(0x0231), // SDLIST
    api.debug.readMemory(0x11),   // $11 game state
    api.debug.readMemory(0x39),   // $39 serial recv flag
    api.debug.readMemory(0x0317), // VBI flag
    api.debug.readMemory(0xD20E), // POKEY IRQEN
    api.debug.readMemory(0xD20F), // POKEY IRQST
    api.debug.readMemory(0x0226), api.debug.readMemory(0x0227), // VVBLKI
    api.debug.readMemory(0xD301), // PORTB
    api.debug.readMemory(0x030F), // some timer/state
  ]);
  const [slo, shi, z11, z39, vbi, irqen, irqst, vvbkilo, vvbkihi, portb, t0f] = reads;
  const sdlist = slo | (shi << 8);
  const vvbki = vvbkilo | (vvbkihi << 8);
  console.log(`  [${label}] PC=${hex(dbg.pc)} SDLIST=${hex(sdlist)} $11=${hex(z11,2)} $39=${hex(z39,2)} VBI=$0317=${hex(vbi,2)} IRQEN=${hex(irqen,2)} IRQST=${hex(irqst,2)} VVBKI=${hex(vvbki)} PORTB=${hex(portb,2)} $030F=${hex(t0f,2)}`);
}

async function run(api, bytes, label, milestones) {
  console.log(`\n=== ${label} ===`);
  await runXexBytes(api, bytes, { resetOptions: { portB: 0xfe }, awaitEntry: false });
  let prev = 0;
  for (const ms of milestones) {
    await api.system.waitForTime({ ms: ms - prev, clock: "real" });
    await readState(api, `${ms}ms`);
    prev = ms;
  }
}

async function main() {
  const milestones = [1000, 1500, 2000, 2500, 3000, 4000, 5000];
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
