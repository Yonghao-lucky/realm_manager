# realm_manager.ps1
# OpenClaw RealmRouter Configuration Manager for Windows PowerShell
# Description: 用于管理 OpenClaw 配置文件，支持 RealmRouter 增量注入、Key 验证及模型管理。

# ================= Configuration =================
$SCRIPT_PATH = $MyInvocation.MyCommand.Path
$SCRIPT_DIR = Split-Path -Parent $SCRIPT_PATH
$CONFIG_DIR = Join-Path $env:USERPROFILE ".openclaw"
$CONFIG_FILE = Join-Path $CONFIG_DIR "openclaw.json"
$BACKUP_DIR = Join-Path $CONFIG_DIR "backups"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"
$API_BASE_URL = "https://realmrouter.cn/v1"

# === ⚠️ 发布前请修改此 URL 为您的真实 GitHub 原始文件地址 ===
$UPDATE_URL = "https://raw.githubusercontent.com/Yonghao-lucky/realm_manager/main/src/realm_manager.ps1"
$README_URL = "https://raw.githubusercontent.com/Yonghao-lucky/realm_manager/main/README.md"

# ================= Model Definitions =================
$SCRIPT_VERSION = "2.3"

# ================= Helper Functions =================

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    switch ($Type) {
        "Success" { Write-Host "✅ $Message" -ForegroundColor Green }
        "Error" { Write-Host "❌ $Message" -ForegroundColor Red }
        "Warning" { Write-Host "⚠️ $Message" -ForegroundColor Yellow }
        "Info" { Write-Host "ℹ️ $Message" -ForegroundColor Cyan }
        "Progress" { Write-Host "⏳ $Message" -ForegroundColor Magenta }
        default { Write-Host $Message }
    }
}

function Check-Environment {
    # Check Config File
    if (-not (Test-Path $CONFIG_FILE)) {
        Write-ColorOutput "Error: 配置文件未找到: $CONFIG_FILE" "Error"
        Write-Host "请确保 OpenClaw 已安装并初始化。"
        exit 1
    }
}

function Backup-Config {
    if (-not (Test-Path $BACKUP_DIR)) {
        New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
    }
    
    $backupFile = Join-Path $BACKUP_DIR "openclaw.json.bak.$TIMESTAMP"
    Copy-Item $CONFIG_FILE $backupFile
    
    if (Test-Path $backupFile) {
        Write-ColorOutput "已创建备份: $backupFile" "Success"
    } else {
        Write-ColorOutput "备份失败，操作取消。" "Error"
        exit 1
    }
}

