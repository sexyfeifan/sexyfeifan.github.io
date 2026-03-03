import SwiftUI

struct AISettingsView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ModernCard(title: "AI 接入设置", subtitle: "用于写作区 AI Markdown 排版") {
                    VStack(spacing: 10) {
                        SettingRow(
                            key: "ai.baseURL",
                            title: "API 地址",
                            helpText: "支持 OpenAI 兼容接口。可填到 /v1 或完整 /chat/completions。",
                            scope: "AI"
                        ) {
                            TextField("https://api.openai.com/v1", text: $viewModel.aiBaseURL)
                                .textFieldStyle(.roundedBorder)
                        }

                        SettingRow(
                            key: "ai.model",
                            title: "模型",
                            helpText: "例如 gpt-4.1-mini。",
                            scope: "AI"
                        ) {
                            TextField("gpt-4.1-mini", text: $viewModel.aiModel)
                                .textFieldStyle(.roundedBorder)
                        }

                        SettingRow(
                            key: "ai.apiKey",
                            title: "API Key",
                            helpText: "保存在项目配置包（.hugodesk.local.json）并同步到系统钥匙串。",
                            scope: "AI"
                        ) {
                            SecureField("sk-...", text: $viewModel.aiAPIKey)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }

                ModernCard(title: "操作") {
                    HStack {
                        Button("保存 AI 设置") {
                            viewModel.saveAISettings()
                        }
                        Spacer()
                    }
                }
            }
            .padding()
        }
    }
}
