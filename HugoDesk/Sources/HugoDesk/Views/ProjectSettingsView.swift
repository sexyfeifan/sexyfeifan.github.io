import AppKit
import SwiftUI
import UniformTypeIdentifiers

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

                ModernCard(title: "远程地址与凭据", subtitle: "自动读取并保存（同步到项目配置包）") {
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
                            helpText: "写入项目配置包并同步到系统钥匙串；项目配置包默认加入 .gitignore。",
                            scope: "状态查询"
                        ) {
                            SecureField("ghp_xxx", text: $viewModel.githubToken)
                                .textFieldStyle(.roundedBorder)
                        }

                        HStack {
                            Button("保存远程与令牌") {
                                viewModel.saveRemoteProfile()
                            }
                            Text("配置会同步到项目根目录 .hugodesk.local.json，并写入系统 Keychain 作为兼容备份。")
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
                        Button("保存项目配置包") {
                            viewModel.exportConfigBundleToProject()
                        }
                        Button("保存主题配置") {
                            viewModel.saveThemeConfig()
                        }
                        Button("构建站点") {
                            viewModel.runBuild()
                        }
                    }
                }

                ModernCard(title: "项目配置包", subtitle: "固定保存在博客根目录，自动加载，不会被 Git 上传") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(viewModel.localConfigBundlePath)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                        HStack {
                            Button("一键导出到项目目录") {
                                viewModel.exportConfigBundleToProject()
                            }
                            Button("一键从项目目录还原") {
                                viewModel.importConfigBundleFromProject()
                            }
                            Spacer()
                        }
                        HStack {
                            Button("另存为外部备份文件") {
                                if let target = pickBackupSaveURL() {
                                    viewModel.exportConfigBundle(to: target)
                                }
                            }
                            Button("从外部备份文件还原") {
                                if let source = pickBackupFileURL() {
                                    viewModel.importConfigBundle(from: source)
                                }
                            }
                            Spacer()
                        }
                        Text("配置包包含项目设置、主题配置、远程信息、GitHub Token、AI API 信息。切换博客目录时会自动尝试读取该文件。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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

    private func pickBackupSaveURL() -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "hugodesk-config-backup.json"
        panel.prompt = "导出"
        panel.canCreateDirectories = true
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func pickBackupFileURL() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.json]
        panel.prompt = "导入"
        return panel.runModal() == .OK ? panel.url : nil
    }
}
