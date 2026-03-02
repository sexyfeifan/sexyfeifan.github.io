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
