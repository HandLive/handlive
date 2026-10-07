English | [Tiếng Việt](brand-guidelines.vi.md)

# HandLive brand guidelines

Version 1.2, 2026-10-07. The source of truth for HandLive's story, voice, messages, logo, app icon,
colors, and promo images. How the brand appears inside the apps (where brand color may go, the welcome
screen, the wordmark in the UI) is in the design system: [Branding](design-system/1-foundations/11-thuong-hieu.md).

## Quick reference

| Element | Value |
|---|---|
| Name | HandLive: one word, capital H and L. Never "Handlive", "Hand Live", or "HL" in public copy |
| Tagline | Never miss a signal. |
| Descriptor | Your Android phone's clipboard, SMS, and calls on your Mac, iPhone, and iPad. |
| Mark | A signal fire on a mountaintop, with its signal going out |
| Brand colors | `brand-fire` #e63d1a, `brand-flame` #ff861f, `brand-ember` #33232d, `brand-glow` #fff0e3 |
| Action color | `accent` green #197934 (Dark #3ddc6c) |
| Brand type | Be Vietnam Pro Bold (SIL OFL 1.1) |
| Voice | Clear, calm, warm, honest |
| Files | `docs/brand/assets/` (logo, app icon, promo), built by `tools/brand/build_brand_assets.py` |

## 1. Story

HandLive keeps an Android phone in step with its owner's Mac, iPhone, and iPad. The moment something
happens on the phone (you copy a link, a text arrives, someone calls), it shows up on the screen in
front of you. Only your devices can read it: the data is end-to-end encrypted, and the relay in the
middle sees nothing.

The logo draws that moment as a signal fire on a mountaintop, sending its light to the devices around
it, in three shapes:

| Shape | Meaning |
|---|---|
| Mountain (plum) | Your phone: steady, always there |
| Flame (red to amber) | What just happened: a copy, a message, a call |
| Rings (orange, fading out) | The signal going out to your other devices |

The colors are those of dawn: warm and calm. HandLive should feel like a lamp left on, not an alarm.

## 2. Positioning

| Item | HandLive |
|---|---|
| For | People who carry an Android phone and work on a Mac, often with an iPad or an iPhone too |
| Problem | Apple's continuity features stop at Apple devices. Android people email links to themselves, read SMS codes off the phone, and miss calls at the desk |
| Promise | What happens on your phone shows up on your screen, privately |
| Proof | End-to-end encryption you cannot turn off; QR pairing; works on the local network with no account; the cloud relay is zero-knowledge; native apps that follow Apple's and Android's own design; open source (Apache-2.0) |
| What it isn't | Not a cloud service, not remote control or screen mirroring, not an Apple or Google product |

## 3. Personality and voice

| Trait | We are | We are not |
|---|---|---|
| Trustworthy | Exact about what happens to data | Vague, or "trust us" |
| Discreet | Quiet, in the background until needed | Chatty, pushy with notifications |
| Warm | Human, plain, a little light | Cute, jokey in errors, full of emoji |
| Precise | Numbers and facts ("under 50 ms") | Superlatives ("blazing fast", "best") |

### Tone by context

| Context | Tone | Example |
|---|---|---|
| Onboarding, pairing | Warm, one step at a time | "Scan this code with your phone." |
| Success | Brief, then out of the way | "Paired with Pixel 9." |
| Errors | Calm, says what to do next | "Your phone isn't reachable. Check that both are on the same Wi-Fi." |
| Privacy, permissions, legal | Plain and complete, no fear | "Messages are encrypted on your phone and decrypted only on your Mac." |
| Release notes | Factual, user-first | "Calls: you can now decline from the Mac." |
| Marketing | Confident, concrete | "Never miss a signal. Your phone's texts and calls, right on your Mac." |

### Writing rules

