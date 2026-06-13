import Foundation

/// Grupos de ações prontas para popular menus de UI.
public struct ActionGroup: Identifiable {
    public let name: String
    public let actions: [Action]
    public var id: String { name }
}

public extension Action {
    static let presetGroups: [ActionGroup] = [
        ActionGroup(name: "Mouse", actions: [
            .leftClick, .rightClick, .middleClick, .backward, .forward,
            .doubleClick, .scrollUp, .scrollDown, .disabled,
        ]),
        ActionGroup(name: "Navigation", actions: [.pageBack, .pageForward]),
        ActionGroup(name: "DPI", actions: [.dpiCycle, .dpiUp, .dpiDown]),
        ActionGroup(name: "Media", actions: [
            .mediaPlay, .mediaNext, .mediaPrev, .mediaStop, .mute, .volumeUp, .volumeDown,
        ]),
    ]
}

public extension Button {
    var displayName: String {
        switch self {
        case .left:    return "Left"
        case .right:   return "Right"
        case .middle:  return "Middle (scroll)"
        case .dpi:     return "DPI Button"
        case .forward: return "Side Forward"
        case .back:    return "Side Back"
        }
    }

    var shortDisplayName: String {
        switch self {
        case .middle:  return "Scroll"
        case .forward: return "Side ▶"
        case .back:    return "Side ◀"
        default:       return displayName
        }
    }
}
