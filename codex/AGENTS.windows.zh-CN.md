# GoalfyData 安装与更新手册 — Codex on Windows（Agent 执行版）

执行本手册时，你必须遵守以下规则：

1. 只执行本手册列出的命令；只写入 `%USERPROFILE%\.codex\.env`（按行更新）和 Codex 插件目录
2. 向用户提及获取或核实 API Key 时，附上设置页链接 https://goalfydata.ai/settings
3. API Key 必须由用户提供，不编造、不用占位符
4. 所有命令在 PowerShell 中执行

每一步开头都有检查命令：已完成的步骤直接跳过，重复执行是安全的。

---

## 安装流程

### 第 1 步：确认 API Key

向用户逐字输出下面模板的内容（作为正文直接输出，不要放进代码块或引用块；一级标题和加粗必须保留，不得改写成普通句子），拿到 API Key 后再继续：

```markdown
# 需要你操作：提供 GoalfyData API Key

**你是否已有 GoalfyData API Key（形如 `gfk_xxx`）？已有请直接发给我。**

**如果还没有，请到 GoalfyData 创建：https://goalfydata.ai/settings （「设置 → API Key」，明文仅在创建时显示一次，请妥善保存）。没有账号可打开 https://goalfydata.ai 注册申请。**

创建后把 API Key 发给我，我来完成剩余步骤。
```

### 第 2 步：安装 uds-cli

检查：`Test-Path "$env:USERPROFILE\.goalfy\bin\uds-cli.exe"` 返回 True 则已安装。已安装时**不要直接跳过**，先更新到最新版，成功后进入第 3 步：

```powershell
& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" self-update --api-url https://api.goalfydata.ai
```

输出 `already on the latest version` 或 `update succeeded: <旧版本> → <新版本>` 均为正常。

未安装时执行安装：

```powershell
irm https://goalfyagent-public.s3.amazonaws.com/dataset-uds/install.ps1 | iex
```

成功标志：输出 `uds-cli <版本号> installed to <路径>\.goalfy\bin\uds-cli.exe`。

安装脚本会把 `.goalfy\bin` 写入用户级 PATH（注册表），并注入当前会话。校验持久化是否生效：

```powershell
[Environment]::GetEnvironmentVariable("Path", "User") -like "*\.goalfy\bin*"
```

返回 True 说明已持久化。返回 False 时**必须**补写，否则用户之后的新会话找不到 `uds-cli`：

```powershell
[Environment]::SetEnvironmentVariable("Path", "$env:USERPROFILE\.goalfy\bin;" + [Environment]::GetEnvironmentVariable("Path", "User"), "User")
```

补写后重新执行上面的校验，返回 True 才算完成本步；仍为 False 时如实报告，不得跳过。

当前会话如果 `uds-cli` 命令不可见，后续一律用绝对路径 `& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe"` 调用，不要重装。

### 第 3 步：登录

检查：`& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" whoami` 后 `$LASTEXITCODE` 为 0 则已登录，跳到第 4 步。

```powershell
& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" login --api-key <用户提供的Key> --api-url https://api.goalfydata.ai
```

成功标志：输出 `Login succeeded` 和 `API Key: gfk_xxx...`。

失败处理：报 `unknown flag: --api-key` 是旧版本，先执行 `& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" self-update` 再重试；报 `API Key validation failed` 说明 Key 无效，回到第 1 步。若输出 `WARNING: environment variable ...`，说明环境里残留旧 Key，第 5 步必须执行且完成后必须让用户重启。

### 第 4 步：安装插件

检查：`codex plugin list | Select-String goalfydata` 有输出则已安装，跳到第 5 步。

```powershell
codex plugin marketplace add GoalfyAI/goalfydata
codex plugin add goalfydata@goalfydata
```

失败处理：安装报错时执行 `codex plugin marketplace upgrade` 更新缓存后重试。

### 第 5 步：配置 API Key

检查：`Select-String GOALFY_UDS_API_KEY "$env:USERPROFILE\.codex\.env"` 有输出且值正确则跳到第 6 步。

