#!/usr/bin/env python3
"""
extract.py — Fetch a URL or read HTML from stdin, extract readable content,
             and output clean markdown.

Usage:
    curl -sL "https://example.com" | python3 extract.py
    python3 extract.py "https://example.com"

For best results: pip install readability-lxml html2text
"""

import html
import json
import re
import sys
import urllib.error
import urllib.request
from html.parser import HTMLParser
from urllib.parse import urlparse

OUTPUT_TEMPLATE = """\
## {title}

{content}

---

*Source: {source}*
"""


# ---------------------------------------------------------------------------
# Try to import optional high-quality extractors
# ---------------------------------------------------------------------------

HAS_READABILITY = False
HAS_HTML2TEXT = False

try:
    from readability import Document  # type: ignore
    HAS_READABILITY = True
except ImportError:
    pass

try:
    import html2text  # type: ignore
    HAS_HTML2TEXT = True
except ImportError:
    pass

_READABILITY_WARNED = False


def _warn_readability() -> None:
    global _READABILITY_WARNED
    if not _READABILITY_WARNED:
        print(
            "<!-- Note: install readability-lxml + html2text for better extraction: "
            "pip install readability-lxml html2text -->",
            file=sys.stderr,
        )
        _READABILITY_WARNED = True


# ---------------------------------------------------------------------------
# Stdlib-based fallback extractor
# ---------------------------------------------------------------------------


