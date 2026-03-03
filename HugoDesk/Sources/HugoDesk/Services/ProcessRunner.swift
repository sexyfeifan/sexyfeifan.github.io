import Foundation

struct ProcessResult {
    let exitCode: Int32
    let output: String
}

enum ProcessRunnerError: LocalizedError {
    case commandFailed(command: String, code: Int32, output: String)

    var errorDescription: String? {
        switch self {
        case let .commandFailed(command, code, output):
            return "Command failed (\(code)): \(command)\n\(output)"
        }
    }
}

final class ProcessRunner {
    func run(command: String, arguments: [String], in cwd: URL) throws -> ProcessResult {
        let process = Process()
        process.currentDirectoryURL = cwd

        if command.contains("/") {
            process.executableURL = URL(fileURLWithPath: command)
            process.arguments = arguments
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [command] + arguments
        }

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()

        let out = String(data: outData, encoding: .utf8) ?? ""
        let err = String(data: errData, encoding: .utf8) ?? ""
        let combined = [out, err].filter { !$0.isEmpty }.joined(separator: "\n")

        let result = ProcessResult(exitCode: process.terminationStatus, output: combined)

        if process.terminationStatus != 0 {
            let commandLine = ([command] + arguments).joined(separator: " ")
            throw ProcessRunnerError.commandFailed(command: commandLine, code: process.terminationStatus, output: combined)
        }

        return result
    }
}
