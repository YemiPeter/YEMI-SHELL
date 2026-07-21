/**
 * binds-niri.js — parser/editor for Niri (KDL) keybind files.
 *
 * Mirrors the function shapes of binds.js (Hyprland) but adapted to Niri's
 * KDL bind syntax:
 *
 *     Combo [flag=value ...] { action [args...]; }
 *
 * Examples (from the real 70-binds.kdl):
 *     Mod+Tab repeat=false { toggle-overview; }
 * Mod+Alt+L allow-when-locked=true { spawn "$RICE_HOME/quickshell/shell" "lock" "activate"; }
 *     Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
 *     Mod+1 { focus-workspace 1; }
 *
 * Flags are free-form "key=value" pairs — no fixed set is hardcoded. Unknown /
 * future flags are preserved verbatim, in original order, on every rebuild.
 *
 * NAMING CONVENTION (differs from Hyprland):
 *   Hyprland: trailing `# name` comment on the SAME line.
 *   Niri:     `//` comment on the line(s) ABOVE the bind.
 *   Rule: walk upward from the bind line through contiguous `//` comment
 *   lines. Skip any comment whose text (after stripping `//` + leading
 *   whitespace) starts with "TODO" (case-insensitive). Use the nearest
 *   remaining non-TODO comment as the name. If nothing remains, fall back to
 *   an auto-derived label from the action name.
 *
 * COMMENTED-OUT BINDS (e.g. `// Mod+M { maximize-window-to-edges; }`) are
 * ignored entirely, same as binds.js does for Hyprland.
 */

/**
 * True when a trimmed line is a Niri/KDL comment (starts with `//`).
 */
function isCommentLine(raw) {
    return /^\s*\/\//.test(raw);
}

/**
 * True when a comment line looks like a decorative section header
 * (contains box-drawing characters), as opposed to a per-bind name.
 */
function isHeaderComment(raw) {
    return /[═─]/.test(raw);
}

/**
 * Strips the leading `//` and whitespace from a comment line.
 */
function stripComment(raw) {
    return raw.replace(/^\s*\/\/\s*/, "");
}

/**
 * Parses a single live bind line into its structural parts.
 * Returns null for blank lines, comments, and non-bind lines.
 *
 * Recognized shape:  <combo> [<flags>] { <action> [<args>]; }
 *   - combo : e.g. "Mod+Tab", "Mod+Ctrl+Shift+Left"
 *   - flags : array of raw "key=value" strings (empty array if none)
 *   - action: e.g. "spawn", "focus-workspace", "toggle-overview"
 *   - args  : everything after the action, as one joined string
 *
 * The semicolon after the action block is optional in KDL but present in
 * this file; we strip it from args.
 */
function parseBindLine(raw) {
    // Skip blank lines and comment-only lines
    if (!raw.trim().length) return null;
    if (isCommentLine(raw)) return null;

    // Match: <combo> [flags...] { <action> [args...]; }
    // Flags are optional key=value pairs between combo and the opening brace.
    var m = raw.match(/^\s*(\S+(?:\s*\+\s*\S+)*)\s*(.*?)\s*\{\s*(\S+)\s*(.*?)\s*;\s*\}/);
    if (!m) return null;

    var combo = m[1].trim();
    var flagBlock = m[2].trim();
    var action = m[3].trim();
    var args = m[4].trim();

    // Parse flags from the block between combo and the opening brace.
    // Flags are space-separated "key=value" tokens.
    var flags = [];
    if (flagBlock.length) {
        // Match each "key=value" token (values may be quoted or unquoted)
        var flagRe = /(\S+="[^"]*"|\S+=\S+)/g;
        var fm;
        while ((fm = flagRe.exec(flagBlock)) !== null) {
            flags.push(fm[1]);
        }
    }

    return {
        combo: combo,
        flags: flags,
        action: action,
        args: args
    };
}

/**
 * Derives a human-readable label from a Niri action name + args.
 * Mirrors the style of deriveLabel() in binds.js.
 */
