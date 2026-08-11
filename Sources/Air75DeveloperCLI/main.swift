import Air75AgentBridgeCore
import Foundation

private let profileID = "nuphy.air75-v3"
private let layoutID = "nuphy.air75-v3.ansi-d8"

private struct DeveloperSignalLightBackup: Codable {
    var schemaVersion = 1
    var createdAt: Date
    var restoredAt: Date?
    var profileID: String
    var keyName: String
    var signalLight: Air75SignalLight
}

private enum DeveloperCLIError: LocalizedError {
    case usage
    case noCompatibleDevice
    case unknownKey(String)
    case invalidColorComponent(String)
    case backupAlreadyExists(URL)
    case backupNotFound(URL)
    case invalidBackup(URL)
    case verificationFailed(String)

    var errorDescription: String? {
        switch self {
        case .usage:
            return "Run 'air75 --help' for usage."
        case .noCompatibleDevice:
            return "No compatible Air75 V3 HID interface was detected."
        case .unknownKey(let name):
            return "Unknown verified ANSI key '\(name)'. Run 'air75 led map'."
        case .invalidColorComponent(let value):
            return "RGB component '\(value)' must be an integer from 0 to 255."
        case .backupAlreadyExists(let url):
            return "A pending backup already exists at \(url.path). Restore it before another set."
        case .backupNotFound(let url):
            return "No pending backup exists at \(url.path)."
        case .invalidBackup(let url):
            return "The developer-light backup at \(url.path) is invalid or belongs to another key."
        case .verificationFailed(let detail):
            return "Verification failed: \(detail)"
        }
    }
}

private func printUsage() {
    print("""
    air75 - safe Air75 V3 developer diagnostics

    Read-only commands:
      air75 list
      air75 info
      air75 keymap snapshot
      air75 bindings clear
      air75 led map
      air75 led get <KEY>

    Verified recovery and per-key RGB writes:
      air75 keymap restore-original
      air75 lighting restore <BACKUP_JSON>
      air75 led set <KEY> <R> <G> <B>
      air75 led restore <KEY>

    Examples:
      air75 led get F1
      air75 keymap snapshot
      air75 keymap restore-original
      air75 led set F1 255 0 0
      air75 led restore F1
      air75 lighting restore "~/Library/Application Support/Air75AgentBridge/Backups/<file>.json"

    Writes use D8 with exact D2 readback and a persisted recovery color.
    Signal Indicator mode (0x15) must already be active. Bluetooth has no
    verified live lighting channel; USB-C and the U1 receiver are supported.
    """)
}

private func printInterfaces(_ interfaces: [HIDInterfaceSnapshot]) {
    if interfaces.isEmpty {
        print("No compatible Air75 V3 interfaces detected.")
        return
    }
    print("Compatible Air75 V3 interfaces: \(interfaces.count)")
    for interface in interfaces.sorted(by: { $0.id < $1.id }) {
        let manufacturer = interface.manufacturer ?? "unknown"
        let serial = interface.serialNumber ?? "unknown"
        let profile = interface.profileID ?? "unknown"
        print(
            "- id=\(interface.id) vendor=0x\(String(format: "%04X", interface.vendorID)) "
                + "product=0x\(String(format: "%04X", interface.productID)) "
                + "transport=\(interface.transport.rawValue) "
                + "usage=0x\(String(format: "%04X", interface.usagePage)):0x\(String(format: "%04X", interface.usage)) "
                + "reports=in:\(interface.maxInputReportSize.map(String.init) ?? "?")/out:\(interface.maxOutputReportSize.map(String.init) ?? "?") "
                + "manufacturer=\(manufacturer) serial=\(serial) profile=\(profile)"
        )
    }
}

private func requireKey(_ name: String) throws -> SignalLightLayout.Key {
    guard let key = SignalLightLayout.key(layoutID: layoutID, named: name) else {
        throw DeveloperCLIError.unknownKey(name)
    }
    return key
}

private func parseColorComponent(_ value: String) throws -> UInt8 {
    guard let integer = Int(value), (0...255).contains(integer) else {
        throw DeveloperCLIError.invalidColorComponent(value)
    }
    return UInt8(integer)
}

private func encoder() -> JSONEncoder {
    let value = JSONEncoder()
    value.outputFormatting = [.prettyPrinted, .sortedKeys]
    value.dateEncodingStrategy = .iso8601
    return value
}

private func backupURL(for index: UInt8, store: ConfigurationStore) -> URL {
    store.backupsURL.appendingPathComponent("developer-signal-light-\(index).json")
}

private func saveBackup(_ backup: DeveloperSignalLightBackup, to url: URL) throws {
    let data = try encoder().encode(backup)
    try data.write(to: url, options: [.atomic, .completeFileProtection])
    guard (try Data(contentsOf: url)) == data else {
        throw DeveloperCLIError.verificationFailed("backup readback did not match")
    }
}

private func validateBackup(_ backup: DeveloperSignalLightBackup, for key: SignalLightLayout.Key,
                            at url: URL) throws {
    guard backup.profileID == profileID,
          backup.signalLight.index == key.index,
          backup.keyName == key.name else {
        throw DeveloperCLIError.invalidBackup(url)
    }
}