Codex 桌面版是 Electron 应用，不读终端环境变量，必须写 `%USERPROFILE%\.codex\.env`。按行更新，不动文件里的其他内容：

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.codex" | Out-Null
$envFile = "$env:USERPROFILE\.codex\.env"
$lines = @()
if (Test-Path $envFile) { $lines = @(Get-Content $envFile | Where-Object { $_ -notmatch '^GOALFY_UDS_API_KEY=' }) }
$lines + 'GOALFY_UDS_API_KEY=<用户提供的Key>' | Set-Content $envFile
```

写入后重新执行检查命令确认能找到该行。

### 第 6 步：重启并验证

MCP 连接在重启后才生效，你在当前会话验证不了，必须由用户完成。向用户逐字输出下面模板的内容（作为正文直接输出，一级标题和加粗必须保留）：

```markdown
# 需要你操作：重启 Codex 并验证 MCP

1. **完全退出并重新打开 Codex**
2. **重启后确认 `goalfydata-mcp` 已连接，工具列表中有 20 个工具**（`uds_query`、`uds_dataset_manage` 等）

如果连接失败：确认 `%USERPROFILE%\.codex\.env` 里有 `GOALFY_UDS_API_KEY`，且该 Key 在 https://goalfydata.ai/settings 显示有效，然后再完全重启一次。
```

### 汇报

全部步骤执行完后按此模板汇报：

```
GoalfyData 安装结果：

【已完成】
- uds-cli 已安装并登录（版本 x.y.z，账号 xxx@example.com）
- 插件 goalfydata 已安装
- API Key 已写入 %USERPROFILE%\.codex\.env

【需要你操作】
- 完全重启 Codex 后确认 goalfydata-mcp 已连接（见上）

【未完成】
-（无 / 列出原因）

之后直接描述需求即可，例如"帮我把这个 Excel 建成数据集"。更多用法见 https://goalfydata.ai 。
```

---

## 更新流程

### 第 1 步：更新插件

```powershell
codex plugin marketplace upgrade goalfydata
codex plugin remove goalfydata@goalfydata
codex plugin add goalfydata@goalfydata
```

### 第 2 步：更新 uds-cli

```powershell
& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe" self-update
```

成功标志：输出 `already on the latest version` 或 `update succeeded: <旧版本> → <新版本>`。

### 第 3 步：重启生效

向用户逐字输出下面模板的内容（作为正文直接输出，一级标题和加粗必须保留）：

```markdown
# 需要你操作：重启生效

**请完全退出并重新打开 Codex，更新才会生效。**
```

---

## 更换 API Key

用户要求更换 API Key（或旧 Key 已删除/失效）时，不需要单独的流程：**重新执行本手册的安装流程**，从第 1 步开始走一遍即可——流程幂等，会自动引导用户创建新 Key、重新登录、更新 MCP 侧存储并提示重启。

用户手上没有本手册时，向用户逐字输出下面模板的内容（作为正文直接输出，一级标题和加粗必须保留）：

```markdown
# 需要你操作：重新获取接入文本

**请打开 GoalfyData 官网集成页：https://goalfydata.ai/integrations/codex**

**复制页面上的接入文本并重新发给我，我会自动完成包括更换 API Key 在内的全部步骤。**
```

换 Key 场景的两条例外（覆盖幂等跳过规则）：

- 第 3 步（登录）不得因 whoami 通过而跳过——旧 Key 可能尚未删除，必须用新 Key 重新执行 login
- login 输出 `WARNING: environment variable ...` 时，第 5 步必须执行，完成后必须让用户重启

---

## 排障

| 现象 | 处理 |
|---|---|
| `uds-cli` 不是内部或外部命令 | 用绝对路径 `& "$env:USERPROFILE\.goalfy\bin\uds-cli.exe"`；文件不存在才重装（安装第 2 步） |
| `unknown flag: --api-key` | 旧版本，先 `self-update` 再重试 |
| `irm` 下载失败 | 检查网络；安装脚本已强制 TLS 1.2，若仍失败向用户报告具体报错 |
| login 报 validation failed | 引导用户到 https://goalfydata.ai/settings 核实 Key，必要时重新创建 |
| login 成功但后续命令 401/未认证 | 环境变量残留旧 Key（优先级高于登录保存的配置）。按「更换 API Key」重新执行安装流程并让用户重启 |
| MCP 未连接 | 检查 `%USERPROFILE%\.codex\.env` 的 `GOALFY_UDS_API_KEY`，然后让用户完全重启 Codex（你不能替用户重启） |
| 工具返回未认证 | Key 缺失或失效，回到安装第 1 步 |
| 终端 export 了 Key 但桌面版连不上 | 桌面版不读终端环境变量，必须写 `%USERPROFILE%\.codex\.env`（安装第 5 步） |
| 新终端仍找不到 uds-cli | 用户级 PATH 未生效，重做安装第 2 步的持久化校验与补写 |
