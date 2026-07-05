# GoalfyData 通用数据集定时同步配置指南

> 本文档是 SKILL.md 的补充参考。提供外部数据源脚本模板、transform 脚本规范、更新模式原理、多表协同策略。
>
> SKILL.md 已包含完整的脚本签名、最小可运行示例、配置流程和沙箱约束。本文档聚焦于 SKILL.md 未覆盖的数据源模板和高级场景。

---

## 1. 更新模式与原子性

### full_replace（全量替换）

最常用的定时同步模式。Dispatcher 自动处理原子换表：
1. 预建临时表（克隆正式表结构）
2. 脚本通过 `uds-cli import` 写入临时表（脚本收到的 `table_name` 已指向临时表，直接写即可）
3. 回调成功 → RENAME 临时表为正式表（瞬间完成）
4. 回调失败 → DROP 临时表，正式表不受影响

用户在更新期间查询正式表看到的是旧数据，RENAME 瞬间切到新数据，不会出现空表中间态。脚本**不需要手动 TRUNCATE 或清空表**。

### append（追加）

直接写入正式表，不建临时表。适合日志、事件流等只增不改的场景。

### upsert（按主键更新或插入）

直接写入正式表，PG 层面 `ON CONFLICT (主键) DO UPDATE`。适合增量同步。主键列在 `uds_table_manage` 的 `primary_key` 字段定义，`uds-cli import` 通过 `--upsert-keys` 指定。

---

## 2. transform 脚本（upload 源）

upload 模式的入口函数是 `transform`（不是 `fetch`）。用户在前端上传文件或通过 `uds_sync_task(source_type="upload", task_id=<task_id>)` 触发时执行。

**upload 表必须编写并登记 transform 脚本**（`uds-cli upload 脚本.py --type script` → `uds_table_manage(update, script_file=...)`），无脚本的表无法接收上传。标准模板见 SKILL.md 4.3 节（pandas 类型化读取 + 按 target_columns 清洗 + 面向用户的可读报错，语言与用户一致），在标准模板基础上叠加本表的定制清洗：

**标准模板全文**（与 SKILL.md 4.3 同一份，勿分叉；在此基础上叠加本表的定制清洗——
列名映射、衍生列、单位换算等写在"列名规范化"与"类型规范化"之间）：

