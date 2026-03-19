"use strict";

const { buildBytes, hex, readBytes, readText, withSpyAutomation } = require("./automation");

function parseXex(buf) {
  const segments = [];
  let i = 0;
  if (buf[0] === 0xFF && buf[1] === 0xFF) i = 2;
  while (i + 3 < buf.length) {
    const start = buf[i] | (buf[i + 1] << 8);
    const end = buf[i + 2] | (buf[i + 3] << 8);
    i += 4;
    if (start === 0xFFFF) {
      i -= 2;
      continue;
    }
    const len = end - start + 1;
    if (len <= 0 || i + len > buf.length) break;
    segments.push({
      start: start,
      end: end,
      len: len,
      preview: Array.from(buf.slice(i, i + 8)).map((b) => hex(b, 2)).join(" "),
    });
    i += len;
  }
  return segments;
}

async function main() {
  const xexBuf = readBytes("Spy vs Spy (Title Version).xex");
  const xexSegs = parseXex(xexBuf);
  console.log(`=== Original XEX (${xexBuf.length} bytes, ${xexSegs.length} segments) ===`);
  xexSegs.forEach((s) => console.log(`  $${hex(s.start)}-$${hex(s.end)} (${s.len} bytes)  [${s.preview}]`));

  await withSpyAutomation({ optionOnStart: true }, async (api) => {
    const source = readText("Spy vs Spy (Title Version).s");
    const build = await api.dev.assembleSource({ name: "Spy vs Spy (Title Version).s", text: source });
    if (!build.ok) {
      console.error("Assembly failed:", build);
      process.exitCode = 1;
      return;
    }

    const srcBuf = buildBytes(build);
    const srcSegs = parseXex(srcBuf);
    console.log(`\n=== Assembled Source (${srcBuf.length} bytes, ${srcSegs.length} segments) ===`);
    srcSegs.forEach((s) => console.log(`  $${hex(s.start)}-$${hex(s.end)} (${s.len} bytes)  [${s.preview}]`));

    console.log("\n=== In XEX but NOT in SRC (missing/different start addresses) ===");
    const srcStarts = new Set(srcSegs.map((s) => s.start));
    xexSegs
      .filter((s) => !srcStarts.has(s.start))
      .forEach((s) => console.log(`  MISSING: $${hex(s.start)}-$${hex(s.end)} (${s.len} bytes)`));

    const xex7f = xexSegs.find((s) => s.start <= 0x7F00 && s.end >= 0x7F00);
    const src7f = srcSegs.find((s) => s.start <= 0x7F00 && s.end >= 0x7F00);
    console.log(`\n$7F00 in XEX: ${xex7f ? `$${hex(xex7f.start)}-$${hex(xex7f.end)} [${xex7f.preview}]` : "NOT FOUND"}`);
    console.log(`$7F00 in SRC: ${src7f ? `$${hex(src7f.start)}-$${hex(src7f.end)} [${src7f.preview}]` : "NOT FOUND"}`);
  });
}

main().catch((err) => {
  console.error(err && err.stack ? err.stack : String(err));
  process.exitCode = 1;
});
