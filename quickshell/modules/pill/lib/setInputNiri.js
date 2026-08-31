/**
 * Niri KDL helpers for the Input surface.
 *
 * Reads and writes the small set of fields we care about inside
 *   $RICE_HOME/niri/config.d/10-input-and-cursor.kdl
 *
 * KDL value syntax we handle:
 *   - Quoted strings  : xcursor-theme "capitaine-cursors-light"
 *   - Numbers         : xcursor-size 24
 *   - Bare words      : tap
 *
 * getField / setField operate on the whole file text and match the first
 * occurrence of `name <value>`, which is safe because the field names we
 * touch (xcursor-theme, xcursor-size, accel-profile, accel-speed) are
 * unique across the config.d tree.
 */

/**
 * Read the current value of a KDL `name <value>` field, ignoring lines that
 * are commented out with `//`. Quoted values are returned unquoted; bare
 * words / numbers are trimmed. Returns "" when the field is absent or only
 * present in comments.
 */
function getField(text, name) {
    // Match: name "quoted"  or  name 123  or  name 0.0
    // The line-prefix group lets us skip commented lines.
    var re = new RegExp("(^|\\n)([^\\n]*?)\\b" + name + "\\s+(\"[^\"]*\"|[^\\s\\n}\\]]+)", "g");
    var m;
    while ((m = re.exec(text)) !== null) {
        // m[2] is everything on the line before the field name.
        // If that prefix contains an unquoted `//`, the line is commented out.
        var prefix = m[2];
        var inStr = false;
        var commentSlash = false;
        for (var i = 0; i < prefix.length; i++) {
            var ch = prefix.charAt(i);
            if (ch === "\"") {
                inStr = !inStr;
            } else if (ch === "/" && !inStr && prefix.charAt(i + 1) === "/") {
                commentSlash = true;
                break;
            }
        }
        if (!commentSlash) {
            var v = m[3].trim();
            if (v.length >= 2 && v.charAt(0) === "\"" && v.charAt(v.length - 1) === "\"")
                return v.slice(1, -1);
            return v;
        }
    }
    return "";
}

/**
 * Replace the value of a KDL `name <value>` field in place, skipping lines
 * that are commented out with `//`. `valueLiteral` is the already-formatted
 * replacement:
 *   - a number  → "24"
 *   - a string  → "\"capitaine-cursors-light\""  (caller adds quotes)
 *
 * Returns { text, ok } where ok is false when the field is absent or only
 * present in comments.
 */
function setField(text, name, valueLiteral) {
    // Capture groups: 1 = line start, 2 = prefix + field name + trailing ws, 3 = old value
    var re = new RegExp("(^|\\n)([^\\n]*?\\b" + name + "\\s+)(\"[^\"]*\"|[^\\s\\n}\\]]+)", "g");
    var m;
    while ((m = re.exec(text)) !== null) {
        var prefix = m[2]; // includes the field name and whitespace before the value
        // Check for an unquoted `//` before the field name on the same line.
        var inStr = false;
        var commentSlash = false;
        for (var i = 0; i < prefix.length; i++) {
            var ch = prefix.charAt(i);
            if (ch === "\"") {
                inStr = !inStr;
            } else if (ch === "/" && !inStr && prefix.charAt(i + 1) === "/") {
                commentSlash = true;
                break;
            }
        }
        if (!commentSlash) {
            // Build a non-global replacement regex so we only touch this one line.
            var replaceRe = new RegExp("(^|\\n)([^\\n]*?\\b" + name + "\\s+)(\"[^\"]*\"|[^\\s\\n}\\]]+)");
            return { text: text.replace(replaceRe, "$1" + prefix + valueLiteral), ok: true };
        }
    }
    return { text: text, ok: false };
}

/**
 * Ensure the `cursor { ... }` block contains the two fields we manage.
 * If the block is missing it is appended; otherwise existing fields are
 * updated in place. Returns the updated full text.
 *
 * IMPORTANT: This function removes any existing active or commented
 * `xcursor-theme` / `xcursor-size` lines inside the cursor block before
 * inserting the new values. This prevents duplicate-node parse errors
 * in Niri's KDL parser.
 */
