# Pi Coding Agent Performance Evaluation

## Context

You asked me to evaluate your Pi coding agent performance and suggest improvements, noting that you're using **DeepSeek V4 Flash** and observing **excessive tool calling** and **slow resolution of basic issues**. This evaluation is based on examining your full config: `pi/settings.json`, `pi/extensions/`, installed npm packages, shell configuration, and the `install.sh` bootstrap script.

---

## Summary of Findings

**Your Pi agent has one critical bottleneck and several moderate inefficiencies:**

1. **pi-tool-display framework fork mismatch (HIGH IMPACT)** — pi-tool-display is built against `@mariozechner/pi-coding-agent` (a third-party fork), but your Pi runtime is `@earendil-works/pi-coding-agent`. This means every tool call crosses between two different framework versions for wrapping, execution, and rendering.

This alone means:
- Slower session startup (multiple framework copies loaded at init)
- Higher memory usage
- Tool-call chain that crosses framework boundaries
- `pi-tool-display` registers custom tool implementations for read/grep/find/ls/edit/write that run **on top of** the built-in versions

---

## Detailed Findings

### 1. Extension Ecosystem Conflict (HIGH IMPACT) — The pi-tool-display Problem

| Package | Depends On | Status |
|---------|-----------|--------|
| `@earendil-works/pi-coding-agent` v0.74.0 | — | **Your actual Pi runtime** |
| `pi-rtk-optimizer` v0.8.2 | `@earendil-works/pi-coding-agent` ^0.74.0 | ✅ Compatible |
| `pi-qq` v0.1.15 | `@earendil-works/pi-coding-agent` * | ✅ Compatible |
| `pi-wierd-statusline` v0.5.0 | `@earendil-works/pi-coding-agent` | ✅ (assumed) |
| `pi-tool-display` v0.3.6 | **`@mariozechner/pi-coding-agent`** ^0.72.0 | ⚠️ **MISMATCH** |
| `pi-mermaid` v0.3.0 | **`@mariozechner/pi-coding-agent`** * | ⚠️ **MISMATCH** |

**This is a problem with pi-tool-display itself, not your setup.** The Pi ecosystem has two parallel forks:

- **`@earendil-works/pi-coding-agent`** — the mainline framework (what you have)
- **`@mariozechner/pi-coding-agent`** — a fork by a different developer

`pi-tool-display` was built exclusively against the `@mariozechner` fork. It carries its own nested copy of `@mariozechner/pi-coding-agent` v0.72.1 (plus `@mariozechner/pi-tui`) in its `node_modules`. While Pi manages to load it without crashing, this means two different framework versions are resident at the same time.

`pi-mermaid` has the same issue but is less impactful since it only activates when rendering mermaid blocks (not on every tool call).

**Second-order effect:** pi-tool-display registers tool overrides (`registerToolOverrides` in your config) for `read`, `grep`, `find`, `ls`, `edit`, and `write` — all enabled. This wraps every built-in tool with a custom renderer from the mismatched framework fork. The full tool chain becomes:

```
Built-in tool (earendil) → pi-rtk-optimizer rewrite → pi-tool-display wrapper (mariozechner) → execution → 
  pi-rtk-optimizer compaction → pi-tool-display rendering
```

Every tool call crosses between two different framework versions for wrapping, execution, and rendering. This is the most likely contributor to the "slow for basic issues" behavior you're seeing.

### 2. RTK Output Compaction Pipeline (MEDIUM IMPACT)

`pi-rtk-optimizer` applies a multi-stage pipeline to **every** tool result:

1. ANSI stripping
2. Read compaction + anchor detection (regex on every line)
3. Test output aggregation
4. Build output filtering
5. Git output compaction
6. Linter output aggregation
7. Search result grouping
8. Source code filtering (optional)
9. Smart truncation
10. Hard truncation (12000 char cap)

Your config has `truncate.maxChars: 12000` which is quite aggressive. Combined with `sourceCodeFiltering: "none"` (good) but `readCompaction.enabled: false` (also good).

**However**, the `truncate.enabled: true` with `maxChars: 12000` means that any tool output over 12K chars gets hard-truncated. This can cause:
- Loss of context the model needs
- Edit failures due to truncated file reads
- Retry loops (model asks to re-read, adds more tool calls)

### 3. pi-tool-display Rendering Cost (MEDIUM IMPACT)

Your config (`pi/extensions/pi-tool-display/config.json`):
- `readOutputMode: "hidden"` — hides read output entirely from TUI (model still sees it)
- `searchOutputMode: "hidden"` — hides grep/find output from TUI
- `bashOutputMode: "opencode"` — shows bash output
- `bashCollapsedLines: 10` — collapses after 10 lines
- `previewLines: 8` — only 8 lines preview

The "hidden" modes are good for TUI performance, but the tool still processes the output to determine whether to hide/show it. The most expensive part is `diffViewMode: "auto"` which renders diffs — if you do many edits, the diff renderer processes file content.

### 4. High Thinking Level (MEDIUM IMPACT)

Your settings:
```json
"defaultThinkingLevel": "high",
"hideThinkingBlock": true
```

`"high"` thinking level on DeepSeek V4 Flash means:
- The model generates extensive internal reasoning before responding
- This consumes tokens and time
- `hideThinkingBlock: true` hides the thinking from the UI but **doesn't save cost** — the tokens are still generated and paid for

