import AppKit
import SwiftUI

struct EditorView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var tagsInput = ""
    @State private var categoriesInput = ""
    @State private var keywordsInput = ""
    @State private var imageAltText = ""
    @State private var showDeleteConfirm = false
    @State private var editorSelection = NSRange(location: 0, length: 0)
    @State private var showingPreview = false
    @State private var imageInsertMode: ImageInsertMode = .cursor

    private let toolGroups: [(id: String, title: String, symbol: String, actions: [MarkdownAction])] = [
        ("heading", "标题", "textformat.size", [.heading1, .heading2, .heading3, .heading4, .heading5, .heading6]),
        ("style", "文本样式", "character.textbox", [.bold, .italic, .strike, .inlineCode]),
        ("list", "列表与结构", "list.bullet.rectangle", [.bulletList, .orderedList, .taskList, .quote]),
        ("insert", "插入", "plus.rectangle.on.rectangle", [.link, .image, .codeBlock, .table, .details, .footnote, .divider])
    ]

    private let selectionTools: [MarkdownAction] = [
        .heading1, .heading2, .heading3,
        .bold, .italic, .strike, .inlineCode,
        .link, .quote, .bulletList, .orderedList, .taskList, .codeBlock
    ]

    var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedPostID) {
                ForEach(viewModel.posts) { post in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.title.isEmpty ? post.fileName : post.title)
                            .font(.headline)
                        Text(post.fileName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(post.id)
                    .contextMenu {
                        Button("删除这篇文章", role: .destructive) {
                            selectAndDelete(post)
                        }
                    }
                }
            }
            .navigationTitle("文章")
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
            .toolbar {
                Button("快速新建") {
                    viewModel.newPostTitle = ""
                    viewModel.newPostFileName = "new-post.md"
                }
                Button("删除当前") {
                    showDeleteConfirm = true
                }
            }
            .onChange(of: viewModel.selectedPostID) { _ in
                viewModel.loadSelectedPost()
                editorSelection = NSRange(location: 0, length: 0)
                showingPreview = false
                refreshInputsFromPost()
            }
        } detail: {
            ScrollView {
                VStack(spacing: 14) {
                    ModernCard(title: "新建文章", subtitle: "支持自定义文件名（默认拼音 slug）") {
                        VStack(spacing: 10) {
                            HStack {
                                TextField("文章标题（例如：你好世界）", text: $viewModel.newPostTitle)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: viewModel.newPostTitle) { _ in
                                        viewModel.updateSuggestedFileName()
                                    }
                                Button("按标题生成文件名") {
                                    viewModel.updateSuggestedFileName()
                                }
                            }
                            HStack {
                                TextField("文件名（例如：hello-world.md）", text: $viewModel.newPostFileName)
                                    .textFieldStyle(.roundedBorder)
                                Button("创建文章") {
                                    viewModel.createPostFromForm()
                                    editorSelection = NSRange(location: 0, length: 0)
                                    showingPreview = false
                                    refreshInputsFromPost()
                                }
                            }
                            Text("建议文件名使用英文或拼音并用 - 连接。若重名会自动追加序号。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    ModernCard(title: "文章元数据", subtitle: "Front Matter") {
                        VStack(spacing: 10) {
                            HStack {
                                TextField("标题", text: $viewModel.editorPost.title)
                                    .font(.title3)
                                Button("获取标题") {
                                    viewModel.updateTitleFromFileName()
                                }
                                DatePicker("", selection: $viewModel.editorPost.date, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                                Toggle("草稿", isOn: $viewModel.editorPost.draft)
                                    .toggleStyle(.switch)
                            }

                            HStack {
                                TextField("摘要", text: $viewModel.editorPost.summary)
                                Button("获取摘要") {
                                    viewModel.updateSummaryFromBody()
                                }
                                Picker("编辑模式", selection: $viewModel.editorMode) {
                                    ForEach(EditorMode.allCases) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 220)
                            }

                            HStack {
                                TextField("标签（逗号分隔）", text: $tagsInput)
                                TextField("分类（逗号分隔）", text: $categoriesInput)
                                TextField("关键词（逗号分隔）", text: $keywordsInput)
                            }

                            HStack {
                                Toggle("置顶", isOn: $viewModel.editorPost.pin)
                                Toggle("KaTeX", isOn: $viewModel.editorPost.math)
                                Toggle("MathJax", isOn: $viewModel.editorPost.mathJax)
                                Toggle("私有", isOn: $viewModel.editorPost.isPrivate)
                                Toggle("可搜索", isOn: $viewModel.editorPost.searchable)
                            }
                        }
                    }

                    ModernCard(title: "文本工具", subtitle: "下拉分类工具 + 选区工具 + AI 排版") {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                ForEach(toolGroups, id: \.id) { group in
                                    Menu {
                                        ForEach(group.actions) { action in
                                            Button(action.title) {
                                                applyMarkdownAction(action)
                                            }
                                        }
                                    } label: {
                                        Label(group.title, systemImage: group.symbol)
                                    }
                                    .menuStyle(.borderlessButton)
                                    .buttonStyle(.bordered)
                                }
                            }

                            HStack {
                                if editorSelection.length > 0 {
                                    Menu {
                                        ForEach(selectionTools) { action in
                                            Button(action.title) {
                                                applyMarkdownAction(action)
                                            }
                                        }
                                    } label: {
                                        Label("选区工具（\(editorSelection.length) 字符）", systemImage: "selection.pin.in.out")
                                    }
                                    .menuStyle(.borderlessButton)
                                    .buttonStyle(.borderedProminent)
                                }

                                Button(editorSelection.length > 0 ? "AI 排版选区" : "AI 排版全文") {
                                    let range = editorSelection.length > 0 ? editorSelection : nil
                                    viewModel.formatPostWithAI(selectionRange: range) { next in
                                        editorSelection = next
                                    }
                                }
                                .buttonStyle(.borderedProminent)

                                Spacer()
                            }

                            HStack {
                                TextField("图片 alt 文本", text: $imageAltText)
                                    .textFieldStyle(.roundedBorder)
                                Picker("插入位置", selection: $imageInsertMode) {
                                    ForEach(ImageInsertMode.allCases) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 160)

                                Button("上传并插入图片") {
                                    if let imageURL = pickImage() {
                                        let next = viewModel.importImageIntoPost(
                                            from: imageURL,
                                            altText: imageAltText,
                                            insertionRange: targetImageInsertionRange()
                                        )
                                        editorSelection = next
                                    }
                                }
                            }
                            Text("图片会复制到 static/images/uploads，并在当前光标或选区位置插入 Markdown 图片语法。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    ModernCard(title: "正文编辑", subtitle: "默认编辑区，通过按钮切换预览") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Button(showingPreview ? "返回编辑区" : "显示预览区") {
                                    showingPreview.toggle()
                                }
                                .buttonStyle(.bordered)

                                Spacer()
                            }

                            if showingPreview {
                                MarkdownPreviewView(
                                    markdown: viewModel.editorPost.body,
                                    project: viewModel.project,
                                    postFileURL: viewModel.editorPost.fileURL
                                )
                                .frame(minHeight: 540)
                                .background(Color.black.opacity(0.03))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                MarkdownTextEditor(
                                    text: $viewModel.editorPost.body,
                                    selection: $editorSelection,
                                    onMenuAction: applyMarkdownAction
                                )
                                .frame(minHeight: 540)
                                .background(Color.black.opacity(0.03))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }

                    HStack {
                        Button("保存文章") {
                            applyInputsToPost()
                            viewModel.saveCurrentPost()
                        }
                        Button("保存并构建预览") {
                            applyInputsToPost()
                            viewModel.saveCurrentPost()
                            viewModel.runBuild()
                        }
                        Button("删除当前文章", role: .destructive) {
                            showDeleteConfirm = true
                        }
                        Spacer()
                        Text(viewModel.editorPost.fileURL.lastPathComponent)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .onAppear {
                refreshInputsFromPost()
            }
            .alert("确认删除这篇文章？", isPresented: $showDeleteConfirm) {
                Button("删除", role: .destructive) {
                    viewModel.deleteCurrentPost()
                    editorSelection = NSRange(location: 0, length: 0)
                    showingPreview = false
                    refreshInputsFromPost()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text(viewModel.editorPost.fileName)
            }
        }
    }

    private func refreshInputsFromPost() {
        tagsInput = viewModel.editorPost.tags.joined(separator: ", ")
        categoriesInput = viewModel.editorPost.categories.joined(separator: ", ")
        keywordsInput = viewModel.editorPost.keywords.joined(separator: ", ")
    }

    private func applyInputsToPost() {
        viewModel.editorPost.tags = splitCSV(tagsInput)
        viewModel.editorPost.categories = splitCSV(categoriesInput)
        viewModel.editorPost.keywords = splitCSV(keywordsInput)
    }

    private func splitCSV(_ input: String) -> [String] {
        input.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func applyMarkdownAction(_ action: MarkdownAction) {
        let result = MarkdownEditing.apply(action: action, to: viewModel.editorPost.body, selection: editorSelection)
        viewModel.editorPost.body = result.text
        editorSelection = result.selection
    }

    private func targetImageInsertionRange() -> NSRange? {
        switch imageInsertMode {
        case .cursor:
            return NSRange(location: editorSelection.location, length: 0)
        case .selection:
            return editorSelection
        case .appendToEnd:
            return NSRange(location: (viewModel.editorPost.body as NSString).length, length: 0)
        }
    }

    private func pickImage() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.png, .jpeg, .gif, .heic, .tiff, .webP]
        panel.prompt = "选择"
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func selectAndDelete(_ post: BlogPost) {
        viewModel.selectedPostID = post.id
        viewModel.loadSelectedPost()
        viewModel.deleteCurrentPost()
        editorSelection = NSRange(location: 0, length: 0)
        showingPreview = false
        refreshInputsFromPost()
    }
}

private enum ImageInsertMode: String, CaseIterable, Identifiable {
    case cursor = "光标位置"
    case selection = "替换选区"
    case appendToEnd = "追加到文末"

    var id: String { rawValue }
}
