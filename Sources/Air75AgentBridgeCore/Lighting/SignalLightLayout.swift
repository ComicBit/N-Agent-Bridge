import Foundation

/// ANSI D2 per-key RGB read-index layout for the Air75 V3. The visible-key order is
/// derived from NuPhy's official NuPhyIO layout; the three hidden knob entries
/// after Insert are removed by the firmware's `skipPos/skipSize` rule.
public enum SignalLightLayout {
    /// A physical-key name and its Air75 V3 ANSI D2 RGB read index.
    /// Aliases cover the installed F13-F24 hardware profile and common CLI
    /// spellings without duplicating the underlying firmware map.
    public struct Key: Codable, Equatable, Hashable, Identifiable, Sendable {
        public let name: String
        public let usagePage: Int
        public let usage: Int
        public let index: UInt8
        public let aliases: [String]

        public var id: String { name }

        public init(name: String, usagePage: Int, usage: Int, index: UInt8,
                    aliases: [String] = []) {
            self.name = name
            self.usagePage = usagePage
            self.usage = usage
            self.index = index
            self.aliases = aliases
        }
    }

    /// The subset of the ANSI board currently exposed by the D2 read map.
    /// Gaps in the numeric index sequence are firmware-reserved or hidden
    /// positions and are intentionally not made addressable by name.
    public static let verifiedANSIKeys: [Key] = [
        makeKey("Esc", usage: 0x29, aliases: ["Escape"]),
        makeKey("F1", usage: 0x3A, aliases: ["F13"]),
        makeKey("F2", usage: 0x3B, aliases: ["F14"]),
        makeKey("F3", usage: 0x3C, aliases: ["F15"]),
        makeKey("F4", usage: 0x3D, aliases: ["F16"]),
        makeKey("F5", usage: 0x3E, aliases: ["F17"]),
        makeKey("F6", usage: 0x3F, aliases: ["F18"]),
        makeKey("F7", usage: 0x40, aliases: ["F19"]),
        makeKey("F8", usage: 0x41, aliases: ["F20"]),
        makeKey("F9", usage: 0x42, aliases: ["F21"]),
        makeKey("F10", usage: 0x43, aliases: ["F22"]),
        makeKey("F11", usage: 0x44, aliases: ["F23"]),
        makeKey("F12", usage: 0x45, aliases: ["F24"]),
        makeKey("Print Screen", usage: 0x46, aliases: ["PrintScreen", "PrtSc"]),
        makeKey("Insert", usage: 0x49),
        makeKey("Backtick", usage: 0x35, aliases: ["`"]),
        makeKey("1", usage: 0x1E), makeKey("2", usage: 0x1F),
        makeKey("3", usage: 0x20), makeKey("4", usage: 0x21),
        makeKey("5", usage: 0x22), makeKey("6", usage: 0x23),
        makeKey("7", usage: 0x24), makeKey("8", usage: 0x25),
        makeKey("9", usage: 0x26), makeKey("0", usage: 0x27),
        makeKey("Minus", usage: 0x2D, aliases: ["-"]),
        makeKey("Equals", usage: 0x2E, aliases: ["="]),
        makeKey("Backspace", usage: 0x2A, aliases: ["Delete"]),
        makeKey("Page Up", usage: 0x4B, aliases: ["PageUp"]),
        makeKey("Tab", usage: 0x2B),
        makeKey("Q", usage: 0x14), makeKey("W", usage: 0x1A),
        makeKey("E", usage: 0x08), makeKey("R", usage: 0x15),
        makeKey("T", usage: 0x17), makeKey("Y", usage: 0x1C),
        makeKey("U", usage: 0x18), makeKey("I", usage: 0x0C),
        makeKey("O", usage: 0x12), makeKey("P", usage: 0x13),
        makeKey("Left Bracket", usage: 0x2F, aliases: ["["]),
        makeKey("Right Bracket", usage: 0x30, aliases: ["]"]),
        makeKey("Return", usage: 0x28, aliases: ["Enter"]),
        makeKey("Page Down", usage: 0x4E, aliases: ["PageDown"]),
        makeKey("Caps Lock", usage: 0x39, aliases: ["CapsLock"]),
        makeKey("A", usage: 0x04), makeKey("S", usage: 0x16),
        makeKey("D", usage: 0x07), makeKey("F", usage: 0x09),
        makeKey("G", usage: 0x0A), makeKey("H", usage: 0x0B),
        makeKey("J", usage: 0x0D), makeKey("K", usage: 0x0E),
        makeKey("L", usage: 0x0F),
        makeKey("Semicolon", usage: 0x33, aliases: [";"]),
        makeKey("Apostrophe", usage: 0x34, aliases: ["'"]),
        makeKey("Backslash", usage: 0x31, aliases: ["\\"]),
        makeKey("Home", usage: 0x4A),
        makeKey("Z", usage: 0x1D), makeKey("X", usage: 0x1B),
        makeKey("C", usage: 0x06), makeKey("V", usage: 0x19),
        makeKey("B", usage: 0x05), makeKey("N", usage: 0x11),
        makeKey("M", usage: 0x10),
        makeKey("Comma", usage: 0x36, aliases: [","]),
        makeKey("Period", usage: 0x37, aliases: ["."]),
        makeKey("Slash", usage: 0x38, aliases: ["/"]),
        makeKey("Up", usage: 0x52, aliases: ["ArrowUp"]),
        makeKey("End", usage: 0x4D),
        makeKey("Space", usage: 0x2C),
        makeKey("Left", usage: 0x50, aliases: ["ArrowLeft"]),
        makeKey("Down", usage: 0x51, aliases: ["ArrowDown"]),
        makeKey("Right", usage: 0x4F, aliases: ["ArrowRight"])
    ]

