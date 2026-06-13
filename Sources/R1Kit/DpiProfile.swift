import Foundation

/// DPI profile: 6 levels + active slot (0-based) + sensor flags.
public struct DpiProfile: Equatable, Codable {
    public static let slotCount = 6
    public static let minDpi = 100
    public static let maxDpi = 10000
    public static let step = 100

    public var levels: [Int]          // length == slotCount
    public var activeIndex: Int       // 0-based
    public var rippleControl: Bool    // report[4]: smooths sensor jitter
    public var angleSnap: Bool        // report[3]: straightens diagonal movement

    public static let `default` = DpiProfile(
        levels: [400, 800, 1600, 3200, 6400, 10000],
        activeIndex: 1,
        rippleControl: false,
        angleSnap: false
    )

    public init(levels: [Int], activeIndex: Int, rippleControl: Bool = false, angleSnap: Bool = false) {
        self.levels = levels
        self.activeIndex = max(0, min(DpiProfile.slotCount - 1, activeIndex))
        self.rippleControl = rippleControl
        self.angleSnap = angleSnap
    }

    // Lookup table: DPI value (100-10000, step 100) → firmware byte.
    // Verified against xb-bx/attack-shark-r1-driver dpi.odin.
    static let encodingTable: [Int: UInt8] = [
        100: 0x02, 200: 0x04, 300: 0x06, 400: 0x09, 500: 0x0b, 600: 0x0e,
        700: 0x10, 800: 0x12, 900: 0x15, 1000: 0x17, 1100: 0x19, 1200: 0x1c,
        1300: 0x1e, 1400: 0x20, 1500: 0x23, 1600: 0x25, 1700: 0x27, 1800: 0x2a,
        1900: 0x2c, 2000: 0x2f, 2100: 0x31, 2200: 0x33, 2300: 0x36, 2400: 0x38,
        2500: 0x3a, 2600: 0x3d, 2700: 0x3f, 2800: 0x41, 2900: 0x44, 3000: 0x46,
        3100: 0x48, 3200: 0x4b, 3300: 0x4d, 3400: 0x4f, 3500: 0x52, 3600: 0x54,
        3700: 0x57, 3800: 0x59, 3900: 0x5b, 4000: 0x5e, 4100: 0x60, 4200: 0x62,
        4300: 0x65, 4400: 0x67, 4500: 0x69, 4600: 0x6c, 4700: 0x6e, 4800: 0x70,
        4900: 0x73, 5000: 0x75, 5100: 0x77, 5200: 0x7a, 5300: 0x7c, 5400: 0x7f,
        5500: 0x81, 5600: 0x83, 5700: 0x86, 5800: 0x88, 5900: 0x8a, 6000: 0x8d,
        6100: 0x8f, 6200: 0x91, 6300: 0x94, 6400: 0x96, 6500: 0x98, 6600: 0x9b,
        6700: 0x9d, 6800: 0x9f, 6900: 0xa2, 7000: 0xa4, 7100: 0xa7, 7200: 0xa9,
        7300: 0xab, 7400: 0xae, 7500: 0xb0, 7600: 0xb2, 7700: 0xb5, 7800: 0xb7,
        7900: 0xb9, 8000: 0xbc, 8100: 0xbe, 8200: 0xc0, 8300: 0xc3, 8400: 0xc5,
        8500: 0xc7, 8600: 0xca, 8700: 0xcc, 8800: 0xcf, 8900: 0xd1, 9000: 0xd3,
        9100: 0xd6, 9200: 0xd8, 9300: 0xda, 9400: 0xdd, 9500: 0xdf, 9600: 0xe1,
        9700: 0xe4, 9800: 0xe6, 9900: 0xe8, 10000: 0xeb,
    ]

    public static func encode(_ dpi: Int) -> UInt8 {
        encodingTable[dpi] ?? 0x12  // fallback: 800 DPI
    }

    public static let validValues: [Int] = Array(stride(from: minDpi, through: maxDpi, by: step))
}

public enum DpiStore {
    static var url: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("r1ctl", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("dpi.json")
    }

    public static func load() -> DpiProfile {
        guard let data = try? Data(contentsOf: url),
              let p = try? JSONDecoder().decode(DpiProfile.self, from: data) else {
            return .default
        }
        return p
    }

    public static func save(_ p: DpiProfile) throws {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        try enc.encode(p).write(to: url)
    }
}
