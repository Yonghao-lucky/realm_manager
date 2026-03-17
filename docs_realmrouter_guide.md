# RealmRouter 使用指南

欢迎使用 **RealmRouter**！本指南将帮助您快速上手，享受高效、稳定的模型服务。

## 📞 客户联系 (微信)
*   **小昭昭**: `yhz8661`
*   **婉清**: `okwwio123`

## 🌟 平台优势

*   **注册福利**：新用户注册即赠送 **5元** 体验金（约等于 300 次 gemini、codex 和 claude 调用），额度不够可在站点注册充值。
*   **免费额度**：每日签到可免费获得额度，签收好评也可以获得额外奖励。
*   **多模型支持**：汇聚 DeepSeek、Anthropic、Google、OpenAI 等前沿大模型。
*   **稳定高效**：提供企业级稳定的 API 接入服务。

## 🚀 快速开始

### 1. 访问与注册
*   **模型广场 (登录站点)**: [https://realmrouter.cn](https://realmrouter.cn)
*   **文档中心 (帮助中心)**: [https://docs.realmrouter.cn](https://docs.realmrouter.cn)

### 2. API 配置信息
在配置您的客户端（如 NextChat, OneAPI, LangChain 等）时，请使用以下信息：

*   **Base URL (接口地址)**: 
    *   `https://realmrouter.cn`
    *   如需完整接口路径：`https://realmrouter.cn/v1/chat/completions`
*   **API Key**: 请在 [模型广场](https://realmrouter.cn) 控制台获取。

---

## 🦞 OpenClaw (龙虾) 专属接入工具

我们为开发者提供了专属的接入工具 **OpenClaw**，支持 Linux/macOS 系统，助您一键配置和切换模型。

*   **仓库地址**: [https://github.com/Yonghao-lucky/realm_manager](https://github.com/Yonghao-lucky/realm_manager)
*   **功能亮点**:
    *   支持一键配置环境
    *   便捷的模型切换功能
    *   完美适配 Linux/macOS

---

## 推荐模型说明

RealmRouter 的可用模型会持续更新，推荐模型列表也会随服务端动态变化。

*   如果您使用本仓库里的 `realm_manager` 工具，模型菜单会实时请求 RealmRouter 的 `/v1/models`
*   实际可用模型、名称和分组请以控制台或接口实时返回结果为准
*   如果某个模型近期下线、无可用渠道或临时维护，脚本会在测试连通时直接提示

---

## 💡 常见问题 (FAQ)

### Q: 登录时提示“账户封禁”怎么办？
**A**: 这通常是因为复制用户名或密码时**多复制了空格**。请尝试重新仔细复制用户名和密码，确保没有包含首尾的空白字符。

### Q: 如何查询剩余额度和 Token 使用情况？
**A**: 请登录 [模型广场控制台](https://realmrouter.cn)，在个人中心即可查看当前的 Token 余额和使用明细。

### Q: 遇到其他问题如何解决？
**A**: 
1. 建议优先查阅 [文档中心](https://docs.realmrouter.cn)，大部分问题都能在其中找到答案。
2. 如文档无法解决，请联系平台客服（见文档开头联系方式）。
