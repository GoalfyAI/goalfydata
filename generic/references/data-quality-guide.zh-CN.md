# GoalfyData 通用数据集数据质量指南

> 本文档是 SKILL.md 的补充参考，承载「脏数据判定 / 建表前校验 / 模板重传 / 幂等验证」。逐表构建的入口必做数据质量检测，按本指南分流。

---

## 1. 脏数据分类：按处置能力分两类

**类别 A — 可自动修复**（经用户确认后程序化修复）

包括但不限于：多层表头展平、聚合行 drop、BOM/编码、列名规范化、日期/数值类型转换、占位符归一、重复行去重、upsert 去重。

**类别 B — 无法自动修复**（转入模板重传分支，见第 4 节）

数据布局失控、单 sheet 多表头区块、语义完全无法推断的结构——无法程序化修复，**必须**引导用户重传。

类别 B 一旦判定：**立即停止本表后续所有步骤**（不进数据探查、不建表、不问更新模式），直接转模板重传分支。**禁止**"让用户选某种字段结构作为标准后继续在原脏数据上建表"——这等同绕过本约束。

---

## 2. 判定方法：机器信号 + 语义判断

### 2.1 机器可检测信号（程序判定，确定性）

- 合并单元格非空（`openpyxl ws.merged_cells`）→ 疑似多层表头
- 某行数值列 ≈ Σ 其他行（按维度 group by + sum 校验）→ 疑似聚合行
- 某列数值列 ≈ Σ 其他列（同粒度）→ 疑似聚合维度列
- 同列 dtype 不一致（数值混文本/日期混字串）→ 解析噪声
- 整列解析失败（全部无法转目标类型）→ 硬失败
- 主键列存在重复 → 需用户确认 upsert/去重

### 2.2 语义判断信号（基于前 N 行内容理解，不靠词表）

- 某行是否为"对其他行的汇总/小计/累计"
- 某列是否为其他列的聚合（结合 SUM 关系 + 列名含义联合判断）
- 空值/占位符是否承载业务含义
- 列名语义是否与数据内容一致

**禁止用硬编码关键词/具体值列表**（如 total/合计/汇总/N/A/货币符号等）做判定——关键词永远不全，且会误判业务字段（如 `total_amount` 订单总金额列本身是正常明细列）。

---

## 3. 类别 A 处置流程

核心原则：任何对数据的修改（清洗、丢弃、替换、展平、drop 聚合行等）都**必须**经用户知情 + 确认后执行。不存在"通用问题默认处理"的豁免——BOM、列名规范化、日期推断、货币符号、空值占位符均不例外。

1. **描述问题**：用业务语言说明脏点（位置、影响行数、占比、样本值）
2. **给出推荐**：列出候选处理方式，推荐方案排第一
3. **等待确认**：用户选择后才执行，不允许跳过
4. **执行修复**：按用户选择执行
5. **报告结果**：通报"清洗前 X 行 → 清洗后 Y 行"
6. **沉淀规则**：若该清洗对未来同源导入仍适用，调 `uds_rule_manage(action="create", rule_type="cleaning", task_id=<task_id>)` 落库，避免重复询问

多个脏点合并在一次提问里，每个脏点包含具体证据（影响行数、样本值、占比），**禁止**逐项分散提问。

---

## 4. 类别 B 模板重传分支

**目标**：通过模板化让用户按干净格式重传，而非直接建脏表。本分支只做模板生成和重传引导，**禁止**夹带业务访谈、更新模式、字段结构选择——这些等用户重传、新文件判定干净、进入标准闭环再处理。

### 4.1 步骤

1. **识别报告**：用业务语言把检测到的脏点告知用户（哪几行是聚合行、哪几列是多层表头、哪些列是聚合维度**禁止**参与求和、为什么直接建表会产生错误，举一个具体分析错误的例子）。本步只表达，不重复检测。
2. **确认是否接受模板**（这一步只问这一件事，不混入其他问题）：
   - 采用干净模板重传（推荐）——生成一份格式规范的 xlsx，用户按此格式填充后重新上传
   - 用户有顾虑/不想用模板 → 进入第 4 步沟通循环
3. **生成并交付模板**（用户接受时）：在用户当前工作目录生成 `<table_name>_template.xlsx`（规范见 4.2）并告知文件路径与格式要点，同时按 4.3 以 `--type sample` 上传登记为该表的 sample_file。用户按格式填充后重新上传 → 新文件重新执行数据质量检测 → 判定干净 → 进入标准闭环。
4. **沟通循环**（用户拒绝模板）：按拒绝原因调整方案，再回到第 2 步。常见顾虑应对：

   | 用户顾虑 | 应对 |
   |---|---|
   | "列太多填不完" | 精简到核心列，扩展列后续按需加；或拆多张表 |
   | "数据量大频繁填麻烦" | 写转换脚本，用户上传原格式，脚本自动转模板格式入库 |
   | "不知道哪些列该聚合" | 与用户逐列确认业务含义后重新确定模板 |
   | "原文件就是标准" | 展示具体脏点证据（行号、内容、示例分析错误）让用户确认 |
   | "模板不符合业务习惯" | 按用户习惯调整（只要满足单层表头/无聚合行即可） |

