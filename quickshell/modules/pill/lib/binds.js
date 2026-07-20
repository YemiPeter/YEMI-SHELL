function readMod(luaText) {
    var m = luaText.match(/^\s*local\s+mod\s*=\s*"([^"]*)"/m);
    return m ? m[1] : "SUPER";
}

function isMouseCombo(combo) {
    return /mouse:|mouse_up|mouse_down/.test(combo);
}

function optsHasMouse(opts) {
    return /\bmouse\s*=\s*true\b/.test(opts);
}

function splitArgs(inner) {
    var args = [];
    var depth = 0;
    var inStr = false;
    var start = 0;
    for (var i = 0; i < inner.length; i++) {
        var c = inner[i];
        if (inStr) {
            if (c === '"') inStr = false;
            continue;
        }
        if (c === '"') { inStr = true; continue; }
        if (c === '(' || c === '{' || c === '[') depth++;
        else if (c === ')' || c === '}' || c === ']') depth--;
        else if (c === ',' && depth === 0) {
            args.push(inner.slice(start, i));
            start = i + 1;
        }
    }
    args.push(inner.slice(start));
    return args.map(function (a) { return a.trim(); });
}

function resolveCombo(firstArg, modValue) {
    var modMatch = firstArg.match(/^mod\s*\.\.\s*"([^"]*)"$/);
    if (modMatch) {
        return { combo: modValue + modMatch[1] };
    }
    var litMatch = firstArg.match(/^"([^"]*)"$/);
    if (litMatch) {
        return { combo: litMatch[1] };
    }
    return { combo: firstArg };
}

function deriveLabel(dispatcher, args) {
    switch (dispatcher) {
        case "exec":
            var cmd = (args || "").trim().split(/\s+/)[0] || "exec";
            return cmd.split("/").pop();
        case "killactive":
            return "kill window";
        case "closewindow":
        case "close":
            return "close window";
        case "fullscreen":
            return "fullscreen";
        case "togglefloating":
            return "toggle float";
        case "workspace":
            return "workspace " + ((args || "").trim() || "?");
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
            return "layout: " + ((args || "").trim() || "?");
        case "submap":
            return "submap: " + ((args || "").trim() || "?");
        case "pass":
            return "pass through";
        case "global":
            return "global: " + ((args || "").trim() || "?");
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

function parseLine(raw, lineIndex) {
    var bm = raw.match(/^\s*(bind(?:e|m|l)?)\s*=\s*(.*)$/);
    if (!bm) return null;

    var variant = bm[1];
    var rest = bm[2];

    // Extract trailing # comment (hyprlang: # always starts a comment)
    var name = "";
    var body = rest;
    var cm = rest.match(/\s+#\s+(.*)$/);
    if (cm) {
        name = cm[1].trim();
        body = rest.slice(0, cm.index);
    }

    var parts = splitArgs(body);
    if (parts.length < 3) return null;

    var mods = parts[0];
    var key = parts[1];
    var dispatcher = parts[2];
    var args = parts.slice(3).join(", ");

    var isExec = dispatcher === "exec";
    var isMouse = /^mouse:/i.test(key);
    var cmd = isExec ? args : "";
    var combo = mods + ", " + key;
    var label = name.length ? name : deriveLabel(dispatcher, args);

    return {
        variant: variant,
        combo: combo,
        mods: mods,
        key: key,
        dispatcher: dispatcher,
        args: args,
        label: label,
        name: name,
        cmd: cmd,
        isExec: isExec,
        isMouse: isMouse,
        lineIndex: lineIndex
    };
}

function parse(text) {
    var lines = text.split("\n");
    var out = [];
    for (var i = 0; i < lines.length; i++) {
        var entry = parseLine(lines[i], i);
        if (entry) out.push(entry);
    }
    return out;
}


/**
 * Splits a captured combo like "$mod + SHIFT + W" (or just "W") into
 * { mods, key } for native hyprlang syntax, e.g. mods:"$mod SHIFT", key:"W".
 */
function comboToModsKey(combo) {
    var parts = combo.split("+").map(function (p) { return p.trim(); }).filter(function (p) { return p.length; });
    if (parts.length === 0) return { mods: "", key: "" };
    var key = parts[parts.length - 1];
    var mods = parts.slice(0, -1).join(" ");
    return { mods: mods, key: key };
}

/**
 * Rebuilds one native hyprlang bind line from its parts. mods may be "".
 */
function buildLine(variant, mods, key, dispatcher, args, name) {
    var line = variant + " = " + mods + ", " + key + ", " + dispatcher;
    if (args && args.length) line += ", " + args;
    if (name && name.length) line += "  # " + name;
    return line;
}

function rebind(luaText, lineIndex, newCombo) {
    var lines = luaText.split("\n");
    if (lineIndex < 0 || lineIndex >= lines.length)
        return { text: luaText, ok: false, error: "invalid lineIndex" };
    var entry = parseLine(lines[lineIndex], lineIndex);
    if (!entry)
        return { text: luaText, ok: false, error: "not a bind line" };
    var mk = comboToModsKey(newCombo);
    lines[lineIndex] = buildLine(entry.variant, mk.mods, mk.key, entry.dispatcher, entry.args, entry.name);
    return { text: lines.join("\n"), ok: true, error: "" };
}

function inUse(luaText, newCombo, exceptLineIndex) {
    var mk = comboToModsKey(newCombo);
    var target = mk.mods + ", " + mk.key;
    var entries = parse(luaText);
    for (var i = 0; i < entries.length; i++) {
        if (entries[i].lineIndex === exceptLineIndex) continue;
        if (entries[i].combo === target) return true;
    }
    return false;
}

function add(luaText, combo, cmd, name) {
    if (!combo || !combo.length)
        return { text: luaText, ok: false, error: "empty combo" };
    if (!cmd || !cmd.length)
        return { text: luaText, ok: false, error: "empty command" };
    var mk = comboToModsKey(combo);
    var line = buildLine("bind", mk.mods, mk.key, "exec", cmd, name);
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
    var entry = parseLine(lines[lineIndex], lineIndex);
    if (!entry)
        return { text: luaText, ok: false, error: "not a bind line" };
    lines[lineIndex] = buildLine(entry.variant, entry.mods, entry.key, entry.dispatcher, cmd, entry.name);
    return { text: lines.join("\n"), ok: true, error: "" };
}

function editName(luaText, lineIndex, name) {
    var lines = luaText.split("\n");
    if (lineIndex < 0 || lineIndex >= lines.length)
        return { text: luaText, ok: false, error: "invalid lineIndex" };
    var entry = parseLine(lines[lineIndex], lineIndex);
    if (!entry)
        return { text: luaText, ok: false, error: "not a bind line" };
    lines[lineIndex] = buildLine(entry.variant, entry.mods, entry.key, entry.dispatcher, entry.args, name);
    return { text: lines.join("\n"), ok: true, error: "" };
}

function editAction(luaText, lineIndex, action) {
    var lines = luaText.split("\n");
    if (lineIndex < 0 || lineIndex >= lines.length)
        return { text: luaText, ok: false, error: "invalid lineIndex" };
    var entry = parseLine(lines[lineIndex], lineIndex);
    if (!entry)
        return { text: luaText, ok: false, error: "not a bind line" };
    var parts = action.split(",");
    var dispatcher = parts[0].trim();
    var args = parts.slice(1).join(",").trim();
    lines[lineIndex] = buildLine(entry.variant, entry.mods, entry.key, dispatcher, args, entry.name);
    return { text: lines.join("\n"), ok: true, error: "" };
}
