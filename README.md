# N Agent Bridge — Air75 V3 developer keyboard foundation

[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black?logo=apple)](https://github.com/bohu8264/N-Agent-Bridge/releases)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white)](Package.swift)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

This repository is an English-first, buildable foundation for a programmable
developer keyboard built around the **NuPhy Air75 V3 ANSI** on macOS. It
preserves the upstream N Agent Bridge implementation for Air75 V3 HID,
keymap, rotary-knob, RGB, and Codex behavior while making the hardware
boundary understandable and independently testable.

The project is an independent third-party open-source tool. It is not
affiliated with OpenAI, Codex, NuPhy, or Work Louder. Reverse-engineered
protocol knowledge and the original implementation are retained under the
upstream project’s license and attribution:
[bohu8264/N-Agent-Bridge](https://github.com/bohu8264/N-Agent-Bridge).

## Supported baseline

- NuPhy Air75 V3 ANSI only
- Official firmware `1.0.16.6` is the verified baseline
- USB-C and the official U1 2.4G receiver (`19F5:2620`) expose the verified S4 management path
- Bluetooth input is supported, but live RGB/keymap management is not claimed
- macOS 13 or later; Swift tools version 5.9+

The six-key custom developer surface (AGENT, TEST, BUILD, GIT, SHIP, TALK) is
not implemented yet. See [NEXT_STEPS.md](NEXT_STEPS.md).

## Install and first setup

1. Download the latest Development DMG from [GitHub Releases](https://github.com/bohu8264/N-Agent-Bridge/releases).
2. Drag **N Agent Bridge.app** into **Applications**. Do not run it from the DMG.
3. Development builds are not Apple-notarized. If macOS blocks the first launch, choose **System Settings → Privacy & Security → Open Anyway**. Do not disable Gatekeeper.
4. Grant **Input Monitoring** and **Accessibility** to N Agent Bridge, then quit and reopen it.
5. Update the keyboard to official firmware `1.0.16.6`, close NuPhyIO, switch to wired mode, and connect a USB-C data cable.
6. Choose **Connect and Enable**. The app backs up the complete 1,568-byte keymap, installs F13-F24, verifies the full readback, and initializes verified lighting.

The app stores configuration and hardware backups locally at
`~/Library/Application Support/Air75AgentBridge/Backups`. Do not remove that
directory while the dedicated keymap is installed.

## Build locally

```sh
git clone https://github.com/bohu8264/N-Agent-Bridge.git
cd N-Agent-Bridge
swift build --disable-sandbox --product Air75AgentBridge
swift build --disable-sandbox --product air75
swift run --disable-sandbox Air75CoreSelfTest --software-only
```

The complete XCTest suite requires a full Xcode installation. The standalone
self-test is the portable software regression path.

## Independent developer diagnostics

The `air75` executable does not require Codex to be running:

```sh
swift run --disable-sandbox air75 list
swift run --disable-sandbox air75 info
swift run --disable-sandbox air75 led map
swift run --disable-sandbox air75 led get F1
```

`led get` queries a named physical-key color through D2. Verified D8 writes can
change individual Air75 V3 ANSI key LEDs over USB-C or the official U1 2.4G
receiver and require exact D2 readback. D5/D6 remain separate whole-board and
side-light controls and are also verified on USB-C and U1.

## Architecture and protocol

- [Architecture](docs/ARCHITECTURE.md) — HID, Air75 hardware, lighting/input, CLI, and application integration boundaries
- [Air75 V3 protocol](docs/AIR75_V3_PROTOCOL.md) — frame layouts, commands, session behavior, firmware assumptions, and confidence labels
- [Air75 V3 LED map](docs/AIR75_V3_LED_MAP.md) — ANSI physical-key to D2 read index map
- [Keymap behavior](docs/KEYMAP.md) — F13-F24 installation and knob events
- [English user guide](docs/USER-GUIDE.en.md)
- [Acceptance test](docs/ACCEPTANCE-TEST.md)

## Connections and permissions

| Connection | Keyboard input | Agent status RGB | Keymap/lighting management |
| --- | --- | --- | --- |
| USB-C | Supported | Supported | Supported after verified read/write checks |
| Official U1 2.4G | Supported | Supported when the S4 route responds | Supported where firmware forwards S4 |
| Bluetooth | Supported | Not verified | Not supported |

Input Monitoring is used to observe dedicated controls. Accessibility is used
to send actions to the active Codex window. Both permissions are user-granted
macOS capabilities; the app cannot silently enable them.

## Safety and provenance

The implementation never flashes firmware, enters IAP mode, restores factory
settings, or writes unknown packet formats. Hardware writes are restricted to
the exact Air75 V3 identity and verified usage `1:0` interface. The upstream
license and attribution remain in [LICENSE](LICENSE).

## License

[MIT License](LICENSE)