若充分沟通仍无共识：按约束 6 诚实汇报并终止流程，不建底表、不落数据集、不写任何 dataset_table 记录。

### 4.2 模板文件规范

| 项 | 规则 |
|---|---|
| 表头 | 第 1 行英文列名（snake_case，与 target_columns 一致），单层，不合并单元格 |
| 示例数据 | 表头之后 2-3 行真实业务示例值，让用户看清每列数据大致长什么样即可——不对用户做格式要求（列的业务含义已在建表 COMMENT 与治理规则中，格式宽容由 transform 脚本负责） |
| 无聚合行 | **禁止**出现对其他行的汇总/小计/累计行 |
| 列数合理 | 只保留核心列，过多时拆多张表 |

### 4.2.1 模板生成骨架（openpyxl）

在本地生成（你是本地 agent，直接写本地文件再上传）。示例行是模板的核心价值——
仅含表头的模板无法让用户理解每列该填什么，禁止只写表头。

以下是**结构骨架，并非可直接套用的成品**：`COLUMNS` 的列名/示例值按本表的
target_columns 和业务访谈结论填写，示例值使用真实业务值即可，无需做格式处理：

```python
from openpyxl import Workbook

# (列名, 示例值)：列名与 target_columns 严格一致；示例值为真实业务值
COLUMNS = [
    ("<列名1>", "<真实业务示例值>"),
    # ... 每列一行，覆盖 target_columns 全部列
]

wb = Workbook()
ws = wb.active
for col_idx, (name, _) in enumerate(COLUMNS, start=1):
    ws.cell(row=1, column=col_idx, value=name)
for row_idx in range(2, 4):  # 2-3 行示例数据
    for col_idx, (_, example) in enumerate(COLUMNS, start=1):
        ws.cell(row=row_idx, column=col_idx, value=example)
wb.save("<table_name>_template.xlsx")
```

### 4.3 模板必须上传登记（强制脚本契约的一部分）

模板不只给用户一次性下载——它是表配置的必填项 `sample_file`，网页端的"下载模板"按钮
长期从这里取文件。生成后**必须**：

```
uds-cli --task-id <task_id> upload <table>_template.xlsx --dataset <dataset_id> --type sample
uds_table_manage(action="update", table_name=..., sample_file=<返回的 workspace_path>, task_id=<task_id>)
```

- `--type sample` 不能省：落盘目录是 /workspace/goalfydata_sample_files/，表配置对
  sample_file 有路径前缀校验，目录不符登记会被拒绝；
- upload 源的表**没有 sample_file 无法完成注册**（与 script_file 同为必填）；
- 用户原始文件本身干净时，可直接将其以 `--type sample` 上传登记为样例，无需另行生成模板；
- 模板与 transform 脚本成对维护：表结构（target_columns）变更时两者都要重新生成并更新登记。

---

## 5. 建表前强制校验清单

建表（标准闭环步骤 3）之前**必须**确认：

- 选定的主键唯一（无重复且无空值）；无单列满足则检查复合键唯一性
- 每个时间语义的列，探查到的格式与 DDL 类型一致（DATE ≠ TIMESTAMP ≠ TIME）
- VARCHAR 列长度 ≥ 实测最大长度 × 1.5（留余量，避免 `value too long`）
- 有空值的列**不能**设 NOT NULL
- 含小数的数值列不用 BIGINT，用 DECIMAL（避免科学计数法导入失败）
- upsert 模式**必须**提前检查候选主键组合有无重复行（PG 同一批次**不能** upsert 同一行两次，有重复需在脚本 `drop_duplicates`）
- 数值列的实际范围决定 INTEGER vs BIGINT vs DECIMAL
- DDL 中**不含** `FOREIGN KEY` / `REFERENCES`（数据集 schema 禁外键，服务端拦截；表间关系用 `uds_relations_set` 登记，不建物理外键）

---

## 6. upsert 幂等性验证

`update_mode=upsert` 时必做。首次导入成功后，用同样的数据再导一次，然后检查：

1. `SELECT COUNT(*) FROM uds_{dataset_id}.<table>` — 行数应与首次一致（无重复行）
2. `SELECT COUNT(*) FROM uds_{dataset_id}.<table> GROUP BY <upsert_keys> HAVING COUNT(*) > 1` — 结果应为空（主键无重复）
3. 若行数翻倍或主键重复 → 脚本 `drop_duplicates` 或 `--upsert-keys` 有问题，修复后重新导入

`append` 模式不做幂等测试（天然增加行数）。`full_replace` 执行两次行数应一致（第二次替换第一次）。

---

## 7. 跨表整体校验

所有表构建完成后，做跨表级别的质量检查和业务验证。任何问题暂停操作，由用户决策（约束 4：不替用户做业务决策）。

### 7.1 表存在性

确认所有预期表已创建，没有遗漏：