function Get-RealmRouterConfig {
    param([string]$ApiKey)
    
    $config = @{
        baseUrl = "https://realmrouter.cn/v1"
        apiKey = $ApiKey
        api = "openai-completions"
        models = @(
            # DeepSeek
            @{ id = "deepseek-ai/DeepSeek-R1"; name = "DeepSeek R1" },
            @{ id = "deepseek-ai/DeepSeek-R1-0528"; name = "DeepSeek R1 (0528)" },
            @{ id = "deepseek-ai/DeepSeek-V3.1"; name = "DeepSeek V3.1" },
            @{ id = "deepseek-ai/DeepSeek-V3.1-Terminus"; name = "DeepSeek V3.1 Terminus" },
            @{ id = "deepseek-ai/DeepSeek-V3.2-Exp"; name = "DeepSeek V3.2 Exp" },
            
            # Google
            @{ id = "gemini-3.1-pro-high"; name = "Gemini 3.1 Pro High" },
            @{ id = "gemini-3.1-pro-low"; name = "Gemini 3.1 Pro Low" },
            
            # Minimax
            @{ id = "MiniMaxAI/MiniMax-M2.1"; name = "MiniMax M2.1" },
            @{ id = "MiniMaxAI/MiniMax-M2.5"; name = "MiniMax M2.5" },
            
            # Moonshot
            @{ id = "moonshotai/Kimi-K2.5"; name = "Kimi K2.5" },
            @{ id = "moonshotai/Kimi-K2-Thinking"; name = "Kimi K2 Thinking" },
            
            # OpenAI
            @{ id = "gpt-5.2"; name = "GPT-5.2" },
            @{ id = "gpt-5.2-codex"; name = "GPT-5.2 Codex" },
            @{ id = "gpt-5.3-codex"; name = "GPT-5.3 Codex" },
            @{ id = "openai/gpt-oss-120b"; name = "GPT OSS 120B" },
            
            # 字节跳动 (ByteDance)
            @{ id = "doubao-seed-code-preview-251028"; name = "Doubao Seed Code Preview" },
            
            # Z.Ai
            @{ id = "zai-org/GLM-4.7"; name = "GLM 4.7" },
            @{ id = "zai-org/GLM-4.6V"; name = "GLM 4.6V" },
            @{ id = "zai-org/GLM-5"; name = "GLM 5" },
            
            # Qwen
            @{ id = "qwen3-coder-plus"; name = "Qwen3 Coder Plus" },
            @{ id = "qwen3-max"; name = "Qwen3 Max" },
            @{ id = "qwen3-max-preview"; name = "Qwen3 Max Preview" },
            @{ id = "qwen3-vl-plus"; name = "Qwen3 VL Plus" },
            @{ id = "qwen3-vl-max"; name = "Qwen3 VL Max" },
            @{ id = "Qwen/Qwen3-Coder-480B-A35B-Instruct"; name = "Qwen3 Coder 480B" },
            @{ id = "Qwen/Qwen3-Coder-Next"; name = "Qwen3 Coder Next" },
            @{ id = "Qwen/Qwen3.5"; name = "Qwen3.5" }
        )
    }
    
    return $config
}

function Get-ModelList {
    param([string]$Provider)
    
    switch ($Provider) {
        "DeepSeek" {
            return @(
                @{ id = "deepseek-ai/DeepSeek-R1"; name = "DeepSeek R1" },
                @{ id = "deepseek-ai/DeepSeek-R1-0528"; name = "DeepSeek R1 (0528)" },
                @{ id = "deepseek-ai/DeepSeek-V3.1"; name = "DeepSeek V3.1" },
                @{ id = "deepseek-ai/DeepSeek-V3.1-Terminus"; name = "DeepSeek V3.1 Terminus" },
                @{ id = "deepseek-ai/DeepSeek-V3.2-Exp"; name = "DeepSeek V3.2 Exp" }
            )
        }
        "Google" {
            return @(
                @{ id = "gemini-3.1-pro-high"; name = "Gemini 3.1 Pro High" },
                @{ id = "gemini-3.1-pro-low"; name = "Gemini 3.1 Pro Low" }
            )
        }
        "Minimax" {
            return @(
                @{ id = "MiniMaxAI/MiniMax-M2.1"; name = "MiniMax M2.1" },
                @{ id = "MiniMaxAI/MiniMax-M2.5"; name = "MiniMax M2.5" }
            )
        }
        "Moonshot" {
            return @(
                @{ id = "moonshotai/Kimi-K2.5"; name = "Kimi K2.5" },
                @{ id = "moonshotai/Kimi-K2-Thinking"; name = "Kimi K2 Thinking" }
            )
        }
        "OpenAI" {
            return @(
                @{ id = "gpt-5.2"; name = "GPT-5.2" },
                @{ id = "gpt-5.2-codex"; name = "GPT-5.2 Codex" },
                @{ id = "gpt-5.3-codex"; name = "GPT-5.3 Codex" },
                @{ id = "openai/gpt-oss-120b"; name = "GPT OSS 120B" }
            )
        }
        "ByteDance" {
            return @(
                @{ id = "doubao-seed-code-preview-251028"; name = "Doubao Seed Code Preview" }
            )
        }
        "Z.Ai" {
            return @(
                @{ id = "zai-org/GLM-4.7"; name = "GLM 4.7" },
                @{ id = "zai-org/GLM-4.6V"; name = "GLM 4.6V" },
                @{ id = "zai-org/GLM-5"; name = "GLM 5" }
            )
        }
        "Qwen" {
            return @(
                @{ id = "qwen3-coder-plus"; name = "Qwen3 Coder Plus" },
                @{ id = "qwen3-max"; name = "Qwen3 Max" },
                @{ id = "qwen3-max-preview"; name = "Qwen3 Max Preview" },
                @{ id = "qwen3-vl-plus"; name = "Qwen3 VL Plus" },
                @{ id = "qwen3-vl-max"; name = "Qwen3 VL Max" },
                @{ id = "Qwen/Qwen3-Coder-480B-A35B-Instruct"; name = "Qwen3 Coder 480B" },
                @{ id = "Qwen/Qwen3-Coder-Next"; name = "Qwen3 Coder Next" },
                @{ id = "Qwen/Qwen3.5"; name = "Qwen3.5" }
            )
        }
        default {
            return @()
        }
    }
}

