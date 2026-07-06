# GoalfyData 安装与更新手册 — Claude Code（Agent 执行版）

执行本手册时，你必须遵守以下规则：

1. 只执行本手册列出的命令；只写入 `~/.claude/settings.json`（合并写入）和 Claude Code 插件目录
2. 向用户提及获取或核实 API Key 时，附上设置页链接 https://goalfydata.ai/settings
3. API Key 必须由用户提供，不编造、不用占位符
4. 凡需要用户亲自操作或提供信息的内容，一律用「需要您操作」模板逐字输出：作为正文直接输出，不要放进代码块或引用块；一级标题和加粗必须保留，不得改写成普通句子

每一步开头都有检查命令：已完成的步骤直接跳过，重复执行是安全的。

---

## 安装流程

### 第 0 步：环境探测（决定走安装还是更新）

以下全部是检查命令，不与用户对话，按结果分流：

```bash
command -v uds-cli || ls "$HOME/.goalfy/bin/uds-cli"   # CLI 是否已安装
"$HOME/.goalfy/bin/uds-cli" whoami                      # 是否已登录（退出码 0 = 已登录）
grep GOALFY_UDS_API_KEY "$HOME/.claude/settings.json" # MCP 侧 Key 是否已配置
claude plugin list | grep goalfydata                   # 插件是否已安装
```

- 四项全部通过 → 用户已完整安装过，**直接转「更新流程」执行**，全程无需向用户索取任何信息
- 部分通过 → 只执行未通过项对应的步骤；whoami 通过时第 1、3 步都跳过（Key 已保存在本机，不要再向用户要）
- 全部未通过 → 从第 1 步开始完整安装

### 第 1 步：确认 API Key

向用户逐字输出下面的模板，拿到 API Key 后再继续：

```markdown
# 需要您操作：提供 GoalfyData API Key

**请问您是否已持有 GoalfyData API Key（形如 `gfk_xxx`）？如已持有，请直接发送给我。**

**如尚未持有，请前往 GoalfyData 创建：https://goalfydata.ai/settings （「设置 → API Key」，明文仅在创建时显示一次，请妥善保存）。如尚无账号，可访问 https://goalfydata.ai 注册。**

创建完成后，请将 API Key 发送给我，我将为您完成剩余步骤。
```

### 第 2 步：安装 uds-cli

检查：`command -v uds-cli || ls "$HOME/.goalfy/bin/uds-cli"`，任一有输出则已安装。已安装时**不要直接跳过**，先更新到最新版，成功后进入第 3 步：

```bash
"$HOME/.goalfy/bin/uds-cli" self-update --api-url https://api.goalfydata.ai
```

输出 `already on the latest version` 或 `update succeeded: <旧版本> → <新版本>` 均为正常。

未安装时执行安装：

```bash
curl -fsSL https://cdn.goalfydata.ai/dataset-uds/install.sh | sh
```

成功标志：输出 `uds-cli <版本号> installed to <家目录绝对路径>/.goalfy/bin/uds-cli`。

安装后如果 `uds-cli` 命令不可见，后续一律用绝对路径 `"$HOME/.goalfy/bin/uds-cli"` 调用，不要重装。

安装后检查 PATH 是否已持久化（安装脚本会自动写入 shell 配置文件，此处兜底校验，保证后续新会话可直接使用 `uds-cli`）：

```bash
grep -l "\.goalfy/bin" "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" 2>/dev/null
```

有输出说明已持久化。无输出时**必须**写入持久化配置，否则用户之后的新会话依然找不到 `uds-cli`。

写入哪个文件由你根据用户环境判断：先看默认 shell（`echo $SHELL`）和哪些配置文件已存在，把 `export PATH="$HOME/.goalfy/bin:$PATH"` 追加到对应文件（zsh 追加 `~/.zshrc`；bash 在 macOS 追加 `~/.bash_profile`、Linux 追加 `~/.bashrc`）。优先追加到已存在的文件，不要凭空创建多余的配置文件。

写入后重新执行上面的 grep 校验，确认有输出才算完成本步；校验仍无输出时如实报告，不得跳过。

### 第 3 步：登录

检查：`"$HOME/.goalfy/bin/uds-cli" whoami` 退出码为 0 则已登录，跳到第 4 步。

```bash
"$HOME/.goalfy/bin/uds-cli" login --api-key <用户提供的Key> --api-url https://api.goalfydata.ai
```

成功标志：输出 `Login succeeded` 和 `API Key: gfk_xxx...`。

失败处理：报 `unknown flag: --api-key` 是旧版本，先执行 `"$HOME/.goalfy/bin/uds-cli" self-update` 再重试；报 `API Key validation failed` 说明 Key 无效，回到第 1 步。

### 第 4 步：安装插件

检查：`claude plugin list | grep goalfydata` 有输出则已安装，跳到第 5 步。

```bash
claude plugin marketplace add GoalfyAI/goalfydata
claude plugin install goalfydata@goalfydata
```

失败处理：报 `source type not supported` 时执行 `claude plugin marketplace update goalfydata` 后重试。

### 第 5 步：配置 API Key

检查：`grep GOALFY_UDS_API_KEY "$HOME/.claude/settings.json"` 有输出且值正确则跳到第 6 步。

目标：在 `~/.claude/settings.json` 的 `env` 中加入（或更新）以下键，文件其余内容原样保留：

```json
{
  "env": {
    "GOALFY_UDS_API_KEY": "<用户提供的Key>"
  }
}
```

