import Foundation

public enum PollingRate: UInt16, CaseIterable, Codable {
    case hz125  = 0xF708
    case hz250  = 0xFB04
    case hz500  = 0xFD02
    case hz1000 = 0xFE01

    public var hz: Int {
        switch self {
        case .hz125:  return 125
        case .hz250:  return 250
        case .hz500:  return 500
        case .hz1000: return 1000
        }
    }

    public var label: String { "\(hz) Hz" }

    public func buildReport() -> [UInt8] {
        var payload: [UInt8] = [0x06, 0x09, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00]
        payload[3] = UInt8(rawValue & 0xFF)
        payload[4] = UInt8((rawValue >> 8) & 0xFF)
        return payload
    }
}

public struct PollingRateStore {
    private static var url: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("r1ctl")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("polling_rate.json")
    }

    public static func load() -> PollingRate {
        guard let data = try? Data(contentsOf: url),
              let rate = try? JSONDecoder().decode(PollingRate.self, from: data) else {
            return .hz1000
        }
        return rate
    }

    public static func save(_ rate: PollingRate) throws {
        let data = try JSONEncoder().encode(rate)
        try data.write(to: url, options: .atomic)
    }
}
