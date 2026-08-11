# Air75 V3 Acceptance Test

The historical physical results in this file are upstream records. A fresh
checkout must label any missing device result **REQUIRES HARDWARE
VERIFICATION**.

## Automated checks

- `Air75CoreSelfTest --software-only` passes.
- The app is Universal (`arm64 + x86_64`) and the bundle contains only the
  verified `Air75V3.json` profile.
- The fixed-signing designated requirement matches the previous release.
- The DMG mounts read-only; the app, Applications link, and English install
  instructions are present; `hdiutil verify` passes.

## USB-C hardware: official firmware 1.0.16.6

- Recognizes exactly `19F5:1028`; unknown models never enter the write path.
- Reads A1 firmware information and performs an `0xEE` handshake before each
  logical transaction.
- Reads both D5 lighting handles; normal D6 writes use macOS handle 0 only.
- D6 no-op, temporary change, exact D5 readback, and final restore pass.
- D2 reads the named physical-key RGB values without writing them.
- Per-key RGB write command and button-color change remain **REQUIRES HARDWARE
  VERIFICATION**; the acceptance probe must not send a guessed D8 frame.
- Reads the complete 1,568-byte B2 keymap. After setup, F1-F12 produce F13-F24
  and the knob mapping and original backup can be restored.
- Unplug/replug, app restart, and Mac wake do not leave the app permanently in
  **USB-C waiting**.

## Fresh Mac

1. Drag the app into Applications.
2. If Gatekeeper blocks the first launch, choose **Open Anyway** only for this
   known-source development build.
3. Grant Input Monitoring and Accessibility, then quit and reopen the app.
4. Quit NuPhyIO, switch the keyboard to wired mode, and choose **Connect and
   Enable**.
5. The app reports ready only after keymap readback, permissions, and the
   lighting handshake succeed.

## Wireless boundary

- U1 2.4G uses only the verified route; first onboard configuration requires
  USB-C.
- Bluetooth has no S4 management channel, so the acceptance claim is limited
  to key input, not live per-key lighting.