class _ContentExtractor(HTMLParser):
    """Heuristic HTML-to-text extractor using only stdlib."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self._title = ""
        self._in_title = False
        self._in_script = 0
        self._in_style = 0
        self._in_code = 0
        self._in_a = 0
        self._link_href = ""
        self._skip_tags = {"nav", "footer", "header", "aside", "noscript"}
        self._skip_depth = 0
        self._text_parts: list[str] = []
        self._links: list[tuple[str, str]] = []  # (text, url)
        self._last_text = ""
        self._block_tags = {
            "p", "br", "div", "h1", "h2", "h3", "h4", "h5", "h6",
            "li", "tr", "blockquote", "hr", "section", "article",
        }
        self._add_space = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        tag_lower = tag.lower()

        if tag_lower == "title":
            self._in_title = True
            return

        if tag_lower in ("script", "style"):
            setattr(self, f"_in_{tag_lower}", getattr(self, f"_in_{tag_lower}") + 1)
            return

        if tag_lower == "code":
            self._in_code += 1
            return

        if tag_lower in self._skip_tags:
            self._skip_depth += 1
            return

        if tag_lower == "a":
            self._in_a += 1
            for name, val in attrs:
                if name == "href" and val:
                    self._link_href = val

        if tag_lower in self._block_tags:
            if self._last_text and not self._last_text.endswith("\n"):
                self._text_parts.append("\n")
                self._last_text = "\n"

    def handle_endtag(self, tag: str) -> None:
        tag_lower = tag.lower()

        if tag_lower == "title":
            self._in_title = False
            return

        if tag_lower in ("script", "style"):
            current = getattr(self, f"_in_{tag_lower}", 0)
            if current > 0:
                setattr(self, f"_in_{tag_lower}", current - 1)
            return

        if tag_lower == "code":
            if self._in_code > 0:
                self._in_code -= 1
            return

        if tag_lower in self._skip_tags:
            if self._skip_depth > 0:
                self._skip_depth -= 1
            return

        if tag_lower == "a":
            if self._in_a > 0:
                self._in_a -= 1
                if self._link_href and self._last_text.strip():
                    href = self._link_href
                    if href.startswith("/"):
                        href = "(relative)" + href
                    self._links.append((self._last_text.strip(), href))
                self._link_href = ""
            return

        if tag_lower in self._block_tags:
            if self._last_text and not self._last_text.endswith("\n"):
                self._text_parts.append("\n")
                self._last_text = "\n"

    def handle_data(self, data: str) -> None:
        if self._in_title:
            self._title += data
            return
        if self._in_script or self._in_style or self._skip_depth > 0:
            return
        if self._in_code:
            data = data.replace("\n", " ")
        stripped = re.sub(r"\s+", " ", data).strip()
        if stripped:
            self._text_parts.append(stripped)
            self._last_text = stripped

    def get_result(self) -> tuple[str, str]:
        text = " ".join(self._text_parts)
        text = re.sub(r" +\n", "\n", text)
        text = re.sub(r"\n{3,}", "\n\n", text)
        text = text.strip()

        # Append link references
        seen_urls: set[str] = set()
        link_lines: list[str] = []
        for link_text, url in self._links:
            if url and url not in seen_urls and not url.startswith("(relative)"):
                seen_urls.add(url)
                link_lines.append(f"- [{link_text}]({url})")
        if link_lines:
            text += "\n\n**Links:**\n" + "\n".join(link_lines)

        return self._title or "Untitled", text


# ---------------------------------------------------------------------------
# High-quality extraction (readability + html2text)
# ---------------------------------------------------------------------------


def _extract_readability(html_content: str, source_url: str) -> tuple[str, str] | None:
    """Try readability-lxml + html2text. Returns (title, markdown) or None."""
    try:
        doc = Document(html_content)
        title = doc.title() or "Untitled"
        summary_html = doc.summary()
    except Exception:
        return None

    try:
        h = html2text.HTML2Text()
        h.body_width = 0  # no wrapping
        h.ignore_links = False
        h.ignore_images = False
        h.ignore_emphasis = False
        h.ignore_tables = False
        h.skip_internal_links = True
        h.protect_links = True
        h.unicode_snob = True
        markdown = h.handle(summary_html).strip()
    except Exception:
        # Fallback: strip HTML tags manually
        markdown = re.sub(r"<[^>]+>", "", summary_html)
        markdown = re.sub(r"\n{3,}", "\n\n", markdown).strip()

    return title, markdown


# ---------------------------------------------------------------------------
# DuckDuckGo HTML result page parser
# ---------------------------------------------------------------------------

DDG_RESULT_RE = re.compile(
    r'<a[^>]*class="result__a"[^>]*href="([^"]+)"[^>]*>(.*?)</a>',
    re.DOTALL,
)
DDG_SNIPPET_RE = re.compile(
    r'<a[^>]*class="result__snippet"[^>]*>(.*?)</a>',
    re.DOTALL,
)


def _is_duckduckgo_html(html_content: str, source_url: str) -> bool:
    return "duckduckgo.com" in source_url and "html" in source_url


def _format_ddg_results(html_content: str) -> str | None:
    """Format DuckDuckGo HTML search results as clean markdown."""

    # Find result blocks
    result_blocks = DDG_RESULT_RE.findall(html_content)
    if not result_blocks:
        return None

    snippets = DDG_SNIPPET_RE.findall(html_content)

    lines: list[str] = ["## Search Results", ""]
    for i, (url, title_html) in enumerate(result_blocks):
        title = re.sub(r"<[^>]+>", "", title_html)
        title = html.unescape(title).strip()
        url = html.unescape(url.strip())

        snippet = ""
        if i < len(snippets):
            snippet = re.sub(r"<[^>]+>", "", snippets[i])
            snippet = html.unescape(snippet).strip()

        lines.append(f"### {i + 1}. {title}")
        lines.append(f"   {url}")
        if snippet:
            lines.append(f"   > {snippet}")
        lines.append("")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Generic content extraction entry point
# ---------------------------------------------------------------------------


def fetch_url(url: str, timeout: int = 30) -> str:
    """Fetch a URL and return its text content."""
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": (
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/131.0.0.0 Safari/537.36"
            ),
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
        },
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        raw = resp.read()
        # Try to detect encoding from Content-Type or HTML meta
        content_type = resp.headers.get("Content-Type", "")
        charset = "utf-8"
        if "charset=" in content_type:
            charset = content_type.split("charset=")[-1].split(";")[0].strip()
        try:
            return raw.decode(charset)
        except (UnicodeDecodeError, LookupError):
            return raw.decode("utf-8", errors="replace")


def extract(html_content: str, source_url: str = "") -> str:
    """Extract clean markdown from HTML content."""

    # Check if this is a DuckDuckGo search results page
    if source_url and _is_duckduckgo_html(html_content, source_url):
        ddg_formatted = _format_ddg_results(html_content)
        if ddg_formatted:
            return ddg_formatted

    # Check if it's a JSON API response
    stripped = html_content.strip()
    if stripped.startswith("{") or stripped.startswith("["):
        try:
            parsed = json.loads(stripped)
            formatted = json.dumps(parsed, indent=2, ensure_ascii=False)
            title = "JSON Response"
            if isinstance(parsed, dict):
                if "message" in parsed:
                    title = str(parsed["message"][:80])
                elif "name" in parsed:
                    title = str(parsed["name"][:80])
                elif "title" in parsed:
                    title = str(parsed["title"][:80])
            return OUTPUT_TEMPLATE.format(
                title=title,
                content=f"```json\n{formatted}\n```",
                source=source_url or "stdin",
            ).strip()
        except json.JSONDecodeError:
            pass  # Not JSON

    # Try high-quality extraction with readability + html2text
    if HAS_READABILITY and HAS_HTML2TEXT:
        result = _extract_readability(html_content, source_url)
        if result:
            title, markdown = result
            return OUTPUT_TEMPLATE.format(
                title=title,
                content=markdown,
                source=source_url or "stdin",
            ).strip()
    else:
        _warn_readability()

    # Fallback: stdlib-based extraction
    parser = _ContentExtractor()
    try:
        parser.feed(html_content)
    except Exception:
        pass

    title, text = parser.get_result()

    # If extraction produced almost nothing, just show a cleaned version
    if len(text) < 50:
        text = re.sub(r"<[^>]+>", " ", html_content)
        text = re.sub(r"\s+", " ", text).strip()
        text = text[:2000]

    if not title:
        title = source_url or "Untitled"

    return OUTPUT_TEMPLATE.format(
        title=title,
        content=text or "(no extractable content found)",
        source=source_url or "stdin",
    ).strip()


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

GITHUB_DOMAIN_RE = re.compile(r"^https?://github\.com/")


def main() -> None:
    # Determine input source
    if len(sys.argv) > 1:
        url = sys.argv[1]
        if url.startswith("http://") or url.startswith("https://"):
            try:
                html_content = fetch_url(url)
            except urllib.error.HTTPError as e:
                msg = f"## Error\n\nHTTP {e.code}: {e.reason}\n\n---\n\n*Source: {url}*"
                print(msg)
                sys.exit(1)
            except urllib.error.URLError as e:
                msg = f"## Error\n\nConnection failed: {e.reason}\n\n---\n\n*Source: {url}*"
                print(msg)
                sys.exit(1)
            except Exception as e:
                msg = f"## Error\n\n{e}\n\n---\n\n*Source: {url}*"
                print(msg)
                sys.exit(1)

            result = extract(html_content, source_url=url)
            print(result)
        else:
            # Treat as raw HTML content passed as argument
            result = extract(url, source_url="<argument>")
            print(result)
    else:
        # Read HTML from stdin
        html_content = sys.stdin.read()
        source = "<stdin>"

        # Try to guess source from GitHub Actions or common patterns
        # (no env vars, no cache — pure heuristics)

        result = extract(html_content, source_url=source)
        print(result)


if __name__ == "__main__":
    main()
