# GoalfyData 通用数据集构建指南

> 本文档是 SKILL.md 的补充参考，承载「业务访谈 / 表命名 / uds-cli 与 PG 语法 / 失败处理」的详尽规则。新建数据集和改结构时按本指南执行。

---

## 1. 业务访谈

### 1.1 四维度矩阵

按 4 维度组织，每维度覆盖完才进入下一维度。具体问题根据数据类型动态生成。

| 维度 | 目标 | 深入时机 |
|------|------|----------|
| 业务背景 | 这份数据是什么？记录哪个业务环节？时间范围？更新频率？来源？ | 所有数据类型必问 |
| 业务口径 | 字段含义？主键？单位（金额/日期/时区）？空值语义？ | 含数字、日期、状态字段时深入 |
| 业务规则 | 计算口径（GMV/ROI/UV）？状态枚举？约束条件？ | 含衍生字段、状态字段、关联字段时深入 |
| 跨表关系 | 外键映射？完整性？是否合并为一个数据集？ | 多文件场景必问 |

### 1.2 节奏

- 一次问一组（不超过 5 个相关问题），**禁止**一次甩 20 个
- 每组答复后用业务语言复述确认（"所以您的 GMV 是扣退款不扣运费的净额，对吗？"）
- 全部维度覆盖完才进入建表——浅尝辄止会导致后续方案反复推倒
- 访谈中发现的业务口径实时调 `uds_rule_manage(action="create", task_id=<task_id>)` 落库，并一句话告知用户

### 1.3 三条硬规则（带正反例）

**问题**必须**有数据依据** — 每个问题附带从数据中发现的具体信息，不凭空提问。

| 反例（无依据） | 正例（有依据） |
|---|---|
| "订单状态有哪些值？" | "我扫描了状态列，发现 3 个值：已完成 / 已取消 / 处理中。这是完整的状态吗？" |

**先分析再问，不反问用户不知道的** — 遇到用户可能不了解的信息，先基于数据样本自主推断，带着结论让用户确认。

| 反例（反问） | 正例（带结论确认） |
|---|---|
| "金额是什么单位？" | "根据数值范围（10-5000）和马来西亚站点，推断金额单位是马来西亚林吉特（MYR）。请确认？" |

**确认措辞**必须**详尽** — 把关键上下文写全（来源、时间范围、单位、口径），不只说"确认以上"。

| 反例（模糊） | 正例（详尽） |
|---|---|
| "以上信息是否正确？" | "请确认：来源=TikTok 马来西亚站点，时间范围=2025-01 至 2026-03，金额单位=MYR（含税），GMV 口径=扣退款不扣运费。是否正确？" |

### 1.4 自主决策 vs **必须**确认

- **可自主决策**：字段命名（snake_case 转换）、表名前缀生成、衍生列命名、清洗的技术实现
- **必须用确认（停下问用户）**：业务口径、表结构方案、数据质量处理策略、更新模式、跨表关系、大数据量处理、开启定时任务

### 1.5 治理规则随时落库

治理规则（业务口径/约束/计算公式/清洗约定）全流程捕获，不集中到最后批量处理。判断标准："这条信息若未落库，未来查询会产生歧义或错误"。基于语义判断，不做关键词匹配。

`rule_type` 映射：`cleaning`（清洗）/ `validation`（校验）/ `computation`（计算口径）/ `constraint`（约束）。

落库即告知用户（"已记录：金额单位为分"），不做静默落库——规则影响未来所有查询，用户有知情权。

---

## 2. 表命名规范

**格式**：`<业务域前缀>_<表名>`

**前缀生成**（向用户确认时只展示中文业务名，不展示英文前缀）：

1. 从业务背景提取 2-4 个关键词，按顺序：平台/来源 + 主体 + 时间粒度
2. 每个关键词独立转 snake_case（小写英文字母、数字、下划线）
3. 非英文词（如中文店铺名）用拼音首字母或音译简写
4. 关键词之间用 `_` 连接
5. 前缀总长度 ≤ 30 字符，前缀 + 表名总长度 ≤ 63（PG 标识符上限）

**约束**：

- 同一数据集下所有表共享同一前缀
- 只能小写字母、数字、下划线
- **禁止**：裸表名（`orders`）、数据集 uid 前缀（`udsx7_orders`）、驼峰或大写（`Orders`、`TikTokOrders`）

---

## 3. uds-cli 与 PG 语法

### 3.1 子命令速查

| 命令 | 用途 |
|------|------|
| `uds-cli --task-id <task_id> schemas` | 列出可见数据集（含 schema 名） |
| `uds-cli --task-id <task_id> exec "<SQL>" --mode reader/writer` | 执行 SQL（查询 reader，DDL/DML writer），支持 `;` 分隔多条 |
| `uds-cli --task-id <task_id> exec --file x.sql --mode writer` | 从文件执行多条 SQL |
| `uds-cli --task-id <task_id> import <file> --table <name> --mode <mode>` | 导入 CSV/Excel，mode=append/full_replace/upsert，upsert 加 `--upsert-keys k1,k2` |
| `uds-cli --task-id <task_id> inspect --table <name>` | 查看表结构（反读 target_columns 用） |

