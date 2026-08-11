# N Agent Bridge development entry point

Before changing code, read `README.md`, `PROGRESS.md`, and `BLOCKERS.md`. The
current product scope is **NuPhy Air75 V3 ANSI** only. Do not restore deleted
keyboard profiles or reuse an unverified driver.

## Current baseline

- Product: N Agent Bridge `0.15.0 (57)`
- Bundle ID: `com.nagentbridge.mac`
- Local signing identity: `N Agent Bridge Local Signing`
- Target firmware: official Air75 V3 `1.0.16.6`
- Wired identity: `19F5:1028`
- Official U1 receiver: `19F5:2620`
- Profile: `nuphy.air75-v3`
- macOS 13+, Swift 5.9+

## Non-negotiable hardware safety rules

1. Management requests must match only the allow-listed 64-byte usage page/usage `1:0` configuration interface.
2. Start every logical transaction with `0xEE SetSecretKey`; the session key is byte 20 of the 56-byte challenge.
3. Decode both the legacy “encrypted route header + encrypted payload” response and the 1.0.16.6 “plain route header + encrypted payload” response.
4. S4 responses have no transaction ID. Keymap, lighting, per-key RGB reads, and sleep frames must be serialized through `NuPhyHIDOperationCoordinator`.
5. Read and persist a backup before writing; require ACK, delayed readback, and strict verification; attempt recovery on failure.
6. Read D5 handles 0 and 1, but write only macOS handle 0. Firmware 1.0.16.6 normalizes unused Windows handle 1 metadata; do not modify it.
7. Before a D8 per-key RGB write, read and persist the original colors through D2. Require ACK and exact delayed D2 readback after writing; restore the original colors on failure. Split sparse reads into contiguous windows no larger than 54 payload bytes.
8. The keymap must be exactly 1,568 bytes. Never persist encrypted, unknown-layout, or mixed-partial reads as an original backup. On official 1.0.16.6, only layer 8 knob press position p60 may be empty `0x0000`; normalize it to `0x0048` during installation. Do not widen that exception.
9. Never send `0xEF SetIapMode`, `0xF1 RestoreFactory`, or guessed firmware commands.
10. Never delete `~/Library/Application Support/Air75AgentBridge/Backups`.

## Product behavior

- The first wired setup changes physical F1-F12 to F13-F24 and maps the knob to unique dedicated events, then performs a complete readback.
- Every USB-C reconnect checks the real keyboard keymap. If a firmware update restores the native layers, setup is required again.
- F1-F6 / custom Agent key events use the verified keymap path and D8 to display five task states, with D2 exact readback and recovery. Esc is index 0, F1-F6 are indexes 1-6, and legacy Tab index 30 is only a compatibility entry when it is not the current binding.
- Agent assignment uses stable thread IDs and supports recent, pinned, priority, and custom sources.
- Input Monitoring and Accessibility must be granted by the user; the app cannot silently approve them.
- Bluetooth has no verified S4 lighting channel and must not be presented as supporting live lighting configuration.

## Verification commands

```sh
swift build --disable-sandbox --product Air75CoreSelfTest
.build/debug/Air75CoreSelfTest --software-only
swift build --disable-sandbox --product air75
.build/debug/air75 list

# Before physical validation, quit N Agent Bridge and NuPhyIO.
swift build --disable-sandbox -c release --product Air75ProtocolProbe
.build/release/Air75ProtocolProbe --hardware-validate
```

Physical validation must report D6 original and temporary readback, D8 original
and temporary values with exact D2 readback, the B2 keymap, and final restoration
as PASS. The probe persists a backup before testing.

Release work uses `scripts/build-release.sh`, `scripts/create-dmg.sh`, and
`scripts/verify-release.sh`. Before release, also run the app-bundle resource
test, fixed-signing check, cold-start diagnostics, and DMG read-only mount
verification.

## Directory map

- `Sources/Air75AgentBridgeCore/`: protocol, HID, device profiles, drivers, configuration, mapping, and integration interfaces
- `Sources/Air75AgentBridgeApp/`: SwiftUI presentation and runtime orchestration
- `Sources/Air75DeveloperCLI/`: independent read-only list/info/map/get diagnostics
- `Sources/Air75ProtocolProbe/`: protected physical-hardware acceptance checks
- `Sources/Air75CoreSelfTest/`: software regression executable
- `Tests/`: XCTest coverage when a complete Xcode environment is available
- `Distribution/`, `scripts/`: signing and release tooling
- `docs/`: protocol, architecture, user, and acceptance documentation

Do not commit `.build/`, `dist/`, hardware captures, user configuration,
backups, certificates, private keys, or API credentials.
