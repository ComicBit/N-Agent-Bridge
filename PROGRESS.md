# Progress

The entries below preserve the upstream project history. Physical-device
results recorded in the historical entries are upstream evidence; they are
not re-run by the current software-only bootstrap unless explicitly stated.

## 2026-08-11: English-first developer foundation

- Cloned the upstream N Agent Bridge repository at the `0.15.0-development`
  baseline and retained its MIT attribution and source provenance.
- Documented the Air75 V3 architecture, ANSI D2 per-key RGB read map, S4
  frame format, session handshake, command boundaries, firmware assumptions,
  transport limits, and safety rules in English.
- Added the independent `air75` developer CLI for compatible-device listing,
  metadata/firmware reads, named ANSI D2 per-key RGB reads, and protected
  per-key diagnostics without Codex running.
- Added software coverage for the F1/F13 physical-location aliases and
  rejected arbitrary numeric LED addresses.
- Verified the portable software self-test, the new CLI build, CLI help/map
  output, and read-only device enumeration. Local USB-C validation on the
  connected Air75 V3 found the exact `19F5:1028` management interface, read
  A1 and both D5 handles, and passed D6 no-op, temporary-change, and exact
  restore checks. D2 returned the per-key F1 color. D8 was then verified after
  selecting Signal Indicator mode `0x15`: USB-C changed and restored F1, while
  U1 copied all 84 key colors, blinked only F1 red for 60 seconds, and restored
  the complete signal palette and original Static mode. U1 D6 also changed
  `0x03` to `0x15`, preserved side-light bytes and handle 1, and restored the
  exact original D5 state. The receiver fix filters duplicated local zero/echo
  frames and waits for the forwarded keyboard response before D5/D2 readback.
- The next implementation slice is the platform-neutral six-key developer
  state machine described in `NEXT_STEPS.md`; the six-key workflow itself is
  intentionally not implemented yet.
- Added the production Agent-lighting lifecycle: the app persists the complete
  84-index D2 palette and both D5 handles before activating mode `0x15`, routes
  D5/D6 and D2/D8 through the most recently active USB-C or U1 input path, and
  restores the complete palette and original mode when Agent lighting is
  disabled. Pending backups survive relaunch until restoration completes.

## 0.15.0: Bilingual interface and distribution cleanup

- Added **Settings → General → Interface Language**, with immediate and
  persistent Chinese/English switching. A fresh install chooses a default
  from the macOS preferred language.
- Sidebar, first-run setup, overview, keys, lighting, settings, menu bar, and
  runtime messages use the selected language. The device-layer placeholder
  for supported NuPhy keyboards is localized too, so English mode does not
  leak an untranslated device message.
- HID, F13-F24, rotary-knob, `0xEE` session, D6/D8 lighting, Codex state, and
  permission behavior were not changed. `Air75CoreSelfTest --software-only`
  and the Universal app build passed.
- Removed regenerable `.build`, old `dist`, and `.DS_Store` content while
  retaining source, protocol docs, release scripts, and user hardware backups.

## 0.14.2: Air75 V3 eighth-layer empty-knob compatibility

- Identified why some computers stopped before writing F13-F24: official Air75
  V3 firmware 1.0.16.6 can leave layer-8 knob press position p60 unassigned
  as `0x0000`, which the strict 0.14.1 allow-list correctly rejected.
- Added only this one confirmed layer-8/p60 empty value and normalize it to
  `0x0048` when creating the bridge profile. Empty values in layers 1-7,
  other positions, and unknown values remain rejected. Full 1,568-byte
  backup, ACK, byte-for-byte readback, and failure recovery remain strict.
- Added software regression checks for the accepted exception and rejected
  variants. `Air75CoreSelfTest --software-only` and the full Universal app
  compile passed.
- Built the 0.14.2 (56) Universal Development App and DMG. Signing
  designated requirement, dual architecture, bundle resources, and DMG
  CRC/read-only checks passed. SHA-256:
  `9e5cf34158d0259521778292e23330902f9cd11c2c1fc506d898744703428ed6`.

## 0.14.1: false orange confirmation-light fix

- Accessibility scanning now reads only the focused window. An explicitly
  empty `AXVisibleChildren` value is treated as hidden, so closed or
  off-screen Electron cards are not traversed.
