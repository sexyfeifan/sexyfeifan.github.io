import SwiftUI

struct PublishView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ModernCard(title: "发布前检查", subtitle: "先检查再发布，减少失败率") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.preflightChecks()) { check in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: iconName(for: check.level))
                                    .foregroundStyle(color(for: check.level))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(check.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text(check.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                ModernCard(title: "GitHub Actions 状态", subtitle: "显示最新 workflow 运行结果") {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("仓库地址（https://github.com/owner/repo.git）", text: $viewModel.publishRemoteURL)
                            .textFieldStyle(.roundedBorder)
                        TextField("Workflow 名称（可留空）", text: $viewModel.workflowName)
                            .textFieldStyle(.roundedBorder)
                        SecureField("GitHub Token（可选，推荐）", text: $viewModel.githubToken)
                            .textFieldStyle(.roundedBorder)

                        HStack {
                            Button("保存查询配置") {
                                viewModel.saveRemoteProfile()
                            }
                            Button("查询最新状态") {
                                viewModel.refreshActionsStatus()
                            }
                            if let run = viewModel.latestWorkflowStatus {
                                Text(run.statusText)
                                    .font(.caption2)
                                    .foregroundStyle(statusColor(for: run).opacity(0.9))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(statusColor(for: run).opacity(0.16))
                                    .clipShape(Capsule())
                            }
                            Spacer()
                        }

                        if let run = viewModel.latestWorkflowStatus {
                            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 6) {
                                GridRow {
                                    Text("Workflow").foregroundStyle(.secondary)
                                    Text(run.name)
                                }
                                GridRow {
                                    Text("分支").foregroundStyle(.secondary)
                                    Text(run.branch)
                                }
                                GridRow {
                                    Text("提交").foregroundStyle(.secondary)
                                    Text(String(run.sha.prefix(10)))
                                        .font(.system(.body, design: .monospaced))
                                }
                                GridRow {
                                    Text("创建时间").foregroundStyle(.secondary)
                                    Text(run.createdAt)
                                }
                                GridRow {
                                    Text("更新时间").foregroundStyle(.secondary)
                                    Text(run.updatedAt)
                                }
                            }
                            if let note = run.note, !note.isEmpty {
                                Text(note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Link("打开运行详情", destination: URL(string: run.htmlURL)!)
                        } else if !viewModel.latestWorkflowError.isEmpty {
                            Text(viewModel.latestWorkflowError)
                                .foregroundStyle(.red)
                        } else {
                            Text("点击“查询最新状态”后显示结果。")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                ModernCard(title: "发布控制台", subtitle: "构建、检查、提交、推送") {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("提交信息", text: $viewModel.publishMessage)
                            .textFieldStyle(.roundedBorder)

                        HStack {
                            Button("保存配置") {
                                viewModel.saveThemeConfig()
                            }
                            Button("构建站点") {
                                viewModel.runBuild()
                            }
                            Button("查看 Git 状态") {
                                viewModel.runGitStatus()
                            }
                            Button("提交并推送") {
                                viewModel.runPublish()
                            }
                        }

                        Divider()

                        HStack {
                            Button("一键检测推送能力") {
                                viewModel.runEnvironmentDiagnostics()
                            }
                            Spacer()
                        }
                        Text("检测会验证 git/hugo 可用性、远程可达性与 dry-run 推送权限，并给出可执行命令建议。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                ModernCard(title: "命令输出") {
                    TextEditor(text: $viewModel.publishLog)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 420)
                        .padding(8)
                        .background(Color.black.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Text("应用会在当前项目目录执行本机的 git/hugo/brew 命令。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    private func statusColor(for run: WorkflowRunStatus) -> Color {
        if run.conclusion == "success" { return .green }
        if run.conclusion == "failure" || run.conclusion == "cancelled" { return .red }
        if run.status == "in_progress" || run.status == "queued" { return .orange }
        return .secondary
    }

    private func iconName(for level: PublishCheck.Level) -> String {
        switch level {
        case .ok: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }

    private func color(for level: PublishCheck.Level) -> Color {
        switch level {
        case .ok: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
}
