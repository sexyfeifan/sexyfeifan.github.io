import SwiftUI

struct ThemeSettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var customCSSInput = ""
    @State private var customJSInput = ""
    @State private var outputsInput = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ModernCard(title: "站点基础") {
                    VStack(spacing: 10) {
                        SettingRow(key: "baseURL", title: "站点地址", helpText: "网站最终访问地址，影响 canonical、RSS、分享链接。", scope: "全站") {
                            TextField("https://example.com/", text: $viewModel.config.baseURL)
                                .textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "languageCode", title: "语言代码", helpText: "站点主语言，例如 zh-cn、en-us。", scope: "全站") {
                            TextField("zh-cn", text: $viewModel.config.languageCode)
                                .textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "title", title: "站点标题", helpText: "浏览器标题、Open Graph 等位置会使用。", scope: "全站") {
                            TextField("站点标题", text: $viewModel.config.title)
                                .textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "theme", title: "主题名称", helpText: "Hugo 使用的主题目录名。", scope: "渲染") {
                            TextField("github-style", text: $viewModel.config.theme)
                                .textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "pygmentsCodeFences", title: "代码块高亮", helpText: "开启 fenced code block 语法高亮。", scope: "渲染") {
                            Toggle("", isOn: $viewModel.config.pygmentsCodeFences)
                                .labelsHidden()
                        }
                        SettingRow(key: "pygmentsUseClasses", title: "高亮样式类", helpText: "使用 CSS class 形式输出高亮样式。", scope: "渲染") {
                            Toggle("", isOn: $viewModel.config.pygmentsUseClasses)
                                .labelsHidden()
                        }
                    }
                }

                ModernCard(title: "个人资料与社交") {
                    VStack(spacing: 10) {
                        SettingRow(key: "params.author", title: "作者名", helpText: "侧栏头像旁与文章头部显示。", scope: "首页/文章") {
                            TextField("", text: $viewModel.config.params.author).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.description", title: "个人简介", helpText: "侧栏简介与社交卡片摘要。", scope: "首页/SEO") {
                            TextField("", text: $viewModel.config.params.description).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.tagline", title: "SEO 标语", helpText: "用于首页 meta description（部分模板）。", scope: "SEO") {
                            TextField("", text: $viewModel.config.params.tagline).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.github", title: "GitHub 用户名", helpText: "生成 GitHub 社交入口。", scope: "侧栏") {
                            TextField("", text: $viewModel.config.params.github).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.twitter", title: "X/Twitter 用户名", helpText: "生成 Twitter 社交入口。", scope: "侧栏") {
                            TextField("", text: $viewModel.config.params.twitter).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.facebook", title: "Facebook 用户名", helpText: "生成 Facebook 社交入口。", scope: "侧栏") {
                            TextField("", text: $viewModel.config.params.facebook).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.linkedin", title: "LinkedIn ID", helpText: "生成 LinkedIn 社交入口。", scope: "侧栏") {
                            TextField("", text: $viewModel.config.params.linkedin).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.instagram", title: "Instagram 用户名", helpText: "生成 Instagram 社交入口。", scope: "侧栏") {
                            TextField("", text: $viewModel.config.params.instagram).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.tumblr", title: "Tumblr 名称", helpText: "生成 Tumblr 社交入口。", scope: "侧栏") {
                            TextField("", text: $viewModel.config.params.tumblr).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.stackoverflow", title: "StackOverflow ID", helpText: "生成 StackOverflow 社交入口。", scope: "侧栏") {
                            TextField("", text: $viewModel.config.params.stackoverflow).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.bluesky", title: "Bluesky Handle", helpText: "生成 Bluesky 社交入口。", scope: "侧栏") {
                            TextField("", text: $viewModel.config.params.bluesky).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.email", title: "邮箱", helpText: "侧栏显示并生成 mailto 链接。", scope: "侧栏") {
                            TextField("", text: $viewModel.config.params.email).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.url", title: "个人链接", helpText: "侧栏个人主页链接。", scope: "侧栏") {
                            TextField("", text: $viewModel.config.params.url).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.keywords", title: "默认关键词", helpText: "文章没有关键词时使用此项作为 fallback。", scope: "SEO") {
                            TextField("例如：hugo, blog", text: $viewModel.config.params.keywords).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.location", title: "地理位置", helpText: "侧栏位置字段。", scope: "侧栏") {
                            TextField("", text: $viewModel.config.params.location).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.userStatusEmoji", title: "状态 Emoji", helpText: "头像角标显示。", scope: "侧栏") {
                            TextField("", text: $viewModel.config.params.userStatusEmoji).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.avatar", title: "头像路径", helpText: "作者头像图片路径。", scope: "首页/文章/SEO") {
                            TextField("/images/avatar.png", text: $viewModel.config.params.avatar).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.headerIcon", title: "顶部图标", helpText: "顶部导航中的站点图标。", scope: "导航") {
                            TextField("/images/github-mark-white.png", text: $viewModel.config.params.headerIcon).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.favicon", title: "网站图标", helpText: "浏览器标签页 favicon。", scope: "全站") {
                            TextField("/images/favicon.ico", text: $viewModel.config.params.favicon).textFieldStyle(.roundedBorder)
                        }
                    }
                }

                ModernCard(title: "功能开关") {
                    VStack(spacing: 10) {
                        SettingRow(key: "params.rss", title: "启用 RSS", helpText: "显示 RSS 入口，并输出 RSS 订阅内容。", scope: "分发") {
                            Toggle("", isOn: $viewModel.config.params.rss).labelsHidden()
                        }
                        SettingRow(key: "params.lastmod", title: "显示最后修改时间", helpText: "文章页显示 Modified 时间。", scope: "文章页") {
                            Toggle("", isOn: $viewModel.config.params.lastmod).labelsHidden()
                        }
                        SettingRow(key: "params.enableSearch", title: "启用本地搜索", helpText: "开启后会使用 index.json 与 fuse.js。", scope: "搜索") {
                            Toggle("", isOn: $viewModel.config.params.enableSearch).labelsHidden()
                        }
                        SettingRow(key: "params.enableGitalk", title: "启用 Gitalk 评论", helpText: "文章底部加载 Gitalk 评论组件。", scope: "评论") {
                            Toggle("", isOn: $viewModel.config.params.enableGitalk).labelsHidden()
                        }
                        SettingRow(key: "params.math", title: "启用 KaTeX", helpText: "全站默认启用 KaTeX 数学渲染。", scope: "文章渲染") {
                            Toggle("", isOn: $viewModel.config.params.math).labelsHidden()
                        }
                        SettingRow(key: "params.MathJax", title: "启用 MathJax", helpText: "全站默认启用 MathJax（与 KaTeX 可同时存在但不建议）。", scope: "文章渲染") {
                            Toggle("", isOn: $viewModel.config.params.mathJax).labelsHidden()
                        }
                        SettingRow(key: "frontmatter.lastmod", title: "根据文件更新时间追踪 lastmod", helpText: "使用 :fileModTime 自动生成文章最后更新时间。", scope: "文章元数据") {
                            Toggle("", isOn: $viewModel.config.frontmatterTrackLastmod).labelsHidden()
                        }
                        SettingRow(key: "services.googleAnalytics.ID", title: "Google Analytics ID", helpText: "生产环境 HUGO_ENV=production 时生效。", scope: "统计") {
                            TextField("", text: $viewModel.config.googleAnalyticsID).textFieldStyle(.roundedBorder)
                        }
                    }
                }

                ModernCard(title: "搜索输出格式") {
                    VStack(spacing: 10) {
                        SettingRow(key: "outputs.home", title: "首页输出类型", helpText: "要开启本地搜索，通常需要包含 html 与 json。", scope: "搜索") {
                            TextField("html, json", text: $outputsInput).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "outputFormats.json.mediaType", title: "JSON 媒体类型", helpText: "一般保持 application/json。", scope: "搜索") {
                            TextField("application/json", text: $viewModel.config.outputFormatJSONMediaType).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "outputFormats.json.baseName", title: "JSON 文件名", helpText: "默认 index，对应 /index.json。", scope: "搜索") {
                            TextField("index", text: $viewModel.config.outputFormatJSONBaseName).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "outputFormats.json.isPlainText", title: "JSON 纯文本输出", helpText: "通常保持 false。", scope: "搜索") {
                            Toggle("", isOn: $viewModel.config.outputFormatJSONIsPlainText).labelsHidden()
                        }
                    }
                }

                ModernCard(title: "自定义资源") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("params.custom_css（每行一个路径）")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .help("添加后会在 head 中按顺序注入样式文件。")
                        TextEditor(text: $customCSSInput)
                            .font(.system(.body, design: .monospaced))
                            .frame(height: 90)
                            .padding(6)
                            .background(Color.black.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        Text("params.custom_js（每行一个路径）")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .help("添加后会在 head 中按顺序注入脚本文件。")
                        TextEditor(text: $customJSInput)
                            .font(.system(.body, design: .monospaced))
                            .frame(height: 90)
                            .padding(6)
                            .background(Color.black.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                ModernCard(title: "Gitalk 评论配置") {
                    VStack(spacing: 10) {
                        SettingRow(key: "params.gitalk.clientID", title: "OAuth Client ID", helpText: "Gitalk GitHub OAuth 应用 ID。", scope: "评论") {
                            TextField("", text: $viewModel.config.params.gitalk.clientID).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.gitalk.clientSecret", title: "OAuth Client Secret", helpText: "Gitalk GitHub OAuth 密钥。", scope: "评论") {
                            TextField("", text: $viewModel.config.params.gitalk.clientSecret).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.gitalk.repo", title: "评论仓库", helpText: "存放 issue 评论的仓库名。", scope: "评论") {
                            TextField("", text: $viewModel.config.params.gitalk.repo).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.gitalk.owner", title: "仓库所有者", helpText: "GitHub 用户名或组织名。", scope: "评论") {
                            TextField("", text: $viewModel.config.params.gitalk.owner).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.gitalk.admin", title: "管理员", helpText: "管理员用户名（当前主题模板仍以 owner 为主）。", scope: "评论") {
                            TextField("", text: $viewModel.config.params.gitalk.admin).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.gitalk.id", title: "Issue ID 规则", helpText: "通常为 location.pathname，保证文章唯一映射。", scope: "评论") {
                            TextField("location.pathname", text: $viewModel.config.params.gitalk.id).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.gitalk.labels", title: "Issue 标签", helpText: "新建评论 issue 时默认标签。", scope: "评论") {
                            TextField("gitalk", text: $viewModel.config.params.gitalk.labels).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.gitalk.perPage", title: "每页评论数", helpText: "评论分页数量，最大 100。", scope: "评论") {
                            Stepper(value: $viewModel.config.params.gitalk.perPage, in: 1...100) {
                                Text("\(viewModel.config.params.gitalk.perPage)")
                            }
                        }
                        SettingRow(key: "params.gitalk.pagerDirection", title: "评论排序", helpText: "last 或 first。", scope: "评论") {
                            TextField("last / first", text: $viewModel.config.params.gitalk.pagerDirection).textFieldStyle(.roundedBorder)
                        }
                        SettingRow(key: "params.gitalk.createIssueManually", title: "手动创建 Issue", helpText: "true 表示管理员登录后自动创建 issue。", scope: "评论") {
                            Toggle("", isOn: $viewModel.config.params.gitalk.createIssueManually).labelsHidden()
                        }
                        SettingRow(key: "params.gitalk.distractionFreeMode", title: "无干扰模式", helpText: "评论输入框快捷提交模式。", scope: "评论") {
                            Toggle("", isOn: $viewModel.config.params.gitalk.distractionFreeMode).labelsHidden()
                        }
                        SettingRow(key: "params.gitalk.proxy", title: "代理地址", helpText: "GitHub OAuth 代理地址。", scope: "评论") {
                            TextField("", text: $viewModel.config.params.gitalk.proxy).textFieldStyle(.roundedBorder)
                        }
                    }
                }

                ModernCard(title: "自定义外链（params.links）") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(viewModel.config.params.links.enumerated()), id: \.element.id) { index, _ in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("链接 \(index + 1)")
                                        .font(.headline)
                                    ScopeBadge(text: "侧栏")
                                    Spacer()
                                    Button("删除") {
                                        viewModel.config.params.links.remove(at: index)
                                    }
                                }
                                TextField("title", text: bindingForLink(index, \.title))
                                    .textFieldStyle(.roundedBorder)
                                TextField("href", text: bindingForLink(index, \.href))
                                    .textFieldStyle(.roundedBorder)
                                TextField("icon（可选）", text: bindingForLink(index, \.icon))
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding(10)
                            .background(Color.black.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        Button("新增链接") {
                            viewModel.config.params.links.append(ThemeLink())
                        }
                    }
                }

                HStack {
                    Button("从 hugo.toml 重新读取") {
                        viewModel.loadAll()
                        syncTextInputs()
                    }
                    Button("保存主题配置") {
                        applyTextInputs()
                        viewModel.saveThemeConfig()
                    }
                    Spacer()
                }
                .padding(.top, 2)
            }
            .padding()
        }
        .onAppear {
            syncTextInputs()
        }
    }

    private func bindingForLink(_ index: Int, _ keyPath: WritableKeyPath<ThemeLink, String>) -> Binding<String> {
        Binding {
            guard viewModel.config.params.links.indices.contains(index) else { return "" }
            return viewModel.config.params.links[index][keyPath: keyPath]
        } set: { newValue in
            guard viewModel.config.params.links.indices.contains(index) else { return }
            viewModel.config.params.links[index][keyPath: keyPath] = newValue
        }
    }

    private func syncTextInputs() {
        customCSSInput = viewModel.config.params.customCSS.joined(separator: "\n")
        customJSInput = viewModel.config.params.customJS.joined(separator: "\n")
        outputsInput = viewModel.config.outputsHome.joined(separator: ", ")
    }

    private func applyTextInputs() {
        viewModel.config.params.customCSS = splitLines(customCSSInput)
        viewModel.config.params.customJS = splitLines(customJSInput)
        viewModel.config.outputsHome = outputsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func splitLines(_ input: String) -> [String] {
        input.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
