import Foundation

struct ThemeConfig: Codable {
    var baseURL: String = "https://example.com/"
    var languageCode: String = "zh-cn"
    var title: String = "My Hugo Blog"
    var theme: String = "github-style"
    var pygmentsCodeFences: Bool = true
    var pygmentsUseClasses: Bool = true
    var params: ThemeParams = ThemeParams()
    var frontmatterTrackLastmod: Bool = true
    var googleAnalyticsID: String = ""
    var outputsHome: [String] = ["html", "json"]
    var outputFormatJSONMediaType: String = "application/json"
    var outputFormatJSONBaseName: String = "index"
    var outputFormatJSONIsPlainText: Bool = false
}

struct ThemeParams: Codable {
    var author: String = ""
    var description: String = ""
    var tagline: String = ""
    var github: String = ""
    var twitter: String = ""
    var facebook: String = ""
    var linkedin: String = ""
    var instagram: String = ""
    var tumblr: String = ""
    var stackoverflow: String = ""
    var bluesky: String = ""
    var email: String = ""
    var url: String = ""
    var keywords: String = ""
    var favicon: String = "/images/github-mark.png"
    var avatar: String = "/images/avatar.png"
    var headerIcon: String = "/images/github-mark-white.png"
    var location: String = ""
    var userStatusEmoji: String = ""

    var rss: Bool = true
    var lastmod: Bool = true
    var enableGitalk: Bool = false
    var enableSearch: Bool = true
    var math: Bool = false
    var mathJax: Bool = false

    var customCSS: [String] = []
    var customJS: [String] = []

    var gitalk: GitalkSettings = GitalkSettings()
    var links: [ThemeLink] = []
}

struct GitalkSettings: Codable {
    var clientID: String = ""
    var clientSecret: String = ""
    var repo: String = ""
    var owner: String = ""
    var admin: String = ""
    var id: String = "location.pathname"
    var labels: String = "gitalk"
    var perPage: Int = 15
    var pagerDirection: String = "last"
    var createIssueManually: Bool = true
    var distractionFreeMode: Bool = false
    var proxy: String = ""
}

struct ThemeLink: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String = ""
    var href: String = ""
    var icon: String = ""
}
