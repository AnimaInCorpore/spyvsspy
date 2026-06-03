"use strict";

/**
 * Captures SIO streaming data from the original XEX by:
 * 1. Parsing the XEX segments to find missing code ($EB87-$ECAE)
 * 2. Running the original XEX in jsA8E and waiting for the SIO streaming to
 *    complete, then dumping the populated memory region.
 */

const fs = require("node:fs");
const path = require("node:path");
const { withSpyAutomation, readBytes, playgroundPath, writePlaygroundFile, hex } = require("./automation");

const XEX_PATH = path.resolve(__dirname, "..", "Spy vs Spy (Title Version).xex");

// Parse the XEX file and build a memory image of all segments.
function parseXex(data) {
  const buf = Buffer.isBuffer(data) ? data : Buffer.from(data);
  let pos = 0;
  const segments = [];
  const image = new Uint8Array(0x10000);

  // Skip the $FFFF header (and any additional $FFFF markers between segments)
  if (buf[0] === 0xff && buf[1] === 0xff) pos = 2;

  while (pos < buf.length - 3) {
    // Allow $FFFF repeat markers between segments
    while (pos + 1 < buf.length && buf[pos] === 0xff && buf[pos + 1] === 0xff) {
      pos += 2;
    }
    if (pos + 3 >= buf.length) break;

    const start = buf[pos] | (buf[pos + 1] << 8);
    const end   = buf[pos + 2] | (buf[pos + 3] << 8);
    pos += 4;

    // Special: INITAD=$02E2 and RUNAD=$02E0 are 2-byte segments
    if (start > end) {
      // Malformed — skip
      break;
    }
    const length = end - start + 1;
    if (pos + length > buf.length) break;

    const bytes = buf.slice(pos, pos + length);
    pos += length;

    segments.push({ start, end, length, bytes });
    for (let i = 0; i < length; i++) {
      image[start + i] = bytes[i];
    }
  }

  return { segments, image };
}

function formatHexDump(bytes, baseAddr, bytesPerRow) {
  const bpr = bytesPerRow || 16;
  const lines = [];
  for (let i = 0; i < bytes.length; i += bpr) {
    const addr = baseAddr + i;
    const chunk = Array.from(bytes.slice(i, Math.min(i + bpr, bytes.length)));
    const hex16 = chunk.map(b => b.toString(16).toUpperCase().padStart(2, "0")).join(" ");
    lines.push(`$${addr.toString(16).toUpperCase().padStart(4, "0")}: ${hex16}`);
  }
  return lines.join("\n");
}

function bytesToAtasmSource(bytes, baseAddr, label) {
  const lines = [`.ORG $${baseAddr.toString(16).toUpperCase()}`];
  if (label) lines.push(`${label}:`);
  for (let i = 0; i < bytes.length; i += 16) {
    const chunk = Array.from(bytes.slice(i, Math.min(i + 16, bytes.length)));
    lines.push("    .BYTE " + chunk.map(b => "$" + b.toString(16).toUpperCase().padStart(2, "0")).join(", "));
  }
  return lines.join("\n") + "\n";
}

