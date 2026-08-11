# Air75 V3 Keymap

| Physical key | Installed hardware value | Default action |
| --- | --- | --- |
| F1-F6 | F13-F18 | Agent 1-6 |
| F7 | F19 | Fast Mode |
| F8 / F9 | F20 / F21 | Approve / Decline |
| F10 | F22 | New task |
| F11 | F23 | Native Codex dictation |
| F12 | F24 | Send |

**Connect and Enable** first reads and persists the complete 1,568-byte
keymap, then changes physical F1-F12 to F13-F24 in the macOS/Windows base
layers. Knob left, press, and right become Scroll Lock, Pause, and Print
Screen so the app can identify reasoning-level controls. All other matrix
bytes remain unchanged.

Every write begins with the official `0xEE` session handshake, writes B3 in
chunks, and reads the complete 1,568 bytes back with B2 for byte-for-byte
verification. A length, original-layout, ACK, or readback failure stops the
operation and attempts to restore the pre-write map. Unverified ciphertext is
never saved as an original backup.

At launch and after USB-C reconnect, the app reads the keyboard to verify the
installed layer instead of trusting only the local configuration. If a
firmware update restores F1-F12, the UI asks for setup again. Known historical
`F13 / F15 / Tab / F16...` corruption is repaired exactly; genuine user
customizations are not overwritten.

The **Keys** page can learn actions onto numbers, letters, the F-row, or
navigation keys. Custom ordinary keys are software mappings: when control is
enabled, a CGEvent session tap consumes the original character, and stopping
control releases it. `usage 0xFFFFFFFF` is an HID-array placeholder and must
be rejected by both the learner and runtime.

D2/D8 per-key RGB management uses the current physical HID usage. The ANSI
map excludes three hidden knob entries: F1 is index 1 and the number 1 key is
index 16. Writes require Signal Indicator mode and use exact D2 readback with
recovery on mismatch over USB-C or the official U1 receiver.

Agent conversation assignment uses stable Codex thread IDs. Recent, pinned,
priority, and custom modes do not depend on changing sidebar row numbers.
