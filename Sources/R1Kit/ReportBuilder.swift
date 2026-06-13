import Foundation

/// Monta o feature report 0x08 (mapa de botões) a partir de um perfil. Funções puras, testáveis sem hardware.
public enum ReportBuilder {
    public static let reportID: UInt8 = 0x08
    public static let length = 59          // 0x3b
    public static let subcommand: UInt8 = 0x01

    /// Soma 16-bit dos bytes [0x03..0x38] (validado no hardware).
    public static func checksum(_ p: [UInt8]) -> Int {
        var s = 0
        for i in 3...0x38 { s += Int(p[i]) }
        return s & 0xffff
    }

    /// Constrói os 59 bytes do report 0x08, já com checksum em [0x39]=high, [0x3a]=low.
    public static func buildButtonReport(_ profile: Profile) -> [UInt8] {
        var p = [UInt8](repeating: 0, count: length)
        p[0] = reportID
        p[1] = 0x3b
        p[2] = subcommand
        for button in Button.allCases {
            let a = profile.action(for: button)
            let o = 3 + button.slot * 3
            p[o] = a.b0; p[o + 1] = a.b1; p[o + 2] = a.b2
        }
        let sum = checksum(p)
        p[0x39] = UInt8((sum >> 8) & 0xff)
        p[0x3a] = UInt8(sum & 0xff)
        return p
    }
}
