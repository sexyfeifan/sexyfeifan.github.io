import Foundation

final class PublishService {
    private let runner = ProcessRunner()

    func runHugoBuild(project: BlogProject) throws -> String {
        let result = try runner.run(
            command: project.hugoExecutable,
            arguments: ["--gc", "--minify"],
            in: project.rootURL
        )
        return result.output
    }

    func gitStatus(project: BlogProject) throws -> String {
        let result = try runner.run(
            command: "git",
            arguments: ["status", "--short", "--branch"],
            in: project.rootURL
        )
        return result.output
    }

    func commitAndPush(project: BlogProject, message: String, remoteURL: String) throws -> String {
        var logs: [String] = []

        if !remoteURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let setRemoteResult = ensureRemoteURL(project: project, remoteURL: remoteURL)
            if !setRemoteResult.isEmpty {
                logs.append(setRemoteResult)
            }
        }

        let add = try runner.run(command: "git", arguments: ["add", "."], in: project.rootURL)
        if !add.output.isEmpty {
            logs.append(add.output)
        }

        do {
            let commit = try runner.run(command: "git", arguments: ["commit", "-m", message], in: project.rootURL)
            if !commit.output.isEmpty {
                logs.append(commit.output)
            }
        } catch let ProcessRunnerError.commandFailed(_, _, output) {
            if output.contains("nothing to commit") || output.contains("no changes added") {
                logs.append("No staged changes. Skip commit.")
            } else {
                throw ProcessRunnerError.commandFailed(command: "git commit", code: 1, output: output)
            }
        }

        let push = try runner.run(
            command: "git",
            arguments: ["push", project.gitRemote, project.publishBranch],
            in: project.rootURL
        )
        if !push.output.isEmpty {
            logs.append(push.output)
        }

        return logs.joined(separator: "\n")
    }

    func detectRemoteURL(project: BlogProject) -> String {
        do {
            let result = try runner.run(
                command: "git",
                arguments: ["remote", "get-url", project.gitRemote],
                in: project.rootURL
            )
            return result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return ""
        }
    }

    private func ensureRemoteURL(project: BlogProject, remoteURL: String) -> String {
        do {
            let _ = try runner.run(
                command: "git",
                arguments: ["remote", "get-url", project.gitRemote],
                in: project.rootURL
            )
            let result = try runner.run(
                command: "git",
                arguments: ["remote", "set-url", project.gitRemote, remoteURL],
                in: project.rootURL
            )
            return result.output
        } catch {
            do {
                let result = try runner.run(
                    command: "git",
                    arguments: ["remote", "add", project.gitRemote, remoteURL],
                    in: project.rootURL
                )
                return result.output
            } catch {
                return ""
            }
        }
    }
}
