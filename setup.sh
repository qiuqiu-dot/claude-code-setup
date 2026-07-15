#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_err()   { echo -e "${RED}[ERR]${NC} $*"; }

CONFIG_DIR="$HOME/.claude-code-fcc"
BIN_DIR="$HOME/.local/bin"
START_SCRIPT="$BIN_DIR/claude"

MODEL_ID=""
API_BASE=""
API_KEY=""
ENABLE_ZH=false

ask_model_config() {
    echo -e "${BLUE}=== Claude Code + FCC 安装配置 ===${NC}"
    echo

    read -rp "Model ID (如: gpt-4o, claude-3-5-sonnet, deepseek-chat): " MODEL_ID
    [[ -z "$MODEL_ID" ]] && { log_err "Model ID 不能为空"; exit 1; }

    read -rp "API Base URL (默认: https://api.openai.com/v1): " API_BASE
    API_BASE=${API_BASE:-"https://api.openai.com/v1"}

    read -rp "API Key: " API_KEY
    [[ -z "$API_KEY" ]] && { log_err "API Key 不能为空"; exit 1; }

    read -rp "启用 FCC Admin UI 汉化? [Y/n]: " ZH_CN
    ZH_CN=${ZH_CN:-Y}
    [[ "$ZH_CN" =~ ^[Yy]$ ]] && ENABLE_ZH=true || ENABLE_ZH=false

    echo
    log_info "配置汇总:"
    echo "  Model ID: $MODEL_ID"
    echo "  API Base: $API_BASE"
    echo "  API Key:  ${API_KEY:0:8}****"
    echo "  汉化 UI:  $([ "$ENABLE_ZH" = true ] && echo "是" || echo "否")"
    echo
    read -rp "确认开始安装? [Y/n]: " CONFIRM
    [[ "$CONFIRM" =~ ^[Nn]$ ]] && { log_info "已取消"; exit 0; }
}

install_deps() {
    log_info "安装基础依赖 (可能需要 1-2 分钟)..."
    DEBIAN_FRONTEND=noninteractive pkg update -y -o DPkg::Options::="--force-confdef" -o DPkg::Options::="--force-confold" \
        && pkg install -y -o DPkg::Options::="--force-confdef" -o DPkg::Options::="--force-confold" nodejs npm git curl unzip python3
    log_ok "依赖安装完成"
}

install_claude_code() {
    log_info "安装 Claude Code..."
    npm install -g @anthropic-ai/claude-code --allow-scripts 2>/dev/null || npm install -g @anthropic-ai/claude-code
    log_ok "Claude Code 安装完成"
}

install_fcc() {
    log_info "安装 FCC (Free Claude Code)..."
    npm install -g free-claude-code
    log_ok "FCC 安装完成"
}

configure_fcc() {
    log_info "配置 FCC..."

    mkdir -p "$CONFIG_DIR"

    cat > "$CONFIG_DIR/config.json" <<EOF
{
  "model": "$MODEL_ID",
  "apiBase": "$API_BASE",
  "apiKey": "$API_KEY",
  "temperature": 0.7,
  "maxTokens": 8192
}
EOF

    cat > "$CONFIG_DIR/fcc-config.json" <<EOF
{
  "claudeCodePath": "claude",
  "configPath": "$CONFIG_DIR/config.json",
  "port": 3456,
  "host": "0.0.0.0",
  "adminEnabled": true,
  "adminPath": "/admin",
  "logLevel": "info"
}
EOF

    log_ok "FCC 配置写入: $CONFIG_DIR"
}

