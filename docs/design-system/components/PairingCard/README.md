English | [Tiếng Việt](README.vi.md)

# PairingCard

Pairs two devices with a QR code (PAIR-01): **the Mac and iPhone/iPad show the code; Android scans it.**
When scanning isn't possible, a 6-digit PIN is used instead (only on the same Wi-Fi network). It's a
brand moment: a `brand-glow` background in the content layer.

## The showing side (Mac, iPhone, iPad)

| Part | Specification |
|------|---------|
| Title | "Pair Phone" — `brand-title` (Mac: a sheet on the welcome window or Settings; iPhone: a large sheet with "Cancel" in the top-left corner) |
| Instructions | "Open HandLive on your Android phone, tap Add Device, then scan this code." |
| QR code | Always `qr-ink` on `qr-paper` in every appearance, `size-qr` on a side (220 pt), in a card with `radius-card` corners |
| Device name | This device's name, so the user picks the right one on the phone |
| Countdown | "Code changes in 1:42" — the digits use `timer` (monospacedDigit) |
| Fallback | The text button "Can't Scan? Use a PIN" → shows 6 digits in the `code-pin` style ("482 915") |

Once paired: the sheet closes itself, with `Feedback` "Paired with Lan's Pixel 8" and a `success`
haptic (iPhone).

## The scanning side (Android)

A full-screen camera view: a four-corner viewfinder in `on-video`, a dark layer outside the frame, the
sentence "Point the camera at the QR code on your Mac or iPhone", a round glass close button (`xmark` ↔
`close`) in the top-left corner, and a glass "Enter PIN" button at the bottom. Once the code is scanned: a `CONFIRM` haptic and the device name; the **Security Code** appears when pairing finishes (on the result and in the device details) for comparison.

## Dos and don'ts

- Do keep the code at its brightest: no glass over it, and no color change in the Dark appearance.
- Don't make the countdown flash red; when time runs out, generate a new code automatically.
- Don't ask people to type in network details; the QR code is enough.
