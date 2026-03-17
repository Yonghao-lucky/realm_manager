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

*   **一键安装/重置**: 自动将 RealmRouter 的配置注入到 `openclaw.json`，并同步写入当前服务端返回的最新模型列表。
*   **模型切换**: 支持按发行商分类浏览模型，菜单会在运行时实时请求 RealmRouter 的 `/v1/models`，避免内置列表过期。
*   **API Key 管理**: 使用 `/v1/models` 快速验证 RealmRouter API Key 是否可用，并在更新 Key 时同步刷新模型列表。
*   **智能连通性测试**: 使用当前选中的模型真实调用 `/v1/chat/completions`，检测当前模型的可用性和网络连通状况。
*   **配置备份与还原**: 每次修改前自动备份配置文件，支持从历史备份中一键还原，安全无忧。
*   **脚本自动更新**: 支持从 GitHub 拉取最新版本的脚本，时刻保持功能最新。

## 快速开始

### 方式一：使用源码运行（Linux/macOS）

如果您熟悉 Shell 脚本，可以直接运行源码。

```bash
git clone https://github.com/Yonghao-lucky/realm_manager.git
cd realm_manager
chmod +x src/realm_manager.sh
./src/realm_manager.sh
```

### 方式二：Windows PowerShell

Windows 用户可以直接使用 PowerShell 脚本，无需安装额外依赖。

**直接运行（推荐）：**
```powershell
# 下载并运行
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Yonghao-lucky/realm_manager/main/src/realm_manager.ps1" -OutFile "realm_manager.ps1"
.\realm_manager.ps1
```

**或从源码运行：**
```powershell
git clone https://github.com/Yonghao-lucky/realm_manager.git
cd realm_manager
.\src\realm_manager.ps1
```

> **注意**: 如果遇到执行策略限制，请先运行以下命令：
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

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
*   脚本会通过 `GET /v1/models` 自动验证 Key 的有效性。
*   验证通过后，脚本会将 RealmRouter 的配置信息写入到 `~/.openclaw/openclaw.json` 中，并将默认模型设置为 `realmrouter/gpt-5.4`。
*   安装过程中会同步写入当前 RealmRouter 返回的模型列表，供后续实时切换使用。

### [2] 更换 Key
如果您的 API Key 发生变更或失效，使用此选项更新。
*   输入新的 API Key。
*   验证成功后自动更新配置文件。
*   更新 Key 时会重新拉取最新模型列表并写回配置。

### [3] 切换模型
想要更换 OpenClaw 使用的默认 AI 模型时使用。
*   脚本会读取当前配置中的 RealmRouter API Key，并实时请求 `/v1/models` 获取最新模型列表。
*   模型列表会按发行商自动分组显示，避免因脚本内置列表过期而切换失败。
*   选择对应的分类和模型后，脚本会自动修改配置文件中的默认模型。

### [4] 还原备份
脚本在每次修改配置文件前都会自动创建一个备份文件。
*   选择此选项可以查看最近的备份列表。
*   选择一个备份文件即可将配置恢复到当时的状态。

### [5] 测试连通
当您遇到模型无法回答或报错时，使用此功能进行诊断。
*   脚本会自动读取当前配置的 API Key 和 **当前选中的默认模型**。
*   先用 `/v1/models` 验证 Key，再对当前模型发起真实的对话请求（发送 "hi"）测试服务器响应。
*   如果当前模型不可用、模型 ID 不存在或网络异常，这里会直接给出错误提示。

### [6] 更新脚本
检查并下载脚本的最新版本，确保您拥有最新的模型列表和功能修复。

## ⚠️ 重要提示

如果 `~/.openclaw/openclaw.json` 或 `%USERPROFILE%\.openclaw\openclaw.json` 已损坏、不是合法 JSON，脚本会明确提示配置文件损坏。此时请优先执行 **[1] 安装/重置** 重新生成配置，而不是误判为网络问题。

每次使用本工具修改配置（如安装、切换模型、更换 Key）后，**必须手动重启 OpenClaw 网关**才能使更改生效：

```bash
openclaw gateway restart
```

## 前置要求

### Linux / macOS
*   **操作系统**: Linux 或 macOS (支持 Bash 环境)
*   **依赖工具**:
    *   `curl`: 用于网络请求和下载。
    *   `python3`: 用于解析和修改 JSON 配置文件。
    *   `OpenClaw`: 需预先安装并运行过 OpenClaw（确保 `~/.openclaw/openclaw.json` 存在）。

### Windows
*   **操作系统**: Windows 10/11 (支持 PowerShell 5.1+)
*   **依赖工具**:
    *   PowerShell 5.1 或更高版本（Windows 默认已安装）
    *   `Invoke-WebRequest`: 用于网络请求（PowerShell 内置）
    *   `OpenClaw`: 需预先安装并运行过 OpenClaw（确保 `%USERPROFILE%\.openclaw\openclaw.json` 存在）。

## 支持的模型

脚本不再内置固定模型清单，而是在运行时直接读取 RealmRouter `/v1/models` 返回结果。

*   默认模型为 `gpt-5.4`
*   切换模型菜单会实时显示当前账号真正可用的模型
*   具体模型数量、名称和发行商分组会随 RealmRouter 服务端更新而变化

## 免责声明

本工具仅作为第三方配置管理辅助工具，与 OpenClaw 或 RealmRouter 官方无直接关联。使用前请自行备份重要数据。
