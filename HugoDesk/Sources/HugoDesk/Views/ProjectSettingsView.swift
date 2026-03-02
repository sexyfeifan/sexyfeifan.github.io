import AppKit
import SwiftUI

struct ProjectSettingsView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ModernCard(title: "项目路径", subtitle: "本地目录与命令工具") {
                    VStack(spacing: 10) {
                        SettingRow(
                            key: "project.rootPath",
                            title: "博客根目录",
                            helpText: "Hugo 项目的根目录，包含 hugo.toml、content、themes 等文件夹。",
                            scope: "项目级"
                        ) {
                            HStack {
                                TextField("例如：/Users/you/Hugo", text: $viewModel.project.rootPath)
                                    .textFieldStyle(.roundedBorder)
                                Button("选择") {
                                    if let path = pickDirectory() {
                                        viewModel.project.rootPath = path
                                        viewModel.loadAll()
                                    }
                                }
                            }
                        }

                        SettingRow(
                            key: "project.hugoExecutable",
                            title: "Hugo 可执行命令",
                            helpText: "默认使用 hugo，可填写绝对路径以锁定版本。",
                            scope: "构建流程"
                        ) {
                            TextField("hugo", text: $viewModel.project.hugoExecutable)
                                .textFieldStyle(.roundedBorder)
                        }

                        SettingRow(
                            key: "project.contentSubpath",
                            title: "文章目录",
                            helpText: "文章保存目录，默认 content/post。",
                            scope: "内容管理"
                        ) {
                            TextField("content/post", text: $viewModel.project.contentSubpath)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }

                ModernCard(title: "Git 发布目标", subtitle: "推送到远端仓库的配置") {
                    VStack(spacing: 10) {
                        SettingRow(
                            key: "project.gitRemote",
                            title: "远程名称",
                            helpText: "通常为 origin，也可切换为其他 remote。",
                            scope: "发布流程"
                        ) {
                            TextField("origin", text: $viewModel.project.gitRemote)
                                .textFieldStyle(.roundedBorder)
                        }

                        SettingRow(
                            key: "project.publishBranch",
                            title: "发布分支",
                            helpText: "默认 main。点击“提交并推送”时会推送到该分支。",
                            scope: "发布流程"
                        ) {
                            TextField("main", text: $viewModel.project.publishBranch)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }

                ModernCard(title: "远程地址与凭据", subtitle: "自动读取并保存（不写入博客目录）") {
                    VStack(spacing: 10) {
                        SettingRow(
                            key: "profile.remoteURL",
                            title: "推送仓库地址",
                            helpText: "例如 https://github.com/you/you.github.io.git。用于推送与 Actions 查询。",
                            scope: "发布流程"
                        ) {
                            TextField("https://github.com/you/repo.git", text: $viewModel.publishRemoteURL)
                                .textFieldStyle(.roundedBorder)
                        }

                        SettingRow(
                            key: "profile.workflowName",
                            title: "Workflow 名称",
                            helpText: "用于匹配要显示状态的 GitHub Actions workflow。",
                            scope: "状态查询"
                        ) {
                            TextField("Deploy Hugo site to Pages", text: $viewModel.workflowName)
                                .textFieldStyle(.roundedBorder)
                        }

                        SettingRow(
                            key: "keychain.githubToken",
                            title: "GitHub Token",
                            helpText: "仅保存在系统钥匙串；不会写入项目目录，也不会被 git 推送。",
                            scope: "状态查询"
                        ) {
                            SecureField("ghp_xxx", text: $viewModel.githubToken)
                                .textFieldStyle(.roundedBorder)
                        }

                        HStack {
                            Button("保存远程与令牌") {
                                viewModel.saveRemoteProfile()
                            }
                            Text("配置文件保存在 ~/Library/Application Support/HugoDesk/profiles，令牌保存在 Keychain。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                ModernCard(title: "快捷操作") {
                    HStack {
                        Button("重新加载项目") {
                            viewModel.loadAll()
                        }
                        Button("保存主题配置") {
                            viewModel.saveThemeConfig()
                        }
                        Button("构建站点") {
                            viewModel.runBuild()
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func pickDirectory() -> String? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "选择"
        return panel.runModal() == .OK ? panel.url?.path : nil
    }
}
