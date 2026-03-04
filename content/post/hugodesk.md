+++
title = "HugoDesk"
date = 2026-03-04T06:37:16Z
draft = false
summary = "HugoDesk 🚀"
pin = true
+++

```markdown
# HugoDesk 🚀

HugoDesk 是一款面向 macOS 的 Hugo 博客桌面客户端（SwiftUI），目标是让你在图形界面中完成 **写作 → 构建 → 检测 → 推送 → GitHub Pages 发布** 的完整流程，减少对命令行的依赖。

## 开发背景 🤔

Hugo 本身非常强大，但日常发布通常要在终端里反复执行 `hugo`、`git pull --rebase`、`git push`、排查冲突和部署状态。

HugoDesk 的定位就是：

- ✍️ 把文章编辑和元数据维护放到一个界面
- 🧱 把构建、同步、推送过程做成可追踪的按钮流程
- 🔎 把故障定位信息统一沉淀到日志窗口
- 🌐 把 GitHub Pages 的关键部署链路（Workflow）内置为一键操作

## 核心功能 ✨

### 内容创作
- 📝 Markdown 写作：支持右键工具、选区工具、常用 Markdown 模板
- 🖼️ 图片处理：导入图片到 `static/images/uploads`，并自动修正文章图片链接
- 🧾 元数据辅助：标题可由文件名生成、摘要可由正文提取

### 智能辅助
- 🧠 AI 能力：可配置 API 地址/Key/模型，在写作页执行 Markdown 排版与错误排障建议

### 发布管理
- 🔐 安全推送：支持 GitHub Token，推送和检测可在无交互终端下执行
- 🧪 发布检测：检查 Git/Hugo、远程可达性、dry-run 推送、Pages Workflow 完整性
- ⚙️ 配置包机制：项目根目录 `.hugodesk.local.json` 自动读写（不进入 Git）

## 界面结构 🧭

| 页面模块    | 主要功能                                                                 |
|-------------|--------------------------------------------------------------------------|
| 项目        | 博客根目录、Git 目标、远程与凭据、项目配置包                             |
| 写作        | 文章列表、Front Matter、文本工具、编辑器/预览切换                        |
| 主题设置    | 主题参数编辑与保存                                                       |
| AI 设置     | AI Base URL / API Key / Model 配置                                       |
| 发布        | 同步、检测、Workflow 生成、提交推送、日志中心                            |

## 标准发布流程 📦

1. **项目准备**
   - 在 `项目` 页确认博客根目录（需包含 `hugo.toml`、`content`、`themes`）
   - 填写仓库地址、Token、Workflow 名称

2. **工作流配置**
   ```bash
   点击 `一键生成 Pages Workflow`（首次或缺失时）
   点击 `同步远程`，解决潜在 non-fast-forward 风险
   ```

3. **部署验证**
   - 点击 `一键检测推送与部署`，确认链路健康
   - 点击 `提交并推送`

> 注意：当前策略固定为 **GitHub Actions 部署**，且 `hugo.toml` 会随项目一起推送

## 开发构建 🛠️

### 运行调试
```bash
cd /Users/sexyfeifan/Library/Mobile\ Documents/com~apple~CloudDocs/Code/HugoDesk
swift run
```

### 发布构建
```bash
swift build -c release
```

## 文件规范 📁

- `latest/`：存放当前最新可用产物（`.app` / `.dmg` / `source.zip`）
- `HugoDeskArchive/versions/<version>/`：历史版本归档目录

## 安全机制 🔒

- 🔑 Token 通过系统钥匙串与本地配置包协同保存
- 📜 发布日志不会明文输出 Token
- 📄 `.hugodesk.local.json` 默认不进入 Git 版本控制

## 版本更新 🆕

### v0.3.9 重点优化
围绕"去掉过度设置、聚焦 Hugo 正确发布路径"进行重构：

- 🎯 发布策略固化：强制使用 GitHub Actions（移除"仅推送源码"模式）
- ⚡ 配置精简：始终包含 `hugo.toml`，移除排除选项
- 🖥️ 界面优化：
  - 发布控制台仅保留核心按钮
  - 强化 `一键生成 Pages Workflow` 功能
  - 精简项目页快捷操作
- 🧹 代码清理：移除无入口逻辑，降低维护复杂度

### 历史版本
- `v0.3.8`：新增 Pages Workflow 一键生成与部署链路检测
- `v0.3.7`：修复目录定位、编辑器工具与预览图片路径等关键问题
```