```python
import gc, json, os, subprocess, tempfile
import pandas as pd

# 业务工单 id：写脚本时替换为建表会话的 task_id，之后固定不变——
# 用户每次前端上传只产生 syn_* 同步执行实例（平台自动生成，与业务工单是两个概念），
# 脚本内 uds-cli 的操作埋点统一挂在建表工单下
TASK_ID = "tk_xxxxxxxx"

# CSV 分块行数：沙箱内存有限（约 4C8G），CSV 无行数上限必须分块；
# xlsx 受 Excel 行数上限（1,048,576）约束，整档读取内存可控
CHUNK_ROWS = 50_000

def transform(file_path, filename, table_name, update_mode, target_columns, **kwargs):
    """类型化读取用户文件 -> 逐块清洗 -> 规范 CSV -> uds-cli import。"""
    try:
        pk = [c["name"] for c in target_columns if c.get("primary_key")]
        if filename.lower().endswith((".xlsx", ".xls")):
            # xlsx 读单元格真实值（日期是 datetime、数字是数值，不受显示格式影响）
            df = pd.read_excel(file_path)
            err = _clean_and_import(df, table_name, update_mode, target_columns, pk, first_chunk=True)
            if err:
                return err
            return {"success": True, "rows_inserted": int(len(df))}
        # CSV 全文本分块读取（chunksize 保持全局行号连续，报错行号可直接使用）
        total = 0
        first_chunk = True
        for df in pd.read_csv(file_path, dtype=str, keep_default_na=False, chunksize=CHUNK_ROWS):
            err = _clean_and_import(df, table_name, update_mode, target_columns, pk, first_chunk)
            if err:
                return err
            total += int(len(df))
            first_chunk = False
            del df
            gc.collect()
        return {"success": True, "rows_inserted": total}
    except (pd.errors.ParserError, UnicodeDecodeError, KeyError, ValueError) as e:
        return {"success": False, "error_code": "USER_FILE", "rows_inserted": 0,
                "error": "文件解析失败: %s，请检查文件格式" % e}
    except Exception as e:
        return {"success": False, "error_code": "SCRIPT", "rows_inserted": 0,
                "error": "脚本异常: %s" % e}

def _clean_and_import(df, table_name, update_mode, target_columns, pk, first_chunk):
    """清洗一个分块并导入。成功返回 None，失败返回结果 dict（调用方直接透传）。
    分块模式语义：full_replace 仅首块（后续块 append），append/upsert 每块保持原模式。"""
    # 列名规范化：strip、小写、分隔符归一
    df.columns = ["_".join(str(c).strip().lower().split()).replace("-", "_") for c in df.columns]

    # <-- 本表的定制清洗写在这里：列名映射、衍生列、单位换算、占位符归一等（勿 reset_index，保持全局行号） -->

    col_types = {c["name"]: c.get("type", "") for c in target_columns}
    missing = [n for n in col_types if n not in df.columns]
    if missing:
        return {"success": False, "error_code": "USER_FILE", "rows_inserted": 0,
                "error": "文件缺少必需列: %s，请对照模板检查表头" % ", ".join(missing)}
    df = df[[n for n in col_types if n in df.columns]]

    for name, ctype in col_types.items():
        if ctype in ("date", "timestamp", "timestamptz"):
            parsed = pd.to_datetime(df[name], errors="coerce")
            bad = df[name].notna() & (df[name].astype(str).str.strip() != "") & parsed.isna()
            if bad.any():
                row = int(bad.idxmax()) + 2  # chunksize 保持全局索引，+2 = 表头一行 + 1 起始行号
                return {"success": False, "error_code": "USER_FILE", "rows_inserted": 0,
                        "error": "第 %d 行「%s」列的值 %r 无法识别为日期，请使用 YYYY-MM-DD 格式"
                                 % (row, name, str(df[name][bad.idxmax()]))}
            fmt = "%Y-%m-%d" if ctype == "date" else "%Y-%m-%d %H:%M:%S"
            df[name] = parsed.dt.strftime(fmt)
        elif ctype in ("integer", "bigint"):
            # 可空整型 Int64：避免含空值时整列变 float、写出 "123.0" 导致 int 列入库失败
            cleaned = df[name].astype(str).str.replace(",", "", regex=False).str.strip()
            df[name] = pd.to_numeric(cleaned, errors="coerce").astype("Int64")
        elif ctype in ("numeric", "double precision"):
            cleaned = df[name].astype(str).str.replace(",", "", regex=False).str.strip()
            df[name] = pd.to_numeric(cleaned, errors="coerce")

    cmd_extra = []
    if update_mode == "upsert" and pk:
        df = df.drop_duplicates(subset=pk, keep="last")  # 跨块同主键由 upsert 语义覆盖（后块覆盖前块）
        cmd_extra = ["--upsert-keys", ",".join(pk)]
    mode = update_mode if (first_chunk or update_mode == "upsert") else "append"

    fd, tmp_csv = tempfile.mkstemp(suffix=".csv", dir="/workspace")
    os.close(fd)
    try:
        df.to_csv(tmp_csv, index=False)
        r = subprocess.run(["uds-cli", "--task-id", TASK_ID, "import", "--format", "json",
                            "--table", table_name, "--mode", mode, tmp_csv] + cmd_extra,
                           capture_output=True, text=True)
        if r.returncode != 0:
            code = "SCRIPT"
            for marker in ("ROW_LIMIT_EXCEEDED", "TABLE_LIMIT_EXCEEDED",
                           "STORAGE_QUOTA_EXCEEDED", "DATASET_LIMIT"):
                if marker in r.stderr:
                    code = marker
                    break
            err = r.stderr[:500].strip() or ("uds-cli import exited with code %d" % r.returncode)
            return {"success": False, "error_code": code, "error": err, "rows_inserted": 0}
        return None
    finally:
        if os.path.exists(tmp_csv):
            os.remove(tmp_csv)
```

