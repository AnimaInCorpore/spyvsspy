"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { createHeadlessAutomation } = require("../A8E/jsA8E/headless");

const ROOT_DIR = path.resolve(__dirname, "..");
const PLAYGROUND_DIR = path.resolve(ROOT_DIR, "playground");
const SOURCE_PATH = path.resolve(ROOT_DIR, "Spy vs Spy (Title Version).s");
const XEX_PATH = path.resolve(ROOT_DIR, "Spy vs Spy (Title Version).xex");
const ROMS = {
  os: path.resolve(ROOT_DIR, "ATARIXL.ROM"),
  basic: path.resolve(ROOT_DIR, "ATARIBAS.ROM"),
};

function hex(value, width) {
  return "$" + (value >>> 0).toString(16).toUpperCase().padStart(width || 4, "0");
}

function ensurePlaygroundDir() {
  fs.mkdirSync(PLAYGROUND_DIR, { recursive: true });
  return PLAYGROUND_DIR;
}

function rootPath(...parts) {
  return path.resolve(ROOT_DIR, ...parts);
}

function playgroundPath(...parts) {
  ensurePlaygroundDir();
  return path.join(PLAYGROUND_DIR, ...parts);
}

function readText(filePath, encoding) {
  return fs.readFileSync(path.isAbsolute(filePath) ? filePath : rootPath(filePath), encoding || "utf8");
}

function readBytes(filePath) {
  return fs.readFileSync(path.isAbsolute(filePath) ? filePath : rootPath(filePath));
}

function writePlaygroundFile(fileName, data) {
  const outPath = playgroundPath(fileName);
  fs.writeFileSync(outPath, data);
  return outPath;
}

async function withSpyAutomation(options, fn) {
  const runtime = await createHeadlessAutomation({
    cwd: ROOT_DIR,
    roms: ROMS,
    turbo: true,
    frameDelayMs: 0,
    ...(options || {}),
  });

  try {
    return await fn(runtime.api, runtime);
  } finally {
    await runtime.dispose();
  }
}

async function assembleSource(api, sourcePath) {
  const resolvedPath = sourcePath ? (path.isAbsolute(sourcePath) ? sourcePath : rootPath(sourcePath)) : SOURCE_PATH;
  const text = readText(resolvedPath, "utf8");
  return api.dev.assembleSource({
    name: path.basename(resolvedPath),
    text: text,
  });
}

function buildBytes(build) {
  if (build && build.bytes) return Buffer.from(build.bytes);
  if (build && build.base64) return Buffer.from(build.base64, "base64");
  throw new Error("No bytes in build result");
}

async function runBuild(api, build, options) {
  const opts = options || {};
  return api.dev.runXex({
    build: build,
    awaitEntry: opts.awaitEntry !== undefined ? opts.awaitEntry : false,
    resetOptions: { portB: 0xfe, ...(opts.resetOptions || {}) },
  });
}

async function runXexBytes(api, bytes, options) {
  const opts = options || {};
  return api.dev.runXex({
    bytes: bytes,
    awaitEntry: opts.awaitEntry !== undefined ? opts.awaitEntry : false,
    resetOptions: { portB: 0xfe, ...(opts.resetOptions || {}) },
  });
}

async function runSource(api, sourcePath, options) {
  const build = await assembleSource(api, sourcePath);
  if (!build.ok) {
    throw new Error("Assembly failed" + (build.errors ? ": " + JSON.stringify(build.errors) : ""));
  }
  return {
    build: build,
    result: await runBuild(api, build, options),
  };
}

async function captureScreenshot(api, fileName) {
  const shot = await api.artifacts.captureScreenshot({ encoding: "bytes" });
  const outPath = writePlaygroundFile(fileName, Buffer.from(shot.bytes));
  return {
    path: outPath,
    width: shot.width,
    height: shot.height,
  };
}

async function getDebugState(api) {
  return (await api.getSystemState()).debugState;
}

module.exports = {
  ROOT_DIR: ROOT_DIR,
  PLAYGROUND_DIR: PLAYGROUND_DIR,
  SOURCE_PATH: SOURCE_PATH,
  XEX_PATH: XEX_PATH,
  hex: hex,
  ensurePlaygroundDir: ensurePlaygroundDir,
  rootPath: rootPath,
  playgroundPath: playgroundPath,
  readText: readText,
  readBytes: readBytes,
  writePlaygroundFile: writePlaygroundFile,
  withSpyAutomation: withSpyAutomation,
  assembleSource: assembleSource,
  buildBytes: buildBytes,
  runBuild: runBuild,
  runXexBytes: runXexBytes,
  runSource: runSource,
  captureScreenshot: captureScreenshot,
  getDebugState: getDebugState,
};
