@_spi(HardwareValidation) import Air75AgentBridgeCore
import Foundation
import IOKit.hid

private struct KeyLightColorSnapshot: Codable {
    var schemaVersion = 1
    var createdAt: Date
    var profileID: String
    var lights: [Air75SignalLight]
    var note: String
}

private enum ProbeError: LocalizedError {
    case verificationFailed(String)

    var errorDescription: String? {
        switch self {
        case .verificationFailed(let detail): return "Air75 V3 verification failed: \(detail)"
        }
    }
}

private func hexBytes(_ bytes: [UInt8]) -> String {
    bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
}

private func saveKeyLightColorSnapshot(
    _ lights: [Air75SignalLight],
    label: String,
    note: String
) throws -> URL {
    let store = ConfigurationStore()
    try store.prepareDirectories()
    let stamp = ISO8601DateFormatter()
        .string(from: Date())
        .replacingOccurrences(of: ":", with: "-")
    let url = store.backupsURL.appendingPathComponent(
        "\(stamp)-\(label)-hardware-key-light-colors.json"
    )
    let backup = KeyLightColorSnapshot(
        createdAt: Date(),
        profileID: "nuphy.air75-v3",
        lights: lights,
        note: note
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(backup)
    try data.write(to: url, options: [.atomic, .completeFileProtection])
    guard (try Data(contentsOf: url)) == data else {
        throw ProbeError.verificationFailed("The read-only key-color snapshot did not match when read back.")
    }
    return url
}

private func blinkF1Red(
    duration: TimeInterval = 60,
    connection: KeyboardLightingConnection = .usbCable
) throws {
    let controller = Air75V3LightingController(preferredConnection: connection)
    guard controller.detectedConnection() == connection else {
        throw ProbeError.verificationFailed("The requested Air75 V3 lighting interface was not found.")
    }
    let stateController = controller

    let originalStates = try stateController.readStates()
    guard let originalMacState = originalStates.first(where: { $0.handle == 0 }) else {
        throw ProbeError.verificationFailed("D5 did not return macOS handle 0.")
    }
    let lightingBackup = try ConfigurationStore().createLightingBackup(
        states: originalStates,
        note: "Complete dual-handle state captured before the protected one-minute F1 red blink test.",
        profileID: controller.profileID,
        deviceFingerprint: nil
    )

    let allKeyLightIndices = Array(UInt8(0)...UInt8(83))
    let staticPalette = try controller.readSignalLights(indices: allKeyLightIndices)
    var signalLayerBackup: [Air75SignalLight]?
    var signalLayerRestored = false
    var lightingStateRestored = false
    defer {
        if let signalLayerBackup, !signalLayerRestored {
            for start in stride(from: 0, to: signalLayerBackup.count, by: 14) {
                _ = try? controller.hardwareValidateSignalLights(
                    Array(signalLayerBackup[start..<min(start + 14, signalLayerBackup.count)])
                )
            }
        }
        if !lightingStateRestored {
            _ = try? stateController.restore(originalStates)
        }
    }

    let indicatorStates = try stateController.setBacklight(mode: .signalIndicator)
    guard let indicatorMacState = indicatorStates.first(where: { $0.handle == 0 }),
          indicatorMacState.backlight.mode == Air75BacklightMode.signalIndicator.rawValue,
          Array(indicatorMacState.raw[9...16]) == Array(originalMacState.raw[9...16]),
          indicatorStates.first(where: { $0.handle == 1 }) == originalStates.first(where: { $0.handle == 1 }) else {
        throw ProbeError.verificationFailed(
            "Signal-indicator activation changed side lights or Windows handle 1."
        )
    }

    let originalSignalPalette = try controller.readSignalLights(indices: allKeyLightIndices)
    signalLayerBackup = originalSignalPalette
    let snapshot = try saveKeyLightColorSnapshot(
        originalSignalPalette,
        label: "blink-f1-signal-layer",
        note: "All 84 signal-layer colors captured before the protected one-minute red blink test."
    )
    print("lighting backup: \(lightingBackup.path)")
    print("F1 signal-layer backup: \(snapshot.path)")
    for start in stride(from: 0, to: staticPalette.count, by: 14) {
        _ = try controller.hardwareValidateSignalLights(
            Array(staticPalette[start..<min(start + 14, staticPalette.count)])
        )
    }
    print("Static palette copied into signal layer: PASS")
    print("F1 red blink: START (60 seconds; other keys and side lights preserved)")

    let red = Air75SignalLight(index: 1, color: Air75RGBColor(red: 0xFF, green: 0, blue: 0))
    let off = Air75SignalLight(index: 1, color: Air75RGBColor(red: 0, green: 0, blue: 0))
    let deadline = Date().addingTimeInterval(duration)
    var redIsOn = false
    while Date() < deadline {
        redIsOn.toggle()
        _ = try controller.hardwareValidateSignalLights([redIsOn ? red : off])
        Thread.sleep(forTimeInterval: 0.5)
    }

    for start in stride(from: 0, to: originalSignalPalette.count, by: 14) {
        _ = try controller.hardwareValidateSignalLights(
            Array(originalSignalPalette[start..<min(start + 14, originalSignalPalette.count)])
        )
    }
    signalLayerRestored = true
    let restoredStates = try stateController.restore(originalStates)
    guard restoredStates == originalStates else {
        throw ProbeError.verificationFailed("Original D5 lighting state was not restored after blinking.")
    }
    lightingStateRestored = true
    guard try controller.readSignalLights(indices: allKeyLightIndices) == staticPalette else {
        throw ProbeError.verificationFailed("Original Static palette was not restored after blinking.")
    }
    print("F1 red blink: PASS; original F1 color and Static mode restored")
}

private func enumerateNuPhyInterfaces() {
    let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    IOHIDManagerSetDeviceMatching(
        manager,
        [kIOHIDVendorIDKey: Air75V3KeymapController.vendorID] as CFDictionary
    )
    _ = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    defer { IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone)) }
    let devices = (IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>) ?? []

    func property(_ device: IOHIDDevice, _ key: String) -> Any? {
        IOHIDDeviceGetProperty(device, key as CFString)
    }

    for device in devices.sorted(by: {
        ((property($0, kIOHIDProductIDKey) as? Int) ?? 0)
            < ((property($1, kIOHIDProductIDKey) as? Int) ?? 0)
    }) {
        let productID = (property(device, kIOHIDProductIDKey) as? Int) ?? 0
        let name = (property(device, kIOHIDProductKey) as? String) ?? "?"
        let transport = (property(device, kIOHIDTransportKey) as? String) ?? "?"
        let page = (property(device, kIOHIDPrimaryUsagePageKey) as? Int) ?? -1
        let usage = (property(device, kIOHIDPrimaryUsageKey) as? Int) ?? -1
        let input = (property(device, kIOHIDMaxInputReportSizeKey) as? Int) ?? 0
        let output = (property(device, kIOHIDMaxOutputReportSizeKey) as? Int) ?? 0
        print(String(
            format: "PID=%04X transport=%@ usage=%d:%d in=%d out=%d name=%@",
            productID, transport, page, usage, input, output, name
        ))
    }
}

