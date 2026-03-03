import Foundation

enum AIServiceError: LocalizedError {
    case missingConfiguration
    case invalidEndpoint
    case invalidResponse
    case apiError(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "请先在 AI 设置中填写 API 地址、API Key 和模型。"
        case .invalidEndpoint:
            return "AI API 地址无效，请检查 base URL。"
        case .invalidResponse:
            return "AI 返回内容为空或格式无法识别。"
        case let .apiError(code, body):
            return "AI 请求失败：HTTP \(code)\n\(body)"
        }
    }
}

struct AIService {
    func formatMarkdown(input: String, profile: AIProfile, apiKey: String) async throws -> String {
        let baseURL = profile.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = profile.model.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !baseURL.isEmpty, !model.isEmpty, !token.isEmpty else {
            throw AIServiceError.missingConfiguration
        }

        let endpoint = normalizedEndpoint(baseURL)
        guard let url = URL(string: endpoint) else {
            throw AIServiceError.invalidEndpoint
        }

        let prompt = """
        请将以下内容整理为结构清晰、语义自然的 Markdown 文档：
        1. 保留原文核心信息，不臆造事实。
        2. 自动补齐合理标题、段落、列表、引用或代码块。
        3. 保持中文表达自然，避免模板化口吻。
        4. 仅输出 Markdown 正文，不要解释。

        原文如下：
        \(input)
        """

        let payload: [String: Any] = [
            "model": model,
            "temperature": 0.2,
            "messages": [
                ["role": "system", "content": "You are a professional markdown editor."],
                ["role": "user", "content": prompt]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard 200..<300 ~= code else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AIServiceError.apiError(code, body)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = extractContent(from: message["content"]),
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIServiceError.invalidResponse
        }

        return content
    }

    private func normalizedEndpoint(_ baseURL: String) -> String {
        if baseURL.hasSuffix("/chat/completions") {
            return baseURL
        }
        if baseURL.hasSuffix("/v1") {
            return baseURL + "/chat/completions"
        }
        return baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/v1/chat/completions"
    }

    private func extractContent(from raw: Any?) -> String? {
        if let text = raw as? String {
            return text
        }

        if let array = raw as? [[String: Any]] {
            let parts = array.compactMap { item -> String? in
                if let text = item["text"] as? String {
                    return text
                }
                if let type = item["type"] as? String,
                   type == "text",
                   let text = item["text"] as? String {
                    return text
                }
                return nil
            }
            return parts.joined(separator: "\n")
        }

        return nil
    }
}