For a **flash** model, "high" thinking is counterproductive. Flash models are designed for speed. High thinking levels are more appropriate for deep reasoning models.

### 5. ReCap Model (NO IMPACT — leave as-is)

```json
"--recap-model": "openrouter/google/gemini-2.5-flash"
```

You're right — this is asynchronous. It only runs after ~40 seconds of inactivity and nothing blocks on it. This isn't contributing to the latency you're seeing. Leave it in place; it helps with session summaries without affecting tool call performance.

### 6. pi-mcp-adapter vs ketch (LOW IMPACT)

You have `pi-mcp-adapter` installed globally but `.opencode/opencode.json` also configures a Context7 MCP server separately. You're right: for Context7 library docs, you should use `ketch docs` (as your AGENTS.md documents). The `pi-mcp-adapter` extension may be vestigial if you're not using it for other MCP servers. 

If you're not actively using the MCP adapter for anything, uninstalling it (`pi uninstall pi-mcp-adapter`) would reduce startup overhead and remove one more tool registration layer.

---

## Recommended Optimizations

### Critical Fix: Resolve Extension Ecosystem Conflict

**Remove `pi-tool-display`** (note: this is an inherent issue with the extension itself, not your setup). pi-tool-display was built against `@mariozechner/pi-coding-agent` — a third-party fork of the Pi framework — while you run the mainline `@earendil-works/pi-coding-agent`. It has to bundle its own copy of the forked framework to function, creating a dual-framework environment at startup and on every tool call. Removing it eliminates the entire `@mariozechner` dependency tree and all tool wrapper overhead.

```bash
pi uninstall pi-tool-display
```

Then remove its config:
```bash
rm ~/.pi/agent/extensions/pi-tool-display/config.json
```

**Yes — use `@vanillagreen/pi-tool-renderer`** as the replacement. Its peerDependencies are `@earendil-works/pi-coding-agent` and `@earendil-works/pi-tui` — exactly the correct framework. Install it:

```bash
pi install npm:@vanillagreen/pi-tool-renderer
```

**Keep** `pi-rtk-optimizer` — it's correctly aligned with your Pi framework (`@earendil-works`) and provides actual token savings.


### High-Impact Config Tweaks

**Consider lowering thinking level:**
```json
"defaultThinkingLevel": "minimal"
```
(or toggle it off entirely with `"off"`)

DeepSeek V4 Flash is a flash-tier model — "high" thinking encourages long internal monologues that don't improve output quality on simple tasks and just burn tokens and time. Dropping to "minimal" or "off" will significantly reduce per-response latency.

**Consider the rtk hard truncation cap:**
```json
"truncate": {
  "enabled": true,
  "maxChars": 24000
}
```
12000 chars is quite tight. Doubling to 24000 will reduce edit failures (and the retry loops they cause), while still keeping context under control.

### Medium-Impact Tweaks

**Uninstall `pi-web-access` (you use ketch instead):**
This extension adds web search/fetch/scrape capabilities, but you already use `ketch` for that (as your AGENTS.md documents). It's just startup overhead and another layer of tool registration.

```bash
pi uninstall pi-web-access
```

**Remove `pi-mcp-adapter` if you're using ketch for Context7:**
You're right — ketch handles Context7 library docs via `ketch docs` directly. The `pi-mcp-adapter` extension provides a general MCP bridge but if you're not actively using other MCP servers through it, it's just startup overhead. The `.opencode/opencode.json` Context7 MCP config is separate from Pi and won't be affected.

```bash
pi uninstall pi-mcp-adapter
```

### Uninstall pi-mermaid (it also has the `@mariozechner` dependency issue)

```bash
pi uninstall pi-mermaid
```

**Check if `pi-container-sandbox` is active:**
If enabled, every read/write/edit/bash operation goes through a container layer. This adds significant latency to every tool call. If you're running locally without sandbox needs, uninstall it.

### Monitoring

To quantify improvements, you can track:
- **Token usage** — before/after changes, compare per-session token counts
- **Tool call count** — how many tools are used per task
- **Edit success rate** — fewer retries = less tool call inflation
- **Time per task** — wall clock for common operations

---

## Summary of Recommendations

| Priority | Change | Expected Benefit |
|----------|--------|------------------|
| 🔴 Critical | Uninstall `pi-tool-display`, install `@vanillagreen/pi-tool-renderer` instead | Eliminates framework fork mismatch, tool wrapper overhead, and rendering cost |
| 🔴 Critical | Set `defaultThinkingLevel` to `"minimal"` or `"off"` | Reduces per-response latency and token waste on flash model |
| 🟡 High | Raise `maxChars` to 24000 | Reduces edit failures and retry loops |
| 🟡 Medium | Uninstall `pi-mermaid` | Removes remaining `@mariozechner` dependency |
| 🟢 Medium | Uninstall `pi-web-access` (use ketch instead) | Lighter startup, fewer registered tools |
| 🟢 Medium | Remove `pi-mcp-adapter` if using ketch for Context7 | Lighter startup, one less tool layer |
| 🟢 Medium | Remove `pi-container-sandbox` if unused | Eliminates per-call container overhead |
| ℹ️ Info | Keep `pi-rtk-optimizer` and `pi-qq` | These are correctly aligned and provide value |

## Verification

After making changes, test with a few common tasks:
1. Read a file and make a small edit — observe tool call count
2. Run a grep + edit cycle — observe latency
3. Start a new session — observe startup time

Compare against your current experience to validate improvements.
