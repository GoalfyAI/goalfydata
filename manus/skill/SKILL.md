---
name: goalfydata
description: 当用户需要对数据做深度分析（多轮 SQL 查询、聚合统计、趋势对比等），或需要将数据（Excel / CSV / API / 数据库）沉淀为可长期复用、跨平台访问的结构化资产时使用——典型场景包括：复杂或反复的数据分析、跨多个 Agent / 跨服务 / 跨电脑访问同一份数据、把数据分享给他人协作、基于数据构建 Dashboard 并部署和分享到公网。GoalfyData 独立于单个项目和对话，覆盖从建表、导入、查询分析、治理规则、权限分享、凭证管理、定时自动更新到 Dashboard 部署的完整数据集生命周期。
keywords:
  - 数据集
  - dataset
  - 建表
  - 导入
  - 分享
  - 定时同步
  - GoalfyData
  - uds
  - 数据应用
  - 应用部署
  - app
  - dashboard
  - 仪表盘
  - 看板
  - 报表
  - report
  - 分析
  - analyze
  - Excel
  - CSV
  - 可视化
  - visualization
---

# GoalfyData

把用户的业务数据沉淀为**独立于项目和对话、可跨 Agent / 跨服务 / 跨电脑复用与分享**的结构化数据集资产，并支持将数据集开发成公网可访问的数据应用。

> 本文档是主指南，包含完整的执行流程。以下子指南提供补充参考：
> - `references/dataset-building-guide.md` — 业务访谈要点矩阵、表命名规范、PG 语法陷阱、建表前校验清单
> - `references/data-quality-guide.md` — 脏数据分类与判定、数据质量检测方法
> - `references/scheduled-sync-guide.md` — 外部数据源脚本模板（MySQL 分块、API 分页）、多表协同、故障排查
> - `references/app-deploy-guide.md` — 数据应用模板结构、开发规范、版本管理细节

## 前置条件

**必需 MCP Server**: `goalfydata-mcp`

GoalfyData MCP Server 提供 20 个工具（15 个数据集管理面工具 + 5 个应用开发部署工具），所有操作通过 GoalfyData 后端 API 完成。

**MCP 配置**（streamable-http 传输，Bearer Token 认证）：

```json
{
  "goalfydata-mcp": {
    "type": "streamable-http",
    "url": "https://mcp.goalfydata.ai/mcp",
    "headers": {
      "Authorization": "Bearer ${GOALFY_UDS_API_TOKEN}"
    }
  }
}
```

- `${GOALFY_UDS_API_TOKEN}` 为 GoalfyData 个人访问令牌（gfk_xxx）；缺 token 时所有工具返回未认证

**必需 CLI**: `uds-cli`（首次使用前必须安装，安装一次全局生效）

数据面操作（执行 SQL、导入数据、查看表结构）通过 uds-cli 完成。**每次执行任务前先检查 uds-cli 是否已安装**（`which uds-cli`），未安装则必须先完成安装和登录，不可跳过。定时同步任务在云端沙箱自动执行，uds-cli 和凭证由平台自动配置，脚本无需处理认证。

  macOS / Linux:
  ```bash
  curl -fsSL https://goalfyagent-public.s3.amazonaws.com/dataset-uds/install.sh | sh
  source ~/.zshrc  # 或 source ~/.bashrc，让 PATH 生效
  uds-cli login --token gfk_xxx --api-url https://api.goalfydata.ai
  ```

  安装脚本会自动将 uds-cli 加入 PATH（写入 `~/.zshrc` 或 `~/.bashrc`），安装一次后所有终端会话均可使用，无需重复安装。

  更新：`uds-cli self-update`

**认证**: 用户需持有 GoalfyData 个人访问令牌（gfk_xxx），通过 Bearer Token 认证。MCP 工具（请求头 `Authorization: Bearer gfk_xxx`）和 uds-cli（`uds-cli login --token gfk_xxx --api-url <Hub地址>`）共用同一套 token 体系。`--api-url` 是必填参数，没有默认值，login 成功后保存到 `~/.goalfy/config.json`，后续命令自动使用。

**获取令牌**: 到 GoalfyData 控制台「设置 → API Key」创建：https://goalfydata.ai/settings 。明文仅在创建时返回一次，请妥善保存。

**未持有 token，或工具返回未认证时**，引导用户：「请到 https://goalfydata.ai/settings 登录并创建 API Key（gfk_xxx），再配置到 MCP 或发给我，即可继续。」不要自行编造或使用占位 token。

**权限模型**: 自己创建的数据集拥有全部权限；别人分享的数据集为只读，不能建表或改结构。

---

## 1. 身份与边界

### 1.1 角色

行为准则：
- 匹配用户的沟通风格：用户用技术语言交流时直接用技术语言回应；用户是非技术角色时，优先用业务语言表达，避免暴露表名、SQL、资产 ID 等技术细节
- 用户已给出完整规格（字段、数据源、更新方式）时直接执行，无需进入访谈流程
- 遇到数据质量问题停下让用户决策，不自作主张丢弃数据
- 业务规则、表关系写到结构化存储（uds_rule_manage / uds_relations_set），不能只留在对话里

### 1.2 何时使用 GoalfyData

GoalfyData 独立于单个项目和对话，是可长期复用、跨平台访问的结构化数据资产。出现以下信号时，优先把数据沉淀成数据集，而不是一次性处理：

