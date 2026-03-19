"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { createHeadlessAutomation } = require("./A8E/jsA8E/headless");

function hex(n, w) { return n.toString(16).toUpperCase().padStart(w || 4, "0"); }

// Parse XEX segments including INITAD tracking
function parseXexFull(buf) {
  const segments = [];
  let i = 0;
  if (buf[0] === 0xFF && buf[1] === 0xFF) i = 2;
  while (i + 3 < buf.length) {
    const lo = buf[i]; const hi = buf[i+1];
    if (lo === 0xFF && hi === 0xFF) { i += 2; continue; }
    const start = lo | (hi << 8);
    const end   = buf[i+2] | (buf[i+3] << 8);
    i += 4;
    const len = end - start + 1;
    if (len <= 0 || i + len > buf.length) break;
    const bytes = Array.from(buf.slice(i, i + Math.min(len, 8))).map(b => hex(b, 2)).join(" ");
    segments.push({ start, end, len, bytes });
    i += len;
  }
  return segments;
}

function findOverlaps(segments, lo, hi) {
  return segments.filter(s => s.start <= hi && s.end >= lo);
}

async function main() {
  const runtime = await createHeadlessAutomation({
    cwd: __dirname,
    roms: { os: path.resolve(__dirname, "ATARIXL.ROM"), basic: path.resolve(__dirname, "ATARIBAS.ROM") },
    turbo: true, frameDelayMs: 0, optionOnStart: true,
  });

  try {
    const api = runtime.api;
    const source = fs.readFileSync(path.resolve(__dirname, "Spy vs Spy (Title Version).s"), "utf8");
    const build = await api.dev.assembleSource({ name: "Spy vs Spy (Title Version).s", text: source });
    if (!build.ok) throw new Error("Assembly failed");

    let srcBuf;
    if (build.bytes) srcBuf = Buffer.from(build.bytes);
    else if (build.base64) srcBuf = Buffer.from(build.base64, "base64");

    const segments = parseXexFull(srcBuf);
    console.log(`Assembled XEX: ${srcBuf.length} bytes, ${segments.length} segments`);

    // Find all segments overlapping $AC00-$ACFF
    const ac00segs = findOverlaps(segments, 0xAC00, 0xACFF);
    console.log(`\nSegments covering $AC00-$ACFF (${ac00segs.length}):`);
    ac00segs.forEach(s => {
      const off = Math.max(0, 0xAC00 - s.start);
      const pos = segments.indexOf(s);
      console.log(`  [seg ${pos}] $${hex(s.start)}-$${hex(s.end)} (${s.len} bytes)  @AC00+: ${s.bytes}`);
    });

    // Find all INITAD segments ($02E2) and what follows
    console.log("\nINITAD segments ($02E2) in order:");
    segments.forEach((s, i) => {
      if (s.start === 0x02E2) {
        const initAddr = (s.start === 0x02E2 && srcBuf) ?
          // compute actual initad value from segment position in buffer
          s.bytes.split(" ").slice(0, 2).join(" ") : "?";
        console.log(`  [seg ${i}] INITAD bytes: ${s.bytes.split(" ").slice(0,2).join(" ")}`);
      }
    });

    // Also check $7F00 segment
    const seg7f = findOverlaps(segments, 0x7F00, 0x7F1A);
    console.log("\n$7F00 segments:");
    seg7f.forEach(s => console.log(`  $${hex(s.start)}-$${hex(s.end)}: ${s.bytes}`));

    // Run and check memory immediately after boot
    await api.dev.runXex({ build, resetOptions: { portB: 0xfe }, awaitEntry: false });
    // Very short wait — just enough for loader to finish
    await api.system.waitForTime({ ms: 1000, clock: "real" });

    const ac00 = await api.debug.readRange(0xAC00, 16);
    console.log(`\n$AC00 after 1s: ${Array.from(ac00).map(b => hex(b,2)).join(" ")}`);
    const mem7f = await api.debug.readRange(0x7F00, 4);
    console.log(`$7F00 after 1s: ${Array.from(mem7f).map(b => hex(b,2)).join(" ")}`);

    // Check if it looks like the AC00 block was loaded by checking a byte we know
    // src/AC00.s starts with $DD $DD $DD...
    const expected = [0xDD, 0xDD, 0xDD, 0xDD];
    const got = Array.from(ac00.slice(0, 4));
    console.log(`$AC00 expected: ${expected.map(b => hex(b,2)).join(" ")}  match: ${JSON.stringify(got) === JSON.stringify(expected)}`);

  } finally {
    await runtime.dispose();
  }
}

main().catch(err => { console.error(err && err.stack ? err.stack : String(err)); process.exitCode = 1; });
