import SwiftUI
import R1Kit

struct InspectorView: View {
    @ObservedObject var model: MouseModel
    @EnvironmentObject private var lm: LanguageManager

    @State private var localProfile: Profile = .default
    @State private var keyText: String = ""
    @State private var keyError: String?
    @FocusState private var keyFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var button: R1Kit.Button { model.selectedButton }
    private var current: Action { localProfile.action(for: button) }
    private var isDirty: Bool { localProfile != model.profile }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if model.connected {
                picker
                Rectangle()
                    .fill(.white.opacity(0.12))
                    .frame(height: 1)
                applyBar
            } else {
                notDetected
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { localProfile = model.profile }
        .onChange(of: model.activeProfileID) { _ in localProfile = model.profile }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(button.shortDisplayName).font(.title3.bold())
            HStack(spacing: 6) {
                Image(systemName: "arrow.right.circle.fill").foregroundStyle(.tint)
                Text(current.label).foregroundStyle(.secondary)
            }
            .font(.callout)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.12))
                .frame(height: 1)
        }
    }

    private var picker: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(Action.presetGroups) { group in groupSection(group) }
                keyboardSection
            }
            .padding(20)
            .id(button)
            .transition(.opacity)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: button)
    }

    private func groupSection(_ group: ActionGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(group.name.uppercased()).font(.caption.bold()).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 8)], spacing: 8) {
                ForEach(group.actions, id: \.label) { actionChip($0) }
            }
        }
    }

    private func actionChip(_ action: Action) -> some View {
        let selected = current == action
        return SwiftUI.Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.75)) {
                localProfile = localProfile.setting(button, to: action)
            }
        } label: {
            Text(action.label)
                .font(.callout)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(selected ? Color.accentColor : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(
                                    selected ? Color.accentColor.opacity(0.6) : Color.white.opacity(0.18),
                                    lineWidth: 1
                                )
                        )
                )
                .foregroundStyle(selected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private var keyboardSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(lm.s.keyShortcut).font(.caption.bold()).foregroundStyle(.secondary)
            HStack {
                TextField(lm.s.keyShortcutHint, text: $keyText)
                    .textFieldStyle(.roundedBorder)
                    .focused($keyFocused)
                    .onSubmit(applyKey)
                SwiftUI.Button(lm.s.setShortcut, action: applyKey).disabled(keyText.isEmpty)
            }
            if let keyError {
                Text(keyError).font(.caption).foregroundStyle(.red).transition(.opacity)
            }
        }
    }

    private var applyBar: some View {
        HStack {
            if !model.status.isEmpty {
                Text(model.status).font(.caption).foregroundStyle(.secondary)
            } else if isDirty {
                Text(lm.s.unsaved).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            SwiftUI.Button(lm.s.discard) {
                withAnimation { localProfile = model.profile }
                keyText = ""; keyError = nil
            }
            .buttonStyle(.bordered).disabled(!isDirty || model.isApplying)

            SwiftUI.Button(lm.s.apply) { model.applyButtonProfile(localProfile) }
                .buttonStyle(.borderedProminent).disabled(!isDirty || model.isApplying)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var notDetected: some View {
        ContentUnavailableView {
            Label(lm.s.mouseNotDetected, systemImage: "computermouse")
        } description: {
            Text(lm.s.mouseNotDetectedDesc)
        } actions: {
            SwiftUI.Button(lm.s.reconnect) { withAnimation { model.checkConnection() } }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxHeight: .infinity)
    }

    private func applyKey() {
        let raw = keyText.hasPrefix("key:") ? keyText : "key:\(keyText)"
        if let action = ActionParser.parse(raw) {
            withAnimation { localProfile = localProfile.setting(button, to: action) }
            keyText = ""; keyError = nil
        } else {
            withAnimation { keyError = lm.s.invalidShortcut }
            keyFocused = true
        }
    }
}
