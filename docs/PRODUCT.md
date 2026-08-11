# Product scope

N Agent Bridge is a third-party macOS control application for the NuPhy
Air75 V3 ANSI. It maps the physical function row and rotary knob to Codex
actions and uses six configurable physical keys for live Agent status.

The app is native SwiftUI, does not record ordinary text input, and releases
keyboard interception when control is stopped or the app exits. First-time
USB-C setup backs up the complete onboard keymap, installs the F13-F24
dedicated events, and verifies the readback. Lighting writes are restricted to
the verified Air75 V3 management interface and recover on failure.

This project is independent of OpenAI, Codex, and NuPhy and does not present
itself as official hardware software. Other NuPhy models are not supported.
A future model must independently pass protocol, LED map, keymap-size,
backup, recovery, and physical-device validation before it can be enabled.