| 对比 | fetch（script 源） | transform（upload 源） |
|---|---|---|
| 入口函数 | `fetch(table_name, update_mode, target_columns, **kwargs)` | `transform(file_path, filename, table_name, update_mode, target_columns, **kwargs)` |
| 数据来源 | 脚本自行拉取（API / 数据库） | `file_path` 参数指向已上传的文件 |
| 默认脚本 | 无，**必须**编写 | 无，**必须**编写（另需登记 sample_file 模板） |

---

## 3. 数据源脚本模板

以下模板均为 `fetch` 入口的自定义区域。通用规则：
- 源库只读，**禁止**写入
- 分块读取（CHUNK_SIZE 约 5000），逐块写 CSV → `uds-cli import`，每块 `del df; gc.collect()`
- 连接用 `try/finally` 确保释放
- 凭证从 `os.environ` 读取（通过 `uds_credential_store` 存储）
- 增量同步配合 `update_mode=upsert`，用时间戳或自增 ID 做增量起点
- upsert 模式：每块 import 都必须带 `--upsert-keys`（从 target_columns 取 primary_key，参考 3.1 模板），且每块都用 `--mode upsert`，不能改用 append

### 3.1 外部 MySQL 拉取

前置：沙箱首次运行前 `pip install pymysql`（快照保留，后续无需重装）。

凭证配置：
```
uds_credential_store(action="store", credential_name="MYSQL_HOST", credential_value="rm-xxx.mysql.rds.aliyuncs.com", task_id=<task_id>)
uds_credential_store(action="store", credential_name="MYSQL_PASSWORD", credential_value="P@ssw0rd", task_id=<task_id>)
```

```python
TASK_ID = "tk_xxxxxxxx"  # Agent 写脚本时替换为当前会话的 task_id

def fetch(table_name, update_mode, target_columns, **kwargs):
    import os, subprocess, gc
    import pymysql
    import pandas as pd

    host = os.environ.get("MYSQL_HOST", "")
    password = os.environ.get("MYSQL_PASSWORD", "")
    conn = pymysql.connect(host=host, user="readonly", password=password,
                           database="source_db", charset="utf8mb4",
                           cursorclass=pymysql.cursors.SSDictCursor)
    try:
        CHUNK_SIZE = 5000
        total_rows = 0
        upsert_keys = [c["name"] for c in target_columns if c.get("primary_key")]

        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM source_orders ORDER BY id")
            while True:
                rows = cursor.fetchmany(CHUNK_SIZE)
                if not rows:
                    break
                df = pd.DataFrame(rows)
                # 清洗：camelCase → snake_case
                df = df.rename(columns={"orderId": "order_id", "createdAt": "created_at"})

                os.makedirs("/workspace/tmp", exist_ok=True)
                tmp_csv = f"/workspace/tmp/chunk_{table_name.split('.')[-1]}.csv"
                df.to_csv(tmp_csv, index=False)
                chunk_rows = int(len(df))
                del df; gc.collect()

                mode = update_mode if update_mode == "upsert" else ("append" if total_rows > 0 else update_mode)  # upsert 每块保持 upsert，避免 append 导致主键冲突
                cmd = ["uds-cli", "--task-id", TASK_ID, "import", tmp_csv, "--table", table_name, "--mode", mode]
                if update_mode == "upsert" and upsert_keys:
                    cmd += ["--upsert-keys", ",".join(upsert_keys)]
                r = subprocess.run(cmd, capture_output=True, text=True)
                os.remove(tmp_csv)
                if r.returncode != 0:
                    return {"success": False, "error_code": "SCRIPT", "error": r.stderr, "rows_inserted": total_rows}
                total_rows += chunk_rows

        return {"success": True, "rows_inserted": total_rows}
    except Exception as e:
        return {"success": False, "error_code": "SCRIPT", "error": str(e), "rows_inserted": 0}
    finally:
        conn.close()
```

