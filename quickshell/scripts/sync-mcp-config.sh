#!/usr/bin/env bash
#
# sync-mcp-config.sh — Re-syncs the unified MCP server configuration to
# all known IDE storage locations from a single canonical source.
#
# Canonical source of truth:  .roomodes  (mcpServers YAML block)
# This script propagates to:  Cline, Cursor, Roo, Trae/Zoocode, Kiro/Zoocode,
#                            Claude extension (saoudrizwan.claude-dev × 4 IDEs)
#
# Targets updated:
#   Cline (standalone) → ~/.cline/data/settings/cline_mcp_settings.json
#   Cursor            → ~/.cursor/mcp.json
#   Roo               → ~/.roo/cline_mcp_settings.json
#   Trae / Zoocode    → ~/.config/Trae/User/globalStorage/zoocodeorganization.zoo-code/settings/mcp_settings.json
#   Kiro / Zoocode    → ~/.config/Kiro/.../zoocodeorganization.zoo-code/settings/mcp_settings.json
#   Trae / Claude     → ~/.config/Trae/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json
#   Kiro / Claude     → ~/.config/Kiro/.../saoudrizwan.claude-dev/settings/cline_mcp_settings.json
#   VS Code / Claude  → ~/.config/Code/.../saoudrizwan.claude-dev/settings/cline_mcp_settings.json
#   Antigravity/Claude→ ~/.config/Antigravity IDE/.../saoudrizwan.claude-dev/settings/cline_mcp_settings.json
#
# Usage:
#   scripts/sync-mcp-config.sh            Sync all targets (writes changes)
#   scripts/sync-mcp-config.sh --dry-run  Preview changes without writing
#
# NOTE: Placeholder tokens (GITHUB_PAT_PLACEHOLDER / CONTEXT7_API_KEY_PLACEHOLDER)
#       are used for security. Replace them with real values via each IDE's
#       configuration UI after the first sync.
#
# Requires: bash ≥4, python3 (optional, for JSON formatting)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

info() { printf '[INFO]  %s\n' "$*"; }
ok()   { printf '[  OK]  %s\n' "$*"; }
warn() { printf '[WARN]  %s\n' "$*" >&2; }

# ──────────────────────────────────────────────────────────────────────────────
# Validate that the canonical .roomodes exists (human-readable source of truth)
# ──────────────────────────────────────────────────────────────────────────────
if [[ -f "$WORKSPACE_ROOT/.roomodes" ]]; then
  info "Canonical .roomodes found at $WORKSPACE_ROOT/.roomodes"
else
  warn "No .roomodes at $WORKSPACE_ROOT/.roomodes — syncing from embedded config"
fi

# ──────────────────────────────────────────────────────────────────────────────
# Per-target complete JSON payloads
# Each heredoc is the full final file content (already includes mcpServers /
# servers wrapper).  Mirror changes in .roomodes mcpServers block too.
# ──────────────────────────────────────────────────────────────────────────────

_STD_PAYLOAD() {
cat << 'JSONEOF'
{
  "mcpServers": {
    "github": {
      "command": "/home/yemi/.local/bin/github-mcp-server",
      "args": ["stdio"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "GITHUB_PAT_PLACEHOLDER"
      },
      "disabled": false,
      "autoApprove": []
    },
    "context7": {
      "command": "npx",
      "args": ["@upstash/context7-mcp"],
      "env": {
        "CONTEXT7_API_KEY": "CONTEXT7_API_KEY_PLACEHOLDER"
      },
      "disabled": false,
      "autoApprove": []
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
      "env": {},
      "disabled": false,
      "autoApprove": []
    },
    "cocoindex-code": {
      "command": "ccc",
      "args": ["mcp"],
      "env": {},
      "disabled": false,
      "autoApprove": ["search"]
    },
    "basic-memory": {
      "command": "basic-memory",
      "args": ["mcp", "--transport", "stdio"],
      "env": {},
      "disabled": false,
      "autoApprove": []
    },
    "knowledge-graph-mcp": {
      "command": "/home/yemi/.venvs/knowledge-graph-mcp/bin/knowledge-graph-mcp",
      "args": [],
      "env": {},
      "disabled": false,
      "autoApprove": []
    },
    "git": {
      "command": "uvx",
      "args": ["mcp-server-git", "--repository", "/home/yemi/.config"],
      "env": {},
      "disabled": false,
      "autoApprove": []
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": {
        "MEMORY_FILE_PATH": "/home/yemi/Documents/Cline/MCP/memory/memory.jsonl"
      },
      "disabled": false,
      "autoApprove": []
    }
  }
}
JSONEOF
}

