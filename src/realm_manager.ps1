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

# === Warning: Change this URL to your real GitHub raw file address before release ===
$UPDATE_URL = "https://raw.githubusercontent.com/Yonghao-lucky/realm_manager/main/src/realm_manager.ps1"
$README_URL = "https://raw.githubusercontent.com/Yonghao-lucky/realm_manager/main/README.md"

# ================= Model Definitions =================
$SCRIPT_VERSION = "2.3"

# ================= Helper Functions =================

function New-JsonObject {
    return [PSCustomObject]@{}
}

function Get-JsonPropertyValue {
    param(
        [object]$Object,
        [string]$Name
    )

    if ($null -eq $Object) {
        return $null
    }

    if ($Object -is [System.Collections.IDictionary]) {
        return $Object[$Name]
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($null -ne $property) {
        return $property.Value
    }

    return $null
}

function Set-JsonPropertyValue {
    param(
        [object]$Object,
        [string]$Name,
        [object]$Value
    )

    if ($Object -is [System.Collections.IDictionary]) {
        $Object[$Name] = $Value
        return
    }

    $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force
}

function Ensure-JsonObjectProperty {
    param(
        [object]$Parent,
        [string]$Name
    )

    $currentValue = Get-JsonPropertyValue -Object $Parent -Name $Name
    if ($null -eq $currentValue) {
        $currentValue = New-JsonObject
        Set-JsonPropertyValue -Object $Parent -Name $Name -Value $currentValue
    }

    return $currentValue
}

function Save-ConfigFile {
    param(
        [string]$FilePath,
        [object]$JsonObject
    )

    $JsonObject | ConvertTo-Json -Depth 100 | Set-Content $FilePath -Encoding UTF8
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    switch ($Type) {
        "Success" { Write-Host "[OK] $Message" -ForegroundColor Green }
        "Error" { Write-Host "[X] $Message" -ForegroundColor Red }
        "Warning" { Write-Host "[!] $Message" -ForegroundColor Yellow }
        "Info" { Write-Host "[i] $Message" -ForegroundColor Cyan }
        "Progress" { Write-Host "[*] $Message" -ForegroundColor Magenta }
        default { Write-Host $Message }
    }
}

function Check-Environment {
    # Check Config File
    if (-not (Test-Path $CONFIG_FILE)) {
        Write-ColorOutput "Error: Config file not found: $CONFIG_FILE" "Error"
        Write-Host "Please make sure OpenClaw is installed and initialized."
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
        Write-ColorOutput "Backup created: $backupFile" "Success"
    } else {
        Write-ColorOutput "Backup failed, operation cancelled." "Error"
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
            # Anthropic
            @{ id = "claude-haiku-4.5"; name = "Claude Haiku 4.5" },
            @{ id = "claude-sonnet-4-5"; name = "Claude Sonnet 4.5" },
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
            @{ id = "gpt-5.4"; name = "GPT-5.4" },
            @{ id = "openai/gpt-oss-120b"; name = "GPT OSS 120B" },
            # ByteDance
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
        "Anthropic" {
            return @(
                @{ id = "claude-haiku-4.5"; name = "Claude Haiku 4.5" },
                @{ id = "claude-sonnet-4-5"; name = "Claude Sonnet 4.5" }
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
                @{ id = "gpt-5.4"; name = "GPT-5.4" },
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
        Write-ColorOutput "JSON parse failed, config file may be corrupted." "Error"
        return $false
    }
    
    # Add RealmRouter config
    $realmConfig = Get-RealmRouterConfig -ApiKey $ApiKey
    
    try {
        # Read original JSON
        $jsonObj = $jsonContent | ConvertFrom-Json
        
        # Ensure structure exists
        $modelsObj = Ensure-JsonObjectProperty -Parent $jsonObj -Name "models"
        $providersObj = Ensure-JsonObjectProperty -Parent $modelsObj -Name "providers"
        $agentsObj = Ensure-JsonObjectProperty -Parent $jsonObj -Name "agents"
        $defaultsObj = Ensure-JsonObjectProperty -Parent $agentsObj -Name "defaults"
        $modelObj = Ensure-JsonObjectProperty -Parent $defaultsObj -Name "model"
        
        # Add realmrouter config
        Set-JsonPropertyValue -Object $providersObj -Name "realmrouter" -Value $realmConfig
        
        Write-ColorOutput "RealmRouter config injected." "Info"
        
        # Set default model
        Set-JsonPropertyValue -Object $modelObj -Name "primary" -Value "realmrouter/qwen3-max"
        
        Write-ColorOutput "Default model switched to realmrouter/qwen3-max." "Info"
        
        # Save config
        Save-ConfigFile -FilePath $FilePath -JsonObject $jsonObj
        Write-ColorOutput "Config file updated." "Success"
        return $true
    } catch {
        Write-ColorOutput "Failed to save config file: $_" "Error"
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
            Write-ColorOutput "RealmRouter config not found, please run [Install/Reset] first." "Error"
            return $false
        }
        
        $jsonObj.models.providers.realmrouter.apiKey = $ApiKey
        Write-ColorOutput "API Key updated." "Info"
        
        Save-ConfigFile -FilePath $FilePath -JsonObject $jsonObj
        Write-ColorOutput "Config file updated." "Success"
        return $true
    } catch {
        Write-ColorOutput "Failed to update API Key: $_" "Error"
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
        
        $agentsObj = Ensure-JsonObjectProperty -Parent $jsonObj -Name "agents"
        $defaultsObj = Ensure-JsonObjectProperty -Parent $agentsObj -Name "defaults"
        $modelObj = Ensure-JsonObjectProperty -Parent $defaultsObj -Name "model"
        
        $fullModelId = "realmrouter/$ModelId"
        
        Set-JsonPropertyValue -Object $modelObj -Name "primary" -Value $fullModelId
        
        Write-ColorOutput "Default model switched to $fullModelId." "Info"
        
        Save-ConfigFile -FilePath $FilePath -JsonObject $jsonObj
        Write-ColorOutput "Config file updated." "Success"
        return $true
    } catch {
        Write-ColorOutput "Failed to switch model: $_" "Error"
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
    
    Write-Host "[*] Validating API Key... " -NoNewline
    
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
        
        Write-Host "[OK] Success." -ForegroundColor Green
        return $true
    } catch {
        $statusCode = "Unknown"
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        Write-Host "[!] Failed (HTTP $statusCode)." -ForegroundColor Yellow
        Write-Host "Possible reasons: Invalid Key, insufficient balance, wrong model name, or network issue."
        
        if ($Silent) {
            return $false
        }
        
        $force = Read-Host "Force continue? (y/N)"
        if ($force -eq "y" -or $force -eq "Y") {
            return $true
        }
        return $false
    }
}

function Restore-Backup {
    Write-Host ""
    Write-Host "=== Restore Backup ===" -ForegroundColor Cyan
    
    if (-not (Test-Path $BACKUP_DIR)) {
        Write-Host "   (No backup files)"
        return
    }
    
    $backups = Get-ChildItem $BACKUP_DIR -Filter "*.bak.*" | Sort-Object LastWriteTime -Descending | Select-Object -First 10
    
    if ($backups.Count -eq 0) {
        Write-Host "   (No backup files)"
        return
    }
    
    $i = 1
    foreach ($backup in $backups) {
        Write-Host "   [$i] $($backup.Name)"
        $i++
    }
    Write-Host "   [0] Back"
    
    $choice = Read-Host "Select"
    
    if ($choice -match "^\d+$" -and [int]$choice -gt 0 -and [int]$choice -le $backups.Count) {
        $selectedBackup = $backups[[int]$choice - 1]
        Copy-Item $selectedBackup.FullName $CONFIG_FILE -Force
        Write-ColorOutput "Backup restored: $($selectedBackup.Name)" "Success"
        Write-ColorOutput "Please run 'openclaw gateway restart' to apply changes." "Warning"
    }
}

function Update-Script {
    Write-Host ""
    Write-Host "=== Update Script ===" -ForegroundColor Cyan
    Write-Host "Fetching latest version from remote repository..."
    
    $tempFile = Join-Path $env:TEMP "realm_manager_new.ps1"
    
    try {
        Invoke-WebRequest -Uri $UPDATE_URL -OutFile $tempFile -UseBasicParsing
        
        # Check if downloaded file is valid
        $content = Get-Content $tempFile -Raw
        if ($content -match "OpenClaw RealmRouter Configuration Manager") {
            Copy-Item $tempFile $SCRIPT_PATH -Force
            Write-ColorOutput "Script core file updated." "Success"
            
            # Try to update README.md
            Write-Host "Fetching latest documentation..."
            try {
                $readmePath = Join-Path $SCRIPT_DIR "..\README.md"
                Invoke-WebRequest -Uri $README_URL -OutFile $readmePath -UseBasicParsing
                Write-ColorOutput "Documentation (README.md) updated." "Success"
            } catch {
                Write-ColorOutput "Documentation update failed, but script will work fine." "Warning"
            }
            
            Write-Host "Update complete! Please re-run the script to load new features."
            exit 0
        } else {
            Write-ColorOutput "Downloaded file appears corrupted or is not a valid script." "Error"
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-ColorOutput "Download failed, please check network connection or GitHub accessibility." "Error"
    }
}

# ================= Menu Functions =================

function Invoke-Install {
    Write-Host ""
    Write-Host "=== Install/Reset RealmRouter Config ===" -ForegroundColor Cyan
    
    $apiKey = Read-Host "Enter your API Key"
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-ColorOutput "API Key cannot be empty." "Error"
        return
    }
    
    if (Test-ApiKey -ApiKey $apiKey) {
        Backup-Config
        Install-RealmRouter -FilePath $CONFIG_FILE -ApiKey $apiKey
        Write-ColorOutput "Please run 'openclaw gateway restart' to apply changes." "Warning"
        Read-Host "Press Enter to continue..."
    }
}

function Invoke-UpdateKey {
    Write-Host ""
    Write-Host "=== Change RealmRouter API Key ===" -ForegroundColor Cyan
    
    $apiKey = Read-Host "Enter new API Key"
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-ColorOutput "API Key cannot be empty." "Error"
        return
    }
    
    if (Test-ApiKey -ApiKey $apiKey) {
        Backup-Config
        Update-ApiKey -FilePath $CONFIG_FILE -ApiKey $apiKey
        Write-ColorOutput "Please run 'openclaw gateway restart' to apply changes." "Warning"
        Read-Host "Press Enter to continue..."
    }
}

function Switch-ToModel {
    param([string]$ModelId)
    
    Write-Host "Switching to model: $ModelId ..."
    Backup-Config
    Switch-DefaultModel -FilePath $CONFIG_FILE -ModelId $ModelId
    Write-ColorOutput "Please run 'openclaw gateway restart' to apply changes." "Warning"
    Read-Host "Press Enter to return to main menu..."
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
        Write-Host "[0] Back"
        
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
        Write-Host "Invalid selection" -ForegroundColor Red
    }
}

