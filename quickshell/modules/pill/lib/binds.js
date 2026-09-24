function readMod(luaText) {
    var m = luaText.match(/^\s*local\s+mod\s*=\s*"([^"]*)"/m);
    return m ? m[1] : "SUPER";
}

/**
 * Reads every `local NAME = "VALUE"` alias in the file, so a combo written as
 * `modS .. " + W"` can be expanded to "SUPER + SHIFT + W". The old hyprlang
 * config only ever had `$mod`; the Lua module uses several aliases (mod, modS,
 * modC, alt, altS) and they are all just string locals.
 */
function readLocals(luaText) {
    var out = {};
    var re = /^\s*local\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"([^"]*)"/gm;
    var m;
    while ((m = re.exec(luaText)) !== null)
        out[m[1]] = m[2];
    return out;
}

function isMouseCombo(combo) {
    return /mouse:|mouse_up|mouse_down/.test(combo);
}

function optsHasMouse(opts) {
    return /\bmouse\s*=\s*true\b/.test(opts);
}

/**
 * Splits an argument list on top-level commas, respecting nested (), {}, []
 * and quoted strings (including escaped quotes). Used to pull `hl.bind`'s
 * first argument from its dispatch and options arguments.
 */
function splitArgs(inner) {
    var args = [];
    var depth = 0;
    var inStr = false;
    var start = 0;
    for (var i = 0; i < inner.length; i++) {
        var c = inner[i];
        if (inStr) {
            // Count the backslash so an escaped quote (\" ) does not end the
            // string, and a double backslash (\\) does not swallow the next
            // quote. Without this a command containing \" shifted the whole
            // argument split.
            if (c === "\\") { i++; continue; }
            if (c === '"') inStr = false;
            continue;
        }
        if (c === '"') { inStr = true; continue; }
        if (c === '(' || c === '{' || c === '[') depth++;
        else if (c === ')' || c === '}' || c === ']') depth--;
        else if (c === ',' && depth === 0) {
            args.push(inner.slice(start, i).trim());
            start = i + 1;
        }
    }
    args.push(inner.slice(start).trim());
    return args;
}

/**
 * Expands a Lua combo expression into a plain "MOD + MOD + KEY" string.
 *
 * Handles the forms the module uses:
 *   mod .. " + Return"          -> "SUPER + Return"
 *   modS .. " + Return"         -> "SUPER + SHIFT + Return"
 *   mod .. " + " .. i           -> "SUPER + " (the loop var is appended)
 *   "SUPER + F12"               -> "SUPER + F12"
 *   "Menu"                      -> "Menu"
 *
 * `locals` maps alias names to their literal values (see readLocals), so the
 * alias is resolved by name rather than by knowing that modS means SHIFT.
 * Returns { combo, dynamic } — `dynamic` marks a combo built from a loop
 * variable, whose real key cannot be known statically.
 */
function resolveCombo(firstArg, modValue, locals) {
    var expr = (firstArg || "").trim();
    var loc = locals || {};

    // Literal: "SUPER + F12"
    var lit = expr.match(/^"([^"]*)"$/);
    if (lit)
        return { combo: lit[1], dynamic: false };

    // alias .. " + KEY"   (possibly with further .. segments)
    var aliasRe = /^([A-Za-z_][A-Za-z0-9_]*)\s*\.\.\s*(.*)$/;
    var am = expr.match(aliasRe);
    if (am) {
        var base = loc[am[1]];
        if (base === undefined)
            // Unknown alias (modValue is the fallback the file declares).
            base = am[1] === "mod" ? (modValue || "SUPER") : am[1];
        var rest = am[2];
        var suffix = "";
        var dynamic = false;
        // Walk the remaining .. "..." segments; anything else is a variable.
        var segRe = /^\s*\.\.\s*(?:"([^"]*)"|([A-Za-z_][A-Za-z0-9_]*))\s*(.*)$/;
        var cursor = rest;
        // The first segment after the alias is a string literal (e.g. " + W").
        var firstSeg = cursor.match(/^"([^"]*)"\s*(.*)$/);
        if (firstSeg) {
            suffix += firstSeg[1];
            cursor = firstSeg[2];
        }
        while (cursor.length) {
            var sm = cursor.match(segRe);
            if (!sm) { dynamic = true; break; }
            if (sm[1] !== undefined) suffix += sm[1];
            else dynamic = true;
            cursor = sm[3];
        }
        return { combo: base + suffix, dynamic: dynamic };
    }

    // Anything else: return the raw expression so the row still renders.
    return { combo: expr, dynamic: true };
}


