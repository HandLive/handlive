English | [Tiếng Việt](11-thuong-hieu.vi.md)

# Branding

HandLive's brand lives in the content layer: the welcome screen, the pairing screen, empty states, the
app icon, and the HandLive logo. Controls, status, and navigation bars keep the system's look.
This section covers how the brand shows up in the apps: the palette, the type, and the limits. The
story, voice, messages, logo files, and promo images are in the
[brand guidelines](../../brand-guidelines.md).

HIG source: https://developer.apple.com/design/human-interface-guidelines/branding

## Story

What happens on the phone shows up on the screen in front of you. The logo draws that as a signal
fire on a mountaintop, in the colors of dawn: flame red, orange, and amber over a plum mountain and a
cream sky.
Personality: trustworthy, discreet, warm. Following the HIG, the brand makes room for content: no
logos scattered around, no unnecessary decoration.

## Palette

| Role | Token | Light / Dark | Used for |
|---|---|---|---|
| Identity | `brand-fire` (flame red) | #e63d1a / #ff7448 | Large brand titles, the app icon, the welcome screen |
| Deep areas | `brand-ember` (plum) | #33232d / #6e5463 | The mountain in the logo, large blocks on covers, in place of black |
| Highlights | `brand-flame` (flame orange) | #ff861f / #ffa04a | The flame and signal rings, brand gradient, illustrations; never a text color |
| Brand background | `brand-glow` (dawn cream) | #fff0e3 / #2b1e26 | Background of the welcome and pairing screens |
| Actions | `accent`, `accent-fill` (green) | #197934 / #3ddc6c | AccentColor: the green light of a signal received |
| Neutral | System grays | Follows the system | Backgrounds, text, borders |
| Secondary accents | `system-pink`, `system-purple`; rarely `system-yellow`, `system-brown` | Follows the system | Letter avatars, illustrations |
| Not for the brand | Black, `systemBlue`, `systemCyan`, `systemTeal`, `systemMint`, `systemIndigo` | — | Blue belongs to the system; deep areas use `brand-ember` instead of black |

The system's dark backgrounds (black on iPhone, gray on Mac) belong to Apple; HandLive adds no black or
blue areas of its own, so it never reads as a system utility. Every brand color has all 4 variants,
including the two Increased Contrast ones (see Color).

## Where brand color goes

| Yes | No |
|---|---|
| `Onboarding`: the welcome screen with a `brand-glow` background and a `brand-large-title` title | Buttons, switches, `SegmentedControl`, links |
| `PairingCard`: a `brand-glow` background around the white QR code frame | Status dots, badges, error text |
| Empty states: a signal-fire illustration | `MenuBarMenu`, `CallPanel`, tab bars, `Notification` |
| The app icon, the HandLive wordmark (`wordmark`) | Settings, the message list |

- HIG: to express the brand with color, put the color in the content layer, where it scrolls under the
  glass controls and the glass "picks up" the color; don't tint controls with the brand color.
- Flame red isn't used for buttons or status, so it can't be mistaken for the cancel, delete, and
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

- The logo is a signal fire on a mountaintop; the files (mark, wordmark, lockups, app icon) are in
  `docs/brand/assets/` and their rules in the [brand guidelines](../../brand-guidelines.md).
- In the apps, the logo appears only on the welcome screen and in the About window: as the lockup
  image, or as the word "HandLive" in the `wordmark` style (Be Vietnam Pro Bold 20/24) in `brand-fire`
  or `label`. Don't scatter logos across the app, and don't put one in navigation bars.
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
| Plum `brand-ember` in place of black | Custom black or blue backgrounds |
