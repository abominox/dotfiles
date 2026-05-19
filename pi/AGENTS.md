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

### Method 1 — Context7 REST API (preferred)

Context7 indexes up-to-date docs for thousands of libraries. No auth required for public repos. Use two endpoints:

**Step 1: Search for the library**
```bash
curl -s "https://context7.com/api/v2/libs/search?libraryName=library-name&query=short+description+of+what+you+need"
```
The response includes library `id`, `title`, `description`, `versions`, etc. Pick the best match.

**Step 2: Get documentation context**
```bash
curl -s "https://context7.com/api/v2/context?libraryId=/owner/repo&query=your+specific+question&type=json"
```
This returns relevant `codeSnippets` (with code examples) and `infoSnippets` (documentation explanations). Use a descriptive query for best results.

**⚠️ Always include `&type=json`.** The default response format is `text/plain`. Without `&type=json`, piping into `python3 -c "json.load(sys.stdin)"` or any JSON parser will fail with `JSONDecodeError`.

**Parsing tip:** Use `python3 -m json.tool` for a human-readable dump, or a compact inline script to extract only what you need:
```bash
curl -s "https://context7.com/api/v2/context?libraryId=/owner/repo&query=...&type=json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for s in d.get('codeSnippets', []):
    for c in s.get('codeList', []): print(c['code'])
"
```

If the library isn't on Context7 or you can't find a match, fall through to Method 2.

### Method 2 — Direct documentation scraping

Use the web-requests skill to fetch official docs or READMEs directly:

```bash
SKILL_DIR="$HOME/.pi/agent/skills/web-requests"
curl -sL "https://pypi.org/pypi/package-name/json" 2>/dev/null | python3 "$SKILL_DIR/scripts/extract.py"
curl -sL "https://raw.githubusercontent.com/owner/repo/main/README.md" 2>/dev/null | python3 "$SKILL_DIR/scripts/extract.py"
```

### Method 3 — Web search (last resort)

```bash
curl -s "https://html.duckduckgo.com/html/?q=library+name+how+to+do+something" | python3 "$SKILL_DIR/scripts/extract.py"
```

### After looking up docs
Always cite where the info came from and which endpoint you used. If you still can't find a definitive answer, be honest about that instead of fabricating an answer.