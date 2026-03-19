"use strict";

const { captureScreenshot, hex, readBytes, readText, runBuild, runXexBytes, withSpyAutomation } = require("./automation");

async function snapshot(label, api) {
  const dbg = (await api.getSystemState()).debugState;
  const sdlistLo = await api.debug.readMemory(0x0230);
  const sdlistHi = await api.debug.readMemory(0x0231);
  const sdlist = sdlistLo | (sdlistHi << 8);
  const portb = await api.debug.readMemory(0xD301);

  const acaa = await api.debug.readRange(0xAC00, 16);
  const acaaData = Array.from(acaa).map((b) => hex(b, 2)).join(" ");

  const mem7f00 = await api.debug.readRange(0x7F00, 8);
  const mem7f00Data = Array.from(mem7f00).map((b) => hex(b, 2)).join(" ");

  console.log(`[${label}] PC=${hex(dbg.pc)} PORTB=${hex(portb, 2)} SDLIST=${hex(sdlist)}`);
  console.log(`[${label}] $AC00: ${acaaData}`);
  console.log(`[${label}] $7F00: ${mem7f00Data}`);
}

async function run(label, launchFn, outFile) {
  await withSpyAutomation({ optionOnStart: true }, async (api) => {
    await launchFn(api);

    await api.system.waitForTime({ ms: 500, clock: "real" });
    await snapshot(label + "@0.5s", api);

    await api.system.waitForTime({ ms: 4500, clock: "real" });
    await snapshot(label + "@5s", api);

    await api.system.waitForTime({ ms: 25000, clock: "real" });
    await snapshot(label + "@30s", api);

    const shot = await captureScreenshot(api, outFile);
    console.log(`[${label}] Screenshot: ${shot.path}`);
  });
}

async function main() {
  await run("XEX", async (api) => {
    const xex = readBytes("Spy vs Spy (Title Version).xex");
    await runXexBytes(api, xex, { resetOptions: { portB: 0xfe }, awaitEntry: false });
  }, "cmp-xex-30s.png");

  await run("SRC", async (api) => {
    const source = readText("Spy vs Spy (Title Version).s");
    const build = await api.dev.assembleSource({ name: "Spy vs Spy (Title Version).s", text: source });
    if (!build.ok) throw new Error("Assembly failed: " + JSON.stringify(build.errors));
    console.log(`[SRC] Assembly ok — ${build.byteLength} bytes, runAddr=${hex(build.runAddr)}`);
    if (build.segments) {
      build.segments.forEach((s) => console.log(`  seg: ${hex(s.start)}-${hex(s.end)} (${s.end - s.start + 1} bytes)`));
    }
    await runBuild(api, build, { resetOptions: { portB: 0xfe }, awaitEntry: false });
  }, "cmp-src-30s.png");
}

main().catch((err) => {
  console.error(err && err.stack ? err.stack : String(err));
  process.exitCode = 1;
});
