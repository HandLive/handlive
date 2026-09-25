English | [Tiếng Việt](03-kieu-chu.vi.md)

# Typography

HandLive uses San Francisco through the system text styles on Mac, iPhone, and iPad; Inter with the
same size scale on Android; and Be Vietnam Pro only for brand titles. This section covers the type
scale, minimum sizes, and the rules for Vietnamese text.

HIG source: https://developer.apple.com/design/human-interface-guidelines/typography

## Fonts by platform

| Used for | macOS, iOS, iPadOS | Android |
|---|---|---|
| Interface | SF Pro, through text styles; don't embed font files | Inter, bundled with the app (OFL) |
| Code, numbers | SF Mono (`design: .monospaced`) | Roboto Mono |
| Brand titles | Be Vietnam Pro, bundled with the app | Be Vietnam Pro |

Under Apple's license, SF Pro and SF Mono may only be used on Apple platforms: don't embed them in the
Android app, and don't use them in a logo.

## macOS: fixed type scale

macOS has no Dynamic Type; text sizes follow the table below.

| Token | Text style | Size/line (pt) | Weight | Emphasis |
|---|---|---|---|---|
| `mac-large-title` | Large Title `.largeTitle` | 26/32 | Regular | Bold |
| `mac-title-1` | Title 1 `.title` | 22/26 | Regular | Bold |
| `mac-title-2` | Title 2 `.title2` | 17/22 | Regular | Bold |
| `mac-title-3` | Title 3 `.title3` | 15/20 | Regular | Semibold |
| `mac-headline` | Headline `.headline` | 13/16 | Bold | Heavy |
| `mac-body` | Body `.body` | 13/16 | Regular | Semibold |
| `mac-callout` | Callout `.callout` | 12/15 | Regular | Semibold |
| `mac-subheadline` | Subheadline `.subheadline` | 11/14 | Regular | Semibold |
| `mac-footnote` | Footnote `.footnote` | 10/13 | Regular | Semibold |
| `mac-caption-1` | Caption 1 `.caption` | 10/13 | Regular | Medium |
| `mac-caption-2` | Caption 2 `.caption2` | 10/13 | Medium | Semibold |

For text inside controls (buttons, menus, text fields), let the control choose the font; set text
styles only on content text.

## iOS and iPadOS: Dynamic Type

Default size (Large). Android uses the `android-*` tokens with the same suffixes (`ios-body` ↔
`android-body`), with the same size, line height, and weight, in sp.

| Token | Text style | Size/line (pt) | Weight | Emphasis |
|---|---|---|---|---|
| `ios-large-title` | `.largeTitle` | 34/41 | Regular | Bold |
| `ios-title-1` | `.title` | 28/34 | Regular | Bold |
| `ios-title-2` | `.title2` | 22/28 | Regular | Bold |
| `ios-title-3` | `.title3` | 20/25 | Regular | Semibold |
| `ios-headline` | `.headline` | 17/22 | Semibold | Semibold |
| `ios-body` | `.body` | 17/22 | Regular | Semibold |
| `ios-callout` | `.callout` | 16/21 | Regular | Semibold |
| `ios-subheadline` | `.subheadline` | 15/20 | Regular | Semibold |
| `ios-footnote` | `.footnote` | 13/18 | Regular | Semibold |
| `ios-caption-1` | `.caption` | 12/16 | Regular | Semibold |
| `ios-caption-2` | `.caption2` | 11/13 | Regular | Semibold |

Tracking: SF adjusts it by size on its own. The `android-*` tokens use Inter's dynamic tracking (Body
−0.013 em instead of SF's −0.026 em).

The extra typography fields — `relativeTo` (scaling with Dynamic Type), `emphasisWeight` (the Emphasis
column), `fontFeatures` (such as `tnum` for `timer`) — live in
`shared/design-tokens/type-extras.json`, separate from `tokens.json` to keep the artifact's format;
the code generators read both.

## Body from xSmall to AX5

| xSmall | Small | Medium | Large | xLarge | xxLarge | xxxLarge | AX1 | AX2 | AX3 | AX4 | AX5 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 14/19 | 15/20 | 16/21 | 17/22 | 19/24 | 21/26 | 23/29 | 28/34 | 33/40 | 40/48 | 47/56 | 53/62 |

- Layouts hold up at every size, including AX1–AX5 (Larger Text in the Accessibility settings). At
  accessibility sizes (`dynamicTypeSize.isAccessibilitySize`), rows with an icon, text, and a value
  switch to a vertical stack.
