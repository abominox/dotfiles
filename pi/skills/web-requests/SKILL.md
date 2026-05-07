---
name: web-requests
description: Fetch URLs, extract readable content, and search the web using curl and Python. Use for web research, URL fetching, API calls, and content extraction.
---

# Web Requests

Provides web research and URL fetching capabilities without any Pi extension — just curl and a lightweight Python extraction script. The `extract.py` script converts raw HTML into clean markdown. Everything is stateless: no cache files, no stored results, no session data.

## Quick Reference

```bash
# Fetch and extract a URL
curl -sL "https://example.com" | python3 extract.py

# Fetch with specific user-agent (some sites block curl)
curl -sL -H "User-Agent: Mozilla/5.0" "https://example.com" | python3 extract.py

# Search DuckDuckGo
curl -s "https://html.duckduckgo.com/html/?q=search+query" | python3 extract.py

# Search GitHub code
curl -s "https://api.github.com/search/code?q=import+react&per_page=5"

# Search Stack Overflow
curl -s "https://api.stackexchange.com/2.3/search?order=desc&sort=relevance&intitle=search+query&site=stackoverflow&pagesize=5"
```

## Usage Patterns

### 1. Fetch a URL and extract readable content

Goal: get clean markdown from any web page.

```bash
# The extract.py script is in the skill's scripts/ directory
SKILL_DIR="$HOME/.pi/agent/skills/web-requests"

# Basic usage — HTML on stdin
curl -sL "https://en.wikipedia.org/wiki/Web_scraping" | python3 "$SKILL_DIR/scripts/extract.py"

# With a URL passed as argument (script can fetch it directly)
python3 "$SKILL_DIR/scripts/extract.py" "https://en.wikipedia.org/wiki/Web_scraping"

# Handle sites that block default curl user-agent
curl -sL -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" "https://docs.example.com" | python3 "$SKILL_DIR/scripts/extract.py"

# Follow redirects (-L) and set a timeout
curl -sL --max-time 30 "https://example.com" | python3 "$SKILL_DIR/scripts/extract.py"
```

**Output format:**
```
## Page Title

Extracted markdown content...

---

*Source: https://example.com*
```

If the page is behind a login wall, blocks bots, or requires JavaScript, the output will indicate the failure and you may need to use a different approach (e.g., Google cache, textise dot iitty).

### 2. Search the web

Use DuckDuckGo's HTML-only (non-JS) endpoint for clean, parseable results:

```bash
SKILL_DIR="$HOME/.pi/agent/skills/web-requests"

# Search and get readable results
curl -s "https://html.duckduckgo.com/html/?q=node.js+performance+benchmarks" | python3 "$SKILL_DIR/scripts/extract.py"

# More specific search with quoted phrases
curl -s "https://html.duckduckgo.com/html/?q=%22react+19%22+release+date" | python3 "$SKILL_DIR/scripts/extract.py"
```

The DuckDuckGo HTML results page contains ranked result links. Pipe through `extract.py` to get clean markdown with the result titles, snippets, and URLs. Then use the URL fetch pattern above to get full content from the most relevant results.

**When to use multiple queries:** For research questions, run 2-4 separate searches with different phrasing and scope to get broader coverage. Each search returns different results.

### 3. Search GitHub for code

Use the GitHub REST API (no auth needed for public repos, but rate-limited to 60 req/hr without a token):

```bash
# Code search
curl -s "https://api.github.com/search/code?q=express+router+middleware+language:javascript&per_page=5&sort=indexed"

# Repo search
curl -s "https://api.github.com/search/repositories?q=cli+markdown+editor+topic:cli&sort=stars&per_page=5"

# Issues/search
curl -s "https://api.github.com/search/issues?q=webpack+vite+migration+is:issue&per_page=5"
```

With a GitHub token (set `GITHUB_TOKEN` env var), rate limit increases to 5000 req/hr. Use `-H "Authorization: Bearer $GITHUB_TOKEN"` in requests.

### 4. Search Stack Overflow

Use the Stack Exchange API (no auth needed, but throttled):

```bash
# Search questions
curl -s "https://api.stackexchange.com/2.3/search?order=desc&sort=relevance&intitle=typescript+decorators+deprecated&site=stackoverflow&pagesize=5"

# Search with tags
curl -s "https://api.stackexchange.com/2.3/questions?order=desc&sort=votes&tagged=next.js+app-router&site=stackoverflow&pagesize=5"

# Answers for a specific question
curl -s "https://api.stackexchange.com/2.3/questions/7654321/answers?order=desc&sort=votes&site=stackoverflow&filter=withbody"
```

### 5. Generic JSON API requests

```bash
# GET with JSON response
curl -s -H "Accept: application/json" "https://api.example.com/data"

# POST with JSON body
curl -s -X POST -H "Content-Type: application/json" -d '{"key":"value"}' "https://api.example.com/submit"

# With API key header
curl -s -H "Authorization: Bearer $API_KEY" "https://api.example.com/data"
```

## extract.py Reference

The `extract.py` script handles:

- **HTML to markdown** — strips navigation, sidebars, ads; extracts title and main content
- **DuckDuckGo search results** — parses the HTML-only search result page
- **GitHub API responses** — pretty-prints JSON responses for readability
- **Error handling** — reports HTTP errors, connection timeouts, empty responses
- **Encoding** — auto-detects and handles common character encodings

It does NOT:
- Execute JavaScript (no headless browser)
- Handle authentication flows or login walls
- Download binary files or large payloads
- Maintain any cache or store any data on disk

If `readability-lxml` and `html2text` are installed (via `pip install readability-lxml html2text`), extraction quality is much higher. Without them, a built-in fallback using Python's stdlib is used.
