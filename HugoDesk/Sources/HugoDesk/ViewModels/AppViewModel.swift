import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var project: BlogProject
    @Published var config: ThemeConfig = ThemeConfig()

    @Published var posts: [BlogPost] = []
    @Published var selectedPostID: String?
    @Published var editorPost: BlogPost
    @Published var editorMode: EditorMode = .markdown

    @Published var publishLog: String = ""
    @Published var publishMessage: String = "chore: 发布博客更新"
    @Published var isBusy: Bool = false
    @Published var statusText: String = ""

    private let configService = ConfigService()
    private let postService = PostService()
    private let publishService = PublishService()

    init() {
        let project = BlogProject.bootstrap()
        self.project = project
        self.editorPost = BlogPost.empty(in: project.contentURL)
        loadAll()
    }

    func loadAll() {
        do {
            config = try configService.loadConfig(for: project)
            posts = try postService.loadPosts(for: project)
            if let first = posts.first {
                selectedPostID = first.id
                editorPost = first
            } else {
                editorPost = BlogPost.empty(in: project.contentURL)
            }
            statusText = "项目已加载。"
        } catch {
            statusText = error.localizedDescription
        }
    }

    func loadSelectedPost() {
        guard let selectedPostID else { return }
        guard let file = posts.first(where: { $0.id == selectedPostID })?.fileURL else { return }
        do {
            editorPost = try postService.loadPost(at: file)
        } catch {
            statusText = error.localizedDescription
        }
    }

    func createNewPost() {
        editorPost = postService.createNewPost(title: "未命名文章", in: project)
        selectedPostID = nil
        statusText = "已创建新草稿。"
    }

    func saveCurrentPost() {
        do {
            try postService.savePost(editorPost)
            posts = try postService.loadPosts(for: project)
            selectedPostID = editorPost.id
            statusText = "文章已保存。"
        } catch {
            statusText = error.localizedDescription
        }
    }

    func saveThemeConfig() {
        do {
            try configService.saveConfig(config, for: project)
            statusText = "hugo.toml 已保存。"
        } catch {
            statusText = error.localizedDescription
        }
    }

    func runBuild() {
        runTask {
            let output = try self.publishService.runHugoBuild(project: self.project)
            self.publishLog = output.isEmpty ? "构建完成（无输出）。" : output
            self.statusText = "构建完成。"
        }
    }

    func runGitStatus() {
        runTask {
            let output = try self.publishService.gitStatus(project: self.project)
            self.publishLog = output
            self.statusText = "Git 状态已更新。"
        }
    }

    func runPublish() {
        runTask {
            let output = try self.publishService.commitAndPush(project: self.project, message: self.publishMessage)
            self.publishLog = output
            self.statusText = "推送完成。"
        }
    }

    private func runTask(_ action: @escaping () throws -> Void) {
        isBusy = true
        Task {
            defer { isBusy = false }
            do {
                try action()
            } catch {
                statusText = error.localizedDescription
            }
        }
    }
}

enum EditorMode: String, CaseIterable, Identifiable {
    case markdown = "Markdown"
    case richText = "富文本"

    var id: String { rawValue }
}