async function main() {
  const xexData = readBytes(XEX_PATH);
  const { segments, image } = parseXex(xexData);

  console.log(`XEX: ${segments.length} segments, ${xexData.length} bytes total`);
  for (const seg of segments) {
    console.log(`  $${seg.start.toString(16).toUpperCase().padStart(4,"0")}-$${seg.end.toString(16).toUpperCase().padStart(4,"0")} (${seg.length} bytes)`);
  }

  // --- Part 1: Extract missing code $EB87-$ECAE ---
  const missingStart = 0xEB87;
  const missingEnd   = 0xECAE;
  const missingLen   = missingEnd - missingStart + 1;
  const missingBytes = image.slice(missingStart, missingEnd + 1);

  console.log(`\n--- Missing code $EB87-$ECAE (${missingLen} bytes) ---`);
  console.log(formatHexDump(missingBytes, missingStart));

  const missingSource = bytesToAtasmSource(missingBytes, missingStart, "SIOSetupBlock");
  const missingSourcePath = writePlaygroundFile("EB87.s", missingSource);
  console.log(`\nWrote source stub: ${missingSourcePath}`);

  // Find specific subroutines: EC17, EC40, EC84
  for (const addr of [0xEC17, 0xEC40, 0xEC84]) {
    if (addr >= missingStart && addr <= missingEnd) {
      const offset = addr - missingStart;
      console.log(`  $${addr.toString(16).toUpperCase()} byte[0]=$${missingBytes[offset].toString(16).toUpperCase().padStart(2,"0")}`);
    }
  }

  // --- Part 2: Run original XEX and capture streamed memory ---
  console.log("\n--- Running original XEX to capture SIO-streamed data ---");

  await withSpyAutomation({ turbo: true, frameDelayMs: 0 }, async (api) => {
    const xexBytes = readBytes(XEX_PATH);

    // Mount and run the original XEX
    await api.dev.runXex({
      bytes: xexBytes,
      awaitEntry: false,
      resetOptions: { portB: 0xfe },
    });

    console.log("XEX loaded, waiting for SIO streaming (target: $9F50=$48)...");

    // Wait for $9F50 to become $48 (first byte of DLI handler) with 15s timeout
    const waitResult = await api.debug.waitForMemory({
      address: 0x9F50,
      predicate: v => v === 0x48,
      timeoutMs: 15000,
      pollIntervalMs: 50,
    });

    if (waitResult && waitResult.error) {
      console.error("Timeout: $9F50 never became $48");
      console.log(`Current $9F50 = $${(await api.debug.readMemory(0x9F50)).toString(16).toUpperCase()}`);
      return;
    }

    console.log("$9F50=$48 confirmed — SIO stream started. Waiting 2s more for full stream...");
    await api.system.waitForTime({ ms: 2000, clock: "real" });

    // Read the SIO buffer pointers to understand the full range
    const ptr32 = await api.debug.readMemory(0x32);
    const ptr33 = await api.debug.readMemory(0x33);
    const ptr34 = await api.debug.readMemory(0x34);
    const ptr35 = await api.debug.readMemory(0x35);
    const bufEnd = ptr32 | (ptr33 << 8);
    const endPtr = ptr34 | (ptr35 << 8);
    console.log(`SIO buffer ptrs: $32/$33=${hex(bufEnd)} $34/$35=${hex(endPtr)}`);

    // Dump the $9F50-$9FFF region (DLI handler + any adjacent data)
    const dliStart = 0x9F50;
    const dliEnd   = 0x9FFF;
    const dliBytes = await api.debug.readRange(dliStart, dliEnd - dliStart + 1);
    console.log(`\n--- $9F50-$9FFF after SIO stream ---`);
    console.log(formatHexDump(dliBytes, dliStart));

    // Write the DLI region as source
    const dliSource = bytesToAtasmSource(dliBytes, dliStart, "StreamedDLIHandler");
    const dliSourcePath = writePlaygroundFile("9F50-streamed.s", dliSource);
    console.log(`Wrote: ${dliSourcePath}`);

    // Also dump surrounding area to catch animation/sound data
    // The game likely streams more than just the DLI handler
    // Check $9E00-$9F4F and $A000+ for any data that changed
    const wideStart = 0x9E00;
    const wideEnd   = 0x9FFF;
    const wideBytes = await api.debug.readRange(wideStart, wideEnd - wideStart + 1);
    const wideSource = bytesToAtasmSource(wideBytes, wideStart, "StreamedRegion9E00");
    writePlaygroundFile("9E00-streamed.s", wideSource);
    console.log(`Wrote: ${playgroundPath("9E00-streamed.s")}`);

    // Get current machine state
    const state = await api.getSystemState();
    const dbg = state.debugState;
    const sdlistLo = await api.debug.readMemory(0x0230);
    const sdlistHi = await api.debug.readMemory(0x0231);
    const sdlist = sdlistLo | (sdlistHi << 8);
    const vdslst = (await api.debug.readMemory(0x0200)) | ((await api.debug.readMemory(0x0201)) << 8);
    console.log(`\nMachine state: PC=${hex(dbg.pc)} SDLIST=${hex(sdlist)} VDSLST=${hex(vdslst)}`);

    // Check value at $9F50 to confirm it's populated
    const byte9f50 = await api.debug.readMemory(0x9F50);
    const byte9f51 = await api.debug.readMemory(0x9F51);
    console.log(`$9F50=$${byte9f50.toString(16).toUpperCase()} $9F51=$${byte9f51.toString(16).toUpperCase()}`);
  });

  console.log("\nDone.");
}

main().catch(err => {
  console.error(err && err.stack ? err.stack : String(err));
  process.exitCode = 1;
});
