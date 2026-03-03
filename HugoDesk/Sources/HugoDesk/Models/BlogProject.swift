import Foundation

struct BlogProject: Codable {
    var rootPath: String
    var hugoExecutable: String
    var contentSubpath: String
    var gitRemote: String
    var publishBranch: String

    static func bootstrap() -> BlogProject {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let direct = cwd.appendingPathComponent("hugo.toml")
        let parent = cwd.deletingLastPathComponent()
        let parentHugo = parent.appendingPathComponent("hugo.toml")

        if FileManager.default.fileExists(atPath: direct.path) {
            return BlogProject(rootPath: cwd.path, hugoExecutable: "hugo", contentSubpath: "content/post", gitRemote: "origin", publishBranch: "main")
        }

        if FileManager.default.fileExists(atPath: parentHugo.path) {
            return BlogProject(rootPath: parent.path, hugoExecutable: "hugo", contentSubpath: "content/post", gitRemote: "origin", publishBranch: "main")
        }

        return BlogProject(rootPath: cwd.path, hugoExecutable: "hugo", contentSubpath: "content/post", gitRemote: "origin", publishBranch: "main")
    }

    var rootURL: URL {
        URL(fileURLWithPath: rootPath, isDirectory: true)
    }

    var contentURL: URL {
        rootURL.appendingPathComponent(contentSubpath, isDirectory: true)
    }

    var configURL: URL {
        rootURL.appendingPathComponent("hugo.toml")
    }

    var staticImagesURL: URL {
        rootURL.appendingPathComponent("static/images", isDirectory: true)
    }

    var localConfigBundleURL: URL {
        rootURL.appendingPathComponent(".hugodesk.local.json", isDirectory: false)
    }
}
