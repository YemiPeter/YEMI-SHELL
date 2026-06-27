/**
 * Fuzzy search implementation for the launcher.
 * Ported from Ricelin — identical logic, no changes needed.
 */

function rank(entries, query, usage) {
    if (!query || query.length === 0)
        return entries.slice(0, 20);

    const q = query.toLowerCase();
    const scored = entries.map((entry, idx) => {
        let score = 0;
        const name = (entry.name || "").toLowerCase();
        const generic = (entry.genericName || "").toLowerCase();
        const exec = (entry.exec || "").toLowerCase();
        const id = (entry.id || "").toLowerCase();

        // Exact match
        if (name === q) score += 100;
        // Starts with
        else if (name.startsWith(q)) score += 80;
        // Contains
        else if (name.includes(q)) score += 60;
        // Generic name match
        else if (generic.includes(q)) score += 50;
        // Exec basename match
        else if (exec.includes(q)) score += 40;
        // ID match
        else if (id.includes(q)) score += 30;
        // Fuzzy character sequence
        else {
            let qi = 0;
            let matched = 0;
            for (let i = 0; i < name.length && qi < q.length; i++) {
                if (name[i] === q[qi]) {
                    matched++;
                    qi++;
                }
            }
            if (qi === q.length) score += 20 + matched;
        }

        // Usage boost
        const use = usage[entry.id];
        if (use) score += Math.min(20, Math.log2(use + 1) * 5);

        return { entry, score, idx };
    });

    scored.sort((a, b) => b.score - a.score || a.idx - b.idx);
    return scored.filter(s => s.score > 0).map(s => s.entry);
}
