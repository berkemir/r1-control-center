import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Gera o ícone mestre 1024×1024 (squircle azul + barbatana de tubarão branca).
let S = 1024
let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: S, height: S, bitsPerComponent: 8,
                          bytesPerRow: 0, space: cs,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    fatalError("ctx")
}
let rect = CGRect(x: 0, y: 0, width: S, height: S)

// fundo squircle com gradiente (azul profundo no topo → ciano embaixo)
let bg = CGPath(roundedRect: rect, cornerWidth: 230, cornerHeight: 230, transform: nil)
ctx.saveGState()
ctx.addPath(bg); ctx.clip()
let grad = CGGradient(colorsSpace: cs,
                      colors: [CGColor(red: 0.28, green: 0.05, blue: 0.62, alpha: 1),
                               CGColor(red: 0.72, green: 0.42, blue: 1.00, alpha: 1)] as CFArray,
                      locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: S), end: CGPoint(x: 0, y: 0), options: [])

// barbatana (branca) — y-up: base embaixo, ponta em cima
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
let fin = CGMutablePath()
fin.move(to: CGPoint(x: 318, y: 322))                                       // base esquerda
fin.addQuadCurve(to: CGPoint(x: 648, y: 792), control: CGPoint(x: 388, y: 690)) // leading edge convexo → ponta varrida
fin.addQuadCurve(to: CGPoint(x: 730, y: 322), control: CGPoint(x: 612, y: 512)) // trailing edge côncavo (varrido)
fin.closeSubpath()
ctx.addPath(fin); ctx.fillPath()

// "água" — duas barras brancas arredondadas sob a barbatana
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.92))
for (y, w) in [(250.0, 470.0), (188.0, 360.0)] {
    let bar = CGPath(roundedRect: CGRect(x: (Double(S) - w) / 2, y: y, width: w, height: 34),
                     cornerWidth: 17, cornerHeight: 17, transform: nil)
    ctx.addPath(bar); ctx.fillPath()
}
ctx.restoreGState()

guard let img = ctx.makeImage() else { fatalError("img") }
let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon-1024.png")
guard let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("dest")
}
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("✓ \(out.path)")
