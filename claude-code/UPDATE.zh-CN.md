# GoalfyData Skill 更新指引 — Claude Code（Agent 版）

当创建工单被 `UDS_SKILL_UPGRADE_REQUIRED` 拒绝，或需要把 goalfydata skill 升到最新版本时，按本指引执行。所有步骤可安全重复执行。

规则：不要执行本文列出之外的变更类命令。更新过程不需要 API Key，不要向用户索要。

## 第一步：更新插件

```bash
# marketplace 安装（默认方式）
claude plugin update goalfydata@goalfydata

# 本地 git clone 安装
cd goalfydata && git pull && claude plugin marketplace update goalfydata
```

## 第二步：更新 uds-cli

```bash
"$HOME/.goalfy/bin/uds-cli" self-update --api-url https://api.goalfydata.ai
```

输出 `already on the latest version` 或 `update succeeded: <old> → <new>` 均为正常。

## 第三步：读取新版本标记并重试

版本闸门只校验版本串，因此当前会话即可解锁。定位更新后的技能文件——直接搜索 `skills/goalfydata/SKILL.md`，不要凭记忆拼路径（安装路径中 goalfydata 会连续出现多层且夹版本号目录，形如 `.../plugins/cache/goalfydata/goalfydata/<版本>/skills/goalfydata/SKILL.md`）——在其 description 中找到 `[skill-version:...]`；命中多份时（旧版本目录、marketplace 副本），取版本目录号最高或最近修改的那份。用该值原样重试之前失败的 `uds_task_manager` create。

## 第四步：重启使新技能完整生效

上一步的重试已解锁建工单，但你上下文中加载的技能内容仍是旧版。按下面模板向用户输出（语言与用户对话一致，非中文用户翻译后输出；作为正文输出，一级标题和加粗必须保留，不要放进代码块或引用块）：

# 需要您操作：重启生效

**在会话中运行 `/reload-plugins`，或完全退出 Claude Code 后重新打开——更新后的技能内容在此之后才生效。**