- A single **Install / Allow / Approve** button no longer turns on the orange
  light. A visible control group must contain both a permission-style
  affirmative action and a rejection action; ordinary **Confirm / Cancel** UI
  does not trigger the waiting state.
- Rollout parsing accepts only explicit `request_user_input`, approval, or
  permission-request events. Ordinary metadata containing `approval`, tool
  output, and completed/rejected results clear the waiting state.
- Added Chinese, English, hidden-card, single-button, ordinary-confirmation,
  named-tool-output, and unrelated-approval-metadata regression checks.
  `Air75CoreSelfTest --software-only` and the Universal app build passed.
- A locally installed 0.14.1 (55) cold-start check recorded normal Air75 V3
  recognition, `LightingAvailable=1`, and
  `CodexVisibleConfirmationWaiting=0` without a confirmation card.
- The local development DMG was
  `dist/NAgentBridge-0.14.1-Development.dmg`; CRC passed. The fixed
  self-signed certificate was not trusted by the system, so strict
  `codesign --verify` returned `CSSMERR_TP_NOT_TRUSTED`; bundle contents,
  designated requirement, and both architectures were normal.
- Source was pushed to the public repository and the
  `v0.14.1-development` pre-release was uploaded with its Universal DMG and
  GitHub-generated source archive. The 0.14.0 release was retained.

## 0.14.0: Air75 V3 official firmware 1.0.16.6 baseline

- Product scope was narrowed to the NuPhy Air75 V3 ANSI (`0x1028` USB PID,
  `0x2620` U1 receiver PID). Other keyboard profiles, drivers, LED maps,
  tests, and unverified entry points were removed. Unknown models never enter
  the vendor-HID write path.
- The post-update **USB-C waiting** root cause was identified: S4
  transactions require `0xEE SetSecretKey`; the session key is challenge byte
  20. Firmware 1.0.16.6 keeps the response route header plain while
  encrypting the payload, while older firmware may encrypt both. The codec
  supports both formats and performs a fresh handshake for every logical
  transaction.
- D5/D6 lighting control writes only macOS handle 0. The app still reads and
  backs up both handles but does not treat firmware normalization of Windows
  handle 1 as a write failure or rewrite the Windows profile.
- D8 signal lights use **read original → write → D2 exact readback → recover
  on failure**. F1-F6 default to indexes 1-6; a stale Tab index is cleared,
  while user-assigned known physical keys continue to follow their real map.
- Full keymap installation continues to use a 1,568-byte B2 readback. The
  app safely changes physical F1-F12 to F13-F24 and retains the complete
  original backup. If a firmware update restores native layers, the app asks
  for USB-C reconfiguration instead of trusting an old local record.
- Upstream recorded physical protection checks on Air75 V3 1.0.16.6:
  A1 firmware read, D5 dual-handle backup, D6 no-op/temporary change/exact
  restore, D2/D8 F1 no-op/temporary change/exact restore, full B2 keymap
  readback, and F13-F24 profile checks.
- Physical backups are stored at
  `~/Library/Application Support/Air75AgentBridge/Backups/`; project cleanup
  does not touch that directory.

## Release verification recorded upstream

- Universal (arm64 + x86_64) fixed-signing app build passed for version
  `0.14.0 (54)`. The designated requirement retained bundle ID
  `com.nagentbridge.mac` and the fixed certificate fingerprint.
- First launch and the second cold launch after a full exit recorded
  `LightingAvailable=1`, `LightingConnection=usbCable`, and
  `HIDManagerOpenResult=0` in about four seconds. Input Monitoring,
  Accessibility, and continuous F13-F24 mapping remained effective.
- Development DMG CRC, read-only mount, signing, Air75V3 bundle resources,
  and content structure passed. SHA-256:
  `477a34f1d9a411bd91f6f25aa27d4382aba8bdc0bd986d1f6538744d8a911e47`.
- The source machine had only Command Line Tools and no XCTest platform, so
  `swift test` returned `XCTest not available`. The standalone
  `Air75CoreSelfTest --software-only` release check passed.
- The GitHub source commit and new `v0.14.0-development` release were still
  pending publication at that historical checkpoint; the older release was
  not overwritten.

## Verification commands

```sh
swift build --disable-sandbox --product Air75CoreSelfTest
.build/debug/Air75CoreSelfTest --software-only
.build/release/Air75ProtocolProbe --hardware-validate
./scripts/verify-release.sh
```
