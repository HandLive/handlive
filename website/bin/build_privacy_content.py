#!/usr/bin/env python3
"""Turn docs/privacy.md and docs/privacy.vi.md into block-editor content for the website's Privacy pages.

The hub documents are the source of truth; this writes website/seed/build/privacy.<lang>.html (git-ignored),
which bin/setup.sh feeds to seed.php (written to website/seed/generated/). Handles what those pages use: ## and ### headings, paragraphs,
"- " lists, **bold**, `code`, [links](url) and bare https:// links. The language switcher line and the
# title are dropped: the page title comes from WordPress.
"""
import html
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "website", "seed", "generated")


INTERNAL_REF = re.compile(r"\s*\((?:detailed design|thiết kế chi tiết) [A-Z]{2,6}-\d{2}[^)]*\)")


def inline(text):
    text = INTERNAL_REF.sub("", text)  # spec references mean nothing to site visitors
    text = html.escape(text, quote=False)
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"`([^`]+)`", r"<code>\1</code>", text)
    text = re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", r'<a href="\2">\1</a>', text)
    return re.sub(r"(?<![\"'>])(https://[^\s<),;]+[^\s<),;.])", r'<a href="\1">\1</a>', text)


def paragraph(text):
    return f"<!-- wp:paragraph -->\n<p>{inline(text)}</p>\n<!-- /wp:paragraph -->"


def heading(text, level):
    attrs = "" if level == 2 else f' {{"level":{level}}}'
    return f'<!-- wp:heading{attrs} -->\n<h{level} class="wp-block-heading">{inline(text)}</h{level}>\n<!-- /wp:heading -->'


def bullet_list(items):
    body = "\n\n".join(f"<!-- wp:list-item -->\n<li>{inline(i)}</li>\n<!-- /wp:list-item -->" for i in items)
    return f'<!-- wp:list -->\n<ul class="wp-block-list">{body}</ul>\n<!-- /wp:list -->'


def convert(markdown):
    blocks, para, items = [], [], []

    def flush():
        if para:
            blocks.append(paragraph(" ".join(para)))
            para.clear()
        if items:
            blocks.append(bullet_list(items[:]))
            items.clear()

    for raw in markdown.splitlines():
        line = raw.rstrip()
        if line.startswith(("English | [", "[English](")) or line.startswith("# "):
            continue
        if not line.strip():
            flush()
        elif line.startswith(("## ", "### ")):
            flush()
            level = 2 if line.startswith("## ") else 3
            blocks.append(heading(line[level + 1:], level))
        elif line.startswith("- "):
            if para:
                flush()
            items.append(line[2:])
        elif items and raw.startswith("  "):
            items[-1] += " " + line.strip()
        else:
            para.append(line.strip())
    flush()
    return "\n\n".join(blocks) + "\n"


def main():
    os.makedirs(OUT, exist_ok=True)
    for lang, name in (("en", "privacy.md"), ("vi", "privacy.vi.md")):
        with open(os.path.join(ROOT, "docs", name), encoding="utf-8") as fh:
            content = convert(fh.read())
        with open(os.path.join(OUT, f"privacy.{lang}.html"), "w", encoding="utf-8") as fh:
            fh.write(content)
    print("privacy content built in", os.path.relpath(OUT, ROOT))


if __name__ == "__main__":
    sys.exit(main())
