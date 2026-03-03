import Foundation

struct TranslationConfig {
    let apiKey: String
    let baseURL: String
    let model: String

    var isEnabled: Bool { !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

struct TranslatorService {
    func translateToChinese(_ text: String, config: TranslationConfig) async -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        guard config.isEnabled else { return trimmed }

        do {
            let clipped = String(trimmed.prefix(12_000))
            return try await translateWithOpenAI(clipped, config: config)
        } catch {
            return trimmed
        }
    }

    func summarizeReadmeToChinese(_ readme: String, config: TranslationConfig) async -> String {
        let trimmed = readme.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "暂无 README 内容。" }

        guard config.isEnabled else {
            if containsChinese(trimmed) {
                return fallbackChineseSummary(trimmed)
            }
            return fallbackChineseSummary("[原文]\n\(trimmed)")
        }

        let clipped = String(trimmed.prefix(12_000))
        let prompt: String
        if containsChinese(clipped) {
            prompt = """
            请把下面 README 内容整理成“中文精简介绍”，要求：
            1) 先给一句项目定位；
            2) 再给 4-8 条要点，覆盖核心功能、适用场景、运行依赖、输入输出；
            3) 如果 README 中有命令或配置项，必须保留原命令并说明用途；
            4) 语言精炼，不要编造不存在的信息。

            README:
            \(clipped)
            """
        } else {
            prompt = """
            请先将下面 README 完整理解并翻译为简体中文，再整理成“中文精简介绍”，要求：
            1) 先给一句项目定位；
            2) 再给 4-8 条要点，覆盖核心功能、适用场景、运行依赖、输入输出；
            3) 如果 README 中有命令或配置项，必须保留原命令并说明用途；
            4) 语言精炼，不要编造不存在的信息。

            README:
            \(clipped)
            """
        }

        do {
            let result = try await chat(
                system: "你是资深开源项目文档编辑，擅长技术翻译与摘要。",
                user: prompt,
                config: config,
                temperature: 0.2
            )
            return result.isEmpty ? fallbackChineseSummary(trimmed) : result
        } catch {
            return fallbackChineseSummary(trimmed)
        }
    }

    func extractSetupGuide(_ readme: String, config: TranslationConfig) async -> String {
        let trimmed = readme.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "暂无可提取的搭建步骤。" }

        guard config.isEnabled else {
            return fallbackSetupGuide(from: trimmed)
        }

        let clipped = String(trimmed.prefix(12_000))
        let prompt = """
        请从 README 中提取“运行方式/搭建代码/部署命令/启动步骤”，不限 docker。
        输出要求：
        - 用中文编号步骤（步骤 1、步骤 2...）；
        - 每一步必须包含“这一步的目的”与“关键命令/配置”；
        - 只要属于安装、构建、运行、部署、测试、初始化相关内容都要纳入；
        - 如果存在多种运行方式（本地、Docker、二进制等），分别分组；
        - 没有明确步骤时，输出“未找到明确搭建步骤”并给出最接近的运行命令。

        README:
        \(clipped)
        """

