import Foundation

enum GitHubActionsError: LocalizedError {
    case invalidRepositoryURL
    case workflowNotFound
    case httpError(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidRepositoryURL:
            return "无法解析 GitHub 仓库地址。"
        case .workflowNotFound:
            return "未找到匹配的 workflow 运行记录。"
        case let .httpError(code, body):
            return "GitHub API 请求失败：HTTP \(code)\n\(body)"
        }
    }
}

struct GitHubActionsService: Sendable {
    func fetchLatestRun(
        remoteURL: String,
        token: String,
        workflowName: String
    ) async throws -> WorkflowRunStatus {
        let repo = try parseRepo(from: remoteURL)
        let endpoint = URL(string: "https://api.github.com/repos/\(repo.owner)/\(repo.name)/actions/runs?per_page=20")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("HugoDesk", forHTTPHeaderField: "User-Agent")
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard 200..<300 ~= code else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw GitHubActionsError.httpError(code, body)
        }

        let decoded = try JSONDecoder().decode(WorkflowRunsResponse.self, from: data)
        let picked: WorkflowRunItem?
        if workflowName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            picked = decoded.workflowRuns.first
        } else {
            picked = decoded.workflowRuns.first {
                $0.name.localizedCaseInsensitiveContains(workflowName)
            }
        }

        guard let run = picked else {
            throw GitHubActionsError.workflowNotFound
        }

        return WorkflowRunStatus(
            name: run.name,
            status: run.status,
            conclusion: run.conclusion,
            htmlURL: run.htmlURL,
            createdAt: run.createdAt,
            updatedAt: run.updatedAt,
            branch: run.headBranch,
            sha: run.headSHA
        )
    }

    private func parseRepo(from remoteURL: String) throws -> (owner: String, name: String) {
        let trimmed = remoteURL.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("git@github.com:") {
            let rest = trimmed.replacingOccurrences(of: "git@github.com:", with: "")
            let parts = rest.split(separator: "/")
            guard parts.count == 2 else {
                throw GitHubActionsError.invalidRepositoryURL
            }
            let owner = String(parts[0])
            let repo = String(parts[1]).replacingOccurrences(of: ".git", with: "")
            return (owner, repo)
        }

        guard let url = URL(string: trimmed),
              url.host?.contains("github.com") == true else {
            throw GitHubActionsError.invalidRepositoryURL
        }
        let comps = url.pathComponents.filter { $0 != "/" }
        guard comps.count >= 2 else {
            throw GitHubActionsError.invalidRepositoryURL
        }
        let owner = comps[0]
        let repo = comps[1].replacingOccurrences(of: ".git", with: "")
        return (owner, repo)
    }
}

private struct WorkflowRunsResponse: Decodable {
    let workflowRuns: [WorkflowRunItem]

    enum CodingKeys: String, CodingKey {
        case workflowRuns = "workflow_runs"
    }
}

private struct WorkflowRunItem: Decodable {
    let name: String
    let status: String
    let conclusion: String?
    let htmlURL: String
    let createdAt: String
    let updatedAt: String
    let headBranch: String
    let headSHA: String

    enum CodingKeys: String, CodingKey {
        case name
        case status
        case conclusion
        case htmlURL = "html_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case headBranch = "head_branch"
        case headSHA = "head_sha"
    }
}
