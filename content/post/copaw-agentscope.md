+++
title = "CoPaw - AgentScope"
date = 2026-03-04T16:32:22Z
draft = true
+++


项目介绍
本页说明 CoPaw 是什么、能做什么、以及如何按文档一步步上手。

CoPaw 是什么？
CoPAW 是一款个人助理型产品，部署在你自己的环境中。

多通道对话 — 通过钉钉、飞书、QQ、Discord、iMessage 等与你对话。
定时执行 — 按你的配置自动运行任务。
能力由 Skills 决定，有无限可能 — 内置定时任务、PDF 与表单、Word/Excel/PPT 文档处理、新闻摘要、文件阅读等，还可在 Skills 中自定义扩展。
数据全在本地 — 不依赖第三方托管。
CoPaw 由 AgentScope 团队 基于 AgentScope、 AgentScope Runtime 与 ReMe 构建。

你怎么用 CoPaw？
使用方式可以概括为两类：

在聊天软件里对话 在钉钉、飞书、QQ、Discord 或 iMessage（仅 Mac）里发消息，CoPaw 在同一 app 内回复， 查资料、记待办、回答问题等都由当前启用的 Skills 完成。一个 CoPaw 可同时接入多个 app，你在哪个频道聊，它就在哪个频道回。

定时自动执行 无需每次手动发消息，CoPaw 可按你设定的时间自动运行：

定时向某频道发送固定文案（如每天 9 点发「早上好」）；
定时向 CoPaw 提问并将回答发到指定频道（如每 2 小时问「我有什么待办」并发到钉钉）；
定时执行「自检/摘要」：用你写好的一串问题问 CoPaw，把回答发到你上次对话的频道。
装好、接好至少一个频道并启动服务后，你就可以在钉钉、飞书、QQ 等里与 CoPaw 对话，并享受定时 消息与自检等能力；具体能做什么，取决于你启用了哪些 Skills。

文档中会出现的几个概念
频道 — 你和 CoPaw 对话的「场所」（钉钉、飞书、QQ、Discord、iMessage 等）。在 频道配置 中按步骤配置。
心跳 — 按固定间隔用你写好的一段问题去问 CoPaw，并可选择把回答发到你上次使用的 频道。详见 心跳。
定时任务 — 多条、各自独立配置时间的任务（每天几点发什么、每隔多久问 CoPaw 什么等）， 通过 CLI 或 API 管理。
各概念的含义与配置方法，在对应章节中均有说明。

建议的阅读与操作顺序
快速开始 — 用三条命令把服务跑起来。
控制台 — 服务启动后，在配置频道之前，可以先在这里（浏览器打开服务根地址）与 CoPAW 对话，也可以在这里配置 Agent；先看控制台有助于理解 CoPAW 怎么用。
按需配置与使用：
频道配置 — 接入钉钉 / 飞书 / QQ / Discord / iMessage，在对应 app 里与 CoPaw 对话；
心跳 — 配置定时自检或摘要（可选）；
CLI — 初始化、定时任务、清空工作目录等命令；
Skills — 了解与扩展 CoPaw 能力；
配置与工作目录 — 工作目录与配置文件说明。


快速开始
本节介绍五种方式运行 CoPAW：

方式一 — 一键安装（推荐）：无需手动配置 Python，一行命令自动完成安装。
方式二 — pip 安装：适合自行管理 Python 环境的用户。
方式三 — 魔搭创空间：一键配置，部署到创空间云端运行，无需本地安装。
方式四 — Docker：使用官方镜像（Docker Hub；国内可选 ACR），镜像 tag 含 latest（稳定版）与 pre（PyPI 预发布版）。
方式五 — 阿里云 ECS：在阿里云上一键部署 CoPaw，无需本地安装。
📖 阅读前请先了解 项目介绍，完成安装与启动后可查看 控制台。

💡 安装并启动后：在配置频道之前，可先打开 控制台（浏览器访问 http://127.0.0.1:8088/）与 CoPAW 对话、配置 Agent；要在钉钉、飞书、QQ 等 app 里对话时，再前往 频道配置 接入频道。

方式一：一键安装（推荐）
无需预装 Python — 安装脚本通过 uv 自动管理一切。

