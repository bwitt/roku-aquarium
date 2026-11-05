const test = require("node:test");
const assert = require("node:assert");
const path = require("node:path");
const brs = require("@rokucommunity/brs");

const root = path.join(__dirname, "..");

test("AquariumScene BrightScript suite", async () => {
  const results = await brs.execute(
    [path.join(__dirname, "AquariumScene.test.brs"), path.join(root, "components", "AquariumScene.brs")],
    { root, componentDirs: ["tests/mocks"] }
  );
  // brs swallows runtime errors, so anything but Main() returning 0 is a failure
  const ret = results.find((r) => r && r.kind === brs.types.ValueKind.Int32);
  assert.ok(ret, "suite did not finish (runtime error?)");
  assert.strictEqual(ret.getValue(), 0, `${ret.getValue()} check(s) failed, see FAIL lines above`);
});
