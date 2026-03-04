+++
title = "CoPaw - 协作个人智能体工作站"
date = 2026-03-04T17:15:28Z
draft = false
+++

# CoPaw — 协作个人智能体工作站

## 项目概述
CoPaw 是一个基于 **AgentScope 框架**构建的开源 AI 助手平台，具有以下核心特性：
- 支持本地或云端灵活部署
- 可无缝连接常用聊天应用
- 支持运行本地大语言模型
- 提供完整的隐私控制能力

> "一只温暖的小'爪'，随时准备帮助你" —— 项目以高亲和力的设计理念，为用户提供智能化辅助服务。

## 快速安装

### 命令行安装
```
curl -fsSL https://copaw.agentscope.io/install.sh | bash
```

### PIP 安装
```bash
pip install copaw
```

### Docker 部署
```bash
docker run -p 8088:8088 agentscope/copaw:latest
```

## 架构优势
- **开源开放**：基于 AgentScope 框架构建
- **隐私优先**：数据完全由用户掌控
- **多模态支持**：兼容各类聊天应用接口
- 多智能体调度机制
- 可扩展的插件体系

> 注意：默认服务端口为 8088，可通过 `-p` 参数自定义映射端口