- **复杂或反复的数据分析**：数据量大、需要多轮 SQL 查询/聚合，零散的文件或内存处理难以承载
- **跨 Agent 复用**：同一份数据要被多个 Agent、多个对话反复使用
- **跨服务 / 跨平台访问**：数据要被不同服务、不同 Agent 平台共享访问
- **跨电脑 / 跨设备**：在本机、沙箱、他人设备上都要访问同一份数据
- **分享与协作**：数据要分享给特定的人，或做成公网应用让多人访问
- **持续更新**：数据需要定时自动同步保持最新

反之，一次性的、用完即弃的小数据处理，无需创建数据集。

### 1.3 能做的事

- 创建通用数据集（独立于项目，跨 Agent 平台可用）
- 建表、导入数据（CSV/Excel/API/脚本）
- 基于数据集做数据分析（多轮 SQL 查询、聚合统计、趋势对比、取数导出）
- 设置表间关系和治理规则（业务口径沉淀）
- 分享数据集（一人一码精确分享 / 应用多人链接分享）
- 配置细粒度权限策略（表/列/行级别控制）
- 配置定时自动更新（cron 计划 + 更新脚本）
- 管理数据源凭证（加密存储 API Key/数据库密码）
- 把数据集开发成公网可访问的数据应用（仪表盘/查询工具等），并部署、分享、版本管理

### 1.4 意图判断

| 用户状态 | 处理 |
|---|---|
| 明确说要建数据集 | 直接进入构建流程 |
| 已给出完整规格（字段、数据源、更新方式） | 跳过访谈，直接执行 |
| 上传文件但没说目的 | 先问是否要把它沉淀成数据集 |
| 说"帮我分析数据" + 上传了文件 | 先确认数据规模，多文件或数据量较大时建议先建数据集再分析，用户明确拒绝后再走本地路线 |
| 说"帮我分析数据" + 无文件 | 检查是否已有数据集（uds_dataset_get），有则直接用 uds_query 分析 |
| 说"帮我查一下数据集" | 调 uds_dataset_get 列出可用数据集 |
| 说"分享给某人" | 进入分享流程 |
| 说"把数据做成看板/网站/应用" | 数据已在 GoalfyData 数据集中时，必须走 GoalfyData 应用部署流程（4.5），禁止用平台内置的 Dashboard/可视化技能 |

---

## 2. 核心约束（违反即任务失败）

### 约束 1 — 数据集的构建与维护走 uds-cli

- 建表/改结构：`uds-cli exec --mode writer "CREATE TABLE ..."`
- 导入数据：`uds-cli import`（禁止手拼大量 INSERT）
- 反读表结构：`uds-cli inspect --table ...`
- SQL 表名一律全限定：`uds_{dataset_id}.表名`
- 禁止绕过 uds-cli 自行拼数据库连接

### 约束 2 — 如实汇报

- 汇报按「已完成 / 部分完成 / 未完成」分类，有未完成项必须显式列出
- 定时任务汇报前须用 `uds_dataset_get` 核实 `cron_enabled` 真实值（配置 schedule 不代表已启用）
- 定时同步配置后必须 `uds_sync_task(action="run", task_id=<task_id>)` 实跑验证一次，`status=success` 才算就绪
- 中断后续作：先 `uds_dataset_get` 查真实状态再继续，不得重复建表或覆盖已有数据

### 约束 3 — 重要操作需用户确认

建表方案、数据清洗策略、删除操作、开启定时任务之前必须停下让用户决策。禁止擅自决定表结构或丢弃数据。大数据量（行数/文件数明显超常）必须把实测量和候选方式给用户选，不得因"数据量大"自行跳过任何数据。

### 约束 4 — 建表必须配套注册元数据

每建一张表，必须紧接着调 `uds_table_manage(action="create", task_id=<task_id>)` 注册元数据，否则 Hub 前端和其他 Agent 看不到该表。

- `target_columns` 必须从 `uds-cli inspect` 反读真实表结构，禁止凭空编造
- 数据集必须有 `tool_usage_guide`（业务背景、核心表说明、常用查询），空字符串不算完成

### 约束 5 — 凭证安全

API Key、数据库密码等敏感信息禁止写进脚本明文，必须通过 `uds_credential_store` 加密存储。脚本通过 `os.environ['凭证名']` 读取。

### 约束 6 — 任务工单（task_id）

每次会话/任务开始时，必须先调 `uds_task_manager(action="create", task_name="任务名称")` 创建任务工单，拿到 `task_id`。后续本次会话中所有操作都必须带上该 `task_id`，缺失会被服务端拦截。

- **MCP 工具**：每次调用必填 `task_id`（`uds_task_manager` 自身豁免）
- **uds-cli 命令**：每条数据面命令加 `--task-id <task_id>`（与 MCP 用同一个），把执行 SQL / 导入等操作一并归入当前任务
- `op_summary`：必填，用业务语言描述本次操作的原因和下一步计划（100-200 字符），禁止提及工具名/函数名/技术参数
- `agent_name`：选填，标识当前 Agent 身份（如 claude / codex / cursor）

同一会话中复用同一个 `task_id`，不要每次调用都创建新工单。需要沉淀阶段性结论时用 `uds_task_manager(action="insert")` 往工单追加记录；用 `uds_task_manager(action="get")` 回看工单及其操作记录。

### 约束 7 — 定时更新走 GoalfyData

数据集的定时更新必须走 GoalfyData 定时同步机制（`uds_table_manage` 配置 schedule + 更新脚本，由平台沙箱定时执行），禁止用系统 crontab / 平台内置定时任务替代。

---

## 3. 工具总览

### 3.1 MCP 工具（管理面）

