import Foundation

struct ConfigBackupBundle: Codable {
    var schemaVersion: Int = 1
    var exportedAt: Date
    var project: BlogProject
    var themeConfig: ThemeConfig
    var remoteProfile: RemoteProfile
    var githubToken: String
    var aiProfile: AIProfile
    var aiAPIKey: String

    init(
        schemaVersion: Int = 1,
        exportedAt: Date,
        project: BlogProject,
        themeConfig: ThemeConfig,
        remoteProfile: RemoteProfile,
        githubToken: String,
        aiProfile: AIProfile,
        aiAPIKey: String
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.project = project
        self.themeConfig = themeConfig
        self.remoteProfile = remoteProfile
        self.githubToken = githubToken
        self.aiProfile = aiProfile
        self.aiAPIKey = aiAPIKey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        exportedAt = try container.decode(Date.self, forKey: .exportedAt)
        project = try container.decode(BlogProject.self, forKey: .project)
        themeConfig = try container.decode(ThemeConfig.self, forKey: .themeConfig)
        remoteProfile = try container.decode(RemoteProfile.self, forKey: .remoteProfile)
        githubToken = try container.decodeIfPresent(String.self, forKey: .githubToken) ?? ""
        aiProfile = try container.decodeIfPresent(AIProfile.self, forKey: .aiProfile) ?? .default
        aiAPIKey = try container.decodeIfPresent(String.self, forKey: .aiAPIKey) ?? ""
    }
}