function Show-SwitchModelMenu {
    $providers = @("DeepSeek", "Anthropic", "Google", "Minimax", "Moonshot", "OpenAI", "ByteDance", "Z.Ai", "Qwen")
    
    while ($true) {
        Write-Host ""
        Write-Host "=== Switch Default Model (by Provider) ===" -ForegroundColor Cyan
        
        $i = 1
        foreach ($provider in $providers) {
            Write-Host " [$i] $provider"
            $i++
        }
        Write-Host " [0] Back to main menu"
        
        $choice = Read-Host "Enter provider number [0-9]"
        
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
            Write-ColorOutput "Invalid selection" "Error"
        }
    }
}

function Invoke-TestConnectivity {
    Write-Host ""
    Write-Host "=== Test Key Connectivity ===" -ForegroundColor Cyan
    
    $currentKey = Get-CurrentApiKey -FilePath $CONFIG_FILE
    $currentModel = Get-CurrentModel -FilePath $CONFIG_FILE
    
    # Remove realmrouter/ prefix
    $realModelId = $currentModel -replace "^realmrouter/", ""
    
    if ([string]::IsNullOrWhiteSpace($realModelId)) {
        $realModelId = "qwen3-max"
    }
    
    if ([string]::IsNullOrWhiteSpace($currentKey)) {
        Write-ColorOutput "Error: No configured API Key found." "Error"
        Write-Host "Please run [1] Install/Reset or [2] Change Key first."
        Read-Host "Press Enter to return..."
        return
    }
    
    Write-Host "Testing current Key connectivity..."
    Write-Host "API Endpoint: $API_BASE_URL/chat/completions"
    Write-Host "Test Model: $realModelId"
    Write-Host "----------------------------------------"
    
    $result = Test-ApiKey -ApiKey $currentKey -ModelId $realModelId -Silent
    
    Write-Host "----------------------------------------"
    if ($result) {
        Write-ColorOutput "Test passed: Key is valid and connection is normal." "Success"
    } else {
        Write-ColorOutput "Test failed: Cannot connect or Key is invalid." "Error"
    }
    
    Read-Host "Press Enter to continue..."
}

