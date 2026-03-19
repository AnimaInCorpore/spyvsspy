"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { createHeadlessAutomation } = require("./A8E/jsA8E/headless");

function hex(n, w) { return n.toString(16).toUpperCase().padStart(w || 4, "0"); }

// Parse raw XEX bytes and return segment list
function parseXex(buf) {
  const segments = [];
  let i = 0;
  if (buf[0] === 0xFF && buf[1] === 0xFF) i = 2; // skip header
  while (i + 3 < buf.length) {
    const start = buf[i] | (buf[i+1] << 8);
    const end   = buf[i+2] | (buf[i+3] << 8);
    i += 4;
    if (start === 0xFFFF) { i -= 2; continue; } // repeat header
    const len = end - start + 1;
    if (len <= 0 || i + len > buf.length) break;
    segments.push({ start, end, len, preview: Array.from(buf.slice(i, i+8)).map(b => hex(b,2)).join(" ") });
    i += len;
  }
  return segments;
}

async function main() {
  // --- Parse original XEX ---
  const xexBuf = fs.readFileSync(path.resolve(__dirname, "Spy vs Spy (Title Version).xex"));
  const xexSegs = parseXex(xexBuf);
  console.log(`=== Original XEX (${xexBuf.length} bytes, ${xexSegs.length} segments) ===`);
  xexSegs.forEach(s => console.log(`  $${hex(s.start)}-$${hex(s.end)} (${s.len} bytes)  [${s.preview}]`));

  // --- Assemble source and parse result ---
  const runtime = await createHeadlessAutomation({
    cwd: __dirname,
    roms: { os: path.resolve(__dirname, "ATARIXL.ROM"), basic: path.resolve(__dirname, "ATARIBAS.ROM") },
    turbo: true,
    frameDelayMs: 0,
    optionOnStart: true,
  });
  try {
    const api = runtime.api;
    const source = fs.readFileSync(path.resolve(__dirname, "Spy vs Spy (Title Version).s"), "utf8");
    const build = await api.dev.assembleSource({ name: "Spy vs Spy (Title Version).s", text: source });
    if (!build.ok) { console.error("Assembly failed:", build); process.exitCode = 1; return; }

    // Get raw bytes
    let srcBuf;
    if (build.bytes) srcBuf = Buffer.from(build.bytes);
    else if (build.base64) srcBuf = Buffer.from(build.base64, "base64");
    else { console.error("No bytes in build result"); process.exitCode = 1; return; }

    const srcSegs = parseXex(srcBuf);
    console.log(`\n=== Assembled Source (${srcBuf.length} bytes, ${srcSegs.length} segments) ===`);
    srcSegs.forEach(s => console.log(`  $${hex(s.start)}-$${hex(s.end)} (${s.len} bytes)  [${s.preview}]`));

    // Show segments present in XEX but missing in SRC
    console.log("\n=== In XEX but NOT in SRC (missing/different start addresses) ===");
    const srcStarts = new Set(srcSegs.map(s => s.start));
    xexSegs.filter(s => !srcStarts.has(s.start))
      .forEach(s => console.log(`  MISSING: $${hex(s.start)}-$${hex(s.end)} (${s.len} bytes)`));

    // Compare $7F00 region specifically
    const xex7f = xexSegs.find(s => s.start <= 0x7F00 && s.end >= 0x7F00);
    const src7f = srcSegs.find(s => s.start <= 0x7F00 && s.end >= 0x7F00);
    console.log(`\n$7F00 in XEX: ${xex7f ? `$${hex(xex7f.start)}-$${hex(xex7f.end)} [${xex7f.preview}]` : "NOT FOUND"}`);
    console.log(`$7F00 in SRC: ${src7f ? `$${hex(src7f.start)}-$${hex(src7f.end)} [${src7f.preview}]` : "NOT FOUND"}`);
  } finally {
    await runtime.dispose();
  }
}

main().catch(err => { console.error(err && err.stack ? err.stack : String(err)); process.exitCode = 1; });