步骤一：安装
macOS / Linux：


复制
curl -fsSL https://copaw.agentscope.io/install.sh | bash
然后打开新终端（或执行 source ~/.zshrc / source ~/.bashrc）。

Windows (CMD):


复制
curl -fsSL https://copaw.agentscope.io/install.bat -o install.bat && install.bat
Windows（PowerShell）：


复制
irm https://copaw.agentscope.io/install.ps1 | iex
然后打开新终端（安装脚本会自动将 CoPaw 加入 PATH）。

⚠️ Windows 企业版 LTSC 用户特别提示

如果您使用的是 Windows LTSC 或受严格安全策略管控的企业环境，PowerShell 可能运行在 受限语言模式 下，可能会遇到以下问题：

如果你使用的是 CMD（.bat）：脚本执行成功但无法写入Path

脚本已完成文件安装，由于 受限语言模式 ，脚本无法自动写入环境变量，此时只需手动配置：

找到安装目录：
检查 uv 是否可用：在 CMD 中输入 uv --version ，如果显示版本号，则只需配置 CoPaw 路径；如果提示 'uv' 不是内部或外部命令，也不是可运行的程序或批处理文件。，则需同时配置两者。
uv路径（任选其一，取决于安装位置，若uv不可用则填）：通常在%USERPROFILE%\.local\bin、%USERPROFILE%\AppData\Local\uv或 Python 安装目录下的 Scripts 文件夹
CoPaw路径：通常在 %USERPROFILE%\.copaw\bin 。
手动添加到系统的 Path 环境变量：
按 Win + R，输入 sysdm.cpl 并回车，打开“系统属性”。
点击 “高级” -> “环境变量”。
在 “系统变量” 中找到并选中 Path，点击 “编辑”。
点击 “新建”，依次填入上述两个目录路径，点击确定保存。
如果你使用的是 PowerShell（.ps1）：脚本运行中断

由于 受限语言模式 ，脚本可能无法自动下载uv。

手动安装uv：参考 GitHub Release下载并将uv.exe放至%USERPROFILE%\.local\bin或%USERPROFILE%\AppData\Local\uv；或者确保已安装 Python ，然后运行python -m pip install -U uv
配置uv环境变量：将uv所在目录和 %USERPROFILE%\.copaw\bin 添加到系统的 Path 变量中。
重新运行：打开新终端，再次执行安装脚本以完成 CoPaw 安装。
配置CoPaw环境变量：将 %USERPROFILE%\.copaw\bin 添加到系统的 Path 变量中。
也可以指定选项：

macOS / Linux：


复制
# 安装指定版本
curl -fsSL ... | bash -s -- --version 0.0.2

# 从源码安装（开发/测试用）
curl -fsSL ... | bash -s -- --from-source

# 安装本地模型支持（详见本地模型文档）
bash install.sh --extras llamacpp    # llama.cpp（跨平台）
bash install.sh --extras mlx         # MLX（Apple Silicon）
bash install.sh --extras ollama      # Ollama（跨平台，需 Ollama 服务运行）
Windows（PowerShell）：


复制
# 安装指定版本
.\install.ps1 -Version 0.0.2

# 从源码安装（开发/测试用）
.\install.ps1 -FromSource

# 安装本地模型支持（详见本地模型文档）
.\install.ps1 -Extras llamacpp      # llama.cpp（跨平台）
.\install.ps1 -Extras mlx           # MLX
.\install.ps1 -Extras ollama        # Ollama
升级只需重新运行安装命令。卸载请运行 copaw uninstall。

步骤二：初始化
在工作目录（默认 ~/.copaw）下生成 config.json 与 HEARTBEAT.md。两种方式：

快速用默认配置（不交互，适合先跑起来再改配置）：

复制
copaw init --defaults
交互式初始化（按提示填写心跳间隔、投递目标、活跃时段，并可顺带配置频道与 Skills）：

复制
copaw init
详见 CLI - 快速上手。
若已有配置想覆盖，可使用 copaw init --force（会提示确认）。 初始化后若尚未启用频道，接入钉钉、飞书、QQ 等需在 频道配置 中按文档填写。

步骤三：启动服务

