"""Build the HandLive detailed-design artifact (single HTML) plus a local Mermaid parse-check page.

Usage: build_design_html.py [--lang en|vi] — English (`X.md`, default) or Vietnamese (`X.vi.md`) pages;
outputs build/docs/handlive-detailed-design[.vi].html, preview-local[.vi].html and mermaid-check[.vi].html.
"""
import argparse
import html
import re
from pathlib import Path

import markdown
from markdown.extensions.toc import slugify_unicode

DOC_DIR = Path(__file__).resolve().parents[2] / "docs" / "detailed-design"
OUT_DIR = Path(__file__).resolve().parents[2] / "build" / "docs"
OUT_DIR.mkdir(parents=True, exist_ok=True)
LABELS = {
    "en": {"suffix": ".md", "out": "", "contents": "Contents and conventions", "overview": "Group overview",
           "group_prefix": "Function group: ", "title": "HandLive Detailed Design", "sub": "Detailed design · v1.2",
           "menu": "Contents", "h1": "HandLive detailed design", "version": "Version 1.2", "groups": "function groups",
           "leaves": "leaf functions", "lang": "en"},
    "vi": {"suffix": ".vi.md", "out": ".vi", "contents": "Mục lục và quy ước", "overview": "Tổng quan nhóm",
           "group_prefix": "Nhóm chức năng: ", "title": "HandLive Thiết kế chi tiết", "sub": "Tài liệu thiết kế chi tiết · v1.2",
           "menu": "Mục lục", "h1": "Tài liệu thiết kế chi tiết HandLive", "version": "Phiên bản 1.2", "groups": "nhóm chức năng",
           "leaves": "chức năng lá", "lang": "vi"},
}
SWITCHER = __import__("re").compile(r"^(English \| \[Tiếng Việt\]\([^)]*\)|\[English\]\([^)]*\) \| Tiếng Việt)\s*\n")
L = LABELS["en"]
ORDER, FILE_ANCHOR = [], {}


def select_language(lang):
    """Pick the pages of one language and their in-page anchors."""
    global L, ORDER, FILE_ANCHOR
    L = LABELS[lang]
    suffix = L["suffix"]
    groups = sorted(p.name for p in DOC_DIR.glob("0[1-8]-*.md")
                    if p.name.endswith(suffix) and (lang == "vi" or not p.name.endswith(".vi.md")))
    ORDER = ["README" + suffix, "00-common-specs" + suffix] + groups
    FILE_ANCHOR = {name: "f-" + name.split(".")[0].split("-")[0].lower() for name in ORDER}
    FILE_ANCHOR["README" + suffix] = "f-readme"