```bash
uds-cli --task-id <task_id> tables --schema uds_{dataset_id}
```

将输出的表列表与访谈确定的建表清单逐一比对。缺表则回溯排查原因（建表失败 / 漏建 / 表名拼写错误）。

### 7.2 行数验证

每张表的实际行数应与导入时 `rows_inserted` 一致：

```sql
-- 逐表检查
SELECT COUNT(*) FROM uds_{dataset_id}.orders;
SELECT COUNT(*) FROM uds_{dataset_id}.order_items;
SELECT COUNT(*) FROM uds_{dataset_id}.customers;
```

与导入日志中的 `rows_inserted` 比对。若不一致，排查原因：
- 行数偏少：可能导入时有解析失败的行（编码 / 类型不匹配）
- 行数偏多：可能重复导入且未使用 `full_replace`
- 行数为 0：导入命令可能静默失败，检查 task 日志

### 7.3 关键列空值

主键列、业务核心列不应有空值：

```sql
-- 主键列空值检查（应返回 0）
SELECT COUNT(*) FROM uds_{dataset_id}.orders WHERE order_id IS NULL;
SELECT COUNT(*) FROM uds_{dataset_id}.order_items WHERE item_id IS NULL;

-- 业务核心列空值检查
SELECT COUNT(*) FROM uds_{dataset_id}.orders WHERE customer_id IS NULL;
SELECT COUNT(*) FROM uds_{dataset_id}.order_items WHERE order_id IS NULL;
```

返回值应为 0。若非 0，需判断：
- 主键列有空值 → 数据源问题，必须修复（回退到标准闭环清洗或模板重传）
- 业务列有空值 → 与用户确认是否属于正常业务场景（如可选字段允许空值）

### 7.4 关联完整性（多表场景）

关系列引用的 ID 在关联表中必须存在（逻辑关系校验，数据集禁物理外键），否则说明数据不完整或关联关系配置错误：

```sql
-- 订单明细的 order_id 必须在订单主表中存在（应返回 0 行）
SELECT a.order_id
FROM uds_{dataset_id}.order_items a
LEFT JOIN uds_{dataset_id}.orders b ON a.order_id = b.order_id
WHERE b.order_id IS NULL;

-- 订单的 customer_id 必须在客户表中存在（应返回 0 行）
SELECT a.customer_id
FROM uds_{dataset_id}.orders a
LEFT JOIN uds_{dataset_id}.customers b ON a.customer_id = b.customer_id
WHERE b.customer_id IS NULL;
```

若有孤立记录（返回非空结果），与用户确认：
- 是否源数据缺失（部分关联数据未提供）→ 补传数据
- 是否关联字段不对（列名 / 含义理解有误）→ 修正关系配置

### 7.5 业务逻辑合理性

根据业务语义做基本的合理性校验：

**金额类字段**：

```sql
-- 金额不应为负数（特殊业务如退款除外，需与用户确认）
SELECT COUNT(*) FROM uds_{dataset_id}.orders WHERE total_amount < 0;
SELECT COUNT(*) FROM uds_{dataset_id}.order_items WHERE unit_price < 0;
```

**日期类字段**：

```sql
-- 检查日期范围是否在合理区间内
SELECT MIN(order_date), MAX(order_date) FROM uds_{dataset_id}.orders;
```

验证最小 / 最大日期是否在预期范围内。若出现 `1970-01-01`、`2099-12-31` 等异常值，说明可能存在默认值污染或解析错误。

**枚举类字段**：

```sql
-- 检查枚举值是否在预期集合内
SELECT DISTINCT status FROM uds_{dataset_id}.orders;
SELECT DISTINCT payment_method FROM uds_{dataset_id}.orders;
```

将结果与业务预期的枚举值集合比对。出现未知值时与用户确认是新增的合法值还是脏数据。

### 7.6 业务查询验证

写 2-3 条典型业务查询，向用户展示结果，确认数据能支撑实际业务分析：

```sql
-- 示例 1：按月统计订单量和总金额
SELECT
    DATE_TRUNC('month', order_date) AS month,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_revenue
FROM uds_{dataset_id}.orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

-- 示例 2：客户维度的订单汇总（验证多表关联正确性）
SELECT
    c.customer_name,
    COUNT(o.order_id) AS order_count,
    SUM(o.total_amount) AS total_spent
FROM uds_{dataset_id}.customers c
LEFT JOIN uds_{dataset_id}.orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name
ORDER BY total_spent DESC
LIMIT 10;

-- 示例 3：订单明细金额与订单总额交叉验证
SELECT
    o.order_id,
    o.total_amount AS order_total,
    SUM(oi.unit_price * oi.quantity) AS calculated_total
FROM uds_{dataset_id}.orders o
JOIN uds_{dataset_id}.order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.total_amount
HAVING ABS(o.total_amount - SUM(oi.unit_price * oi.quantity)) > 0.01
LIMIT 10;
```

将查询结果展示给用户，让用户确认数据是否符合业务预期。若用户发现异常（如某月数据缺失、金额不对），回溯排查并修复。