复制
copaw app
服务默认监听 127.0.0.1:8088。若已配置频道，CoPaw 会在对应 app 内回复；若尚未配置，也可先完成本节再前往频道配置。

方式二：pip 安装
如果你更习惯自行管理 Python 环境（需 Python >= 3.10, < 3.14）：


复制
pip install copaw
可选：先创建并激活虚拟环境再安装（python -m venv .venv，Linux/macOS 下 source .venv/bin/activate，Windows 下 .venv\Scripts\Activate.ps1）。安装后会提供 copaw 命令。

然后按上方 步骤二：初始化 和 步骤三：启动服务 操作。

方式三：魔搭创空间一键配置（无需安装）
若不想在本地安装 Python，可通过魔搭创空间将 CoPaw 部署到云端运行：

先前往 魔搭 注册并登录；
打开 CoPaw 创空间，一键配置即可使用。
重要：使用创空间请将空间设为 非公开，否则你的 CoPaw 可能被他人操纵。

方式四：Docker
镜像在 Docker Hub（agentscope/copaw）。镜像 tag：latest（稳定版）；pre（PyPI 预发布版）。国内用户也可选用阿里云 ACR：agentscope-registry.ap-southeast-1.cr.aliyuncs.com/agentscope/copaw（tag 相同）。

拉取并运行：


复制
docker pull agentscope/copaw:latest
docker run -p 8088:8088 -v copaw-data:/app/working agentscope/copaw:latest
然后在浏览器打开 http://127.0.0.1:8088/ 进入控制台。配置、记忆与 Skills 保存在 copaw-data 卷中。传入 API Key 可在 docker run 时加 -e DASHSCOPE_API_KEY=xxx 或 --env-file .env。

方式五：部署到阿里云 ECS
若希望将 CoPaw 部署在阿里云上，可使用阿里云 ECS 一键部署：

打开 CoPaw 阿里云 ECS 部署链接，按页面提示填写部署参数；
参数配置完成后确认费用并创建实例，部署完成后即可获取访问地址并使用服务。
详细步骤与说明请参考 阿里云开发者社区：CoPaw 3 分钟部署你的 AI 助理。

验证安装（可选）
服务启动后,可通过 HTTP 调用 Agent 接口以确认环境正常。接口为 POST /api/agent/process,请求体为 JSON,支持 SSE 流式响应。单轮请求示例:


复制
curl -N -X POST "http://localhost:8088/api/agent/process" \
  -H "Content-Type: application/json" \
  -d '{"input":[{"role":"user","content":[{"type":"text","text":"你好"}]}],"session_id":"session123"}'
同一 session_id 可进行多轮对话。

接下来做什么？
想和 CoPAW 对话 → 去 频道配置 接一个频道（推荐先接钉钉或飞书），按文档申请应用、填 config，保存后即可在对应 app 里发消息试。
想定时自动跑一套「自检/摘要」 → 看 心跳，编辑 HEARTBEAT.md 并在 config 里设间隔和 target。
想用更多命令 → CLI（交互式 init、定时任务、清空工作目录）、Skills。
想改工作目录或配置文件路径 → 配置与工作目录。

控制台
控制台 是 CoPaw 内置的 Web 管理界面。运行 copaw app 后，在浏览器中打开 http://127.0.0.1:8088/ 即可进入。

在控制台中你可以：

和 CoPaw 实时对话
启用/禁用消息频道
查看和管理所有聊天会话
管理定时任务
编辑 CoPaw 的人设和行为文件
开关技能以扩展 CoPaw 的能力
管理MCP客户端
修改运行配置
配置 LLM 提供商并选择使用的模型
管理工具所需的环境变量
左侧侧边栏列出所有功能，分为 聊天、控制、智能体、设置 四组，点击即可 切换页面。下面按顺序逐一介绍每个功能的操作方法。

看不到控制台？ 请确认前端已构建，构建方式见 CLI。

聊天
侧边栏：聊天 → 聊天

这是你和 CoPaw 对话的地方。打开控制台后默认就是这个页面。

聊天

发送消息： 在底部输入框中输入内容，按 Enter 或点击发送按钮（↑），CoPaw 会实时回复。

新建会话： 点击聊天页面侧边栏顶部的 + New Chat 按钮，开始一段全新的对话。每个会话独立保存各自的对话记录。

