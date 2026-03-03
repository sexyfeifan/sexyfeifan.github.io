import Foundation

enum DownloadServiceError: Error, LocalizedError {
    case cloneFailed(String)

    var errorDescription: String? {
        switch self {
        case .cloneFailed(let message):
            return "源码拉取失败：\(message)"
        }
    }
}

struct DownloadProgressInfo {
    let downloadedBytes: Int64
    let totalBytes: Int64
    let speedBytesPerSec: Double
    let sourceURL: URL

    var progress: Double {
        guard totalBytes > 0 else { return 0 }
        return min(max(Double(downloadedBytes) / Double(totalBytes), 0), 1)
    }
}

struct DownloadService {
    private let fm = FileManager.default

    func download(
        asset: GitHubAsset,
        to projectDir: URL,
        onProgress: ((DownloadProgressInfo) -> Void)? = nil
    ) async throws -> URL {
        try fm.createDirectory(at: projectDir, withIntermediateDirectories: true)

        let destination = projectDir.appendingPathComponent(asset.name)
        if fm.fileExists(atPath: destination.path) {
            return destination
        }

        let helper = DownloadTaskHelper(
            url: asset.browserDownloadURL,
            expectedTotalBytes: Int64(max(asset.size, 0)),
            onProgress: onProgress
        )
        let tmpURL = try await helper.start()
        try fm.moveItem(at: tmpURL, to: destination)
        return destination
    }

    func downloadImage(from url: URL, to projectDir: URL) async -> String {
        do {
            try fm.createDirectory(at: projectDir, withIntermediateDirectories: true)
            let name = imageFileName(from: url)
            let destination = projectDir.appendingPathComponent(name)
            if fm.fileExists(atPath: destination.path) {
                return destination.path
            }

            let helper = DownloadTaskHelper(url: url, expectedTotalBytes: nil, onProgress: nil)
            let tmpURL = try await helper.start()
            try fm.moveItem(at: tmpURL, to: destination)
            return destination.path
        } catch {
            return ""
        }
    }

    private func imageFileName(from url: URL) -> String {
        let last = url.lastPathComponent
        if last.isEmpty || !last.contains(".") {
            return "preview_image.jpg"
        }
        return "preview_" + last
    }

    func cloneRepository(repoURL: URL, to projectDir: URL) async throws -> URL {
        try fm.createDirectory(at: projectDir, withIntermediateDirectories: true)
        let sourceDir = projectDir.appendingPathComponent("source_code", isDirectory: true)
        if fm.fileExists(atPath: sourceDir.path) {
            do {
                try await runGit(arguments: ["-C", sourceDir.path, "pull", "--ff-only", "--quiet"])
                // Upgrade historical shallow clones to full repository when possible.
                try? await runGit(arguments: ["-C", sourceDir.path, "fetch", "--unshallow", "--quiet"])
                return sourceDir
            } catch {
                try? fm.removeItem(at: sourceDir)
            }
        }

        try await runGit(arguments: ["clone", "--quiet", repoURL.absoluteString, sourceDir.path])
        return sourceDir
    }

    private func runGit(arguments: [String]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                do {
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                    process.arguments = ["git"] + arguments
                    var env = ProcessInfo.processInfo.environment
                    env["GIT_TERMINAL_PROMPT"] = "0"
                    process.environment = env

                    let outputPipe = Pipe()
                    process.standardOutput = outputPipe
                    process.standardError = outputPipe

                    try process.run()
                    process.waitUntilExit()
                    if process.terminationStatus == 0 {
                        continuation.resume(returning: ())
                        return
                    }

                    let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let reason = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "unknown"
                    continuation.resume(throwing: DownloadServiceError.cloneFailed(reason))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

private final class DownloadTaskHelper: NSObject, URLSessionDownloadDelegate {
    private let sourceURL: URL
    private let expectedTotalBytes: Int64?
    private let onProgress: ((DownloadProgressInfo) -> Void)?

    private var continuation: CheckedContinuation<URL, Error>?
    private var session: URLSession?
    private var startTime = Date()
    private var lastTickTime = Date()
    private var lastBytes: Int64 = 0

    init(url: URL, expectedTotalBytes: Int64?, onProgress: ((DownloadProgressInfo) -> Void)?) {
        self.sourceURL = url
        self.expectedTotalBytes = expectedTotalBytes
        self.onProgress = onProgress
    }

    func start() async throws -> URL {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
            continuation = cont
            let config = URLSessionConfiguration.default
            session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
            startTime = Date()
            lastTickTime = startTime
            lastBytes = 0
            let task = session!.downloadTask(with: sourceURL)
            task.resume()
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let onProgress {
            let expected = max(downloadTask.response?.expectedContentLength ?? -1, expectedTotalBytes ?? -1)
            let total = expected > 0 ? expected : -1
            onProgress(
                DownloadProgressInfo(
                    downloadedBytes: total > 0 ? total : 0,
                    totalBytes: total,
                    speedBytesPerSec: 0,
                    sourceURL: sourceURL
                )
            )
        }
        continuation?.resume(returning: location)
        continuation = nil
        session.invalidateAndCancel()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            continuation?.resume(throwing: error)
            continuation = nil
            session.invalidateAndCancel()
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let onProgress else { return }
        let now = Date()
        let deltaT = now.timeIntervalSince(lastTickTime)
        if deltaT < 0.2 { return }

        let deltaBytes = totalBytesWritten - lastBytes
        let speed = deltaT > 0 ? Double(deltaBytes) / deltaT : 0
        lastTickTime = now
        lastBytes = totalBytesWritten
        let expected = max(totalBytesExpectedToWrite, expectedTotalBytes ?? -1)

        onProgress(
            DownloadProgressInfo(
                downloadedBytes: totalBytesWritten,
                totalBytes: expected,
                speedBytesPerSec: max(speed, 0),
                sourceURL: sourceURL
            )
        )
    }
}
