import Foundation

struct AIProfile: Codable {
    var baseURL: String
    var model: String

    static let `default` = AIProfile(
        baseURL: "https://api.openai.com/v1",
        model: "gpt-4.1-mini"
    )
}