切换会话： 点击聊天页面侧边栏中的任意会话名称，即可加载该会话的历史消息。

删除会话： 点击任意回话条目右侧的 ··· 按钮，再点击出现的 垃圾桶 图标即可删除。

频道
侧边栏：控制 → 频道

在这里管理各消息频道（钉钉、飞书、Discord、QQ、iMessage、Console）的开关和凭据。

频道

启用一个频道：

点击你要配置的频道卡片。

右侧滑出配置面板，打开 Enable 开关。

频道配置

填写该频道所需的凭据——每个频道要求不同：

频道	需要填写的字段
钉钉	Client ID、Client Secret
飞书	App ID、App Secret、加密密钥、验证令牌、媒体文件目录
Discord	Bot Token、HTTP 代理、代理认证
QQ	App ID、Client Secret
iMessage	数据库路径、轮询间隔
Console	（只需开关）
点 保存，几秒内自动生效，无需重启。

禁用一个频道： 打开同一个配置面板，关闭 Enable 开关，然后 保存。

各平台的凭据获取步骤，请看 频道配置。

会话
侧边栏：控制 → 会话

在这里查看、筛选和清理所有频道的聊天会话。

会话

查找会话： 在搜索框中输入用户名过滤，或用下拉菜单按频道筛选，表格会即时更新。

重命名会话： 点击某行的 编辑 按钮 → 修改名称 → 点 保存。

删除单条会话： 点击某行的 删除 按钮 → 弹窗确认即可。

批量删除： 勾选要删除的行 → 点击出现的 批量删除 按钮 → 确认。

定时任务
侧边栏：控制 → 定时任务

在这里创建和管理 CoPaw 按时间自动执行的定时任务。

定时任务

创建新任务：

点击 + 创建任务 按钮。

创建定时任务

按区域填写表单：

基本信息 —— 给任务一个 ID（如 job-001）、一个名称（如「每日摘要」）， 并打开启用开关。
调度 —— 填写 Cron 表达式（如 0 9 * * * = 每天上午 9 点）并选择时区。
任务类型及内容 —— 选择 文本（发送固定消息）或 Agent（向 CoPaw 提问并 转发回复），然后填入具体内容。
投递 —— 选择目标频道（如 Console、钉钉）、目标用户，以及投递方式 （流式 = 实时发送，最终 = 完成后一次性发送）。
高级选项 —— 按需调整最大并发数、超时时间和宽限时间。
点 保存。

编辑任务： 点击某行的 编辑 按钮 → 修改任意字段 → 保存。

启用 / 禁用任务： 点击行内的开关即可。

立即执行一次： 点击 立即执行 → 确认，任务会马上运行一次。

删除任务： 点击 删除 → 确认。

工作区
侧边栏：智能体 → 工作区

在这里编辑定义 CoPaw 人设和行为的文件——SOUL.md、AGENTS.md、 HEARTBEAT.md 等——全部在浏览器中完成。

工作区

编辑文件：

点击文件列表中的文件名（如 SOUL.md）。
文件内容出现在编辑器中，关闭预览按钮，修改内容。
点 保存 生效，或点 重置 放弃修改并重新加载。
查看每日记忆： 如果存在 MEMORY.md，点击旁边的 ▶ 箭头可展开按日期分组的条目，点击某个日期 即可查看或编辑当天的记忆。

下载整个工作区： 点击 下载 按钮（⬇），工作区会打包为 .zip 文件保存到本地。

上传 / 恢复工作区： 点击 上传 按钮（⬆）→ 选择 .zip 文件（最大 100 MB），当前工作区文件会被替换。 适合在不同机器之间迁移或从备份恢复。

技能
侧边栏：智能体 → 技能

在这里管理扩展 CoPaw 能力的技能（如读取 PDF、创建 Word 文档、获取新闻等）。

技能

启用技能： 点击技能卡片底部的 启用 链接，立即生效。

查看技能详情： 点击技能卡片可查看完整说明。

禁用技能： 点击 禁用 链接，同样立即生效。

从 Skill Hub 中导入技能：

点击导入技能。

输入技能 URL，点击导入技能。

等待技能导入，成功后可在技能列表中看到已启用。

