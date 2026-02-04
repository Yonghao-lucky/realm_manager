# RealmRouter Configuration Manager

**OpenClaw RealmRouter Configuration Manager** 是一个用于管理 OpenClaw 配置文件的 Bash 脚本工具，专为 [RealmRouter](https://realmrouter.cn) 服务设计。它能够帮助用户轻松地将 RealmRouter 的模型配置注入到 OpenClaw 中，并提供方便的模型切换、API Key 管理以及配置备份功能。

> 💖 **Special Sponsor / 特别赞助**
>
> 本项目由 **[RealmRouter](https://realmrouter.cn)** 独家赞助支持。
>
> **🚀 限时福利活动进行中：**
> *   **新人礼包**：注册即送 **5 元** 体验金（约可抵扣 Qwen 系列 500万 Token 或 Gemini Pro 250次调用），0 门槛畅享顶级 AI 模型！
> *   **邀请双赢**：每邀请一位好友注册，双方各得 **5 元** 余额，上不封顶！
>
> 👉 **[立即点击注册 RealmRouter](https://realmrouter.cn)**

## 功能特性

*   **一键安装/重置**: 自动将 RealmRouter 的配置（包括最新的模型列表）注入到 `openclaw.json` 配置文件中。
*   **模型切换**: 支持按发行商（Anthropic, DeepSeek, Google, OpenAI 等）分类浏览并切换默认 AI 模型。
*   **API Key 管理**: 方便地更新和验证 RealmRouter API Key。
*   **智能连通性测试**: 使用当前选中的模型真实调用 API，检测 Key 的有效性及网络连通状况，快速排查问题。
*   **配置备份与还原**: 每次修改前自动备份配置文件，支持从历史备份中一键还原，安全无忧。
*   **脚本自动更新**: 支持从 GitHub 拉取最新版本的脚本，时刻保持功能最新。

## 快速开始

### 1. 下载脚本

您可以通过 `curl` 或 `wget` 下载本脚本，或者直接克隆本仓库。

```bash
git clone https://github.com/Yonghao-lucky/realm_manager.git
cd realm_manager
```

### 2. 添加执行权限

在使用之前，请确保脚本具有可执行权限：

```bash
chmod +x realm_manager.sh
```

### 3. 运行脚本

直接运行脚本即可进入交互式菜单：

```bash
./realm_manager.sh
```

## 使用指南

脚本启动后，您将看到如下主菜单：

```text
========================================
    RealmRouter 配置管理工具 v2.3
========================================
 [1] 安装/重置 (注入 RealmRouter 配置)
 [2] 更换 Key  (更新 API Key)
 [3] 切换模型  (修改默认 AI 模型)
 [4] 还原备份  (从历史备份恢复)
 [5] 测试连通  (测试 Key 有效性)
 [6] 更新脚本  (获取最新版本)
 [q] 退出
```

### [1] 安装/重置
首次使用时，请选择此选项。
*   输入您的 RealmRouter API Key。
*   脚本会自动验证 Key 的有效性。
*   验证通过后，脚本会将 RealmRouter 的配置信息写入到 `~/.openclaw/openclaw.json` 中，并将默认模型设置为 `realmrouter/qwen3-max`。

### [2] 更换 Key
如果您的 API Key 发生变更或失效，使用此选项更新。
*   输入新的 API Key。
*   验证成功后自动更新配置文件。

### [3] 切换模型
想要更换 OpenClaw 使用的默认 AI 模型时使用。
*   脚本提供了按发行商分类的模型列表（如 Anthropic, DeepSeek, Google, OpenAI 等）。
*   选择对应的分类和模型后，脚本会自动修改配置文件中的默认模型。

### [4] 还原备份
脚本在每次修改配置文件前都会自动创建一个备份文件。
*   选择此选项可以查看最近的备份列表。
*   选择一个备份文件即可将配置恢复到当时的状态。

### [5] 测试连通
当您遇到模型无法回答或报错时，使用此功能进行诊断。
*   脚本会自动读取当前配置的 API Key 和 **当前选中的默认模型**。
*   发起真实的对话请求（发送 "hi"）来测试服务器响应。
*   如果是模型 ID 问题或 Key 失效，这里会直接给出错误提示。

### [6] 更新脚本
检查并下载脚本的最新版本，确保您拥有最新的模型列表和功能修复。

## 前置要求

*   **操作系统**: Linux 或 macOS (支持 Bash 环境)
*   **依赖工具**:
    *   `curl`: 用于网络请求和下载。
    *   `python3`: 用于解析和修改 JSON 配置文件。
    *   `OpenClaw`: 需预先安装并运行过 OpenClaw（确保 `~/.openclaw/openclaw.json` 存在）。

## 支持的模型

目前脚本内置支持多种主流模型，包括但不限于：

### Anthropic
*   `claude-opus-4-5-thinking`
*   `claude-sonnet-4-5`
*   `claude-sonnet-4-5-thinking`

### DeepSeek
*   `deepseek-ai/DeepSeek-R1`
*   `deepseek-ai/DeepSeek-R1-0528`
*   `deepseek-ai/DeepSeek-V3.1`
*   `deepseek-ai/DeepSeek-V3.1-Terminus`
*   `deepseek-ai/DeepSeek-V3.2-Exp`

### Google
*   `gemini-3-flash-preview`
*   `gemini-3-pro-preview`
*   `gemini-2.5-flash`

### Minimax
*   `MiniMaxAI/MiniMax-M2.1`

### Moonshot
*   `moonshotai/Kimi-K2.5`
*   `moonshotai/Kimi-K2-Thinking`

### OpenAI
*   `gpt-5.2`
*   `openai/gpt-oss-120b`

### 字节跳动 (ByteDance)
*   `doubao-seed-code-preview-251028`

### Z.Ai (GLM)
*   `zai-org/GLM-4.7`
*   `zai-org/GLM-4.6V`

### Qwen (通义千问)
*   `qwen3-coder-plus`
*   `qwen3-max` (默认)
*   `qwen3-max-preview`
*   `qwen3-vl-plus`
*   `Qwen/Qwen3-Coder-480B-A35B-Instruct`
*   `qwen3-vl-max`

*(具体模型列表请以脚本内实际显示为准)*

## 免责声明

本工具仅作为第三方配置管理辅助工具，与 OpenClaw 或 RealmRouter 官方无直接关联。使用前请自行备份重要数据。
