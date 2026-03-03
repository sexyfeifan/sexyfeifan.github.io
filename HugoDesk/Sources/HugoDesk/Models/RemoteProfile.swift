import Foundation

struct RemoteProfile: Codable {
    var remoteURL: String
    var workflowName: String
}

struct WorkflowRunStatus {
    var name: String
    var status: String
    var conclusion: String?
    var htmlURL: String
    var createdAt: String
    var updatedAt: String
    var branch: String
    var sha: String
    var note: String?

    var statusText: String {
        if let conclusion, !conclusion.isEmpty {
            return "\(status) / \(conclusion)"
        }
        return status
    }
}