导入技能

创建自定义技能：

点击 创建技能。

输入技能名称（如 weather_query）和技能内容（Markdown 格式，需包含 name 和 description）。

点 保存，新技能立即出现。

创建技能

删除自定义技能： 先禁用该技能，然后点击卡片上的 🗑 图标 → 确认删除。

内置技能说明、导入技能和自定义技能编写方法，请看 技能。

MCP
侧边栏：智能体 → MCP

在这里启用/禁用/删除MCP，或者创建新的客户端。

MCP

创建客户端 点击右上角的创建客户端，填写必要信息，点击创建，可以看到MCP客户端列表中新增内容。

运行配置
侧边栏：智能体 → 运行配置

运行配置

在这里修改最大迭代次数和最大输入长度，修改后点击保存。

模型
侧边栏：设置 → 模型

在这里配置 LLM 提供商并选择 CoPaw 使用的模型。CoPaw 同时支持云提供商（需要 API Key）和本地提供商（无需 API Key）。

模型

云提供商
配置提供商：

点击提供商卡片（ModelScope、DashScope）上的 设置 按钮。
输入你的 API Key。
点 保存，卡片状态变为「已授权」。
如果想添加自定义提供商，点击右侧添加提供商。
输入提供商 ID、显示名称等必要信息，点击创建。
找到创建的提供商，点击设置，填写必要信息，选择保存，卡片状态变为「已授权」。
撤销授权： 打开提供商的 设置对话框，点击 撤销授权，API Key 会被清除； 如果当前使用的就是该提供商，模型选择也会一并清空。

本地提供商（llama.cpp / MLX）
本地提供商显示紫色的 本地 标签。 使用前需先安装后端依赖（pip install 'copaw[llamacpp]' 或 pip install 'copaw[mlx]'）。

下载模型：

点击本地提供商卡片上的 模型按钮。
点击 下载模型，填写：
Repo ID（必填）—— 如 Qwen/Qwen3-4B-GGUF
文件名（可选）—— 留空自动选择
下载源 —— Hugging Face（默认）或 ModelScope
点击 下载，等待下载完成。
查看和删除模型： 已下载的模型列在管理面板中，显示文件大小、来源标记（HF / MS）和删除按钮。

Ollama 提供商
Ollama 提供商集成本地 Ollama 守护进程，动态加载其中的模型。

前置条件：

从 ollama.com 安装 Ollama
安装 Ollama SDK：pip install 'copaw[ollama]'（或使用 --extras ollama 重新运行安装脚本）
下载模型：

点击 Ollama 提供商卡片的 设置按钮。
在API key中填写内容，例如可以直接填写为ollama，点击保存。
点击Ollama卡片中的 模型按钮，点击下载模型，输入 模型名称（如 mistral:7b、qwen3:8b）。
点击 下载模型，等待下载完成。
取消下载： 下载过程中，点击进度指示器旁的 ✕ 按钮即可取消。

查看和删除模型： 已下载的模型列在管理面板中，显示大小和删除按钮。通过 Ollama CLI 或控制台添加/删除模型时，列表会自动更新。

与本地模型的区别：

模型来自 Ollama 守护进程（不由 CoPaw 直接下载）
模型列表与 Ollama 自动同步
支持热门模型：mistral:7b、qwen3:8b 等
也可以通过 CLI 管理 Ollama 模型：copaw models ollama-pull、copaw models ollama-list、copaw models ollama-remove。详见 CLI。

选择活跃模型
在顶部LLM配置的提供商下拉菜单中选择一个提供商（只显示已授权或 有已下载模型的本地提供商）。
在 模型 下拉菜单中选择一个模型。
点 保存。
注意： 云提供商 API Key 的有效性需要用户自行保证，CoPaw 不会验证。

提供商详细说明见 配置 — 模型提供商。

环境变量
侧边栏：设置 → 环境变量

在这里管理 CoPaw 的工具和技能在运行时需要的环境变量（如 TAVILY_API_KEY）。

环境变量

添加变量：

点击底部的 + 添加变量。
输入变量名（如 TAVILY_API_KEY）和对应的值。
点击 保存。
编辑变量： 修改已有行的 Value 字段，然后点 保存。 （变量名保存后为只读，如需改名请先删除再新建。）

