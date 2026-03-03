import AppKit
import SwiftUI

enum MarkdownAction: String, CaseIterable, Identifiable {
    case heading1
    case bold
    case italic
    case strike
    case inlineCode
    case codeBlock
    case quote
    case bulletList
    case orderedList
    case taskList
    case heading2
    case heading3
    case heading4
    case heading5
    case heading6
    case link
    case image
    case footnote
    case table
    case details
    case divider

    var id: String { rawValue }

    var title: String {
        switch self {
        case .heading1: return "H1"
        case .bold: return "加粗"
        case .italic: return "斜体"
        case .strike: return "删除线"
        case .inlineCode: return "行内代码"
        case .codeBlock: return "代码块"
        case .quote: return "引用"
        case .bulletList: return "无序列表"
        case .orderedList: return "有序列表"
        case .taskList: return "任务列表"
        case .heading2: return "H2"
        case .heading3: return "H3"
        case .heading4: return "H4"
        case .heading5: return "H5"
        case .heading6: return "H6"
        case .link: return "链接"
        case .image: return "图片"
        case .footnote: return "脚注"
        case .table: return "表格"
        case .details: return "折叠块"
        case .divider: return "分割线"
        }
    }

    var toolbarSymbol: String {
        switch self {
        case .heading1: return "textformat.size"
        case .bold: return "bold"
        case .italic: return "italic"
        case .strike: return "strikethrough"
        case .inlineCode: return "chevron.left.forwardslash.chevron.right"
        case .codeBlock: return "terminal"
        case .quote: return "text.quote"
        case .bulletList: return "list.bullet"
        case .orderedList: return "list.number"
        case .taskList: return "checklist"
        case .heading2: return "textformat.size"
        case .heading3: return "textformat"
        case .heading4: return "textformat.size"
        case .heading5: return "textformat.size"
        case .heading6: return "textformat.size"
        case .link: return "link"
        case .image: return "photo"
        case .footnote: return "note.text"
        case .table: return "tablecells"
        case .details: return "rectangle.compress.vertical"
        case .divider: return "minus"
        }
    }
}

struct MarkdownEditResult {
    var text: String
    var selection: NSRange
}

enum MarkdownEditing {
    static func apply(action: MarkdownAction, to original: String, selection rawSelection: NSRange) -> MarkdownEditResult {
        let selection = clamped(rawSelection, in: original)

        switch action {
        case .heading1:
            return prefixLines(in: original, selection: selection) { line, _ in
                line.isEmpty ? "# " : "# \(line)"
            }
        case .bold:
            return wrapSelection(in: original, selection: selection, prefix: "**", suffix: "**", placeholder: "加粗文本")
        case .italic:
            return wrapSelection(in: original, selection: selection, prefix: "*", suffix: "*", placeholder: "斜体文本")
        case .strike:
            return wrapSelection(in: original, selection: selection, prefix: "~~", suffix: "~~", placeholder: "删除线")
        case .inlineCode:
            return wrapSelection(in: original, selection: selection, prefix: "`", suffix: "`", placeholder: "code")
        case .codeBlock:
            return codeBlock(in: original, selection: selection)
        case .quote:
            return prefixLines(in: original, selection: selection) { line, _ in
                line.isEmpty ? "> " : "> \(line)"
            }
        case .bulletList:
            return prefixLines(in: original, selection: selection) { line, _ in
                line.isEmpty ? "- " : "- \(line)"
            }
        case .orderedList:
            return prefixLines(in: original, selection: selection) { line, idx in
                line.isEmpty ? "\(idx + 1). " : "\(idx + 1). \(line)"
            }
        case .taskList:
            return prefixLines(in: original, selection: selection) { line, _ in
                line.isEmpty ? "- [ ] " : "- [ ] \(line)"
            }
        case .heading2:
            return prefixLines(in: original, selection: selection) { line, _ in
                line.isEmpty ? "## " : "## \(line)"
            }
        case .heading3:
            return prefixLines(in: original, selection: selection) { line, _ in
                line.isEmpty ? "### " : "### \(line)"
            }
        case .heading4:
            return prefixLines(in: original, selection: selection) { line, _ in
                line.isEmpty ? "#### " : "#### \(line)"
            }
        case .heading5:
            return prefixLines(in: original, selection: selection) { line, _ in
                line.isEmpty ? "##### " : "##### \(line)"
            }
        case .heading6:
            return prefixLines(in: original, selection: selection) { line, _ in
                line.isEmpty ? "###### " : "###### \(line)"
            }
        case .link:
            return link(in: original, selection: selection)
        case .image:
            return insertSnippet(
                in: original,
                selection: selection,
                snippet: "![图片描述](/images/uploads/your-image.png)\n"
            )
        case .footnote:
            return insertSnippet(
                in: original,
                selection: selection,
                snippet: "[^1]\n\n[^1]: 脚注内容\n"
            )
        case .table:
            return insertSnippet(
                in: original,
                selection: selection,
                snippet: "| 列1 | 列2 |\n| --- | --- |\n| 内容1 | 内容2 |\n"
            )
        case .details:
            return insertSnippet(
                in: original,
                selection: selection,
                snippet: "<details>\n<summary>点击展开</summary>\n\n内容\n\n</details>\n"
            )
        case .divider:
            return insertSnippet(in: original, selection: selection, snippet: "\n---\n")
        }
    }

