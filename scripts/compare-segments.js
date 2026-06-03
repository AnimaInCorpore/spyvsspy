"use strict";

/**
 * Compares the segment layout of the original XEX vs the assembled source XEX.
 * Highlights differences in segment order, content, and addresses.
 */

const path = require("node:path");
const { withSpyAutomation, assembleSource, readBytes, buildBytes, writePlaygroundFile, hex } = require("./automation");

function parseXex(data) {
  const buf = Buffer.isBuffer(data) ? data : Buffer.from(data);
  let pos = 0;
  const segments = [];
  const image = new Uint8Array(0x10000);

  if (buf[0] === 0xff && buf[1] === 0xff) pos = 2;

  while (pos < buf.length - 3) {
    while (pos + 1 < buf.length && buf[pos] === 0xff && buf[pos + 1] === 0xff) pos += 2;
    if (pos + 3 >= buf.length) break;

    const start = buf[pos] | (buf[pos + 1] << 8);
    const end   = buf[pos + 2] | (buf[pos + 3] << 8);
    pos += 4;
    if (start > end) break;

    const length = end - start + 1;
    if (pos + length > buf.length) break;

    const bytes = buf.slice(pos, pos + length);
    pos += length;

    segments.push({ start, end, length, bytes });
    for (let i = 0; i < length; i++) image[start + i] = bytes[i];
  }

  return { segments, image };
}

function findDiffs(origImage, srcImage, start, end) {
  const diffs = [];
  for (let a = start; a <= end; a++) {
    if (origImage[a] !== srcImage[a]) {
      diffs.push({ addr: a, orig: origImage[a], src: srcImage[a] });
    }
  }
  return diffs;
}

function hexByte(b) { return b.toString(16).toUpperCase().padStart(2, "0"); }

async function main() {
  const origData = readBytes(require("./automation").XEX_PATH);
  const orig = parseXex(origData);

  console.log(`Original XEX: ${orig.segments.length} segments, ${origData.length} bytes`);

  let srcImage;
  let srcBuild;

  await withSpyAutomation({ turbo: true, frameDelayMs: 0 }, async (api) => {
    console.log("Assembling source...");
    srcBuild = await assembleSource(api);
    if (!srcBuild.ok) {
      console.error("Assembly FAILED:", JSON.stringify(srcBuild.errors, null, 2));
      process.exitCode = 1;
      return;
    }
    console.log(`Assembly ok — ${srcBuild.byteLength} bytes`);

    const srcBytes = buildBytes(srcBuild);
    const srcParsed = parseXex(srcBytes);
    srcImage = srcParsed.image;

    console.log(`Source XEX: ${srcParsed.segments.length} segments`);

    // Write the source XEX to playground for inspection
    writePlaygroundFile("source-assembled.xex", srcBytes);
  });

  if (!srcImage) return;

  const origImage = orig.image;

  // Check key address ranges for differences
  const keyRanges = [
    { start: 0x9F50, end: 0x9FDD, label: "DLI handler / INITAD" },
    { start: 0x7F00, end: 0x7F1A, label: "Clear routine" },
    { start: 0xC000, end: 0xC28F, label: "NMI/DLI/IRQ handlers" },
    { start: 0xC290, end: 0xC42D, label: "Boot entry" },
    { start: 0xEB87, end: 0xECAE, label: "OS ROM gap (EC17/EC40/EC84)" },
    { start: 0x2000, end: 0x349C, label: "Main game code" },
  ];

  console.log("\n=== Key range comparison (original vs source) ===\n");
  for (const { start, end, label } of keyRanges) {
    const diffs = findDiffs(origImage, srcImage, start, end);
    const origAllZero = Array.from(origImage.slice(start, end+1)).every(b => b === 0);
    const srcAllZero  = Array.from(srcImage.slice(start, end+1)).every(b => b === 0);
    if (diffs.length === 0) {
      console.log(`  $${start.toString(16).toUpperCase()}-$${end.toString(16).toUpperCase()} [${label}]: MATCH ✓`);
    } else {
      console.log(`  $${start.toString(16).toUpperCase()}-$${end.toString(16).toUpperCase()} [${label}]: ${diffs.length} diffs (orig_zero=${origAllZero}, src_zero=${srcAllZero})`);
      const shown = diffs.slice(0, 8);
      for (const { addr, orig: o, src: s } of shown) {
        console.log(`    $${addr.toString(16).toUpperCase().padStart(4,"0")}: orig=$${hexByte(o)} src=$${hexByte(s)}`);
      }
      if (diffs.length > 8) console.log(`    ... and ${diffs.length - 8} more`);
    }
  }

  // Check if 9F50 segment exists in source XEX
  console.log("\n=== 9F50 area in source vs original ===");
  const src9f50 = Array.from(srcImage.slice(0x9F50, 0x9FDE));
  const orig9f50 = Array.from(origImage.slice(0x9F50, 0x9FDE));
  console.log("Orig $9F50:", orig9f50.slice(0,8).map(hexByte).join(" "), "...");
  console.log("Src  $9F50:", src9f50.slice(0,8).map(hexByte).join(" "), "...");

  // Check $02E2 INITAD in both
  console.log("\n=== INITAD ($02E2) in source ===");
  const srcInitad = srcImage[0x02E2] | (srcImage[0x02E3] << 8);
  const origInitad = origImage[0x02E2] | (origImage[0x02E3] << 8);
  console.log(`Orig INITAD=$${origInitad.toString(16).toUpperCase().padStart(4,"0")}`);
  console.log(`Src  INITAD=$${srcInitad.toString(16).toUpperCase().padStart(4,"0")}`);

  // Check RUNAD
  const srcRunad = srcImage[0x02E0] | (srcImage[0x02E1] << 8);
  const origRunad = origImage[0x02E0] | (origImage[0x02E1] << 8);
  console.log(`\nOrig RUNAD=$${origRunad.toString(16).toUpperCase().padStart(4,"0")}`);
  console.log(`Src  RUNAD=$${srcRunad.toString(16).toUpperCase().padStart(4,"0")}`);

  // Diff the FULL memory image - count differing bytes by region
  console.log("\n=== Full memory diff summary ===");
  const regionSize = 0x1000; // 4K pages
  for (let page = 0; page < 0x10; page++) {
    const start = page * regionSize;
    const end = start + regionSize - 1;
    const diffs = findDiffs(origImage, srcImage, start, end);
    if (diffs.length > 0) {
      console.log(`  $${start.toString(16).toUpperCase().padStart(4,"0")}-$${end.toString(16).toUpperCase().padStart(4,"0")}: ${diffs.length} bytes differ`);
    }
  }
}

main().catch(err => {
  console.error(err && err.stack ? err.stack : String(err));
  process.exitCode = 1;
});
