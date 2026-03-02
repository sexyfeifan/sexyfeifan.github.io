import SwiftUI

struct RootView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(nsColor: .windowBackgroundColor), Color.accentColor.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
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