- Short sentences; start with the verb in instructions ("Scan", "Allow", "Pair").
- Say what happens to the data whenever data moves.
- Numbers over adjectives; claims we can show.
- English UI text uses Apple's English style (title-style capitalization for buttons, menus, window
  titles). Vietnamese uses Apple-style diacritics (hủy, xóa, mã hóa) and the design system's terms
  ("bảng nhớ tạm", not "clipboard"). Details: [Writing](design-system/1-foundations/09-viet-noi-dung.md).

### Words

| Use | Avoid | Why |
|---|---|---|
| end-to-end encrypted | military-grade, unhackable | Exact, and true |
| pair, paired | link up, hook up | One word for one action |
| your phone, your Mac | the device, the endpoint | People own devices, not endpoints |
| relay (when we must name it) | cloud sync | Nothing is stored in a cloud |
| works with iPhone and iPad; for Mac | for Apple, Apple Continuity for Android | Apple trademark rules (section 11) |
| simple, quick | seamless, revolutionary, magic | Overused, says nothing |

## 4. Messages

| Item | English | Vietnamese |
|---|---|---|
| Tagline | Never miss a signal. | Không bỏ lỡ tín hiệu nào. |
| One-liner | Your Android phone's clipboard, SMS, and calls, on your Mac, iPhone, and iPad. | Bảng nhớ tạm, SMS và cuộc gọi từ điện thoại Android, ngay trên Mac, iPhone và iPad. |
| App Store subtitle (≤ 30) | Your phone's texts and calls | Tin nhắn, gọi từ điện thoại |
| Play short description (≤ 80) | Clipboard, SMS, and calls from your phone on your Mac, iPhone, and iPad. | Bảng nhớ tạm, SMS và cuộc gọi từ điện thoại lên Mac, iPhone và iPad. |
| Store description, first paragraph | Your Android phone, within reach. HandLive brings clipboard, SMS, and calls to your Mac, iPhone, and iPad — end-to-end encrypted, no account needed, open source. | Điện thoại Android, ngay trong tầm tay. HandLive đưa bảng nhớ tạm, SMS và cuộc gọi lên Mac, iPhone và iPad — mã hóa đầu cuối, không cần tài khoản, mã nguồn mở. |

### Elevator pitch

HandLive brings your Android phone to your Mac, iPhone, and iPad. Copy on one, paste on the other.
Read and answer texts, see who's calling, and answer or decline from your desk. Everything is
end-to-end encrypted, works on your own Wi-Fi without an account, and the code is open source.

### Message pillars

| Pillar | Message | Proof |
|---|---|---|
| Right where you are | What happens on your phone shows up on the screen in front of you | Clipboard in under 50 ms on the same network; SMS and call details on Mac and iPhone |
| Private by design | Only your devices can read your data | E2E always on, QR pairing, zero-knowledge relay |
| Native and open | Feels like it belongs on each device; anyone can read the code | Apple HIG on every platform, Apache-2.0 |

### By audience

| Audience | Lead with |
|---|---|
| Mac people with an Android phone | "Your texts and calls, right on your Mac." |
| Privacy-minded people | "End-to-end encrypted. No account. Open source." |
| Developers, contributors | "Open source, WebSocket for data and Bluetooth for voice; come build it with us." |

### Boilerplate

HandLive is an open-source app that keeps an Android phone in step with a Mac, iPhone, and iPad:
clipboard, SMS, and calls, end-to-end encrypted, with no account required. It is free software under
the Apache-2.0 license.

## 5. Logo

### Parts and files

| Part | File (`docs/brand/assets/logo/`) | Use |
|---|---|---|
| Mark | `handlive-mark.svg`, `-on-dark.svg` | App badges, avatars, favicons from 33 px up |
| Compact mark | `handlive-mark-compact.svg` | 16–32 px: the outer ring is dropped |
| One-color mark | `handlive-mark-mono-black.svg`, `-mono-white.svg` | Embossing, single-color print, themed icons |
| Wordmark | `handlive-wordmark.svg`, `-on-dark.svg` | Where the mark already appears nearby |
| Horizontal lockup | `handlive-lockup-horizontal.svg`, `-on-dark.svg` | Default: README, website header, slides |
| Stacked lockup | `handlive-lockup-stacked.svg`, `-on-dark.svg` | Square spaces, posters, splash art |

