import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var vm = AppViewModel()
    @State private var detailRecord: RepoRecord?
    @State private var showSettingsDrawer = false
    @State private var showLogSheet = false

    private let columns = [
        GridItem(.adaptive(minimum: 340), spacing: 16)
    ]

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                inputPanel

                if vm.isLoading {
                    ProgressView().controlSize(.small)
                }

                if !vm.statusMessage.isEmpty {
                    Text(vm.statusMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if !vm.errorMessage.isEmpty {
                    Text(vm.errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                }

                if !vm.queueItems.isEmpty {
                    queuePanel
                }

                categoryPanel

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(vm.pagedRecords) { record in
                            RepoCard(
                                record: record,
                                openFolder: { vm.openInFinder(record) },
                                openInstaller: { vm.openInstaller(record) },
                                openSource: { vm.openSourcePage(record) },
                                retranslate: { vm.retranslateRecord(record) },
                                openDetail: { detailRecord = record },
                                deleteRecord: { deleteFiles in
                                    vm.deleteRecord(record, deleteFiles: deleteFiles)
                                }
                            )
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 10)
                }

                HStack {
                    Text("第 \(vm.currentPage) / \(vm.totalPages) 页")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("上一页") { vm.prevPage() }
                        .buttonStyle(.bordered)
                        .disabled(vm.currentPage <= 1)
                    Button("下一页") { vm.nextPage() }
                        .buttonStyle(.bordered)
                        .disabled(vm.currentPage >= vm.totalPages)
                }
            }
            .padding(16)
            .frame(minWidth: 1180, minHeight: 780)

            if showSettingsDrawer {
                Divider()
                settingsDrawer
                    .frame(width: 380)
                    .transition(.move(edge: .trailing))
            }
        }
        .sheet(item: $detailRecord) { record in
            RepoDetailView(record: record) {
                detailRecord = nil
            }
            .frame(minWidth: 820, minHeight: 620)
        }
        .sheet(isPresented: $showLogSheet) {
            LogDetailView(logs: vm.realtimeLogs) {
                showLogSheet = false
            }
            .frame(minWidth: 920, minHeight: 620)
        }
        .onChange(of: vm.searchQuery) { _ in
            vm.resetPageToFirst()
        }
        .onChange(of: vm.selectedCategory) { _ in
            vm.resetPageToFirst()
        }
        .onChange(of: vm.records.count) { _ in
            vm.ensureValidPage()
        }
        .animation(.easeInOut(duration: 0.2), value: showSettingsDrawer)
    }

    private var inputPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("导入 GitHub 链接（单个或批量，每行一个）")
                    .font(.headline)
                Spacer()
                Button("清空") {
                    vm.clearInputURLs()
                }
                .buttonStyle(.bordered)
                Button("输入链接") {
                    vm.promptInputLinks()
                }
                .buttonStyle(.borderedProminent)
                Button("设置") {
                    showSettingsDrawer.toggle()
                }
                .buttonStyle(.bordered)
            }

            NativeInputField(
                text: $vm.inputURL,
                placeholder: "粘贴一个或多个 GitHub 链接（可用空格分隔）"
            )
            .frame(height: 26)

            HStack(spacing: 10) {
                Button("粘贴") { vm.pasteFromClipboard() }
                    .buttonStyle(.borderedProminent)

                Button("开始") { vm.startCrawl() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!vm.canStartCrawl)

                Button("暂停") { vm.pauseCrawl() }
                    .buttonStyle(.bordered)
                    .disabled(!vm.canPauseCrawl)

                Button("停止") { vm.stopCrawl() }
                    .buttonStyle(.bordered)
                    .disabled(!vm.canStopCrawl)

                Button("重试失败项") { vm.retryFailedImports() }
                    .buttonStyle(.bordered)
                    .disabled(vm.failedURLs.isEmpty || vm.crawlState == .running)

                Button("同步库") { vm.syncLibrary() }
                    .buttonStyle(.bordered)
                    .disabled(vm.isLoading)
            }

            HStack(spacing: 8) {
                Text("搜索项目")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("按项目名、分类、简介关键词搜索", text: $vm.searchQuery)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("抓取精度")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(vm.fetchPrecision * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: vm.fetchPrecision, total: 1.0)
            }

            GroupBox("下载与存储状态") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text("当前下载")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .leading)
                        Text(vm.downloadTrafficText)
                            .font(.caption)
                            .lineLimit(2)
                    }
                    HStack(alignment: .top) {
                        Text("占用大小")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .leading)
                        Text(vm.storageUsageText)
                            .font(.caption)
                    }
                    HStack(alignment: .top) {
                        Text("当前保存路径")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .leading)
                        Text(vm.currentSavePathText)
                            .font(.caption2)
                            .lineLimit(2)
                            .truncationMode(.middle)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("实时日志") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Spacer()
                        Button("展开日志") { showLogSheet = true }
                            .buttonStyle(.bordered)
                    }

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(vm.realtimeLogs.suffix(80).enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .font(.system(size: 11, design: .monospaced))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(4)
                    }
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var settingsDrawer: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("设置")
                    .font(.title3).bold()
                Spacer()
                Button("收起") {
                    showSettingsDrawer = false
                }
                .buttonStyle(.bordered)
            }

            Text("OpenAI")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $vm.openAIKey)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                            .allowsHitTesting(false)
                    )
                HStack {
                    Button("粘贴 Key") { vm.pasteAPIKeyFromClipboard() }
                        .buttonStyle(.bordered)
                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Base URL")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $vm.openAIBaseURL)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(height: 34)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                            .allowsHitTesting(false)
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Model")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $vm.openAIModel)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(height: 34)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                            .allowsHitTesting(false)
                    )
            }

            Divider()

            Text("GitHub")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Token")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $vm.githubToken)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                            .allowsHitTesting(false)
                    )
                HStack {
                    Button("粘贴 Token") { vm.pasteGitHubTokenFromClipboard() }
                        .buttonStyle(.bordered)
                    Spacer()
                }
            }

            Divider()

            Text("下载与导入")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("失败重试次数")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Stepper(value: $vm.retryCount, in: 1...5) {
                    Text("\(vm.retryCount) 次")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("软件下载路径")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $vm.downloadRootPath)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(height: 34)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                            .allowsHitTesting(false)
                    )
                Button("选择路径") { vm.chooseStorageDirectory() }
                    .buttonStyle(.bordered)
                Text("当前生效路径：\(vm.activeBaseDirPath)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Toggle("纳入无安装包项目", isOn: $vm.includeNoPackageProjects)
                .toggleStyle(.switch)

            HStack {
                Spacer()
                Button("保存并扫描") { vm.saveSettings() }
                    .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding(12)
    }

    private var queuePanel: some View {
        GroupBox("任务队列") {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(vm.queueItems) { item in
                        HStack {
                            Text(item.status.rawValue)
                                .font(.caption)
                                .foregroundStyle(color(for: item.status))
                                .frame(width: 45, alignment: .leading)
                            Text(item.url)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer(minLength: 8)
                            Text(item.detail)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(4)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .clipped()
        }
    }

    private func color(for status: AppViewModel.QueueItem.Status) -> Color {
        switch status {
        case .pending: return .secondary
        case .running: return .orange
        case .success: return .green
        case .failed: return .red
        }
    }

    private var categoryPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(vm.categories, id: \.self) { c in
                            Button(c) {
                                vm.selectedCategory = c
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(vm.selectedCategory == c ? .accentColor : .gray)
                        }
                    }
                }
                Button("刷新列表") {
                    vm.reloadRecords()
                }
                .buttonStyle(.bordered)
            }

            if !vm.failedProjects.isEmpty {
                GroupBox("失败项目汇总（可跳转检查）") {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(vm.failedProjects) { item in
                                HStack {
                                    Text(item.name)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Spacer(minLength: 8)
                                    Button("打开 GitHub") {
                                        vm.openGitHubURL(item.url)
                                    }
                                    .buttonStyle(.bordered)
                                }
                                Text(item.url)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                Text(item.reason)
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                                    .lineLimit(1)
                                Divider()
                            }
                        }
                        .padding(4)
                    }
                    .frame(height: 120)
                }
            }
        }
    }
}