function Install-RealmRouter {
    param(
        [string]$FilePath,
        [string]$ApiKey
    )
    
    try {
        $jsonContent = Get-Content $FilePath -Raw
        $json = $jsonContent | ConvertFrom-Json
    } catch {
        Write-ColorOutput "JSON 解析失败，配置文件可能已损坏。" "Error"
        return $false
    }
    
    # 添加 RealmRouter 配置
    $realmConfig = Get-RealmRouterConfig -ApiKey $ApiKey
    
    # 使用 JSON 字符串操作来确保正确添加
    try {
        # 读取原始 JSON
        $jsonObj = $jsonContent | ConvertFrom-Json
        
        # 确保结构存在
        if (-not $jsonObj.models) {
            $jsonObj | Add-Member -MemberType NoteProperty -Name "models" -Value @{} -Force
        }
        if (-not $jsonObj.models.providers) {
            $jsonObj.models | Add-Member -MemberType NoteProperty -Name "providers" -Value @{} -Force
        }
        if (-not $jsonObj.agents) {
            $jsonObj | Add-Member -MemberType NoteProperty -Name "agents" -Value @{} -Force
        }
        if (-not $jsonObj.agents.defaults) {
            $jsonObj.agents | Add-Member -MemberType NoteProperty -Name "defaults" -Value @{} -Force
        }
        if (-not $jsonObj.agents.defaults.model) {
            $jsonObj.agents.defaults | Add-Member -MemberType NoteProperty -Name "model" -Value @{} -Force
        }
        
        # 添加 realmrouter 配置
        $jsonObj.models.providers | Add-Member -MemberType NoteProperty -Name "realmrouter" -Value $realmConfig -Force
        
        Write-ColorOutput "RealmRouter 配置已注入。" "Info"
        
        # 设置默认模型
        $jsonObj.agents.defaults.model | Add-Member -MemberType NoteProperty -Name "primary" -Value "realmrouter/qwen3-max" -Force
        
        Write-ColorOutput "默认模型已切换为 realmrouter/qwen3-max。" "Info"
        
        # 保存配置
        $jsonObj | ConvertTo-Json -Depth 10 | Set-Content $FilePath -Encoding UTF8
        Write-ColorOutput "配置文件已更新。" "Success"
        return $true
    } catch {
        Write-ColorOutput "保存配置文件失败: $_" "Error"
        return $false
    }
}

function Update-ApiKey {
    param(
        [string]$FilePath,
        [string]$ApiKey
    )
    
    try {
        $jsonContent = Get-Content $FilePath -Raw
        $jsonObj = $jsonContent | ConvertFrom-Json
        
        if (-not $jsonObj.models.providers.realmrouter) {
            Write-ColorOutput "未找到 RealmRouter 配置，请先执行[安装/重置]。" "Error"
            return $false
        }
        
        $jsonObj.models.providers.realmrouter.apiKey = $ApiKey
        Write-ColorOutput "API Key 已更新。" "Info"
        
        $jsonObj | ConvertTo-Json -Depth 10 | Set-Content $FilePath -Encoding UTF8
        Write-ColorOutput "配置文件已更新。" "Success"
        return $true
    } catch {
        Write-ColorOutput "更新 API Key 失败: $_" "Error"
        return $false
    }
}

