#!/bin/bash
# realm_manager.sh
# OpenClaw RealmRouter Configuration Manager
# Description: 用于管理 OpenClaw 配置文件，支持 RealmRouter 增量注入、Key 验证及模型管理。

set -e

# ================= Configuration =================
CONFIG_DIR="$HOME/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
BACKUP_DIR="$CONFIG_DIR/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
API_BASE_URL="https://realmrouter.cn/v1"

# === ⚠️ 发布前请修改此 URL 为您的真实 GitHub 原始文件地址 ===
UPDATE_URL="https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/realm_manager.sh"


# ================= Python Processor =================
read -r -d '' PYTHON_SCRIPT << 'EOF'
import sys
import json
import os

def load_json(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except json.JSONDecodeError:
        print("Error: JSON 解析失败，配置文件可能已损坏。")
        sys.exit(1)
    except FileNotFoundError:
        print(f"Error: 找不到文件: {path}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: 读取配置文件失败: {e}")
        sys.exit(1)

def save_json(path, data):
    try:
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print("Success: 配置文件已更新。")
    except Exception as e:
        print(f"Error: 保存配置文件失败: {e}")
        sys.exit(1)

def get_realmrouter_config(api_key):
    # 完整的模型列表
    return {
        "baseUrl": "https://realmrouter.cn/v1",
        "apiKey": api_key,
        "api": "openai-completions",
        "models": [
            # Anthropic
            { "id": "claude-opus-4-5-thinking", "name": "Claude Opus 4.5 Thinking" },
            { "id": "claude-sonnet-4-5", "name": "Claude Sonnet 4.5" },
            { "id": "claude-sonnet-4-5-thinking", "name": "Claude Sonnet 4.5 Thinking" },
            
            # DeepSeek
            { "id": "deepseek-ai/DeepSeek-R1", "name": "DeepSeek R1" },
            { "id": "deepseek-ai/DeepSeek-R1-0528", "name": "DeepSeek R1 (0528)" },
            { "id": "deepseek-ai/DeepSeek-V3.1", "name": "DeepSeek V3.1" },
            { "id": "deepseek-ai/DeepSeek-V3.1-Terminus", "name": "DeepSeek V3.1 Terminus" },
            { "id": "deepseek-ai/DeepSeek-V3.2-Exp", "name": "DeepSeek V3.2 Exp" },
            
            # Google
            { "id": "gemini-3-flash-preview", "name": "Gemini 3 Flash Preview" },
            { "id": "gemini-3-pro-preview", "name": "Gemini 3 Pro Preview" },
            { "id": "gemini-2.5-flash", "name": "Gemini 2.5 Flash" },
            
            # Minimax
            { "id": "MiniMaxAI/MiniMax-M2.1", "name": "MiniMax M2.1" },
            
            # Moonshot
            { "id": "moonshotai/Kimi-K2.5", "name": "Kimi K2.5" },
            { "id": "moonshotai/Kimi-K2-Thinking", "name": "Kimi K2 Thinking" },
            
            # OpenAI
            { "id": "gpt-5.2", "name": "GPT-5.2" },
            { "id": "openai/gpt-oss-120b", "name": "GPT OSS 120B" },
            
            # 字节跳动 (ByteDance)
            { "id": "doubao-seed-code-preview-251028", "name": "Doubao Seed Code Preview" },
            
            # Z.Ai
            { "id": "zai-org/GLM-4.7", "name": "GLM 4.7" },
            { "id": "zai-org/GLM-4.6V", "name": "GLM 4.6V" },
            
            # Qwen
            { "id": "qwen3-coder-plus", "name": "Qwen3 Coder Plus" },
            { "id": "qwen3-max", "name": "Qwen3 Max" },
            { "id": "qwen3-max-preview", "name": "Qwen3 Max Preview" },
            { "id": "qwen3-vl-plus", "name": "Qwen3 VL Plus" },
            { "id": "Qwen/Qwen3-Coder-480B-A35B-Instruct", "name": "Qwen3 Coder 480B" },
            { "id": "qwen3-vl-max", "name": "Qwen3 VL Max" }
        ]
    }

def action_install(file_path, api_key):
    data = load_json(file_path)
    
    if 'models' not in data: data['models'] = {}
    if 'providers' not in data['models']: data['models']['providers'] = {}
    if 'agents' not in data: data['agents'] = {}
    if 'defaults' not in data['agents']: data['agents']['defaults'] = {}
    if 'model' not in data['agents']['defaults']: data['agents']['defaults']['model'] = {}

    realm_config = get_realmrouter_config(api_key)
    data['models']['providers']['realmrouter'] = realm_config
    print("Info: RealmRouter 配置已注入。")

    # 默认模型: realmrouter/qwen3-max
    data['agents']['defaults']['model']['primary'] = "realmrouter/qwen3-max"
    print("Info: 默认模型已切换为 realmrouter/qwen3-max。")

    save_json(file_path, data)

def action_update_key(file_path, api_key):
    data = load_json(file_path)
    try:
        if 'models' not in data or \
           'providers' not in data['models'] or \
           'realmrouter' not in data['models']['providers']:
            print("Error: 未找到 RealmRouter 配置，请先执行[安装/重置]。")
            sys.exit(1)
            
        data['models']['providers']['realmrouter']['apiKey'] = api_key
        print("Info: API Key 已更新。")
        save_json(file_path, data)
    except KeyError:
        print("Error: 配置文件结构异常。")
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
        print(f"Error: 切换模型失败: {e}")
        sys.exit(1)

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
    echo -n "⏳ 正在验证 API Key 有效性... "
    
    # 使用 /v1/models 接口验证
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $key" "$API_BASE_URL/models")
    
    if [ "$http_code" -eq 200 ]; then
        echo "✅ 成功。"
        return 0
    else
        echo "⚠️ 失败 (HTTP $http_code)。"
        echo "可能原因: Key 无效、余额不足或网络问题。"
        read -p "是否强制继续？(y/N): " force
        if [[ "$force" =~ ^[Yy]$ ]]; then
            return 0
        else
            return 1
        fi
    fi
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
    fi
}

