# External blockers

This file records limitations that ordinary application code cannot remove.

## 1. macOS permissions require the user

Input Monitoring is used to read dedicated Air75 V3 controls. Accessibility is
used to send actions to the active Codex window. macOS does not allow an app or
installer to grant either permission silently, so the user must approve both on
first setup. The fixed bundle ID, stable signing identity, and in-place
upgrades help macOS retain the grants on later versions.

## 2. Development builds are not notarized

The current keychain has `N Agent Bridge Local Signing`, not a Developer ID
Application certificate or notarytool credentials. Development DMGs are
appropriate for known-source testing, but macOS may require **Open Anyway** on
the first launch. Do not disable Gatekeeper or run `spctl --master-disable`.

## 3. Bluetooth has no verified S4 management channel

Air75 V3 Bluetooth HID can carry ordinary key input, but the current firmware
does not expose a verified 64-byte S4 vendor channel. Keymap installation,
D5/D6 zone management and D2 per-key RGB inspection therefore require USB-C
or the verified U1 2.4G route.
The software cannot create a BLE characteristic that the firmware does not
expose.

## 4. Codex Desktop state is not a stable public API

The app combines read-only app-server thread IDs/names, active-window
Accessibility semantics, and local state events. Third-party MCP confirmation
cards that are not rendered do not expose a shared public event stream. Codex
internal command or storage changes may require compatibility updates. Unknown
formats fall back to idle instead of being presented as a false waiting or
thinking state.

## 5. macOS cannot reliably distinguish a second physical keyboard

The non-root CGEvent session tap does not provide a reliable physical-device
source. If an Agent action is assigned to Q, a number key, or another ordinary
key, the same virtual key is consumed while Codex control is enabled. Stopping
control or quitting the app releases it immediately. Precise multi-keyboard
separation would require DriverKit/HIDDriver and is outside the current scope.

## 6. Bluetooth has no verified S4 lighting route

Bluetooth exposes keyboard input but no verified 64-byte S4 management
interface, so live lighting configuration must not be advertised for
Bluetooth.

## 7. Per-key color writing needs a verified NuPhyIO capture

D2 safely reads individual key colors, but the previously assumed D8 write
transaction is not accepted as product evidence. Per-key writes are disabled
for USB-C and U1 until the real NuPhyIO transaction is captured, decoded, and
passes backup, ACK, delayed readback, and restoration checks. App-only status
animations can coexist with the keyboard's normal backlight animation.