Every SVG has a PNG next to it. The wordmark is Be Vietnam Pro Bold, tracked −0.01 em, converted to
outlines: the files don't need the font.

### Construction

- One geometry on a 1024 grid (`tools/brand/brand_geometry.py`): a mountain with a rounded summit and a
  lit left face, a flame above the summit with a hot core, and two rings of signal at ±36°.
- In the horizontal lockup the mountain's base sits on the wordmark's baseline.
- Don't redraw, trace, or re-space the logo; change the generator and rebuild.

### Clear space and minimum size

- Clear space on every side: at least the width of the flame (about a quarter of the mark's width).
- Mark: 33 px and up; compact mark from 16 to 32 px. Horizontal lockup: 120 px wide and up. Print:
  mark 10 mm, lockup 30 mm.

### Color versions

| Background | Version |
|---|---|
| White, `brand-glow`, light photos | Full color (plum mountain, plum wordmark) |
| Black, dark gray, `brand-ember` | On-dark (mauve mountain, cream wordmark) |
| One ink only | One-color black or white; the flame's core is cut out |

### Don'ts

- Don't recolor parts, add shadows, outlines, or glow, or put the logo on a busy photo.
- Don't rotate, stretch, or rearrange the flame, rings, and mountain.
- Don't set "HandLive" in another font, or use the wordmark without enough contrast.
- Don't combine the logo with Apple or Google logos, product names, or hardware.

## 6. App icon

| Platform | What ships | Where |
|---|---|---|
| macOS, iOS, iPadOS | One Icon Composer document (Liquid Glass) for both apps: rings, fire, and mountain layers over a dawn fill (night fill and on-dark mountain in Dark); Xcode renders the macOS 13–15 and iOS 16–18 icons from it | `apple/macOS/HandLive/Resources/AppIcon.icon` (both targets) |
| Android | Adaptive icon: dawn background layer, foreground layer, monochrome layer for themed icons (Android 13+) | `android/app/src/main/res/` (`mipmap-anydpi`, `drawable`) |
| App Store, Play Store | 1024 px (App Store, from the iOS icon), 512 px no alpha (Play) | `docs/brand/assets/app-icon/` |
| Icon Composer (Liquid Glass) | `AppIcon.icon` (the same document as the apps) and its preview sheets; square, unmasked background and foreground layers for other tools | `docs/brand/assets/app-icon/icon-composer/` |

- No text, no SF Symbols, no Apple hardware in the icon; don't add highlights or shadows on iOS: the
  system adds them.
- The Dark icon keeps the same flame on a night-plum background; the Tinted icon is grayscale and the
  system tints it.
- **No compact mark on the Mac app icon** (project owner's decision, 2026-10-07). Xcode 27's `actool` renders
  every older-OS icon from the `.icon` and cannot keep hand-drawn small sizes beside it, so macOS 13–15 show the
  generated icon at 16 and 32 pt too, with both pairs of rings. The compact mark still serves other small places
  (the website favicon, any artwork from 16 to 32 px): see Clear space and minimum size.
- The Mac app also ships every size in `AppIcon.icns` (16–512 pt at 1× and 2×,
  `ASSETCATALOG_COMPILER_STANDALONE_ICON_BEHAVIOR: all`); the asset catalog holds 2× renditions only.
- `handlive-app-icon.png` (and Dark, Tinted, the macOS tile) in `docs/brand/assets/app-icon/` are flat artwork for
  docs and marketing; no app ships them.

## 7. Color

### Primary Colors

| Token | Light | Dark | Light · IC | Dark · IC | Role |
|---|---|---|---|---|---|
| `brand-fire` | #e63d1a | #ff7448 | #b82c10 | #ff8f6b | Identity: the flame's base, large brand titles, the app icon |
| `brand-flame` | #ff861f | #ffa04a | #f07410 | #ffb066 | The flame's body, the inner ring, highlights in illustrations; never text |

### Secondary Colors

| Token | Light | Dark | Light · IC | Dark · IC | Role |
|---|---|---|---|---|---|
| `brand-ember` | #33232d | #6e5463 | #2a1c25 | #83677a | Plum: the mountain, the logo's ink, deep blocks on covers; in place of black |
| `brand-glow` | #fff0e3 | #2b1e26 | #ffe6d2 | #33242e | Dawn cream: the background of brand moments (welcome, pairing) |
| `accent` | #197934 | #3ddc6c | #146b2e | #5be584 | Actions: one primary button per screen, links, unread, sent bubbles |

IC: Increased Contrast. Token values live in `shared/design-tokens/tokens.json` (copy:
`docs/design-system/tokens.json`); apps generate their colors from it.

### Neutral Palette

Apple's system grays and backgrounds, through the system API on Apple platforms and the tokens on
Android. HandLive adds no black or gray surfaces of its own: deep brand areas use `brand-ember`.

### Logo artwork colors

Used only inside the logo, the app icon, and promo images (not tokens):

| Name | Hex | Where |
|---|---|---|
| Flame tip | #ffb83d | Top of the flame gradient (`brand-fire` → `brand-flame` → tip) |
| Flame core | #fff6e0 | The hot core inside the flame |
| Outer ring | #ffc68c | The outer ring, fading out |
| Mountain, lit face | #4b3542 | Left face of the mountain |
| Dawn sky | #fff6ee → #ffe3cf | Icon and promo background, top to bottom |
| Night sky | #2b1e26 → #1c1319 | Dark icon background |
| On-dark mountain | #6e5463, lit #83677a | Mark on dark backgrounds |

### Semantic Colors

Status keeps the system's colors (`system-red` for errors and destructive actions, `system-orange`,
`system-green`). `brand-fire` is never a button, status, or error color, so it can't be mistaken for
delete or cancel.

### Rules and contrast

- Brand color lives in the content layer: the welcome and pairing screens, empty states, the icon, the
  logo. Controls keep the system look and the green `accent`.
- At most one brand moment per screen.
- Blue stays the system's: HandLive's links and selections use `accent`, and the brand adds no blue
  surfaces, so it never reads as a system utility.
- `brand-fire` as text is for large titles only: 4.16:1 on white and 3.73:1 on `brand-glow` in Light
  (minimum 3:1 for large text), 5.2–7.8:1 in Dark on the seven system backgrounds.
- `brand-ember` as text reaches 12.5:1 or more on light backgrounds; body text still uses `label`.

## 8. Typography

```css
--font-heading: 'Be Vietnam Pro', Inter, -apple-system, system-ui, sans-serif;
--font-body: -apple-system, system-ui, Inter, sans-serif;
--font-mono: 'SF Mono', ui-monospace, 'JetBrains Mono', monospace;
```

- Be Vietnam Pro Bold: the wordmark, `brand-large-title`, `brand-title`, and promo headlines. Designed
  for Vietnamese, so diacritics stay clear at large sizes. Bundled under the SIL OFL 1.1. The website also
  uses ExtraBold and Black for display titles, tracked tight (−0.03 to −0.04 em).
- Everything else uses the system font: San Francisco on Apple platforms, Inter on Android; the website
  uses the reader's system font stack.
- San Francisco and SF Symbols never appear in the logo, the icon, or marketing images (Apple's
  license allows them only in interfaces running on Apple platforms).

## 9. Imagery and illustration

- Flat geometric shapes taken from the mark: rounded mountains, flames, rings. Dawn gradient
  backgrounds; plum for depth.
- Real screenshots of the apps, never mock-ups drawn with Apple's UI kits; no drawn Apple hardware.
- No stock photos of people holding phones; no glowing "cyber" lock imagery for encryption.
- Base prompt when generating art with an AI model: "Flat geometric illustration, dawn palette: cream
  sky #fff6ee to #ffe3cf, plum mountains #33232d and #4b3542, a single flame in #e63d1a, #ff861f and
  #ffb83d, soft orange signal rings; calm, warm, minimal, generous empty space, no text, no devices."

## 10. Promo images

| File (`docs/brand/assets/promo/`) | Size | Use |
|---|---|---|
| `github-social-preview.png` | 1280 × 640 | Social preview of every HandLive repository on GitHub |
| `readme-hero.en.png`, `readme-hero.vi.png` | 1600 × 600 | Top of `README.md` and `README.vi.md` |
| `release-banner-beta.en.png`, `release-banner-beta.vi.png` | 1280 × 640 | Release notes and posts for `v0.1.0-beta.1` |

Layout: lockup top left; headline (the tagline) in Be Vietnam Pro Bold, plum; one or two supporting
lines in a softer plum (#6b5562); the mark large, bleeding off the bottom right.

## 11. Apple and Google trademarks

- The app's name is "HandLive". Store copy uses "for Mac", "works with iPhone and iPad"; never "Apple"
  in the name, the icon, or the logo.
- Spell trademarks correctly: iPhone, iPad, Mac, macOS, iOS, iPadOS; Android. Apple's feature names
  (Continuity, Handoff, AirDrop) describe Apple's features, not HandLive's.
- Android is a trademark of Google LLC; use Google Play badges only as Google supplies them.

## 12. Rebuilding the files

```bash
python3 tools/brand/build_brand_assets.py \
  --android-res android/app/src/main/res \
  --apple-icon apple/macOS/HandLive/Resources/AppIcon.icon --icon-preview \
  --android-design-res android/core/design/src/main/res \
  --apple-imageset apple/Packages/HLDesignSystem/Sources/HLDesignSystem/Resources/Images.xcassets
```

- Needs `rsvg-convert` and ImageMagick (`brew install librsvg imagemagick`).
- Text outlines are cached in `tools/brand/text-outlines.json`. After changing a text string, rerun with
  `--font BeVietnamPro-Bold.ttf` (needs fontTools); the font file itself is not committed.
- Platform files are written into the app repositories; commit them there, one repository per commit. The last
  two flags write the in-app mark of the welcome screens (`HLBrandMark` on Apple, the `HLBrandMark` composable
  on Android): a vector drawable with a night variant, and a PDF image set with light and dark appearances.
- `AppIcon.icon` comes from `tools/brand/icon_composer_writer.py`: `icon.json` plus one SVG per layer in
  `Assets/`. Apple publishes no schema for `icon.json`; the generator writes the keys Icon Composer saves, and
  Xcode 27's `actool` and `ictool` accept them. Tune glass, shadow, and translucency in the generator, not in
  Icon Composer, or the next rebuild undoes it. `--icon-preview` renders
  `icon-composer/AppIcon-preview.png` (rows iOS, macOS; columns Default, Dark, Tinted light, Tinted dark) and
  `icon-composer/AppIcon-preview-mac-sizes.png` (the Mac icon at 16, 32, 128, and 512 pt, actual size, one row per
  appearance) with the `ictool` inside Xcode's Icon Composer, so it needs Xcode 26 or later: the Xcode that
  `xcode-select -p` points at, or the path in the `ICTOOL` environment variable. A rerun leaves no diff.

## Changelog

| Version | Date | Changes |
|---|---|---|
| 1.2 | 2026-10-07 | The Mac app icon is the same Liquid Glass `AppIcon.icon` as iOS; no compact mark at 16 and 32 pt on the Mac app icon (project owner's decision); the `AppIcon.appiconset` is gone |
| 1.1 | 2026-10-07 | Liquid Glass app icon for iOS and iPadOS (`AppIcon.icon` from the generator); the Mac keeps the compact-mark set |
| 1.0 | 2026-10-01 | First guidelines: the signal fire at dawn (logo, app icon, voice, messages, promo); dawn values for the `brand-*` tokens |