# ================= Model Selection Logic =================
# Helper for switch_to to avoid duplication
switch_to() {
    local model_id="$1"
    echo "正在切换到模型: $model_id ..."
    backup_config
    python3 -c "$PYTHON_SCRIPT" "$CONFIG_FILE" "switch_model" "$model_id"
    read -p "按回车键返回主菜单..."
}

select_anthropic() {
    while true; do
        echo -e "\n--- Anthropic Models ---"
        echo "1. claude-opus-4-5-thinking"
        echo "2. claude-sonnet-4-5"
        echo "3. claude-sonnet-4-5-thinking"
        echo "0. 返回上级"
        read -p "Select Model: " c; case $c in
            1) switch_to "claude-opus-4-5-thinking"; return ;;
            2) switch_to "claude-sonnet-4-5"; return ;;
            3) switch_to "claude-sonnet-4-5-thinking"; return ;;
            0) return ;; *) echo "无效选择" ;; esac
    done
}

select_deepseek() {
    while true; do
        echo -e "\n--- DeepSeek Models ---"
        echo "1. DeepSeek-R1"
        echo "2. DeepSeek-R1 (0528)"
        echo "3. DeepSeek-V3.1"
        echo "4. DeepSeek-V3.1-Terminus"
        echo "5. DeepSeek-V3.2-Exp"
        echo "0. 返回上级"
        read -p "Select Model: " c; case $c in
            1) switch_to "deepseek-ai/DeepSeek-R1"; return ;;
            2) switch_to "deepseek-ai/DeepSeek-R1-0528"; return ;;
            3) switch_to "deepseek-ai/DeepSeek-V3.1"; return ;;
            4) switch_to "deepseek-ai/DeepSeek-V3.1-Terminus"; return ;;
            5) switch_to "deepseek-ai/DeepSeek-V3.2-Exp"; return ;;
            0) return ;; *) echo "无效选择" ;; esac
    done
}

select_google() {
    while true; do
        echo -e "\n--- Google Models ---"
        echo "1. Gemini 3 Flash Preview"
        echo "2. Gemini 3 Pro Preview"
        echo "3. Gemini 2.5 Flash"
        echo "0. 返回上级"
        read -p "Select Model: " c; case $c in
            1) switch_to "gemini-3-flash-preview"; return ;;
            2) switch_to "gemini-3-pro-preview"; return ;;
            3) switch_to "gemini-2.5-flash"; return ;;
            0) return ;; *) echo "无效选择" ;; esac
    done
}

select_minimax() {
    while true; do
        echo -e "\n--- Minimax Models ---"
        echo "1. MiniMax-M2.1"
        echo "0. 返回上级"
        read -p "Select Model: " c; case $c in
            1) switch_to "MiniMaxAI/MiniMax-M2.1"; return ;;
            0) return ;; *) echo "无效选择" ;; esac
    done
}

select_moonshot() {
    while true; do
        echo -e "\n--- Moonshot Models ---"
        echo "1. Kimi-K2.5"
        echo "2. Kimi-K2-Thinking"
        echo "0. 返回上级"
        read -p "Select Model: " c; case $c in
            1) switch_to "moonshotai/Kimi-K2.5"; return ;;
            2) switch_to "moonshotai/Kimi-K2-Thinking"; return ;;
            0) return ;; *) echo "无效选择" ;; esac
    done
}

