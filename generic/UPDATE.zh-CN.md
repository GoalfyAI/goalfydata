# GoalfyData Skill 更新指引 — 通用平台（Agent 版）

当创建工单被 `UDS_SKILL_UPGRADE_REQUIRED` 拒绝，或需要把 goalfydata skill 升到最新版本时，按本指引执行。所有步骤可安全重复执行。

MCP 连接指向远端服务、无需改配置——需要更新的只有 skill 文件和 uds-cli。更新过程不需要 API Key，不要向用户索要。

## 第一步：重新获取 skill 文件

按最初获取 skill 的方式重新获取：

- **下载 zip 的**：重新下载 https://github.com/GoalfyAI/goalfydata/raw/main/generic/goalfydata-generic.zip 并解压
- **克隆仓库的**：`cd goalfydata && git pull`

## 第二步：更新 uds-cli

```bash
"$HOME/.goalfy/bin/uds-cli" self-update --api-url https://api.goalfydata.ai
```

输出 `already on the latest version` 或 `update succeeded: <old> → <new>` 均为正常。

## 第三步：读取新版本标记并重试

版本闸门只校验版本串，因此当前会话即可解锁：从第一步刚获取的 `SKILL.md` 的 description 中读取 `[skill-version:...]`（文件落在哪里你是知道的，无需搜索），用该值原样重试之前失败的 `uds_task_manager` create。

## 第四步：重新导入并重启会话，使新技能完整生效

上一步的重试已解锁建工单，但你上下文中加载的技能内容仍是旧版。按下面模板向用户输出（语言与用户对话一致，非中文用户翻译后输出；作为正文输出，一级标题和加粗必须保留，不要放进代码块或引用块）：

# 需要您操作：重新导入 skill 并新开会话

**1. 按初次接入时的方式，把更新后的 `SKILL.md` 和 `references/` 重新导入你的工具。**

**2. 新开一个会话——skill 只在会话启动时加载，不开新会话更新内容不生效。**