删除变量： 点击行右侧的 🗑 图标 → 如有提示则确认。

批量删除： 勾选要删除的行 → 点工具栏的 删除 → 确认删除。

注意： 环境变量值的有效性需要用户自行保证，CoPaw 只负责存储和加载。

更多说明见 配置 — 环境变量。

快速索引
页面	侧边栏路径	你能做什么
聊天	聊天 → 聊天	和 CoPaw 对话、管理会话
频道	控制 → 频道	启用/禁用频道、填入凭据
会话	控制 → 会话	筛选、重命名、删除会话
定时任务	控制 → 定时任务	创建/编辑/删除任务、立即执行
工作区	智能体 → 工作区	编辑人设文件、查看记忆、上传/下载
技能	智能体 → 技能	启用/禁用/创建/删除技能
MCP	智能体 → MCP	启用/禁用/创建/删除MCP
运行配置	智能体 → 运行配置	修改运行配置
模型	设置 → 模型	配置提供商 API Key、管理本地/Ollama 模型、选择模型
环境变量	设置 → 环境变量	添加/编辑/删除环境变量


模型
在于CoPaw对话前，需要先配置模型。在 控制台 → 设置 → 模型 中可以快捷配置。

控制台模型

CoPaw 支持多种 LLM 提供商：云提供商（需 API Key）、本地提供商（llama.cpp / MLX）和 Ollama 提供商，且支持添加自定义 提供商。本文介绍这几类提供商的配置方式。

配置云提供商
云提供商（包括 ModelScope、DashScope、Aliyun Coding Plan、OpenAI 和 Azure OpenAI）通过 API 调用远程模型，需要配置 API Key。

在控制台中配置：

打开控制台，进入 设置 → 模型。

找到目标云提供商卡片（以 DashScope 为例），点击 设置。输入你的 API key，点击 保存。

save

保存后可以看到目标云提供商卡片右上角状态变成 可用，此时在上方的 LLM 配置 中，提供商 对应的下拉菜单中可以选择目标云提供商，模型 对应的下拉菜单中出现一系列可选模型。

choose

选择目标模型（以 qwen3.5-plus 为例），点击 保存。

save

可以看到 LLM 配置栏右上角显示当前正在使用的模型提供商及模型。

model

注：如果想撤销某个云提供商授权，点击目标云提供商卡片的 设置，点击撤销授权，二次确认撤销授权后，可将目标提供商的状态调整为 不可用。

cancel

本地提供商（llama.cpp / MLX）
本地提供商在本地运行模型，无需 API Key，数据不出本机。

前置条件：

在CoPaw所在环境中安装对应后端：
llama.cpp：pip install 'copaw[llamacpp]'
MLX：pip install 'copaw[mlx]'
在控制台的模型页面可以找到 llama.cpp 和 MLX 对应的卡片。

card

点击目标本地提供商（以llama.cpp为例）卡片的 模型，选择 下载模型。

download

填写 仓库 ID，并选择 来源，点击 下载模型。

id

可以看到正在下载模型，需要等待一段时间。

wait

模型下载完成后，可以看到本地提供商卡片右上角转为 可用 状态。

avai

在上方的 LLM 配置 中，提供商 对应的下拉菜单中可以选择本地提供商，模型 对应的下拉菜单中可选择刚刚添加的模型。点击保存。

model

可以看到 LLM 配置右上角显示本地提供商和选择的模型名称。

see

注：点击对应本地提供商卡片上的 模型，可以看到不同模型名称、大小、下载来源。如果想删除模型，点击对应模型最右侧的 垃圾桶图标，二次确认后即可删除。

delete

Ollama 提供商
Ollama 提供商对接本机安装的 Ollama 守护进程，使用其中的模型，无需由 CoPaw 直接下载模型文件，列表会与 Ollama 自动同步。

前置条件：

从 ollama.com 安装 Ollama。
在 CoPaw所在虚拟环境中安装 Ollama：pip install 'copaw[ollama]'。
在控制台的模型界面中，可以看到 ollama 提供商对应的卡片。

点击右下角 设置，在配置 ollama 的页面中，填写 API Key。此处可随意填写一个内容，例如 ollama。点击 保存。

