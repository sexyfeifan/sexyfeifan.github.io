import Foundation

enum URLParserError: Error, LocalizedError {
    case unsupportedHost
    case invalidPath

    var errorDescription: String? {
        switch self {
        case .unsupportedHost:
            return "仅支持 github.com 链接。"
        case .invalidPath:
            return "无法从该链接识别 owner/repo。"
        }
    }
}

enum URLParser {
    static func parseGitHubStarsUser(from raw: String) -> String? {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: cleaned), let host = url.host?.lowercased() else { return nil }
        guard host == "github.com" || host == "www.github.com" else { return nil }

        let parts = url.path.split(separator: "/").map(String.init)
        guard parts.count == 1 else { return nil }
        let username = parts[0]
        guard !username.isEmpty else { return nil }

        let isStars = url.query?.lowercased().contains("tab=stars") == true
        return isStars ? username : nil
    }

    static func parseGitHubRepo(from raw: String) throws -> RepoIdentity {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: cleaned), let host = url.host?.lowercased() else {
            throw URLParserError.invalidPath
        }

        guard host == "github.com" || host == "www.github.com" else {
            throw URLParserError.unsupportedHost
        }

        let parts = url.path.split(separator: "/").map(String.init)
        guard parts.count >= 2 else {
            throw URLParserError.invalidPath
        }

        let owner = parts[0]
        let repo = parts[1].replacingOccurrences(of: ".git", with: "")

        guard !owner.isEmpty, !repo.isEmpty else {
            throw URLParserError.invalidPath
        }

        return RepoIdentity(owner: owner, name: repo)
    }
}
