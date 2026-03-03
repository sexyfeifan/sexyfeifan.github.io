import Foundation

struct RepoIdentity: Hashable {
    let owner: String
    let name: String

    var fullName: String { "\(owner)/\(name)" }
}

struct GitHubRepo: Decodable {
    let name: String
    let fullName: String
    let description: String?
    let language: String?
    let stargazersCount: Int
    let htmlURL: URL
    let topics: [String]?

    enum CodingKeys: String, CodingKey {
        case name
        case fullName = "full_name"
        case description
        case language
        case stargazersCount = "stargazers_count"
        case htmlURL = "html_url"
        case topics
    }
}

struct GitHubRelease: Decodable {
    let tagName: String
    let name: String?
    let body: String?
    let publishedAt: String?
    let draft: Bool?
    let prerelease: Bool?
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case publishedAt = "published_at"
        case draft
        case prerelease
        case assets
    }
}

struct GitHubAsset: Decodable {
    let name: String
    let browserDownloadURL: URL
    let size: Int

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
        case size
    }
}

struct RepoRecord: Codable, Identifiable {
    let id: String
    let owner: String
    let repo: String
    var projectName: String
    var sourceURL: String

    var descriptionEN: String
    var descriptionZH: String
    var summaryZH: String
    var setupGuideZH: String

    var releaseNotesEN: String
    var releaseNotesZH: String

    var category: String
    var language: String
    var stars: Int

    var releaseTag: String
    var releaseAssetName: String
    var releaseAssetURL: String

    var hasDownloadAsset: Bool
    var localPath: String
    var sourceCodePath: String
    var previewImagePath: String
    var storageRootPath: String
    var infoFilePath: String

    var updatedAt: Date

    var fullName: String { "\(owner)/\(repo)" }

    init(
        id: String,
        owner: String,
        repo: String,
        projectName: String,
        sourceURL: String,
        descriptionEN: String,
        descriptionZH: String,
        summaryZH: String,
        setupGuideZH: String,
        releaseNotesEN: String,
        releaseNotesZH: String,
        category: String,
        language: String,
        stars: Int,
        releaseTag: String,
        releaseAssetName: String,
        releaseAssetURL: String,
        hasDownloadAsset: Bool,
        localPath: String,
        sourceCodePath: String,
        previewImagePath: String,
        storageRootPath: String,
        infoFilePath: String,
        updatedAt: Date
    ) {
        self.id = id
        self.owner = owner
        self.repo = repo
        self.projectName = projectName
        self.sourceURL = sourceURL
        self.descriptionEN = descriptionEN
        self.descriptionZH = descriptionZH
        self.summaryZH = summaryZH
        self.setupGuideZH = setupGuideZH
        self.releaseNotesEN = releaseNotesEN
        self.releaseNotesZH = releaseNotesZH
        self.category = category
        self.language = language
        self.stars = stars
        self.releaseTag = releaseTag
        self.releaseAssetName = releaseAssetName
        self.releaseAssetURL = releaseAssetURL
        self.hasDownloadAsset = hasDownloadAsset
        self.localPath = localPath
        self.sourceCodePath = sourceCodePath
        self.previewImagePath = previewImagePath
        self.storageRootPath = storageRootPath
        self.infoFilePath = infoFilePath
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, owner, repo, projectName, sourceURL
        case descriptionEN, descriptionZH, summaryZH, setupGuideZH
        case releaseNotesEN, releaseNotesZH
        case category, language, stars
        case releaseTag, releaseAssetName, releaseAssetURL
        case hasDownloadAsset, localPath, sourceCodePath, previewImagePath, storageRootPath, infoFilePath
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(String.self, forKey: .id)
        owner = try c.decode(String.self, forKey: .owner)
        repo = try c.decode(String.self, forKey: .repo)
        projectName = try c.decode(String.self, forKey: .projectName)
        sourceURL = try c.decode(String.self, forKey: .sourceURL)

        descriptionEN = try c.decodeIfPresent(String.self, forKey: .descriptionEN) ?? ""
        descriptionZH = try c.decodeIfPresent(String.self, forKey: .descriptionZH) ?? ""
        summaryZH = try c.decodeIfPresent(String.self, forKey: .summaryZH) ?? ""
        setupGuideZH = try c.decodeIfPresent(String.self, forKey: .setupGuideZH) ?? ""

        releaseNotesEN = try c.decodeIfPresent(String.self, forKey: .releaseNotesEN) ?? ""
        releaseNotesZH = try c.decodeIfPresent(String.self, forKey: .releaseNotesZH) ?? ""

        category = try c.decodeIfPresent(String.self, forKey: .category) ?? "未分类"
        language = try c.decodeIfPresent(String.self, forKey: .language) ?? "Unknown"
        stars = try c.decodeIfPresent(Int.self, forKey: .stars) ?? 0

        releaseTag = try c.decodeIfPresent(String.self, forKey: .releaseTag) ?? "N/A"
        releaseAssetName = try c.decodeIfPresent(String.self, forKey: .releaseAssetName) ?? "无安装包"
        releaseAssetURL = try c.decodeIfPresent(String.self, forKey: .releaseAssetURL) ?? ""

        localPath = try c.decodeIfPresent(String.self, forKey: .localPath) ?? ""
        sourceCodePath = try c.decodeIfPresent(String.self, forKey: .sourceCodePath) ?? ""
        hasDownloadAsset = try c.decodeIfPresent(Bool.self, forKey: .hasDownloadAsset) ?? !localPath.isEmpty
        previewImagePath = try c.decodeIfPresent(String.self, forKey: .previewImagePath) ?? ""
        storageRootPath = try c.decodeIfPresent(String.self, forKey: .storageRootPath) ?? ""
        infoFilePath = try c.decodeIfPresent(String.self, forKey: .infoFilePath) ?? ""

        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }
}

struct RepoDraft {
    let identity: RepoIdentity
    let projectName: String
    let sourceURL: URL

    let descriptionEN: String
    let descriptionZH: String
    let summaryZH: String
    let setupGuideZH: String

    let releaseNotesEN: String
    let releaseNotesZH: String

    let category: String
    let language: String
    let stars: Int

    let releaseTag: String
    let releaseAssetName: String
    let releaseAssetURL: String

    let hasDownloadAsset: Bool
    let localPath: String
    let sourceCodePath: String
    let previewImagePath: String
}