        do {
            let result = try await chat(
                system: "你是 DevOps 与工程化文档专家。",
                user: prompt,
                config: config,
                temperature: 0.2
            )
            return result.isEmpty ? fallbackSetupGuide(from: trimmed) : result
        } catch {
            return fallbackSetupGuide(from: trimmed)
        }
    }

    private func translateWithOpenAI(_ text: String, config: TranslationConfig) async throws -> String {
        try await chat(
            system: "你是专业技术翻译助手。将输入英文技术说明翻译为简体中文，保持术语准确，输出纯文本。",
            user: text,
            config: config,
            temperature: 0.1
        )
    }

    private func chat(
        system: String,
        user: String,
        config: TranslationConfig,
        temperature: Double
    ) async throws -> String {
        guard let url = URL(string: "\(config.baseURL.trimmingCharacters(in: .whitespacesAndNewlines))/chat/completions") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        let payload = OpenAIChatRequest(
            model: config.model,
            temperature: temperature,
            messages: [
                .init(role: "system", content: system),
                .init(role: "user", content: user)
            ]
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        let output = decoded.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return output
    }

    private func containsChinese(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if scalar.value >= 0x4E00 && scalar.value <= 0x9FFF {
                return true
            }
        }
        return false
    }

    private func fallbackChineseSummary(_ text: String) -> String {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if lines.isEmpty { return "暂无 README 内容。" }
        let title = lines.first ?? "项目简介"
        let body = lines.dropFirst().prefix(8).map { "- \($0)" }.joined(separator: "\n")
        if body.isEmpty { return title }
        return "\(title)\n\n\(body)"
    }

    private func fallbackSetupGuide(from text: String) -> String {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let keywords = [
            "install", "setup", "quick start", "usage", "run", "start", "build", "deploy", "test",
            "启动", "运行", "安装", "部署", "构建", "编译", "测试", "初始化",
            "docker", "npm", "pnpm", "yarn", "pip", "poetry", "cargo", "go run", "make", "cmake", "swift run"
        ]
        let commandHints = ["$", "npm ", "pnpm ", "yarn ", "pip ", "python ", "cargo ", "go ", "make ", "docker ", "swift "]
        let matches = lines.filter { line in
            let lower = line.lowercased()
            let hasKeyword = keywords.contains(where: { lower.contains($0) })
            let looksLikeCommand = commandHints.contains(where: { lower.hasPrefix($0) || lower.contains(" \($0)") })
            return hasKeyword || looksLikeCommand || line.hasPrefix("```")
        }.prefix(12)

        if matches.isEmpty {
            return "未找到明确搭建步骤。"
        }

        var steps: [String] = []
        var index = 1
        for line in matches {
            steps.append("步骤 \(index)：\(purposeHint(for: line))\n- 关键内容：\(line)")
            index += 1
        }
        return steps.joined(separator: "\n")
    }

    private func purposeHint(for line: String) -> String {
        let lower = line.lowercased()
        if lower.contains("install") || lower.contains("安装") {
            return "安装依赖或准备运行环境"
        }
        if lower.contains("build") || lower.contains("构建") || lower.contains("编译") {
            return "构建项目产物"
        }
        if lower.contains("test") || lower.contains("测试") {
            return "验证项目可用性"
        }
        if lower.contains("run") || lower.contains("start") || lower.contains("启动") || lower.contains("运行") {
            return "启动项目服务或应用"
        }
        if lower.contains("docker") {
            return "通过容器方式启动项目"
        }
        return "执行 README 中给出的关键步骤"
    }
}

struct SummarizerService {
    func summarize(_ text: String, fallbackTitle: String) -> String {
        let source = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if source.isEmpty {
            return "\(fallbackTitle)：GitHub 开源项目，可用于快速评估与本地安装。"
        }
        let compact = source
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "*", with: "")
        let short = String(compact.prefix(90))
        return short + (compact.count > 90 ? "..." : "")
    }
}

struct ClassifierService {
    func classify(repo: GitHubRepo, text: String) -> String {
        let joined = ([repo.description ?? "", text] + (repo.topics ?? [])).joined(separator: " ").lowercased()
        let rules: [(String, [String])] = [
            ("AI 工具", ["ai", "llm", "rag", "machine learning", "agent", "gpt"]),
            ("开发工具", ["terminal", "cli", "developer", "devtool", "sdk", "compiler", "debug"]),
            ("效率工具", ["note", "todo", "productivity", "task", "calendar", "workflow"]),
            ("媒体工具", ["video", "audio", "image", "media", "photo", "ffmpeg"]),
            ("安全工具", ["security", "encrypt", "crypto", "vulnerability", "auth"]),
            ("系统工具", ["system", "monitor", "performance", "benchmark", "ops"]),
            ("网络工具", ["network", "proxy", "http", "api", "dns", "gateway"]),
            ("数据库工具", ["database", "sql", "postgres", "mysql", "redis", "sqlite"]),
            ("设计工具", ["design", "ui", "figma", "theme", "font"])
        ]

        var bestCategory = "通用工具"
        var bestScore = 0
        for (category, keywords) in rules {
            let score = keywords.reduce(0) { partial, kw in
                partial + (joined.contains(kw) ? 1 : 0)
            }
            if score > bestScore {
                bestScore = score
                bestCategory = category
            }
        }

        if bestScore > 0 {
            return bestCategory
        }
        if let lang = repo.language, !lang.isEmpty {
            return "\(lang) 工具"
        }
        return "通用工具"
    }
}

private struct OpenAIChatRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    let model: String
    let temperature: Double
    let messages: [Message]
}

private struct OpenAIChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let role: String?
            let content: String?
        }

        let message: Message
    }

    let choices: [Choice]
}
