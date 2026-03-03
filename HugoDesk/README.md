# GitHubCollector (macOS)

一个 macOS 端 GitHub 软件抓取与本地软件库管理工具：

- 粘贴 GitHub 链接自动识别 `owner/repo`
- 抓取项目介绍（Repo + README）
- 生成中文介绍（支持 OpenAI 翻译，失败自动回退原文）
- 自动总结简介
- 抓取最新 Release 并优选安装包 (`.dmg/.pkg/.zip`)
- 下载到本地并按分类平铺展示，支持二次安装
- 支持批量链接导入（每行一个）、队列进度展示、失败重试
- 内置 OpenAI 翻译配置（可选，留空则不调用在线翻译）
- 新增粘贴按钮（剪贴板一键导入）
- 输入面板修复键盘输入与粘贴命中问题
- 设置抽屉中的 OpenAI 输入改为稳定可编辑文本区
- 首页新增搜索、抓取精度条、抓取实时日志
- 日志新增单文件下载进度、速度、下载链接
- 支持粘贴 `https://github.com/<username>?tab=stars` 批量抓取该用户星标仓库
- “纳入无安装包项目”已迁移到设置抽屉
- 无安装包项目可选择是否纳入，并自动归类到“无安装包项目”
- 卡片支持弹出详情窗口（含关闭按钮）：简介与 Release Notes 的中英对照
- 卡片支持展开删除面板（仅删记录 / 删除记录+文件）
- 设置集中到右侧设置抽屉，不再占用首页空间
- 设置会同步写入下载目录下的 `collector_settings.json`，切换目录时自动回填
- 新增 GitHub Token 配置（可选），用于提升 API 限流场景下的抓取稳定性
- 删除项目后即时从首页消失（防止目录扫描回流）
- 抓取内容自动清洗，剔除徽章/链接/图片 markdown 等无关文本
- 若抓到图片会下载到本地并在卡片与详情窗口显示
- 分类策略升级，默认回落到“通用工具”而非“未分类”
- 同步库会对比 GitHub 版本，发现新版本自动下载并归档旧版本到 `过期版本/<旧版本>/`
- 可自定义下载目录，并自动扫描该目录下已下载软件
- 新增项目会在项目目录写入 `README_COLLECTOR.md` 和 `project_info.json`
- 下载状态区按“当前下载 / 占用大小 / 当前保存路径”顺序展示，不显示累计流量

## 目录结构

- `Sources/GitHubCollector/GitHubCollectorApp.swift`: 应用入口
- `Sources/GitHubCollector/ContentView.swift`: UI
- `Sources/GitHubCollector/AppViewModel.swift`: 主流程编排
- `Sources/GitHubCollector/GitHubService.swift`: GitHub API 抓取
- `Sources/GitHubCollector/DownloadService.swift`: Release 下载
- `Sources/GitHubCollector/StorageService.swift`: 本地持久化
- `Sources/GitHubCollector/TextServices.swift`: 翻译、总结、分类
- `Sources/GitHubCollector/SettingsStore.swift`: 配置持久化
- `Sources/GitHubCollector/StorageService.swift`: 自定义路径、目录扫描、简介文件写入

## 运行

```bash
cd "/Users/sexyfeifan/Documents/New project/GitHubCollector"
mkdir -p .build-cache .clang-cache
SWIFTPM_ENABLE_PLUGINS=0 \
CLANG_MODULE_CACHE_PATH="$PWD/.clang-cache" \
swift build
swift run
```

如果你的机器出现 Swift SDK / Toolchain 版本不匹配，请在 Xcode 中统一 Command Line Tools 版本，或通过：

```bash
xcode-select -p
swift --version
```

确认工具链与系统 SDK 匹配后重新编译。

## 本地数据

应用会把下载文件和记录存到：

- `~/Downloads/GitHubCollector/<分类>/<项目>/...`
- `~/Downloads/GitHubCollector/records.json`

## 后续增强（建议）

- API Key 存储从 UserDefaults 升级为 Keychain
- 增加 GitHub Token（避免 API 限速）
- 增加“仅下载 macOS 资产”严格过滤
