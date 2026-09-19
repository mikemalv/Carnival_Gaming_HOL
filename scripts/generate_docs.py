#!/usr/bin/env python3
"""
Generate README.html and README.pdf for each USER_HOL_xx folder.

Reads each per-user README.md, converts it with pandoc, wraps it in a
self-contained styled template (no external CSS/JS/fonts), then renders
a PDF with headless Chrome.

Run scripts/generate_user_folders.sh first -- this consumes its output.

Usage:  python3 scripts/generate_docs.py
"""

import html
import re
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Self-contained styles. No CDN, no web fonts, no JavaScript -- so the file
# renders identically from disk, from a Snowflake workspace, and in print.
# Screen styling adapts to light/dark; print is forced light for legibility.
STYLE = """
:root { color-scheme: light dark; }

* { box-sizing: border-box; }

.banner { margin: 0 0 8px; line-height: 0; }
.banner svg { display: block; width: 100%; height: auto; border-radius: 6px; }
body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
  font-size: 15px;
  line-height: 1.65;
  max-width: 900px;
  width: 100%;
  margin: 0 auto;
  padding: clamp(16px, 4vw, 40px);
  color: light-dark(#1f2937, #e5e7eb);
  background: light-dark(#ffffff, #0f172a);
}

h1 {
  font-size: 1.9rem;
  line-height: 1.25;
  margin: 0 0 4px;
  padding-bottom: 14px;
  border-bottom: 3px solid #29b5e8;
  color: light-dark(#0f172a, #f1f5f9);
}

h2 {
  font-size: 1.35rem;
  margin-top: 2.2em;
  padding-bottom: 6px;
  border-bottom: 1px solid light-dark(#e5e7eb, #334155);
  color: light-dark(#0f172a, #f1f5f9);
}

h3 {
  font-size: 1.1rem;
  margin-top: 1.8em;
  color: light-dark(#0f172a, #f1f5f9);
}

a { color: light-dark(#0969da, #60a5fa); }

code {
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 0.88em;
  padding: 2px 5px;
  border-radius: 4px;
  background: light-dark(#f1f5f9, #1e293b);
  color: light-dark(#0f172a, #e2e8f0);
}

pre {
  background: light-dark(#f8fafc, #1e293b);
  border: 1px solid light-dark(#e2e8f0, #334155);
  border-radius: 6px;
  padding: 14px 16px;
  overflow-x: auto;
}

pre code { background: none; padding: 0; font-size: 0.86em; }

/* Wide tables scroll on their own instead of stretching the page. */
.table-wrap { overflow-x: auto; margin: 16px 0; }

table { border-collapse: collapse; width: 100%; font-size: 0.93em; }

th, td {
  border: 1px solid light-dark(#d8dee4, #374151);
  padding: 8px 11px;
  text-align: left;
  vertical-align: top;
}

th { background: light-dark(#f1f5f9, #1f2937); font-weight: 600; }

tbody tr:nth-child(even) td { background: light-dark(#fafbfc, #172033); }

blockquote {
  margin: 18px 0;
  padding: 12px 18px;
  border-left: 4px solid #29b5e8;
  background: light-dark(#f0f9ff, #10263a);
  border-radius: 0 4px 4px 0;
}

blockquote p { margin: 0.4em 0; }

hr {
  border: none;
  border-top: 1px solid light-dark(#e5e7eb, #334155);
  margin: 2.4em 0;
}

img, svg { max-width: 100%; height: auto; }

ol, ul { padding-left: 1.6em; }
li { margin: 0.3em 0; }

.doc-meta {
  font-size: 0.85rem;
  color: light-dark(#57606a, #94a3b8);
  margin: 10px 0 28px;
}

/* ---- Print / PDF ---- */
@page { size: letter; margin: 14mm 12mm; }

@media print {
  /* Force light: a dark-mode PDF wastes toner and reads poorly. */
  :root { color-scheme: light; }
  body {
    max-width: none;
    padding: 0;
    font-size: 10.5pt;
    color: #1f2937;
    background: #fff;
  }
  h1 { font-size: 19pt; }
  h2 { font-size: 14pt; page-break-after: avoid; }
  h3 { font-size: 11.5pt; page-break-after: avoid; }
  /* Keep a section heading with the text that follows it. */
  h2, h3 { break-after: avoid-page; }
  pre, blockquote, table, .table-wrap { page-break-inside: avoid; }
  tr, li { page-break-inside: avoid; }
  a { color: #0b4f87; text-decoration: none; }
  /* Spell out link targets, since a printed page can't be clicked. */
  a[href^="http"]::after { content: " (" attr(href) ")"; font-size: 0.82em; color: #57606a; }
  code { background: #f1f5f9; }
  pre { background: #f8fafc; border: 1px solid #e2e8f0; }
  th { background: #f1f5f9 !important; }
  tbody tr:nth-child(even) td { background: #fafbfc !important; }
  .doc-meta { color: #57606a; }
}
"""

PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<meta name="snowflake-source" content="cortex-agent-authored" />
<title>{title}</title>
<script type="application/json" id="snowflake-report-metadata">
{metadata}
</script>
<style>{style}</style>
</head>
<body>
{body}
<hr />
<p class="doc-meta">Carnival Cruise Gaming Hands-On Lab &mdash; User {num}. \
Generated {generated} from <code>README.md</code>. \
This document is a rendering of the lab directions; the SQL files in this \
folder are the source of truth.</p>
</body>
</html>
"""

METADATA = """{{
  "generated": "{generated}",
  "intent": "Printable lab directions for Carnival Gaming HOL user {num}",
  "dataSources": [
    {{ "type": "file", "path": "USER_HOL_{num}/README.md",
      "note": "Generated by scripts/generate_user_folders.sh from templates/README.md" }}
  ],
  "sections": [
    {{ "id": "lab-directions", "title": "Carnival Gaming HOL directions - user {num}",
      "dataSources": [{{ "type": "file", "path": "USER_HOL_{num}/README.md" }}],
      "producerNotes": "Rendered with pandoc (gfm to html5) and wrapped by scripts/generate_docs.py. Regenerate by re-running that script; do not hand-edit README.html." }}
  ]
}}"""


def wrap_tables(body: str) -> str:
    """Make wide tables scroll independently rather than widening the page."""
    return body.replace("<table>", '<div class="table-wrap"><table>').replace(
        "</table>", "</table></div>"
    )


BANNER_IMG = re.compile(r'<img\s[^>]*src="[^"]*hol-banner\.svg"[^>]*>')


def inline_banner(body: str) -> str:
    """Replace the banner <img> with the SVG source itself.

    The markdown points at ../assets/hol-banner.svg, which resolves on GitHub
    and in a clone. It does NOT resolve in a Snowflake Workspace, where each
    user's files sit flat in one directory with no assets/ folder. Inlining the
    SVG makes the HTML -- and therefore the PDF -- self-contained wherever it
    ends up.
    """
    banner = REPO / "assets" / "hol-banner.svg"
    if not banner.exists():
        return body

    svg = banner.read_text(encoding="utf-8")
    # Inline SVG must not carry an XML prolog.
    svg = re.sub(r"^\s*<\?xml[^>]*\?>\s*", "", svg)
    # Scale to the content column rather than its intrinsic 1200px.
    svg = svg.replace('width="1200" height="300"', 'width="100%"', 1)
    return BANNER_IMG.sub(lambda _: f'<div class="banner">{svg}</div>', body, count=1)


def main() -> int:
    if not shutil.which("pandoc"):
        print("error: pandoc not found", file=sys.stderr)
        return 1
    if not Path(CHROME).exists():
        print(f"error: Chrome not found at {CHROME}", file=sys.stderr)
        return 1

    generated = date.today().isoformat()
    folders = sorted(REPO.glob("USER_HOL_*"))
    if not folders:
        print("error: no USER_HOL_* folders; run generate_user_folders.sh first", file=sys.stderr)
        return 1

    failures = []

    for folder in folders:
        num = folder.name.replace("USER_HOL_", "")
        md = folder / "README.md"
        if not md.exists():
            failures.append(f"{folder.name}: README.md missing")
            continue

        # Markdown -> HTML fragment
        proc = subprocess.run(
            ["pandoc", str(md), "-f", "gfm", "-t", "html5"],
            capture_output=True, text=True,
        )
        if proc.returncode != 0:
            failures.append(f"{folder.name}: pandoc failed: {proc.stderr.strip()}")
            continue

        body = inline_banner(wrap_tables(proc.stdout))

        # Pull the H1 for <title>, stripping any tags pandoc left inside it.
        m = re.search(r"<h1[^>]*>(.*?)</h1>", body, re.S)
        title = html.unescape(re.sub(r"<[^>]+>", "", m.group(1))).strip() if m else f"Carnival Gaming HOL -- User {num}"
        title = " ".join(title.split())

        page = PAGE.format(
            title=html.escape(title),
            metadata=METADATA.format(generated=generated, num=num),
            style=STYLE,
            body=body,
            num=num,
            generated=generated,
        )

        html_path = folder / "README.html"
        html_path.write_text(page, encoding="utf-8")

        # HTML -> PDF via headless Chrome
        pdf_path = folder / "README.pdf"
        proc = subprocess.run(
            [
                CHROME,
                "--headless=new",
                "--disable-gpu",
                "--no-sandbox",
                "--no-pdf-header-footer",
                f"--print-to-pdf={pdf_path}",
                html_path.as_uri(),
            ],
            capture_output=True, text=True, timeout=120,
        )
        if not pdf_path.exists() or pdf_path.stat().st_size == 0:
            failures.append(f"{folder.name}: PDF not produced: {proc.stderr.strip()[:200]}")
            continue

        print(
            f"{folder.name}: README.html ({html_path.stat().st_size:,}B) "
            f"README.pdf ({pdf_path.stat().st_size:,}B)"
        )

    if failures:
        print("\nFAILURES:", file=sys.stderr)
        for f in failures:
            print(f"  {f}", file=sys.stderr)
        return 1

    print(f"\nDone. Generated HTML + PDF for {len(folders)} users.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
