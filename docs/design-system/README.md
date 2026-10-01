English | [Tiếng Việt](README.vi.md)

HandLive is an open source project. It brings ecosystem-native features, such as Apple Handoff, to Android, so an Android device stays in sync with a Mac, iPhone and iPad, and those Apple devices sync back. The link stays end-to-end encrypted.

This design system follows **Apple's Human Interface Guidelines (HIG)** on all three platforms. On Mac, iPhone, and iPad, HandLive uses the system controls, the San Francisco font, SF Symbols, and the Liquid Glass material. On Android, the app rebuilds the same design language in Jetpack Compose, the way Apple built Apple Music for Android. The app leaves the parts Android owns as they are: notifications, permission dialogs, Quick Settings tiles, the back gesture.

These documents follow the HIG as of September 24, 2026 (Liquid Glass, macOS 27, iOS and iPadOS 27).
The app supports macOS 13 and iOS 16 and later: system controls render correctly on each version on
their own; custom components have their own rendering for versions before 26 (see Materials).

## How to read this

The sections follow the structure of the HIG:

1. **Foundations** — color, Dark Mode, typography, layout, materials, icons, motion, accessibility,
   writing, privacy, branding.
2. **Patterns** — onboarding, requesting permission, notifications, settings, feedback and loading.
3. **Platforms** — macOS, iOS and iPadOS, Android.
4. **Components** — each component has a preview for every platform, the API names to use, and where
   its copy lives in the detailed design.

Each section cites the original HIG page for reference. Wherever HandLive departs from the HIG, the
section says why.

## Eight principles

From the HIG's Design principles page, applied to HandLive:

| Principle | For HandLive |
|-----------|--------------|
| Purpose | Each screen serves one task: check the link, send the clipboard, read a message, take a call. |
| Agency | People decide whether to show or hide the menu bar icon, which features to turn on, and whether to skip the introduction. |
| Responsibility | Say where data goes before asking for permission; end-to-end encryption can't be turned off. |
| Familiarity | Use the system's controls and terminology; an incoming call on the Mac looks like a Continuity call. |
| Flexibility | Works correctly in the four appearances — Light, Dark, and their two Increased Contrast variants — with large text sizes, VoiceOver, TalkBack, and the keyboard. |
| Simplicity | Few words, one primary button per screen; advanced options sit behind a disclosure button. |
| Craft | Concentric corners, Vietnamese text whose diacritics are never clipped, timers whose digits don't jump. |
| Delight | Saved for the right moments: pairing completes, the first copy from phone to Mac. |

## Brand: a signal fire on the mountaintop

What happens on the phone shows up on the screen in front of you; the logo draws that as a signal fire
on a mountaintop, in the colors of dawn.
Story, voice, logo files, and promo images: [brand guidelines](../brand-guidelines.md).

| Role | Color | Why |
|---------|-----|----------|
| Identity | Flame red `brand-fire`, flame orange `brand-flame` | The signal fire |
| Depth | Plum `brand-ember` | The mountain; used in place of black |
| Actions (AccentColor) | Green `accent`, `accent-fill` | The green light of a signal received |
| Brand background | Dawn cream `brand-glow` | The sky at first light |
| Neutral | Apple's system grays | Backgrounds, text, borders |
| Not for the brand | Black, blue, and sea blues: systemBlue, Cyan, Teal, Mint, Indigo | Blue belongs to the system |

- Flame red appears only in the app icon, the logo, the welcome screen, and illustrations — never on
  buttons or status, so it can't be mistaken for the system's cancel and delete colors.
- Green is the AccentColor: primary buttons, links, unread indicators, the bubbles of messages you
  send. Following the HIG, tint controls sparingly — one tinted button per screen, two at most.
- Links and selections use green instead of Apple's default blue. On the Mac, when someone chooses an
  accent color other than Multicolor, controls follow their choice.
- The system's dark backgrounds (black on iPhone, gray on Mac) belong to Apple; HandLive adds no black
  or blue areas of its own.
- The logo and app icon live in `docs/brand/assets/`; inside the apps, the word HandLive uses the
  `wordmark` style. Don't use SF Symbols or the San Francisco font in the logo or the app icon —
  Apple's license doesn't allow it.

## Quick summary

| Topic | How |
|------|----------|
| Text | San Francisco through the system text styles (Dynamic Type on iOS). Android uses Inter with the same size scale. Be Vietnam Pro only for brand titles. |
| Color | Apple's semantic colors (`label`, `systemBackground`…) called through the API. The tokens on these pages are reference values for Android and previews. |
| Icons | SF Symbols on Apple platforms; Material Symbols Rounded on Android (mapping table in Icons). |
| Materials | Liquid Glass for the control layer: menus, the call panel, tab bars, floating buttons. Not for the content layer. |
| Hit targets | iOS ≥ 44 pt, macOS ≥ 28 pt (20 pt minimum), Android ≥ 48 dp. |
| Contrast | Text up to 17 pt reaches 4.5:1; large or bold text reaches 3:1. Every token pair has been checked in all four appearances. |

## Apple resources

- Human Interface Guidelines: developer.apple.com/design/human-interface-guidelines
- Apple Design Resources: the macOS 27 and iOS/iPadOS 27 UI Kits (Figma, Sketch), app icon templates,
  Icon Composer.
- The SF Symbols app; the SF Pro and SF Mono fonts.

License: the UI Kits, the San Francisco fonts, and SF Symbols may only be used for interfaces that run
on Apple platforms. Don't use them to build mock-ups or Android apps, and don't use them in a logo.
