import Foundation

struct PublishCheck: Identifiable {
    enum Level {
        case ok
        case warning
        case error
    }

    let id = UUID()
    let title: String
    let detail: String
    let level: Level
}
