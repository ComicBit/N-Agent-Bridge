import Air75AgentBridgeCore
import SwiftUI

struct Air75KeyboardLayoutView: View {
    struct Key {
        let label: String
        let usage: Int?
        let width: CGFloat

        init(_ label: String, usage: Int? = nil, width: CGFloat = 1) {
            self.label = label
            self.usage = usage
            self.width = width
        }
    }

    let bindings: [KeyBinding]
    let learningBindingIndex: Int?
    let hardwareProfileInstalled: Bool
    let colorsBySignalLightIndex: [Int: String]
    let actionTitle: (BridgeAction) -> String
    let assign: (Int, Int) -> Void

    private let rows: [[Key]] = [
        [Key("Esc", usage: 0x29)]
            + (1...12).map { Key("F\($0)", usage: 0x39 + $0) }
            + [Key("PrtSc", usage: 0x46), Key("Ins", usage: 0x49), Key("◉")],
        [Key("`", usage: 0x35)]
            + (1...9).map { Key("\($0)", usage: 0x1D + $0) }
            + [Key("0", usage: 0x27), Key("-", usage: 0x2D), Key("=", usage: 0x2E),
               Key("Delete", usage: 0x2A, width: 2), Key("M1")],
        [Key("Tab", usage: 0x2B, width: 1.5)]
            + zip(Array("QWERTYUIOP"), [0x14, 0x1A, 0x08, 0x15, 0x17, 0x1C, 0x18, 0x0C, 0x12, 0x13]).map {
                Key(String($0.0), usage: $0.1)
            }
            + [Key("[", usage: 0x2F), Key("]", usage: 0x30), Key("\\", usage: 0x31, width: 1.5),
               Key("PgDn", usage: 0x4E)],
        [Key("Caps", usage: 0x39, width: 1.7)]
            + zip(Array("ASDFGHJKL"), [0x04, 0x16, 0x07, 0x09, 0x0A, 0x0B, 0x0D, 0x0E, 0x0F]).map {
                Key(String($0.0), usage: $0.1)
            }
            + [Key(";", usage: 0x33), Key("'", usage: 0x34), Key("Return", usage: 0x28, width: 2.3),
               Key("Home", usage: 0x4A)],
        [Key("Shift", width: 2.2)]
            + zip(Array("ZXCVBNM"), [0x1D, 0x1B, 0x06, 0x19, 0x05, 0x11, 0x10]).map {
                Key(String($0.0), usage: $0.1)
            }
            + [Key(",", usage: 0x36), Key(".", usage: 0x37), Key("/", usage: 0x38),
               Key("Shift", width: 2), Key("↑", usage: 0x52), Key("End", usage: 0x4D)],
        [Key("Ctrl"), Key("Opt"), Key("Cmd"), Key("Space", usage: 0x2C, width: 6.1),
         Key("Cmd"), Key("Fn"), Key("Ctrl"), Key("←", usage: 0x50),
         Key("↓", usage: 0x51), Key("→", usage: 0x4F)]
    ]

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 7) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 6) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, key in keyView(key) }
                    }
                }
            }
            .padding(10)
        }
        .background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Air75 V3 keyboard layout")
    }

    @ViewBuilder
    private func keyView(_ key: Key) -> some View {
        let assignment = key.usage.flatMap { physicalUsage in
            let eventUsage = hardwareProfileInstalled && (0x3A...0x45).contains(physicalUsage)
                ? physicalUsage + (0x68 - 0x3A) : physicalUsage
            return bindings.enumerated().first(where: {
                $0.element.usagePage == 0x07 && $0.element.usage == eventUsage
            })
        }
        let isTarget = assignment?.offset == learningBindingIndex
        let statusColor = assignment?.element.signalLightIndex
            .flatMap { colorsBySignalLightIndex[$0] }
            .flatMap(swiftUIColor)
        Button {
            guard let learningBindingIndex, let usage = key.usage else { return }
            assign(learningBindingIndex, usage)
        } label: {
            VStack(spacing: 2) {
                Text(key.label)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                if let assignment {
                    Text(actionTitle(assignment.element.action))
                        .font(.system(size: 8, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 35)
        }
        .buttonStyle(.plain)
        .frame(width: 42 * key.width)
        .background(
            statusColor?.opacity(0.42)
                ?? (assignment == nil ? Color.primary.opacity(0.045) : Color.accentColor.opacity(isTarget ? 0.28 : 0.13)),
            in: RoundedRectangle(cornerRadius: 7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(isTarget ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: isTarget ? 2 : 1)
        )
        .disabled(key.usage == nil || learningBindingIndex == nil)
        .accessibilityLabel(assignment.map {
            "\(key.label), assigned to \(actionTitle($0.element.action))"
        } ?? "\(key.label), unassigned")
        .accessibilityHint(learningBindingIndex == nil ? "Choose Change on an action first" : "Assign selected action to this key")
    }

    private func swiftUIColor(hex: String) -> Color? {
        guard let color = Air75RGBColor(hex: hex) else { return nil }
        return Color(
            red: Double(color.red) / 255,
            green: Double(color.green) / 255,
            blue: Double(color.blue) / 255
        )
    }
}
