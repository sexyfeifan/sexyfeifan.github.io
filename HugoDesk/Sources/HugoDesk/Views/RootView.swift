import SwiftUI

struct RootView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color.accentColor.opacity(0.10),
                    Color.cyan.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HugoDesk")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text(viewModel.project.rootPath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button("重新加载") {
                        viewModel.loadAll()
                    }
                    Button("保存配置") {
                        viewModel.saveThemeConfig()
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 4)

                TabView {
                    ProjectSettingsView(viewModel: viewModel)
                        .tabItem {
                            Label("项目", systemImage: "folder")
                        }

                    EditorView(viewModel: viewModel)
                        .tabItem {
                            Label("写作", systemImage: "square.and.pencil")
                        }

                    ThemeSettingsView(viewModel: viewModel)
                        .tabItem {
                            Label("主题设置", systemImage: "slider.horizontal.3")
                        }

                    PublishView(viewModel: viewModel)
                        .tabItem {
                            Label("发布", systemImage: "icloud.and.arrow.up")
                        }
                }
                .padding(10)

                Divider()
                HStack {
                    Text(viewModel.statusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if viewModel.isBusy {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
    }
}
