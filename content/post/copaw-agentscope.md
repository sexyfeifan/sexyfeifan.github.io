+++
title = "CoPaw - AgentScope"
date = 2026-03-04T16:32:22Z
draft = false
pin = true
+++


```markdown
# CoPaw 项目文档

## 项目介绍

CoPaw 是一款个人助理型产品，可部署在用户自己的环境中。本页将介绍 CoPaw 的功能特性及快速上手指南。

### CoPaw 是什么？

CoPAW 是由 AgentScope 团队基于 AgentScope、AgentScope Runtime 与 ReMe 构建的个人助理产品，具有以下核心特性：

- **多通道对话**：支持钉钉、飞书、QQ、Discord、iMessage 等通讯平台
- **定时执行**：可按配置自动运行任务
- **模块化能力**：通过 Skills 实现功能扩展，内置：
  - 定时任务
  - PDF 与表单处理
  - Office 文档处理（Word/Excel/PPT）
  - 新闻摘要
  - 文件阅读等
- **数据安全**：所有数据存储在本地，不依赖第三方托管

### 使用方式

#### 1. 聊天软件对话
在支持的通讯平台中与 CoPaw 交互：
- 发送消息后 CoPaw 会在同一 app 内回复
- 功能由当前启用的 Skills 决定
- 单个 CoPaw 实例可同时接入多个通讯平台

#### 2. 定时自动执行
支持多种定时任务模式：
- 定时发送固定消息（如每日9点问候）
- 定时提问并转发回答（如每2小时查询待办事项）
- 定时执行自检/摘要任务

## 核心概念

- **频道**：对话的通讯平台（钉钉/飞书/QQ等），需在[频道配置]中设置
- **心跳**：定时自检机制，配置详见[心跳]
- **定时任务**：通过 CLI 或 API 管理的独立定时任务

## 快速开始

### 安装方式

提供五种安装方案：

1. **一键安装（推荐）**
   ```bash
   # macOS/Linux
   curl -fsSL https://copaw.agentscope.io/install.sh | bash

   # Windows CMD
   curl -fsSL https://copaw.agentscope.io/install.bat -o install.bat && install.bat

   # Windows PowerShell
   irm https://copaw.agentscope.io/install.ps1 | iex
   ```

2. **pip 安装**
   ```bash
   pip install copaw
   ```

3. **魔搭创空间**  
   一键云端部署，无需本地安装

4. **Docker**
   ```bash
   docker pull agentscope/copaw:latest
   docker run -p 8088:8088 -v copaw-data:/app/working agentscope/copaw:latest
   ```

5. **阿里云 ECS**  
   通过阿里云一键部署

### 初始化配置
```bash
# 快速初始化
copaw init --defaults

# 交互式初始化
copaw init
```

### 启动服务
```bash
copaw app
```
服务默认运行在 `127.0.0.1:8088`

## 控制台功能

访问 `http://127.0.0.1:8088/` 可使用以下功能：

| 功能模块       | 主要操作                     |
|----------------|----------------------------|
| 聊天           | 实时对话、会话管理          |
| 频道管理       | 启用/禁用通讯平台           |
| 定时任务       | 创建/管理自动化任务         |
| 技能管理       | 启用/禁用功能模块           |
| 模型配置       | 设置LLM提供商和模型         |
| 环境变量       | 管理API密钥等敏感信息       |

## Skills 管理

### 内置 Skills
| Skill名称          | 功能描述                     |
|--------------------|----------------------------|
| cron              | 定时任务管理                |
| file_reader       | 文本文件阅读                |
| news              | 新闻摘要                    |
| pdf/docx/pptx/xlsx| Office文档处理              |

### 自定义 Skill
1. 在 `~/.copaw/customized_skills/` 创建目录
2. 添加 `SKILL.md` 文件定义功能
3. 示例结构：
   ```markdown
   ---
   name: my_skill
   description: 自定义功能说明
   ---
   # 使用说明
   具体功能描述...
   ```

## 模型配置

支持三类模型提供商：

1. **云提供商**（需API Key）
   - ModelScope
   - DashScope
   - OpenAI等

2. **本地提供商**
   - llama.cpp
   - MLX（Apple Silicon）

3. **Ollama**  
   需先安装Ollama守护进程

配置路径：控制台 → 设置 → 模型

## 建议阅读顺序

1. [快速开始] → 基础部署
2. [控制台] → 功能预览
3. [频道配置] → 接入通讯平台
4. [Skills] → 功能扩展
```。
