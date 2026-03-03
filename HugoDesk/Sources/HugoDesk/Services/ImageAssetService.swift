import Foundation

final class ImageAssetService {
    private let fm = FileManager.default

    func importImage(from sourceURL: URL, project: BlogProject, subfolder: String) throws -> String {
        let targetDir = project.staticImagesURL.appendingPathComponent(subfolder, isDirectory: true)
        try fm.createDirectory(at: targetDir, withIntermediateDirectories: true)

        let ext = sourceURL.pathExtension.isEmpty ? "png" : sourceURL.pathExtension.lowercased()
        let base = sourceURL.deletingPathExtension().lastPathComponent
        let slug = slugify(base)
        let stamp = timestamp()
        let fileName = "\(stamp)-\(slug).\(ext)"
        let targetURL = uniqueFileURL(in: targetDir, preferredName: fileName)

        try fm.copyItem(at: sourceURL, to: targetURL)
        return "/images/\(subfolder)/\(targetURL.lastPathComponent)"
    }

    func normalizePostImageLinks(project: BlogProject) throws -> (changedFiles: Int, changedLinks: Int) {
        var changedFiles = 0
        var changedLinks = 0

        let enumerator = fm.enumerator(at: project.contentURL, includingPropertiesForKeys: nil)
        while let item = enumerator?.nextObject() as? URL {
            guard item.pathExtension.lowercased() == "md" else { continue }
            let raw = try String(contentsOf: item, encoding: .utf8)
            let updated = try normalizeMarkdownImages(in: raw, for: item, project: project)
            if updated.changedCount > 0 {
                try updated.text.write(to: item, atomically: true, encoding: .utf8)
                changedFiles += 1
                changedLinks += updated.changedCount
            }
        }

        return (changedFiles, changedLinks)
    }

    private func normalizeMarkdownImages(in markdown: String, for fileURL: URL, project: BlogProject) throws -> (text: String, changedCount: Int) {
        let pattern = #"\!\[([^\]]*)\]\(([^)]+)\)"#
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let ns = markdown as NSString
        let matches = regex.matches(in: markdown, range: NSRange(location: 0, length: ns.length))
        if matches.isEmpty {
            return (markdown, 0)
        }

        var result = markdown
        var changed = 0
        for match in matches.reversed() {
            guard match.numberOfRanges >= 3 else { continue }
            let alt = ns.substring(with: match.range(at: 1))
            let rawLink = ns.substring(with: match.range(at: 2))
            let cleanLink = rawLink.trimmingCharacters(in: CharacterSet(charactersIn: "\"' ").union(.whitespacesAndNewlines))

            guard let localURL = resolveLocalImage(link: cleanLink, relativeTo: fileURL) else { continue }
            guard fm.fileExists(atPath: localURL.path) else { continue }

            let webPath = try importImage(from: localURL, project: project, subfolder: "uploads")
            let replacement = "![\(alt)](\(webPath))"
            let r = Range(match.range, in: result)!
            result.replaceSubrange(r, with: replacement)
            changed += 1
        }

        return (result, changed)
    }

    private func resolveLocalImage(link: String, relativeTo postURL: URL) -> URL? {
        let lower = link.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") || lower.hasPrefix("data:") || lower.hasPrefix("/images/") {
            return nil
        }

        if lower.hasPrefix("file://"), let url = URL(string: link) {
            return url
        }

        if link.hasPrefix("~/") {
            let expanded = NSString(string: link).expandingTildeInPath
            return URL(fileURLWithPath: expanded)
        }

        if link.hasPrefix("/") {
            return URL(fileURLWithPath: link)
        }

        return postURL.deletingLastPathComponent().appendingPathComponent(link)
    }

    private func uniqueFileURL(in dir: URL, preferredName: String) -> URL {
        var candidate = dir.appendingPathComponent(preferredName)
        var idx = 2
        while fm.fileExists(atPath: candidate.path) {
            let ext = candidate.pathExtension
            let base = candidate.deletingPathExtension().lastPathComponent
            let trimmedBase = base.replacingOccurrences(of: "-\(idx - 1)$", with: "", options: .regularExpression)
            let next = ext.isEmpty ? "\(trimmedBase)-\(idx)" : "\(trimmedBase)-\(idx).\(ext)"
            candidate = dir.appendingPathComponent(next)
            idx += 1
        }
        return candidate
    }

    private func slugify(_ source: String) -> String {
        let lower = source.lowercased()
        let out = lower.map { ch -> Character in
            if ch.isLetter || ch.isNumber {
                return ch
            }
            return "-"
        }
        let compact = String(out)
            .replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return compact.isEmpty ? "image" : compact
    }

    private func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmmss"
        return f.string(from: Date())
    }
}
