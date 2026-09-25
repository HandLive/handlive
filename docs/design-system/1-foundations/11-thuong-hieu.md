English | [Tiếng Việt](11-thuong-hieu.vi.md)

# Branding

HandLive's brand lives in the content layer: the welcome screen, the pairing screen, empty states, the
app icon, and the HandLive wordmark. Controls, status, and navigation bars keep the system's look.
This section covers the story, the palette, the type, and the limits.

HIG source: https://developer.apple.com/design/human-interface-guidelines/branding

## Story

The palette is the Sơn Đầu Hỏa feng-shui palette: Sơn Đầu Hỏa, "fire on the mountaintop", is one of
the Fire destiny elements in Vietnamese feng shui. In the past, people lit signal fires on mountaintops
to pass messages from one station to the next; HandLive does the same between a phone and a computer.
Personality: trustworthy, discreet, warm. Following the HIG, the brand makes room for content: no
logos scattered around, no unnecessary decoration.

## Palette

| Role | Token | Light / Dark | Five Elements | Used for |
|---|---|---|---|---|
| Identity | `brand-fire` (vermilion) | #d2381f / #ff6b4a | Fire, the destiny element's own color | The HandLive wordmark, app icon, welcome screen |
| Deep areas | `brand-ember` (ember red) | #8a2210 / #b43a20 | Fire | Large blocks on covers, the app icon's background layer, in place of black |
| Highlights | `brand-flame` (flame orange) | #f07a1a / #ff9a3d | Fire | Brand gradient, illustrations; never a text color |
| Brand background | `brand-glow` (peach) | #fde9e2 / #3b1a12 | Fire | Background of the welcome and pairing screens |
| Actions | `accent`, `accent-fill` (green) | #197934 / #3ddc6c | "Wood feeds Fire", a supporting element | AccentColor |
| Neutral | System grays | Follows the system | Metal; Fire overcomes Metal, so it may be used | Backgrounds, text, borders |
| Secondary accents | `system-pink`, `system-purple`; rarely `system-yellow`, `system-brown` | Follows the system | Fire; Earth | Letter avatars, illustrations |
| Not used | Black, `systemBlue`, `systemCyan`, `systemTeal`, `systemMint`, `systemIndigo` | — | Water overcomes Fire | Not for the brand or large color areas |

The system's dark backgrounds (black on iPhone, gray on Mac) belong to Apple; HandLive adds no black or
blue areas of its own. Every brand color has all 4 variants, including the two Increased Contrast ones
(see Color).

## Where brand color goes

| Yes | No |
|---|---|
| `Onboarding`: the welcome screen with a `brand-glow` background and a `brand-large-title` title | Buttons, switches, `SegmentedControl`, links |
| `PairingCard`: a `brand-glow` background around the white QR code frame | Status dots, badges, error text |
| Empty states: a signal-fire illustration | `MenuBarMenu`, `CallPanel`, tab bars, `Notification` |
| The app icon, the HandLive wordmark (`wordmark`) | Settings, the message list |

- HIG: to express the brand with color, put the color in the content layer, where it scrolls under the
  glass controls and the glass "picks up" the color; don't tint controls with the brand color.
- Vermilion isn't used for buttons or status, so it can't be mistaken for the cancel, delete, and
  error color (systemRed).
- At most one brand moment per screen.

## Accent color on controls

Per the HIG, the accent color is used sparingly on controls:

- Primary button: one button tinted `accent-fill` per screen, two at most.
- Status indicators: the `unread` indicator, the selected tab icon, the `bubble-outgoing` bubbles of
  messages you send, links.
- On glass: tint the background of one primary action, never text or symbols.
- iOS switches keep the system's default green.
- Mac: when the user chooses an accent color other than Multicolor, controls follow that color; the
  brand identity doesn't depend on the accent color.

## Brand type

- Be Vietnam Pro (OFL), designed for Vietnamese, with clear diacritics at large sizes; bundled with the
  app on both Apple platforms and Android.
- Only for `brand-large-title`, `brand-title`, `wordmark`; scales with Dynamic Type and supports Bold
  Text (see Typography). Body text, buttons, and control labels use the system font.

## Logo and the HandLive wordmark

- There's no logo yet. Until there is, use the word "HandLive" in the `wordmark` style (Be Vietnam Pro
  Bold 20/24), in `brand-fire` or `label`.
- The wordmark appears only on the welcome screen and in the About window; don't scatter logos across
  the app, and don't put one in navigation bars.
- Don't use SF Symbols, the San Francisco font, or shapes easily mistaken for symbols in the logo or
  the app icon: Apple's license doesn't allow it.

## Launch screen

- No branding on the launch screen. iOS: the launch screen looks like the app's first screen, with no
  text and no logo. macOS has no launch screen.
- Android 12+: the system's launch screen (the app icon on a background); don't add a custom splash
  screen.
- The brand moment belongs in `Onboarding`: the welcome screen with a `brand-glow` background and a
  `brand-large-title` title.

## Apple trademarks

- The app's name is "HandLive"; don't combine Apple trademarks with the app name or the app icon. Store
  descriptions use "for Mac", "for iPhone and iPad". The internal names "HandLive for Mac" and
  "HandLive for iOS/iPadOS" in the detailed design aren't used as display names.
- Spell them correctly: iPhone, iPad, Mac, macOS, iOS, iPadOS, Liquid Glass; not "IPhone", "MacOS",
  "Macbook".
- Don't draw Apple hardware in illustrations; when you need a picture of a device, use the SF Symbols
  product symbols, and only on Apple platforms.

## Dos and don'ts

| Do | Don't |
|---|---|
| Brand color on the welcome and pairing screens | Primary buttons in `brand-fire` |
| The HandLive wordmark set in `wordmark` | A logo assembled from SF Symbols |
| The welcome screen in `Onboarding` | A logo on the launch screen |
| Ember red in place of black | Custom black or blue backgrounds |
