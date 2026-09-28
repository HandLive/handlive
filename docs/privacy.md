English | [Tiếng Việt](privacy.vi.md)

# HandLive and your privacy

HandLive is an open source project. It brings ecosystem-native features, such as Apple Handoff, to Android. An Android device stays in sync with a Mac, iPhone and iPad, and those Apple devices sync back.

This page explains what data HandLive handles, where that data goes, and what the user controls. It covers every HandLive app and the relay. The apps link here from the welcome screen (detailed design SET-01 field 1).

## In short

- No account: HandLive never asks for your name, email address or phone number.
- Your clipboard, messages, calls, camera and, when you turn on Continue Browsing, the address of the web page you have open stay between the devices you pair. Everything that leaves a device is end-to-end encrypted with keys that only your devices hold.
- When your devices are not on the same Wi-Fi network, the relay server passes encrypted data between them. It cannot read the content and does not keep it.
- No ads, no analytics, no tracking, and no third-party SDK that collects data.

## What stays on your devices

- Identity and pairing keys, in the Android Keystore and the Apple Keychain; they never leave the device.
- Synced messages, call history and settings, in a local database (encrypted with SQLCipher on Mac, iPhone and iPad).
- Clipboard content, sent when you copy or tap Send and cleared after 60 seconds by default. Content that looks like a password or a card number is not sent unless you choose Send Anyway.

## What the relay server sees

- A random device identifier derived from your device's public key, which devices are paired with each other, and the push tokens your iPhone, iPad or Android phone registers for notifications.
- The time and size of each encrypted message and the IP address of each connection, used only for rate limiting and kept for at most one hour.
- Never the content: every message is encrypted end to end before it leaves your device.
- Usage statistics use a monthly salted hash of the device identifier and are deleted after 30 days; undelivered encrypted messages are deleted after 30 days at most.
- Turn off Internet Connection in Settings to use HandLive only on your Wi-Fi network; Remove Device from Server deletes your registration.

## Permissions

HandLive asks for a permission only when you turn on the feature that needs it, after a screen that explains why: notifications, the local network, the camera (to scan the pairing QR code), SMS and contacts (messages), phone state and call log (calls), microphone and Bluetooth (taking calls on the Mac), Accessibility (sending what you copy automatically on Android, and reading the open page's address in supported browsers for Continue Browsing), and Automation on the Mac (reading the open page's address in each browser you allow). Turning a feature off stops its use of the permission.

## Web pages (Continue Browsing, planned)

Continue Browsing is off by default. When you turn it on, HandLive sends the address and title of the web page open in the foreground browser to your paired devices, so you can continue there: from your Android phone to your Mac, iPhone and iPad, and from your Mac to your phone.

- The address travels end-to-end encrypted, like everything else, also through the relay, which cannot read it. It is never sent in a push notification.
- It is never stored: the receiving device keeps only the latest page in memory and forgets it after 10 minutes, when you leave the page, or when the devices disconnect. HandLive never keeps a browsing history.
- Pages in incognito or private tabs and windows are never sent. You can exclude any browser in Settings.
- The receiving device never opens a page by itself: you always click or tap first.

## Calls

When you take a phone call on your Mac, the audio goes only between your phone and your Mac: over Bluetooth, protected by Bluetooth link encryption, or over Wi-Fi, end-to-end encrypted. HandLive never records calls. Where the law requires everyone's consent, tell the other person that the call is heard on your computer.

## Deleting your data

- Unpairing a device deletes the pair's keys and synced data on both devices.
- Delete All HandLive Data in Settings deletes every key, the database and the settings on that device and removes its registration from the relay server.
- Uninstalling the app deletes its local data.

## Open source and contact

HandLive is open source under the Apache License 2.0, so anyone can check what the apps and the relay server do: https://github.com/HandLive. Questions about privacy: me@hxd.vn. Security issues: see the [security policy](https://github.com/HandLive/.github/blob/main/SECURITY.md).

Last updated: 2026-09-28.