set

点击 模型，如果已经使用 Ollama 下载过一些模型，则可以看到对应的模型列表。如果还没有下载模型，或需要下载额外模型，点击 下载模型。

download

填写 模型名称，点击 下载模型。

download

可以看到进入模型下载状态，等待模型下载完成。

wait

下载完成后，可以在上方的 LLM 配置 中，提供商 对应的下拉菜单中可以选择 Ollama，模型 对应的下拉菜单中可选择想使用的模型。点击 保存。

save

可以看到 LLM 配置右上角显示 Ollama 提供商和选择的模型名称。

name

如果在过程中遇到 Ollama SDK not installed. Install with: pip install 'copaw[ollama]'的提示，请先确认是否已经在 ollama.com 下载 Ollama，并在 CoPaw所在虚拟环境中执行过 pip install 'copaw[ollama]'。如果想删除某个模型，点击 Ollama 卡片右下角的 模型，在模型列表中，点击想要删除的模型右侧的 垃圾桶按钮，二次确认后即可删除。

delete

添加自定义提供商
在控制台的模型页面点击 添加提供商。

add

填写 提供商 ID 和 显示名称，点击 创建。

create

可以看见新添加的提供商卡片。

card

点击设置，填写 Base URL 和 API Key，点击 保存。

save

可以看到自定义提供商卡片中已经显示刚刚配置的 Base_URL 和 API Key，但此时右上角仍显示 不可用， 还需要配置模型。

model

点击 模型，填写 模型 ID，点击 添加模型。

add

此时可见自定义提供商为 可见。在上方的 LLM 配置 中，提供商 对应的下拉菜单中可以选择自定义提供商，模型 对应的下拉菜单中可选择刚刚添加的模型。点击 保存。

model

可以看到 LLM 配置右上角显示自定义提供商的 ID 和选择的模型名称。

save

注：如果无法成功配置，请重点检查 Base URL，API Key 和 模型 ID 是否填写正确，尤其是模型的大小写。如果想删除自定义提供商，在对应卡片右下角点击 删除提供商，二次确认后可成功删除。

delete

Skills
Skills：内置多类能力，你还可以添加自定义 Skill，或者直接从社区 Skills Hub 导入 Skills。

管理 Skill 有两种方式：

控制台 — 在 控制台 的 Agent → Skills 页面操作
工作目录 — 按本文步骤直接编辑文件
若尚未了解「频道」「心跳」「定时任务」等概念，建议先阅读 项目介绍。

应用从工作目录下的 skills 目录（默认 ~/.copaw/active_skills/）加载能力：每个子目录中只要包含一份 SKILL.md，即会被识别为一个 Skill 并加载，无需额外注册。

内置 Skills 一览
当前内置的 Skills 如下，安装后会在首次需要时同步到工作目录，你可在控制台或通过配置启用/禁用。

Skill 名称	说明	来源
cron	定时任务管理。通过 copaw cron 或控制台 Cron Jobs 创建、查询、暂停、恢复、删除定时任务，按时间表执行并把结果发到频道。	自建
file_reader	读取与摘要文本类文件（如 .txt、.md、.json、.csv、.log、.py 等）。PDF 与 Office 由下方专用 Skill 处理。	自建
dingtalk_channel_connect	辅助完成钉钉频道接入流程：引导进入开发者后台、填写必要信息，帮助用户获取 Client ID 与 Client Secret，并提示用户完成必要的手动配置步骤。	自建
himalaya	通过 CLI 管理邮件（IMAP/SMTP）。使用 himalaya 列出、阅读、搜索、整理邮件，支持多账户与附件管理。	https://github.com/openclaw/openclaw/tree/main/skills/himalaya
news	从指定新闻站点查询最新新闻，支持政治、财经、社会、国际、科技、体育、娱乐等分类，并做摘要。	自建
pdf	PDF 相关操作：阅读、提取文字/表格、合并/拆分、旋转、水印、创建、填表、加密/解密、OCR 等。	https://github.com/anthropics/skills/tree/main/skills/pdf
docx	Word 文档（.docx）的创建、阅读、编辑，含目录、页眉页脚、表格、图片、修订与批注等。	https://github.com/anthropics/skills/tree/main/skills/docx
pptx	PPT（.pptx）的创建、阅读、编辑，含模板、版式、备注与批注等。	https://github.com/anthropics/skills/tree/main/skills/pptx
xlsx	表格（.xlsx、.xlsm、.csv、.tsv）的读取、编辑、创建与格式整理，支持公式与数据分析。	https://github.com/anthropics/skills/tree/main/skills/xlsx
browser_visible	以可见模式（headed）启动真实浏览器窗口，适用于演示、调试或需要人工参与（如登录、验证码）的场景。	自建
通过控制台管理 Skills
在 控制台 侧栏进入 Agent → Skills，可以：

