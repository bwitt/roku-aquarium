const test = require("node:test");
const assert = require("node:assert");
const fs = require("node:fs");
const path = require("node:path");

const root = path.join(__dirname, "..");
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");
const listFiles = (dir) =>
  fs.readdirSync(path.join(root, dir), { recursive: true }).map((f) => path.join(dir, f));

function pngSize(rel) {
  const buf = fs.readFileSync(path.join(root, rel));
  assert.strictEqual(buf.toString("ascii", 12, 16), "IHDR", `${rel} is not a PNG`);
  return { width: buf.readUInt32BE(16), height: buf.readUInt32BE(20) };
}

test("manifest has the keys a screensaver needs", () => {
  const manifest = Object.fromEntries(
    read("manifest")
      .split("\n")
      .filter((line) => line.includes("="))
      .map((line) => line.split(/=(.*)/s, 2).map((s) => s.trim()))
  );
  for (const key of ["title", "screensaver_title", "mm_icon_focus_hd", "ui_resolutions"]) {
    assert.ok(manifest[key], `manifest is missing ${key}`);
  }
  for (const key of ["major_version", "minor_version", "build_version"]) {
    assert.match(manifest[key] ?? "", /^\d+$/, `manifest ${key} must be an integer`);
  }
});

test("every pkg:/ reference points at a packaged file", () => {
  const sources = ["manifest", ...listFiles("source"), ...listFiles("components")];
  const refs = sources.flatMap((rel) =>
    [...read(rel).matchAll(/pkg:\/([\w./-]+)/g)].map((m) => ({ rel, target: m[1] }))
  );
  assert.ok(refs.length > 0, "no pkg:/ references found");
  for (const { rel, target } of refs) {
    assert.ok(fs.existsSync(path.join(root, target)), `${rel} references missing pkg:/${target}`);
  }
});

test("images match the sizes AquariumScene.brs assumes", () => {
  // addFish() sizes posters from a 240x150 base
  for (const rel of listFiles("images").filter((f) => /fish\d+\.png$/.test(f))) {
    assert.deepStrictEqual(pngSize(rel), { width: 240, height: 150 }, `${rel} is not 240x150`);
  }
  const bubble = pngSize("images/bubble.png");
  assert.strictEqual(bubble.width, bubble.height, "bubble.png is not square");
});