| 工具 | 用途 |
|------|------|
| `uds_dataset_manage` | 创建/更新/删除数据集 |
| `uds_dataset_get` | 查询数据集详情或列表 |
| `uds_query` | 执行只读 SQL 查询 |
| `uds_table_manage` | 注册/管理表元数据、配置定时计划、开关定时任务 |
| `uds_relations_set` | 管理表间关系 |
| `uds_rule_manage` | 管理治理规则（业务口径沉淀） |
| `uds_policy_manage` | 管理细粒度权限策略（表/列/行级别） |
| `uds_share` | 分享数据集或应用 |
| `uds_sync_task` | 触发/查询/取消同步任务 |
| `uds_sync_logs` | 查看同步执行日志 |
| `uds_credential_store` | 加密存储数据源凭证 |
| `uds_schema_init` | 初始化 PG schema（仅 pg_schema_ready=false 时） |
| `uds_notify_config` | 配置同步失败/成功通知渠道 |
| `uds_init_project` | 起应用项目（template 新建 / fork 二次开发） |
| `uds_app_deploy` | 部署应用（两步：拿上传地址 → 部署） |
| `uds_app_status` | 查应用状态/URL/版本 |
| `uds_app_manage` | 应用生命周期（online/offline/rollback/delete） |
| `uds_app_list` | 列出已部署应用 |
| `uds_task_manager` | 任务工单管理（create 创建工单拿 task_id / insert 追加信息记录 / list 列工单 / get 工单详情及操作日志） |
| `uds_billing_info` | 查询订阅套餐、月度用量、各维度配额（数据更新次数、存储空间、已部署应用数）及可用加量包 |

### 3.2 CLI 工具（数据面）

| 命令 | 用途 |
|------|------|
| `uds-cli --task-id <task_id> exec "SQL" --mode reader/writer` | 执行 SQL（查询用 reader，DDL/DML 用 writer） |
| `uds-cli --task-id <task_id> import file.csv --table name --mode append/full_replace/upsert` | 导入数据 |
| `uds-cli --task-id <task_id> upload <file> --dataset <dataset_id>` | 上传文件/脚本到数据集存储 |
| `uds-cli --task-id <task_id> inspect --table name` | 查看表结构 |
| `uds-cli --task-id <task_id> export --table name` | 导出数据 |
| `uds-cli --task-id <task_id> connect --mode reader/writer --schema X` | 获取数据集连接串（临时凭证）。--schema 必填，不指定会报错。多个数据集用逗号分隔或重复 --schema：`--schema uds_a,uds_b` 或 `--schema uds_a --schema uds_b`。凭证按所选收窄：writer 下自有数据集可读写、被分享的只读、未选或无权的访问不到 |
| `uds-cli --task-id <task_id> schemas` | 列出可访问的数据集 id |
| `uds-cli task-create --name "任务名"` | 创建任务工单，返回 task_id（CLI 版的 uds_task_manager create） |
| `uds-cli task-insert <task_id> --content "记录内容"` | 往工单追加信息记录（note/result/checkpoint） |
| `uds-cli task-select [task_id]` | 不带参数列出工单列表；带 task_id 查看工单详情，加 `--tool-calls` 附操作日志 |

`--task-id` 是全局参数，所有数据面命令都必须带上（约束 6）。具体参数以 `uds-cli <命令> --help` 为准。

### 3.3 核心调用链

```
uds_task_manager(create, task_name) → 拿 task_id（后续所有调用必带）
  │
  ▼
uds_dataset_manage(create, task_id) → 拿 dataset_id
  │
  ▼ 对每张表：
  uds-cli --task-id <task_id> exec --mode writer "CREATE TABLE ..."    建表
  uds_table_manage(create, table_name, task_id)                         注册元数据
  uds-cli --task-id <task_id> import --table ... --mode ...            导入数据
  uds-cli --task-id <task_id> inspect --table ...                      反读 target_columns
  uds_table_manage(update, target_columns, sources, task_id)  完善配置
  │
  ▼ 全部表完成后：
  uds_relations_set(replace, task_id)                表间关系
  uds_dataset_manage(update, tool_usage_guide, task_id) 使用指南
  uds_table_manage(update, cron_enabled=true, task_id) 开启定时（需用户确认）

可选 · 开发数据应用：
  uds_init_project(template, task_id) → 下载模板 → 本地开发 → 打包
  uds_app_deploy(filename, task_id) → 上传 → uds_app_deploy(package_key, task_id) → 拿 app_url
  uds_app_status(deploy_id, task_id) 确认在线
```

---

## 4. 执行流程

### 4.1 新建数据集（从文件/数据源构建）

```
Phase 1 — 需求理解
  Step 1.0  创建任务工单（拿 task_id，后续所有操作必带）
  Step 1.1  意图确认 + 数据源识别 + 创建数据集
  Step 1.2  业务访谈（4 维度，治理规则实时落库）

Phase 2 — 构建与验证
  Step 2.1  逐表构建（核心循环：探查→建表→注册→导入→校验→反读→完善）
  Step 2.2  整体校验（跨表质量检查 + 业务查询验证）
  Step 2.3  产出物沉淀（关系 + 规则 + 使用指南 + 自查）

Phase 3 — 同步验证与交付
  Step 3.1  逐表触发 sync task（验证生产链路）
  Step 3.2  失败处理与重试
  Step 3.3  最终汇报（含 cron_enabled 状态核实）
```

#### Phase 1 — 需求理解

**Step 1.0 — 创建任务工单**

`uds_task_manager(action="create", task_name="任务名称")` → 拿到 `task_id`，后续本次会话所有 MCP 调用和 uds-cli 命令都必须带上（约束 6）。

**Step 1.1 — 意图确认 + 初始化**

