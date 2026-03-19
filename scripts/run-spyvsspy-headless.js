"use strict";

const { assembleSource, runBuild, withSpyAutomation } = require("./automation");

async function main() {
  await withSpyAutomation({}, async (api) => {
    const build = await assembleSource(api);
    if (!build.ok) throw new Error("Assembly failed");

    const result = await runBuild(api, build, {
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
  });
}

main().catch((err) => {
  console.error(err && err.stack ? err.stack : String(err));
  process.exitCode = 1;
});