CSS = """
:root {
  --bg: #fafaf8; --surface: #ffffff; --surface-alt: #f3f2ee; --text: #18181b; --text-2: #3f3f46;
  --text-3: #71717a; --accent: #0b7fb3; --accent-soft: #e0f2fe; --border: #e4e4e7; --mark: #fef3c7;
  --shadow: 0 1px 3px rgba(0,0,0,0.05); color-scheme: light;
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --bg: #0c0c0e; --surface: #17171a; --surface-alt: #1f1f23; --text: #f4f4f5; --text-2: #d4d4d8;
    --text-3: #a1a1aa; --accent: #38bdf8; --accent-soft: #0c2d48; --border: #2a2a2e; --mark: #3a2f0b;
    --shadow: 0 1px 3px rgba(0,0,0,0.4); color-scheme: dark;
  }
}
:root[data-theme="dark"] {
  --bg: #0c0c0e; --surface: #17171a; --surface-alt: #1f1f23; --text: #f4f4f5; --text-2: #d4d4d8;
  --text-3: #a1a1aa; --accent: #38bdf8; --accent-soft: #0c2d48; --border: #2a2a2e; --mark: #3a2f0b;
  --shadow: 0 1px 3px rgba(0,0,0,0.4); color-scheme: dark;
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--text);
  font-family: 'Be Vietnam Pro', system-ui, -apple-system, 'Segoe UI', sans-serif; font-size: 15px; line-height: 1.65; }
.layout { display: grid; grid-template-columns: 290px minmax(0, 1fr); max-width: 1320px; margin: 0 auto; }
.sidebar { position: sticky; top: env(safe-area-inset-top, 0px); height: 100vh; overflow-y: auto;
  border-right: 1px solid var(--border); padding: 20px 16px 40px; font-size: 13px; }
.sidebar .brand { font-weight: 800; font-size: 15px; letter-spacing: -0.01em; margin-bottom: 2px; }
.sidebar .brand-sub { color: var(--text-3); font-size: 12px; margin-bottom: 16px; }
.sidebar a { color: var(--text-2); text-decoration: none; display: block; padding: 3px 8px; border-radius: 6px; }
.sidebar a:hover { background: var(--surface-alt); color: var(--text); }
.sidebar details { margin: 2px 0; }
.sidebar summary { cursor: pointer; list-style: none; padding: 4px 8px; border-radius: 6px; font-weight: 600; color: var(--text); }
.sidebar summary::-webkit-details-marker { display: none; }
.sidebar summary::before { content: '▸'; display: inline-block; width: 14px; color: var(--text-3); transition: transform .15s; }
.sidebar details[open] > summary::before { transform: rotate(90deg); }
.sidebar details a { padding-left: 22px; font-size: 12.5px; }
.sidebar .code { font-family: 'JetBrains Mono', ui-monospace, monospace; font-size: 11px; color: var(--accent); margin-right: 4px; }
main { padding-block: 24px 80px; padding-inline: 40px; min-width: 0; }
.doc-head { border-bottom: 1px solid var(--border); padding-bottom: 18px; margin-bottom: 8px; }
.doc-head h1 { font-size: 30px; margin: 0 0 6px; letter-spacing: -0.02em; line-height: 1.2; text-wrap: balance; }
.doc-head .meta { color: var(--text-3); font-size: 13px; display: flex; flex-wrap: wrap; gap: 6px 14px; }
.doc-head .meta span { font-variant-numeric: tabular-nums; }
section.file { padding-top: 12px; }
section.file + section.file { border-top: 3px solid var(--accent); margin-top: 48px; }
h1, h2, h3, h4, h5 { text-wrap: balance; scroll-margin-top: 16px; }
main h1 { font-size: 25px; margin: 28px 0 10px; letter-spacing: -0.015em; }
main h2 { font-size: 20px; margin: 34px 0 10px; padding-bottom: 6px; border-bottom: 1px solid var(--border); }
main h3 { font-size: 16.5px; margin: 24px 0 8px; color: var(--accent); }
main h4 { font-size: 15px; margin: 20px 0 6px; }
main h5 { font-size: 14px; margin: 16px 0 6px; }
p, li { color: var(--text-2); max-width: 78ch; }
p, li, blockquote, h1, h2, h3, h4, h5 { overflow-wrap: break-word; }
blockquote { margin: 12px 0; padding: 8px 14px; border-left: 3px solid var(--accent); background: var(--accent-soft);
  border-radius: 0 8px 8px 0; }
blockquote p { color: var(--text); margin: 4px 0; }
a { color: var(--accent); }
code { font-family: 'JetBrains Mono', ui-monospace, monospace; font-size: 0.86em; background: var(--surface-alt);
  padding: 1px 5px; border-radius: 4px; overflow-wrap: anywhere; }
pre { background: var(--surface-alt); border: 1px solid var(--border); border-radius: 8px; padding: 12px 14px;
  overflow-x: auto; font-size: 12.5px; line-height: 1.5; }
pre code { background: none; padding: 0; overflow-wrap: normal; }
pre.mermaid { background: var(--surface); text-align: center; font-family: inherit; }
.table-wrap { overflow-x: auto; margin: 10px 0 14px; border: 1px solid var(--border); border-radius: 8px; }
table { border-collapse: collapse; width: 100%; font-size: 13.5px; }
th { background: var(--surface-alt); text-align: left; font-weight: 600; color: var(--text); }
th, td { padding: 7px 10px; border-bottom: 1px solid var(--border); vertical-align: top; }
td { color: var(--text-2); }
tr:last-child td { border-bottom: none; }
td code, th code { white-space: nowrap; }
hr { border: none; border-top: 1px dashed var(--border); margin: 36px 0; }
.menu-toggle { display: none; }
@media (max-width: 900px) {
  .layout { display: block; }
  .sidebar { position: static; height: auto; border-right: none; border-bottom: 1px solid var(--border); padding-inline: 16px; }
  .sidebar nav { display: none; }
  .sidebar.open nav { display: block; }
  .menu-toggle { display: inline-block; margin-top: 6px; font: inherit; font-size: 13px; padding: 4px 10px;
    border-radius: 6px; border: 1px solid var(--border); background: var(--surface); color: var(--text); }
  main { padding-inline: 16px; }
  .doc-head h1 { font-size: 24px; }
  table:has(th:nth-child(4)) { min-width: 680px; }
}
"""


def md_to_html(text):
    md = markdown.Markdown(
        extensions=["tables", "fenced_code", "toc", "sane_lists"],
        extension_configs={"toc": {"slugify": slugify_unicode, "permalink": False}},
    )
    return md.convert(text)


def postprocess(body, prefix):
    body = re.sub(r'<pre><code class="language-mermaid">(.*?)</code></pre>',
                  lambda m: f'<pre class="mermaid">{m.group(1)}</pre>', body, flags=re.S)
    body = body.replace("<table>", '<div class="table-wrap"><table>').replace("</table>", "</table></div>")
    body = re.sub(r'id="([^"]+)"', lambda m: f'id="{prefix}-{m.group(1)}"', body)
    body = re.sub(r'href="#([^"]+)"', lambda m: f'href="#{prefix}-{m.group(1)}"', body)
    for name, anchor in FILE_ANCHOR.items():
        body = body.replace(f'href="{name}"', f'href="#{anchor}"')
    body = re.sub(r'href="(\.\./\.\./[^"]+|\.\./[^"]+)"', 'href="#f-readme"', body)
    return body


