# Context View Plugin for OpenCode

## Overview

A TUI plugin for OpenCode that registers a `/context` slash command (with `/info` alias) to display a visual breakdown of the current session's context — session messages, token usage, MCP/LSP integrations, file changes, and environment info.

## Design

### Plugin Structure

A single TUI plugin living at `~/.config/opencode/plugins/context-view/` with:
- `package.json` — name, type: module, main entry point
- `index.js` — the TUI plugin implementation

### Command Registration

- Slash command: `/context` with alias `/info`
- Registers via `api.command.register()` returning a `TuiCommand` with `slash: { name: "context", aliases: ["info"] }`
- `onSelect` handler gathers all context data and renders it

### Data Sources

| Data | Source | Type |
|------|--------|------|
| Messages | `api.state.session.messages(sessionID)` | `Message[]` |
| Message parts | `api.state.part(messageID)` | `Part[]` |
| Token counts | `AssistantMessage.tokens` (on each assistant message) | `{ input, output, total, cache: { read, write }, reasoning }` |
| MCP servers | `api.state.mcp()` | `TuiSidebarMcpItem[]` |
| LSP servers | `api.state.lsp()` | `TuiSidebarLspItem[]` |
| File changes | `api.state.session.diff(sessionID)` | `TuiSidebarFileItem[]` |
| VCS branch | `api.state.vcs` | `{ branch?: string }` |
| Working dir | `api.state.path.directory` | string |
| Providers | `api.state.provider` | `Provider[]` |
| Session info | `api.client.session.get({sessionID})` via SDK | `Session` object |
| App version | `api.app.version` | string |

### Display

Uses `api.ui.dialog.replace()` to render a SolidJS dialog component. The dialog shows a formatted breakdown:

```
╔═══════════════════════════════════════════════╗
║  Context Usage — <session-title>              ║
║                                               ║
║  Session                                      ║
║    Messages: 42 (24 user, 18 assistant)       ║
║    Input tokens:      124,532                 ║
║    Output tokens:      84,210                 ║
║    Cache read:         12,400                 ║
║    Cache write:         8,200                 ║
║    Reasoning tokens:    3,100                 ║
║    Total tokens:      229,342                 ║
║                                               ║
║  Environment                                  ║
║    Provider:   anthropic/claude-sonnet-4      ║
║    Branch:     main                           ║
║    Project:    my-project                     ║
║    Directory:  ~/code/my-project              ║
║                                               ║
║  Integrations                                 ║
║    MCP:  3 connected, 1 disconnected          ║
║      • searxng (connected)                    ║
║      • playwright (connected)                 ║
║      • filesystem (connected)                 ║
║      • github (disconnected)                  ║
║    LSP:  2 connected                          ║
║      • typescript (connected)                 ║
║      • eslint (connected)                     ║
║                                               ║
║  Files Changed                                ║
║    12 files (+245 / -89)                     ║
║                                               ║
║  [ OK ]                                       ║
╚═══════════════════════════════════════════════╝
```

### Edge Cases

- **No active session:** Show a message "No active session" rather than erroring
- **No messages yet:** Show zeros for token counts
- **No MCP/LSP servers:** Show "None connected" or omit section
- **Dialog dismissed:** `onClose` handler cleans up

### Installation

Reference the plugin by its local path in `opencode.jsonc`:

```json
{
  "plugin": [
    "superpowers@git+https://github.com/obra/superpowers.git",
    "file:plugins/context-view"
  ]
}
```

OpenCode resolves `file:` URIs relative to the config directory (`~/.config/opencode/`).

### Token Aggregation

Iterates all messages from `api.state.session.messages(sessionID)`, filters for `AssistantMessage` types (role: "assistant"), sums their `tokens` field. No estimation needed — real token counts returned by the provider.

### Implementation

- Pure TUI plugin (no server-side hooks)
- SolidJS component rendered inside a dialog
- Registered via `plugins/context-view/index.js` with exports matching `TuiPluginModule` shape
- Installed by adding to `opencode.jsonc` plugin list