function deriveLabel(action, args) {
    switch (action) {
        case "spawn":
            var cmd = (args || "").trim().split(/\s+/)[0] || "spawn";
            return cmd.split("/").pop();
        case "quit":
            return "quit niri";
        case "toggle-overview":
            return "overview";
        case "toggle-keyboard-shortcuts-inhibit":
            return "toggle inhibit";
        case "power-off-monitors":
            return "power off monitors";
        case "maximize-column":
            return "maximize column";
        case "maximize-window-to-edges":
            return "maximize window";
        case "fullscreen-window":
            return "fullscreen";
        case "toggle-window-floating":
            return "toggle float";
        case "switch-focus-between-floating-and-tiling":
            return "switch focus layer";
        case "switch-preset-column-width":
            return "switch column width";
        case "reset-window-height":
            return "reset height";
        case "center-column":
            return "center column";
        case "center-visible-columns":
            return "center columns";
        case "expand-column-to-available-width":
            return "expand column";
        case "set-column-width":
            return "column width " + ((args || "").trim() || "?");
        case "set-window-height":
            return "window height " + ((args || "").trim() || "?");
        case "consume-or-expel-window-left":
            return "consume/expel left";
        case "consume-or-expel-window-right":
            return "consume/expel right";
        case "toggle-column-tabbed-display":
            return "toggle tabs";
        case "focus-column-left":
            return "focus left";
        case "focus-column-right":
            return "focus right";
        case "focus-window-up":
            return "focus up";
        case "focus-window-down":
            return "focus down";
        case "focus-column-first":
            return "focus first";
        case "focus-column-last":
            return "focus last";
        case "move-column-left":
            return "move left";
        case "move-column-right":
            return "move right";
        case "move-window-up":
            return "move up";
        case "move-window-down":
            return "move down";
        case "move-column-to-first":
            return "move to first";
        case "move-column-to-last":
            return "move to last";
        case "focus-monitor-left":
            return "monitor left";
        case "focus-monitor-right":
            return "monitor right";
        case "focus-monitor-up":
            return "monitor up";
        case "focus-monitor-down":
            return "monitor down";
        case "move-column-to-monitor-left":
            return "move to monitor left";
        case "move-column-to-monitor-right":
            return "move to monitor right";
        case "move-column-to-monitor-up":
            return "move to monitor up";
        case "move-column-to-monitor-down":
            return "move to monitor down";
        case "move-workspace-to-monitor-left":
            return "move ws to monitor left";
        case "focus-workspace":
            return "workspace " + ((args || "").trim() || "?");
        case "move-column-to-workspace":
            return "move to workspace " + ((args || "").trim() || "?");
        case "focus-workspace-down":
            return "workspace down";
        case "focus-workspace-up":
            return "workspace up";
        case "move-column-to-workspace-down":
            return "move ws down";
        case "move-column-to-workspace-up":
            return "move ws up";
        case "move-workspace-down":
            return "move workspace down";
        case "move-workspace-up":
            return "move workspace up";
        case "screenshot":
            return "screenshot";
        case "screenshot-screen":
            return "screenshot screen";
        case "screenshot-window":
            return "screenshot window";
        case "close-window":
            return "close window";
        default:
            return action;
    }
}

/**
 * Finds the name comment for a bind at the given line index.
 * Walks upward through contiguous `//` comment lines, skipping TODO comments
 * and header decorations. Returns the nearest non-TODO comment text, or "".
 */
function findNameComment(lines, bindLineIndex) {
    var name = "";
    for (var i = bindLineIndex - 1; i >= 0; i--) {
        var raw = lines[i];
        if (!isCommentLine(raw)) break;
        if (isHeaderComment(raw)) break;
        var text = stripComment(raw);
        if (/^TODO/i.test(text)) continue;
        name = text;
        break;
    }
    return name;
}

/**
 * Returns the range of comment lines directly above a bind line that
 * constitute its "name comment block". Returns { top, bottom } where
 * `top` is the first (topmost) comment line and `bottom` is the last
 * comment line (closest to the bind). Both are line indices.
 * Returns null if there is no comment block.
 */
function findNameCommentRange(lines, bindLineIndex) {
    var bottom = -1;
    var top = -1;
    // Walk upward from the bind to find all contiguous comment lines.
    // The first one we hit (highest index) is the bottom (closest to bind).
    // The last one we hit (lowest index) is the top (furthest from bind).
    for (var i = bindLineIndex - 1; i >= 0; i--) {
        var raw = lines[i];
        if (!isCommentLine(raw)) break;
        if (isHeaderComment(raw)) break;
        if (bottom === -1) bottom = i;
        top = i;
    }
    if (bottom === -1) return null;
    return { top: top, bottom: bottom };
}

/**
 * Rebuilds a Niri KDL bind line from its parts.
 */
function buildBindLine(combo, flags, action, args) {
    var line = combo;
    if (flags && flags.length) {
        line += " " + flags.join(" ");
    }
    line += " { " + action;
    if (args && args.length) {
        line += " " + args;
    }
    line += "; }";
    return line;
}

/**
 * Parses the full text of a Niri binds file.
 *
 * Returns an array of entry objects, each with:
 *   { combo, flags, action, args, name, label, lineIndex }
 *
 * - flags: array of raw "key=value" strings in original order (empty if none)
 * - name: the `//` comment above the bind (or "" if none found)
 * - label: name if present, otherwise deriveLabel(action, args)
 * - lineIndex: 0-based line number in the original text
 */
function parse(text) {
    var lines = text.split("\n");
    var out = [];
    for (var i = 0; i < lines.length; i++) {
        var parsed = parseBindLine(lines[i]);
        if (!parsed) continue;
        var name = findNameComment(lines, i);
        var label = name.length ? name : deriveLabel(parsed.action, parsed.args);
        out.push({
            combo: parsed.combo,
            flags: parsed.flags,
            action: parsed.action,
            args: parsed.args,
            name: name,
            label: label,
            lineIndex: i
        });
    }
    return out;
}