**增量同步变体**：查目标表最大时间戳，只拉增量数据：

```python
# 在 fetch 函数开头加：
r0 = subprocess.run(["uds-cli", "--task-id", TASK_ID, "exec", f"SELECT MAX(updated_at) FROM {table_name}", "--format", "csv"],
                    capture_output=True, text=True)
max_ts = None
if r0.returncode == 0:
    lines = r0.stdout.strip().split("\n")
    if len(lines) > 1 and lines[-1].strip() != "":
        max_ts = lines[-1].strip()

# cursor.execute 改为：
if max_ts:
    cursor.execute("SELECT * FROM source_orders WHERE updated_at > %s ORDER BY id", (max_ts,))
else:
    cursor.execute("SELECT * FROM source_orders ORDER BY id")
```

### 3.2 REST API 分页拉取

```python
TASK_ID = "tk_xxxxxxxx"  # Agent 写脚本时替换为当前会话的 task_id

def fetch(table_name, update_mode, target_columns, **kwargs):
    import os, subprocess, json, csv, gc
    import urllib.request

    api_key = os.environ.get("API_KEY", "")
    base_url = "https://api.example.com/v1/orders"
    PAGE_SIZE = 500
    total_rows = 0
    page = 1

    while True:
        url = f"{base_url}?page={page}&per_page={PAGE_SIZE}"
        req = urllib.request.Request(url, headers={
            "Authorization": f"Bearer {api_key}",
            "User-Agent": "uds-sync/1.0",
        })
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read())

        items = data.get("items") or data.get("data") or []
        if not items:
            break

        # 逐页写 CSV → import（不在内存中累积）
        os.makedirs("/workspace/tmp", exist_ok=True)
        tmp_csv = f"/workspace/tmp/page_{table_name.split('.')[-1]}.csv"
        with open(tmp_csv, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=[c["name"] for c in target_columns])
            writer.writeheader()
            for item in items:
                writer.writerow({c["name"]: item.get(c["name"], "") for c in target_columns})

        chunk_rows = len(items)
        mode = update_mode if update_mode == "upsert" else ("append" if total_rows > 0 else update_mode)  # upsert 每块保持 upsert，避免 append 导致主键冲突
        r = subprocess.run(["uds-cli", "--task-id", TASK_ID, "import", tmp_csv, "--table", table_name, "--mode", mode],
                           capture_output=True, text=True)
        os.remove(tmp_csv)
        if r.returncode != 0:
            return {"success": False, "error_code": "SCRIPT", "error": r.stderr, "rows_inserted": total_rows}
        total_rows += chunk_rows

        if len(items) < PAGE_SIZE:
            break
        page += 1

    return {"success": True, "rows_inserted": total_rows}
```

### 3.3 外部 PostgreSQL 拉取

前置：`pip install psycopg2-binary`

