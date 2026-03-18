const fs = require("node:fs");
const path = require("node:path");
const { createHeadlessAutomation } = require("./A8E/jsA8E/headless");

async function main() {
  const runtime = await createHeadlessAutomation({
    cwd: __dirname,
    roms: {
      os: path.resolve(__dirname, "ATARIXL.ROM"),
      basic: path.resolve(__dirname, "ATARIBAS.ROM"),
    },
  });

  try {
    const api = runtime.api;
    const sourcePath = path.resolve(__dirname, "Spy vs Spy (Title Version).s");
    const source = fs.readFileSync(sourcePath, "utf8");
    const build = await api.dev.assembleSource({
      name: path.basename(sourcePath),
      text: source,
    });

    const result = await api.dev.runXex({
      build,
      resetOptions: { portB: 0xfe },
      awaitEntry: false,
    });

    console.log(
      JSON.stringify(
        {
          ok: result.ok,
          phase: result.phase,
          started: result.started,
          runAddr: result.runAddr,
          portB: result.xexPreflight && result.xexPreflight.portB,
          overlaps: result.xexPreflight && result.xexPreflight.overlaps.length,
        },
        null,
        2,
      ),
    );
  } finally {
    await runtime.dispose();
  }
}

main().catch((err) => {
  console.error(err && err.stack ? err.stack : String(err));
  process.exitCode = 1;
});
