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
| 跨表关系 | 关联字段映射？完整性？是否合并为一个数据集？ | 多文件场景必问 |

### 1.2 节奏

- 每次提问一组（不超过 5 个相关问题），**禁止**一次性提出 20 个问题
- 每组答复后用业务语言复述确认（"所以您的 GMV 是扣退款不扣运费的净额，对吗？"）
- 全部维度覆盖完才进入建表——浅尝辄止会导致后续方案反复推倒
- 访谈中发现的业务口径实时调 `uds_rule_manage(action="create", task_id=<task_id>)` 落库，并一句话告知用户

### 1.3 三条硬规则（带正反例）

**问题**必须**有数据依据** — 每个问题附带从数据中发现的具体信息，不凭空提问。

| 反例（无依据） | 正例（有依据） |
|---|---|
| "订单状态有哪些值？" | "我扫描了状态列，发现 3 个值：已完成 / 已取消 / 处理中。这是完整的状态吗？" |

**先分析后提问，不反问用户不了解的信息** — 遇到用户可能不了解的信息，先基于数据样本自主推断，带推断结论向用户确认。

| 反例（反问） | 正例（带结论确认） |
|---|---|
| "金额是什么单位？" | "根据数值范围（10-5000）和马来西亚站点，推断金额单位是马来西亚林吉特（MYR）。请确认？" |

**确认措辞**必须**详尽** — 把关键上下文写全（来源、时间范围、单位、口径），不只说"确认以上"。

| 反例（模糊） | 正例（详尽） |
|---|---|
| "以上信息是否正确？" | "请确认：来源=TikTok 马来西亚站点，时间范围=2025-01 至 2026-03，金额单位=MYR（含税），GMV 口径=扣退款不扣运费。是否正确？" |

### 1.4 自主决策 vs **必须**确认

- **可自主决策**：字段命名（snake_case 转换）、表名前缀生成、衍生列命名、清洗的技术实现
- **必须暂停并询问用户确认**：业务口径、表结构方案、数据质量处理策略、更新模式、跨表关系、大数据量处理、开启 GoalfyData 托管刷新定时触发

### 1.5 治理规则随时落库

治理规则（业务口径/约束/计算公式/清洗约定）全流程捕获，不集中到最后批量处理。判断标准："这条信息若未落库，未来查询会产生歧义或错误"。基于语义判断，不做关键词匹配。

`rule_type` 映射：`cleaning`（清洗）/ `validation`（校验）/ `computation`（计算口径）/ `constraint`（约束）。

落库即告知用户（"已记录：金额单位为分"），不做静默落库——规则影响未来所有查询，用户有知情权。

---

## 2. 表命名规范

**格式**：`<业务域前缀>_<表名>`

**前缀生成**（向用户确认时只展示业务名——使用与用户一致的语言，不展示 snake_case 前缀）：

1. 从业务背景提取 2-4 个关键词，按顺序：平台/来源 + 主体 + 时间粒度
2. 每个关键词独立转 snake_case（小写英文字母、数字、下划线）
3. 非英文词（如中文店铺名）用拼音首字母或音译简写；用户语言本身为英文时直接取英文关键词
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
| `uds-cli --task-id <task_id> import <file> --table <name> --mode <mode>` | 导入数据，**只收 CSV/NDJSON**（xlsx 先 pandas 读真实值转 CSV），mode=append/full_replace/upsert，upsert 加 `--upsert-keys k1,k2` |
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
- 外键：**禁止** `FOREIGN KEY` / `REFERENCES`（数据集 schema 不支持，服务端拦截，报错 `FOREIGN_KEY_NOT_ALLOWED`）。表间关系改用 `uds_relations_set` 登记逻辑关系，不在 DDL 里建物理外键

### 3.3 建表 COMMENT 规范

建表时每个字段补独立的 `COMMENT ON COLUMN uds_{dataset_id}.<table>.<col> IS '<原始列名/业务名> - <含义/单位/枚举>'`（业务名使用与用户一致的语言），原始列名即 display_name，便于其他 Agent 理解字段。

---

## 4. 失败处理

### 4.1 失败决策树

```
uds-cli 命令失败
├── 参数/用法错误 → 修正后重试（≤ 1 次）
├── SQL 语法错误  → 修正后重试（≤ 1 次）
├── 数据质量问题  → 暂停操作，由用户决策（约束 4）
└── 其他错误      → 停止操作并如实汇报（约束 6）
```