1. 确认用户要创建数据集（约束 3）。用户已给出完整规格时直接执行，无需进入访谈流程
2. 识别数据源：文件上传 / API / 已有数据
3. 初步了解数据：扫描文件元数据或 API 样本，记录数据结构概况（列数、行数、候选主键、时间列、数值列、数据源类型）
4. 创建数据集：`uds_dataset_manage(action="create", name="...", task_id=<task_id>)` → 拿到 `dataset_id` 和 `pg_schema`，后续访谈中识别的治理规则可实时落库

**Step 1.2 — 业务访谈**

按 4 维度组织访谈：**业务背景 → 业务口径 → 业务规则 → 跨表关系**。

**执行前必须先读** `references/dataset-building-guide.md` 的访谈要点矩阵（第 1 节）和正反例（第 1.3 节），确保问题有数据依据、措辞详尽。

节奏控制：
- 一次问一组（不超过 5 个相关问题），每组答复后复述确认
- 全部维度覆盖完才进入 Phase 2 建表

硬规则：
- **问题必须有数据依据**：附带从扫描中发现的具体信息，不凭空提问（"扫描发现 status 列有 3 个唯一值：completed/cancelled/processing，这是完整枚举吗？"）
- **先分析再问**：先自主推断带结论让用户确认（"根据数值范围和站点，推断金额单位是 MYR，请确认？"）
- **确认措辞详尽**：把关键上下文写全（来源、时间范围、单位、口径），不只说"确认以上"
- **识别治理规则**：访谈过程中捕获的业务口径/约束/清洗约定，**实时**调 `uds_rule_manage(action="create", task_id=<task_id>)` 落库，并一句话告知用户

#### Phase 2 — 构建与验证

**Step 2.1 — 逐表构建（核心循环）**

对每个文件/数据源重复。**入口必须先读** `references/data-quality-guide.md` 执行数据质量检测（脏数据分类、机器信号 + 语义判断方法、建表前校验清单）：

- 干净或可自动修复（类别 A）→ 进入标准闭环
- 无法自动修复（类别 B）→ 停止本表后续步骤，向用户说明数据质量问题并协商处理方案

**标准闭环**：

| 步骤 | 动作 | 关键约束 |
|------|------|----------|
| 1. 数据探查 | 分析行数、类型分布、空值、样本值 | 采样模式，不全量加载 |
| 2. 建表方案确认 | 向用户展示字段业务含义，确认表结构 | 约束 3 |
| 3. 建表 | `uds-cli --task-id <task_id> exec --mode writer "CREATE TABLE uds_{dataset_id}.表名 (...)"` | 字段 snake_case；建表前先读 `references/dataset-building-guide.md` 第 2-3 节（命名规范 + PG 语法陷阱） |
| 4. 注册元数据 | `uds_table_manage(action="create", dataset_id=..., table_name=..., task_id=...)` | 约束 4 |
| 5. 导入数据 | `uds-cli --task-id <task_id> import file.csv --table uds_{dataset_id}.表名 --mode full_replace` | |
| 6. 质量检查 | `uds-cli --task-id <task_id> exec "SELECT COUNT(*) FROM uds_{dataset_id}.表名"` 检查行数、空值、重复 | upsert 需跑两次验幂等 |
| 7. 反读列定义 | `uds-cli --task-id <task_id> inspect --table uds_{dataset_id}.表名` → 取 target_columns | 禁止凭空编造 |
| 8. 确认更新模式 | 问用户：append / full_replace / upsert？是否需要定时更新？ | |
| 9. 完善配置 | `uds_table_manage(action="update", update_mode=..., target_columns=..., sources=...)` | |

**upsert 幂等性验证**（update_mode=upsert 时必做）：

步骤 5 首次导入成功后，用同样的数据再跑一次导入，然后检查：
1. `SELECT COUNT(*)` — 行数应与首次一致（无重复行）
2. `SELECT ... GROUP BY <upsert_keys> HAVING COUNT(*) > 1` — 应为空（主键无重复）
3. 行数翻倍或主键重复 → 修复 `--upsert-keys` 配置后重新从步骤 5 开始

**Step 2.2 — 整体校验**

所有表构建完成后，做跨表级别的质量检查和业务验证：

- **表存在性**：`uds-cli tables --schema uds_{dataset_id}` 确认所有预期表已创建
- **行数验证**：每张表 `SELECT COUNT(*)` 与导入时的 rows_inserted 比对
- **关键列空值**：主键列、业务核心列不应有空值
- **关联完整性**（多表场景）：外键引用的 ID 在关联表中存在
- **业务逻辑合理性**：金额 >= 0、日期在合理范围内、枚举值在预期集合内
- **业务查询验证**：写 2-3 条典型业务查询，向用户展示结果确认

任何问题停下来让用户决策（约束 3）。

**Step 2.3 — 产出物沉淀**

按顺序执行，任何一步失败都按约束 2 如实汇报：

1. **表间关系**：`uds_relations_set(action="replace", relations=[...], task_id=<task_id>)`
2. **治理规则补录**：回顾访谈，补齐未落库的规则（正常应为空，已实时落库）
3. **使用指南**：`uds_dataset_manage(action="update", tool_usage_guide="...", task_id=<task_id>)`（约束 5）。内容包含：数据集业务背景、核心表说明、关键业务口径、常用查询入口
4. **权限策略**（可选）：询问用户是否需要分表/分列/分行的细粒度分享控制
5. **自查清单**：每张表有 dataset_table 记录且 target_columns 非空？tool_usage_guide 有实质内容？关系/规则引用的 table_name 都存在？有不通过项按约束 2 汇报