```python
TASK_ID = "tk_xxxxxxxx"  # Agent 写脚本时替换为当前会话的 task_id

def fetch(table_name, update_mode, target_columns, **kwargs):
    import os, subprocess, gc
    import psycopg2
    import psycopg2.extras
    import pandas as pd

    conn = psycopg2.connect(
        host=os.environ.get("PG_HOST", ""),
        port=int(os.environ.get("PG_PORT", "5432")),
        user=os.environ.get("PG_USER", ""),
        password=os.environ.get("PG_PASSWORD", ""),
        database=os.environ.get("PG_DATABASE", ""),
    )
    try:
        CHUNK_SIZE = 5000
        total_rows = 0

        with conn.cursor(name="uds_fetch", cursor_factory=psycopg2.extras.RealDictCursor) as cursor:
            cursor.itersize = CHUNK_SIZE
            cursor.execute("SELECT * FROM source_table ORDER BY id")
            while True:
                rows = cursor.fetchmany(CHUNK_SIZE)
                if not rows:
                    break
                df = pd.DataFrame(rows)
                os.makedirs("/workspace/tmp", exist_ok=True)
                tmp_csv = f"/workspace/tmp/chunk_{table_name.split('.')[-1]}.csv"
                df.to_csv(tmp_csv, index=False)
                chunk_rows = int(len(df))
                del df; gc.collect()

                mode = update_mode if update_mode == "upsert" else ("append" if total_rows > 0 else update_mode)  # upsert 每块保持 upsert，避免 append 导致主键冲突
                r = subprocess.run(["uds-cli", "--task-id", TASK_ID, "import", tmp_csv, "--table", table_name, "--mode", mode],
                                   capture_output=True, text=True)
                os.remove(tmp_csv)
                if r.returncode != 0:
                    return {"success": False, "error_code": "SCRIPT", "error": r.stderr, "rows_inserted": total_rows}
                total_rows += chunk_rows

        return {"success": True, "rows_inserted": total_rows}
    except Exception as e:
        return {"success": False, "error_code": "SCRIPT", "error": str(e), "rows_inserted": 0}
    finally:
        conn.close()
```

### 3.4 MongoDB 拉取

前置：`pip install pymongo`

```python
TASK_ID = "tk_xxxxxxxx"  # Agent 写脚本时替换为当前会话的 task_id

def fetch(table_name, update_mode, target_columns, **kwargs):
    import os, subprocess, gc
    import pandas as pd
    from pymongo import MongoClient

    uri = os.environ.get("MONGO_URI", "")
    client = MongoClient(uri, serverSelectionTimeoutMS=10000)
    try:
        db = client[os.environ.get("MONGO_DB", "production")]
        collection = db[os.environ.get("MONGO_COLLECTION", "orders")]

        CHUNK_SIZE = 5000
        total_rows = 0
        skip = 0

        while True:
            docs = list(collection.find({}, {"_id": 0}).sort("_id", 1).skip(skip).limit(CHUNK_SIZE))
            if not docs:
                break
            df = pd.DataFrame(docs)
            os.makedirs("/workspace/tmp", exist_ok=True)
            tmp_csv = f"/workspace/tmp/chunk_{table_name.split('.')[-1]}.csv"
            df.to_csv(tmp_csv, index=False)
            chunk_rows = int(len(df))
            del df; gc.collect()

            mode = update_mode if update_mode == "upsert" else ("append" if total_rows > 0 else update_mode)  # upsert 每块保持 upsert，避免 append 导致主键冲突
            r = subprocess.run(["uds-cli", "--task-id", TASK_ID, "import", tmp_csv, "--table", table_name, "--mode", mode],
                               capture_output=True, text=True)
            os.remove(tmp_csv)
            if r.returncode != 0:
                return {"success": False, "error_code": "SCRIPT", "error": r.stderr, "rows_inserted": total_rows}
            total_rows += chunk_rows
            skip += CHUNK_SIZE

        return {"success": True, "rows_inserted": total_rows}
    except Exception as e:
        return {"success": False, "error_code": "SCRIPT", "error": str(e), "rows_inserted": 0}
    finally:
        client.close()
```

### 3.5 跨数据集 SQL 聚合（不读文件）

适用于从其他数据集的表聚合数据到当前表（如汇总表、宽表）。

