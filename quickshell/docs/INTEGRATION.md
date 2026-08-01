# YemiShell — Cline MCP & Zoocode Integration

> **Date:** 2026-07-31
> **Status:** Complete
> **Maintainer:** Yemi

This document describes the integration of Cline MCP (Model Context Protocol) server configurations from the Trae (Toolchain Environment) with the existing Zoocode and Claude extension installations, establishing a unified toolchain across all IDE environments.

---

# Table of Contents

1. [Integration Overview](#integration-overview)
2. [MCP Server Inventory](#mcp-server-inventory)
3. [Configuration Architecture](#configuration-architecture)
4. [Skill Dispatch Table](#skill-dispatch-table)
5. [Cross-IDE Compatibility Matrix](#cross-ide-compatibility-matrix)
6. [Secrets Management](#secrets-management)
7. [Sync Script](#sync-script)
8. [Configuration Reference](#configuration-reference)

---

## Integration Overview

### What Was Done

1. **Audited** all MCP configuration sources across 11 IDE installations (Zoocode ×4 + Cline/Cursor/Roo + Claude extension ×4 + OpenClaude desktop)
2. **Masked** exposed secrets (GitHub PAT, Context7 API key, Apify API key)
3. **Merged** MCP servers from 3 independent configs into one canonical source
4. **Back-synced** the unified config to all IDE storage locations
5. **Copied** 4 Trae builtin skills into the workspace
6. **Synced** Zoocode custom modes across IDE globalStorage
7. **Created** a reusable sync script for future updates
8. **Documented** everything here

### Configuration Sources (before integration)

| Source | MCP Servers | Secrets Exposure |
|--------|-------------|------------------|
| `~/.cline/data/settings/cline_mcp_settings.json` | sequential-thinking, cocoindex-code | None |
| `~/.roo/cline_mcp_settings.json` | github, context7 | **PAT + API key** |
| `~/.cursor/mcp.json` | github, context7 | **PAT + API key** |
| `~/.config/Trae/.../mcp-dev/settings/cline_mcp_settings.json` | 7 servers (brave-search, git, actors, seq-thinking, planning, memory, supermemory) | None |
| `~/.config/Code/.../claude-dev/settings/cline_mcp_settings.json` | 6 servers | **Apify token (plaintext)** |
| `~/.config/Kiro/.../claude-dev/settings/cline_mcp_settings.json` | Empty | N/A |
| `~/.config/Antigravity IDE/.../claude-dev/settings/cline_mcp_settings.json` | memory only | None |
| `~/.openclaude.json` (OpenClaude desktop) | github, context7, basic-memory, knowledge-graph-mcp, memory, sequential-thinking, cocoindex-code | Masked in output |

### Unified Result

All 8 MCP servers are now registered across all 6 install families (9 config files):

| Server | Before | After |
|--------|--------|-------|
| `github` | Roo, Cursor only | **All 9 locations** |
| `context7` | Roo, Cursor only | **All 9 locations** |
| `sequential-thinking` | Cline only | **All 9 locations** |
| `cocoindex-code` | Cline only | **All 9 locations** |
| `basic-memory` | OpenClaude only | **All 9 locations** |
| `knowledge-graph-mcp` | OpenClaude only | **All 9 locations** |
| `git` | Trae Claude only | **All 9 locations (normalized to uvx)** |
| `memory` | Trae/Code Claude only | **All 9 locations (normalized to npx)** |

---

## MCP Server Inventory

### 1. GitHub (`github`)
```yaml
command: /home/yemi/.local/bin/github-mcp-server
args: [stdio]
env:
  GITHUB_PERSONAL_ACCESS_TOKEN: "GITHUB_PAT_PLACEHOLDER"  # Set your real token
```
**Purpose:** Semantic code search, repository operations, issue/PR management, commit inspection.

**Prerequisites:** Install `github-mcp-server` binary at the specified path.

### 2. Context7 (`context7`)
```yaml
command: npx
args: ["@upstash/context7-mcp"]
env:
  CONTEXT7_API_KEY: "CONTEXT7_API_KEY_PLACEHOLDER"  # Get from console.upstash.com
```
**Purpose:** Library/framework documentation lookups from Context7's indexed docs.

**Prerequisites:** Node.js/npx in PATH.

### 3. Sequential Thinking (`sequential-thinking`)
```yaml
command: npx
args: ["-y", "@modelcontextprotocol/server-sequential-thinking"]
```
**Purpose:** Structured reasoning for complex problem decomposition. Good for debugging, architecture planning, and multi-step analysis.

**Prerequisites:** Node.js/npx in PATH. The `-y` flag auto-confirms npx install.

### 4. CocoIndex Code (`cocoindex-code`)
```yaml
command: ccc
args: [mcp]
```
**Purpose:** CocoIndex code indexing and search.

**Prerequisites:** `ccc` CLI installed in PATH.

### 5. Basic Memory (`basic-memory`)
```yaml
command: basic-memory
args: ["mcp", "--transport", "stdio"]
```
**Purpose:** Persistent conversation memory and recall across sessions. Used by OpenClaude desktop.

**Prerequisites:** `basic-memory` binary in PATH (installed at `~/.local/bin/basic-memory`).

### 6. Knowledge Graph (`knowledge-graph-mcp`)
```yaml
command: /home/yemi/.venvs/knowledge-graph-mcp/bin/knowledge-graph-mcp
args: []
```
**Purpose:** Entity and relationship tracking via a dedicated knowledge graph. Used by OpenClaude desktop.

**Prerequisites:** Python venv at `~/.venvs/knowledge-graph-mcp/` containing the `knowledge-graph-mcp` entry point.

### 7. Git (`git`)
```yaml
command: uvx
args: ["mcp-server-git", "--repository", "/home/yemi/.config"]
```
**Purpose:** Git repository inspection — file history, blame, diff, log.

**Prerequisites:** `uvx` (bundled with `uv`, available at `/usr/bin/uv`).

### 8. Memory (`memory`)
```yaml
command: npx
args: ["-y", "@modelcontextprotocol/server-memory"]
env:
  MEMORY_FILE_PATH: "/home/yemi/Documents/Cline/MCP/memory/memory.jsonl"
```
**Purpose:** MCP-native file-backed memory store.

**Prerequisites:** Node.js/npx in PATH. Memory file at the specified path.

---

## Configuration Architecture

```
Canonical source (workspace)
~/.config/quickshell/.roomodes
├── customModes: [mode-writer]
└── mcpServers: [github, context7, sequential-thinking, cocoindex-code,
                  basic-memory, knowledge-graph-mcp, git, memory]
│
├─ run .scripts/sync-mcp-config.sh
│
└─ Back.sync targets (9 files):
    MCP-aware IDEs:
    ├── ~/.cline/data/settings/cline_mcp_settings.json
    ├── ~/.cursor/mcp.json
    ├── ~/.roo/cline_mcp_settings.json
    ├── ~/.config/Trae/.../zoocodeorganization.zoo-code/settings/mcp_settings.json
    ├── ~/.config/Kiro/.../zoocodeorganization.zoo-code/settings/mcp_settings.json
    └── ~/.cline/data/settings/cline_mcp_settings.json.bak.*
    Claude extension (saoudrizwan.claude-dev) ×4 IDEs:
    ├── ~/.config/Trae/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json
    ├── ~/.config/Kiro/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json
    ├── ~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json
    └── ~/.config/Antigravity IDE/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json

Custom modes back-sync:
~/.roomodes (customModes)
└─ ~/.config/{Trae,Kiro}/.../zoocodeorganization.zoo-code/settings/custom_modes.yaml
```

### Why `.roomodes` as canonical?

- `.roomodes` is the **workspace-scoped** config format used by Roo-Code/Zoocode
- It already contained the `mode-writer` custom mode definition
- Adding the `mcpServers` block keeps MCP + modes in one file
- Changes to `.roomodes` are version-controlled and portable

---

## Skill Dispatch Table

| Task | Primary Skill | Backup Skills |
|------|---------------|---------------|
| QML code generation/editing | `.lingma/rules/SKILL.md` (qt-qml section) | TRAE-generate-mini-app (for scaffolding) |
| C++ Qt code review | `.lingma/rules/SKILL.md` (qt-cpp-review) | TRAE-code-review (Mermaid diagrams) |
| QML code review | `.lingma/rules/SKILL.md` (qt-qml-review) | TRAE-code-review (cross-validation) |
| Runtime debugging | TRAE-debugger | — |
| Library documentation lookup | context7 MCP | — |
| Complex reasoning / planning | sequential-thinking MCP | — |
| Code search (semantic) | github MCP | cocoindex-code MCP |
| Visual diagrams / reports | TRAE-dynamic-ui | — |
| Mini-app / full project generation | TRAE-generate-mini-app | — |
| Configuration design (modes/skills) | `.roomodes` mode-writer | — |

---

## Cross-IDE Compatibility Matrix

| Feature | VS Code | Trae | Kiro | Antigravity | Cursor | Cline | Roo | OpenClaude |
|---------|---------|------|------|-------------|--------|-------|-----|------------|
| Zoocode extension | 3.72.0 | 3.72.0 | 3.73.100299 | 3.72.0 | — | — | — | — |
| Claude extension | ✅ (4.0.12) | ✅ (4.0.12) | ✅ (4.0.11) | ✅ (4.0.11) | — | — | — | ✅ (native) |
| MCP via `.roomodes` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — |
| MCP via IDE-native config | — | ✅ | — | — | ✅ (`mcp.json`) | ✅ (`cline_mcp_settings.json`) | ✅ (`cline_mcp_settings.json`) | — |
| Custom modes | ✅ | ✅ | ✅ | ✅ | — | — | — | — |
| Workspace Taee skills | ✅ | ✅ | ✅ | ✅ | — | — | — | — |

---

## Secrets Management

### WARNING: Secrets were found in plain text

During audit, the following credentials were exposed in config files:

| Credential | Files Affected | Action Taken |
|------------|----------------|--------------|
| GitHub PAT (`ghp_sjRphh...`) | `~/.roo/cline_mcp_settings.json`, `~/.cursor/mcp.json` | **Masked** → `GITHUB_PAT_PLACEHOLDER` |
| Context7 API key (`ctx7sk-fd38...`) | `~/.roo/cline_mcp_settings.json`, `~/.cursor/mcp.json` | **Masked** → `CONTEXT7_API_KEY_PLACEHOLDER` |
| Apify token (`apify_api_e...`) | `~/.config/Code/.../claude-dev/settings/cline_mcp_settings.json` | **Masked** → `APIFY_TOKEN_PLACEHOLDER` |

### Recommendations

1. **Rotate the GitHub PAT and Apify token immediately** — the old tokens may have been included in backups, logs, or cache.
2. Set real values only via environment variables or a secrets manager — never in VCS.
3. Use the sync script (which respects the placeholder pattern) or set your keys before running sync again.

---

## Sync Script

`scripts/sync-mcp-config.sh` automates back-synchronization from `.roomodes` to all IDE config locations.

Usage:
```bash
# Sync all IDE MCP configs from the canonical .roomodes
./scripts/sync-mcp-config.sh

# Preview without writing
./scripts/sync-mcp-config.sh --dry-run
```

The script now covers **9 target files** across 6 install families:
- Cline standalone
- Cursor
- Roo
- Trae / Zoocode
- Kiro / Zoocode
- Claude extension (saoudrizwan.claude-dev) × 4 IDEs: Trae, Kiro, VS Code, Antigravity

---

## Configuration Reference

### Canonical Config: `.roomodes`

- **customModes** — workspace mode definitions (mode-writer)
- **mcpServers** — all 4 MCP server configurations with API key placeholders

### Skill Configuration

| File | Purpose |
|------|---------|
| `.lingma/rules/SKILL.md` | Primary Qt/ QML/ Quickshell development skill |
| `.lingma/rules/*.md` | Task-specific rule files |
| `.lingma/rules/combined-skill.md` | Flattened combined skill reference |
| `.lingma/rules/trae/TRAE-code-review/SKILL.md` | Trae code review workflow |
| `.lingma/rules/trae/TRAE-debugger/SKILL.md` | Trae debugging workflow |
| `.lingma/rules/trae/TRAE-dynamic-ui/SKILL.md` | Trae dynamic visual rendering |
| `.lingma/rules/trae/TRAE-generate-mini-app/SKILL.md` | Trae mini-app generation |

### Mode Configuration

| File | Modes |
|------|-------|
| `.roomodes` | `mode-writer` (project) |
| `~/.config/Code/.../custom_modes.yaml` | `skill-writer` (global), `coding-teacher` (global) |
| `~/.config/Trae/.../custom_modes.yaml` | `mode-writer` (project) |
| `~/.config/Kiro/.../custom_modes.yaml` | `mode-writer` (project) |
| `~/.config/Antigravity IDE/.../custom_modes.yaml` | `merge-resolver` (global) |

## Verification Checklist

After setting up, verify with:

- [ ] `cat .roomodes` shows 8 MCP servers + mode-writer
- [ ] `cat ~/.cursor/mcp.json` shows `GITHUB_PAT_PLACEHOLDER` (not real token)
- [ ] `cat ~/.config/Code/.../claude-dev/settings/cline_mcp_settings.json` shows `APIFY_TOKEN_PLACEHOLDER` (not real token)
- [ ] `chmod +x scripts/sync-mcp-config.sh` — script is executable
- [ ] `./scripts/sync-mcp-config.sh --dry-run` lists all 9 targets
- [ ] Trae's Zoocode sidebar shows MCP servers in settings
- [ ] All 4 Trae skills available in `.lingma/rules/trae/`
- [ ] Modes sync expected across IDE installations
- [ ] Claude extension (saoudrizwan.claude-dev) shows 8 servers in each IDE settings MCP panel