表名一律用全限定名 `uds_{dataset_id}.表名`。

### 3.2 PG 语法陷阱（uds-cli 后端是 PostgreSQL，禁用 MySQL 语法）

- 列注释：`COMMENT ON COLUMN <table>.<col> IS '注释'`（独立语句）。**不能**用 MySQL 的 `... COMMENT '...'`
- 自增主键：`BIGSERIAL` / `SERIAL`。不是 `AUTO_INCREMENT`
- 改字段类型：`ALTER COLUMN <col> TYPE <type> USING <expr>`。不是 `MODIFY COLUMN`
- 字符串用单引号，标识符不加引号或用双引号。禁反引号
- 列别名：`AS col_name` 或 `AS "中文别名"`（双引号），**不能**用单引号
- NULL 判断：`IS NULL` / `IS NOT NULL`
- 类型转换：`::type` 或 `CAST(x AS type)`

### 3.3 建表 COMMENT 规范

建表时每个字段补独立的 `COMMENT ON COLUMN uds_{dataset_id}.<table>.<col> IS '<原始列名/业务中文名> - <含义/单位/枚举>'`，原始列名即 display_name，便于其他 Agent 理解字段。

---

## 4. 失败处理

### 4.1 失败决策树

```
uds-cli 命令失败
├── 参数/用法错误 → 修正后重试（≤ 1 次）
├── SQL 语法错误  → 修正后重试（≤ 1 次）
├── 数据质量问题  → 停下来让用户决策（约束 3）
└── 其他错误      → 停下来如实汇报（约束 2）
```

### 4.2 重试上限

单条命令最多执行 2 次（首次 + 1 次修正重试）。超过**必须**停下来按约束 2 汇报。

**禁止盲重试**：失败后**必须**先分析错误、定位根因、确认修正方案再重试，**禁止**不改任何东西重复执行：

- 导入失败（duplicate key / type mismatch / 文件不存在）→ 定位根因（主键不唯一？类型不匹配？路径错？），修正后重试
- 建表后导入失败需重建 → DROP + CREATE 前**必须**确认新 DDL 修正了失败原因
- 脚本执行失败 → 读完整错误信息定位代码行，修正后重试

### 4.3 行数上限 ROW_LIMIT_EXCEEDED

`uds-cli import` 写入前按单表上限（当前固定 20,000,000 行，暂不支持调整）做批校验，超限时整批 rollback 并返回 `ROW_LIMIT_EXCEEDED`。

**禁止**盲目分批/截断重试——会导致数据被静默截断，违反约束 2。正确处置：停下来让用户三选一：

1. **改用 `full_replace` 模式** — 先 TRUNCATE 再写，写入后行数 = 新数据行数。前提：用户确认旧数据可丢；append/upsert 下**禁止**自作主张切换
2. **清理旧数据** — 给一段示意 `uds-cli --task-id <task_id> exec "DELETE FROM uds_{dataset_id}.<table> WHERE <条件>"`（按时间窗口/业务维度），用户确认条件后执行，**禁止**直接 TRUNCATE 不问
3. **按维度拆表** — 单表上限 2000 万行暂不支持调整，按时间窗口或业务维度拆分为多张表

**禁止**：收到 ROW_LIMIT_EXCEEDED 后悄悄丢部分行重试；把超限当普通"导入失败"走重试（重试也是同样失败）；未经确认就切 `full_replace`。

---

## 5. 底表与中间表

数据集里的表分两类，构建策略不同：

**底表**：直接从用户文件建的表，一个数据文件对应一张底表（标准闭环自动建）。

**中间表**（汇总表 / 宽表 / 维度表）：是否建、聚合什么维度、刷新策略，全是业务决策，**必须和用户确认**，不主动建。

| 场景 | 做法 |
|------|------|
| 用户只传了原始数据文件（干净或类别 A） | 只建底表，不主动建中间表 |
| 用户明确要汇总表 / 宽表 | 建底表 + 中间表（用户确认聚合维度和粒度后） |
| 你发现底表间有明显汇总需求 | 主动向用户建议，同意后再建 |
| 中间表数据来自 SQL 聚合（不是文件导入） | 中间表注册 `script` 源、入口 `fetch`，更新脚本用 `uds-cli --task-id <task_id> exec` 做 SQL 聚合（`INSERT INTO 中间表 SELECT ... FROM 底表 GROUP BY ...`），不读文件 |

中间表也是表，**同样要 `uds_table_manage` 注册元数据**（约束 4）；要定时刷新就配 `schedule`（见 `scheduled-sync-guide.md`）。

---

## 6. 标准闭环详细步骤

对每个文件/数据源重复。**入口必须先读** `references/data-quality-guide.md` 执行数据质量检测（脏数据分类、机器信号 + 语义判断方法、建表前校验清单）：

- 干净或可自动修复（类别 A）→ 进入标准闭环
- 无法自动修复（类别 B）→ 停止本表后续步骤，向用户说明数据质量问题并协商处理方案

