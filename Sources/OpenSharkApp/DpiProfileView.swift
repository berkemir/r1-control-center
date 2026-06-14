import SwiftUI
import R1Kit

struct DpiProfileView: View {
    @ObservedObject var model: MouseModel
    @EnvironmentObject private var lm: LanguageManager

    @State private var levels: [Int] = []
    @State private var localActiveIndex: Int = 0

    private var isDirty: Bool {
        levels != model.dpiProfile.levels
    }

    private let slotColors: [Color] = [
        .red,
        .green,
        Color(red: 0.28, green: 0.42, blue: 0.78),
        .yellow,
        Color(red: 0.15, green: 0.85, blue: 0.90),
        Color(red: 0.75, green: 0.55, blue: 1.00),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if model.connected {
                slots
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
        .onChange(of: model.dpiProfile.activeIndex) { localActiveIndex = model.dpiProfile.activeIndex }
        .onChange(of: model.activeProfileID) { _ in syncFromModel() }
    }

    private var slots: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(0..<DpiProfile.slotCount, id: \.self) { i in
                    if i < levels.count { slotRow(i) }
                }
            }
            .padding(20)
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
            SwiftUI.Button(lm.s.discard) { withAnimation { syncFromModel() } }
                .buttonStyle(.bordered).disabled(!isDirty || model.isApplying)
            SwiftUI.Button(lm.s.apply) {
                model.applyDpiAll(levels: levels, activeIndex: localActiveIndex)
            }
            .buttonStyle(.borderedProminent).disabled(!isDirty || model.isApplying)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private func slotRow(_ i: Int) -> some View {
        let isActive = localActiveIndex == i
        return HStack(spacing: 10) {
            Circle()
                .fill(isActive ? slotColors[i] : Color.gray.opacity(0.25))
                .frame(width: 9, height: 9)

            Text(lm.s.slotLabel(i + 1))
                .font(.callout.bold())
                .frame(width: 68, alignment: .leading)

            Slider(
                value: Binding(get: { Double(levels[i]) }, set: { levels[i] = rounded($0) }),
                in: Double(DpiProfile.minDpi)...Double(DpiProfile.maxDpi)
            )

            TextField("", value: Binding(get: { levels[i] }, set: { levels[i] = clamped($0) }),
                      formatter: dpiFormatter)
                .frame(width: 54)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)

            Text("DPI").font(.caption).foregroundStyle(.secondary).frame(width: 24, alignment: .leading)

            SwiftUI.Button {
                localActiveIndex = i
                model.applyDpiActiveIndex(i)
            } label: {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isActive ? slotColors[i] : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .help(isActive ? lm.s.activeSlot : lm.s.setAsActive)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isActive ? slotColors[i].opacity(0.12) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isActive ? slotColors[i].opacity(0.50) : Color.white.opacity(0.14),
                            lineWidth: 1.5
                        )
                )
        )
    }

    private func syncFromModel() {
        levels = model.dpiProfile.levels
        localActiveIndex = model.dpiProfile.activeIndex
    }

    private func rounded(_ value: Double) -> Int {
        let v = Int(value)
        return max(DpiProfile.minDpi, min(DpiProfile.maxDpi, (v / 100) * 100))
    }

    private func clamped(_ value: Int) -> Int {
        max(DpiProfile.minDpi, min(DpiProfile.maxDpi, (value / 100) * 100))
    }

    private var dpiFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimum = NSNumber(value: DpiProfile.minDpi)
        f.maximum = NSNumber(value: DpiProfile.maxDpi)
        f.usesGroupingSeparator = false
        return f
    }
}