function Switch-DefaultModel {
    param(
        [string]$FilePath,
        [string]$ModelId
    )
    
    try {
        $jsonContent = Get-Content $FilePath -Raw
        $jsonObj = $jsonContent | ConvertFrom-Json
        
        if (-not $jsonObj.agents) {
            $jsonObj | Add-Member -MemberType NoteProperty -Name "agents" -Value @{} -Force
        }
        if (-not $jsonObj.agents.defaults) {
            $jsonObj.agents | Add-Member -MemberType NoteProperty -Name "defaults" -Value @{} -Force
        }
        if (-not $jsonObj.agents.defaults.model) {
            $jsonObj.agents.defaults | Add-Member -MemberType NoteProperty -Name "model" -Value @{} -Force
        }
        
        $fullModelId = "realmrouter/$ModelId"
        
        $jsonObj.agents.defaults.model | Add-Member -MemberType NoteProperty -Name "primary" -Value $fullModelId -Force
        
        Write-ColorOutput "默认模型已切换为 $fullModelId。" "Info"
        
        $jsonObj | ConvertTo-Json -Depth 10 | Set-Content $FilePath -Encoding UTF8
        Write-ColorOutput "配置文件已更新。" "Success"
        return $true
    } catch {
        Write-ColorOutput "切换模型失败: $_" "Error"
        return $false
    }
}

function Get-CurrentApiKey {
    param([string]$FilePath)
    
    try {
        $jsonContent = Get-Content $FilePath -Raw
        $jsonObj = $jsonContent | ConvertFrom-Json
        return $jsonObj.models.providers.realmrouter.apiKey
    } catch {
        return $null
    }
}

function Get-CurrentModel {
    param([string]$FilePath)
    
    try {
        $jsonContent = Get-Content $FilePath -Raw
        $jsonObj = $jsonContent | ConvertFrom-Json
        return $jsonObj.agents.defaults.model.primary
    } catch {
        return $null
    }
}

