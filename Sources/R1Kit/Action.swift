import Foundation

/// Máscara de modificadores de teclado (byte HID padrão).
public struct KeyModifiers: OptionSet, Codable, Equatable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let control = KeyModifiers(rawValue: 0x01)
    public static let shift   = KeyModifiers(rawValue: 0x02)
    public static let option  = KeyModifiers(rawValue: 0x04) // Alt
    public static let command = KeyModifiers(rawValue: 0x08) // Win/GUI/Cmd
}

/// Ação atribuível a um botão. Codifica os 3 bytes (b0,b1,b2) do slot no report 0x08.
/// Bytes confirmados por engenharia-reversa + teste no hardware (ver VALIDATED-ON-DEVICE.md).
public struct Action: Equatable, Codable {
    public let b0: UInt8
    public let b1: UInt8
    public let b2: UInt8
    public let label: String

    public init(b0: UInt8, b1: UInt8, b2: UInt8, label: String) {
        self.b0 = b0; self.b1 = b1; self.b2 = b2; self.label = label
    }

    public var bytes: [UInt8] { [b0, b1, b2] }

    // Funções de mouse / sistema (b0 único, b1=b2=0)
    public static let disabled    = Action(b0: 0x01, b1: 0, b2: 0, label: "disabled")
    public static let leftClick   = Action(b0: 0x02, b1: 0, b2: 0, label: "left-click")
    public static let rightClick  = Action(b0: 0x03, b1: 0, b2: 0, label: "right-click")
    public static let middleClick = Action(b0: 0x04, b1: 0, b2: 0, label: "middle-click")
    public static let backward    = Action(b0: 0x05, b1: 0, b2: 0, label: "back")
    public static let forward     = Action(b0: 0x06, b1: 0, b2: 0, label: "forward")
    public static let doubleClick = Action(b0: 0x07, b1: 0, b2: 0, label: "double-click")
    public static let fire        = Action(b0: 0x08, b1: 0, b2: 0, label: "fire")
    public static let scrollUp    = Action(b0: 0x09, b1: 0, b2: 0, label: "scroll-up")
    public static let scrollDown  = Action(b0: 0x0A, b1: 0, b2: 0, label: "scroll-down")
    public static let tiltLeft    = Action(b0: 0x0B, b1: 0, b2: 0, label: "tilt-left")
    public static let tiltRight   = Action(b0: 0x0C, b1: 0, b2: 0, label: "tilt-right")
    public static let dpiCycle    = Action(b0: 0x0D, b1: 0, b2: 0, label: "dpi-cycle")
    public static let dpiUp       = Action(b0: 0x0E, b1: 0, b2: 0, label: "dpi-up")
    public static let dpiDown     = Action(b0: 0x0F, b1: 0, b2: 0, label: "dpi-down")
    // Mídia (b0 único)
    public static let mediaPrev   = Action(b0: 0x16, b1: 0, b2: 0, label: "media-prev")
    public static let mediaNext   = Action(b0: 0x17, b1: 0, b2: 0, label: "media-next")
    public static let mediaPlay   = Action(b0: 0x18, b1: 0, b2: 0, label: "media-playpause")
    public static let mediaStop   = Action(b0: 0x19, b1: 0, b2: 0, label: "media-stop")
    public static let mute        = Action(b0: 0x1A, b1: 0, b2: 0, label: "mute")
    public static let volumeUp    = Action(b0: 0x1B, b1: 0, b2: 0, label: "volume-up")
    // Page navigation: on macOS the firmware's browser codes (0x20/0x21) don't work;
    // Cmd+←/→ keyboard shortcuts do (Safari, Chrome, Finder).
    public static let pageBack    = Action.key([.command], 0x50, label: "page-back")    // Cmd+←
    public static let pageForward = Action.key([.command], 0x4F, label: "page-forward") // Cmd+→
    public static let volumeDown  = Action(b0: 0x1C, b1: 0, b2: 0, label: "volume-down")

    /// Tecla/atalho de teclado: b0=0x11, b1=modificadores, b2=HID usage.
    public static func key(_ modifiers: KeyModifiers, _ usage: UInt8, label: String) -> Action {
        Action(b0: 0x11, b1: modifiers.rawValue, b2: usage, label: label)
    }
}
