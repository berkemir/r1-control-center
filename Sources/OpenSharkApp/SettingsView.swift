import SwiftUI
import R1Kit

struct SettingsView: View {
    @ObservedObject var model: MouseModel
    @EnvironmentObject private var lm: LanguageManager

    @State private var settings: MouseSettings = .default
    @State private var rippleControl: Bool = false
    @State private var angleSnap: Bool = false
    @State private var localPollingRate: PollingRate = .hz1000

    private var isDirty: Bool {
        settings != model.mouseSettings ||
        rippleControl != model.dpiProfile.rippleControl ||
        angleSnap != model.dpiProfile.angleSnap ||
        localPollingRate != model.pollingRate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if model.connected {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        pollingSection
                        Divider()
                        sensorSection
                        Divider()
                        powerSection
                        Divider()
                        languageSection
                        Divider()
                        Text("R1 Control Center")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(20)
                }
                Rectangle()
                    .fill(.white.opacity(0.12))
                    .frame(height: 1)
                applyBar
            } else {
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { syncFromModel() }
        .onChange(of: model.activeProfileID) { _ in syncFromModel() }
    }

    // MARK: - Polling rate

    private var pollingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(lm.s.pollingRate, icon: "waveform.path")
            Picker("", selection: $localPollingRate) {
                ForEach(PollingRate.allCases, id: \.self) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            Text(lm.s.pollingRateDesc).font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: - Sensor

    private var sensorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(lm.s.sensor, icon: "dot.scope")
            toggle(title: lm.s.rippleControl, subtitle: lm.s.rippleControlDesc, isOn: $rippleControl)
            toggle(title: lm.s.angleSnap,     subtitle: lm.s.angleSnapDesc,     isOn: $angleSnap)
        }
    }

    // MARK: - Power

    private var powerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel(lm.s.powerManagement, icon: "bolt.fill")

            sliderRow(
                title: lm.s.keyResponseTime,
                value: Binding(get: { Double(settings.keyResponseTime) },
                               set: { settings.keyResponseTime = roundedEven($0) }),
                in: 4...50,
                label: "\(settings.keyResponseTime) ms",
                hint: lm.s.keyResponseTimeDesc
            )
            sliderRow(
                title: lm.s.sleepAfter,
                value: Binding(get: { settings.sleepTime },
                               set: { settings.sleepTime = roundedHalf($0) }),
                in: 0.5...30,
                label: minuteLabel(settings.sleepTime),
                hint: lm.s.sleepAfterDesc
            )
            sliderRow(
                title: lm.s.deepSleepAfter,
                value: Binding(get: { Double(settings.deepSleepTime) },
                               set: { settings.deepSleepTime = Int($0.rounded()) }),
                in: 1...60,
                label: "\(settings.deepSleepTime) min",
                hint: lm.s.deepSleepAfterDesc
            )
        }
    }

    // MARK: - Language

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(lm.s.language, icon: "globe")
            Picker("", selection: Binding(
                get: { lm.language },
                set: { lm.set($0) }
            )) {
                ForEach(Language.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Apply bar

    private var applyBar: some View {
        HStack {
            if !model.status.isEmpty {
                Text(model.status).font(.caption).foregroundStyle(.secondary)
            } else if isDirty {
                Text(lm.s.unsaved).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            SwiftUI.Button(lm.s.discard) { withAnimation { syncFromModel() } }
                .buttonStyle(.bordered).disabled(!isDirty || model.isApplying)
            SwiftUI.Button(lm.s.apply) {
                model.applyPollingRate(localPollingRate)
                model.applyMouseSettings(settings)
                model.applyDpiFlags(rippleControl: rippleControl, angleSnap: angleSnap)
            }
            .buttonStyle(.borderedProminent).disabled(!isDirty || model.isApplying)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Helpers

    private func syncFromModel() {
        settings = model.mouseSettings
        rippleControl = model.dpiProfile.rippleControl
        angleSnap = model.dpiProfile.angleSnap
        localPollingRate = model.pollingRate
    }

    private func roundedEven(_ v: Double) -> Int {
        let n = Int(v.rounded())
        return max(4, min(50, n % 2 == 0 ? n : n + 1))
    }

    private func roundedHalf(_ v: Double) -> Double {
        Double(max(1, min(60, Int((v * 2).rounded())))) / 2.0
    }

    private func minuteLabel(_ v: Double) -> String {
        v == v.rounded() ? "\(Int(v)) min" : String(format: "%.1f min", v)
    }

    @ViewBuilder
    private func sectionLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon).font(.subheadline.bold()).foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func toggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn).labelsHidden()
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func sliderRow(title: String, value: Binding<Double>, in range: ClosedRange<Double>,
                           label: String, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.callout)
                Spacer()
                Text(label).font(.callout.monospacedDigit()).foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
            Text(hint).font(.caption).foregroundStyle(.secondary)
        }
    }
}
