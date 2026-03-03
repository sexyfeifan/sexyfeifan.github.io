import AppKit
import SwiftUI

struct MarkdownPreviewView: View {
    let markdown: String
    let project: BlogProject
    let postFileURL: URL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(parsedSegments) { segment in
                    switch segment.kind {
                    case let .text(content):
                        if let parsed = try? AttributedString(markdown: content) {
                            Text(parsed)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(content)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    case let .image(alt, link):
                        imageView(alt: alt, link: link)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
    }

    @ViewBuilder
    private func imageView(alt: String, link: String) -> some View {
        if let localURL = resolveLocalImageURL(link) {
            if let image = NSImage(contentsOf: localURL) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 520, alignment: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                if !alt.isEmpty {
                    Text(alt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("[图片无法加载] \(link)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        } else if let remoteURL = URL(string: link), remoteURL.scheme?.hasPrefix("http") == true {
            AsyncImage(url: remoteURL) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 520, alignment: .leading)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    Text("[图片加载失败] \(link)")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                case .empty:
                    ProgressView()
                @unknown default:
                    EmptyView()
                }
            }
            if !alt.isEmpty {
                Text(alt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("[未知图片地址] \(link)")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }

    private func resolveLocalImageURL(_ rawLink: String) -> URL? {
        let link = cleanedMarkdownLink(rawLink)
        if link.hasPrefix("http://") || link.hasPrefix("https://") || link.hasPrefix("data:") {
            return nil
        }

        if link.hasPrefix("/") {
            if link.hasPrefix("/images/") {
                let rel = String(link.dropFirst())
                return project.rootURL
                    .appendingPathComponent("static", isDirectory: true)
                    .appendingPathComponent(rel)
            }
            if link.hasPrefix("/static/") {
                return project.rootURL.appendingPathComponent(String(link.dropFirst()))
            }
            return URL(fileURLWithPath: link)
        }

        if link.hasPrefix("~/") {
            let expanded = NSString(string: link).expandingTildeInPath
            return URL(fileURLWithPath: expanded)
        }

        if link.hasPrefix("file://") {
            return URL(string: link)
        }

        return postFileURL.deletingLastPathComponent().appendingPathComponent(link)
    }

    private func cleanedMarkdownLink(_ rawLink: String) -> String {
        var link = rawLink.trimmingCharacters(in: .whitespacesAndNewlines)
        link = link.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        if link.hasPrefix("<"), link.hasSuffix(">"), link.count >= 2 {
            link.removeFirst()
            link.removeLast()
        }

        if let first = link.firstIndex(of: " ") {
            link = String(link[..<first])
        }

        let decoded = link.removingPercentEncoding ?? link
        return decoded.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedSegments: [PreviewSegment] {
        let pattern = #"!\[([^\]]*)\]\(([^)]+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [PreviewSegment(kind: .text(markdown))]
        }

        let ns = markdown as NSString
        let matches = regex.matches(in: markdown, range: NSRange(location: 0, length: ns.length))
        if matches.isEmpty {
            return [PreviewSegment(kind: .text(markdown))]
        }

        var segments: [PreviewSegment] = []
        var cursor = 0

        for match in matches {
            let range = match.range
            if range.location > cursor {
                let part = ns.substring(with: NSRange(location: cursor, length: range.location - cursor))
                if !part.isEmpty {
                    segments.append(PreviewSegment(kind: .text(part)))
                }
            }

            if match.numberOfRanges >= 3 {
                let alt = ns.substring(with: match.range(at: 1))
                let link = ns.substring(with: match.range(at: 2))
                segments.append(PreviewSegment(kind: .image(alt: alt, link: link)))
            }

            cursor = range.location + range.length
        }

        if cursor < ns.length {
            let tail = ns.substring(from: cursor)
            if !tail.isEmpty {
                segments.append(PreviewSegment(kind: .text(tail)))
            }
        }

        return segments
    }
}

private struct PreviewSegment: Identifiable {
    enum Kind {
        case text(String)
        case image(alt: String, link: String)
    }

    let id = UUID()
    let kind: Kind
}
