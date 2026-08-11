# Architecture

The project is intentionally organized around a one-way dependency flow:

```text
macOS HID discovery and input
        |
        v
Air75 V3 device identity and verified drivers
        |
        +--> keymap / knob configuration
        +--> lighting-zone and per-key RGB read APIs
        |
        v
generic keyboard input, mapping, and state models
        |
        +--> Codex adapter
        +--> Claude Code adapter
        +--> air75 developer CLI
        +--> SwiftUI application orchestration
```

## Source boundaries

### HID and discovery

- `HIDDeviceManager` owns `IOHIDManager` lifecycle, device enumeration,
  profile matching, input callbacks, runtime input filtering, and the Input
  Monitoring request.
- `DeviceFingerprintMatcher` never treats a product name as sufficient
  identity. USB recognition requires the profile’s VID/PID and product alias;
  Bluetooth candidates require the profile rules or a prior user association.
- `DeviceProfileRegistry` loads declarative JSON profiles. A profile alone does
  not authorize a vendor HID write path.

### Air75 V3 hardware drivers

- `NuPhyS4ProtocolCodec` is a pure 64-byte frame encoder/decoder. It has no
  Codex, SwiftUI, Accessibility, or application-state dependency.
- `NuPhyHIDOperationCoordinator` serializes management frames because S4
  responses have no transaction ID.
- `Air75V3KeymapController` performs the narrow 1,568-byte B2/B3 keymap
  workflow, including layout validation, backup-safe installation, readback,
  and recovery.
- `Air75V3LightingController` performs the A1/D2/D5/D6/F3/F5 workflow and
  keeps per-key RGB reads separate from the verified zone writes.
- `SignalLightLayout` is the single source of truth for the ANSI physical-key
  to D2 read-index map; it does not authorize per-key writes.
- `KeyboardDriverRegistry` is the write-capability gate: an unknown or
  software-only profile cannot acquire a hardware driver by JSON configuration
  alone.

### Generic keyboard APIs

`Core/Protocols.swift` and `Device/KeyboardDriverRegistry.swift` expose the
application-facing contracts:

- `KeyboardDeviceProvider` for discovery and lifecycle;
- `KeyboardInputProvider` for HID events;
- `KeyboardKeymapDriver` for validated install/restore;
- `KeyboardLightingDriver` for zone operations and read-only per-key RGB;
- `KeyboardSleepDriver` for the verified sleep configuration;
- `MappingEngine` and `BridgeModels` for model-independent bindings and state.

The hardware drivers do not import Codex or the SwiftUI app. The current Swift
package keeps the Codex adapters in the same `Air75AgentBridgeCore` target for
compatibility with the upstream package, but the source-level boundary is
already one-way: application integrations consume generic contracts and the
Air75 protocol layer does not call an integration.

### Integrations and presentation

- `Agent/Codex/` contains the app-server and local Codex state adapters.
- `Agent/ClaudeCode/` contains the optional Claude Code process adapter.
- `Sources/Air75AgentBridgeApp/` contains `BridgeStore`, SwiftUI views,
  Accessibility relays, menu-bar actions, and lifecycle orchestration.
- `Sources/Air75DeveloperCLI/` consumes only `Air75AgentBridgeCore`. It is the
  independent path for device discovery, firmware reads, key-name resolution,
  and read-only per-key RGB inspection without Codex running. Per-key writes
  remain disabled until a real hardware transaction is verified.
- `Sources/Air75ProtocolProbe/` is separate from normal product behavior and
  is allowed to run the protected physical acceptance sequence only when the
  operator explicitly requests it.

## Runtime sequencing

1. `HIDDeviceManager` enumerates interfaces and produces `DeviceSnapshot` values.
2. The app chooses a recognized profile and selects the registered drivers.
3. Lighting discovery selects USB-C or the U1 receiver based on active input
   and verified product identity. Bluetooth is never promoted to a lighting
   management path.
4. Every logical S4 transaction performs a fresh `0xEE` handshake and runs
   under the process-wide coordinator.
5. Any write follows read/backup -> write -> ACK -> delayed readback -> exact
   verification. Failure attempts recovery and reports the uncertainty.
6. Integrations receive generic events and decide what Codex, Claude Code, the
   CLI, or a future IDE adapter should do.

## Permissions

- Input Monitoring permits the HID listener to observe dedicated controls.
- Accessibility permits targeted synthetic events to the active Codex window.
- The app does not request microphone access for F11; it triggers Codex’s own
  dictation action.
- No driver seizes the keyboard. Ordinary text is not stored or uploaded.

## Future split point

If the package later grows beyond one supported keyboard, the stable split is:

```text
KeyboardFoundation (generic models, protocols, HID lifecycle)
Air75V3Driver (S4 codec, keymap, lighting, ANSI map)
ApplicationIntegrations (Codex, Claude Code, IDEs, shell, CI)
Air75DeveloperCLI (diagnostics)
Air75AgentBridgeApp (SwiftUI orchestration)
```

That split is deliberately deferred until a second verified hardware driver
creates a real need. The current baseline keeps the smaller reviewable change
surface while preventing Codex from becoming a dependency of the Air75 layer.