    static func insertText(_ text: String, into original: String, selection rawSelection: NSRange) -> MarkdownEditResult {
        let selection = clamped(rawSelection, in: original)
        return replace(in: original, range: selection, with: text, caretOffsetFromInsertStart: (text as NSString).length)
    }

    private static func codeBlock(in original: String, selection: NSRange) -> MarkdownEditResult {
        if selection.length > 0 {
            let ns = original as NSString
            let picked = ns.substring(with: selection)
            let wrapped = "```\n\(picked)\n```"
            return replace(in: original, range: selection, with: wrapped, caretOffsetFromInsertStart: (wrapped as NSString).length)
        }

        let snippet = "```\ncode\n```"
        let insert = replace(in: original, range: selection, with: snippet, caretOffsetFromInsertStart: 4)
        return MarkdownEditResult(text: insert.text, selection: NSRange(location: selection.location + 4, length: 4))
    }

    private static func link(in original: String, selection: NSRange) -> MarkdownEditResult {
        let ns = original as NSString
        let selected = selection.length > 0 ? ns.substring(with: selection) : "链接标题"
        let replacement = "[\(selected)](https://example.com)"
        let urlStart = ("[\(selected)](" as NSString).length
        let urlLength = ("https://example.com" as NSString).length
        let replaced = replace(in: original, range: selection, with: replacement, caretOffsetFromInsertStart: urlStart)
        return MarkdownEditResult(
            text: replaced.text,
            selection: NSRange(location: selection.location + urlStart, length: urlLength)
        )
    }

    private static func wrapSelection(
        in original: String,
        selection: NSRange,
        prefix: String,
        suffix: String,
        placeholder: String
    ) -> MarkdownEditResult {
        let ns = original as NSString
        if selection.length > 0 {
            let selected = ns.substring(with: selection)
            let wrapped = "\(prefix)\(selected)\(suffix)"
            return replace(in: original, range: selection, with: wrapped, caretOffsetFromInsertStart: (wrapped as NSString).length)
        }

        let inserted = "\(prefix)\(placeholder)\(suffix)"
        let prefixLen = (prefix as NSString).length
        let placeholderLen = (placeholder as NSString).length
        let result = replace(in: original, range: selection, with: inserted, caretOffsetFromInsertStart: prefixLen)
        return MarkdownEditResult(
            text: result.text,
            selection: NSRange(location: selection.location + prefixLen, length: placeholderLen)
        )
    }

    private static func prefixLines(
        in original: String,
        selection: NSRange,
        transform: (String, Int) -> String
    ) -> MarkdownEditResult {
        let ns = original as NSString
        let target = selection.length > 0 ? selection : NSRange(location: selection.location, length: 0)
        let lineRange = ns.lineRange(for: target)
        let selected = ns.substring(with: lineRange)
        let hasTrailingNewline = selected.hasSuffix("\n")
        var parts = selected.components(separatedBy: "\n")
        if hasTrailingNewline, !parts.isEmpty {
            parts.removeLast()
        }

        let mapped = parts.enumerated().map { idx, line in
            transform(line, idx)
        }

        var replacement = mapped.joined(separator: "\n")
        if hasTrailingNewline {
            replacement += "\n"
        }

        let caret = (replacement as NSString).length
        return replace(in: original, range: lineRange, with: replacement, caretOffsetFromInsertStart: caret)
    }

