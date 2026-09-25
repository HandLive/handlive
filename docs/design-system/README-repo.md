English | [Tiếng Việt](README-repo.vi.md)

# The design system's copy in this repo

This folder is the source copy of the "HandLive Design System" artifact
(https://claude.ai/artifact/2rsmYxBjxXrd12FByTd9vT, version 6): `README.md` (principles, brand),
`1-foundations/`, `2-patterns/`, `3-platforms/`, `components/<Tên>/README.md` + `preview.html` (one
folder per component name), `components/bundle.css` (web previews only), `tokens.json`. The tokens
also live in `shared/design-tokens/tokens.json` for code generation (Compose `HandLiveTheme`, Asset
Catalog Color Sets, CSS).

Edit here first, then republish the artifact; the two copies must match. The HTML previews use
Material Symbols in place of SF Symbols only so they can be viewed on the web; the Apple apps use SF
Symbols according to the table in `1-foundations/06-bieu-tuong.md`.
