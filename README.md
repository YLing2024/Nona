# Nona

一款简洁高效的 AI 聊天客户端，兼容 OpenAI 格式接口，支持多服务商、多模型、多会话管理与 Agent 预设，可自行配置 API Key 接入任意兼容服务商。

## 功能特性

- **多服务商配置**：可添加多个服务商（OpenAI 或任何兼容 OpenAI 格式的第三方），各自独立配置 Base URL 与 API Key；支持调用 `/models` 接口获取模型列表并多选启用
- **会话管理**：多会话的新建、切换、删除与本地持久化；会话标题自动取首条用户消息
- **匿名会话**：完全独立的内存会话，不保存记录、不出现在会话列表中
- **Agent 预设**：可配置多个 Agent（名称 + 完整上下文参数），设置默认 Agent 后单击「新建会话」自动套用；长按「新建会话」可指定 Agent 创建会话
- **会话上下文**：每个会话可独立配置系统提示词、Temperature、Top P、Max Tokens、Presence/Frequency Penalty、N、Stop、Seed、Response Format、思考强度等 OpenAI 参数，每项带说明（tips）
- **流式输出**：SSE 流式渲染，Markdown 实时渲染，思考内容（reasoning）可展开/收起；滚动跟随策略：仅在停在底部时自动滚动
- **多行输入**：输入框最大 5 行，工具条可直接切换模型、思考强度与流式开关
- **主题**：浅色 / 深色（OLED 纯黑）/ 跟随系统

## 快速开始

```bash
flutter pub get
flutter run
```

1. 打开应用后，点击左侧抽屉底部「设置」→「服务商」
2. 添加服务商：填写名称、Base URL（如 `https://api.openai.com/v1`）与 API Key
3. 点击「获取模型列表」拉取可用模型并勾选启用
4. 回到聊天页即可开始对话（可在输入框上方工具条切换模型）

> 支持任意 OpenAI 兼容接口：修改 Base URL 即可接入 OpenAI、DeepSeek、通义千问等第三方服务商。

## 项目结构

```
lib/
├── main.dart                        # 应用入口与主题
├── models/                          # 数据模型（消息/会话/上下文/服务商/Agent）
├── services/                        # 业务服务（聊天/存储/配置）
├── screens/                         # 页面（聊天/设置/会话上下文/服务商/Agent）
└── widgets/                         # 复用组件（上下文参数表单）
```

## 技术说明

- Flutter + Material 3
- 依赖：`http`（API 请求）、`shared_preferences`（本地存储）、`flutter_markdown`（Markdown 渲染）
- 兼容 OpenAI Chat Completions 与 `/models` 接口格式
