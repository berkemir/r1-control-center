import SwiftUI
import R1Kit

struct ContentView: View {
    @StateObject private var model = MouseModel()
    @EnvironmentObject private var lm: LanguageManager
    @State private var selectedTab: Tab = .buttons

    enum Tab { case buttons, dpi, settings }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(model: model, selectedTab: $selectedTab)
            Divider()
            HStack(spacing: 0) {
                if selectedTab == .buttons {
                    LeftPanel(model: model)
                    Divider()
                }
                Group {
                    switch selectedTab {
                    case .buttons:  InspectorView(model: model)
                    case .dpi:      DpiProfileView(model: model)
                    case .settings: SettingsView(model: model)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 760, height: 540)
        .onAppear { model.checkConnection() }
    }
}

// MARK: - Left panel

private struct LeftPanel: View {
    @ObservedObject var model: MouseModel
    @EnvironmentObject private var lm: LanguageManager

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            MouseView(model: model)
            Spacer()
            Button {
                model.restoreDefaults()
            } label: {
                Label(lm.s.restoreDefaults, systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 300)
        .frame(maxHeight: .infinity)
        .background(.regularMaterial)
    }
}

// MARK: - Top bar

private struct TopBar: View {
    @ObservedObject var model: MouseModel
    @Binding var selectedTab: ContentView.Tab
    @EnvironmentObject private var lm: LanguageManager

    @State private var showAddAlert    = false
    @State private var newProfileName  = ""
    @State private var showRenameAlert = false
    @State private var renameText      = ""

    var body: some View {
        HStack {
            profileMenu

            Spacer()

            Picker("", selection: $selectedTab) {
                Label(lm.s.buttonsTab,  systemImage: "computermouse").tag(ContentView.Tab.buttons)
                Label(lm.s.dpiTab,      systemImage: "gauge.with.dots.needle.67percent").tag(ContentView.Tab.dpi)
                Label(lm.s.settingsTab, systemImage: "slider.horizontal.3").tag(ContentView.Tab.settings)
            }
            .pickerStyle(.segmented)
            .frame(width: 300)

            Spacer()

            connectionStatus
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .alert(lm.s.newProfile, isPresented: $showAddAlert) {
            TextField(lm.s.profileNamePlaceholder, text: $newProfileName)
            Button(lm.s.create) {
                let name = newProfileName.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { model.addProfile(name: name) }
                newProfileName = ""
            }
            Button(lm.s.cancel, role: .cancel) { newProfileName = "" }
        } message: {
            Text(lm.s.newProfileMessage)
        }
        .alert(lm.s.renameProfile, isPresented: $showRenameAlert) {
            TextField(lm.s.newNamePlaceholder, text: $renameText)
            Button(lm.s.rename) {
                let name = renameText.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { model.renameProfile(id: model.activeProfileID, name: name) }
            }
            Button(lm.s.cancel, role: .cancel) {}
        }
    }

    private var profileMenu: some View {
        Menu {
            ForEach(model.profiles) { p in
                Button {
                    model.activateProfile(id: p.id)
                } label: {
                    if p.id == model.activeProfileID {
                        Label(p.name, systemImage: "checkmark")
                    } else {
                        Text(p.name)
                    }
                }
            }
            Divider()
            Button(lm.s.newProfileEllipsis) {
                newProfileName = ""
                showAddAlert = true
            }
            Button(lm.s.renameEllipsis) {
                renameText = model.activeProfile.name
                showRenameAlert = true
            }
            if model.profiles.count > 1 {
                Divider()
                Button(lm.s.deleteProfile(model.activeProfile.name), role: .destructive) {
                    model.deleteProfile(id: model.activeProfileID)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "computermouse.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                Text(model.activeProfile.name).font(.headline)
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private var connectionStatus: some View {
        HStack(spacing: 7) {
            if model.isApplying {
                ProgressView()
                    .scaleEffect(0.55)
                    .frame(width: 9, height: 9)
                Text(lm.s.syncing)
                    .font(.callout).foregroundStyle(.secondary)
            } else {
                Circle()
                    .fill(model.connected ? Color.green : Color.red)
                    .frame(width: 9, height: 9)
                Text(model.connected ? lm.s.connected : lm.s.disconnected)
                    .font(.callout).foregroundStyle(.secondary)
                Button {
                    withAnimation { model.checkConnection() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.isApplying)
    }
}
