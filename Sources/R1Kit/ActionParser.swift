import Foundation

/// Converte strings da CLI em `Action`. Ex: "left-click", "back", "media-next", "key:ctrl+c", "key:f13".
public enum ActionParser {
    /// Ações nomeadas (sem teclado).
    public static let named: [String: Action] = [
        "disabled": .disabled, "off": .disabled,
        "left-click": .leftClick, "left": .leftClick,
        "right-click": .rightClick, "right": .rightClick,
        "middle-click": .middleClick, "middle": .middleClick, "wheel": .middleClick,
        "back": .backward, "backward": .backward,
        "forward": .forward,
        "page-back": .pageBack, "page-forward": .pageForward,
        "double-click": .doubleClick, "double": .doubleClick,
        "fire": .fire,
        "scroll-up": .scrollUp, "scroll-down": .scrollDown,
        "tilt-left": .tiltLeft, "tilt-right": .tiltRight,
        "dpi-cycle": .dpiCycle, "dpi": .dpiCycle, "dpi-up": .dpiUp, "dpi-down": .dpiDown,
        "media-prev": .mediaPrev, "media-next": .mediaNext,
        "media-playpause": .mediaPlay, "play": .mediaPlay, "media-stop": .mediaStop,
        "mute": .mute, "volume-up": .volumeUp, "volup": .volumeUp,
        "volume-down": .volumeDown, "voldown": .volumeDown,
    ]

    /// HID usage de teclas comuns.
    static func usage(for key: String) -> UInt8? {
        let k = key.lowercased()
        if k.count == 1, let c = k.unicodeScalars.first {
            if c.value >= 97 && c.value <= 122 { return UInt8(0x04 + (c.value - 97)) }   // a-z
            if c.value >= 49 && c.value <= 57  { return UInt8(0x1E + (c.value - 49)) }   // 1-9
            if c.value == 48 { return 0x27 }                                             // 0
        }
        if k.hasPrefix("f"), let n = Int(k.dropFirst()) {
            if (1...12).contains(n) { return UInt8(0x3A + n - 1) }
            if (13...24).contains(n) { return UInt8(0x68 + n - 13) }
        }
        let special: [String: UInt8] = [
            "enter": 0x28, "return": 0x28, "esc": 0x29, "escape": 0x29,
            "backspace": 0x2A, "tab": 0x2B, "space": 0x2C,
            "minus": 0x2D, "equal": 0x2E, "delete": 0x4C, "del": 0x4C, "insert": 0x49,
            "home": 0x4A, "end": 0x4D, "pageup": 0x4B, "pagedown": 0x4E,
            "right": 0x4F, "left": 0x50, "down": 0x51, "up": 0x52,
        ]
        return special[k]
    }

    static func modifier(for token: String) -> KeyModifiers? {
        switch token.lowercased() {
        case "ctrl", "control": return .control
        case "shift": return .shift
        case "alt", "option", "opt": return .option
        case "cmd", "command", "win", "gui", "super": return .command
        default: return nil
        }
    }

    /// Parseia a string completa em uma Action, ou nil se inválida.
    public static func parse(_ raw: String) -> Action? {
        let s = raw.trimmingCharacters(in: .whitespaces)
        if let a = named[s.lowercased()] { return a }
        if s.lowercased().hasPrefix("key:") {
            let combo = String(s.dropFirst(4))
            let parts = combo.split(separator: "+").map { String($0) }
            guard let last = parts.last else { return nil }
            var mods: KeyModifiers = []
            for p in parts.dropLast() {
                guard let m = modifier(for: p) else { return nil }
                mods.insert(m)
            }
            guard let usage = usage(for: last) else { return nil }
            return .key(mods, usage, label: "key:\(combo.lowercased())")
        }
        return nil
    }
}