def build():
    sections, nav_items, mermaid_blocks, leaf_count = [], [], [], 0
    for name in ORDER:
        text = SWITCHER.sub("", (DOC_DIR / name).read_text(encoding="utf-8"), count=1)
        mermaid_blocks += [(name, b) for b in re.findall(r"```mermaid\n(.*?)```", text, flags=re.S)]
        anchor = FILE_ANCHOR[name]
        render_text = re.sub(r"^# .+\n", "", text, count=1) if name.startswith("README") else text
        body = postprocess(md_to_html(render_text), anchor)
        sections.append(f'<section class="file" id="{anchor}">{body}</section>')
        h1 = re.search(r"^# (.+)$", text, flags=re.M).group(1)
        leaves = re.findall(r"^## (\d+\.\d+) ([A-Z]+-\d+) — (.+)$", text, flags=re.M)
        leaf_count += len(leaves)
        if name.startswith("README"):
            nav_items.append(f'<a href="#{anchor}">{L["contents"]}</a>')
        elif leaves:
            links = "".join(
                f'<a href="#{anchor}-{slugify_unicode(f"{n} {c} — {t}", "-")}"><span class="code">{c}</span>{html.escape(t)}</a>'
                for n, c, t in leaves)
            title = html.escape(re.sub(r"^\d+\.\s*", "", h1).replace(L["group_prefix"], ""))
            nav_items.append(f'<details><summary>{title}</summary><a href="#{anchor}">{L["overview"]}</a>{links}</details>')
        else:
            nav_items.append(f'<a href="#{anchor}">{html.escape(h1)}</a>')

    group_count = sum(1 for n in ORDER if re.match(r"0[1-8]-", n))
    head = f"""<title>{L["title"]}</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;600;700;800&family=JetBrains+Mono:wght@400;500&display=swap">
<style>{CSS}</style>"""
    page = f"""{head}
<div class="layout">
  <aside class="sidebar" id="sidebar">
    <div class="brand">HandLive</div>
    <div class="brand-sub">{L["sub"]}</div>
    <button class="menu-toggle" type="button" onclick="document.getElementById('sidebar').classList.toggle('open')">{L["menu"]}</button>
    <nav>{''.join(nav_items)}</nav>
  </aside>
  <main>
    <div class="doc-head">
      <h1>{L["h1"]}</h1>
      <div class="meta"><span>{L["version"]}</span><span>2026-09-25</span><span>{group_count} {L["groups"]}</span><span>{leaf_count} {L["leaves"]}</span><span>Android · macOS · iOS · Relay</span></div>
    </div>
    {''.join(sections)}
  </main>
</div>
"""
    (OUT_DIR / f"handlive-detailed-design{L['out']}.html").write_text(page, encoding="utf-8")
    preview = ('<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">'
               + page +
               '<script src="https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.min.js"></script>'
               '<script>mermaid.initialize({startOnLoad:true, theme: matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "default"});</script>')
    (OUT_DIR / f"preview-local{L['out']}.html").write_text(preview, encoding="utf-8")

    checks = "".join(f'<pre class="src" data-file="{html.escape(f)}">{html.escape(b)}</pre>' for f, b in mermaid_blocks)
    check_page = f"""<!doctype html><meta charset="utf-8"><title>Mermaid check</title>
<script src="https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.min.js"></script>
<body>{checks}<div id="out">running</div>
<script>
(async () => {{
  mermaid.initialize({{ startOnLoad: false }});
  const res = [];
  for (const [i, el] of [...document.querySelectorAll('pre.src')].entries()) {{
    try {{ await mermaid.parse(el.textContent); res.push({{i, file: el.dataset.file, ok: true}}); }}
    catch (e) {{ res.push({{i, file: el.dataset.file, ok: false, err: String(e.message || e).slice(0, 300), head: el.textContent.slice(0, 120)}}); }}
  }}
  window.__results = res;
  document.getElementById('out').textContent = JSON.stringify({{total: res.length, failed: res.filter(r => !r.ok)}});
}})();
</script></body>"""
    (OUT_DIR / f"mermaid-check{L['out']}.html").write_text(check_page, encoding="utf-8")
    print(f"sections={len(sections)} leaves={leaf_count} mermaid={len(mermaid_blocks)} "
          f"html_kb={len(page.encode()) // 1024}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Export docs/detailed-design as one HTML page")
    parser.add_argument("--lang", choices=sorted(LABELS), default="en")
    select_language(parser.parse_args().lang)
    build()
