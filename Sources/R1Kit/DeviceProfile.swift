import Foundation

/// A named snapshot of all mouse settings. Switching profiles applies every
/// sub-setting to the hardware in one shot.
public struct DeviceProfile: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var buttons: Profile
    public var dpi: DpiProfile
    public var pollingRate: PollingRate
    public var settings: MouseSettings

    public init(
        id: UUID = UUID(),
        name: String,
        buttons: Profile = .default,
        dpi: DpiProfile = .default,
        pollingRate: PollingRate = .hz1000,
        settings: MouseSettings = .default
    ) {
        self.id = id
        self.name = name
        self.buttons = buttons
        self.dpi = dpi
        self.pollingRate = pollingRate
        self.settings = settings
    }

    public static let `default` = DeviceProfile(name: "Default")
}

// MARK: - Persistence

private struct ProfileDocument: Codable {
    var profiles: [DeviceProfile]
    var activeID: UUID
}

public struct DeviceProfileStore {
    private static var url: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("r1ctl")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("device_profiles.json")
    }

    public static func load() -> (profiles: [DeviceProfile], activeID: UUID) {
        if let data = try? Data(contentsOf: url),
           let doc = try? JSONDecoder().decode(ProfileDocument.self, from: data),
           !doc.profiles.isEmpty {
            let validID = doc.profiles.contains(where: { $0.id == doc.activeID })
                ? doc.activeID : doc.profiles[0].id
            return (doc.profiles, validID)
        }
        let def = DeviceProfile.default
        return ([def], def.id)
    }

    public static func save(profiles: [DeviceProfile], activeID: UUID) throws {
        let doc = ProfileDocument(profiles: profiles, activeID: activeID)
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        try enc.encode(doc).write(to: url, options: .atomic)
    }
}