function Test-ApiKey {
    param(
        [string]$ApiKey,
        [string]$ModelId = "qwen3-max",
        [switch]$Silent
    )
    
    Write-Host "⏳ 正在验证 API Key 有效性... " -NoNewline
    
    $payload = @{
        model = $ModelId
        messages = @(
            @{ role = "user"; content = "hi" }
        )
        max_tokens = 1
    } | ConvertTo-Json -Depth 3
    
    try {
        $headers = @{
            "Authorization" = "Bearer $ApiKey"
            "Content-Type" = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri "$API_BASE_URL/chat/completions" -Method Post -Headers $headers -Body $payload -ErrorAction Stop
        
        Write-Host "✅ 成功。" -ForegroundColor Green
        return $true
    } catch {
        $statusCode = "未知"
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        Write-Host "⚠️ 失败 (HTTP $statusCode)。" -ForegroundColor Yellow
        Write-Host "可能原因: Key 无效、余额不足、模型名称错误或网络问题。"
        
        if ($Silent) {
            return $false
        }
        
        $force = Read-Host "是否强制继续？(y/N)"
        if ($force -eq "y" -or $force -eq "Y") {
            return $true
        }
        return $false
    }
}

function Restore-Backup {
    Write-Host ""
    Write-Host "=== 还原备份 ===" -ForegroundColor Cyan
    
    if (-not (Test-Path $BACKUP_DIR)) {
        Write-Host "   (无备份文件)"
        return
    }
    
    $backups = Get-ChildItem $BACKUP_DIR -Filter "*.bak.*" | Sort-Object LastWriteTime -Descending | Select-Object -First 10
    
    if ($backups.Count -eq 0) {
        Write-Host "   (无备份文件)"
        return
    }
    
    $i = 1
    foreach ($backup in $backups) {
        Write-Host "   [$i] $($backup.Name)"
        $i++
    }
    Write-Host "   [0] 返回上级"
    
    $choice = Read-Host "请选择"
    
    if ($choice -match "^\d+$" -and [int]$choice -gt 0 -and [int]$choice -le $backups.Count) {
        $selectedBackup = $backups[[int]$choice - 1]
        Copy-Item $selectedBackup.FullName $CONFIG_FILE -Force
        Write-ColorOutput "已还原备份: $($selectedBackup.Name)" "Success"
        Write-ColorOutput "请手动执行 'openclaw gateway restart' 以应用更改。" "Warning"
    }
}

function Update-Script {
    Write-Host ""
    Write-Host "=== 更新脚本 ===" -ForegroundColor Cyan
    Write-Host "正在从远程仓库获取最新版本..."
    
    $tempFile = Join-Path $env:TEMP "realm_manager_new.ps1"
    
    try {
        Invoke-WebRequest -Uri $UPDATE_URL -OutFile $tempFile -UseBasicParsing
        
        # 检查下载的文件是否完整
        $content = Get-Content $tempFile -Raw
        if ($content -match "OpenClaw RealmRouter Configuration Manager") {
            Copy-Item $tempFile $SCRIPT_PATH -Force
            Write-ColorOutput "脚本核心文件已更新。" "Success"
            
            # 尝试更新 README.md
            Write-Host "正在获取最新文档..."
            try {
                $readmePath = Join-Path $SCRIPT_DIR "..\README.md"
                Invoke-WebRequest -Uri $README_URL -OutFile $readmePath -UseBasicParsing
                Write-ColorOutput "文档(README.md)已更新。" "Success"
            } catch {
                Write-ColorOutput "文档更新失败，但这不影响脚本使用。" "Warning"
            }
            
            Write-Host "更新完成！请重新运行脚本以加载新功能。"
            exit 0
        } else {
            Write-ColorOutput "下载的文件似乎已损坏或不是有效的脚本。" "Error"
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-ColorOutput "下载失败，请检查网络连接或 GitHub 是否可访问。" "Error"
    }
}

# ================= Menu Functions =================

function Invoke-Install {
    Write-Host ""
    Write-Host "=== 安装/重置 RealmRouter 配置 ===" -ForegroundColor Cyan
    
    $apiKey = Read-Host "请输入您的 API Key"
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-ColorOutput "API Key 不能为空。" "Error"
        return
    }
    
    if (Test-ApiKey -ApiKey $apiKey) {
        Backup-Config
        Install-RealmRouter -FilePath $CONFIG_FILE -ApiKey $apiKey
        Write-ColorOutput "请手动执行 'openclaw gateway restart' 以应用更改。" "Warning"
        Read-Host "按回车键继续..."
    }
}

function Invoke-UpdateKey {
    Write-Host ""
    Write-Host "=== 更换 RealmRouter API Key ===" -ForegroundColor Cyan
    
    $apiKey = Read-Host "请输入新的 API Key"
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-ColorOutput "API Key 不能为空。" "Error"
        return
    }
    
    if (Test-ApiKey -ApiKey $apiKey) {
        Backup-Config
        Update-ApiKey -FilePath $CONFIG_FILE -ApiKey $apiKey
        Write-ColorOutput "请手动执行 'openclaw gateway restart' 以应用更改。" "Warning"
        Read-Host "按回车键继续..."
    }
}

function Switch-ToModel {
    param([string]$ModelId)
    
    Write-Host "正在切换到模型: $ModelId ..."
    Backup-Config
    Switch-DefaultModel -FilePath $CONFIG_FILE -ModelId $ModelId
    Write-ColorOutput "请手动执行 'openclaw gateway restart' 以应用更改。" "Warning"
    Read-Host "按回车键返回主菜单..."
}

function Show-ModelMenu {
    param(
        [string]$Provider,
        $ModelList
    )
    
    while ($true) {
        Write-Host ""
        Write-Host "--- $Provider Models ---" -ForegroundColor Cyan
        
        $i = 1
        foreach ($model in $ModelList) {
            Write-Host "[$i] $($model.name)"
            $i++
        }
        Write-Host "[0] 返回上级"
        
        $choice = Read-Host "Select Model"
        
        if ($choice -match "^\d+$") {
            $idx = [int]$choice
            if ($idx -eq 0) {
                return
            } elseif ($idx -gt 0 -and $idx -le $ModelList.Count) {
                Switch-ToModel -ModelId $ModelList[$idx - 1].id
                return
            }
        }
        Write-Host "无效选择" -ForegroundColor Red
    }
}

