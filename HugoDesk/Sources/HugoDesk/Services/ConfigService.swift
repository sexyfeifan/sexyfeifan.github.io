import Foundation

final class ConfigService {
    func loadConfig(for project: BlogProject) throws -> ThemeConfig {
        let fileURL = project.configURL
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return ThemeConfig()
        }

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        var config = ThemeConfig()
        var section = ""
        var linkIndex: Int?

        for raw in lines {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            if trimmed.hasPrefix("[[") && trimmed.hasSuffix("]]") {
                let name = String(trimmed.dropFirst(2).dropLast(2))
                section = name
                if name == "params.links" {
                    config.params.links.append(ThemeLink())
                    linkIndex = config.params.links.count - 1
                }
                continue
            }

            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                section = String(trimmed.dropFirst().dropLast())
                linkIndex = nil
                continue
            }

            guard let (key, valueRaw) = splitKeyValue(trimmed) else {
                continue
            }

            let value = stripInlineComment(valueRaw).trimmingCharacters(in: .whitespaces)

            switch section {
            case "":
                switch key {
                case "baseURL": config.baseURL = parseString(value)
                case "languageCode": config.languageCode = parseString(value)
                case "title": config.title = parseString(value)
                case "theme": config.theme = parseString(value)
                case "pygmentsCodeFences": config.pygmentsCodeFences = parseBool(value)
                case "pygmentsUseClasses": config.pygmentsUseClasses = parseBool(value)
                default: break
                }

            case "params":
                applyParam(key: key, value: value, to: &config)

            case "params.gitalk":
                applyGitalkParam(key: key, value: value, to: &config)

            case "params.links":
                if let idx = linkIndex {
                    switch key {
                    case "title": config.params.links[idx].title = parseString(value)
                    case "href": config.params.links[idx].href = parseString(value)
                    case "icon": config.params.links[idx].icon = parseString(value)
                    default: break
                    }
                }

            case "frontmatter":
                if key == "lastmod" {
                    config.frontmatterTrackLastmod = true
                }

            case "services.googleAnalytics":
                if key == "ID" {
                    config.googleAnalyticsID = parseString(value)
                }

            case "outputs":
                if key == "home" {
                    config.outputsHome = parseStringArray(value)
                }

            case "outputFormats.json":
                switch key {
                case "mediaType": config.outputFormatJSONMediaType = parseString(value)
                case "baseName": config.outputFormatJSONBaseName = parseString(value)
                case "isPlainText": config.outputFormatJSONIsPlainText = parseBool(value)
                default: break
                }

            default:
                break
            }
        }

        return config
    }

    func saveConfig(_ config: ThemeConfig, for project: BlogProject) throws {
        var lines: [String] = []

        lines.append("baseURL = \(encodeString(config.baseURL))")
        lines.append("languageCode = \(encodeString(config.languageCode))")
        lines.append("title = \(encodeString(config.title))")
        lines.append("theme = \(encodeString(config.theme))")
        lines.append("pygmentsCodeFences = \(config.pygmentsCodeFences ? "true" : "false")")
        lines.append("pygmentsUseClasses = \(config.pygmentsUseClasses ? "true" : "false")")
        lines.append("")

        lines.append("[params]")
        lines.append("  author = \(encodeString(config.params.author))")
        lines.append("  description = \(encodeString(config.params.description))")
        lines.append("  tagline = \(encodeString(config.params.tagline))")
        lines.append("  github = \(encodeString(config.params.github))")
        lines.append("  twitter = \(encodeString(config.params.twitter))")
        lines.append("  facebook = \(encodeString(config.params.facebook))")
        lines.append("  linkedin = \(encodeString(config.params.linkedin))")
        lines.append("  instagram = \(encodeString(config.params.instagram))")
        lines.append("  tumblr = \(encodeString(config.params.tumblr))")
        lines.append("  stackoverflow = \(encodeString(config.params.stackoverflow))")
        lines.append("  bluesky = \(encodeString(config.params.bluesky))")
        lines.append("  email = \(encodeString(config.params.email))")
        lines.append("  url = \(encodeString(config.params.url))")
        lines.append("  keywords = \(encodeString(config.params.keywords))")
        lines.append("  favicon = \(encodeString(config.params.favicon))")
        lines.append("  avatar = \(encodeString(config.params.avatar))")
        lines.append("  headerIcon = \(encodeString(config.params.headerIcon))")
        lines.append("  location = \(encodeString(config.params.location))")
        lines.append("  userStatusEmoji = \(encodeString(config.params.userStatusEmoji))")
        lines.append("  rss = \(config.params.rss ? "true" : "false")")
        lines.append("  lastmod = \(config.params.lastmod ? "true" : "false")")
        lines.append("  enableGitalk = \(config.params.enableGitalk ? "true" : "false")")
        lines.append("  enableSearch = \(config.params.enableSearch ? "true" : "false")")
        lines.append("  math = \(config.params.math ? "true" : "false")")
        lines.append("  MathJax = \(config.params.mathJax ? "true" : "false")")
        lines.append("  custom_css = \(encodeArray(config.params.customCSS))")
        lines.append("  custom_js = \(encodeArray(config.params.customJS))")
        lines.append("")

        lines.append("  [params.gitalk]")
        lines.append("    clientID = \(encodeString(config.params.gitalk.clientID))")
        lines.append("    clientSecret = \(encodeString(config.params.gitalk.clientSecret))")
        lines.append("    repo = \(encodeString(config.params.gitalk.repo))")
        lines.append("    owner = \(encodeString(config.params.gitalk.owner))")
        lines.append("    admin = \(encodeString(config.params.gitalk.admin))")
        lines.append("    id = \(encodeString(config.params.gitalk.id))")
        lines.append("    labels = \(encodeString(config.params.gitalk.labels))")
        lines.append("    perPage = \(config.params.gitalk.perPage)")
        lines.append("    pagerDirection = \(encodeString(config.params.gitalk.pagerDirection))")
        lines.append("    createIssueManually = \(config.params.gitalk.createIssueManually ? "true" : "false")")
        lines.append("    distractionFreeMode = \(config.params.gitalk.distractionFreeMode ? "true" : "false")")
        lines.append("    proxy = \(encodeString(config.params.gitalk.proxy))")

        if !config.params.links.isEmpty {
            lines.append("")
            for link in config.params.links {
                lines.append("  [[params.links]]")
                lines.append("    title = \(encodeString(link.title))")
                lines.append("    href = \(encodeString(link.href))")
                if !link.icon.isEmpty {
                    lines.append("    icon = \(encodeString(link.icon))")
                }
            }
        }

        lines.append("")
        lines.append("[frontmatter]")
        if config.frontmatterTrackLastmod {
            lines.append("  lastmod = [\"lastmod\", \":fileModTime\", \":default\"]")
        } else {
            lines.append("  lastmod = [\":default\"]")
        }

        lines.append("")
        lines.append("[services]")
        lines.append("  [services.googleAnalytics]")
        lines.append("    ID = \(encodeString(config.googleAnalyticsID))")

        lines.append("")
        lines.append("[outputs]")
        lines.append("  home = \(encodeArray(config.outputsHome))")

        lines.append("")
        lines.append("[outputFormats.json]")
        lines.append("  mediaType = \(encodeString(config.outputFormatJSONMediaType))")
        lines.append("  baseName = \(encodeString(config.outputFormatJSONBaseName))")
        lines.append("  isPlainText = \(config.outputFormatJSONIsPlainText ? "true" : "false")")

        let output = lines.joined(separator: "\n") + "\n"
        try output.write(to: project.configURL, atomically: true, encoding: .utf8)
    }

    private func applyParam(key: String, value: String, to config: inout ThemeConfig) {
        switch key {
        case "author": config.params.author = parseString(value)
        case "description", "Description": config.params.description = parseString(value)
        case "tagline": config.params.tagline = parseString(value)
        case "github": config.params.github = parseString(value)
        case "twitter": config.params.twitter = parseString(value)
        case "facebook": config.params.facebook = parseString(value)
        case "linkedin": config.params.linkedin = parseString(value)
        case "instagram": config.params.instagram = parseString(value)
        case "tumblr": config.params.tumblr = parseString(value)
        case "stackoverflow": config.params.stackoverflow = parseString(value)
        case "bluesky": config.params.bluesky = parseString(value)
        case "email", "Email": config.params.email = parseString(value)
        case "url": config.params.url = parseString(value)
        case "keywords", "Keywords": config.params.keywords = parseString(value)
        case "favicon": config.params.favicon = parseString(value)
        case "avatar": config.params.avatar = parseString(value)
        case "headerIcon": config.params.headerIcon = parseString(value)
        case "location": config.params.location = parseString(value)
        case "userStatusEmoji": config.params.userStatusEmoji = parseString(value)
        case "rss": config.params.rss = parseBool(value)
        case "lastmod": config.params.lastmod = parseBool(value)
        case "enableGitalk": config.params.enableGitalk = parseBool(value)
        case "enableSearch": config.params.enableSearch = parseBool(value)
        case "math": config.params.math = parseBool(value)
        case "MathJax": config.params.mathJax = parseBool(value)
        case "custom_css": config.params.customCSS = parseStringArray(value)
        case "custom_js": config.params.customJS = parseStringArray(value)
        default: break
        }
    }

    private func applyGitalkParam(key: String, value: String, to config: inout ThemeConfig) {
        switch key {
        case "clientID": config.params.gitalk.clientID = parseString(value)
        case "clientSecret": config.params.gitalk.clientSecret = parseString(value)
        case "repo": config.params.gitalk.repo = parseString(value)
        case "owner": config.params.gitalk.owner = parseString(value)
        case "admin": config.params.gitalk.admin = parseString(value)
        case "id": config.params.gitalk.id = parseString(value)
        case "labels": config.params.gitalk.labels = parseString(value)
        case "perPage": config.params.gitalk.perPage = Int(parseString(value)) ?? 15
        case "pagerDirection": config.params.gitalk.pagerDirection = parseString(value)
        case "createIssueManually": config.params.gitalk.createIssueManually = parseBool(value)
        case "distractionFreeMode": config.params.gitalk.distractionFreeMode = parseBool(value)
        case "proxy": config.params.gitalk.proxy = parseString(value)
        default: break
        }
    }

    private func splitKeyValue(_ line: String) -> (String, String)? {
        guard let idx = line.firstIndex(of: "=") else {
            return nil
        }
        let key = line[..<idx].trimmingCharacters(in: .whitespaces)
        let value = line[line.index(after: idx)...].trimmingCharacters(in: .whitespaces)
        return (String(key), String(value))
    }

    private func stripInlineComment(_ value: String) -> String {
        var inSingle = false
        var inDouble = false

        for (idx, ch) in value.enumerated() {
            if ch == "\"" && !inSingle {
                inDouble.toggle()
            } else if ch == "'" && !inDouble {
                inSingle.toggle()
            } else if ch == "#" && !inSingle && !inDouble {
                let cut = value.index(value.startIndex, offsetBy: idx)
                return String(value[..<cut])
            }
        }

        return value
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

    private func parseStringArray(_ raw: String) -> [String] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("[") && trimmed.hasSuffix("]") else {
            return parseString(trimmed).isEmpty ? [] : [parseString(trimmed)]
        }

        let body = String(trimmed.dropFirst().dropLast())
        if body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }

        return body
            .split(separator: ",")
            .map { parseString(String($0)) }
            .filter { !$0.isEmpty }
    }

    private func encodeString(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    private func encodeArray(_ values: [String]) -> String {
        if values.isEmpty {
            return "[]"
        }
        return "[" + values.map { encodeString($0) }.joined(separator: ", ") + "]"
    }
}
