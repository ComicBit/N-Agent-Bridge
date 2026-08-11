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
                    Button(language.text("继续", "Continue")) {
                        step += 1
                        if step == 1 { store.beginLearningBinding(selectedBinding) }
                        else { store.cancelLearningBinding() }
                    }
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
        .onAppear {
            store.wizardHardwarePreviewEnabled = false
        }
        .onChange(of: store.learningBindingIndex) { next in
            if let next { selectedBinding = next }
        }
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
                        HStack {
                            Button {
                                selectedBinding = index
                                store.beginLearningBinding(index)
                            } label: {
                                HStack {
                                    Text(localizedBridgeAction(binding.action, language))
                                    Spacer()
                                    Text(binding.displayName).monospaced()
                                }
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                            if binding.isSupportedInputSource {
                                Button(role: .destructive) { store.removeBinding(index) } label: {
                                    Image(systemName: "xmark.circle")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(8)
                        .background(index == selectedBinding ? Color.accentColor.opacity(0.18) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 7))
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
                    }
                )
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var previewStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(language.text("实时状态教程", "Live status tutorial"))
                .font(.title2.bold())
            Text(language.text(
                "选一个动作和状态，屏幕上的键会立即变色。实体单键状态需要键盘的指示灯模式，会保留其他键的颜色，但会暂停原有动画。",
                "Choose an action and state to update the on-screen key immediately. Physical per-key status requires Signal Indicator mode: other keys keep their saved colors, but their previous animation pauses while status lighting is active."
            ))
            .foregroundStyle(.secondary)

            Label(language.text("屏幕预览不会修改键盘的原有灯效", "On-screen preview leaves the keyboard's normal lighting untouched"), systemImage: "checkmark.shield")
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
                            Text(stateTitle(state))
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
            .frame(maxWidth: .infinity, alignment: .center)

            Text(store.lightingBusy
                 ? language.text("正在同步预览…", "Synchronizing preview…")
                 : (store.lightingAvailable
                    ? language.text("键盘灯光通道已就绪", "Keyboard lighting is ready")
                    : language.text("屏幕预览可用；键盘灯光将在自动检测后同步", "On-screen preview is available; hardware lighting will mirror after automatic detection")))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func stateTitle(_ state: CodexTaskLightState) -> String {
        switch state {
        case .idle: return language.text("空闲", "Idle")
        case .reasoning: return language.text("正在思考", "Working")
        case .waitingForConfirmation: return language.text("需要确认", "Needs confirmation")
        case .complete: return language.text("任务完成", "Complete")
        case .error: return language.text("报错", "Error")
        }
    }
}
