# Pi Rules

## Git

- **Never commit or push to git without asking the user first.** Always confirm before `git commit`, `git push`, or any operation that modifies remotes.
- The user will explicitly tell you when they're ready to commit. Don't assume.

## Web Research & Lookups

When you don't know a library, API, framework, or CLI tool confidently, **look it up** rather than guessing. Hallucinated API names and stale training data are harder to fix than taking 20 seconds to check.

### When to look things up

- **Unfamiliar libraries** — if you haven't seen recent docs for this exact version, look it up
- **Uncertain APIs** — if you're not sure of a parameter, method name, or signature, check first
- **Version-specific features** — your training data may predate new releases, deprecations, or breaking changes
- **Configuration formats** — YAML schemas, config file structures, env vars change over time
- **User asks about something recent** — any question about the latest releases, features, or ecosystem changes

**Important**: answering "let me check the latest docs" is always preferred over guessing.

### Method 1 — ketch (preferred)

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

### Method 2 — Direct URL fetching (fallback)

If you need to fetch a raw URL that ketch can't handle:

```bash
curl -sL "https://raw.githubusercontent.com/owner/repo/main/README.md"
curl -sL "https://pypi.org/pypi/package-name/json"
```

### After looking up docs
Always cite where the info came from. If you still can't find a definitive answer, be honest about that instead of fabricating an answer.