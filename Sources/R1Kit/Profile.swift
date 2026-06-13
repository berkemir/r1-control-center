import Foundation

/// Mapeamento botão→ação. Imutável: mutações retornam novo perfil.
/// O device é write-only (GetReport ecoa a última escrita), então este perfil é a fonte de verdade.
public struct Profile: Codable, Equatable {
    public private(set) var actions: [String: Action]   // chave = Button.rawValue

    public init(actions: [String: Action]) { self.actions = actions }

    public static var `default`: Profile {
        Profile(actions: Dictionary(uniqueKeysWithValues: Button.allCases.map { ($0.rawValue, $0.defaultAction) }))
    }

    public func action(for button: Button) -> Action {
        actions[button.rawValue] ?? button.defaultAction
    }

    /// Retorna um NOVO perfil com a ação do botão alterada (imutabilidade).
    public func setting(_ button: Button, to action: Action) -> Profile {
        var copy = actions
        copy[button.rawValue] = action
        return Profile(actions: copy)
    }
}

/// Persistência do perfil em disco (~/Library/Application Support/r1ctl/profile.json).
public enum ProfileStore {
    public static var url: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("r1ctl", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("profile.json")
    }

    public static func load() -> Profile {
        guard let data = try? Data(contentsOf: url),
              let profile = try? JSONDecoder().decode(Profile.self, from: data) else {
            return .default
        }
        return profile
    }

    public static func save(_ profile: Profile) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(profile).write(to: url)
    }
}