查看当前已加载的 Skills 及启用状态；
启用/禁用某个 Skill（开关切换）；
新建自定义 Skill：填写名称与内容即可，无需手动建目录；
编辑已有 Skill 的名称或内容。
导入 Skills Hub 中的 Skills
修改后会自动同步到工作目录并影响 Agent 行为。适合不习惯直接改文件的用户。

内置 Skill：Cron（定时任务）
首次运行时会从包里把 Cron 同步到 ~/.copaw/active_skills/cron/。它提供「按时间表执行任务并把结果发到频道」的能力；具体任务的增删改查用 CLI 的 copaw cron 或控制台 Control → Cron Jobs 完成，不需要手写 cron 以外的配置。

常用操作：

创建任务：copaw cron create --type agent --name "xxx" --cron "0 9 * * *" ...
查看列表：copaw cron list
查看状态：copaw cron state <job_id>
导入 Skill
当前支持在控制台中导入以下四种来源的 Skills：

https://skills.sh/...
https://clawhub.ai/...
https://skillsmp.com/...
https://github.com/...
步骤
打开 控制台 → 智能体 → 技能，点击右上角 导入技能。

import

在弹窗中粘贴 Skill URL（获取方式见下方 URL 获取示例）。

url

点击导入技能，等待导入完成。

click

导入成功后，在技能列表中可以看到新加入的 Skill。

new

URL 获取示例
以 skills.sh 为例（clawhub.ai 和 skillsmp.com 获取 Skill URL 的方式相同），进入 https://skills.sh/。

选择你需要的 Skill（以 find-skills 为例）。

find

点击最上方的 URL 并复制，即为导入 Skill 时需要的 Skill URL。

url

如果想导入 GitHub 仓库中的 Skills，进入包含 SKILL.md 的页面（以 anthropics 的 skills 仓库中的 skill-creator 为例），复制最上方 URL 即可。

github

说明
若同名 Skill 已存在，默认不会覆盖；建议先在列表中确认现有内容后再处理。
导入失败时优先检查：URL 是否完整、来源域名是否受支持、外网是否可访问。若遇到网络不稳定或 GitHub 限流，建议在 控制台 → 设置 → 环境变量 中添加 GITHUB_TOKEN；获取方式可参考 GitHub 官方文档：管理个人访问令牌（PAT）。
自定义 Skill（在工作目录中）
想通过文件方式给 Agent 加自己的一套说明或能力时，可以在 customized_skills 目录下手动添加自定义 Skill。

步骤
在 ~/.copaw/customized_skills/ 下新建一个目录，例如 my_skill。
在该目录下新建 SKILL.md。里面写 Markdown，给 Agent 看的能力说明、使用注意等；可选在文件开头用 YAML front matter 写 name、description、metadata，方便在 Agent 或控制台里展示。
目录结构示例

复制
~/.copaw/
  active_skills/        # 实际激活的 Skill（由内置与自定义合并同步）
    cron/
      SKILL.md
    my_skill/
      SKILL.md
  customized_skills/    # 用户自定义 Skill（在此添加）
    my_skill/
      SKILL.md
SKILL.md 示例

复制
---
name: my_skill
description: 我的自定义能力说明
---

# 使用说明

本 Skill 用于……
应用启动时会将内置 Skill 与 ~/.copaw/customized_skills/ 中的自定义 Skill 合并同步到 ~/.copaw/active_skills/，同名时自定义优先。你在 customized_skills 中新加的目录不会被覆盖；内置 Skill 只会在 active_skills 中缺失时复制一次，已存在则不会覆盖。