private struct RepoCard: View {
    let record: RepoRecord
    let openFolder: () -> Void
    let openInstaller: () -> Void
    let openSource: () -> Void
    let retranslate: () -> Void
    let openDetail: () -> Void
    let deleteRecord: (Bool) -> Void

    @State private var showDeletePanel = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.projectName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(record.releaseTag)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(record.fullName)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(record.summaryZH)
                .font(.subheadline)
                .lineLimit(2)

            if !record.previewImagePath.isEmpty {
                LocalPreviewImage(path: record.previewImagePath)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack(spacing: 12) {
                Label(record.category, systemImage: "square.grid.2x2")
                Label("★ \(record.stars)", systemImage: "star")
                Label(record.language, systemImage: "curlybraces")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text("文件：\(record.releaseAssetName)")
                .font(.caption)
                .lineLimit(1)

            HStack {
                Button("详情窗口", action: openDetail)
                Button("GitHub", action: openSource)
                Button("打开目录", action: openFolder)
                Button(record.hasDownloadAsset ? "安装/解压" : "查看简介", action: openInstaller)
                Button("重新翻译", action: retranslate)
            }
            .buttonStyle(.bordered)

            DisclosureGroup("删除项目", isExpanded: $showDeletePanel) {
                HStack {
                    Button("仅删除记录") { deleteRecord(false) }
                        .buttonStyle(.bordered)
                    Button("删除记录+本地文件") { deleteRecord(true) }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(!record.hasDownloadAsset && record.sourceCodePath.isEmpty)
                }
                .padding(.top, 4)
            }
            .font(.caption)

            if !record.localPath.isEmpty {
                Text(record.localPath)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if !record.sourceCodePath.isEmpty {
                Text("源码：\(record.sourceCodePath)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        )
    }
}

private struct RepoDetailView: View {
    let record: RepoRecord
    let onClose: () -> Void
    @State private var renderMarkdown = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.projectName)
                        .font(.title2).bold()
                    Text(record.fullName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text("版本：\(record.releaseTag)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("关闭") {
                        onClose()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            HStack(spacing: 14) {
                Label(record.category, systemImage: "square.grid.2x2")
                Label("★ \(record.stars)", systemImage: "star")
                Label(record.language, systemImage: "curlybraces")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack {
                Picker("显示模式", selection: $renderMarkdown) {
                    Text("渲染").tag(true)
                    Text("原文").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
                Spacer()
            }

            if let sourceURL = URL(string: record.sourceURL), !record.sourceURL.isEmpty {
                Link(destination: sourceURL) {
                    Label("打开 GitHub 项目页", systemImage: "link")
                }
                .font(.caption)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if !record.previewImagePath.isEmpty {
                        LocalPreviewImage(path: record.previewImagePath)
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    section(
                        "简介（中文）",
                        record.descriptionZH.isEmpty ? "暂无中文简介" : record.descriptionZH,
                        renderMarkdown: renderMarkdown
                    )
                    section(
                        "搭建教程",
                        record.setupGuideZH.isEmpty ? "暂无可提取的搭建教程" : record.setupGuideZH,
                        renderMarkdown: renderMarkdown
                    )
                    section(
                        "更新说明",
                        record.releaseNotesZH.isEmpty ? "暂无中文更新说明" : record.releaseNotesZH,
                        renderMarkdown: renderMarkdown
                    )
                    section(
                        "README.md",
                        originalReadmeBundle,
                        renderMarkdown: renderMarkdown
                    )
                }
                .padding(.top, 6)
            }
        }
        .padding(16)
    }

    private var originalReadmeBundle: String {
        let readme = record.descriptionEN.trimmingCharacters(in: .whitespacesAndNewlines)
        let notes = record.releaseNotesEN.trimmingCharacters(in: .whitespacesAndNewlines)
        if notes.isEmpty {
            return readme.isEmpty ? "No README content" : readme
        }
        if readme.isEmpty {
            return "## Release Notes\n\n\(notes)"
        }
        return "\(readme)\n\n---\n\n## Release Notes\n\n\(notes)"
    }

    private func section(_ title: String, _ text: String, renderMarkdown: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            if renderMarkdown {
                StyledMarkdownView(markdown: text)
                    .frame(height: 280)
            } else {
                ScrollView(.horizontal) {
                    Text(text)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            }
            Divider()
        }
    }
}

private struct LocalPreviewImage: View {
    let path: String

    var body: some View {
        if let image = NSImage(contentsOfFile: path) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            EmptyView()
        }
    }
}

private struct LogDetailView: View {
    let logs: [String]
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("实时日志详情")
                    .font(.title3).bold()
                Spacer()
                Button("关闭") { onClose() }
                    .buttonStyle(.borderedProminent)
            }

            ScrollView([.vertical, .horizontal]) {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(logs.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }
                .padding(8)
            }
            .background(Color(NSColor.textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
    }
}

private struct MarkdownRenderText: View {
    let text: String

    var body: some View {
        if let attr = try? AttributedString(markdown: text) {
            Text(attr)
                .font(.body)
                .textSelection(.enabled)
        } else {
            Text(text)
                .font(.body)
                .textSelection(.enabled)
        }
    }
}

private struct StyledMarkdownView: NSViewRepresentable {
    let markdown: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        let web = WKWebView(frame: .zero, configuration: config)
        web.setValue(false, forKey: "drawsBackground")
        return web
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(htmlTemplate(from: markdown), baseURL: nil)
    }

    private func htmlTemplate(from markdown: String) -> String {
        let htmlBody = markdownToHTML(markdown)
        return """
        <!doctype html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        :root {
          --ink: #0f172a;
          --muted: #64748b;
          --border: #e2e8f0;
          --code-bg: #f8fafc;
          --accent: #0369a1;
        }
        body {
          margin: 0;
          padding: 4px 2px 8px 2px;
          background: transparent;
          color: var(--ink);
          font-family: "SF Pro Text", "PingFang SC", -apple-system, sans-serif;
          line-height: 1.68;
          font-size: 14px;
        }
        h1,h2,h3,h4 {
          color: #0f172a;
          margin: 16px 0 8px;
          line-height: 1.3;
          letter-spacing: 0.2px;
        }
        h1 { font-size: 22px; }
        h2 { font-size: 18px; border-bottom: 1px solid var(--border); padding-bottom: 6px; }
        h3 { font-size: 16px; }
        p { margin: 8px 0; color: var(--ink); }
        a { color: var(--accent); text-decoration: none; }
        a:hover { text-decoration: underline; }
        code {
          background: #f1f5f9;
          border: 1px solid var(--border);
          border-radius: 6px;
          padding: 1px 6px;
          color: #0f172a;
          font-family: "SF Mono", Menlo, monospace;
          font-size: 12px;
        }
        pre {
          margin: 12px 0;
          padding: 12px;
          background: var(--code-bg);
          border: 1px solid var(--border);
          border-radius: 6px;
          overflow: auto;
        }
        pre code {
          background: transparent;
          border: none;
          padding: 0;
          color: #1e293b;
          font-size: 12px;
          line-height: 1.6;
        }
        blockquote {
          margin: 12px 0;
          padding: 10px 12px;
          border-left: 4px solid var(--accent);
          background: #f8fafc;
          color: #334155;
          border-radius: 0 6px 6px 0;
        }
        ul, ol { margin: 8px 0 8px 18px; }
        li { margin: 4px 0; }
        table {
          width: 100%;
          border-collapse: collapse;
          margin: 12px 0;
          border: 1px solid var(--border);
          border-radius: 8px;
          overflow: hidden;
        }
        th, td {
          border: 1px solid var(--border);
          padding: 8px 10px;
          text-align: left;
          vertical-align: top;
        }
        th { background: #f8fafc; color: #0f172a; }
        hr { border: none; border-top: 1px solid var(--border); margin: 16px 0; }
        </style>
        </head>
        <body>\(htmlBody)</body>
        </html>
        """
    }

    private func markdownToHTML(_ source: String) -> String {
        var s = escapeHTML(source)

        s = s.replacingOccurrences(of: "\r\n", with: "\n")

        // fenced code blocks
        if let regex = try? NSRegularExpression(pattern: "```([\\s\\S]*?)```") {
            s = regex.stringByReplacingMatches(in: s, range: NSRange(location: 0, length: s.utf16.count), withTemplate: "<pre><code>$1</code></pre>")
        }

        // headings
        let headingRules: [(String, String)] = [
            ("(?m)^######\\s+(.*)$", "<h4>$1</h4>"),
            ("(?m)^#####\\s+(.*)$", "<h4>$1</h4>"),
            ("(?m)^####\\s+(.*)$", "<h3>$1</h3>"),
            ("(?m)^###\\s+(.*)$", "<h3>$1</h3>"),
            ("(?m)^##\\s+(.*)$", "<h2>$1</h2>"),
            ("(?m)^#\\s+(.*)$", "<h1>$1</h1>")
        ]
        for (pat, tpl) in headingRules {
            if let regex = try? NSRegularExpression(pattern: pat) {
                s = regex.stringByReplacingMatches(in: s, range: NSRange(location: 0, length: s.utf16.count), withTemplate: tpl)
            }
        }

        // blockquote
        if let regex = try? NSRegularExpression(pattern: "(?m)^>\\s?(.*)$") {
            s = regex.stringByReplacingMatches(in: s, range: NSRange(location: 0, length: s.utf16.count), withTemplate: "<blockquote>$1</blockquote>")
        }

        // inline styles
        s = replaceRegex(s, "\\*\\*(.*?)\\*\\*", "<strong>$1</strong>")
        s = replaceRegex(s, "\\*(.*?)\\*", "<em>$1</em>")
        s = replaceRegex(s, "`([^`]+)`", "<code>$1</code>")
        s = replaceRegex(s, "\\[([^\\]]+)\\]\\(([^\\)]+)\\)", "<a href=\"$2\">$1</a>")

        // unordered list
        s = replaceRegex(s, "(?m)^[-\\*]\\s+(.*)$", "<li>$1</li>")
        s = s.replacingOccurrences(of: "(?s)(<li>.*?</li>\\n?)+", with: { block in
            "<ul>\(block)</ul>"
        })

        // horizontal rule
        s = replaceRegex(s, "(?m)^---+$", "<hr/>")

        // paragraph wrapping (skip existing block tags)
        let lines = s.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var out: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                out.append("")
                continue
            }
            let lower = trimmed.lowercased()
            let startsWithBlock = ["<h", "<pre", "<ul", "<ol", "<li", "<blockquote", "<hr", "<table", "<tr", "<th", "<td", "</"]
                .contains(where: { lower.hasPrefix($0) })
            if startsWithBlock {
                out.append(trimmed)
            } else {
                out.append("<p>\(trimmed)</p>")
            }
        }
        return out.joined(separator: "\n")
    }

    private func replaceRegex(_ input: String, _ pattern: String, _ template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return input }
        return regex.stringByReplacingMatches(in: input, range: NSRange(location: 0, length: input.utf16.count), withTemplate: template)
    }

    private func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

private extension String {
    func replacingOccurrences(of pattern: String, with transformer: (String) -> String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else { return self }
        let ns = self as NSString
        let matches = regex.matches(in: self, range: NSRange(location: 0, length: ns.length))
        if matches.isEmpty { return self }
        var result = self
        for m in matches.reversed() {
            let part = (result as NSString).substring(with: m.range)
            let replaced = transformer(part)
            result = (result as NSString).replacingCharacters(in: m.range, with: replaced)
        }
        return result
    }
}
