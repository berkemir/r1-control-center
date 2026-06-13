import Foundation

/// Power management + timing settings — sent via feature report 0x05 (15 bytes).
/// Protocol reverse-engineered from xb-bx/attack-shark-r1-driver set_times().
public struct MouseSettings: Equatable, Codable {
    /// Minutes before the mouse enters sleep. Range: 0.5–30, step 0.5.
    public var sleepTime: Double
    /// Minutes before sleep deepens further. Range: 1–60, step 1.
    public var deepSleepTime: Int
    /// Click debounce/response time in ms. Range: 4–50, must be even.
    public var keyResponseTime: Int

    public static let `default` = MouseSettings(sleepTime: 2, deepSleepTime: 1, keyResponseTime: 4)

    public init(sleepTime: Double, deepSleepTime: Int, keyResponseTime: Int) {
        self.sleepTime    = sleepTime
        self.deepSleepTime  = deepSleepTime
        self.keyResponseTime = keyResponseTime
    }

    // MARK: - Report builder (15 bytes, report ID 0x05)

    public func buildReport() -> [UInt8] {
        var p: [UInt8] = [
            0x05, 0x0f, 0x01, 0x00, 0x03, 0x18, 0x00, 0x00,
            0xff, 0x04, 0x02, 0x01, 0x20, 0x00, 0x00
        ]

        let ds = UInt8(deepSleepTime)
        p[4] = 0x03 | (ds & 0xF0)
        p[5] = 0x08 | ((ds & 0x0F) << 4)

        let sleepByte    = UInt8(Int(sleepTime * 2))
        let keyRespByte  = UInt8(keyResponseTime / 2)
        p[9]  = sleepByte
        p[10] = keyRespByte

        // Checksum: (lowNibble(ds) + highNibble(ds)) << 4 + 0x0a + sleepByte + keyRespByte
        let lowN  = ds & 0x0F
        let highN = (ds & 0xF0) >> 4
        p[12] = ((lowN &+ highN) << 4) &+ 0x0a &+ sleepByte &+ keyRespByte

        return p
    }
}

public struct MouseSettingsStore {
    private static var url: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("r1ctl")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("settings.json")
    }

    public static func load() -> MouseSettings {
        guard let data = try? Data(contentsOf: url),
              let s = try? JSONDecoder().decode(MouseSettings.self, from: data) else {
            return .default
        }
        return s
    }

    public static func save(_ s: MouseSettings) throws {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        try enc.encode(s).write(to: url, options: .atomic)
    }
}