private func loadBackup(from url: URL) throws -> DeveloperSignalLightBackup {
    guard let data = try? Data(contentsOf: url),
          let backup = try? JSONDecoder.iso8601.decode(DeveloperSignalLightBackup.self, from: data) else {
        throw DeveloperCLIError.invalidBackup(url)
    }
    return backup
}

private extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let value = JSONDecoder()
        value.dateDecodingStrategy = .iso8601
        return value
    }
}

private func run(_ arguments: [String]) throws {
    guard let command = arguments.first else {
        printUsage()
        return
    }

    switch command {
    case "--help", "-h":
        printUsage()
    case "list":
        guard arguments.count == 1 else { throw DeveloperCLIError.usage }
        printInterfaces(HIDDeviceManager.enumerateAllInterfaces())
    case "info":
        guard arguments.count == 1 else { throw DeveloperCLIError.usage }
        let interfaces = HIDDeviceManager.enumerateAllInterfaces()
        guard !interfaces.isEmpty else { throw DeveloperCLIError.noCompatibleDevice }
        printInterfaces(interfaces)
        let controller = Air75V3LightingController()
        guard let connection = controller.detectedConnection() else {
            throw DeveloperCLIError.noCompatibleDevice
        }
        print("lightingConnection=\(connection.rawValue)")
        print("firmwareRaw=\(try controller.firmwareDescription())")
        let states = try controller.readStates().sorted { $0.handle < $1.handle }
        print("d5Handles=\(states.map(\.handle))")
        for state in states {
            print(
                "d5 h\(state.handle) backlightMode=\(state.backlight.mode) "
                    + "sidelightMode=\(state.sidelight.mode)"
            )
        }
    case "led":
        try runLEDCommand(Array(arguments.dropFirst()))
    case "bindings":
        guard arguments.count == 2, arguments[1] == "clear" else {
            throw DeveloperCLIError.usage
        }
        let store = ConfigurationStore()
        var configuration = store.load()
        configuration.keyBindings = BridgeConfiguration.defaultBindings
        configuration.setBindings(BridgeConfiguration.defaultBindings, for: profileID)
        configuration.enabled = false
        configuration.codexModeEnabled = false
        configuration.mappingMode = .runtime
        configuration.mappingPausedByUser = true
        configuration.agentLightingEnabled = false
        configuration.hasCompletedOnboarding = false
        try store.save(configuration)
        print("BINDINGS CLEAR verified profile=\(profileID) assignments=0")
    case "keymap":
        guard arguments.count == 2 else {
            throw DeveloperCLIError.usage
        }
        let store = ConfigurationStore()
        var configuration = store.load()
        let controller = Air75V3KeymapController()
        if arguments[1] == "snapshot" {
            let current = try controller.readKeymap()
            guard controller.isPlausibleKeymap(current),
                  !controller.containsBridgeProfile(current) else {
                throw DeveloperCLIError.verificationFailed("current keymap is not a plausible original Air75 V3 layout")
            }
            let url = try store.createKeymapBackup(
                data: current,
                note: "Read-only post-reset source-of-truth snapshot; no keyboard write was performed.",
                profileID: profileID
            )
            print("KEYMAP SNAPSHOT verified bytes=\(current.count) backup=\(url.path)")
            return
        }
        guard arguments[1] == "restore-original" else {
            throw DeveloperCLIError.usage
        }
        guard let selected = store.loadOriginalKeymapBackup(
            preferredName: configuration.hardwareProfileState(for: profileID)?.backupName
        ), let bytes = selected.backup.bytes else {
            throw DeveloperCLIError.verificationFailed("no plausible non-Bridge 1,568-byte original keymap backup was found")
        }
        let readback = try controller.restore(bytes)
        guard readback == bytes else {
            throw DeveloperCLIError.verificationFailed("keymap readback did not match the original backup")
        }
        configuration.enabled = false
        configuration.codexModeEnabled = false
        configuration.mappingPausedByUser = true
        configuration.mappingMode = .unavailable
        configuration.setBindings(
            BridgeConfiguration.bindingsForOriginalHardwareProfile(
                configuration.bindings(for: profileID)
            ),
            for: profileID
        )
        configuration.setHardwareProfileState(nil, for: profileID)
        try store.save(configuration)
        print("KEYMAP RESTORE verified bytes=\(readback.count) backup=\(selected.url.path)")
    case "lighting":
        guard arguments.count == 3, arguments[1] == "restore" else {
            throw DeveloperCLIError.usage
        }
        let url = URL(fileURLWithPath: NSString(string: arguments[2]).expandingTildeInPath)
        let data = try Data(contentsOf: url)
        let backup = try JSONDecoder.iso8601.decode(HardwareLightingBackup.self, from: data)
        guard backup.profileID == nil || backup.profileID == profileID,
              Set(backup.states.map(\.handle)) == Set([0, 1]) else {
            throw DeveloperCLIError.invalidBackup(url)
        }
        let restored = try Air75V3LightingController().restore(backup.states)
        let expectedMac = backup.states.first(where: { $0.handle == 0 })
        let restoredMac = restored.first(where: { $0.handle == 0 })
        guard expectedMac == restoredMac,
              Set(restored.map(\.handle)) == Set([0, 1]) else {
            throw DeveloperCLIError.verificationFailed("D5 macOS handle 0 did not match the backup")
        }
        print("LIGHTING RESTORE verified macOS handle 0; Windows handle 1 remained read-only backup=\(url.path)")
        for state in restored.sorted(by: { $0.handle < $1.handle }) {
            print("d5 h\(state.handle) backlightMode=\(state.backlight.mode) sidelightMode=\(state.sidelight.mode)")
        }
    default:
        throw DeveloperCLIError.usage
    }
}

