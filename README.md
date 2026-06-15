# 🏝️ 动森风格 Astro 博客

配合 [NookDesk](https://github.com/sexyfeifan/NookDesk) 桌面管理软件使用的 Astro 博客模板。

## ✨ 特性

- 🎨 动森风格 UI 设计
- 📝 Markdown + Frontmatter 文章格式
- 📚 归档页面
- 🏷️ 分类/标签系统
- 🔍 搜索功能
- 🌙 暗色模式
- 🚀 项目展示
- 🤝 友链页面
- 📱 响应式设计
- ⚡ Astro 构建，快速加载

## 🚀 快速开始

### 方式一：使用 NookDesk（推荐）

1. 下载安装 [NookDesk](https://github.com/sexyfeifan/NookDesk/releases)
2. 在引导流程中选择「从 GitHub 克隆」
3. 输入本仓库地址
4. 开始写作！

### 方式二：手动部署

1. Fork 本仓库
2. 进入 Settings → Pages，将 Source 改为 GitHub Actions
3. 克隆到本地：
   ```bash
   git clone https://github.com/你的用户名/你的仓库名.git
   cd 你的仓库名
   ```
4. 安装依赖：
   ```bash
   npm install
   ```
5. 本地预览：
   ```bash
   npm run dev
   ```
6. 提交并推送：
   ```bash
   git add .
   git commit -m "初始化博客"
   git push
   ```
7. 等待 GitHub Actions 完成部署
8. 访问 `https://你的用户名.github.io`

## 📝 文章格式

文章使用 Markdown 格式，存储在 `src/content/blog/` 目录下：

```markdown
---
title: "文章标题"
description: "文章描述"
pubDate: 2026-04-18
category: "分类"
tags: ["标签1", "标签2"]
cover: "🏝️"
color: "app-blue"
readTime: "6 分钟"
draft: false
---

## 章节标题

文章内容...
```

### Frontmatter 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| title | string | 文章标题（必填） |
| description | string | 文章描述（必填） |
| pubDate | date | 发布日期（必填） |
| category | string | 分类（默认：未分类） |
| tags | string[] | 标签列表 |
| cover | string | 封面 emoji |
| color | string | 卡片颜色 |
| readTime | string | 阅读时间 |
| draft | boolean | 是否为草稿 |
| pin | boolean | 是否置顶 |

### 可用颜色

- app-pink
- purple
- app-blue
- app-yellow
- app-orange
- app-teal
- app-green
- app-red
- lime-green
- yellow-green
- brown
- warm-peach-pink

## 🛠️ 技术栈

- **框架**: Astro
- **UI**: React + animal-island-ui
- **样式**: CSS Variables
- **部署**: GitHub Pages + GitHub Actions

## 📄 许可证

MIT License