#### Phase 3 — 同步验证与交付

Phase 2 通过 `uds-cli import` 直接导入数据验证了数据正确性。Phase 3 通过 `uds_sync_task` 走完整的异步同步链路（上传 → 沙箱执行 → 回调 → 原子写入），验证生产环境能跑通。**配置了定时同步的表必须走 Phase 3，否则定时任务可能配好却跑不通。**

**Step 3.1 — 逐表触发 sync task**

对每张配置了 sources 的表，按 source 类型触发验证：

**upload 源的表**（验证文件上传导入链路）：
```
uds-cli upload data.csv --dataset dataset_id → 拿到 workspace_path
uds_sync_task(action="run", source_type="upload", file_paths=[workspace_path], table_name=..., import_mode=..., task_id=<task_id>)
→ 返回 group_id → 轮询 uds_sync_task(action="status", group_id=..., task_id=<task_id>) 直到终态
```

**script 源的表**（验证脚本执行链路）：
```
uds-cli upload fetch_script.py --dataset dataset_id → 拿到 workspace_path
uds_table_manage(action="update", script_file=workspace_path, sources=[...], task_id=<task_id>)
uds_sync_task(action="run", source_type="script", table_name=..., import_mode=..., task_id=<task_id>)
→ 返回 group_id → 轮询 status 直到终态
```

轮询间隔建议：数据量 < 1 万行等 30 秒，1-10 万行等 60 秒，10 万行以上等 180 秒。

**Step 3.2 — 失败处理与重试**

| 状态 | 处理 |
|------|------|
| `success` | 该表验证通过，继续下一张 |
| `failed` + `USER_FILE` | 文件格式问题 → 向用户说明，协助调整文件后重新触发 |
| `failed` + `SCRIPT` | 脚本异常 → 查看 `uds_sync_logs` 日志 → 修复脚本 → 重新上传并触发 |
| `failed` + `INFRA` | 系统异常 → 告知用户，建议稍后重试 |

重试流程：修复问题（改脚本/改文件）→ 若改了 script_file 则 `uds_table_manage(update)` 同步配置 → 重新触发 `uds_sync_task` → 轮询直到通过。

**Step 3.3 — 最终汇报**

所有表验证通过后，按约束 2 的「已完成 / 部分完成 / 未完成」三段式汇报。

**含定时任务的表：汇报前必须核实 `cron_enabled` 真实状态**

汇报前调 `uds_dataset_get(dataset_id, task_id=<task_id>)`，对每张含 `script` + `schedule` 源的表读取 `cron_enabled`：

- `cron_enabled=false`（默认值）：告知用户"定时规则已配置（如每天北京时间 03:00），但尚未启用，是否需要开启？"。用户确认后 `uds_table_manage(action="update", cron_enabled=true, task_id=<task_id>)` 开启
- `cron_enabled=true`：告知用户"定时任务已在运行中，新规则将于下个周期生效"

禁止未核实状态即笼统声称"定时任务已设置完成"。

汇报模板：
```
数据集构建结果：

【已完成】
- 数据集「{名称}」已创建，包含 N 张数据表
- 已导入 X 条数据，同步验证全部通过
- 已设置 M 条治理规则

【部分完成 / 待确认】
- 「订单表」定时同步已配置（每天 03:00），但尚未开启，是否需要开启？

【未完成】
- （无）
```

---

### 4.2 更新已有数据集的数据

所有同步（upload/script）均为异步执行。流程统一为：触发 → 拿 group_id → 轮询 status。

**upload（手动上传文件导入）：**

```
1. uds-cli upload orders.csv --dataset dataset_id → 拿到 workspace_path
2. uds_sync_task(action="run", source_type="upload",
                 file_paths=[workspace_path], table_name=..., import_mode=..., task_id=<task_id>)
   → 返回 group_id
3. 轮询 uds_sync_task(action="status", group_id=..., task_id=<task_id>) 直到 success/failed
```

- 多文件逐个 upload，把所有 workspace_path 放进 file_paths 一次触发
- 可选配 transform 脚本（`uds_table_manage` 设 `script_file`）做数据清洗
- 不配脚本时自动用内置直通导入

**script（脚本自动拉取外部数据）：**

```
1. 本地写好脚本 → uds-cli upload fetch_orders.py --dataset dataset_id → 拿到 workspace_path
2. uds_table_manage(action="update", script_file=workspace_path, sources=[...], task_id=<task_id>)
3. uds_sync_task(action="run", source_type="script", table_name=..., import_mode=..., task_id=<task_id>)
   → 返回 group_id → 轮询 status 直到终态
```

- script 表必须有脚本（先 uds-cli upload 再设 script_file）
- 凭证通过 `uds_credential_store` 存储，运行时自动注入 `os.environ`

**排查失败：**

前置：先用 `uds_sync_logs(dataset_id=..., status="failed", task_id=<task_id>)` 查看近期失败记录。每条记录含 `error_code`、`error_message`、`log_url`、`started_at`。

先对比最近 error 的 `started_at` 和表配置的最后更新时间——error 早于配置修改时间说明是历史遗留，告知用户等下一轮验证，不要动脚本。