/**
 * Rebuilds a bind line with a new key combo.
 * Preserves flags, action, args, and the name comment above exactly as they were.
 */
function rebind(text, lineIndex, newCombo) {
    var lines = text.split("\n");
    if (lineIndex < 0 || lineIndex >= lines.length)
        return { text: text, ok: false, error: "invalid lineIndex" };
    var parsed = parseBindLine(lines[lineIndex]);
    if (!parsed)
        return { text: text, ok: false, error: "not a bind line" };
    lines[lineIndex] = buildBindLine(newCombo, parsed.flags, parsed.action, parsed.args);
    return { text: lines.join("\n"), ok: true, error: "" };
}

/**
 * Appends a new spawn-style bind at the end of the file.
 * Adds a `// name` comment on the line above the bind (matching Niri's convention).
 */
function add(text, combo, cmd, name) {
    if (!combo || !combo.length)
        return { text: text, ok: false, error: "empty combo" };
    if (!cmd || !cmd.length)
        return { text: text, ok: false, error: "empty command" };
    var sep = text.length === 0 || text.charAt(text.length - 1) === "\n" ? "" : "\n";
    var result = text + sep;
    if (name && name.length) {
        result += "// " + name + "\n";
    }
    result += buildBindLine(combo, [], "spawn", cmd) + "\n";
    return { text: result, ok: true, error: "" };
}

/**
 * Removes a bind line and its associated name comment line above it.
 * The name comment is only removed if it is a single comment line that
 * appears to describe only this bind (not a shared section header).
 * If in doubt, the comment is left and only the bind line is removed.
 */
function del(text, lineIndex) {
    var lines = text.split("\n");
    if (lineIndex < 0 || lineIndex >= lines.length)
        return { text: text, ok: false, error: "invalid lineIndex" };
    var parsed = parseBindLine(lines[lineIndex]);
    if (!parsed)
        return { text: text, ok: false, error: "not a bind line" };

    // Check for a name comment range above this bind
    var range = findNameCommentRange(lines, lineIndex);
    if (range) {
        // Only remove the comment if it's a single line (not a multi-line block
        // that might describe more than this bind).
        if (range.top === range.bottom) {
            lines.splice(range.top, 2); // remove comment + bind line
        } else {
            // Multi-line comment block — leave the comment, only remove the bind
            lines.splice(lineIndex, 1);
        }
    } else {
        lines.splice(lineIndex, 1);
    }
    return { text: lines.join("\n"), ok: true, error: "" };
}

/**
 * Updates the spawn command args, preserving everything else.
 */
function editCmd(text, lineIndex, cmd) {
    var lines = text.split("\n");
    if (lineIndex < 0 || lineIndex >= lines.length)
        return { text: text, ok: false, error: "invalid lineIndex" };
    var parsed = parseBindLine(lines[lineIndex]);
    if (!parsed)
        return { text: text, ok: false, error: "not a bind line" };
    lines[lineIndex] = buildBindLine(parsed.combo, parsed.flags, parsed.action, cmd);
    return { text: lines.join("\n"), ok: true, error: "" };
}

/**
 * Updates (or adds, if absent) the `//` comment line above the bind.
 */
function editName(text, lineIndex, name) {
    var lines = text.split("\n");
    if (lineIndex < 0 || lineIndex >= lines.length)
        return { text: text, ok: false, error: "invalid lineIndex" };
    var parsed = parseBindLine(lines[lineIndex]);
    if (!parsed)
        return { text: text, ok: false, error: "not a bind line" };

    var range = findNameCommentRange(lines, lineIndex);
    if (range) {
        // Replace the bottom (closest to bind) comment line with the new name
        lines[range.bottom] = "// " + name;
    } else {
        // Insert a new comment line above the bind
        lines.splice(lineIndex, 0, "// " + name);
    }
    return { text: lines.join("\n"), ok: true, error: "" };
}

/**
 * Replaces the action + args, preserving combo, flags, and name.
 */
function editAction(text, lineIndex, action) {
    var lines = text.split("\n");
    if (lineIndex < 0 || lineIndex >= lines.length)
        return { text: text, ok: false, error: "invalid lineIndex" };
    var parsed = parseBindLine(lines[lineIndex]);
    if (!parsed)
        return { text: text, ok: false, error: "not a bind line" };

    // Split the new action into action name and args
    var parts = action.split(/\s+/);
    var newAction = parts[0];
    var newArgs = parts.slice(1).join(" ");

    lines[lineIndex] = buildBindLine(parsed.combo, parsed.flags, newAction, newArgs);
    return { text: lines.join("\n"), ok: true, error: "" };
}