private func validateWirelessReadRoute() throws {
    let controller = Air75V3LightingController(preferredConnection: .twoPointFourGHzReceiver)
    for attempt in 1...5 {
        let states = try controller.hardwareReadReceiverStates()
        guard states.count == 2 else {
            throw ProbeError.verificationFailed("U1 D5 did not return both lighting handles.")
        }
        print("U1 D5 read \(attempt)/5: PASS")
        for state in states.sorted(by: { $0.handle < $1.handle }) {
            print("  h\(state.handle): \(hexBytes(state.raw))")
        }
    }
}

private func validateWirelessD6() throws {
    let controller = Air75V3LightingController(preferredConnection: .twoPointFourGHzReceiver)
    guard controller.detectedConnection() == .twoPointFourGHzReceiver else {
        throw ProbeError.verificationFailed("The U1 2.4G management interface was not found.")
    }
    let originalStates = try controller.readStates()
    let backupURL = try ConfigurationStore().createLightingBackup(
        states: originalStates,
        note: "Complete dual-handle state captured before protected U1 D6 mode validation.",
        profileID: controller.profileID,
        deviceFingerprint: nil
    )
    guard let originalMacState = originalStates.first(where: { $0.handle == 0 }) else {
        throw ProbeError.verificationFailed("U1 D5 did not return macOS handle 0.")
    }
    var restored = false
    defer {
        if !restored { _ = try? controller.restore(originalStates) }
    }
    print("wireless D6 backup: \(backupURL.path)")

    let changed = try controller.setBacklight(mode: .signalIndicator)
    guard let changedMacState = changed.first(where: { $0.handle == 0 }),
          changedMacState.backlight.mode == Air75BacklightMode.signalIndicator.rawValue,
          Array(changedMacState.raw[9...16]) == Array(originalMacState.raw[9...16]),
          changed.first(where: { $0.handle == 1 }) == originalStates.first(where: { $0.handle == 1 }) else {
        throw ProbeError.verificationFailed(
            "U1 D6 changed side lights, failed mode readback, or modified Windows handle 1."
        )
    }
    print("U1 D6 mode 0x15 + exact D5 readback: PASS")
    Thread.sleep(forTimeInterval: 2)

    let finalStates = try controller.restore(originalStates)
    guard finalStates == originalStates else {
        throw ProbeError.verificationFailed("U1 D6 did not restore the original dual-handle state.")
    }
    restored = true
    print("U1 D6 original Static mode restore: PASS")
}