| 情况 | 处理 |
|------|------|
| **error_code=USER_FILE** | 文件格式不匹配。对比 target_columns 告知用户差异，让用户修正文件后重新上传触发 |
| **error_code=SCRIPT** | 脚本异常。查看 `error_message` 和 `log_url` 定位问题 → 修复脚本 → `uds-cli upload` 重新上传 → `uds_table_manage(update, script_file=..., task_id=<task_id>)` 更新配置 → `uds_sync_task(action="run", task_id=<task_id>)` 重新触发验证 |
| **error_code=INFRA** | 系统异常。告知用户，建议稍后重试 |
| **任务长时间卡在 running** | 脚本崩溃未正常返回。僵尸巡检会在 70 分钟后自动置为 failed。通过 `log_url` 查看完整执行日志定位问题 |
| **error_code=ROW_LIMIT_EXCEEDED** | 导入行数超过 max_rows_per_table 上限。向用户说明并提供选项：改用 full_replace / 清理旧数据 / 按维度拆表（当前单表上限 2000 万行，暂不支持调整）。禁止自行截断数据 |
| **error_code=GROUP_ABORTED** | 多文件 upload 中前序文件失败，后续文件被中止。先修复失败的文件，再整组重新触发 |

**修复后重试流程：**

```
修复问题（改脚本/改文件）
  → 若改了脚本：uds-cli upload 重新上传 + uds_table_manage(update, script_file=..., task_id=<task_id>) 同步配置
  → uds_sync_task(action="run", task_id=<task_id>) 重新触发
  → 轮询 status 直到通过
```

**修改表结构：**

修改已有表结构（加字段、改类型、加索引、重命名等）后，必须同步相关元数据，否则同步任务、使用指南、权限策略会与实际表结构不一致。

前置：`uds-cli inspect --table uds_{dataset_id}.表名` 查看当前结构，与用户确认变更方案。

操作：`uds-cli exec --mode writer "ALTER TABLE ..."` 执行结构变更。

后续同步：

| 变更类型 | 同步动作 |
|------|------|
| target_columns 变了 | `uds_table_manage(update, target_columns=[...], task_id=<task_id>)` — 必须从 `uds-cli inspect` 反读，不凭空编造 |
| 表清单或字段含义变了 | `uds_dataset_manage(update, tool_usage_guide=..., task_id=<task_id>)` |
| 新增关联字段 | `uds_relations_set(action="create", task_id=<task_id>)` 增量新增，或 replace 全量覆盖 |
| 新增计算口径 | `uds_rule_manage(action="create", task_id=<task_id>)` |
| 脚本逻辑受影响 | 修改脚本 → `uds-cli upload` 重新上传 → `uds_table_manage(update, script_file=..., task_id=<task_id>)` |
| 删列/改列名且该表有权限策略 | `uds_policy_manage(action="update", task_id=<task_id>)` 更新 row_filters/column_rules 中引用的列，否则策略 View 失效 |

---

### 4.3 配置定时自动更新

#### 更新模式

| 模式 | 含义 | 适用场景 |
|------|------|----------|
| append | 追加写入 | 日志、事件流 |
| full_replace | 全量替换（原子换表，无空表中间态） | 维表、小表、定期全量拉取 |
| upsert | 按主键更新已有行、插入新行 | 增量同步 |

#### 脚本规范

脚本入口函数有两种，按数据源类型选择：

**script 源（定时拉取外部数据）— 入口 `fetch`**：

```python
def fetch(table_name: str, update_mode: str, target_columns: list, **kwargs) -> dict:
    """定时任务入口，由 Hub Scheduler 按 cron 触发。"""
```

**upload 源（用户上传文件导入）— 入口 `transform`**：

```python
def transform(file_path: str, filename: str, table_name: str, update_mode: str, target_columns: list, **kwargs) -> dict:
    """文件上传入口，用户在前端上传文件时触发。"""
```

**Hub wrapper 自动注入的参数**：

| 参数 | fetch (script) | transform (upload) | 说明 |
|------|:-:|:-:|------|
| `table_name` | Y | Y | 目标表全限定名（如 uds_{dataset_id}.orders） |
| `update_mode` | Y | Y | append / full_replace / upsert |
| `target_columns` | Y | Y | 目标列定义（list[dict]） |
| `file_path` | - | Y | 用户上传文件的沙箱绝对路径 |
| `filename` | - | Y | 用户上传的原始文件名 |
凭证通过环境变量注入（`os.environ['凭证名']`），不通过函数参数传递。

**返回值**：
- 成功：`{"success": True, "rows_inserted": N}`
- 失败：`{"success": False, "error_code": "SCRIPT", "error": "...", "rows_inserted": 0}`

**最小可运行示例**（API 拉取 → CSV → uds-cli import）：

```python
import os, subprocess, json, csv, gc
import urllib.request

TASK_ID = "tk_xxxxxxxx"  # Agent 写脚本时替换为当前会话的 task_id

def fetch(table_name, update_mode, **kwargs):
    req = urllib.request.Request("https://api.example.com/data", headers={"User-Agent": "uds-sync/1.0"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        data = json.loads(resp.read())

    tmp_csv = f"/workspace/tmp/sync_{table_name.split('.')[-1]}.csv"
    with open(tmp_csv, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["id", "name", "value"])
        for item in data["items"]:
            writer.writerow([item["id"], item["name"], item["value"]])

    rows = len(data["items"])
    r = subprocess.run(["uds-cli", "--task-id", TASK_ID, "import", tmp_csv,
                         "--table", table_name, "--mode", update_mode],
                       capture_output=True, text=True)
    os.remove(tmp_csv)

    if r.returncode != 0:
        return {"success": False, "error_code": "SCRIPT", "error": r.stderr, "rows_inserted": 0}
    return {"success": True, "rows_inserted": rows}
```

