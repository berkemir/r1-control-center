import SwiftUI
import AppKit
import R1Kit

/// Define onde cada botão fica na silhueta do mouse (coords no canvas 220×360).
private struct Zone {
    let button: R1Kit.Button
    let rect: CGRect
    let corner: CGFloat
    let number: Int
}

/// Mouse vetorial fiel ao R1, com zonas clicáveis que acendem (estilo Logi Options+).
struct MouseView: View {
    @ObservedObject var model: MouseModel
    @State private var hovered: R1Kit.Button?
    @FocusState private var focused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let canvas = CGSize(width: 220, height: 360)

    // numeração igual ao mouse real: 1 esq, 2 dir, 3 roda, 4 lateral sup, 5 lateral inf, 6 DPI
    private var zones: [Zone] {
        [
            Zone(button: .left,    rect: CGRect(x: 30,  y: 32,  width: 72, height: 120), corner: 28, number: 1),
            Zone(button: .right,   rect: CGRect(x: 118, y: 32,  width: 72, height: 120), corner: 28, number: 2),
            Zone(button: .middle,  rect: CGRect(x: 100, y: 30,  width: 20, height: 68),  corner: 10, number: 3),
            Zone(button: .forward, rect: CGRect(x: 6,   y: 150, width: 20, height: 36),  corner: 8,  number: 4),
            Zone(button: .back,    rect: CGRect(x: 6,   y: 192, width: 20, height: 36),  corner: 8,  number: 5),
            Zone(button: .dpi,     rect: CGRect(x: 96,  y: 108, width: 28, height: 26),  corner: 9,  number: 6),
        ]
    }

    private var spring: Animation? { reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.7) }

    var body: some View {
        ZStack {
            // corpo
            MouseShape()
                .fill(LinearGradient(colors: [Color.white.opacity(0.10), Color.white.opacity(0.03)],
                                     startPoint: .top, endPoint: .bottom))
                .background(MouseShape().fill(.regularMaterial))
                .overlay(MouseShape().stroke(.white.opacity(0.14), lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 18, y: 8)

            // linha separadora sob os botões superiores
            Capsule()
                .fill(.white.opacity(0.10))
                .frame(width: 150, height: 1.5)
                .position(x: 110, y: 156)

            ForEach(zones, id: \.button) { zone in
                zoneView(zone)
            }
        }
        .frame(width: canvas.width, height: canvas.height)
        .padding(.vertical, 8)
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onKeyPress(.leftArrow)  { cycle(-1); return .handled }
        .onKeyPress(.upArrow)    { cycle(-1); return .handled }
        .onKeyPress(.rightArrow) { cycle(1);  return .handled }
        .onKeyPress(.downArrow)  { cycle(1);  return .handled }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Mouse buttons — use arrow keys to navigate")
    }

    private func cycle(_ direction: Int) {
        let all = R1Kit.Button.allCases
        guard let i = all.firstIndex(of: model.selectedButton) else { return }
        let next = (i + direction + all.count) % all.count
        withAnimation(spring) { model.selectedButton = all[next] }
    }

    @ViewBuilder
    private func zoneView(_ zone: Zone) -> some View {
        let isSelected = model.selectedButton == zone.button
        let isHover = hovered == zone.button
        let action = model.profile.action(for: zone.button)
        let fillColor: Color = isSelected ? Color.accentColor.opacity(0.92)
                                          : isHover ? Color.accentColor.opacity(0.32)
                                          : Color.white.opacity(0.08)
        let strokeColor: Color = isSelected ? Color.accentColor : Color.white.opacity(0.22)
        let strokeWidth: CGFloat = isSelected ? 2 : 1
        let shape = RoundedRectangle(cornerRadius: zone.corner, style: .continuous)

        shape.fill(fillColor)
            .overlay(shape.strokeBorder(strokeColor, lineWidth: strokeWidth))
            .overlay(
                Text("\(zone.number)")
                    .font(.caption2.bold())
                    .foregroundStyle(isSelected ? .white : .secondary)
            )
            .frame(width: zone.rect.width, height: zone.rect.height)
            .contentShape(Rectangle())
            .position(x: zone.rect.midX, y: zone.rect.midY)
            .onHover { inside in
                if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) {
                    if inside { hovered = zone.button } else if hovered == zone.button { hovered = nil }
                }
            }
            .onTapGesture { withAnimation(spring) { model.selectedButton = zone.button } }
            .animation(spring, value: isSelected)
            .scaleEffect(isHover && !isSelected ? 1.05 : 1)
            .accessibilityElement()
            .accessibilityLabel(zone.button.displayName)
            .accessibilityValue(action.label)
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
            .accessibilityHint("Click to configure")
    }
}