setup_zh_admin() {
    [[ "$ENABLE_ZH" != true ]] && return

    log_info "应用 FCC Admin UI 汉化..."

    FCC_ROOT=$(npm root -g)/free-claude-code
    ADMIN_DIR="$FCC_ROOT/admin"

    if [[ ! -d "$ADMIN_DIR" ]]; then
        log_warn "未找到 FCC admin 目录，跳过汉化"
        return
    fi

    mkdir -p "$ADMIN_DIR/locales"
    cat > "$ADMIN_DIR/locales/zh-CN.json" <<'ZHEOF'
{
  "app": { "title": "FCC 管理面板", "subtitle": "Free Claude Code 代理管理" },
  "nav": { "dashboard": "仪表盘", "models": "模型管理", "keys": "API Key 管理", "logs": "请求日志", "settings": "设置" },
  "dashboard": { "totalRequests": "总请求数", "totalTokens": "总 Token 数", "avgLatency": "平均延迟", "errorRate": "错误率", "recentRequests": "最近请求" },
  "models": { "title": "模型配置", "addModel": "添加模型", "modelId": "模型 ID", "provider": "提供商", "apiBase": "API 基础地址", "apiKey": "API Key", "enabled": "启用", "actions": "操作", "edit": "编辑", "delete": "删除", "save": "保存", "cancel": "取消" },
  "keys": { "title": "API Key 管理", "addKey": "添加 Key", "key": "Key", "name": "名称", "usage": "用量", "lastUsed": "最后使用" },
  "logs": { "title": "请求日志", "method": "方法", "path": "路径", "status": "状态", "latency": "耗时", "tokens": "Tokens", "time": "时间", "request": "请求体", "response": "响应体" },
  "settings": { "title": "系统设置", "port": "端口", "host": "监听地址", "logLevel": "日志级别", "language": "语言", "save": "保存设置" },
  "common": { "loading": "加载中...", "success": "成功", "error": "错误", "confirm": "确认", "close": "关闭", "refresh": "刷新" }
}
ZHEOF
    log_ok "中文语言包已写入"
}

create_start_script() {
    log_info "生成一键启动脚本..."

    mkdir -p "$BIN_DIR"

    cat > "$START_SCRIPT" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

CONFIG_DIR="$HOME/.claude-code-fcc"
FCC_CONFIG="$CONFIG_DIR/fcc-config.json"

if [[ ! -f "$FCC_CONFIG" ]]; then
    echo "未找到配置，请先运行安装脚本"
    exit 1
fi

cd "$CONFIG_DIR"
exec free-claude-code --config "$FCC_CONFIG" "$@"
EOF

    chmod +x "$START_SCRIPT"
    log_ok "启动脚本创建: $START_SCRIPT"
}

setup_path() {
    log_info "配置环境变量..."

    SHELL_RC=""
    case "$SHELL" in
        */bash) SHELL_RC="$HOME/.bashrc" ;;
        */zsh)  SHELL_RC="$HOME/.zshrc" ;;
        */fish) SHELL_RC="$HOME/.config/fish/config.fish" ;;
        *)      SHELL_RC="$HOME/.profile" ;;
    esac

    PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'

    if ! grep -q "$PATH_LINE" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# Claude Code + FCC" >> "$SHELL_RC"
        echo "$PATH_LINE" >> "$SHELL_RC"
        log_ok "已添加到 $SHELL_RC"
    else
        log_ok "PATH 已配置"
    fi

    export PATH="$HOME/.local/bin:$PATH"
}

print_summary() {
    echo
    echo -e "${GREEN}=== 安装完成！ ===${NC}"
    echo
    echo "使用方法:"
    echo "  1. 重新打开终端，或执行: source $SHELL_RC"
    echo "  2. 直接输入: claude"
    echo
    echo "管理面板: http://localhost:3456/admin"
    echo "配置目录: $CONFIG_DIR"
    echo "启动脚本: $START_SCRIPT"
    echo
    echo "常用命令:"
    echo "  claude              # 启动 FCC 代理"
    echo "  claude --help       # 查看帮助"
    echo "  claude --port 8080  # 指定端口"
    echo
    log_info "现在可以运行 'claude' 开始使用了"
}

main() {
    log_info "开始安装..."
    ask_model_config
    install_deps
    install_claude_code
    install_fcc
    configure_fcc
    setup_zh_admin
    create_start_script
    setup_path
    print_summary
}

main "$@"