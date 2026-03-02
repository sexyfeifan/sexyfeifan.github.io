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
    @Published var publishRemoteURL: String = ""
    @Published var githubToken: String = ""
    @Published var workflowName: String = "Deploy Hugo site to Pages"
    @Published var latestWorkflowStatus: WorkflowRunStatus?
    @Published var latestWorkflowError: String = ""
    @Published var isBusy: Bool = false
    @Published var statusText: String = ""

    private let configService = ConfigService()
    private let postService = PostService()
    private let publishService = PublishService()
    private let actionsService = GitHubActionsService()
    private let credentialStore = CredentialStore()

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
            loadRemoteProfile()
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

    func saveRemoteProfile() {
        do {
            let profile = RemoteProfile(
                remoteURL: publishRemoteURL.trimmingCharacters(in: .whitespacesAndNewlines),
                workflowName: workflowName.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            try credentialStore.saveRemoteProfile(profile, for: project.rootPath)
            credentialStore.saveToken(githubToken, for: project.rootPath)
            statusText = "远程与令牌设置已保存。"
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
            let output = try self.publishService.commitAndPush(
                project: self.project,
                message: self.publishMessage,
                remoteURL: self.publishRemoteURL
            )
            self.publishLog = output
            self.statusText = "推送完成。"
        }
    }

    func refreshActionsStatus() {
        runAsyncTask {
            self.latestWorkflowError = ""
            self.latestWorkflowStatus = nil
            let run = try await self.actionsService.fetchLatestRun(
                remoteURL: self.publishRemoteURL,
                token: self.githubToken,
                workflowName: self.workflowName
            )
            self.latestWorkflowStatus = run
            self.statusText = "已获取最新 Actions 状态。"
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

    private func runAsyncTask(_ action: @escaping () async throws -> Void) {
        isBusy = true
        Task {
            defer { isBusy = false }
            do {
                try await action()
            } catch {
                latestWorkflowError = error.localizedDescription
                statusText = error.localizedDescription
            }
        }
    }

    private func loadRemoteProfile() {
        if let profile = credentialStore.loadRemoteProfile(for: project.rootPath) {
            publishRemoteURL = profile.remoteURL
            workflowName = profile.workflowName.isEmpty ? "Deploy Hugo site to Pages" : profile.workflowName
        } else {
            publishRemoteURL = publishService.detectRemoteURL(project: project)
            workflowName = "Deploy Hugo site to Pages"
        }
        githubToken = credentialStore.loadToken(for: project.rootPath)
    }
}

enum EditorMode: String, CaseIterable, Identifiable {
    case markdown = "Markdown"
    case richText = "富文本"

    var id: String { rawValue }
}