# ================= Main Menu =================

# Pre-flight Check
Check-Environment

while ($true) {
    Clear-Host
    Write-Host "========================================"
    Write-Host "    RealmRouter Config Manager v$SCRIPT_VERSION (PowerShell)"
    Write-Host "========================================"
    Write-Host " [1] Install/Reset (Inject RealmRouter Config)"
    Write-Host " [2] Change Key  (Update API Key)"
    Write-Host " [3] Switch Model  (Change Default AI Model)"
    Write-Host " [4] Restore Backup  (Recover from History)"
    Write-Host " [5] Test Connectivity  (Test Key Validity)"
    Write-Host " [6] Update Script  (Get Latest Version)"
    Write-Host " [q] Exit"
    Write-Host ""
    
    $choice = Read-Host "Enter option number and press Enter"
    
    switch ($choice) {
        "1" { Invoke-Install }
        "2" { Invoke-UpdateKey }
        "3" { Show-SwitchModelMenu }
        "4" { Restore-Backup; Read-Host "Press Enter to continue..." }
        "5" { Invoke-TestConnectivity }
        "6" { Update-Script; Read-Host "Press Enter to continue..." }
        { $_ -eq "q" -or $_ -eq "Q" } { Write-Host "Bye!"; exit 0 }
        default { Write-ColorOutput "Invalid input" "Error"; Start-Sleep -Seconds 1 }
    }
}
