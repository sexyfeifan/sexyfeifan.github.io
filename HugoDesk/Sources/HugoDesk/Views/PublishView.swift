import SwiftUI

struct PublishView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ModernCard(title: "GitHub Actions 状态", subtitle: "显示最新 workflow 运行结果") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
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
                                Text("Workflow")
                                    .foregroundStyle(.secondary)
                                Text(run.name)
                            }
                            GridRow {
                                Text("分支")
                                    .foregroundStyle(.secondary)
                                Text(run.branch)
                            }
                            GridRow {
                                Text("提交")
                                    .foregroundStyle(.secondary)
                                Text(String(run.sha.prefix(10)))
                                    .font(.system(.body, design: .monospaced))
                            }
                            GridRow {
                                Text("创建时间")
                                    .foregroundStyle(.secondary)
                                Text(run.createdAt)
                            }
                            GridRow {
                                Text("更新时间")
                                    .foregroundStyle(.secondary)
                                Text(run.updatedAt)
                            }
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
                        Button("构建站点（hugo --gc --minify）") {
                            viewModel.runBuild()
                        }
                        Button("查看 Git 状态") {
                            viewModel.runGitStatus()
                        }
                        Button("提交并推送") {
                            viewModel.runPublish()
                        }
                    }
                }
            }

            ModernCard(title: "命令输出") {
                TextEditor(text: $viewModel.publishLog)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 400)
                    .padding(8)
                    .background(Color.black.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Text("应用会在当前项目目录执行本机的 git/hugo 命令。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func statusColor(for run: WorkflowRunStatus) -> Color {
        if run.conclusion == "success" { return .green }
        if run.conclusion == "failure" || run.conclusion == "cancelled" { return .red }
        if run.status == "in_progress" || run.status == "queued" { return .orange }
        return .secondary
    }
}
