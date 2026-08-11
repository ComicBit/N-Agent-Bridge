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
does not expose a verified 64-byte S4 vendor channel. Keymap installation and
D5/D6 zone management therefore require USB-C or the verified U1 2.4G route.
Per-key RGB writing is separately blocked pending its real write transaction.
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

On 2026-08-11 the connected Air75 V3 passed protected D5/D6 lighting-state and
D2/D8 per-key RGB write/readback/recovery tests over both USB-C and the official
U1 2.4G receiver. Bluetooth exposes keyboard input but no verified 64-byte S4
management interface, so live lighting configuration must not be advertised
for Bluetooth.