function upsertCursorBlock(text, theme, size) {
    var themeLit = "\"" + theme + "\"";
    var sizeLit = String(size);

    var cursorRe = /cursor\s*\{/;
    var blockStart = cursorRe.exec(text);
    if (!blockStart) {
        // No cursor block — append one.
        var sep = text.length === 0 || text.charAt(text.length - 1) === "\n" ? "\n" : "\n\n";
        return text + sep + "cursor {\n    xcursor-theme " + themeLit + "\n    xcursor-size " + sizeLit + "\n}\n";
    }

    // Find the matching closing brace.
    var open = text.indexOf("{", blockStart.index);
    var depth = 0;
    var close = -1;
    for (var i = open; i < text.length; i++) {
        var c = text.charAt(i);
        if (c === "{") depth++;
        else if (c === "}") {
            depth--;
            if (depth === 0) { close = i; break; }
        }
    }
    if (close === -1)
        return text; // malformed — bail out, do not clobber

    var body = text.slice(blockStart.index, close + 1);

    // ── Deduplicate: remove any existing xcursor-theme / xcursor-size lines
    // (active or commented) so the cursor block never holds more than one
    // of each. Niri's KDL parser rejects duplicate property nodes.
    body = body.replace(/^\s*\/\/\s*xcursor-(theme|size)\s+.*$/gm, "");
    body = body.replace(/^\s*xcursor-(theme|size)\s+.*$/gm, "");

    // Collapse excessive blank lines left by the removals, but keep the
    // block readable.
    body = body.replace(/\n{3,}/g, "\n\n");
    // Trim trailing whitespace on each line.
    body = body.replace(/[ \t]+$/gm, "");

    // Insert the new fields immediately after the opening brace.
    body = body.replace(/\{/, "{\n    xcursor-theme " + themeLit + "\n    xcursor-size " + sizeLit);

    return text.slice(0, blockStart.index) + body + text.slice(close + 1);
}

/**
 * Ensure the `input { ... }` block contains the `mouse { ... }` sub-block
 * with accel-profile and accel-speed. Missing blocks are created.
 * Returns the updated full text.
 *
 * IMPORTANT: This function removes any existing active or commented
 * `accel-profile` / `accel-speed` lines inside the mouse block before
 * inserting the new values. This prevents duplicate-node parse errors
 * in Niri's KDL parser when a previously-commented line is uncommented
 * manually or when the function is called multiple times.
 */
function upsertMouseBlock(text, profile, speed) {
    var profileLit = "\"" + profile + "\"";
    var speedLit = String(speed);

    var inputRe = /input\s*\{/;
    var inputStart = inputRe.exec(text);
    if (!inputStart) {
        var sep = text.length === 0 || text.charAt(text.length - 1) === "\n" ? "\n" : "\n\n";
        return text + sep + "input {\n    mouse {\n        accel-profile " + profileLit + "\n        accel-speed " + speedLit + "\n    }\n}\n";
    }

    // Find the matching closing brace for `input {`.
    var open = text.indexOf("{", inputStart.index);
    var depth = 0;
    var close = -1;
    for (var i = open; i < text.length; i++) {
        var c = text.charAt(i);
        if (c === "{") depth++;
        else if (c === "}") {
            depth--;
            if (depth === 0) { close = i; break; }
        }
    }
    if (close === -1)
        return text;

    var body = text.slice(inputStart.index, close + 1);

    // Find or create the mouse { ... } sub-block.
    var mouseRe = /mouse\s*\{/;
    var mouseMatch = mouseRe.exec(body);
    var mouseBody;
    if (mouseMatch) {
        var mouseOpen = body.indexOf("{", mouseMatch.index);
        var mDepth = 0;
        var mouseClose = -1;
        for (var j = mouseOpen; j < body.length; j++) {
            var ch = body.charAt(j);
            if (ch === "{") mDepth++;
            else if (ch === "}") {
                mDepth--;
                if (mDepth === 0) { mouseClose = j; break; }
            }
        }
        if (mouseClose === -1)
            return text;
        mouseBody = body.slice(mouseMatch.index, mouseClose + 1);
    } else {
        // Append a mouse block inside input.
        mouseBody = "    mouse {\n        accel-profile " + profileLit + "\n        accel-speed " + speedLit + "\n    }";
        body = body.replace(/\}$/, "\n" + mouseBody + "\n}");
        return text.slice(0, inputStart.index) + body + text.slice(close + 1);
    }

    // ── Deduplicate: remove any existing accel-profile / accel-speed lines
    // (active or commented) so the mouse block never holds more than one
    // of each. Niri's KDL parser rejects duplicate property nodes.
    mouseBody = mouseBody.replace(/^\s*\/\/\s*accel-(profile|speed)\s+.*$/gm, "");
    mouseBody = mouseBody.replace(/^\s*accel-(profile|speed)\s+.*$/gm, "");

    // Collapse excessive blank lines left by the removals, but keep the
    // block readable.
    mouseBody = mouseBody.replace(/\n{3,}/g, "\n\n");
    // Trim trailing whitespace on each line.
    mouseBody = mouseBody.replace(/[ \t]+$/gm, "");

    // Insert the new fields immediately after the opening brace.
    mouseBody = mouseBody.replace(/\{/, "{\n        accel-profile " + profileLit + "\n        accel-speed " + speedLit);

    return text.slice(0, inputStart.index) + body.slice(0, mouseMatch.index) + mouseBody + body.slice(mouseClose + 1) + text.slice(close + 1);
}