### 4.2 重试上限

单条命令最多执行 2 次（首次 + 1 次修正重试）。超过后**必须**停止操作并按约束 6 汇报。

**禁止盲重试**：失败后**必须**先分析错误、定位根因、确认修正方案再重试，**禁止**不改任何东西重复执行：

- 导入失败（duplicate key / type mismatch / 文件不存在）→ 定位根因（主键不唯一？类型不匹配？路径错？），修正后重试
- 建表后导入失败需重建 → DROP + CREATE 前**必须**确认新 DDL 修正了失败原因
- 脚本执行失败 → 读完整错误信息定位代码行，修正后重试

### 4.3 存储超限 STORAGE_QUOTA_EXCEEDED

单表**没有行数上限**。存储采用数据集名额制：每个数据集默认包含 300MB，数据集不会因超过 300MB 就直接被阻止——更大的数据集按容量折算为多个数据集用量（例如 900MB 的数据集约按 3 个数据集计算）。

套餐的数据集用量耗尽时写入才会被拦：GoalfyData 托管刷新链路返回 `STORAGE_QUOTA_EXCEEDED`；agent 直接编辑（`uds-cli import` / `exec`）则可能在 PG 层报 `SCHEMA_BYTES_EXCEEDED`（单数据集字节硬限兜底）。

**禁止**盲目分批/截断重试——会导致数据被静默截断，违反约束 6。正确处置：暂停操作，由用户在以下三种方案中选择：

1. **改用 `full_replace` 模式** — 原子换表后仅保留新数据，存储占用 = 新数据大小。前提：用户确认旧数据可丢；append/upsert 下**禁止**自作主张切换
2. **清理旧数据** — 提供一段示例 `uds-cli --task-id <task_id> exec "DELETE FROM uds_{dataset_id}.<table> WHERE <条件>"`（按时间窗口/业务维度），用户确认条件后执行，**禁止**直接 TRUNCATE 不问
3. **升级套餐或购买加量包** — 用 `uds_billing_info` 查询当前配额与可用加量包，引导用户在 GoalfyData 网页端完成购买

**禁止**：收到存储超限后悄悄丢部分行重试；把超限当作普通"导入失败"盲目重试（重试同样失败）。

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

中间表也是表，**同样要 `uds_table_manage` 注册元数据**（约束 5）；要定时刷新就配 `schedule`（见 `scheduled-sync-guide.md`）。

---

## 6. 标准闭环详细步骤

对每个文件/数据源重复。**入口必须先读** `references/data-quality-guide.md` 执行数据质量检测（脏数据分类、机器信号 + 语义判断方法、建表前校验清单）：

- 干净或可自动修复（类别 A）→ 进入标准闭环
- 无法自动修复（类别 B）→ 停止本表后续步骤，向用户说明数据质量问题并协商处理方案

**标准闭环**：

