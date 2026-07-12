/**
 * test-binds.js — Unit tests for modules/pill/lib/binds.js
 * Run: node test-binds.js
 * No test framework needed — pure Node.js assertions.
 */

const fs = require("fs");
const src = fs.readFileSync("./modules/pill/lib/binds.js", "utf8");
eval(src); // Load all functions into scope (QML-style module, no exports)

let passed = 0;
let failed = 0;

function assert(condition, label) {
    if (condition) {
        console.log("  ✅ " + label);
        passed++;
    } else {
        console.error("  ❌ FAIL: " + label);
        failed++;
    }
}

function assertEqual(actual, expected, label) {
    if (actual === expected) {
        console.log("  ✅ " + label);
        passed++;
    } else {
        console.error("  ❌ FAIL: " + label);
        console.error("     expected: " + JSON.stringify(expected));
        console.error("     actual:   " + JSON.stringify(actual));
        failed++;
    }
}

// ─── parse() ─────────────────────────────────────────────────────────────────

console.log("\n── parse() basic cases ──");

{
    const r = parse("bind = SUPER, Q, killactive");
    assert(r.length === 1, "single line parses to 1 result");
    assertEqual(r[0].mods, "SUPER", "mods parsed");
    assertEqual(r[0].key, "Q", "key parsed");
    assertEqual(r[0].dispatcher, "killactive", "dispatcher parsed");
    assertEqual(r[0].isExec, false, "killactive is not exec");
    assertEqual(r[0].isMouse, false, "killactive is not mouse");
}

console.log("\n── parse() exec binds ──");

{
    const r = parse("bind = SUPER, Return, exec, kitty");
    assertEqual(r[0].isExec, true, "exec bind detected");
    assertEqual(r[0].cmd, "kitty", "exec cmd parsed");
    assertEqual(r[0].label, "kitty", "label is first word of cmd");
}

console.log("\n── parse() empty mods ──");

{
    const r = parse("bind = , Print, exec, grim ~/screenshots/shot.png");
    assertEqual(r[0].mods, "", "empty mods handled");
    assertEqual(r[0].key, "Print", "key parsed with empty mods");
    assertEqual(r[0].isExec, true, "exec detected with empty mods");
}

console.log("\n── parse() mouse bindings ──");

{
    const r = parse("bindm = SUPER, mouse:272, movewindow");
    assertEqual(r[0].isMouse, true, "mouse binding detected");
    assertEqual(r[0].variant, "bindm", "bindm variant parsed");
    assertEqual(r[0].key, "mouse:272", "mouse key parsed");
}

console.log("\n── parse() binde variant ──");

{
    const r = parse("binde = SUPER CTRL, Left, resizeactive, -20 0");
    assertEqual(r[0].variant, "binde", "binde variant parsed");
    assertEqual(r[0].mods, "SUPER CTRL", "multi-mod parsed");
    assertEqual(r[0].args, "-20 0", "args with space parsed");
}

console.log("\n── parse() shell metacharacters in args ──");

{
    const r = parse('bind = SUPER, F12, exec, hyprctl activeworkspace -j >> /tmp/debug.log 2>&1');
    assertEqual(r[0].isExec, true, "exec with shell redirect detected");
    assert(r[0].cmd.includes(">>"), "shell redirect preserved in cmd");
    assert(r[0].cmd.includes("2>&1"), "stderr redirect preserved in cmd");
}

console.log("\n── parse() named comment ──");

{
    const r = parse("bind = SUPER, T, exec, kitty # Terminal");
    assertEqual(r[0].name, "Terminal", "name parsed from trailing comment");
    assertEqual(r[0].cmd, "kitty", "cmd excludes comment");
}

console.log("\n── parse() empty input ──");

{
    const r = parse("");
    assertEqual(r.length, 0, "empty string returns empty array");
}

console.log("\n── parse() comment-only lines skipped ──");

{
    const r = parse("# this is a comment\nbind = SUPER, Q, killactive");
    assertEqual(r.length, 1, "comment lines skipped");
    assertEqual(r[0].key, "Q", "real bind still parsed after comment");
}

console.log("\n── parse() multiple lines ──");

{
    const input = [
        "bind = SUPER, Q, killactive",
        "bind = SUPER, Return, exec, kitty",
        "bindm = SUPER, mouse:272, movewindow",
    ].join("\n");
    const r = parse(input);
    assertEqual(r.length, 3, "all 3 lines parsed");
    assertEqual(r[0].lineIndex, 0, "lineIndex 0 correct");
    assertEqual(r[1].lineIndex, 1, "lineIndex 1 correct");
    assertEqual(r[2].lineIndex, 2, "lineIndex 2 correct");
}

// ─── splitArgs() ─────────────────────────────────────────────────────────────

console.log("\n── splitArgs() ──");

{
    const r = splitArgs('a, b, c');
    assertEqual(r.length, 3, "simple split produces 3 args");
    assertEqual(r[0], "a", "first arg");
    assertEqual(r[2], "c", "third arg");
}

{
    const r = splitArgs('"hello, world", b');
    assertEqual(r.length, 2, "quoted comma not split");
    assertEqual(r[0], '"hello, world"', "quoted string preserved");
}

{
    const r = splitArgs('fn(a, b), c');
    assertEqual(r.length, 2, "nested parens not split");
}

// ─── isMouseCombo() ──────────────────────────────────────────────────────────

console.log("\n── isMouseCombo() ──");

{
    assert(isMouseCombo("mouse:272"), "mouse:272 is mouse");
    assert(isMouseCombo("mouse_up"), "mouse_up is mouse");
    assert(isMouseCombo("mouse_down"), "mouse_down is mouse");
    assert(!isMouseCombo("Return"), "Return is not mouse");
    assert(!isMouseCombo("SUPER"), "SUPER is not mouse");
}

// ─── deriveLabel() ───────────────────────────────────────────────────────────

console.log("\n── deriveLabel() ──");

{
    assertEqual(deriveLabel("killactive", []), "kill window", "killactive label");
    assertEqual(deriveLabel("movewindow", ["l"]), "move window", "movewindow label");
    assertEqual(deriveLabel("exec", "kitty"), "kitty", "exec label is first word");
    assertEqual(deriveLabel("exec", "kitty --hold -e bash"), "kitty", "exec label strips args");
}

// ─── Summary ─────────────────────────────────────────────────────────────────

console.log("\n" + "─".repeat(50));
console.log(`Results: ${passed} passed, ${failed} failed`);
if (failed > 0) {
    process.exit(1);
}
