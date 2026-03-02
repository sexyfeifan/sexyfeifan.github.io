import SwiftUI

struct PublishView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
}