_CURSOR_PAYLOAD() {
cat << 'JSONEOF'
{
  "servers": {
    "github": {
      "command": "/home/yemi/.local/bin/github-mcp-server",
      "args": ["stdio"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "GITHUB_PAT_PLACEHOLDER"
      },
      "disabled": false,
      "autoApprove": []
    },
    "context7": {
      "command": "npx",
      "args": ["@upstash/context7-mcp"],
      "env": {
        "CONTEXT7_API_KEY": "CONTEXT7_API_KEY_PLACEHOLDER"
      },
      "disabled": false,
      "autoApprove": []
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
      "env": {},
      "disabled": false,
      "autoApprove": []
    },
    "cocoindex-code": {
      "command": "ccc",
      "args": ["mcp"],
      "env": {},
      "disabled": false,
      "autoApprove": ["search"]
    },
    "basic-memory": {
      "command": "basic-memory",
      "args": ["mcp", "--transport", "stdio"],
      "env": {},
      "disabled": false,
      "autoApprove": []
    },
    "knowledge-graph-mcp": {
      "command": "/home/yemi/.venvs/knowledge-graph-mcp/bin/knowledge-graph-mcp",
      "args": [],
      "env": {},
      "disabled": false,
      "autoApprove": []
    },
    "git": {
      "command": "uvx",
      "args": ["mcp-server-git", "--repository", "/home/yemi/.config"],
      "env": {},
      "disabled": false,
      "autoApprove": []
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": {
        "MEMORY_FILE_PATH": "/home/yemi/Documents/Cline/MCP/memory/memory.jsonl"
      },
      "disabled": false,
      "autoApprove": []
    }
  }
}
JSONEOF
}

# ──────────────────────────────────────────────────────────────────────────────
# sync_one <path> <label>
# Writes the appropriate payload to <path>, creating parent dirs as needed.
# ──────────────────────────────────────────────────────────────────────────────
sync_one() {
  local dest="$1"
  local label="$2"
  local payload_fn="$3"   # name of the function that prints the JSON
  local dir
  dir="$(dirname "$dest")"

  if [[ ! -d "$dir" ]]; then
    warn "Directory missing: $dir — skipping $label"
    return 1
  fi

  # Detect whether this file previously contained live secrets
  local had_secrets="no"
  if [[ -f "$dest" ]] && grep -qF 'GITHUB_PERSONAL_ACCESS_TOKEN' "$dest" 2>/dev/null; then
    if ! grep -q 'GITHUB_PAT_PLACEHOLDER' "$dest" 2>/dev/null; then
      had_secrets="yes"
    fi
  fi

  if [[ -f "$dest" ]]; then
    if [[ "$had_secrets" == "yes" ]]; then
      warn "Overwriting $label (had live secrets — placeholders will be used)"
    else
      info "Updating $label"
    fi
  else
    info "Creating $label"
  fi

  if $DRY_RUN; then
    info "  [dry-run] Would write → $dest"
    return 0
  fi

  "$payload_fn" > "$dest"
  ok "Synced → $dest"
}

# ──────────────────────────────────────────────────────────────────────────────
# Optional: pretty-print JSON using python3 (falls back to raw if unavailable)
# ──────────────────────────────────────────────────────────────────────────────
prettify() {
  if command -v python3 &>/dev/null; then
    python3 -c 'import sys,json; json.dump(json.load(sys.stdin), sys.stdout, indent=2); print()'
  else
    cat   # pass through unchanged
  fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Dry-run banner
# ──────────────────────────────────────────────────────────────────────────────
if $DRY_RUN; then
  info "=== DRY-RUN MODE — no files will be modified ==="
fi

# ──────────────────────────────────────────────────────────────────────────────
# Sync all 9 targets
# Order: Cline standalone → Cursor → Roo → Trae/Zoocode → Kiro/Zoocode
#        → Claude ×4 (Trae, Kiro, VS Code, Antigravity)
# ──────────────────────────────────────────────────────────────────────────────

sync_one \
  "$HOME/.cline/data/settings/cline_mcp_settings.json" \
  "Cline standalone" \
  _STD_PAYLOAD

sync_one \
  "$HOME/.cursor/mcp.json" \
  "Cursor" \
  _CURSOR_PAYLOAD

sync_one \
  "$HOME/.roo/cline_mcp_settings.json" \
  "Roo" \
  _STD_PAYLOAD

sync_one \
  "$HOME/.config/Trae/User/globalStorage/zoocodeorganization.zoo-code/settings/mcp_settings.json" \
  "Trae / Zoocode" \
  _STD_PAYLOAD

sync_one \
  "$HOME/.config/Kiro/User/globalStorage/zoocodeorganization.zoo-code/settings/mcp_settings.json" \
  "Kiro / Zoocode" \
  _STD_PAYLOAD

sync_one \
  "$HOME/.config/Trae/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json" \
  "Trae / Claude" \
  _STD_PAYLOAD

sync_one \
  "$HOME/.config/Kiro/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json" \
  "Kiro / Claude" \
  _STD_PAYLOAD

sync_one \
  "$HOME/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json" \
  "VS Code / Claude" \
  _STD_PAYLOAD

sync_one \
  "$HOME/.config/Antigravity IDE/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json" \
  "Antigravity / Claude" \
  _STD_PAYLOAD

info ""
info "Sync complete."
info "👉 Restart each IDE to load the updated MCP configuration."
warn "⚠  Placeholder tokens in effect — set real keys via each IDE's config UI."
warn "   GitHub:     https://github.com/settings/tokens"
warn "   Context7:   https://console.upstash.com"