    /// Resolves a user-facing physical key name without allowing arbitrary
    /// numeric LED addresses. This keeps developer writes inside the verified
    /// ANSI map and gives F13-F24 the same physical locations as F1-F12.
    public static func key(layoutID: String?, named name: String) -> Key? {
        guard layoutID == "nuphy.air75-v3.ansi-d8" else { return nil }
        let normalized = normalizeKeyName(name)
        return verifiedANSIKeys.first { key in
            ([key.name] + key.aliases).map(normalizeKeyName).contains(normalized)
        }
    }

    /// Per-key colors are read independently from ordinary backlight
    /// animation. The corresponding write path is not enabled.
    /// A short-lived first-run bug assigned Agent 3 to Tab (index 30), so the
    /// Air75 driver explicitly clears it unless Tab is intentionally active.
    public static func staleManagedIndices(layoutID: String?) -> Set<Int> {
        layoutID == "nuphy.air75-v3.ansi-d8" ? [30] : []
    }

    public static func index(
        layoutID: String?,
        usagePage: Int,
        usage: Int
    ) -> Int? {
        guard layoutID == "nuphy.air75-v3.ansi-d8", usagePage == 0x07 else {
            return nil
        }
        return air75V3ANSI[usage]
    }

    private static let air75V3ANSI: [Int: Int] = {
        var result: [Int: Int] = [:]

        result[0x29] = 0 // Esc
        for offset in 0..<12 {
            result[0x3A + offset] = 1 + offset // native F1...F12
            result[0x68 + offset] = 1 + offset // Bridge F13...F24 layer
        }
        result[0x46] = 13 // Print Screen / screenshot key
        result[0x49] = 14 // Insert

        result[0x35] = 15 // `
        for offset in 0..<10 { result[0x1E + offset] = 16 + offset } // 1...0
        result[0x2D] = 26
        result[0x2E] = 27
        result[0x2A] = 28
        result[0x4B] = 29 // Page Up

        result[0x2B] = 30 // Tab
        let qwertyUsages = [0x14, 0x1A, 0x08, 0x15, 0x17, 0x1C, 0x18, 0x0C, 0x12, 0x13]
        for (offset, usage) in qwertyUsages.enumerated() { result[usage] = 31 + offset }
        result[0x2F] = 41
        result[0x30] = 42
        result[0x28] = 43 // ANSI Return
        result[0x4E] = 44 // Page Down

        result[0x39] = 45 // Caps Lock
        let homeRow = [0x04, 0x16, 0x07, 0x09, 0x0A, 0x0B, 0x0D, 0x0E, 0x0F]
        for (offset, usage) in homeRow.enumerated() { result[usage] = 46 + offset }
        result[0x33] = 55
        result[0x34] = 56
        result[0x31] = 57
        result[0x4A] = 58 // Home

        let bottomLetters = [0x1D, 0x1B, 0x06, 0x19, 0x05, 0x11, 0x10]
        for (offset, usage) in bottomLetters.enumerated() { result[usage] = 61 + offset }
        result[0x36] = 68
        result[0x37] = 69
        result[0x38] = 70
        result[0x52] = 72 // Up
        result[0x4D] = 73 // End
        result[0x2C] = 77 // Space
        result[0x50] = 81 // Left
        result[0x51] = 82 // Down
        result[0x4F] = 83 // Right
        return result
    }()

    private static func makeKey(_ name: String, usage: Int, aliases: [String] = []) -> Key {
        Key(
            name: name,
            usagePage: 0x07,
            usage: usage,
            index: UInt8(air75V3ANSI[usage] ?? 0),
            aliases: aliases
        )
    }

    private static func normalizeKeyName(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .uppercased()
            .filter { $0.isLetter || $0.isNumber }
    }
}
