# Claude Code + FCC 一键安装脚本 (Termux/Android)

在 Android/Termux 上一键部署 **Claude Code + Free Claude Code (FCC) 代理**，配置第三方模型（OpenRouter、DeepSeek、OpenAI、Ollama 等），**无需 Anthropic 账号/登录**即可使用 `claude` 命令。

## 功能

- ✅ 自动安装 Node.js、npm、Claude Code、FCC
- ✅ 交互式配置 Model ID / API Base / API Key
- ✅ 自动生成 FCC 配置，预填第三方 Key，**绕过 Claude 登录**
- ✅ 可选 FCC Admin UI 汉化（中文面板）
- ✅ 生成 `~/.local/bin/claude` 一键启动脚本
- ✅ 自动加入 PATH，重开终端直接 `claude` 可用

## 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/qiuqiu-dot/claude-code-setup/main/setup.sh | bash
```

或克隆后运行：

```bash
git clone https://github.com/qiuqiu-dot/claude-code-setup.git
cd claude-code-setup
./setup.sh
```

## 交互示例

```
Model ID: nemotron-3-ultra-free
API Base URL: https://openrouter.ai/api/v1
API Key: sk-or-v1-xxxxxxxxxxxx
启用 FCC Admin UI 汉化? [Y/n]: Y
确认开始安装? [Y/n]: Y
```

## 安装后使用

```bash
source ~/.bashrc   # 或重开终端
claude             # 启动 FCC 代理
# 管理面板: http://localhost:3456/admin
```

## 常用模型配置参考

| 平台 | Model ID | API Base URL |
|------|----------|--------------|
| OpenRouter | `nemotron-3-ultra-free` / `gpt-4o` / `deepseek-chat` | `https://openrouter.ai/api/v1` |
| DeepSeek | `deepseek-chat` | `https://api.deepseek.com` |
| OpenAI | `gpt-4o` / `gpt-4o-mini` | `https://api.openai.com/v1` |
| 本地 Ollama | `llama3.1` / `qwen2.5` | `http://localhost:11434/v1` |

> **注意**：API Key 必须有效、有额度，Model ID 必须是该平台真实存在的模型名。Key 错误会导致 401/403。

## 目录结构

```
~/.claude-code-fcc/
├── config.json       # 模型/Key 配置
├── fcc-config.json   # FCC 运行配置
└── locales/zh-CN.json  # 汉化语言包 (可选)
```

## 更新/重装

```bash
cd ~/claude-code-setup
git pull
./setup.sh
```

## 卸载

```bash
rm -rf ~/.claude-code-fcc ~/.local/bin/claude
# 从 ~/.bashrc 中删除 PATH 行
```

## 原理说明

1. **Claude Code** (`@anthropic-ai/claude-code`) 是官方 CLI，默认请求 Anthropic API
2. **FCC (free-claude-code)** 是 Node.js 代理，把 Anthropic 格式请求转发到兼容 OpenAI 格式的任意端点
3. 脚本预填 `config.json` 里的 `apiKey`/`apiBase`，FCC 启动时自动带上 `Authorization: Bearer <Key>`，**完全绕过 `claude auth login`**

## 许可证

MIT