要求：
- 这个文件承载用户全部 Claude Code 配置，写坏会导致 Claude Code 无法使用。必须先读取现有内容再合并写入，禁止整体覆盖
- 文件不存在时按上面结构新建
- 写入后校验两项：文件仍是合法 JSON（`python3 -c "import json; json.load(open('<路径>'))"`），且 grep 能找到 `GOALFY_UDS_API_KEY`

### 第 6 步：重启并验证

MCP 连接在重启后才生效，你在当前会话验证不了，必须由用户完成。向用户逐字输出下面的模板：

```markdown
# 需要您操作：重启并验证 MCP

1. **请完全退出并重新打开 Claude Code**
2. **重启后请输入 `/mcp`，确认 `goalfydata-mcp` 状态为 connected + 20 tools**

若显示失败：请确认 `~/.claude/settings.json` 中已配置 `GOALFY_UDS_API_KEY`，且该 Key 在 https://goalfydata.ai/settings 显示为有效，随后再次完全重启。
```

### 汇报

全部步骤执行完后按此模板汇报：

```
GoalfyData 安装结果：

【已完成】
- uds-cli 已安装并登录（版本 x.y.z，账号 xxx@example.com）
- 插件 goalfydata 已安装
- API Key 已写入 ~/.claude/settings.json

【需要您操作】
- 重启 Claude Code 后输入 /mcp 验证连接（见上）

【未完成】
-（无 / 列出原因）

后续您可直接描述需求，例如"帮我把这个 Excel 文件构建为数据集"。更多用法请见 https://goalfydata.ai 。
```

---

## 更新流程

### 第 1 步：更新插件

```bash
# marketplace 安装的（默认）
claude plugin update goalfydata@goalfydata

# 本地 git clone 安装的
cd goalfydata && git pull && claude plugin marketplace update goalfydata
```

### 第 2 步：更新 uds-cli

```bash
"$HOME/.goalfy/bin/uds-cli" self-update
```

成功标志：输出 `already on the latest version` 或 `update succeeded: <旧版本> → <新版本>`。

### 第 3 步：重启生效

向用户逐字输出下面的模板：

```markdown
# 需要您操作：重启生效

**请在会话中执行 `/reload-plugins`，或完全退出并重新打开 Claude Code，更新才会生效。**
```

---

## 更换 API Key

用户要求更换 API Key（或旧 Key 已删除/失效）时执行本节。先理解 Key 的生效模型，否则容易换了个寂寞：

- Key 存在两处：`~/.goalfy/config.json`（login 写入，uds-cli 读取）和 `~/.claude/settings.json` 的 `env`（供 MCP 请求头使用，同时会注入 Agent 的会话环境变量）
- 优先级：环境变量高于 config——`~/.claude/settings.json` 的 `env` 不更新，login 写入的新 Key 会被旧环境值覆盖
- 生效时点：config 立即生效；`~/.claude/settings.json` 的 `env` 与会话环境仅在**完全重启后**生效

按顺序执行（更换场景不做第 0 步分流）：

1. 引导用户到官网创建新 Key：执行安装流程第 1 步（输出要 Key 模板）
2. 用新 Key 重新登录：执行安装流程第 3 步，**不得因 whoami 通过而跳过**（旧 Key 可能尚未删除）
3. 更新 MCP 侧存储：执行安装流程第 5 步，**无条件必做、不得因检查通过而跳过**——`~/.claude/settings.json` 里存的还是旧 Key，不更新则重启后 MCP 和新会话仍用旧 Key（login 是否输出 `WARNING: environment variable ...` 只反映当前会话环境，不能作为跳过依据）
4. 换 Key 一致性校验：确认 `~/.goalfy/config.json` 与 `~/.claude/settings.json` 中的 Key 均为新值（对比 gfk_ 后的前几位）
5. 向用户逐字输出下面的模板：

```markdown
# 需要您操作：重启使新 API Key 生效

**请完全退出并重新打开 Claude Code。** 当前会话的环境变量与 MCP 连接仍在使用旧 Key，仅在完全重启后才会切换为新 Key。

**重启后如旧 Key 尚未删除，建议前往 https://goalfydata.ai/settings 删除，避免混用。**
```

验收标准（在用户重启后的新会话中）：`uds-cli whoami` 显示的 Key 前缀为新值，MCP 工具调用不再返回未认证。

用户手上没有本手册时，向用户逐字输出下面的模板：用户手上没有本手册时，向用户逐字输出下面的模板：

```markdown
# 需要您操作：重新获取接入文本

**请打开 GoalfyData 官网集成页：https://goalfydata.ai/integrations/claude-code**

**请复制页面上的接入文本并重新发送给我，我将自动完成包括更换 API Key 在内的全部步骤。**
```

---

## 排障

| 现象 | 处理 |
|---|---|
| `command not found: uds-cli` | 用绝对路径 `"$HOME/.goalfy/bin/uds-cli"`；文件不存在才重装（安装第 2 步） |
| `unknown flag: --api-key` | 旧版本，先 `self-update` 再重试 |
| login 报 validation failed | 引导用户到 https://goalfydata.ai/settings 核实 Key，必要时重新创建 |
| `/mcp` 显示未连接 | 检查 settings.json 的 `GOALFY_UDS_API_KEY`，然后让用户完全重启（你不能替用户重启） |
| 工具返回未认证 | Key 缺失或失效，回到安装第 1 步 |
| 插件更新后不生效 | 让用户执行 `/reload-plugins` 或完全重启 |
| login 成功但后续命令 401/未认证 | 环境变量残留旧 Key（优先级高于登录保存的配置）。按「更换 API Key」重新执行安装流程并让用户重启 |