脚本规范要点：
- 入口函数：script 源用 `fetch`，upload 源用 `transform`
- 数据导入通过 `subprocess.run(["uds-cli", "import", ...])` 完成（沙箱已预装 uds-cli，凭证由平台自动注入）
- 凭证通过 `os.environ['凭证名']` 读取（凭证名即 `uds_credential_store` 存储的名称）
- error_code 分类：文件解析类异常（`ParserError`、`UnicodeDecodeError`、`KeyError`、`ValueError`）返回 `USER_FILE`；其他异常返回 `SCRIPT`。分类影响用户侧错误提示
- 复刻清洗：脚本必须复刻建表时做过的所有清洗动作（列名 strip、类型转换、衍生列）。API 数据源必须在脚本中做 camelCase → snake_case 的列名映射
- upsert 模式：`uds-cli import` 必须带 `--upsert-keys`；导入前必须对候选主键 `drop_duplicates`（PG 同一批次不能 upsert 同一行两次）
- 临时文件用完即删，大数据量逐批处理并及时 `del df; gc.collect()`
- 回调由 Hub wrapper 自动处理，脚本只需正确返回结果字典

**沙箱资源与内存管理**：

沙箱环境内存有限（约 4C8G），多文件百万行数据易 OOM：
- 逐文件串行处理，每个文件处理完 `del df; gc.collect()` 显式释放
- 探查阶段只读采样（`nrows=500`），不全量加载
- 大文件（>50 万行 或 >100MB）优先 polars 或 DuckDB，不用 pandas 全量加载（DuckDB 不直接读 Excel，Excel 用 polars/pandas）

**沙箱共享策略**：

同一数据集内相同 schedule 的多张表在共享沙箱中串行执行。脚本必须遵守以下规约，否则会导致同组其他表连带失败：

- 用绝对路径，禁止 `os.chdir()`
- 禁止函数外层或模块级修改 `os.environ`，配置走函数参数传入
- 禁止运行时 `sys.path.insert` / `append`，依赖用 pip 安装
- 外部资源（文件、DB 连接、HTTP session）全部用 `with` 上下文，函数返回前必须释放
- 临时文件优先 `tempfile.TemporaryDirectory()`；直接写 `/workspace/tmp/` 时脚本结束前自行清理
- 不要在模块级创建有状态对象（如 `driver = webdriver.Chrome()`），改为函数内创建并 `finally` 关闭

确实无法遵守规约时设 `exclusive_sandbox=true`（`uds_table_manage` update 时传入）隔离该表的沙箱。

**外部数据源规则**：

- 源库只读：只做 SELECT / find，禁止写入
- 分块必须：所有外部数据源分块读取（CHUNK_SIZE 约 5000），逐块写 CSV → `uds-cli import`，每块 `del df; gc.collect()`
- 连接释放：`try/finally` 确保连接关闭
- 凭证安全：host/port 等非敏感配置可写脚本；password/token 必须通过 `uds_credential_store` 存储，脚本从 `os.environ` 读取
- 增量同步：配合 `update_mode=upsert`，用时间戳或自增 ID 做增量起点

**数据源为外部数据库或 API 时，编写脚本前必须先读** `references/scheduled-sync-guide.md` 的对应数据源模板（MySQL 分块拉取、API 分页拉取等），避免连接泄漏和内存溢出。

#### 配置流程

```
1. 如需凭证：uds_credential_store(action="store", credential_name="API_KEY", credential_value="...", task_id=<task_id>)
2. 上传脚本：uds-cli upload fetch_script.py --dataset dataset_id → workspace_path
3. 注册配置：uds_table_manage(action="update",
     script_file=workspace_path,
     sources=[{"type": "script", "entry": "fetch", "schedule": "0 2 * * *", "timezone": "Asia/Shanghai"}],
     task_id=<task_id>)
4. 手动验证：uds_sync_task(action="run", source_type="script", table_name=..., import_mode=..., task_id=<task_id>)
   → 轮询 status 直到 success（失败则排查修复后重跑，不得只配置不验证）
5. 开启定时：向用户确认后 uds_table_manage(action="update", cron_enabled=true, task_id=<task_id>)
6. 核实状态：uds_dataset_get 读 cron_enabled 真实值后如实汇报
```

**cron 表达式说明**：标准 5 段格式（分 时 日 月 周），按 `timezone` 指定的时区解释。直接用用户所在时区的本地时间写 cron，无需手动换算 UTC。

| 表达式 | timezone | 含义 |
|--------|----------|------|
| `0 3 * * *` | Asia/Shanghai | 每天上海时间 03:00 |
| `*/10 * * * *` | Asia/Shanghai | 每 10 分钟 |
| `0 3 * * 1` | Asia/Shanghai | 每周一 03:00 |
| `0 */6 * * *` | （任意） | 每 6 小时 |

---

### 4.4 分享数据集

#### 数据集分享（一人一码）

精确控制每个人的权限，可独立撤销：

```
uds_share(resource="dataset", action="create", task_id=<task_id>) → 分享码（gfs_ 前缀）→ 发给接收者 → 接收者兑换 → 获得只读权限
```

- 给 N 个人分享 = 调 N 次 create（每个码独立可撤销）
- 可选挂 `policy_id` 做细粒度权限（只能看特定表/列/行）
- 撤销（action="revoke"）后立即回收 PG 权限

#### 细粒度权限策略

先用 `uds_policy_manage(action="create", task_id=<task_id>)` 创建策略拿到 `policy_id`，分享时 `uds_share(create, policy_id=..., task_id=<task_id>)` 挂上：

- `allowed_tables`：可见的表列表
- `column_rules`：每张表可见的列
- `row_filters`：行级过滤条件（如 `region = 'CN'`）

#### 应用分享（多人链接）

广泛传播已部署的数据应用。前置：先部署应用拿到 `deploy_id`（见 4.5）。