| 步骤 | 动作 | 关键约束 |
|------|------|----------|
| 1. 数据探查 | 分析行数、类型分布、空值、样本值 | 采样模式，不全量加载 |
| 2. 建表方案确认 | 向用户展示字段业务含义，确认表结构 | 约束 4 |
| 3. 建表 | `uds-cli --task-id <task_id> exec --mode writer "CREATE TABLE uds_{dataset_id}.表名 (...)"` | 字段 snake_case；建表前先读本文档第 2-3 节（命名规范 + PG 语法陷阱） |
| 4. 注册元数据 | `uds_table_manage(action="create", dataset_id=..., table_name=..., task_id=...)` | 约束 5 |
| 5. 导入数据 | 先 `uds-cli --task-id <task_id> validate file.csv --table uds_{dataset_id}.表名` 预检（列名/类型匹配，不写入数据），通过后 `uds-cli --task-id <task_id> import file.csv --table uds_{dataset_id}.表名 --mode full_replace` | 只收 CSV/NDJSON；源文件是 xlsx 时先 pandas 读真实值转 CSV |
| 6. 质量检查 | `uds-cli --task-id <task_id> exec "SELECT COUNT(*) FROM uds_{dataset_id}.表名"` 检查行数、空值、重复 | upsert 需执行两次以验证幂等性 |
| 7. 反读列定义 | `uds-cli --task-id <task_id> inspect --table uds_{dataset_id}.表名` → 取 target_columns | 禁止凭空编造 |
| 8. 确认更新模式 | 询问用户：append / full_replace / upsert？后续手动上传更新还是定时拉取？ | |
| 9. 写更新脚本 | 按 SKILL.md 4.3 的脚本入口约定与 scheduled-sync-guide.md 的脚本规范写脚本（upload 源 `transform` / script 源 `fetch`），`uds-cli --task-id <task_id> upload 脚本.py --dataset ... --type script` → 获取 workspace_path | **必做**：脚本必须复刻本表建表时的全部清洗动作（步骤 1-5 中确认过的类型转换/列名规范化/衍生列）；非显而易见的清洗动作同步 `uds_rule_manage(create, rule_type="cleaning")` 落库（业务口径事实源）。跨会话修脚本用 `uds-cli download-script <script_file> --dataset ...` 获取下载 URL、curl 下载后修改 |
| 10. 生成模板文件 | upload 源表必做：生成 xlsx 模板（规范见 data-quality-guide 4.2/4.3），`uds-cli upload 模板.xlsx --dataset ... --type sample` → 获取 workspace_path | 用户原始文件干净时可直接将其以 `--type sample` 上传登记为样例 |
| 11. 完善配置 | `uds_table_manage(action="update", update_mode=..., target_columns=..., sources=[{type: upload, entry: transform}]或[{type: script, entry: fetch, schedule: ...}], script_file=..., sample_file=..., task_id=<task_id>)` | **强制脚本契约**：upload/script 源必须有 script_file；upload 源还必须有 sample_file，缺一注册被拒 |

**upsert 幂等性验证**（update_mode=upsert 时必做）：

步骤 5 首次导入成功后，用同样的数据再执行一次导入，然后检查：
1. `SELECT COUNT(*)` — 行数应与首次一致（无重复行）
2. `SELECT ... GROUP BY <upsert_keys> HAVING COUNT(*) > 1` — 应为空（主键无重复）
3. 行数翻倍或主键重复 → 修复 `--upsert-keys` 配置后重新从步骤 5 开始

---

## 7. 整体校验清单

所有表构建完成后，做跨表级别的质量检查和业务验证：

- **表存在性**：`uds-cli --task-id <task_id> tables --schema uds_{dataset_id}` 确认所有预期表已创建
- **行数验证**：每张表 `SELECT COUNT(*)` 与导入时的 rows_inserted 比对
- **关键列空值**：主键列、业务核心列不应有空值
- **关联完整性**（多表场景）：关系列引用的 ID 在关联表中存在（逻辑关系校验，数据集禁物理外键）
- **业务逻辑合理性**：金额 >= 0、日期在合理范围内、枚举值在预期集合内
- **业务查询验证**：写 2-3 条典型业务查询，向用户展示结果确认

任何问题暂停操作，由用户决策（约束 4）。

---

## 8. 产出物沉淀步骤

按顺序执行，任何一步失败都按约束 6 如实汇报：

1. **表间关系**：`uds_relations_set(action="replace", relations=[...], task_id=<task_id>)`
2. **治理规则补录**：回顾访谈，补齐未落库的规则（正常应为空，已实时落库）
3. **使用指南**：`uds_dataset_manage(action="update", tool_usage_guide="...", task_id=<task_id>)`（约束 5）。内容包含：数据集业务背景、核心表说明、关键业务口径、常用查询入口
4. **权限策略**（可选）：询问用户是否需要分表/分列/分行的细粒度分享控制
5. **自查清单**：每张表有 dataset_table 记录且 target_columns 非空？tool_usage_guide 有实质内容？关系/规则引用的 table_name 都存在？有不通过项按约束 6 汇报

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
| 脚本逻辑受影响 | 修改脚本 → `uds-cli --task-id <task_id> upload --type script` 重新上传 → `uds_table_manage(update, script_file=..., task_id=<task_id>)` |
| upload 表结构变了 | 重新生成模板文件 → `uds-cli upload --type sample` → `uds_table_manage(update, sample_file=..., task_id=<task_id>)` |
| 删列/改列名且该表有权限策略 | `uds_policy_manage(action="update", task_id=<task_id>)` 更新 row_filters/column_rules 中引用的列，否则策略 View 失效 |
