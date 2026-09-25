English | [Tiếng Việt](README.vi.md)

# Onboarding

The welcome screen the first time the app opens — HandLive's main brand moment. Short, skippable, and
about HandLive rather than teaching people how to use the system (SET-03). The HIG doesn't allow
branding on the launch screen; this screen is the right place for it.

## Anatomy

| Part | Specification |
|------|---------|
| Background | `system-background` with a `brand-glow` halo at the top (the brand color lives in the content layer) |
| Title | "Welcome to HandLive", `brand-large-title`; the word "HandLive" in `brand-fire` |
| Three or four feature rows | An SF Symbol in `brand-fire` + a bold title + one sentence. Mac: clipboard, messages and calls, webcam, privacy. iPhone/iPad: clipboard, messages, call notifications, privacy. Android: the phone's role as the hub, privacy |
| Link | "HandLive and Your Privacy" (opens `docs/privacy.md` or `docs/privacy.vi.md` in the display language) |
| Button | "Get Started" — a prominent `Button`, at the bottom (iPhone, Android) or in the bottom-right corner (Mac); later steps use "Continue", and the last step "Done" |

The flow after the welcome screen: `PermissionPrimer` for the permissions needed to run → (Mac) ask
about "Show HandLive in Menu Bar" → `PairingCard` → done. Every other permission is requested when its
feature is used.

## By platform

- **macOS:** a 520×560 pt welcome window, not resizable, with a working close button (closing means
  "later"; reopen it from the "Add Phone…" menu item). macOS has no launch screen.
- **iOS/iPadOS:** full screen (iPad: a form sheet); the feature rows scale with Dynamic Type and scroll
  at the AX sizes.
- **Android:** full screen, edge-to-edge; Be Vietnam Pro for the title, Inter for the content.

## Dos and don'ts

- Do let people reach the main task (pairing) in ≤ 3 taps.
- Don't show the welcome screen again once it's done; don't stuff terms and conditions in here, and
  don't ask for an app rating here.
