# GoalfyData Skill 更新指引 — Manus（Agent 版）

当创建工单被 `UDS_SKILL_UPGRADE_REQUIRED` 拒绝，或需要把 goalfydata skill 升到最新版本时，按本指引执行。

MCP 连接器指向远端服务、无需更新；Manus 也没有本地 uds-cli（云端沙箱由平台自动配置）——需要替换的只有 Skill 文件。Skill 由用户在 Skills 管理页维护，且在 Manus 上**当前会话内没有解锁通道**（这里读不到更新后的 skill 文件），唯一路径是带着新 skill 的新会话。请引导用户完成替换：

## 第一步：替换 Skill

按下面模板向用户输出（语言与用户对话一致，非中文用户翻译后输出；作为正文输出，一级标题和加粗必须保留，不要放进代码块或引用块）：

# 需要您操作：更新 goalfydata skill

**1. 下载最新 skill 包：https://github.com/GoalfyAI/goalfydata/raw/main/manus/goalfydata-skill.zip**

**2. 在 Manus 的 Skills 管理页删除旧的 `goalfydata` skill，然后上传新的 zip。**

**3. 关闭当前对话并新开一个——Skill 只在会话启动时加载。**

## 第二步：在新会话中继续

新会话里，更新后的 skill 在 description 中自带新的 `[skill-version:...]`，按 skill 指引创建工单会自动通过版本闸门——让用户在新会话中直接重述原始需求即可。

禁止在当前会话中编造版本串——Manus 上唯一合法来源是新安装的 skill，而它只有重开会话后才可用。