```python
TASK_ID = "tk_xxxxxxxx"  # Agent 写脚本时替换为当前会话的 task_id

def fetch(table_name, update_mode, target_columns, **kwargs):
    import subprocess

    # 跨 schema 聚合 SQL（源表用全限定名）
    agg_sql = """
    INSERT INTO {table} (date, region, total_orders, total_gmv)
    SELECT
        date,
        region,
        COUNT(*) AS total_orders,
        SUM(amount) AS total_gmv
    FROM uds_source1uid.orders
    GROUP BY date, region
    """.format(table=table_name)

    # full_replace 模式下 table_name 已指向临时表，直接写即可，不需要手动 TRUNCATE
    r = subprocess.run(["uds-cli", "--task-id", TASK_ID, "exec", agg_sql, "--mode", "writer"],
                       capture_output=True, text=True)
    if r.returncode != 0:
        return {"success": False, "error_code": "SCRIPT", "error": r.stderr, "rows_inserted": 0}

    # 查行数
    r2 = subprocess.run(["uds-cli", "--task-id", TASK_ID, "exec", f"SELECT COUNT(*) FROM {table_name}", "--format", "csv"],
                        capture_output=True, text=True)
    rows = 0
    if r2.returncode == 0:
        lines = r2.stdout.strip().split("\n")
        if len(lines) > 1:
            try:
                rows = int(lines[-1].strip())
            except ValueError:
                pass

    return {"success": True, "rows_inserted": rows}
```

---

## 4. 多表协同

### 同步顺序

同一数据集的多张表可能有依赖关系（如先同步维表，再同步事实表）。通过 `sync_order` 控制：

```
uds_table_manage(action="update", table_name="dim_products", sync_order=10, task_id=<task_id>)    # 维表先执行
uds_table_manage(action="update", table_name="fact_orders", sync_order=100, task_id=<task_id>)    # 事实表后执行
```

数字小的先执行。未设置时默认 100。

### 共享沙箱排错

同一数据集、同一 schedule 的多张表在共享沙箱中串行执行。当某张表单独执行正常但共享组内反复失败时，通常是前序表的脚本污染了沙箱环境。

典型错误模式（查 `uds_sync_logs` 的 error_message）：

| 错误信息 | 可能原因 |
|----------|----------|
| `FileNotFoundError` | 前序表脚本调用了 `os.chdir()` 更改了工作目录 |
| `KeyError: 'XXX_ENV'` | 前序表脚本修改了 `os.environ` 且未还原 |
| `ModuleNotFoundError` | 前序表脚本污染了 `sys.path` |
| `Connection already closed` | 前序表脚本持有连接未释放 |

排错步骤：
1. 确认单表执行正常：对比 `uds_sync_logs` 中该表的历史成功记录
2. 定位同 schedule 的其他表脚本，找违反沙箱共享规约的代码
3. 修正污染源脚本（修一个救整组）
4. 确实无法修正 → 为污染源表设 `exclusive_sandbox=true` 隔离

---

## 5. 失败通知配置（可选）

定时任务在无人值守时可能失败。通过 `uds_notify_config` 配置告警渠道：

```
uds_notify_config(
    action="create",
    dataset_id="dataset_id",
    channel="dingtalk",
    config={...},
    notify_on=["failed"],
    task_id=<task_id>
)
```

支持的渠道：webhook / dingtalk / feishu / telegram / whatsapp / email。

配置后，定时同步失败时自动推送到对应渠道。

---

## 6. 同步验证完整流程

构建阶段通过 `uds-cli import` 直接导入数据，验证的是数据正确性（列匹配、类型兼容、业务逻辑合理）。验证阶段通过 `uds_sync_task` 经由完整的异步同步链路（上传 → 沙箱执行 → 回调 → 原子写入），验证生产链路可正常运行。**配置了定时同步的表必须执行同步验证，否则定时任务可能配置完成却无法运行。**

### 6.1 触发 sync task

对每张配置了 sources 的表，按 source 类型触发验证：

前置契约（强制脚本，任何触发路径都一样）：表必须已登记 script_file（upload 源还需
sources=[{type: upload, entry: transform}] + sample_file），否则触发被拒（`SCRIPT_NOT_CONFIGURED`）。
脚本一律 `uds-cli upload 脚本.py --type script` 上传（落 /workspace/goalfydata_dataset_scripts/，
不带 --type 会落数据目录、被表配置的路径前缀校验拒绝）。