select_openai() {
    while true; do
        echo -e "\n--- OpenAI Models ---"
        echo "1. GPT-5.2"
        echo "2. GPT OSS 120B"
        echo "0. 返回上级"
        read -p "Select Model: " c; case $c in
            1) switch_to "gpt-5.2"; return ;;
            2) switch_to "openai/gpt-oss-120b"; return ;;
            0) return ;; *) echo "无效选择" ;; esac
    done
}

select_bytedance() {
    while true; do
        echo -e "\n--- Bytedance Models ---"
        echo "1. Doubao Seed Code Preview"
        echo "0. 返回上级"
        read -p "Select Model: " c; case $c in
            1) switch_to "doubao-seed-code-preview-251028"; return ;;
            0) return ;; *) echo "无效选择" ;; esac
    done
}

select_zai() {
    while true; do
        echo -e "\n--- Z.Ai (GLM) Models ---"
        echo "1. GLM-4.7"
        echo "2. GLM-4.6V"
        echo "0. 返回上级"
        read -p "Select Model: " c; case $c in
            1) switch_to "zai-org/GLM-4.7"; return ;;
            2) switch_to "zai-org/GLM-4.6V"; return ;;
            0) return ;; *) echo "无效选择" ;; esac
    done
}

select_qwen() {
    while true; do
        echo -e "\n--- Qwen Models ---"
        echo "1. Qwen3 Max"
        echo "2. Qwen3 Max Preview"
        echo "3. Qwen3 Coder Plus"
        echo "4. Qwen3 VL Plus"
        echo "5. Qwen3 VL Max"
        echo "6. Qwen3 Coder 480B"
        echo "0. 返回上级"
        read -p "Select Model: " c; case $c in
            1) switch_to "qwen3-max"; return ;;
            2) switch_to "qwen3-max-preview"; return ;;
            3) switch_to "qwen3-coder-plus"; return ;;
            4) switch_to "qwen3-vl-plus"; return ;;
            5) switch_to "qwen3-vl-max"; return ;;
            6) switch_to "Qwen/Qwen3-Coder-480B-A35B-Instruct"; return ;;
            0) return ;; *) echo "无效选择" ;; esac
    done
}

process_switch_model_menu() {
    while true; do
        echo -e "\n=== 切换默认模型 (按发行商) ==="
        echo " [1] Anthropic (Claude)"
        echo " [2] DeepSeek"
        echo " [3] Google (Gemini)"
        echo " [4] Minimax"
        echo " [5] Moonshot (Kimi)"
        echo " [6] OpenAI"
        echo " [7] 字节跳动 (Doubao)"
        echo " [8] Z.Ai (GLM)"
        echo " [9] Qwen (通义千问)"
        echo " [0] 返回主菜单"
        
        read -p "请输入发行商编号 [0-9]: " p_choice
        case $p_choice in
            1) select_anthropic ;;
            2) select_deepseek ;;
            3) select_google ;;
            4) select_minimax ;;
            5) select_moonshot ;;
            6) select_openai ;;
            7) select_bytedance ;;
            8) select_zai ;;
            9) select_qwen ;;
            0) return ;;
            *) echo "❌ 无效的选择" ;;
        esac
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
        read -p "按回车键继续..."
    fi
}

process_update_script() {
    echo -e "\n=== 更新脚本 ==="
    echo "正在从远程仓库获取最新版本..."
    
    local temp_file="/tmp/realm_manager_new.sh"
    
    if curl -sSL "$UPDATE_URL" -o "$temp_file"; then
        # 简单检查下载的文件是否完整 (比如包含特定关键词)
        if grep -q "OpenClaw RealmRouter Configuration Manager" "$temp_file"; then
            # 覆盖当前脚本
            mv "$temp_file" "$0"
            chmod +x "$0"
            echo "✅ 脚本已更新成功！请重新运行脚本以加载新功能。"
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
if [[ $- != *i* ]] && [[ -z "$TERM" ]]; then
    : # Non-interactive mode
fi

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
    echo " [5] 更新脚本  (获取最新版本)"
    echo " [q] 退出"
    
    echo ""
    read -p "请输入选项编号并回车: " choice
    
    case $choice in
        1) process_install ;;
        2) process_update_key ;;
        3) process_switch_model_menu ;;
        4) restore_backup; read -p "按回车键继续..." ;;
        5) process_update_script ;;
        q|Q) echo "Bye!"; exit 0 ;;
        *) echo "❌ 无效的输入"; sleep 1 ;;
    esac
done
