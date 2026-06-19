# Pi Rules

## Git

- **Never commit or push to git without asking the user first.** Always confirm before `git commit`, `git push`, or any operation that modifies remotes.
- The user will explicitly tell you when they're ready to commit. Don't assume.

## Subagent Delegation (REQUIRED)

Context-mode and subagents add fixed upfront context cost but prevent context bloat. Use them aggressively:

- **After any implementation**, launch parallel async `reviewer` subagents before summarizing. Do not consider an implementation complete until at least one reviewer has passed.
- **Before editing unfamiliar code**, run a `scout` subagent to map the relevant files, patterns, and risks.
- **For non-trivial changes** (multi-file, architecture, or things you haven't seen before), run `oracle` for advisory review before implementing.
- **Test runs, CI output, build output, or anything producing >50 lines** — delegate to a subagent rather than reading raw output inline. This is what keeps context from ballooning.
- **Web research tasks** — prefer `researcher` subagent over inline `ctx_fetch_and_index`/`ketch` when the research scope is broad or needs sources.
- **Exploration or audit of an unfamiliar repo/project** — fan out parallel `scout` subagents, one per major subsystem or directory, instead of reading files sequentially. This is the single biggest context-saving move on a new codebase.
- **Parallel fanout** — when you need multiple independent checks (different review angles, separate files, distinct questions), launch them as parallel subagents rather than sequentially.
- **Subagents default async** — use `async: true` for every subagent launch unless you specifically need a foreground/blocking run.
- **When in doubt, delegate.** An unnecessary subagent costs a few seconds. Bloating your context with raw file reads degrades quality for the entire rest of the session.
- **ANTI-PATTERN: incremental synthesis from parallel gathers** — when you fan out N parallel async subagents to gather independent facts (scout an unfamiliar repo, audit different subsystems, research multiple topics), do NOT re-compile, re-plan, or re-present findings every time a single subagent returns. Each intermediate synthesis wastes tokens on a picture that the next returning subagent will render obsolete. Instead: wait for ALL parallel subagents to complete, then synthesize ONE consolidated result. The only exception is when an early return reveals something that would change what the remaining subagents should investigate — in that case, interrupt and redirect the still-running subagents rather than re-planning at the orchestrator level.

## Web Research & Lookups

When you don't know a library, API, framework, or CLI tool confidently, **look it up** rather than guessing. Hallucinated API names and stale training data are harder to fix than taking 20 seconds to check.

### Decision flow

| You need to…                  | Use…                                             | Don't…               |
| ----------------------------- | ------------------------------------------------ | -------------------- |
| Look up a library/API         | MCP Context7 (Method 1)                          | Don't guess          |
| Search the web                | ketch (Method 2)                                 | Don't raw `curl`     |
| Browse a live site / fill forms | MCP Playwright (check `mcp({})` first)         | —                    |
| Anything else infra/monitoring | Check `mcp({})` — you may have a tool for it   | —                    |

### When to look things up

- **Unfamiliar libraries** — if you haven't seen recent docs for this exact version, look it up
- **Uncertain APIs** — if you're not sure of a parameter, method name, or signature, check first
- **Version-specific features** — your training data may predate new releases, deprecations, or breaking changes
- **Configuration formats** — YAML schemas, config file structures, env vars change over time
- **User asks about something recent** — any question about the latest releases, features, or ecosystem changes

**Important**: answering "let me check the latest docs" is always preferred over guessing.

### Method 1 — MCP Context7 for library/API docs (preferred)

When you need documentation for a specific library, framework, or API, use the Context7
MCP tool. It returns structured, version-specific docs without the noise of general web
search.

First resolve the library ID, then query:
```
mcp({ tool: "mcpjungle_context7__resolve-library-id", args: '{"name": "react"}' })
mcp({ tool: "mcpjungle_context7__query-docs", args: '{"libraryId": "/react", "query": "useEffect cleanup"}' })
```

### Method 2 — ketch for general web search (preferred)

[Ketch](https://github.com/1broseidon/ketch) is a blazing fast CLI for agentic search and scrape. It uses a local SearXNG instance for web search and Context7 for library docs. One tool for web search, scraping, library docs, and code search.

```bash
# Search the web (uses SearXNG backend configured in ~/Library/Application\ Support/ketch/config.json)
ketch search "your query"
ketch search "your query" --scrape       # search + fetch full content
ketch search "your query" --limit 10     # more results
ketch search "your query" --json         # structured JSON output

# Scrape a URL to clean markdown
ketch scrape https://example.com/page

# Search library docs (Context7-backed, supports pagination via --limit)
ketch docs "library-name"                        # search docs for a library
ketch docs "how to render tables" --library /charmbracelet/glamour  # direct library ID
ketch docs <library-name> --limit 10              # paginate results
ketch docs <library-name> --limit 10 --tokens 8000  # full-detail docs

# Search open-source code (Grep, Sourcegraph, or GitHub backends)
ketch code "http.NewRequestWithContext" --lang go
ketch code "rate limit middleware" --lang go --limit 10 -b github
ketch code "search pattern" --regex

# Crawl a site
ketch crawl https://docs.example.com --depth 2
```

All commands support `--json` for structured output. Use `--limit` to control result volume and paginate through results.

### Method 3 — Direct URL fetching (fallback)

If you need to fetch a raw URL that ketch can't handle:

```bash
curl -sL "https://raw.githubusercontent.com/owner/repo/main/README.md"
curl -sL "https://pypi.org/pypi/package-name/json"
```

### Discovering other MCP tools

Your environment has additional MCP servers (Grafana, Proxmox, Gitea, Playwright,
*arr, and others). Before scripting something complex in bash, check whether a
dedicated tool already exists:

```
mcp({})                         → list all servers and tool counts
mcp({ search: "browser" })      → search across all tools by keyword
mcp({ server: "mcpjungle" })    → list all tools on a specific server
```

If you're about to do something a tool could handle (browser automation, infrastructure
queries, issue tracking, monitoring dashboard work) — check MCP first.

### After looking up docs
Always cite where the info came from. If you still can't find a definitive answer, be honest about that instead of fabricating an answer.