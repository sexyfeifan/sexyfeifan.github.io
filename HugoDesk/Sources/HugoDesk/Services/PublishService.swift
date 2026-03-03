import Foundation

final class PublishService {
    private let runner = ProcessRunner()
    private let fm = FileManager.default

    func runHugoBuild(project: BlogProject) throws -> String {
        let executable = resolveCommandPath(name: project.hugoExecutable, cwd: project.rootURL) ?? project.hugoExecutable
        let result = try runner.run(
            command: executable,
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

    func diagnosePublishEnvironment(project: BlogProject, remoteURL: String) throws -> String {
        var lines: [String] = []

        lines.append("== 组件检查 ==")
        let git = toolStatus(name: "git", versionArgs: ["--version"], cwd: project.rootURL)
        let hugo = toolStatus(name: project.hugoExecutable, versionArgs: ["version"], cwd: project.rootURL)
        let brewPath = resolveCommandPath(name: "brew", cwd: project.rootURL)

        lines.append(statusLine(for: git))
        lines.append(statusLine(for: hugo))
        appendMissingToolHints(lines: &lines, git: git, hugo: hugo, brewPath: brewPath)

        if git.requiresXcodeLicense || hugo.requiresXcodeLicense {
            lines.append("⚠️ 检测到 Xcode 许可未同意，请先在终端执行：sudo xcodebuild -license accept")
        }

        lines.append("")
        lines.append("== 推送能力检查 ==")

        if !git.usable {
            lines.append("❌ Git 不可用，跳过推送检查。")
            return lines.joined(separator: "\n")
        }

        let isRepo = capture(command: "git", arguments: ["rev-parse", "--is-inside-work-tree"], in: project.rootURL)
        lines.append(renderCheck(title: "Git 仓库", result: isRepo))
        if !isRepo.success {
            lines.append("❌ 当前目录不是有效 Git 仓库，无法继续推送检查。")
            return lines.joined(separator: "\n")
        }

        let remoteName = project.gitRemote.trimmingCharacters(in: .whitespacesAndNewlines)
        let remoteCandidate = remoteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let remoteTarget = remoteCandidate.isEmpty ? remoteName : remoteCandidate
        if remoteTarget.isEmpty {
            lines.append("❌ 未配置远程地址（remote URL / remote name）。")
            return lines.joined(separator: "\n")
        }

        if remoteCandidate.isEmpty {
            let remoteExists = capture(command: "git", arguments: ["remote", "get-url", remoteName], in: project.rootURL)
            lines.append(renderCheck(title: "远程地址检测（\(remoteName)）", result: remoteExists))
            if !remoteExists.success {
                lines.append("❌ 未找到 remote \"\(remoteName)\"，请先在项目设置中配置推送地址。")
                return lines.joined(separator: "\n")
            }
        }

        let remoteProbe = capture(command: "git", arguments: ["ls-remote", remoteTarget, "HEAD"], in: project.rootURL)
        lines.append(renderCheck(title: "远程可达性（git ls-remote）", result: remoteProbe))

        let dryRun = capture(command: "git", arguments: ["push", "--dry-run", remoteTarget, project.publishBranch], in: project.rootURL)
        lines.append(renderCheck(title: "推送权限（git push --dry-run）", result: dryRun))

        if containsTLSError(remoteProbe.output) || containsTLSError(dryRun.output) {
            lines.append("⚠️ 检测到 TLS/SSL 网络异常。可尝试更换网络、关闭系统代理或配置 Git 代理后重试。")
            appendTLSHints(lines: &lines, remoteTarget: remoteTarget, publishBranch: project.publishBranch)
        }

        if remoteProbe.success && dryRun.success {
            lines.append("✅ 推送链路可用，可以执行提交推送。")
        } else {
            lines.append("⚠️ 推送能力存在问题，请先修复上方失败项。")
        }

        return lines.joined(separator: "\n")
    }

    func installMissingComponents(project: BlogProject, remoteURL: String) throws -> String {
        var lines: [String] = []
        lines.append("== 自动安装缺失组件 ==")

        let git = toolStatus(name: "git", versionArgs: ["--version"], cwd: project.rootURL)
        let hugo = toolStatus(name: project.hugoExecutable, versionArgs: ["version"], cwd: project.rootURL)
        let brewPath = resolveCommandPath(name: "brew", cwd: project.rootURL)

        if git.requiresXcodeLicense || hugo.requiresXcodeLicense {
            lines.append("⚠️ 检测到 Xcode 许可未同意。此项无法自动处理，请先执行：sudo xcodebuild -license accept")
            lines.append("")
            lines.append(try diagnosePublishEnvironment(project: project, remoteURL: remoteURL))
            return lines.joined(separator: "\n")
        }

        if let brewPath {
            lines.append("✅ Homebrew 已安装：\(brewPath)")
        } else {
            let missing = missingComponentNames(git: git, hugo: hugo)
            if missing.isEmpty {
                lines.append("✅ 未发现缺失组件。")
            } else {
                lines.append("❌ 未检测到 Homebrew，无法一键安装：\(missing.joined(separator: "、"))")
                lines.append("")
                lines.append("请先安装 Homebrew 后重试：https://brew.sh")
                lines.append("安装命令：/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"")
                lines.append("安装 hugo 命令：brew install hugo")
                lines.append("安装 git 命令：brew install git")
            }
            lines.append("")
            lines.append("== 安装后复检 ==")
            lines.append(try diagnosePublishEnvironment(project: project, remoteURL: remoteURL))
            return lines.joined(separator: "\n")
        }

        if !git.usable {
            let brew = brewPath ?? "brew"
            let installGit = capture(command: brew, arguments: ["install", "git"], in: project.rootURL)
            lines.append(renderCheck(title: "安装 git", result: installGit))
            lines.append("若安装失败可手动执行：brew install git")
        } else {
            lines.append("✅ git 已安装，无需处理。")
        }

        if !hugo.usable {
            let brew = brewPath ?? "brew"
            let installHugo = capture(command: brew, arguments: ["install", "hugo"], in: project.rootURL)
            lines.append(renderCheck(title: "安装 hugo", result: installHugo))
            lines.append("若安装失败可手动执行：brew install hugo")
        } else {
            lines.append("✅ hugo 已安装，无需处理。")
        }

        lines.append("")
        lines.append("== 安装后复检 ==")
        lines.append(try diagnosePublishEnvironment(project: project, remoteURL: remoteURL))

        return lines.joined(separator: "\n")
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
            _ = try runner.run(
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

    private func containsTLSError(_ output: String) -> Bool {
        let text = output.lowercased()
        return text.contains("ssl_connect") || text.contains("ssl_error") || text.contains("tls")
    }

    private func appendMissingToolHints(lines: inout [String], git: ToolStatus, hugo: ToolStatus, brewPath: String?) {
        var hints: [String] = []

        if !git.usable {
            if brewPath != nil {
                hints.append("git 缺失可执行命令：brew install git")
            } else {
                hints.append("git 缺失：先安装 Homebrew，再执行 brew install git")
            }
        }

        if !hugo.usable {
            if brewPath != nil {
                hints.append("hugo 缺失可执行命令：brew install hugo")
            } else {
                hints.append("hugo 缺失：先安装 Homebrew，再执行 brew install hugo")
            }
        }

        if hints.isEmpty {
            return
        }

        lines.append("安装建议：")
        for hint in hints {
            lines.append("- \(hint)")
        }
    }

    private func appendTLSHints(lines: inout [String], remoteTarget: String, publishBranch: String) {
        lines.append("建议按顺序执行以下排查命令：")
        lines.append("- git config --global --get http.proxy")
        lines.append("- git config --global --get https.proxy")
        lines.append("- env | grep -i proxy")
        lines.append("- unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY")
        lines.append("- git ls-remote \(remoteTarget) HEAD")
        lines.append("- git push --dry-run \(remoteTarget) \(publishBranch)")
    }

    private func missingComponentNames(git: ToolStatus, hugo: ToolStatus) -> [String] {
        var names: [String] = []
        if !git.usable {
            names.append("git")
        }
        if !hugo.usable {
            names.append("hugo")
        }
        return names
    }

    private func statusLine(for status: ToolStatus) -> String {
        if status.usable {
            return "✅ \(status.displayName)：\(status.versionText)"
        }
        if status.exists {
            return "⚠️ \(status.displayName)：已安装但不可用（\(status.versionText)）"
        }
        return "❌ \(status.displayName)：未安装"
    }

    private func renderCheck(title: String, result: CommandCapture) -> String {
        if result.success {
            if result.output.isEmpty {
                return "✅ \(title)：通过"
            }
            return "✅ \(title)：\(result.output)"
        }
        if result.output.isEmpty {
            return "❌ \(title)：失败"
        }
        return "❌ \(title)：\(result.output)"
    }

    private func toolStatus(name: String, versionArgs: [String], cwd: URL) -> ToolStatus {
        let executable = resolveCommandPath(name: name, cwd: cwd)
        guard let executable else {
            return ToolStatus(
                displayName: name,
                exists: false,
                usable: false,
                versionText: "无输出",
                requiresXcodeLicense: false
            )
        }

        let version = capture(command: executable, arguments: versionArgs, in: cwd)
        let licenseIssue = version.output.localizedCaseInsensitiveContains("Xcode license agreements")

        return ToolStatus(
            displayName: name,
            exists: true,
            usable: version.success,
            versionText: version.output.isEmpty ? executable : version.output,
            requiresXcodeLicense: licenseIssue
        )
    }

    private func resolveCommandPath(name: String, cwd: URL) -> String? {
        if name.contains("/") {
            return fm.isExecutableFile(atPath: name) ? name : nil
        }

        let commonRoots = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin", "/opt/local/bin"]
        for root in commonRoots {
            let candidate = "\(root)/\(name)"
            if fm.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }

        let lookup = capture(command: "/usr/bin/env", arguments: ["which", name], in: cwd)
        let path = lookup.output.trimmingCharacters(in: .whitespacesAndNewlines)
        if lookup.success, !path.isEmpty, fm.isExecutableFile(atPath: path) {
            return path
        }

        return nil
    }

    private func capture(command: String, arguments: [String], in cwd: URL) -> CommandCapture {
        do {
            let result = try runner.run(command: command, arguments: arguments, in: cwd)
            return CommandCapture(success: true, output: sanitizeOutput(result.output))
        } catch let ProcessRunnerError.commandFailed(_, _, output) {
            return CommandCapture(success: false, output: sanitizeOutput(output))
        } catch {
            return CommandCapture(success: false, output: sanitizeOutput(error.localizedDescription))
        }
    }

    private func sanitizeOutput(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n\n+", with: "\n", options: .regularExpression)
    }
}

private struct ToolStatus {
    var displayName: String
    var exists: Bool
    var usable: Bool
    var versionText: String
    var requiresXcodeLicense: Bool
}

private struct CommandCapture {
    var success: Bool
    var output: String
}