function deriveLabel(dispatcher, args) {
    var a = (args || "").trim();
    switch (dispatcher) {
        // ── Lua dispatcher names (hl.dsp.*) ─────────────────────────────────
        case "exec_cmd":
            // args here is the shell command (parseLine passes cmd for execs).
            var luaCmd = a.split(/\s+/)[0] || "exec";
            return luaCmd.split("/").pop();
        case "focus":
            // hl.dsp.focus({...}) — workspace loop or directional focus.
            var fw = a.match(/workspace\s*=\s*([A-Za-z0-9_]+)/);
            if (fw) return "workspace " + fw[1];
            var fd = a.match(/direction\s*=\s*"?([A-Za-z]+)"?/);
            return fd ? "focus " + fd[1] : "focus";
        case "move":
            var mw = a.match(/workspace\s*=\s*([A-Za-z0-9_]+)/);
            if (mw) return "move to workspace " + mw[1];
            return "move window";
        case "resize":
            return "resize";
        case "cycle_next":
            return "cycle next";
        case "layout":
            return "layout: " + (a || "?");
        case "drag":
            return "drag window";
        // ── hyprlang dispatcher names (kept for safety / old configs) ───────
        case "exec":
            var cmd = a.split(/\s+/)[0] || "exec";
            return cmd.split("/").pop();
        case "killactive":
            return "kill window";
        case "closewindow":
        case "close":
            return "close window";
        case "fullscreen":
            return "fullscreen";
        case "togglefloating":
        case "float":
            return "toggle float";
        case "workspace":
            return "workspace " + (a || "?");
        case "movewindow":
        case "moveactive":
            return "move window";
        case "resizeactive":
            return "resize";
        case "cyclenext":
            return "cycle next";
        case "pin":
            return "pin";
        case "pseudo":
            return "pseudo tile";
        case "split":
            return "split";
        case "layoutmsg":
            return "layout: " + (a || "?");
        case "submap":
            return "submap: " + (a || "?");
        case "pass":
            return "pass through";
        case "global":
            return "global: " + (a || "?");
        case "mouse":
            return "mouse action";
        default:
            return dispatcher;
    }
}

/**
 * Reads a trailing lua line-comment that sits AFTER the bind statement's closing
 * paren, i.e. `hl.bind(...)  -- my name`. The scan starts past `closeIndex` (the
 * outer close paren) so a `--` inside a quoted string arg can never be mistaken
 * for the name. Returns the trimmed comment text, or "" when there is none.
 */
function nameComment(raw, closeIndex) {
    var rest = raw.slice(closeIndex + 1);
    var m = rest.match(/--\s?(.*)$/);
    return m ? m[1].trim() : "";
}

