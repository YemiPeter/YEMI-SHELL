/**
 * Reads the current value of a `name = <value>` Lua field. A double-quoted value
 * is returned unquoted; any other run is trimmed. Returns "" when the field is
 * absent.
 */
function getField(text, name) {
    var re = new RegExp(name + "\\s*=\\s*(\"[^\"]*\"|[^,}\\n]*)");
    var m = re.exec(text);
    if (!m)
        return "";
    var v = m[1].trim();
    if (v.length >= 2 && v.charAt(0) === "\"" && v.charAt(v.length - 1) === "\"")
        return v.slice(1, -1);
    return v;
}

/**
 * Reads the value of an `hl.env("KEY", "VALUE")` call. Returns the second
 * argument unquoted, or "" when the key's env call is absent.
 *
 * This is deliberately separate from getField: hl.env takes POSITIONAL
 * arguments, so a `KEY = VALUE` pattern can never match it. The old hyprlang
 * form was `env = KEY,VALUE`, and after the 0.57 Lua migration the file holds
 * hl.env("KEY", "VALUE") instead — reading it with the `name =` pattern (or
 * writing it with setEnv's old `env = KEY,` replacement) silently found
 * nothing, which is what broke the Input surface's cursor rows.
 *
 * The key match is anchored with the opening quote so XCURSOR_SIZE cannot match
 * inside HYPRCURSOR_SIZE.
 */
function getEnv(text, key) {
    var re = new RegExp("hl\\.env\\(\\s*\"" + escapeRe(key) + "\"\\s*,\\s*(\"[^\"]*\"|[^)\\n]*)");
    var m = re.exec(text);
    if (!m)
        return "";
    var v = m[1].trim();
    if (v.length >= 2 && v.charAt(0) === "\"" && v.charAt(v.length - 1) === "\"")
        return v.slice(1, -1);
    return v;
}

/**
 * Replaces the value of a single `name = <value>` field in place, preserving the
 * field name, the `=` spacing and any trailing comma. A quoted value run is taken
 * whole so a comma inside the quotes is not mistaken for the field end; otherwise
 * the run goes up to the next comma, brace or newline. `valueLiteral` is already
 * formatted by the caller (a number/bool as-is, a string already double-quoted).
 * Returns `{ text, ok }`; ok is false (text unchanged) when the field is absent.
 */
function setField(text, name, valueLiteral) {
    var re = new RegExp("(" + name + "\\s*=\\s*)(\"[^\"]*\"|[^,}\\n]*)");
    if (!re.test(text))
        return { text: text, ok: false };
    return { text: text.replace(re, "$1" + valueLiteral), ok: true };
}

/**
 * Replaces the value of an `hl.env("KEY", "<old>")` call, re-quoted, keeping the
 * key and the existing `, ` separator. Returns `{ text, ok }`; ok is false when
 * the key's env call is absent.
 *
 * `valueRaw` is the value the caller wants, quoting included (e.g. `"14"`), and
 * is inserted verbatim so callers keep the same formatting contract as
 * setField. Only the value run is replaced — the key, the comma and the spacing
 * before the value stay byte-identical, so the file's alignment is preserved.
 */
function setEnv(text, key, valueRaw) {
    var re = new RegExp("(hl\\.env\\(\\s*\"" + escapeRe(key) + "\"\\s*,\\s*)(\"[^\"]*\"|[^)\\n]*)");
    if (!re.test(text))
        return { text: text, ok: false };
    return { text: text.replace(re, "$1" + valueRaw), ok: true };
}

/**
 * Replaces the theme name and size in a `hyprctl setcursor <theme> <size>` call.
 * Returns `{ text, ok }`; ok is false when the call is absent.
 */
function setCursorLine(text, theme, size) {
    var re = /setcursor\s+\S+\s+\d+/;
    if (!re.test(text))
        return { text: text, ok: false };
    return { text: text.replace(re, "setcursor " + theme + " " + size), ok: true };
}

function escapeRe(s) {
    return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
