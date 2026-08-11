import Air75AgentBridgeCore
import SwiftUI

struct KeyboardSetupWizardView: View {
    @EnvironmentObject private var store: BridgeStore
    @Environment(\.interfaceLanguage) private var language
    @State private var step = 0
    @State private var selectedBinding = 0

    private let states: [CodexTaskLightState] = [
        .idle, .reasoning, .waitingForConfirmation, .complete, .error
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(language.text("设置你的 Air75 V3", "Set up your Air75 V3"))
                        .font(.title.bold())
                    Text(language.text(
                        "只分配按键和状态灯，永远不改写键盘键位表。",
                        "Assign actions and status lights without ever rewriting the keyboard keymap."
                    ))
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(step + 1) / 3")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(26)

            Divider()

            Group {
                switch step {
                case 0: connectionStep
                case 1: assignmentStep
                default: previewStep
                }
            }
            .padding(26)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Divider()
            HStack {
                if step > 0 { Button(language.text("返回", "Back")) { step -= 1 } }
                Spacer()
                if step < 2 {
                    Button(language.text("继续", "Continue")) { step += 1 }
                        .buttonStyle(.borderedProminent)
                        .disabled(step == 0 && store.currentDevice == nil)
                } else {
                    Button(language.text("启用软件按键控制", "Enable software key control")) {
                        store.oneClickEnable()
                        store.completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
        }
        .frame(width: 960, height: 720)
        .background(AppPalette.pageBackground)
    }

    private var connectionStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label(
                store.currentDevice == nil
                    ? language.text("等待 Air75 V3", "Waiting for Air75 V3")
                    : language.text("已识别 \(store.currentModelName)", "Detected \(localizedModelName(store.currentModelName, language))"),
                systemImage: store.currentDevice == nil ? "keyboard.badge.ellipsis" : "checkmark.circle.fill"
            )
            .font(.title2.bold())
            .foregroundStyle(store.currentDevice == nil ? Color.secondary : Color.green)

            Text(language.text(
                "应用会保留你刚刚重置后的真实键位。后续每个选择都只是 macOS 软件分配。",
                "The reset keyboard layout remains the source of truth. Every selection that follows is a macOS software assignment only."
            ))
            .font(.body)
            .foregroundStyle(.secondary)

            Label(language.text("不写入 F13–F24", "No F13–F24 keymap installation"), systemImage: "lock.shield")
            Label(language.text("不修改旋钮或 Fn 层", "No knob or Fn-layer remapping"), systemImage: "lock.shield")
            Label(language.text("只拦截你明确选择的键", "Only explicitly selected keys are intercepted"), systemImage: "cursorarrow.click")
        }
    }

    private var assignmentStep: some View {
        HStack(alignment: .top, spacing: 20) {
            ScrollView {
                VStack(alignment: .leading, spacing: 7) {
                    Text(language.text("选择要设置的动作", "Choose an action"))
                        .font(.headline)
                    ForEach(Array(store.activeKeyBindings.enumerated()), id: \.offset) { index, binding in
                        Button {
                            selectedBinding = index
                        } label: {
                            HStack {
                                Text(localizedBridgeAction(binding.action, language))
                                Spacer()
                                Text(binding.displayName).monospaced()
                            }
                            .padding(8)
                            .background(index == selectedBinding ? Color.accentColor.opacity(0.18) : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 7))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(width: 230)

            VStack(alignment: .leading, spacing: 12) {
                Text(language.text(
                    "现在点击键盘上的一颗键",
                    "Now click a key on the keyboard"
                ))
                .font(.headline)
                Air75KeyboardLayoutView(
                    bindings: store.activeKeyBindings,
                    learningBindingIndex: selectedBinding,
                    hardwareProfileInstalled: false,
                    colorsBySignalLightIndex: store.visibleKeyColorHexBySignalIndex,
                    actionTitle: { localizedBridgeAction($0, language) },
                    assign: { index, usage in
                        store.assignBinding(index, usage: usage)
                        selectedBinding = min(index + 1, store.activeKeyBindings.count - 1)
                    }
                )
            }
        }
    }

    private var previewStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(language.text("实时状态教程", "Live status tutorial"))
                .font(.title2.bold())
            Text(language.text(
                "选一个动作和状态。屏幕上的键会立即变色；如果 USB-C 或 U1 灯光通道可用，实体键会同步显示两秒。",
                "Choose an action and a state. Its on-screen key changes immediately; when USB-C or U1 lighting is available, the physical key mirrors it for two seconds."
            ))
            .foregroundStyle(.secondary)

            Picker(language.text("动作", "Action"), selection: $selectedBinding) {
                ForEach(Array(store.activeKeyBindings.enumerated()), id: \.offset) { index, binding in
                    Text(localizedBridgeAction(binding.action, language)).tag(index)
                }
            }
            .frame(width: 320)

            HStack(spacing: 10) {
                ForEach(states, id: \.rawValue) { state in
                    Button {
                        store.previewTaskLight(state, bindingIndex: selectedBinding)
                    } label: {
                        VStack(spacing: 7) {
                            Circle()
                                .fill(Color(hex: store.taskLightColorHex(for: state)))
                                .frame(width: 20, height: 20)
                            Text(state.displayName)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Air75KeyboardLayoutView(
                bindings: store.activeKeyBindings,
                learningBindingIndex: nil,
                hardwareProfileInstalled: false,
                colorsBySignalLightIndex: store.visibleKeyColorHexBySignalIndex,
                actionTitle: { localizedBridgeAction($0, language) },
                assign: { _, _ in }
            )

            Text(store.lightingMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
