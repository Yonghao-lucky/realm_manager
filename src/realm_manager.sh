#!/bin/bash
# realm_manager.sh
# OpenClaw RealmRouter Configuration Manager
# Description: 用于管理 OpenClaw 配置文件，支持 RealmRouter 增量注入、Key 验证及模型管理。

# ================= Configuration =================
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
CONFIG_DIR="$HOME/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
BACKUP_DIR="$CONFIG_DIR/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
API_BASE_URL="https://realmrouter.cn/v1"

# === ⚠️ 发布前请修改此 URL 为您的真实 GitHub 原始文件地址 ===
UPDATE_URL="https://raw.githubusercontent.com/Yonghao-lucky/realm_manager/main/src/realm_manager.sh"
README_URL="https://raw.githubusercontent.com/Yonghao-lucky/realm_manager/main/README.md"


# ================= Python Processor =================
read -r -d '' PYTHON_SCRIPT << 'EOF' || true
import sys
import json
import os
import urllib.request
import urllib.error

API_BASE_URL = "https://realmrouter.cn/v1"
DEFAULT_MODEL_ID = "gpt-5.4"

def load_json(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except json.JSONDecodeError:
        print("Error: JSON 解析失败，配置文件可能已损坏。", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print(f"Error: 找不到文件: {path}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: 读取配置文件失败: {e}", file=sys.stderr)
        sys.exit(1)

def save_json(path, data):
    try:
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print("Success: 配置文件已更新。")
    except Exception as e:
        print(f"Error: 保存配置文件失败: {e}", file=sys.stderr)
        sys.exit(1)

def classify_provider(model_id):
    model_id_lower = model_id.lower()
    if model_id.startswith("claude"):
        return "Anthropic"
    if model_id.startswith("gemini"):
        return "Google"
    if model_id.startswith("minimaxai/"):
        return "Minimax"
    if model_id.startswith("moonshotai/") or model_id.startswith("kimi"):
        return "Moonshot"
    if model_id.startswith("doubao"):
        return "ByteDance"
    if model_id.startswith("zai-org/") or model_id.startswith("glm"):
        return "Z.Ai"
    if model_id.startswith("qwen") or model_id.startswith("qwen/"):
        return "Qwen"
    if model_id.startswith("deepseek"):
        return "DeepSeek"
    if model_id.startswith("gpt") or model_id.startswith("openai/"):
        return "OpenAI"
    if "qwen" in model_id_lower:
        return "Qwen"
    if "deepseek" in model_id_lower:
        return "DeepSeek"
    return "Other"

def fetch_remote_models(api_key):
    request = urllib.request.Request(
        f"{API_BASE_URL}/models",
        headers={"Authorization": f"Bearer {api_key}"}
    )

    with urllib.request.urlopen(request, timeout=30) as response:
        payload = json.load(response)

    remote_models = []
    for item in payload.get("data", []):
        model_id = item.get("id")
        if not model_id:
            continue
        remote_models.append({
            "id": model_id,
            "name": item.get("name") or model_id,
            "provider": classify_provider(model_id)
        })

    remote_models.sort(key=lambda model: (model["provider"], model["name"].lower()))
    return remote_models

def get_realmrouter_config(api_key, models):
    return {
        "baseUrl": API_BASE_URL,
        "apiKey": api_key,
        "api": "openai-completions",
        "models": [{"id": model["id"], "name": model["name"]} for model in models]
    }

def action_install(file_path, api_key):
    data = load_json(file_path)
    
    if 'models' not in data: data['models'] = {}
    if 'providers' not in data['models']: data['models']['providers'] = {}
    if 'agents' not in data: data['agents'] = {}
    if 'defaults' not in data['agents']: data['agents']['defaults'] = {}
    if 'model' not in data['agents']['defaults']: data['agents']['defaults']['model'] = {}

    remote_models = fetch_remote_models(api_key)
    realm_config = get_realmrouter_config(api_key, remote_models)
    data['models']['providers']['realmrouter'] = realm_config
    print("Info: RealmRouter 配置已注入。")

    data['agents']['defaults']['model']['primary'] = f"realmrouter/{DEFAULT_MODEL_ID}"
    print(f"Info: 默认模型已切换为 realmrouter/{DEFAULT_MODEL_ID}。")

    save_json(file_path, data)

def action_update_key(file_path, api_key):
    data = load_json(file_path)
    try:
        if 'models' not in data or \
           'providers' not in data['models'] or \
           'realmrouter' not in data['models']['providers']:
            print("Error: 未找到 RealmRouter 配置，请先执行[安装/重置]。", file=sys.stderr)
            sys.exit(1)
            
        data['models']['providers']['realmrouter']['apiKey'] = api_key
        data['models']['providers']['realmrouter']['models'] = [
            {"id": model["id"], "name": model["name"]}
            for model in fetch_remote_models(api_key)
        ]
        print("Info: API Key 已更新。")
        save_json(file_path, data)
    except KeyError:
        print("Error: 配置文件结构异常。", file=sys.stderr)
        sys.exit(1)

def action_switch_model(file_path, model_id):
    data = load_json(file_path)
    try:
        if 'agents' not in data: data['agents'] = {}
        if 'defaults' not in data['agents']: data['agents']['defaults'] = {}
        if 'model' not in data['agents']['defaults']: data['agents']['defaults']['model'] = {}
        
        # 自动加上 realmrouter/ 前缀
        full_model_id = f"realmrouter/{model_id}"
        data['agents']['defaults']['model']['primary'] = full_model_id
        print(f"Info: 默认模型已切换为 {full_model_id}。")
        save_json(file_path, data)
    except Exception as e:
        print(f"Error: 切换模型失败: {e}", file=sys.stderr)
        sys.exit(1)

def action_get_key(file_path):
    data = load_json(file_path)
    try:
        if 'models' in data and \
           'providers' in data['models'] and \
           'realmrouter' in data['models']['providers'] and \
           'apiKey' in data['models']['providers']['realmrouter']:
            print(data['models']['providers']['realmrouter']['apiKey'])
        else:
            sys.exit(1)
    except Exception:
        sys.exit(1)

def action_get_model(file_path):
    data = load_json(file_path)
    try:
        if 'agents' in data and \
           'defaults' in data['agents'] and \
           'model' in data['agents']['defaults'] and \
           'primary' in data['agents']['defaults']['model']:
            print(data['agents']['defaults']['model']['primary'])
        else:
            sys.exit(1)
    except Exception:
        sys.exit(1)

def action_config_state(file_path):
    try:
        data = load_json(file_path)
    except SystemExit:
        print("invalid_json")
        return

    api_key = data.get('models', {}).get('providers', {}).get('realmrouter', {}).get('apiKey')
    if api_key:
        print("ok")
    else:
        print("missing_key")

def action_list_providers(file_path):
    data = load_json(file_path)
    api_key = data.get('models', {}).get('providers', {}).get('realmrouter', {}).get('apiKey')
    if not api_key:
        sys.exit(1)

    providers = []
    seen = set()
    for model in fetch_remote_models(api_key):
        provider = model['provider']
        if provider in seen:
            continue
        providers.append(provider)
        seen.add(provider)

    for provider in providers:
        print(provider)

def action_list_models_by_provider(file_path, provider):
    data = load_json(file_path)
    api_key = data.get('models', {}).get('providers', {}).get('realmrouter', {}).get('apiKey')
    if not api_key:
        sys.exit(1)

    for model in fetch_remote_models(api_key):
        if model['provider'] == provider:
            print(f"{model['id']}\t{model['name']}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(1)

    file_path = sys.argv[1]
    action = sys.argv[2]

    if action == "install":
        action_install(file_path, sys.argv[3])
    elif action == "update_key":
        action_update_key(file_path, sys.argv[3])
    elif action == "switch_model":
        action_switch_model(file_path, sys.argv[3])
    elif action == "get_key":
        action_get_key(file_path)
    elif action == "get_model":
        action_get_model(file_path)
    elif action == "config_state":
        action_config_state(file_path)
    elif action == "list_providers":
        action_list_providers(file_path)
    elif action == "list_models_by_provider":
        action_list_models_by_provider(file_path, sys.argv[3])
EOF

# ================= Helper Functions =================

check_env() {
    # 1. Check Python 3
    if ! command -v python3 &> /dev/null; then
        echo "❌ Error: 未检测到 Python 3 环境。"
        echo "请先安装 Python 3，然后重试。"
        exit 1
    fi

    # 2. Check Config File
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "❌ Error: 配置文件未找到: $CONFIG_FILE"
        echo "请确保 OpenClaw 已安装并初始化。"
        exit 1
    fi
}

get_config_state() {
    python3 -c "$PYTHON_SCRIPT" "$CONFIG_FILE" "config_state" 2>/dev/null
}

show_config_guidance() {
    local state
    state=$(get_config_state)

    if [ "$state" = "invalid_json" ]; then
        echo "❌ 检测到配置文件已损坏: $CONFIG_FILE"
        echo "请先执行 [1] 安装/重置，重新生成有效配置。"
        return 0
    fi

    if [ "$state" = "missing_key" ]; then
        echo "❌ 当前未检测到已配置的 RealmRouter API Key。"
        echo "请先执行 [1] 安装/重置 或 [2] 更换 Key。"
        return 0
    fi

    return 1
}

backup_config() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
    fi
    local backup_file="$BACKUP_DIR/openclaw.json.bak.$TIMESTAMP"
    cp "$CONFIG_FILE" "$backup_file"
    if [ $? -eq 0 ]; then
        echo "✅ 已创建备份: $backup_file"
    else
        echo "❌ 备份失败，操作取消。"
        exit 1
    fi
}

verify_api_key() {
    local key="$1"
    local silent="${2:-false}"
    echo -n "⏳ 正在验证 API Key 有效性... "

    local response
    local http_code

    response=$(curl -s -w "\n%{http_code}" -X GET "$API_BASE_URL/models" \
        -H "Authorization: Bearer $key" \
        -H "Content-Type: application/json" 2>/dev/null)

    http_code=$(python3 -c 'import sys; data=sys.stdin.read().splitlines(); print(data[-1] if data else "")' <<< "$response")

    if [ "$http_code" = "200" ]; then
        echo "✅ 成功。"
        return 0
    fi

    echo "⚠️ 失败 (HTTP ${http_code:-无响应})。"
    echo "可能原因: Key 无效、权限不足或网络问题。"
    if [ "$silent" = "true" ]; then
        return 1
    fi

    read -p "是否强制继续？(y/N): " force
    if [[ "$force" =~ ^[Yy]$ ]]; then
        return 0
    fi
    return 1
}

test_model_connectivity() {
    local key="$1"
    local model_id="${2:-gpt-5.4}"
    local silent="${3:-false}"
    echo -n "⏳ 正在测试模型连通性... "

    local payload="{\"model\": \"$model_id\", \"messages\": [{\"role\": \"user\", \"content\": \"hi\"}], \"max_tokens\": 1}"
    local response
    local http_code

    response=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE_URL/chat/completions" \
        -H "Authorization: Bearer $key" \
        -H "Content-Type: application/json" \
        -d "$payload" 2>/dev/null)

    http_code=$(python3 -c 'import sys; data=sys.stdin.read().splitlines(); print(data[-1] if data else "")' <<< "$response")

    if [ "$http_code" = "200" ]; then
        echo "✅ 成功。"
        return 0
    fi

    echo "⚠️ 失败 (HTTP ${http_code:-无响应})。"
    echo "可能原因: 当前模型不可用、余额不足、模型名称错误或网络问题。"
    if [ "$silent" = "true" ]; then
        return 1
    fi

    read -p "是否强制继续？(y/N): " force
    if [[ "$force" =~ ^[Yy]$ ]]; then
        return 0
    fi
    return 1
}

restore_backup() {
    echo -e "\n=== 还原备份 ==="
    local backups=($(ls -t "$BACKUP_DIR" 2>/dev/null | head -n 10))
    
    if [ ${#backups[@]} -eq 0 ]; then
        echo "   (无备份文件)"
        return
    fi

    for i in "${!backups[@]}"; do
        echo "   [$((i+1))] ${backups[$i]}"
    done
    echo "   [0] 返回上级"

    read -p "请选择: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -gt 0 ] && [ "$choice" -le "${#backups[@]}" ]; then
        local selected_backup="${backups[$((choice-1))]}"
        cp "$BACKUP_DIR/$selected_backup" "$CONFIG_FILE"
        echo "✅ 已还原备份: $selected_backup"
        echo "⚠️ 请手动执行 'openclaw gateway restart' 以应用更改。"
    fi
}

# ================= Model Selection Logic =================
# Helper for switch_to to avoid duplication
switch_to() {
    local model_id="$1"
    echo "正在切换到模型: $model_id ..."
    backup_config
    python3 -c "$PYTHON_SCRIPT" "$CONFIG_FILE" "switch_model" "$model_id"
    echo "⚠️ 请手动执行 'openclaw gateway restart' 以应用更改。"
    read -p "按回车键返回主菜单..."
}

show_provider_model_menu() {
    local provider="$1"
    local model_lines

    model_lines=$(python3 -c "$PYTHON_SCRIPT" "$CONFIG_FILE" "list_models_by_provider" "$provider" 2>/dev/null)
    if [ -z "$model_lines" ]; then
        echo "❌ 未获取到 $provider 的可用模型。"
        read -p "按回车键返回..."
        return
    fi

    local models=()
    while IFS= read -r line; do
        [ -n "$line" ] && models+=("$line")
    done <<< "$model_lines"

    while true; do
        echo -e "\n--- $provider Models ---"
        local i=1
        for model_line in "${models[@]}"; do
            local model_name=${model_line#*$'\t'}
            echo "[$i] $model_name"
            i=$((i+1))
        done
        echo "[0] 返回上级"

        read -p "Select Model: " c
        if [[ "$c" =~ ^[0-9]+$ ]]; then
            if [ "$c" -eq 0 ]; then
                return
            fi
            if [ "$c" -ge 1 ] && [ "$c" -le "${#models[@]}" ]; then
                local selected=${models[$((c-1))]}
                switch_to "${selected%%$'\t'*}"
                return
            fi
        fi
        echo "无效选择"
    done
}

process_switch_model_menu() {
    local provider_lines
    provider_lines=$(python3 -c "$PYTHON_SCRIPT" "$CONFIG_FILE" "list_providers" 2>/dev/null)
    if [ -z "$provider_lines" ]; then
        echo ""
        if ! show_config_guidance; then
            echo "❌ 无法实时获取模型列表。请确认网络正常后重试。"
        fi
        read -p "按回车键继续..."
        return
    fi

    local providers=()
    while IFS= read -r line; do
        [ -n "$line" ] && providers+=("$line")
    done <<< "$provider_lines"

    while true; do
        echo -e "\n=== 切换默认模型 (实时获取) ==="
        local i=1
        for provider in "${providers[@]}"; do
            echo " [$i] $provider"
            i=$((i+1))
        done
        echo " [0] 返回主菜单"
        
        read -p "请输入发行商编号: " p_choice
        if [[ "$p_choice" =~ ^[0-9]+$ ]]; then
            if [ "$p_choice" -eq 0 ]; then
                return
            fi
            if [ "$p_choice" -ge 1 ] && [ "$p_choice" -le "${#providers[@]}" ]; then
                show_provider_model_menu "${providers[$((p_choice-1))]}"
            else
                echo "❌ 无效的选择"
            fi
        else
            echo "❌ 无效的选择"
        fi
    done
}

process_install() {
    echo -e "\n=== 安装/重置 RealmRouter 配置 ==="
    read -p "请输入您的 API Key: " api_key
    if [ -z "$api_key" ]; then
        echo "❌ API Key 不能为空。"
        return
    fi
    
    # Verify Key
    if verify_api_key "$api_key"; then
        backup_config
        python3 -c "$PYTHON_SCRIPT" "$CONFIG_FILE" "install" "$api_key"
        echo "⚠️ 请手动执行 'openclaw gateway restart' 以应用更改。"
        read -p "按回车键继续..."
    fi
}

process_update_key() {
    echo -e "\n=== 更换 RealmRouter API Key ==="
    read -p "请输入新的 API Key: " api_key
    if [ -z "$api_key" ]; then
        echo "❌ API Key 不能为空。"
        return
    fi

    # Verify Key
    if verify_api_key "$api_key"; then
        backup_config
        python3 -c "$PYTHON_SCRIPT" "$CONFIG_FILE" "update_key" "$api_key"
        echo "⚠️ 请手动执行 'openclaw gateway restart' 以应用更改。"
        read -p "按回车键继续..."
    fi
}

process_test_connectivity() {
    echo -e "\n=== 测试 Key 连通性 ==="
    
    # 从配置文件读取当前 Key
    local current_key
    current_key=$(python3 -c "$PYTHON_SCRIPT" "$CONFIG_FILE" "get_key")
    
    # 读取当前模型
    local current_model
    current_model=$(python3 -c "$PYTHON_SCRIPT" "$CONFIG_FILE" "get_model")
    
    # 去除 realmrouter/ 前缀
    local real_model_id=${current_model#realmrouter/}
    
    # 如果没获取到，默认回退到 gpt-5.4
    if [ -z "$real_model_id" ]; then
        real_model_id="gpt-5.4"
    fi

    if [ -z "$current_key" ]; then
        if ! show_config_guidance; then
            echo "❌ Error: 未找到已配置的 API Key。"
            echo "请先执行 [1] 安装/重置 或 [2] 更换 Key。"
        fi
        read -p "按回车键返回..."
        return
    fi
    
    echo "正在测试当前 Key 的连通性..."
    echo "API Endpoint: $API_BASE_URL/chat/completions"
    echo "测试模型: $real_model_id"
    echo "----------------------------------------"
    
    test_model_connectivity "$current_key" "$real_model_id" "true"
    local result=$?
    
    echo "----------------------------------------"
    if [ $result -eq 0 ]; then
        echo "✅ 测试通过: Key 有效且连接正常。"
    else
        echo "❌ 测试失败: 无法连接或 Key 无效。"
    fi
    
    read -p "按回车键继续..."
}

process_update_script() {
    echo -e "\n=== 更新脚本 ==="
    echo "正在从远程仓库获取最新版本..."
    
    local temp_file="/tmp/realm_manager_new.sh"
    
    if curl -sSL "$UPDATE_URL" -o "$temp_file"; then
        # 简单检查下载的文件是否完整 (比如包含特定关键词)
        if grep -q "OpenClaw RealmRouter Configuration Manager" "$temp_file"; then
            # 覆盖当前脚本
            mv "$temp_file" "$SCRIPT_PATH"
            chmod +x "$SCRIPT_PATH"
            echo "✅ 脚本核心文件已更新。"
            
            # 尝试更新 README.md
            echo "正在获取最新文档..."
            if curl -sSL "$README_URL" -o "$SCRIPT_DIR/../README.md"; then
                echo "✅ 文档(README.md)已更新。"
            else
                echo "⚠️ 文档更新失败，但这不影响脚本使用。"
            fi
            
            echo "更新完成！请重新运行脚本以加载新功能。"
            exit 0
        else
            echo "❌ 下载的文件似乎已损坏或不是有效的脚本。"
            rm -f "$temp_file"
        fi
    else
        echo "❌ 下载失败，请检查网络连接或 GitHub 是否可访问。"
    fi
    read -p "按回车键继续..."
}

# ================= Main Menu =================
# Pre-flight Check
check_env

while true; do
    clear
    echo "========================================"
    echo "    RealmRouter 配置管理工具 v2.3"
    echo "========================================"
    echo " [1] 安装/重置 (注入 RealmRouter 配置)"
    echo " [2] 更换 Key  (更新 API Key)"
    echo " [3] 切换模型  (修改默认 AI 模型)"
    echo " [4] 还原备份  (从历史备份恢复)"
    echo " [5] 测试连通  (测试 Key 有效性)"
    echo " [6] 更新脚本  (获取最新版本)"
    echo " [q] 退出"
    
    echo ""
    read -p "请输入选项编号并回车: " choice
    
    case $choice in
        1) process_install ;;
        2) process_update_key ;;
        3) process_switch_model_menu ;;
        4) restore_backup; read -p "按回车键继续..." ;;
        5) process_test_connectivity ;;
        6) process_update_script ;;
        q|Q) echo "Bye!"; exit 0 ;;
        *) echo "❌ 无效的输入"; sleep 1 ;;
    esac
done