- The HIG requires text to scale to at least 200%. Android: font scale up to 200% (Android 14 scales
  nonlinearly); both text size and line height are in sp.
- Icons that carry meaning scale with the text; SF Symbols scale on their own when set with the same
  text style.

## Minimum sizes and weights

| Platform | Default | Minimum |
|---|---|---|
| iOS, iPadOS | 17 pt | 11 pt |
| macOS | 13 pt | 10 pt |
| Android | 17 sp | 11 sp |

- Don't use Ultralight, Thin, or Light, especially at small sizes. Use Regular, Medium, Semibold,
  Bold; Heavy is only the emphasis weight of Headline on macOS.
- Emphasize according to the "Emphasis" column: SwiftUI `.bold()` or `.fontWeight(_:)`, UIKit
  `traitBold`.
- Build hierarchy with weight, size, and color (`label`, `secondary-label`); don't add any typeface
  besides the system font and Be Vietnam Pro.

## Brand type

| Token | Size/line | Weight | Scales with | Used for |
|---|---|---|---|---|
| `brand-large-title` | 34/41 | Bold | `.largeTitle` | Titles of the welcome and pairing screens; at most once per screen |
| `brand-title` | 22/28 | Semibold | `.title2` | Empty-state titles, `Onboarding` steps |
| `wordmark` | 20/24 | Bold | `.title3` | The word HandLive in place of a logo, in `brand-fire` or `label` |

- Scale with Dynamic Type: `Font.custom("BeVietnamPro-Bold", size: 34, relativeTo: .largeTitle)`;
  UIKit `UIFontMetrics(forTextStyle:)`. macOS keeps fixed sizes.
- Support Bold Text: when `legibilityWeight == .bold`, go up one weight; Android 12+ reads
  `Configuration.fontWeightAdjustment`.
- Don't use Be Vietnam Pro for body text, buttons, or control labels.

## Vietnamese text

- Capital letters with stacked diacritics (Ấ, Ổ, Ặ, Ộ) are taller than unaccented Latin letters: don't
  reduce line height below the text style's value, and don't set a fixed height that clips the
  letters. Check the first line of titles and the text inside buttons.
- Don't use ALL CAPS: diacritics become hard to read, and the HIG has dropped uppercase headers. iOS
  16–18 uppercases `List` section headers on its own, so add `.textCase(nil)`.
- Test at AX5 (iOS) and 200% (Android) with real, long strings: "Nguyễn Thị Ngọc Huyền", "Đã kết nối
  qua cùng mạng Wi-Fi" ("Connected via the same Wi-Fi network"). Text wraps and never breaks in the
  middle of a word; a caller's name gets two lines before it's truncated.
- Don't add letter-spacing beyond the tokens to text with diacritics.

## Numbers and codes

| Token | Size/line | Weight | How it's built | Example |
|---|---|---|---|---|
| `code-pin` | 28/34 | Semibold | Apple `.system(.title, design: .monospaced)`, Android Roboto Mono; tracking 0.15 em | A PIN in groups of three digits: "482 915" |
| `timer` | 17/22 | Medium | SwiftUI `.monospacedDigit()`, AppKit `NSFont.monospacedDigitSystemFont(ofSize:weight:)`, Android `fontFeatureSettings = "tnum"` | Duration "02:15" |

Equal-width digits keep counters from jumping. `code-pin` scales with `.title` on iOS.

## API

| Platform | API |
|---|---|
| SwiftUI | `Font.TextStyle`, `.font(.body)`, `Font.custom(_:size:relativeTo:)`, `.monospacedDigit()`, `dynamicTypeSize`, `legibilityWeight` |
| UIKit | `UIFont.preferredFont(forTextStyle:)`, `adjustsFontForContentSizeCategory`, `UIFontMetrics` |
| AppKit | `NSFont.preferredFont(forTextStyle:)`, `NSFont.systemFont(ofSize:weight:)` |
| Compose | `TextStyle(fontFamily = Inter, fontSize = 17.sp, lineHeight = 22.sp, letterSpacing = (-0.013).em)`, gathered in HandLive's own type set (not the Material type scale) |

## Dos and don'ts

| Do | Don't |
|---|---|
| Use the system text styles | Set fixed text sizes on iOS |
| Scale the brand font with Dynamic Type | Use Be Vietnam Pro for body text |
| Test text with diacritics at AX5 and 200% | Reduce line height to make things tighter |
| Use equal-width digits for counters | Put titles in all caps |
