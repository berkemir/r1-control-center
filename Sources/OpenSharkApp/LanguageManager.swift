import Foundation

enum Language: String, CaseIterable, Codable, Identifiable {
    case english    = "en"
    case turkish    = "tr"
    case portuguese = "pt"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:    return "English"
        case .turkish:    return "Türkçe"
        case .portuguese: return "Português"
        }
    }

    static var system: Language {
        let code = Locale.preferredLanguages.first ?? "en"
        if code.hasPrefix("tr") { return .turkish }
        if code.hasPrefix("pt") { return .portuguese }
        return .english
    }
}

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published private(set) var language: Language
    var s: Strings { Strings(lang: language) }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: "r1cc.language"),
           let saved = Language(rawValue: raw) {
            language = saved
        } else {
            language = .system
        }
    }

    func set(_ lang: Language) {
        language = lang
        UserDefaults.standard.set(lang.rawValue, forKey: "r1cc.language")
    }
}
