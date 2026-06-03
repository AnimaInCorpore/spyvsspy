"use strict";

/**
 * Runs BOTH the original XEX and the source-assembled XEX in jsA8E,
 * comparing their machine state at key checkpoints.
 * Focus: $9F50, SDLIST, VDSLST, PC, and SIO state.
 */

const path = require("node:path");
const { withSpyAutomation, assembleSource, runBuild, runXexBytes, readBytes, writePlaygroundFile, hex } = require("./automation");

function formatBytes(arr, base) {
  const lines = [];
  for (let i = 0; i < arr.length; i += 16) {
    const addr = base + i;
    const chunk = Array.from(arr.slice(i, Math.min(i + 16, arr.length)));
    const h = chunk.map(b => b.toString(16).toUpperCase().padStart(2, "0")).join(" ");
    lines.push(`$${addr.toString(16).toUpperCase().padStart(4,"0")}: ${h}`);
  }
  return lines.join("\n");
}

async function captureState(api, label, timeoutMs) {
  const dbg = (await api.getSystemState()).debugState;
  const sdlistLo = await api.debug.readMemory(0x0230);
  const sdlistHi = await api.debug.readMemory(0x0231);
  const sdlist = sdlistLo | (sdlistHi << 8);
  const vdslstLo = await api.debug.readMemory(0x0200);
  const vdslstHi = await api.debug.readMemory(0x0201);
  const vdslst = vdslstLo | (vdslstHi << 8);
  const initadLo = await api.debug.readMemory(0x02E2);
  const initadHi = await api.debug.readMemory(0x02E3);
  const initad = initadLo | (initadHi << 8);
  const runadLo = await api.debug.readMemory(0x02E0);
  const runadHi = await api.debug.readMemory(0x02E1);
  const runad = runadLo | (runadHi << 8);
  const byte9f50 = await api.debug.readMemory(0x9F50);
  const portb = await api.debug.readMemory(0xD301);
  const p39 = await api.debug.readMemory(0x39);
  const p17 = await api.debug.readMemory(0x17);
  const p30 = await api.debug.readMemory(0x30);

  console.log(`\n=== ${label} ===`);
  console.log(`PC=${hex(dbg.pc)} SP=${hex(dbg.sp,2)} A=${hex(dbg.a,2)} X=${hex(dbg.x,2)} Y=${hex(dbg.y,2)}`);
  console.log(`SDLIST=${hex(sdlist)} VDSLST=${hex(vdslst)} PORTB=${hex(portb,2)}`);
  console.log(`$9F50=${hex(byte9f50,2)} $39=${hex(p39,2)} $17=${hex(p17,2)} $30=${hex(p30,2)}`);
  console.log(`INITAD=${hex(initad)} RUNAD=${hex(runad)}`);
  return { pc: dbg.pc, sdlist, vdslst, byte9f50, portb, p39, p30, initad, runad };
}

async function runDiag(api, label, runFn) {
  console.log(`\n${"=".repeat(60)}`);
  console.log(`RUNNING: ${label}`);
  console.log(`${"=".repeat(60)}`);

  await runFn(api);

  // State right after launch
  await captureState(api, `${label} @ t=0`);

  // Wait 1s then check
  await api.system.waitForTime({ ms: 1000, clock: "real" });
  await captureState(api, `${label} @ t=1s`);

  // Wait for $9F50 to become $48 (DLI handler loaded) or timeout
  const waitResult = await api.debug.waitForMemory({
    address: 0x9F50,
    predicate: v => v === 0x48,
    timeoutMs: 8000,
    pollIntervalMs: 100,
  });

  if (waitResult && waitResult.error) {
    const state = await captureState(api, `${label} @ timeout (9F50 never $48)`);
    const range9f = await api.debug.readRange(0x9F50, 96);
    console.log("$9F50 region:\n" + formatBytes(range9f, 0x9F50));
    return state;
  }

  const tState = await captureState(api, `${label} @ 9F50=$48`);

  // Wait for SDLIST to change from $0000 / default to something interesting
  await api.system.waitForTime({ ms: 1000, clock: "real" });
  const finalState = await captureState(api, `${label} @ +1s after 9F50`);

  // Dump key memory regions
  const range9f = await api.debug.readRange(0x9F50, 96);
  console.log("$9F50 region:\n" + formatBytes(range9f, 0x9F50));

  // SIO-related ZP
  const sioZp = await api.debug.readRange(0x32, 6);
  console.log(`SIO ZP $32-$37: ${Array.from(sioZp).map(b=>hex(b,2)).join(" ")}`);

  return finalState;
}

async function main() {
  // ---- Test 1: original XEX ----
  await withSpyAutomation({ turbo: true, frameDelayMs: 0 }, async (api) => {
    await runDiag(api, "ORIGINAL XEX", async (api) => {
      const xexBytes = readBytes(require("./automation").XEX_PATH);
      await api.dev.runXex({
        bytes: xexBytes,
        awaitEntry: false,
        resetOptions: { portB: 0xfe },
      });
    });
  });

  // ---- Test 2: source XEX ----
  await withSpyAutomation({ turbo: true, frameDelayMs: 0 }, async (api) => {
    await runDiag(api, "SOURCE XEX", async (api) => {
      console.log("Assembling source...");
      const build = await assembleSource(api);
      if (!build.ok) {
        console.error("Assembly FAILED:", JSON.stringify(build.errors || build, null, 2));
        throw new Error("Assembly failed");
      }
      console.log(`Assembly ok — runAddr=${hex(build.runAddr)} size=${build.byteLength} bytes`);
      await runBuild(api, build, { awaitEntry: false });
    });
  });
}

main().catch(err => {
  console.error(err && err.stack ? err.stack : String(err));
  process.exitCode = 1;
});