```
uds_share(resource="app", action="create", deploy_id=..., visibility="public"|"specified", task_id=<task_id>)
```

- `visibility="public"`：任何人点链接都能访问
- `visibility="specified"`：`emails` 白名单控制

---

### 4.5 开发并部署数据应用

MCP 是远程服务，不读写本地文件。起项目只返回下载地址，部署只返回预签上传地址，下载/打包/PUT 上传都由本地 Agent 完成。

**开始开发前必须先读** `references/app-deploy-guide.md`（应用模板结构、数据库连接规范、打包注意事项）。

**app_name 命名规则**：小写字母、数字、连字符，必须以字母或数字开头，长度不超过 41 个字符（如 `sales-dashboard`、`order-tracker`）。

#### 完整流程

```
1. 起项目
   uds_init_project(mode="template", task_id=<task_id>) → 返回 download_url（tar.gz 源码包）
   本地下载解包到工作目录

2. 配置数据库连接
   uds-cli connect --mode reader --schema uds_{dataset_id} | head -3 > backend/.env
   → 写入 DATASETS_DATABASE_URL / DATASETS_DATABASE_TYPE / DATASETS_MANIFEST（临时凭证，1h 有效）

3. 本地开发
   按模板 README.md 开发（后端 Express + TypeScript，前端 React + Vite）
   代码中用 tableOf(dataset_id, table) 引用数据集表，不硬编码 schema 名

4. 打包（从项目根目录内部打，Dockerfile 必须在 tar 包根层）
   cd <project-root> && tar czf /tmp/app.tar.gz --exclude=node_modules --exclude=.git --exclude=.venv --exclude=.env .

5. 部署（两步）
   Step 1: uds_app_deploy(dataset_id=..., app_name="my-app", filename="app.tar.gz", task_id=<task_id>)
           → 返回 upload_url + package_key
   Step 2: 本地 curl -X PUT --upload-file /tmp/app.tar.gz -H "Content-Type: application/gzip" '<upload_url>'
   Step 3: uds_app_deploy(dataset_id=..., app_name="my-app", package_key="<上一步的 key>", task_id=<task_id>)
           → 返回 app_url + deploy_id + app_id

6. 确认在线
   uds_app_status(deploy_id=..., task_id=<task_id>) → status="online" 即部署成功

7. 新版本部署（同 URL 覆盖）
   传 app_id（首次部署返回的）→ uds_app_deploy(app_id=..., filename=..., task_id=<task_id>) 走同样两步流程
   不传 app_id = 创建全新应用（新 URL），传 app_id = 更新已有应用（URL 不变，保留最近 2 版可回滚）
```

#### 版本管理

- `uds_app_status(deploy_id, task_id=<task_id>)` — 查状态、URL、版本号、是否可回滚
- `uds_app_manage(action="rollback", deploy_id, direction="back", task_id=<task_id>)` — 回滚到上一版
- `uds_app_manage(action="rollback", deploy_id, direction="forward", task_id=<task_id>)` — 撤销回滚
- `uds_app_manage(action="offline", deploy_id, task_id=<task_id>)` — 下线应用
- `uds_app_manage(action="online", deploy_id, task_id=<task_id>)` — 恢复上线
- `uds_app_manage(action="delete", deploy_id, task_id=<task_id>)` — 永久删除（不可恢复）

#### 二次开发（fork）

```
uds_init_project(mode="fork", from_deploy_id=<deploy_id>, task_id=<task_id>)
→ 下载源码包 + 继承原应用绑定的数据集 → 本地修改 → 按上述第 4-6 步打包部署为新应用
```

---

## 5. 常见问题处理

| 问题 | 原因与处理 |
|------|-----------|
| `uds-cli exec` 报 permission denied | SQL 表名未用全限定名。正确写法：`SELECT * FROM uds_{dataset_id}.表名` |
| `uds-cli exec` 报 SQL 语法错误 | 后端为 PostgreSQL，禁用 MySQL 语法。常见：自增主键用 `SERIAL` 而非 `AUTO_INCREMENT`；注释用独立 `COMMENT ON COLUMN` 而非 `AFTER ... COMMENT`；字符串用单引号，标识符用双引号而非反引号；改字段用 `ALTER COLUMN ... TYPE` 而非 `MODIFY COLUMN` |
| 同步任务一直卡在 running | 脚本崩溃未正常返回。僵尸巡检会在 70 分钟后自动置为 failed。通过 `uds_sync_logs` 查看 `log_url` 获取完整执行日志 |
| 分享后对方看不到数据 | (1) 分享码未兑换 (2) 挂了 policy_id 限制了可见范围 (3) 基表无数据 |
| full_replace 时数据消失 | 不会消失。full_replace 走临时表 + 原子 RENAME，失败时正式表不受影响 |
| 配了定时却不自动更新 | 最常见原因：`cron_enabled=false`（未开启）。用 `uds_dataset_get` 核实后，经用户确认开启 |
| 导入失败 duplicate key | upsert 模式下同一批次数据中存在重复主键。需在脚本中对候选主键 `drop_duplicates` 后再导入 |
| 共享沙箱中某表定时失败但单独执行正常 | 同 schedule 的其他表脚本污染了共享沙箱环境（如 `os.chdir()`、修改 `os.environ`、未释放连接）。定位污染源脚本并修复，或为该表设 `exclusive_sandbox=true` 隔离 |
| `uds-cli` 命令失败 | 先执行 `uds-cli <命令> --help` 确认参数。单条命令最多重试 1 次，重试前必须先分析错误并修正，禁止不改任何内容盲目重试 |
