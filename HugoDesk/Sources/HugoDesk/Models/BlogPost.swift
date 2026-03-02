import Foundation

struct BlogPost: Identifiable {
    var fileURL: URL
    var title: String
    var date: Date
    var draft: Bool
    var summary: String
    var tags: [String]
    var categories: [String]
    var pin: Bool
    var math: Bool
    var mathJax: Bool
    var isPrivate: Bool
    var searchable: Bool
    var cover: String
    var author: String
    var keywords: [String]
    var body: String

    var id: String {
        fileURL.path
    }

    var fileName: String {
        fileURL.lastPathComponent
    }

    static func empty(in contentURL: URL) -> BlogPost {
        let file = contentURL.appendingPathComponent("new-post.md")
        return BlogPost(
            fileURL: file,
            title: "",
            date: Date(),
            draft: true,
            summary: "",
            tags: [],
            categories: [],
            pin: false,
            math: false,
            mathJax: false,
            isPrivate: false,
            searchable: true,
            cover: "",
            author: "",
            keywords: [],
            body: ""
        )
    }
}
