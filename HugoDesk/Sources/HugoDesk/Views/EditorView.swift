import SwiftUI

struct EditorView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var tagsInput = ""
    @State private var categoriesInput = ""
    @State private var keywordsInput = ""

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
                }
            }
            .navigationTitle("文章")
            .toolbar {
                Button("新建文章") {
                    viewModel.createNewPost()
                    refreshInputsFromPost()
                }
            }
            .onChange(of: viewModel.selectedPostID) { _ in
                viewModel.loadSelectedPost()
                refreshInputsFromPost()
            }
        } detail: {
            VStack(spacing: 14) {
                ModernCard(title: "文章元数据", subtitle: "Front Matter") {
                    VStack(spacing: 10) {
                        HStack {
                            TextField("标题", text: $viewModel.editorPost.title)
                                .font(.title3)
                            DatePicker("", selection: $viewModel.editorPost.date, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                            Toggle("草稿", isOn: $viewModel.editorPost.draft)
                                .toggleStyle(.switch)
                        }

                        HStack {
                            TextField("摘要", text: $viewModel.editorPost.summary)
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

                if viewModel.editorMode == .richText {
                    ModernCard(title: "富文本快捷工具", subtitle: "v1 为 Markdown 快捷插入") {
                        HStack {
                            Button("H1") { insertMarkdownPrefix("# ") }
                            Button("加粗") { wrapSelection("**", "**") }
                            Button("行内代码") { wrapSelection("`", "`") }
                            Button("引用") { insertMarkdownPrefix("> ") }
                            Spacer()
                            Text("后续可升级为完整富文本编辑器。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                ModernCard(title: "正文编辑", subtitle: "左侧编辑 / 右侧预览") {
                    HSplitView {
                        TextEditor(text: $viewModel.editorPost.body)
                            .font(.system(.body, design: .monospaced))
                            .padding(8)

                        ScrollView {
                            VStack(alignment: .leading) {
                                Text("预览")
                                    .font(.headline)
                                if let parsed = try? AttributedString(markdown: viewModel.editorPost.body) {
                                    Text(parsed)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    Text(viewModel.editorPost.body)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding()
                        }
                    }
                    .frame(minHeight: 380)
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
                    Spacer()
                    Text(viewModel.editorPost.fileURL.lastPathComponent)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .padding()
            .onAppear {
                refreshInputsFromPost()
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

    private func insertMarkdownPrefix(_ prefix: String) {
        viewModel.editorPost.body += viewModel.editorPost.body.hasSuffix("\n") ? "\(prefix)" : "\n\(prefix)"
    }

    private func wrapSelection(_ left: String, _ right: String) {
        viewModel.editorPost.body += "\(left)text\(right)"
    }
}