    private static func insertSnippet(in original: String, selection: NSRange, snippet: String) -> MarkdownEditResult {
        replace(in: original, range: selection, with: snippet, caretOffsetFromInsertStart: (snippet as NSString).length)
    }

    private static func replace(
        in original: String,
        range: NSRange,
        with replacement: String,
        caretOffsetFromInsertStart: Int
    ) -> MarkdownEditResult {
        let ns = NSMutableString(string: original)
        ns.replaceCharacters(in: range, with: replacement)
        let newLocation = range.location + max(0, caretOffsetFromInsertStart)
        return MarkdownEditResult(text: ns as String, selection: NSRange(location: newLocation, length: 0))
    }

    private static func clamped(_ range: NSRange, in text: String) -> NSRange {
        let length = (text as NSString).length
        let location = max(0, min(range.location, length))
        let end = max(location, min(range.location + range.length, length))
        return NSRange(location: location, length: end - location)
    }
}

@MainActor
private protocol MarkdownMenuActionHandling: AnyObject {
    func handleMenuAction(_ action: MarkdownAction)
}

private final class ContextMenuTextView: NSTextView {
    weak var markdownActionHandler: MarkdownMenuActionHandling?
    private static let menuPrefix = "hugodesk.markdown."

    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = super.menu(for: event) ?? NSMenu(title: "")
        menu.items.removeAll { item in
            item.identifier?.rawValue.hasPrefix(Self.menuPrefix) == true
        }

        if !menu.items.isEmpty {
            menu.addItem(NSMenuItem.separator())
        }

        let contextActions: [MarkdownAction] = [
            .heading1, .heading2, .heading3, .bold, .italic, .strike, .inlineCode,
            .link, .image, .quote, .bulletList, .orderedList, .taskList, .codeBlock, .footnote
        ]

        for action in contextActions {
            let item = NSMenuItem(title: action.title, action: #selector(triggerMarkdownAction(_:)), keyEquivalent: "")
            item.target = self
            item.identifier = NSUserInterfaceItemIdentifier(Self.menuPrefix + action.rawValue)
            item.representedObject = action.rawValue
            menu.addItem(item)
        }
        return menu
    }

    @objc private func triggerMarkdownAction(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let action = MarkdownAction(rawValue: raw) else {
            return
        }
        markdownActionHandler?.handleMenuAction(action)
    }
}

struct MarkdownTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var selection: NSRange
    var onMenuAction: (MarkdownAction) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = ContextMenuTextView(frame: .zero)
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.string = text
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 10, height: 10)
        textView.markdownActionHandler = context.coordinator
        textView.setSelectedRange(selection)

        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.documentView = textView

        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? ContextMenuTextView else { return }
        context.coordinator.parent = self

        if textView.string != text {
            context.coordinator.isSyncingFromSwiftUI = true
            textView.string = text
            context.coordinator.isSyncingFromSwiftUI = false
        }

        let currentSelection = textView.selectedRange()
        if currentSelection.location != selection.location || currentSelection.length != selection.length {
            context.coordinator.isSyncingFromSwiftUI = true
            textView.setSelectedRange(selection)
            context.coordinator.isSyncingFromSwiftUI = false
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate, MarkdownMenuActionHandling {
        var parent: MarkdownTextEditor
        weak var textView: NSTextView?
        var isSyncingFromSwiftUI = false

        init(parent: MarkdownTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isSyncingFromSwiftUI,
                  let textView = notification.object as? NSTextView else {
                return
            }
            parent.text = textView.string
            parent.selection = textView.selectedRange()
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard !isSyncingFromSwiftUI,
                  let textView = notification.object as? NSTextView else {
                return
            }
            parent.selection = textView.selectedRange()
        }

        func handleMenuAction(_ action: MarkdownAction) {
            parent.onMenuAction(action)
        }
    }
}
