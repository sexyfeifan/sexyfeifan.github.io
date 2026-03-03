import Foundation

struct AppSettings {
    var openAIKey: String = ""
    var openAIBaseURL: String = "https://api.openai.com/v1"
    var openAIModel: String = "gpt-4.1-mini"
    var githubToken: String = ""
    var retryCount: Int = 2
    var downloadRootPath: String = ""
    var includeNoPackageProjects: Bool = true
}

struct SettingsStore {
    private enum Keys {
        static let openAIKey = "settings.openai.key"
        static let openAIBaseURL = "settings.openai.base_url"
        static let openAIModel = "settings.openai.model"
        static let githubToken = "settings.github.token"
        static let retryCount = "settings.retry_count"
        static let downloadRootPath = "settings.download.root_path"
        static let includeNoPackageProjects = "settings.include_no_package_projects"
    }

    private let ud = UserDefaults.standard

    func load() -> AppSettings {
        var s = AppSettings()
        s.openAIKey = ud.string(forKey: Keys.openAIKey) ?? ""
        s.openAIBaseURL = ud.string(forKey: Keys.openAIBaseURL) ?? s.openAIBaseURL
        s.openAIModel = ud.string(forKey: Keys.openAIModel) ?? s.openAIModel
        s.githubToken = ud.string(forKey: Keys.githubToken) ?? ""
        let retry = ud.integer(forKey: Keys.retryCount)
        s.retryCount = retry == 0 ? 2 : max(1, min(retry, 5))
        s.downloadRootPath = ud.string(forKey: Keys.downloadRootPath) ?? ""
        if ud.object(forKey: Keys.includeNoPackageProjects) == nil {
            s.includeNoPackageProjects = true
        } else {
            s.includeNoPackageProjects = ud.bool(forKey: Keys.includeNoPackageProjects)
        }
        return s
    }

    func save(_ settings: AppSettings) {
        ud.set(settings.openAIKey, forKey: Keys.openAIKey)
        ud.set(settings.openAIBaseURL, forKey: Keys.openAIBaseURL)
        ud.set(settings.openAIModel, forKey: Keys.openAIModel)
        ud.set(settings.githubToken, forKey: Keys.githubToken)
        ud.set(max(1, min(settings.retryCount, 5)), forKey: Keys.retryCount)
        ud.set(settings.downloadRootPath, forKey: Keys.downloadRootPath)
        ud.set(settings.includeNoPackageProjects, forKey: Keys.includeNoPackageProjects)
    }

    func loadFromFile(baseDir: URL) -> AppSettings? {
        let file = settingsFileURL(baseDir: baseDir)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        do {
            let data = try Data(contentsOf: file)
            let decoded = try JSONDecoder().decode(FileSettings.self, from: data)
            return decoded.toAppSettings(defaultDownloadPath: baseDir.path)
        } catch {
            return nil
        }
    }

    func saveToFile(_ settings: AppSettings, baseDir: URL) throws {
        try FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        let file = settingsFileURL(baseDir: baseDir)
        let payload = FileSettings(from: settings, normalizedDownloadPath: baseDir.path)
        let data = try JSONEncoder.pretty.encode(payload)
        try data.write(to: file, options: .atomic)
    }

    private func settingsFileURL(baseDir: URL) -> URL {
        baseDir.appendingPathComponent("collector_settings.json")
    }
}

private struct FileSettings: Codable {
    let openAIKey: String
    let openAIBaseURL: String
    let openAIModel: String
    let githubToken: String
    let retryCount: Int
    let downloadRootPath: String
    let includeNoPackageProjects: Bool

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        openAIKey = try c.decodeIfPresent(String.self, forKey: .openAIKey) ?? ""
        openAIBaseURL = try c.decodeIfPresent(String.self, forKey: .openAIBaseURL) ?? "https://api.openai.com/v1"
        openAIModel = try c.decodeIfPresent(String.self, forKey: .openAIModel) ?? "gpt-4.1-mini"
        githubToken = try c.decodeIfPresent(String.self, forKey: .githubToken) ?? ""
        retryCount = try c.decodeIfPresent(Int.self, forKey: .retryCount) ?? 2
        downloadRootPath = try c.decodeIfPresent(String.self, forKey: .downloadRootPath) ?? ""
        includeNoPackageProjects = try c.decodeIfPresent(Bool.self, forKey: .includeNoPackageProjects) ?? true
    }

    init(from settings: AppSettings, normalizedDownloadPath: String) {
        openAIKey = settings.openAIKey
        openAIBaseURL = settings.openAIBaseURL
        openAIModel = settings.openAIModel
        githubToken = settings.githubToken
        retryCount = max(1, min(settings.retryCount, 5))
        downloadRootPath = normalizedDownloadPath
        includeNoPackageProjects = settings.includeNoPackageProjects
    }

    func toAppSettings(defaultDownloadPath: String) -> AppSettings {
        var settings = AppSettings()
        settings.openAIKey = openAIKey
        settings.openAIBaseURL = openAIBaseURL.isEmpty ? settings.openAIBaseURL : openAIBaseURL
        settings.openAIModel = openAIModel.isEmpty ? settings.openAIModel : openAIModel
        settings.githubToken = githubToken
        settings.retryCount = max(1, min(retryCount, 5))
        settings.downloadRootPath = downloadRootPath.isEmpty ? defaultDownloadPath : downloadRootPath
        settings.includeNoPackageProjects = includeNoPackageProjects
        return settings
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