private func validateHardware() throws {
    let controller = Air75V3LightingController(preferredConnection: .usbCable)
    guard controller.detectedConnection() == .usbCable else {
        throw ProbeError.verificationFailed("No Air75 V3 USB-C management interface was found.")
    }

    let firmware = try controller.firmwareDescription()
    let originalStates = try controller.readStates()
    let lightingBackup = try ConfigurationStore().createLightingBackup(
        states: originalStates,
        note: "Complete dual-handle state captured before Air75 V3 1.0.16.6 D5/D6 restore validation.",
        profileID: "nuphy.air75-v3",
        deviceFingerprint: nil
    )
    print("firmware: \(firmware)")
    print("lighting backup: \(lightingBackup.path)")
    for state in originalStates.sorted(by: { $0.handle < $1.handle }) {
        print("D5 h\(state.handle): \(hexBytes(state.raw))")
    }

    // D6 validation uses an exact no-op. The controller requires full ACK,
    // bounded D5 readback and rollback on any mismatch.
    let d6Verified = try controller.restore(originalStates)
    guard d6Verified == originalStates else {
        throw ProbeError.verificationFailed("D5 dual-handle readback did not match after the D6 original-state write.")
    }
    print("D6 no-op ACK + D5 exact readback: PASS")

    guard let originalMacState = originalStates.first(where: { $0.handle == 0 }) else {
        throw ProbeError.verificationFailed("D5 did not return macOS handle 0.")
    }
    let temporaryBrightness = originalMacState.backlight.brightness == 99
        ? 98 : 99
    let changedStates = try controller.setBacklight(brightness: temporaryBrightness)
    guard changedStates.first(where: { $0.handle == 0 })?.backlight.brightness
            == temporaryBrightness else {
        throw ProbeError.verificationFailed("The temporary D6 brightness write did not pass D5 readback.")
    }
    let restoredStates = try controller.restore(originalStates)
    guard restoredStates == originalStates else {
        throw ProbeError.verificationFailed("D6 did not restore the exact original state after the temporary brightness test.")
    }
    print("D6 changed value + exact restore: PASS")

    let indexes = Array(UInt8(0)...UInt8(6))
    let originalLights = try controller.readSignalLights(indices: indexes)
    let keyLightSnapshot = try saveKeyLightColorSnapshot(
        originalLights,
        label: "pre-mode",
        note: "Esc and F1-F6 D2 colors captured before temporary signal-indicator-mode validation."
    )
    print("D2 pre-validation RGB snapshot: \(keyLightSnapshot.path)")

    guard let originalF1 = originalLights.first(where: { $0.index == 1 }) else {
        throw ProbeError.verificationFailed("D2 did not return the F1 per-key RGB value.")
    }
    print("D2 F1 RGB: \(originalF1.color.hex)")

    // D8 is the per-key signal layer, but firmware applies it only while the
    // key backlight is in mode 0x15. Preserve both D5 profiles, modify only the
    // macOS backlight-mode byte, and leave side-light bytes 9...16 untouched.
    var indicatorLights: [Air75SignalLight]?
    var indicatorLightsRestored = false
    var lightingStateRestored = false
    defer {
        if let indicatorLights, !indicatorLightsRestored {
            _ = try? controller.hardwareValidateSignalLights(indicatorLights)
        }
        if !lightingStateRestored {
            _ = try? controller.restore(originalStates)
        }
    }

    let indicatorStates = try controller.setBacklight(mode: .signalIndicator)
    guard let indicatorMacState = indicatorStates.first(where: { $0.handle == 0 }),
          indicatorMacState.backlight.mode == Air75BacklightMode.signalIndicator.rawValue,
          Array(indicatorMacState.raw[9...16]) == Array(originalMacState.raw[9...16]),
          indicatorStates.first(where: { $0.handle == 1 }) == originalStates.first(where: { $0.handle == 1 }) else {
        throw ProbeError.verificationFailed(
            "D6 did not activate signal-indicator mode without changing side lights or Windows handle 1."
        )
    }
    print("D6 macOS key-backlight mode 0x15 activation: PASS; side lights unchanged")

    let capturedIndicatorLights = try controller.readSignalLights(indices: indexes)
    indicatorLights = capturedIndicatorLights
    let indicatorSnapshot = try saveKeyLightColorSnapshot(
        capturedIndicatorLights,
        label: "signal-layer",
        note: "Esc and F1-F6 signal-layer colors captured after temporary mode 0x15 activation and before D8 validation."
    )
    print("D2 signal-layer backup: \(indicatorSnapshot.path)")

    let d8NoOp = try controller.hardwareValidateSignalLights(capturedIndicatorLights)
    guard d8NoOp == capturedIndicatorLights.sorted(by: { $0.index < $1.index }) else {
        throw ProbeError.verificationFailed("D8 original-value write did not pass exact D2 readback.")
    }
    print("D8 no-op ACK + D2 exact readback: PASS")

    guard let indicatorF1 = capturedIndicatorLights.first(where: { $0.index == 1 }) else {
        throw ProbeError.verificationFailed("D2 did not return F1 in signal-indicator mode.")
    }
    let temporaryColor = indicatorF1.color == Air75RGBColor(red: 0xFF, green: 0x00, blue: 0xFF)
        ? Air75RGBColor(red: 0x00, green: 0xFF, blue: 0xFF)
        : Air75RGBColor(red: 0xFF, green: 0x00, blue: 0xFF)
    let writeStartedAt = Date()
    let changedLights = try controller.hardwareValidateSignalLights([
        Air75SignalLight(index: 1, color: temporaryColor)
    ])
    let verifiedLatency = Date().timeIntervalSince(writeStartedAt)
    guard changedLights == [Air75SignalLight(index: 1, color: temporaryColor)] else {
        throw ProbeError.verificationFailed("D8 temporary F1 color did not pass D2 readback.")
    }
    print(String(
        format: "D8 F1 temporary color %@: PASS (ACK + D2 readback %.0f ms)",
        temporaryColor.hex,
        verifiedLatency * 1_000
    ))
    Thread.sleep(forTimeInterval: 2.0)

    let restoredIndicatorLights = try controller.hardwareValidateSignalLights(capturedIndicatorLights)
    guard restoredIndicatorLights == capturedIndicatorLights.sorted(by: { $0.index < $1.index }) else {
        throw ProbeError.verificationFailed("D8 did not restore the exact original signal-layer colors.")
    }
    indicatorLightsRestored = true
    print("D8 changed value + exact signal-layer restore: PASS")

    let restoredLightingStates = try controller.restore(originalStates)
    guard restoredLightingStates == originalStates else {
        throw ProbeError.verificationFailed("D6 did not restore the original static lighting state.")
    }
    lightingStateRestored = true
    print("D6 original key-backlight mode restored: PASS")

    let keymapController = Air75V3KeymapController()
    let keymap = try keymapController.readKeymap()
    guard keymap.count == Air75V3KeymapController.keymapByteCount,
          Air75V3KeymapController.isPlausibleKeymap(keymap) else {
        throw ProbeError.verificationFailed("The 1,568-byte keymap does not match the verified Air75 V3 ANSI safety layout.")
    }
    print("B2 full keymap readback: PASS")
    print("Bridge F13–F24 profile installed: \(Air75V3KeymapController.hasBridgeProfile(keymap))")

    let finalStates = try controller.readStates()
    let finalLights = try controller.readSignalLights(indices: indexes)
    guard finalStates == originalStates, finalLights == originalLights else {
        throw ProbeError.verificationFailed("The final state does not match the pre-validation backup.")
    }
    print("FINAL RESTORE CHECK: PASS")
}

do {
    if CommandLine.arguments.contains("--enumerate") {
        enumerateNuPhyInterfaces()
    } else if CommandLine.arguments.contains("--wireless-read-validate") {
        try validateWirelessReadRoute()
    } else if CommandLine.arguments.contains("--wireless-d6-validate") {
        try validateWirelessD6()
    } else if CommandLine.arguments.contains("--blink-f1-red-wireless") {
        try blinkF1Red(connection: .twoPointFourGHzReceiver)
    } else if CommandLine.arguments.contains("--blink-f1-red") {
        try blinkF1Red()
    } else if CommandLine.arguments.contains("--hardware-validate") {
        try validateHardware()
    } else {
        print("Usage:")
        print("  Air75ProtocolProbe --enumerate")
        print("  Air75ProtocolProbe --wireless-read-validate")
        print("  Air75ProtocolProbe --wireless-d6-validate")
        print("  Air75ProtocolProbe --blink-f1-red")
        print("  Air75ProtocolProbe --blink-f1-red-wireless")
        print("  Air75ProtocolProbe --hardware-validate")
        print("Quit N Agent Bridge and NuPhyIO before running hardware validation.")
    }
} catch {
    fputs("ERROR: \(error.localizedDescription)\n", stderr)
    exit(1)
}
