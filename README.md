# Claude Code Best V5 (CCB)

[![GitHub Stars](https://img.shields.io/github/stars/claude-code-best/claude-code?style=flat-square&logo=github&color=yellow)](https://github.com/claude-code-best/claude-code/stargazers)
[![GitHub Contributors](https://img.shields.io/github/contributors/claude-code-best/claude-code?style=flat-square&color=green)](https://github.com/claude-code-best/claude-code/graphs/contributors)
[![GitHub Issues](https://img.shields.io/github/issues/claude-code-best/claude-code?style=flat-square&color=orange)](https://github.com/claude-code-best/claude-code/issues)
[![GitHub License](https://img.shields.io/github/license/claude-code-best/claude-code?style=flat-square)](https://github.com/claude-code-best/claude-code/blob/main/LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/claude-code-best/claude-code?style=flat-square&color=blue)](https://github.com/claude-code-best/claude-code/commits/main)
[![Bun](https://img.shields.io/badge/runtime-Bun-black?style=flat-square&logo=bun)](https://bun.sh/)
[![Discord](https://img.shields.io/badge/Discord-Join-5865F2?style=flat-square&logo=discord)](https://discord.gg/qZU6zS7Q)

> Which Claude do you like? The open source one is the best.

牢 A (Anthropic) 官方 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI 工具的源码反编译/逆向还原项目。目标是将 Claude Code 大部分功能及工程化能力复现 (问就是老佛爷已经付过钱了)。虽然很难绷, 但是它叫做 CCB(踩踩背)... 而且, 我们实现了企业版或者需要登陆 Claude 账号才能使用的特性, 实现技术普惠

[文档在这里, 支持投稿 PR](https://ccb.agent-aura.top/) | [留影文档在这里](./Friends.md) | [Discord 群组](https://discord.gg/qZU6zS7Q)

| 特性 | 说明 | 文档 |
|------|------|------|
| **Claude 群控技术** | Pipe IPC 多实例协作：同机 main/sub 自动编排 + LAN 跨机器零配置发现与通讯，`/pipes` 选择面板 + `Shift+↓` 交互 + 消息广播路由 | [Pipe IPC](https://ccb.agent-aura.top/docs/features/pipes-and-lan) / [LAN](https://ccb.agent-aura.top/docs/features/lan-pipes) |
| **ACP 协议一等一支持** | 支持接入 Zed、Cursor 等 IDE，支持会话恢复、Skills、权限桥接 | [文档](https://ccb.agent-aura.top/docs/features/acp-zed) |
| **Remote Control 私有部署** | Docker 自托管远程界面, 可以手机上看 CC | [文档](https://ccb.agent-aura.top/docs/features/remote-control-self-hosting) |
| **Langfuse 监控** | 企业级 Agent 监控, 可以清晰看到每次 agent loop 细节, 可以一键转化为数据集 | [文档](https://ccb.agent-aura.top/docs/features/langfuse-monitoring) |
| **Web Search** | 内置网页搜索工具, 支持 bing 和 brave 搜索 | [文档](https://ccb.agent-aura.top/docs/features/web-browser-tool) |
| **Poor Mode** | 穷鬼模式，关闭记忆提取和键入建议,大幅度减少并发请求 | /poor 可以开关 |
| **自定义模型供应商** | OpenAI/Anthropic/Gemini/Grok 兼容 | [文档](https://ccb.agent-aura.top/docs/features/custom-platform-login) |
| Voice Mode | Push-to-Talk 语音输入 | [文档](https://ccb.agent-aura.top/docs/features/voice-mode) |
| Computer Use | 屏幕截图、键鼠控制 | [文档](https://ccb.agent-aura.top/docs/features/computer-use) |
| Chrome Use | 浏览器自动化、表单填写、数据抓取 | [自托管](https://ccb.agent-aura.top/docs/features/chrome-use-mcp) [原生版](https://ccb.agent-aura.top/docs/features/claude-in-chrome-mcp) |
| Sentry | 企业级错误追踪 | [文档](https://ccb.agent-aura.top/docs/internals/sentry-setup) |
| GrowthBook | 企业级特性开关 | [文档](https://ccb.agent-aura.top/docs/internals/growthbook-adapter) |
| /dream 记忆整理 | 自动整理和优化记忆文件 | [文档](https://ccb.agent-aura.top/docs/features/auto-dream) |

- 🚀 [想要启动项目](#快速开始源码版)
- 🐛 [想要调试项目](#vs-code-调试)
- 📖 [想要学习项目](#teach-me-学习项目)


## ⚡ 快速开始(安装版)

不用克隆仓库, 从 NPM 下载后, 直接使用

```sh
bun  i -g claude-code-best
bun pm -g trust claude-code-best
ccb # 以 nodejs 打开 claude code
ccb-bun # 以 bun 形态打开
CLAUDE_BRIDGE_BASE_URL=https://remote-control.claude-code-best.win/ CLAUDE_BRIDGE_OAUTH_TOKEN=test-my-key ccb --remote-control # 我们有自部署的远程控制
```

## ⚡ 快速开始(源码版)

### ⚙️ 环境要求

一定要最新版本的 bun 啊, 不然一堆奇奇怪怪的 BUG!!! bun upgrade!!!

- 📦 [Bun](https://bun.sh/) >= 1.3.11
- ⚙️ 常规的配置 CC 的方式, 各大提供商都有自己的配置方式

### 📥 安装

```bash
bun install
```

### ▶️ 运行

```bash
# 开发模式, 看到版本号 888 说明就是对了
bun run dev

# 构建
bun run build
```

构建采用 code splitting 多文件打包（`build.ts`），产物输出到 `dist/` 目录（入口 `dist/cli.js` + 约 450 个 chunk 文件）。

构建出的版本 bun 和 node 都可以启动, 你 publish 到私有源可以直接启动

如果遇到 bug 请直接提一个 issues, 我们优先解决

### 👤 新人配置 /login

首次运行后，在 REPL 中输入 `/login` 命令进入登录配置界面，选择 **Anthropic Compatible** 即可对接第三方 API 兼容服务（无需 Anthropic 官方账号）。
选择 OpenAI 和 Gemini 对应的栏目都是支持相应协议的

需要填写的字段：

| 📌 字段 | 📝 说明 | 💡 示例 |
|------|------|------|
| Base URL | API 服务地址 | `https://api.example.com/v1` |
| API Key | 认证密钥 | `sk-xxx` |
| Haiku Model | 快速模型 ID | `claude-haiku-4-5-20251001` |
| Sonnet Model | 均衡模型 ID | `claude-sonnet-4-6` |
| Opus Model | 高性能模型 ID | `claude-opus-4-6` |

- ⌨️ **Tab / Shift+Tab** 切换字段，**Enter** 确认并跳到下一个，最后一个字段按 Enter 保存


> ℹ️ 支持所有 Anthropic API 兼容服务（如 OpenRouter、AWS Bedrock 代理等），只要接口兼容 Messages API 即可。

## Feature Flags

所有功能开关通过 `FEATURE_<FLAG_NAME>=1` 环境变量启用，例如：

```bash
FEATURE_BUDDY=1 FEATURE_FORK_SUBAGENT=1 bun run dev
```

各 Feature 的详细说明见 [`docs/features/`](docs/features/) 目录，欢迎投稿补充。

## VS Code 调试

TUI (REPL) 模式需要真实终端，无法直接通过 VS Code launch 启动调试。使用 **attach 模式**：

### 步骤

1. **终端启动 inspect 服务**：
   ```bash
   bun run dev:inspect
   ```
   会输出类似 `ws://localhost:8888/xxxxxxxx` 的地址。

2. **VS Code 附着调试器**：
   - 在 `src/` 文件中打断点
   - F5 → 选择 **"Attach to Bun (TUI debug)"**


## Teach Me 学习项目

我们新加了一个 teach-me skills, 通过问答式引导帮你理解这个项目的任何模块。(调整 [sigma skill 而来](https://github.com/sanyuan0704/sanyuan-skills))

```bash
# 在 REPL 中直接输入
/teach-me Claude Code 架构
/teach-me React Ink 终端渲染 --level beginner
/teach-me Tool 系统 --resume
```

### 它能做什么

- **诊断水平** — 自动评估你对相关概念的掌握程度，跳过已知的、聚焦薄弱的
- **构建学习路径** — 将主题拆解为 5-15 个原子概念，按依赖排序逐步推进
- **苏格拉底式提问** — 用选项引导思考，而非直接给答案
- **错误概念追踪** — 发现并纠正深层误解
- **断点续学** — `--resume` 从上次进度继续

### 学习记录

学习进度保存在 `.claude/skills/teach-me/` 目录下，支持跨主题学习者档案。

## 相关文档及网站

- **在线文档（Mintlify）**: [ccb.agent-aura.top](https://ccb.agent-aura.top/) — 文档源码位于 [`docs/`](docs/) 目录，欢迎投稿 PR
- **DeepWiki**: <https://deepwiki.com/claude-code-best/claude-code>

## Contributors

<a href="https://github.com/claude-code-best/claude-code/graphs/contributors">
  <img src="contributors.svg" alt="Contributors" />
</a>

## Star History

<a href="https://www.star-history.com/?repos=claude-code-best%2Fclaude-code&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/image?repos=claude-code-best/claude-code&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/image?repos=claude-code-best/claude-code&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/image?repos=claude-code-best/claude-code&type=date&legend=top-left" />
 </picture>
</a>

## Copyright & Attribution | 版权与致谢

### English

This project is an **unofficial, community-maintained** Windows packaging of the [claude-code-best](https://github.com/claude-code-best/claude-code) decompiled source restoration of Anthropic's Claude Code CLI.

**Copyright ownership:**

| Layer | Rights Holder | Description |
|-------|--------------|-------------|
| Claude Code (original) | **Anthropic, PBC** | All rights reserved. The original Claude Code CLI, its algorithms and compiled artifacts are the exclusive property of Anthropic. |
| Source restoration | **claude-code-best contributors** | Decompiled/reverse-engineered source reconstruction, feature restoration, and third-party API compatibility layers. |
| Windows packaging | **This repository's maintainer** | `packaging/` directory — build scripts, installer configuration, and launcher. Original contribution, non-commercial terms only. |

This repository thanks the [claude-code-best community](https://github.com/claude-code-best/claude-code) for their foundational work, and Anthropic for building Claude Code.

### 中文

本项目是 [claude-code-best](https://github.com/claude-code-best/claude-code)（Anthropic Claude Code CLI 反编译还原版）的**非官方 Windows 打包方案**，由社区独立维护。

**版权归属：**

| 层级 | 权利归属 | 说明 |
|------|----------|------|
| Claude Code（原始版本） | **Anthropic, PBC** | 保留所有权利。原始 Claude Code CLI 工具、算法及编译产物，均为 Anthropic 的专有财产。 |
| 源码还原工作 | **claude-code-best 社区贡献者** | 反编译/逆向还原、功能复现、第三方 API 兼容层等工程化工作。 |
| Windows 打包方案 | **本仓库维护者** | `packaging/` 目录下的构建脚本、安装脚本、启动器等，为本仓库独立原创贡献，仅供非商业用途。 |

---

## Disclaimer | 免责声明

> **⚠️ This project is NOT affiliated with, endorsed by, or officially supported by Anthropic, PBC in any way.**
>
> **⚠️ 本项目与 Anthropic, PBC 没有任何隶属关系，未获得 Anthropic 的授权或官方支持。**

**English:**
- This is an **unofficial, third-party** Windows packaging of a community reverse-engineered source restoration.
- Intended **strictly for personal learning and research**. Not for production use.
- Requires a valid **Anthropic API key** and is subject to [Anthropic's Terms of Service](https://www.anthropic.com/legal/consumer-terms).
- Pre-built `.exe` files embed code whose copyright belongs to Anthropic. You are solely responsible for ensuring your use complies with applicable laws.
- For production use, please use the [official Claude Code CLI](https://www.anthropic.com/claude-code).

**中文：**
- 本项目是社区维护的反编译源码的**非官方第三方** Windows 打包方案，仅供学习研究。
- 使用本软件需要有效的 **Anthropic API 密钥**，须遵守 [Anthropic 服务条款](https://www.anthropic.com/legal/consumer-terms)。
- 预构建可执行文件（`.exe`）内嵌了版权归属 Anthropic 的代码，用户须自行确保使用合规。
- 生产环境请使用 [官方 Claude Code CLI](https://www.anthropic.com/claude-code)。

---

## License & Distribution | 许可证与分发条款

**What you CAN do | 可以做的事：**
- ✅ 个人非商业使用 / Personal non-commercial use
- ✅ 学习研究源码（尤其是 `packaging/` 打包方案）/ Study source code for learning
- ✅ Fork 并修改打包脚本用于自己的非商业项目 / Fork and modify packaging scripts
- ✅ 分享本仓库链接 / Share this repository link

**What you CANNOT do | 不可以做的事：**
- ❌ 商业用途或集成到商业产品 / Commercial use or integration into paid products
- ❌ 声称为 Anthropic 官方产品或官方发行版 / Claim as official Anthropic product
- ❌ 删除或遮蔽版权声明和致谢信息 / Remove copyright notices or attribution
- ❌ 分发预构建 EXE 时不附带免责声明 / Distribute binaries without this disclaimer

Full terms: [LICENSE](./LICENSE)
