"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { hex, readBytes, withSpyAutomation, runXexBytes, playgroundPath } = require("./automation");

async function main() {
  const xexBuf = readBytes("Spy vs Spy (Title Version).xex");

  await withSpyAutomation({}, async (api) => {
    console.log("Loading original XEX...");
    await runXexBytes(api, xexBuf, { resetOptions: { portB: 0xfe }, awaitEntry: false });

    console.log("Waiting 5s for loader to finish...");
    await api.system.waitForTime({ ms: 5000, clock: "real" });

    const dbg = (await api.getSystemState()).debugState;
    console.log(`PC=${hex(dbg.pc)} SP=${hex(dbg.sp, 2)} A=${hex(dbg.a, 2)} X=${hex(dbg.x, 2)} Y=${hex(dbg.y, 2)}`);

    const sdlistLo = await api.debug.readMemory(0x0230);
    const sdlistHi = await api.debug.readMemory(0x0231);
    console.log(`SDLIST=${hex(sdlistLo | (sdlistHi << 8))}`);

    // Dump $C000-$C28F (the undiscovered upper-bank area)
    const SIZE = 0xC290 - 0xC000;
    const region = await api.debug.readRange(0xC000, SIZE);
    const bytes = Array.from(region);

    // Print in hex rows of 16
    console.log(`\n=== $C000-$C28F (${SIZE} bytes) ===`);
    for (let r = 0; r * 16 < SIZE; r++) {
      const addr = 0xC000 + r * 16;
      const row = bytes.slice(r * 16, r * 16 + 16).map((b) => b.toString(16).toUpperCase().padStart(2, "0")).join(" ");
      console.log(`$${addr.toString(16).toUpperCase()}: ${row}`);
    }

    // Also save as binary for verification
    const outPath = playgroundPath("c000-c28f-original.bin");
    fs.writeFileSync(outPath, Buffer.from(bytes));
    console.log(`\nSaved binary to ${outPath}`);

    // Also dump vectors at $FFFA-$FFFF
    const vec = await api.debug.readRange(0xFFFA, 6);
    console.log(`\nVectors: NMI=${hex(vec[0]|(vec[1]<<8))} RESET=${hex(vec[2]|(vec[3]<<8))} IRQ=${hex(vec[4]|(vec[5]<<8))}`);
  });
}

main().catch((err) => { console.error(err && err.stack ? err.stack : String(err)); process.exitCode = 1; });