**upload 源的表**（验证「用户上传 → transform 清洗 → 入库」全链路；脚本与模板已在建表时登记）：
```
uds-cli --task-id <task_id> upload data.csv --dataset dataset_id → 获取 workspace_path（--type 默认 data）
uds_sync_task(action="run", source_type="upload", file_paths=[workspace_path], table_name=..., import_mode=..., task_id=<task_id>)
→ 返回 group_id → 轮询 uds_sync_task(action="status", group_id=..., task_id=<task_id>) 直到终态
```

**script 源的表**（验证脚本执行链路；脚本已在建表时登记，改过脚本才需要重新上传+更新配置）：
```
（若修改了脚本）uds-cli --task-id <task_id> upload fetch_script.py --dataset dataset_id --type script → 获取 workspace_path
（若修改了脚本）uds_table_manage(action="update", script_file=workspace_path, sources=[...], task_id=<task_id>)
uds_sync_task(action="run", source_type="script", table_name=..., import_mode=..., task_id=<task_id>)
→ 返回 group_id → 轮询 status 直到终态
```

轮询间隔建议：数据量 < 1 万行等 30 秒，1-10 万行等 60 秒，10 万行以上等 180 秒。

### 6.2 失败处理与重试

前置：先用 `uds_sync_logs(dataset_id=..., status="failed", task_id=<task_id>)` 查看近期失败记录。每条记录含 `error_code`、`error_message`、`log_url`、`started_at`。

先对比最近 error 的 `started_at` 和表配置的最后更新时间——error 早于配置修改时间说明是历史遗留，告知用户等待下一轮验证，无需修改脚本。

| 状态/情况 | 处理 |
|------|------|
| `success` | 该表验证通过，继续下一张 |
| `failed` + `USER_FILE` | 文件格式不匹配。对比 target_columns 告知用户差异，让用户修正文件后重新上传触发 |
| `failed` + `SCRIPT` | 脚本异常。查看 `error_message` 和 `log_url` 定位问题 → 修复脚本 → `uds-cli --task-id <task_id> upload --type script` 重新上传 → `uds_table_manage(update, script_file=..., task_id=<task_id>)` 更新配置 → `uds_sync_task(action="run", task_id=<task_id>)` 重新触发验证 |
| `failed` + `SCRIPT_NOT_CONFIGURED` | 表未登记更新脚本（注册未完成）。按 SKILL.md Step 2.1 步骤 9-11 补齐：写 transform 脚本 + 生成模板 → `uds-cli upload --type script` / `--type sample` → `uds_table_manage(update, script_file=..., sample_file=..., sources=[{type: upload, entry: transform}])`，完成后重试 |
| `failed` + `INFRA` | 系统异常。告知用户，建议稍后重试 |
| 任务长时间处于 `running` 状态未结束 | 脚本崩溃未正常返回。僵尸巡检会在 70 分钟后自动置为 failed。通过 `log_url` 查看完整执行日志定位问题 |
| `failed` + `ROW_LIMIT_EXCEEDED` | 导入行数超过 max_rows_per_table 上限。向用户说明并提供选项：改用 full_replace / 清理旧数据 / 按维度拆表（当前单表上限 2000 万行，暂不支持调整）。禁止自行截断数据 |
| `failed` + `GROUP_ABORTED` | 多文件 upload 中前序文件失败，后续文件被中止。先修复失败的文件，再整组重新触发 |

### 6.3 修复后重试流程

```
修复问题（修改脚本或数据文件）
  → 若修改了脚本：uds-cli --task-id <task_id> upload --type script 重新上传 + uds_table_manage(update, script_file=..., task_id=<task_id>) 同步配置
  → uds_sync_task(action="run", task_id=<task_id>) 重新触发
  → 轮询 status 直到通过
```

### 6.4 最终汇报

所有表验证通过后，按「已完成 / 部分完成 / 未完成」三段式汇报。

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