function Show-SwitchModelMenu {
    $providers = @("DeepSeek", "Google", "Minimax", "Moonshot", "OpenAI", "ByteDance", "Z.Ai", "Qwen")
    
    while ($true) {
        Write-Host ""
        Write-Host "=== 切换默认模型 (按发行商) ===" -ForegroundColor Cyan
        
        $i = 1
        foreach ($provider in $providers) {
            Write-Host " [$i] $provider"
            $i++
        }
        Write-Host " [0] 返回主菜单"
        
        $choice = Read-Host "请输入发行商编号 [0-8]"
        
        if ($choice -match "^\d+$") {
            $idx = [int]$choice
            if ($idx -eq 0) {
                return
            } elseif ($idx -ge 1 -and $idx -le $providers.Count) {
                $providerName = $providers[$idx - 1]
                $modelList = Get-ModelList -Provider $providerName
                Show-ModelMenu -Provider $providerName -ModelList $modelList
            }
        } else {
            Write-ColorOutput "无效的选择" "Error"
        }
    }
}

function Invoke-TestConnectivity {
    Write-Host ""
    Write-Host "=== 测试 Key 连通性 ===" -ForegroundColor Cyan
    
    $currentKey = Get-CurrentApiKey -FilePath $CONFIG_FILE
    $currentModel = Get-CurrentModel -FilePath $CONFIG_FILE
    
    # 去除 realmrouter/ 前缀
    $realModelId = $currentModel -replace "^realmrouter/", ""
    
    if ([string]::IsNullOrWhiteSpace($realModelId)) {
        $realModelId = "qwen3-max"
    }
    
    if ([string]::IsNullOrWhiteSpace($currentKey)) {
        Write-ColorOutput "Error: 未找到已配置的 API Key。" "Error"
        Write-Host "请先执行 [1] 安装/重置 或 [2] 更换 Key。"
        Read-Host "按回车键返回..."
        return
    }
    
    Write-Host "正在测试当前 Key 的连通性..."
    Write-Host "API Endpoint: $API_BASE_URL/chat/completions"
    Write-Host "测试模型: $realModelId"
    Write-Host "----------------------------------------"
    
    $result = Test-ApiKey -ApiKey $currentKey -ModelId $realModelId -Silent
    
    Write-Host "----------------------------------------"
    if ($result) {
        Write-ColorOutput "测试通过: Key 有效且连接正常。" "Success"
    } else {
        Write-ColorOutput "测试失败: 无法连接或 Key 无效。" "Error"
    }
    
    Read-Host "按回车键继续..."
}

# ================= Main Menu =================

# Pre-flight Check
Check-Environment

while ($true) {
    Clear-Host
    Write-Host "========================================"
    Write-Host "    RealmRouter 配置管理工具 v$SCRIPT_VERSION (PowerShell)"
    Write-Host "========================================"
    Write-Host " [1] 安装/重置 (注入 RealmRouter 配置)"
    Write-Host " [2] 更换 Key  (更新 API Key)"
    Write-Host " [3] 切换模型  (修改默认 AI 模型)"
    Write-Host " [4] 还原备份  (从历史备份恢复)"
    Write-Host " [5] 测试连通  (测试 Key 有效性)"
    Write-Host " [6] 更新脚本  (获取最新版本)"
    Write-Host " [q] 退出"
    Write-Host ""
    
    $choice = Read-Host "请输入选项编号并回车"
    
    switch ($choice) {
        "1" { Invoke-Install }
        "2" { Invoke-UpdateKey }
        "3" { Show-SwitchModelMenu }
        "4" { Restore-Backup; Read-Host "按回车键继续..." }
        "5" { Invoke-TestConnectivity }
        "6" { Update-Script; Read-Host "按回车键继续..." }
        { $_ -eq "q" -or $_ -eq "Q" } { Write-Host "Bye!"; exit 0 }
        default { Write-ColorOutput "无效的输入" "Error"; Start-Sleep -Seconds 1 }
    }
}
