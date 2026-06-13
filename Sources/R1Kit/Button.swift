import Foundation

/// Os 6 botões físicos do R1. O `slot` é o índice no report 0x08, confirmado no hardware.
public enum Button: String, CaseIterable, Codable {
    case left
    case right
    case middle
    case dpi
    case forward   // lateral dianteiro
    case back      // lateral traseiro

    /// Índice do slot dentro do report 0x08 (validado escrevendo no mouse real).
    public var slot: Int {
        switch self {
        case .left:    return 0
        case .right:   return 1
        case .middle:  return 2
        case .dpi:     return 3
        case .forward: return 6
        case .back:    return 7
        }
    }

    /// Ação de fábrica de cada botão.
    public var defaultAction: Action {
        switch self {
        case .left:    return .leftClick
        case .right:   return .rightClick
        case .middle:  return .middleClick
        case .dpi:     return .dpiCycle
        case .forward: return .forward
        case .back:    return .backward
        }
    }
}