function isExecAction(action) {
    return /exec_cmd\s*\(/.test(action);
}

/**
 * Pulls the inner shell command out of an `exec_cmd("...")` dispatch. Returns ""
 * for an env-prefixed or non-exec dispatch, where the command is not a single
 * editable literal.
 */
function execCmd(action) {
    var m = action.match(/exec_cmd\(\s*"((?:[^"\\]|\\.)*)"\s*\)/);
    if (!m) return "";
    return m[1].replace(/\\"/g, '"').replace(/\\\\/g, "\\");
}

/**
 * Parses one physical line into a bind entry.
 *
 * Lua form (the only form the module uses now):
 *     hl.bind(mod .. " + Q", hl.dsp.window.close())
 *     hl.bind("Menu", hl.dsp.exec_cmd("..."))
 *     hl.bind(modS .. " + Return", hl.dsp.exec_cmd("..."))  -- optional name
 *
 * Returns the same entry shape the hyprlang parser returned, so Keybinds.qml,
 * shell.qml and ConflictKiller.qml need no changes:
 *     { variant, combo, mods, key, dispatcher, args, label, name, cmd,
 *       isExec, isMouse, lineIndex }
 * `variant` is always "bind" now (the Lua API has no binde/bindm split; repeat
 * and mouse behaviour moved into the dispatch/opts arguments).
 */
function parseLine(raw, lineIndex, ctx) {
    var mod = (ctx && ctx.mod) || "SUPER";
    var luaLine = raw.replace(/\s+$/, "");

    // Locate `hl.bind(` and find its matching close paren.
    var head = luaLine.match(/^\s*hl\.bind\s*\(/);
    if (!head) return null;
    var open = luaLine.indexOf("(", luaLine.indexOf("hl.bind"));
    if (open === -1) return null;
    var depth = 0;
    var inStr = false;
    var close = -1;
    for (var i = open; i < luaLine.length; i++) {
        var c = luaLine.charAt(i);
        if (inStr) {
            if (c === "\\") { i++; continue; }
            if (c === '"') inStr = false;
            continue;
        }
        if (c === '"') { inStr = true; continue; }
        if (c === "(") depth++;
        else if (c === ")") {
            depth--;
            if (depth === 0) { close = i; break; }
        }
    }
    if (close === -1) return null;   // multi-line call; not a single-bind line

    var inner = luaLine.slice(open + 1, close);
    var args = splitArgs(inner);
    if (args.length < 2) return null;

    var comboInfo = resolveCombo(args[0], mod, ctx && ctx.locals);
    var combo = comboInfo.combo;

    // Second argument is the dispatch: hl.dsp.exec_cmd("..."), hl.dsp.window.close(), ...
    var dispatch = args[1] || "";
    var dm = dispatch.match(/^hl\.dsp\.([A-Za-z_][A-Za-z0-9_]*)\s*\(/);
    var dispatcher = dm ? dm[1] : dispatch.replace(/\s*\(.*$/, "");
    // Map the nested namespace calls onto the flat names the label table knows:
    // hl.dsp.window.close() -> "close", hl.dsp.window.float() -> "float", ...
    var nm = dispatch.match(/^hl\.dsp\.(?:window|workspace|group|cursor)\.([A-Za-z_][A-Za-z0-9_]*)\s*\(/);
    if (nm) dispatcher = nm[1];

    // Trailing `-- name` comment after the close paren. The scan starts past
    // `close` so a `--` inside a quoted command can never be read as the name.
    var name = nameComment(luaLine, close);

    var isExec = isExecAction(dispatch);
    var cmd = isExec ? execCmd(dispatch) : "";
    // `args` mirrors the old field: for an exec it is the shell command, for
    // everything else the raw dispatch text, so the UI can show something.
    var argText = isExec ? cmd : dispatch;
    var isMouse = isMouseCombo(combo);
    var label = name.length ? name : deriveLabel(dispatcher, argText);

    return {
        variant: "bind",
        combo: combo,
        mods: combo,
        key: combo,
        dispatcher: dispatcher,
        args: argText,
        label: label,
        name: name,
        cmd: cmd,
        isExec: isExec,
        isMouse: isMouse,
        dynamic: comboInfo.dynamic,
        lineIndex: lineIndex
    };
}

function parse(text) {
    var lines = text.split("\n");
    var ctx = { mod: readMod(text), locals: readLocals(text) };
    var out = [];
    for (var i = 0; i < lines.length; i++) {
        var entry = parseLine(lines[i], i, ctx);
        if (entry) out.push(entry);
    }
    return out;
}



/**
 * Splits a captured combo like "SUPER + SHIFT + W" (or just "W") into
 * { mods, key }. Kept for the UI's inUse() comparison and for rebuilding.
 */
function comboToModsKey(combo) {
    var parts = combo.split("+").map(function (p) { return p.trim(); }).filter(function (p) { return p.length; });
    if (parts.length === 0) return { mods: "", key: "" };
    var key = parts[parts.length - 1];
    var mods = parts.slice(0, -1).join(" + ");
    return { mods: mods, key: key };
}

function escapeLua(s) {
    return String(s).replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

/**
 * Rebuilds one `hl.bind(...)` line.
 *
 * Two shapes are emitted, matching how the module is written by hand:
 *   - a plain literal combo:  hl.bind("SUPER + W", <dispatch>)
 *   - a combo with modifiers: hl.bind(mod .. " + W", <dispatch>)
 *     so edits keep following the file's own `mod` alias and stay consistent
 *     with the surrounding lines (and with a user who later changes the alias).
 *
 * `dispatch` is the full expression (hl.dsp.exec_cmd("..."), hl.dsp.window.close()).
 * An optional `name` becomes a trailing `-- name` comment, which is the form
 * the parser and the old UI already understand.
 */
function buildLine(dispatch, combo, name) {
    var mk = comboToModsKey(combo);
    var comboExpr;
    // Modifier-only prefixes map back onto the file's alias where possible.
    var known = { "SUPER": "mod", "SUPER + SHIFT": "modS", "SUPER + CTRL": "modC" };
    if (mk.mods && known[mk.mods]) {
        comboExpr = known[mk.mods] + ' .. " + ' + mk.key + '"';
    } else if (mk.mods) {
        comboExpr = '"' + mk.mods + " + " + mk.key + '"';
    } else {
        comboExpr = '"' + mk.key + '"';
    }
    var line = "hl.bind(" + comboExpr + ", " + dispatch + ")";
    if (name && name.length)
        line += "  -- " + name;
    return line;
}

/**
 * Builds the dispatch expression for an exec bind, quoting the command.
 */
function execDispatch(cmd) {
    return 'hl.dsp.exec_cmd("' + escapeLua(cmd) + '")';
}

/**
 * Finds the close paren matching the `(` at `open`, respecting strings and
 * nesting. Returns -1 when unbalanced.
 */
function findCloseParen(line, open) {
    if (open === -1) return -1;
    var depth = 0, inStr = false;
    for (var i = open; i < line.length; i++) {
        var c = line.charAt(i);
        if (inStr) {
            if (c === "\\") { i++; continue; }
            if (c === '"') inStr = false;
            continue;
        }
        if (c === '"') { inStr = true; continue; }
        if (c === "(") depth++;
        else if (c === ")") { depth--; if (depth === 0) return i; }
    }
    return -1;
}

/**
 * Pulls the dispatch expression (argument 2) out of an existing hl.bind line.
 */
function existingDispatch(line) {
    var open = line.indexOf("(", line.indexOf("hl.bind"));
    var close = findCloseParen(line, open);
    if (open === -1 || close === -1)
        return "";
    var args = splitArgs(line.slice(open + 1, close));
    return args[1] || "";
}

function rebind(luaText, lineIndex, newCombo) {
    var lines = luaText.split("\n");
    if (lineIndex < 0 || lineIndex >= lines.length)
        return { text: luaText, ok: false, error: "invalid lineIndex" };
    var ctx = { mod: readMod(luaText), locals: readLocals(luaText) };
    var entry = parseLine(lines[lineIndex], lineIndex, ctx);
    if (!entry)
        return { text: luaText, ok: false, error: "not a bind line" };
    // Preserve the existing dispatch expression verbatim; only the combo moves.
    var dispatch = existingDispatch(lines[lineIndex]);
    if (!dispatch)
        return { text: luaText, ok: false, error: "no dispatch" };
    lines[lineIndex] = buildLine(dispatch, newCombo, entry.name);
    return { text: lines.join("\n"), ok: true, error: "" };
}

function inUse(luaText, newCombo, exceptLineIndex) {
    var entries = parse(luaText);
    for (var i = 0; i < entries.length; i++) {
        if (entries[i].lineIndex === exceptLineIndex) continue;
        if (entries[i].combo === newCombo) return true;
    }
    return false;
}


function add(luaText, combo, cmd, name) {
    if (!combo || !combo.length)
        return { text: luaText, ok: false, error: "empty combo" };
    if (!cmd || !cmd.length)
        return { text: luaText, ok: false, error: "empty command" };
    var line = buildLine(execDispatch(cmd), combo, name);
    var sep = luaText.length === 0 || luaText.charAt(luaText.length - 1) === "\n" ? "" : "\n";
    return { text: luaText + sep + line + "\n", ok: true, error: "" };
}

function del(luaText, lineIndex) {
    var lines = luaText.split("\n");
    if (lineIndex < 0 || lineIndex >= lines.length)
        return { text: luaText, ok: false, error: "invalid lineIndex" };
    lines.splice(lineIndex, 1);
    return { text: lines.join("\n"), ok: true, error: "" };
}

function editCmd(luaText, lineIndex, cmd) {
    var lines = luaText.split("\n");
    if (lineIndex < 0 || lineIndex >= lines.length)
        return { text: luaText, ok: false, error: "invalid lineIndex" };
    var ctx = { mod: readMod(luaText), locals: readLocals(luaText) };
    var entry = parseLine(lines[lineIndex], lineIndex, ctx);
    if (!entry)
        return { text: luaText, ok: false, error: "not a bind line" };
    lines[lineIndex] = buildLine(execDispatch(cmd), entry.combo, entry.name);
    return { text: lines.join("\n"), ok: true, error: "" };
}

function editName(luaText, lineIndex, name) {
    var lines = luaText.split("\n");
    if (lineIndex < 0 || lineIndex >= lines.length)
        return { text: luaText, ok: false, error: "invalid lineIndex" };
    var ctx = { mod: readMod(luaText), locals: readLocals(luaText) };
    var entry = parseLine(lines[lineIndex], lineIndex, ctx);
    if (!entry)
        return { text: luaText, ok: false, error: "not a bind line" };
    // Rebuild with the same dispatch the line already had, so renaming never
    // rewrites (or loses) the command.
    var dispatch = existingDispatch(lines[lineIndex]);
    if (!dispatch)
        return { text: luaText, ok: false, error: "no dispatch" };
    lines[lineIndex] = buildLine(dispatch, entry.combo, name);
    return { text: lines.join("\n"), ok: true, error: "" };
}

/**
 * Replaces the whole dispatch of a line from the UI's raw "action" string.
 *
 * The UI shows a read-only action for anything that is not a single-string exec
 * (see Keybinds.qml formCmdEditable), and only ever calls this with the action
 * it was given. Non-exec actions arrive as a plain dispatcher name (possibly
 * with arguments); those are mapped back onto the hl.dsp.* expression form so
 * the emitted line stays valid Lua rather than writing a bare word.
 */
function editAction(luaText, lineIndex, action) {
    var lines = luaText.split("\n");
    if (lineIndex < 0 || lineIndex >= lines.length)
        return { text: luaText, ok: false, error: "invalid lineIndex" };
    var ctx = { mod: readMod(luaText), locals: readLocals(luaText) };
    var entry = parseLine(lines[lineIndex], lineIndex, ctx);
    if (!entry)
        return { text: luaText, ok: false, error: "not a bind line" };

    var trimmed = (action || "").trim();
    var dispatch;
    if (/^hl\.dsp\./.test(trimmed)) {
        dispatch = trimmed;                                   // already an expression
    } else if (/^exec\b/.test(trimmed)) {
        var cmd = trimmed.replace(/^exec\s*[,]?\s*/, "");
        dispatch = execDispatch(cmd);
    } else {
        // A bare dispatcher name (e.g. "killactive"): route it through the
        // window namespace, which is where the close/kill/float family lives.
        var parts = trimmed.split(/\s+/);
        dispatch = "hl.dsp.window." + parts[0] + "()";
    }
    lines[lineIndex] = buildLine(dispatch, entry.combo, entry.name);
    return { text: lines.join("\n"), ok: true, error: "" };
}
