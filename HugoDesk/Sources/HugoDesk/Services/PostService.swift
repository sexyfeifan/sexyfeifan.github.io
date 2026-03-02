import Foundation

final class PostService {
    func loadPosts(for project: BlogProject) throws -> [BlogPost] {
        let contentURL = project.contentURL
        try FileManager.default.createDirectory(at: contentURL, withIntermediateDirectories: true)

        let files = try FileManager.default.contentsOfDirectory(at: contentURL, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension.lowercased() == "md" }

        let posts = try files.map(loadPost)
        return posts.sorted { $0.date > $1.date }
    }

    func loadPost(at fileURL: URL) throws -> BlogPost {
        let raw = try String(contentsOf: fileURL, encoding: .utf8)
        let (frontMatter, body) = splitFrontMatter(from: raw)

        var post = BlogPost.empty(in: fileURL.deletingLastPathComponent())
        post.fileURL = fileURL
        post.body = body

        for line in frontMatter.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            guard let idx = trimmed.firstIndex(of: "=") else {
                continue
            }

            let key = String(trimmed[..<idx]).trimmingCharacters(in: .whitespaces)
            let value = String(trimmed[trimmed.index(after: idx)...]).trimmingCharacters(in: .whitespaces)

            switch key {
            case "title": post.title = parseString(value)
            case "date":
                if let date = parseDate(value) {
                    post.date = date
                }
            case "draft": post.draft = parseBool(value)
            case "summary": post.summary = parseString(value)
            case "tags": post.tags = parseArray(value)
            case "categories": post.categories = parseArray(value)
            case "pin": post.pin = parseBool(value)
            case "math": post.math = parseBool(value)
            case "MathJax", "mathJax": post.mathJax = parseBool(value)
            case "private": post.isPrivate = parseBool(value)
            case "searchable": post.searchable = parseBool(value)
            case "cover": post.cover = parseString(value)
            case "author", "Author": post.author = parseString(value)
            case "keywords", "Keywords": post.keywords = parseArray(value)
            default: break
            }
        }

        return post
    }

    func createNewPost(title: String, in project: BlogProject) -> BlogPost {
        let slug = slugify(title.isEmpty ? "new-post" : title)
        let target = project.contentURL.appendingPathComponent("\(slug).md")
        var post = BlogPost.empty(in: project.contentURL)
        post.fileURL = target
        post.title = title
        post.date = Date()
        post.draft = true
        return post
    }

    func savePost(_ post: BlogPost) throws {
        try FileManager.default.createDirectory(at: post.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let raw = renderPost(post)
        try raw.write(to: post.fileURL, atomically: true, encoding: .utf8)
    }

    private func splitFrontMatter(from raw: String) -> (String, String) {
        let lines = raw.components(separatedBy: .newlines)
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "+++" else {
            return ("", raw)
        }

        var endIndex: Int?
        for idx in 1..<lines.count where lines[idx].trimmingCharacters(in: .whitespaces) == "+++" {
            endIndex = idx
            break
        }

        guard let end = endIndex else {
            return ("", raw)
        }

        let front = lines[1..<end].joined(separator: "\n")
        let body = lines[(end + 1)...].joined(separator: "\n")
        return (front, body)
    }

    private func parseDate(_ raw: String) -> Date? {
        let text = parseString(raw)
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let value = iso.date(from: text) {
            return value
        }

        let iso2 = ISO8601DateFormatter()
        iso2.formatOptions = [.withInternetDateTime]
        return iso2.date(from: text)
    }

    private func renderPost(_ post: BlogPost) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        var lines: [String] = []
        lines.append("+++")
        lines.append("title = \(encode(post.title))")
        lines.append("date = \(formatter.string(from: post.date))")
        lines.append("draft = \(post.draft ? "true" : "false")")

        if !post.summary.isEmpty { lines.append("summary = \(encode(post.summary))") }
        if !post.tags.isEmpty { lines.append("tags = \(encodeArray(post.tags))") }
        if !post.categories.isEmpty { lines.append("categories = \(encodeArray(post.categories))") }
        if post.pin { lines.append("pin = true") }
        if post.math { lines.append("math = true") }
        if post.mathJax { lines.append("MathJax = true") }
        if post.isPrivate { lines.append("private = true") }
        if !post.searchable { lines.append("searchable = false") }
        if !post.cover.isEmpty { lines.append("cover = \(encode(post.cover))") }
        if !post.author.isEmpty { lines.append("author = \(encode(post.author))") }
        if !post.keywords.isEmpty { lines.append("keywords = \(encodeArray(post.keywords))") }

        lines.append("+++")
        lines.append("")
        lines.append(post.body)
        if !post.body.hasSuffix("\n") {
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    private func parseString(_ raw: String) -> String {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("\"") && value.hasSuffix("\"") && value.count >= 2 {
            value.removeFirst()
            value.removeLast()
        } else if value.hasPrefix("'") && value.hasSuffix("'") && value.count >= 2 {
            value.removeFirst()
            value.removeLast()
        }
        return value
    }

    private func parseBool(_ raw: String) -> Bool {
        parseString(raw).lowercased() == "true"
    }

    private func parseArray(_ raw: String) -> [String] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("[") && trimmed.hasSuffix("]") else {
            let single = parseString(trimmed)
            return single.isEmpty ? [] : [single]
        }
        let content = String(trimmed.dropFirst().dropLast())
        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }
        return content.split(separator: ",")
            .map { parseString(String($0)) }
            .filter { !$0.isEmpty }
    }

    private func encode(_ text: String) -> String {
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    private func encodeArray(_ values: [String]) -> String {
        "[" + values.map { encode($0) }.joined(separator: ", ") + "]"
    }

    private func slugify(_ source: String) -> String {
        let lower = source.lowercased()
        let filtered = lower.map { char -> Character in
            if char.isLetter || char.isNumber {
                return char
            }
            return "-"
        }
        let compact = String(filtered)
            .replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return compact.isEmpty ? "post-\(Int(Date().timeIntervalSince1970))" : compact
    }
}
