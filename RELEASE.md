# Release Notes

## 0.14.2 Development Build

- Version: `0.14.2 (56)`.
- Supports the confirmed Air75 V3 official-firmware 1.0.16.6 keymap variant
  where layer-8 knob press p60 may be unassigned as `0x0000`.
- Only that one empty value is normalized to dedicated event `0x0048` before
  F13-F24 installation and full readback. All other layers, positions, and
  unknown values remain subject to strict safety checks.
- Fixed a setup path that stopped on some newer Macs before the actual
  F13-F24 write, making configuration appear incomplete.
- Retained the 0.14.1 visible-confirmation-card fix, so ordinary buttons or
  stale hidden cards do not turn the status light orange.
- Universal (arm64 + x86_64) fixed-signing app, software regression, bundle
  resources, and DMG CRC/read-only checks passed.

Development DMG SHA-256:
`9e5cf34158d0259521778292e23330902f9cd11c2c1fc506d898744703428ed6`

## 0.14.0 Development Build

- Version: `0.14.0 (54)`.
- Product scope is NuPhy Air75 V3 ANSI; other profiles, drivers, LED maps,
  and unverified entry points were removed.
- Supports official Air75 V3 firmware `1.0.16.6`, including the `0xEE`
  session handshake and both observed response-header formats.
- Fixed the post-upgrade lighting page staying in **USB-C waiting**, disabled
  controls, and status lights not landing on physical keys.
- Lighting writes modify only macOS handle 0. Every D6/D8 write requires an
  ACK and exact readback and attempts to restore the pre-write state on
  failure.
- USB-C setup reads the real 1,568-byte keymap, installs F13-F24 when needed,
  and reads the complete map back so another computer does not trigger the
  native F1-F12 actions.
- First setup requires dragging the app into Applications, granting Input
  Monitoring and Accessibility, and choosing **Connect and Enable** over
  USB-C.
- Upstream recorded physical A1/D5/D6/D2/D8/B2 backup, temporary-write,
  exact-readback, and final-restore checks on Air75 V3 1.0.16.6.
- Universal (arm64 + x86_64) app, fixed signing, DMG CRC/read-only mount,
  bundle resources, two post-install cold starts, and final SHA-256 checks
  passed in the upstream release record.

Development DMG SHA-256:
`477a34f1d9a411bd91f6f25aa27d4382aba8bdc0bd986d1f6538744d8a911e47`

> This package uses fixed local signing for public-source and friend testing;
> it is not an Apple Developer ID notarized package.