private func runLEDCommand(_ arguments: [String]) throws {
    guard let command = arguments.first else { throw DeveloperCLIError.usage }
    switch command {
    case "map":
        guard arguments.count == 1 else { throw DeveloperCLIError.usage }
        for key in SignalLightLayout.verifiedANSIKeys {
            let aliases = key.aliases.isEmpty ? "" : " aliases=\(key.aliases.joined(separator: ","))"
            print("\(key.name) index=\(key.index) usage=0x\(String(format: "%04X", key.usage))\(aliases)")
        }
    case "get":
        guard arguments.count == 2 else { throw DeveloperCLIError.usage }
        let key = try requireKey(arguments[1])
        let light = try Air75V3LightingController().readSignalLights(indices: [key.index]).first
        guard let light else { throw DeveloperCLIError.verificationFailed("D2 returned no light for index \(key.index)") }
        print("key=\(key.name) index=\(key.index) rgb=\(light.color.red),\(light.color.green),\(light.color.blue) hex=\(light.color.hex)")
    case "set":
        guard arguments.count == 5 else { throw DeveloperCLIError.usage }
        let key = try requireKey(arguments[1])
        let color = Air75RGBColor(
            red: try parseColorComponent(arguments[2]),
            green: try parseColorComponent(arguments[3]),
            blue: try parseColorComponent(arguments[4])
        )
        let store = ConfigurationStore()
        try store.prepareDirectories()
        let backupURL = backupURL(for: key.index, store: store)
        var backup: DeveloperSignalLightBackup?
        if FileManager.default.fileExists(atPath: backupURL.path) {
            let existing = try loadBackup(from: backupURL)
            try validateBackup(existing, for: key, at: backupURL)
            guard existing.restoredAt != nil else {
                throw DeveloperCLIError.backupAlreadyExists(backupURL)
            }
            backup = existing
        }
        let controller = Air75V3LightingController()
        guard let previous = try controller.readSignalLights(indices: [key.index]).first else {
            throw DeveloperCLIError.verificationFailed("D2 returned no previous color")
        }
        if var backup {
            // Keep the earliest verified original color as the recovery point
            // across repeated set/restore cycles, but mark it pending before
            // the next write so a failure cannot leave an apparently restored
            // backup.
            backup.restoredAt = nil
            try saveBackup(backup, to: backupURL)
        } else {
            try saveBackup(
                DeveloperSignalLightBackup(
                    createdAt: Date(), restoredAt: nil, profileID: profileID,
                    keyName: key.name, signalLight: previous
                ),
                to: backupURL
            )
        }
        do {
            let verified = try controller.setSignalLights([
                Air75SignalLight(index: key.index, color: color)
            ])
            guard verified == [Air75SignalLight(index: key.index, color: color)] else {
                throw DeveloperCLIError.verificationFailed("Per-key RGB readback did not match the requested color")
            }
            print("SET verified key=\(key.name) index=\(key.index) rgb=\(color.red),\(color.green),\(color.blue)")
            print("backup=\(backupURL.path)")
        } catch {
            fputs("SET failed; the pre-write backup remains at \(backupURL.path)\n", stderr)
            throw error
        }
    case "restore":
        guard arguments.count == 2 else { throw DeveloperCLIError.usage }
        let key = try requireKey(arguments[1])
        let store = ConfigurationStore()
        let backupURL = backupURL(for: key.index, store: store)
        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            throw DeveloperCLIError.backupNotFound(backupURL)
        }
        var backup = try loadBackup(from: backupURL)
        try validateBackup(backup, for: key, at: backupURL)
        let verified = try Air75V3LightingController().setSignalLights([backup.signalLight])
        guard verified == [backup.signalLight] else {
            throw DeveloperCLIError.verificationFailed("Per-key RGB readback did not match the saved color")
        }
        backup.restoredAt = Date()
        try saveBackup(backup, to: backupURL)
        print("RESTORE verified key=\(key.name) index=\(key.index) rgb=\(backup.signalLight.color.red),\(backup.signalLight.color.green),\(backup.signalLight.color.blue)")
    default:
        throw DeveloperCLIError.usage
    }
}

do {
    try run(Array(CommandLine.arguments.dropFirst()))
} catch {
    fputs("error: \(error.localizedDescription)\n", stderr)
    exit(EXIT_FAILURE)
}