**标准闭环**：

| 步骤 | 动作 | 关键约束 |
|------|------|----------|
| 1. 数据探查 | 分析行数、类型分布、空值、样本值 | 采样模式，不全量加载 |
| 2. 建表方案确认 | 向用户展示字段业务含义，确认表结构 | 约束 3 |
| 3. 建表 | `uds-cli --task-id <task_id> exec --mode writer "CREATE TABLE uds_{dataset_id}.表名 (...)"` | 字段 snake_case；建表前先读本文档第 2-3 节（命名规范 + PG 语法陷阱） |
| 4. 注册元数据 | `uds_table_manage(action="create", dataset_id=..., table_name=..., task_id=...)` | 约束 4 |
| 5. 导入数据 | `uds-cli --task-id <task_id> import file.csv --table uds_{dataset_id}.表名 --mode full_replace` | |
| 6. 质量检查 | `uds-cli --task-id <task_id> exec "SELECT COUNT(*) FROM uds_{dataset_id}.表名"` 检查行数、空值、重复 | upsert 需跑两次验幂等 |
| 7. 反读列定义 | `uds-cli --task-id <task_id> inspect --table uds_{dataset_id}.表名` → 取 target_columns | 禁止凭空编造 |
| 8. 确认更新模式 | 问用户：append / full_replace / upsert？是否需要定时更新？ | |
| 9. 完善配置 | `uds_table_manage(action="update", update_mode=..., target_columns=..., sources=..., task_id=<task_id>)` | |

**upsert 幂等性验证**（update_mode=upsert 时必做）：

步骤 5 首次导入成功后，用同样的数据再跑一次导入，然后检查：
1. `SELECT COUNT(*)` — 行数应与首次一致（无重复行）
2. `SELECT ... GROUP BY <upsert_keys> HAVING COUNT(*) > 1` — 应为空（主键无重复）
3. 行数翻倍或主键重复 → 修复 `--upsert-keys` 配置后重新从步骤 5 开始

---

## 7. 整体校验清单

所有表构建完成后，做跨表级别的质量检查和业务验证：

- **表存在性**：`uds-cli --task-id <task_id> tables --schema uds_{dataset_id}` 确认所有预期表已创建
- **行数验证**：每张表 `SELECT COUNT(*)` 与导入时的 rows_inserted 比对
- **关键列空值**：主键列、业务核心列不应有空值
- **关联完整性**（多表场景）：外键引用的 ID 在关联表中存在
- **业务逻辑合理性**：金额 >= 0、日期在合理范围内、枚举值在预期集合内
- **业务查询验证**：写 2-3 条典型业务查询，向用户展示结果确认

任何问题停下来让用户决策（约束 3）。

---

## 8. 产出物沉淀步骤

按顺序执行，任何一步失败都按约束 2 如实汇报：

1. **表间关系**：`uds_relations_set(action="replace", relations=[...], task_id=<task_id>)`
2. **治理规则补录**：回顾访谈，补齐未落库的规则（正常应为空，已实时落库）
3. **使用指南**：`uds_dataset_manage(action="update", tool_usage_guide="...", task_id=<task_id>)`（约束 4）。内容包含：数据集业务背景、核心表说明、关键业务口径、常用查询入口
4. **权限策略**（可选）：询问用户是否需要分表/分列/分行的细粒度分享控制
5. **自查清单**：每张表有 dataset_table 记录且 target_columns 非空？tool_usage_guide 有实质内容？关系/规则引用的 table_name 都存在？有不通过项按约束 2 汇报

---

## 9. 修改表结构

修改已有表结构（加字段、改类型、加索引、重命名等）后，必须同步相关元数据，否则同步任务、使用指南、权限策略会与实际表结构不一致。

前置：`uds-cli --task-id <task_id> inspect --table uds_{dataset_id}.表名` 查看当前结构，与用户确认变更方案。

操作：`uds-cli --task-id <task_id> exec --mode writer "ALTER TABLE ..."` 执行结构变更。

后续同步：

| 变更类型 | 同步动作 |
|------|------|
| target_columns 变了 | `uds_table_manage(update, target_columns=[...], task_id=<task_id>)` — 必须从 `uds-cli --task-id <task_id> inspect` 反读，不凭空编造 |
| 表清单或字段含义变了 | `uds_dataset_manage(update, tool_usage_guide=..., task_id=<task_id>)` |
| 新增关联字段 | `uds_relations_set(action="create", task_id=<task_id>)` 增量新增，或 replace 全量覆盖 |
| 新增计算口径 | `uds_rule_manage(action="create", task_id=<task_id>)` |
| 脚本逻辑受影响 | 修改脚本 → `uds-cli --task-id <task_id> upload` 重新上传 → `uds_table_manage(update, script_file=..., task_id=<task_id>)` |
| 删列/改列名且该表有权限策略 | `uds_policy_manage(action="update", task_id=<task_id>)` 更新 row_filters/column_rules 中引用的列，否则策略 View 失效 |
