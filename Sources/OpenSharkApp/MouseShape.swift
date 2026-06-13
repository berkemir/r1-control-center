import SwiftUI

/// Silhueta estilizada (top-down) do R1: frente estreita e arredondada, palma larga.
/// Preenche quase todo o rect (canvas), pra os botões assentarem dentro do corpo.
struct MouseShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let topInset = w * 0.20          // frente mais estreita
        let frontY = rect.minY + h * 0.11
        let waistY = rect.minY + h * 0.46 // ponto mais largo (palma)

        p.move(to: CGPoint(x: rect.minX + topInset, y: frontY))
        // topo (frente) arredondado
        p.addQuadCurve(to: CGPoint(x: rect.maxX - topInset, y: frontY),
                       control: CGPoint(x: rect.midX, y: rect.minY))
        // lado direito descendo até a cintura
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: waistY),
                       control: CGPoint(x: rect.maxX + w * 0.02, y: rect.minY + h * 0.24))
        // direito → base arredondada
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                       control: CGPoint(x: rect.maxX, y: rect.maxY - h * 0.02))
        // base → lado esquerdo
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: waistY),
                       control: CGPoint(x: rect.minX, y: rect.maxY - h * 0.02))
        // esquerdo subindo até a frente
        p.addQuadCurve(to: CGPoint(x: rect.minX + topInset, y: frontY),
                       control: CGPoint(x: rect.minX - w * 0.02, y: rect.minY + h * 0.24))
        p.closeSubpath()
        return p
    }
}
