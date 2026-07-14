# GoalfyData Managed Refresh Configuration Guide

> This document is the single source of truth for GoalfyData Managed Refresh scripts: script spec essentials, the fetch standard template, cross-session maintenance, sandbox rules, external data-source templates, and multi-table coordination all live here.
>
> SKILL.md keeps only the script entry signatures, parameter table, return-value contract, and configuration flow; read this document before writing or modifying any update script.

---

## 1. Update Modes and Atomicity

### full_replace

The most common GoalfyData Managed Refresh mode. The dispatcher handles the atomic table swap automatically:
1. Pre-creates a temporary table (cloning the production table's structure)
2. The script writes into the temporary table via `uds-cli import` (the `table_name` the script receives already points at the temp table — just write)
3. Callback succeeds → RENAME the temp table to production (instant)
4. Callback fails → DROP the temp table; production is untouched

Users querying the production table during the update see the old data; the RENAME switches to the new data instantly, with no empty-table window. The script **never needs to TRUNCATE or clear the table manually**.

### append

Writes directly into the production table, no temp table. For append-only data like logs and event streams.

### upsert

Writes directly into the production table via PG `ON CONFLICT (key) DO UPDATE`. For incremental sync. Key columns are defined in `uds_table_manage`'s `primary_key` field and passed to `uds-cli import` via `--upsert-keys`.

---

## 2. Script Spec Essentials

- Entry function: `fetch` for script sources
- Data import goes through `subprocess.run(["uds-cli", "import", ...])` (uds-cli is preinstalled in the sandbox; credentials are injected automatically)
- Credentials are read via `os.environ['CREDENTIAL_NAME']` (the name stored via `uds_credential_store`)
- error_code: failures return `SCRIPT`; the error message drives the user-facing display
- Replicate the cleaning: the script must replicate every cleaning action done while building the table (column-name strip, type conversion, derived columns). API data sources must map camelCase → snake_case column names in the script
- Upsert mode: `uds-cli import` must carry `--upsert-keys`; deduplicate the candidate keys via `drop_duplicates` before importing (PG cannot upsert the same row twice in one batch)
- Delete temporary files when done; process large volumes batch by batch with timely `del df; gc.collect()`
- The callback is handled by the GoalfyData platform automatically; the script only needs to return the result dict correctly
- Error messages are user-facing: write them in the user's language (the sample messages in the standard template are English; use Chinese for a Chinese user's dataset), include row numbers, column names, and fix suggestions (the website shows the error verbatim), and never pass raw low-level exceptions through

---

## 3. Minimal fetch Example (script source)

A minimal runnable example; the pipeline is API pull → CSV → uds-cli import:

```python
import os, subprocess, json, csv
import urllib.request

TASK_ID = "tk_xxxxxxxx"  # replace with the current session's task_id when writing the script

def fetch(table_name, update_mode, **kwargs):
    os.makedirs("/workspace/tmp", exist_ok=True)
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

---

## 4. Cross-session Maintenance (important: you are a local agent — there is exactly one channel for reading sandbox files)

You run on the user's machine and `uds-cli upload` is write-only; there are two equivalent channels for retrieving a registered script (script directory only):
`uds-cli --task-id <task_id> download-script <script_file path> --dataset <dataset_id>` or
`uds_table_manage(action="get_script", table_name=...)` — both return a short-lived download URL; download it yourself.
The standard cross-session script-edit flow (get URL → download → edit → upload):

1. `uds_table_manage(list)` for the script_file path → `download-script` for the URL → `curl -o local.py "<URL>"`;
2. Edit the local file directly (keep the existing custom cleaning logic);
3. `uds-cli upload script.py --type script` to re-upload → `uds_table_manage(update, script_file=...)` to update the registration.

Also keep the **cleaning-conventions-into-governance-rules** discipline: every non-obvious cleaning action in the script (derived columns,
unit conversion, column mapping, dedup criteria) was persisted at build time via `uds_rule_manage(create, rule_type="cleaning")` —
governance rules are the source of truth for business definitions (consumed by every query path); the script is merely their implementation.
When the two disagree, fix the script to match the rules.

---

## 5. Sandbox Rules (resources and sharing)

**Sandbox resources and memory management**:

Sandbox memory is limited (~4C8G); multi-file, million-row data OOMs easily:
- Process files serially; after each file, `del df; gc.collect()` explicitly
- Profile with sampled reads only (`nrows=500`), never full loads
- For large files (>500k rows or >100MB), prefer polars or DuckDB over full pandas loads (DuckDB cannot read Excel directly; use polars/pandas for Excel)

**Shared-sandbox policy**:

Tables in one dataset sharing the same schedule run serially in a shared sandbox. Scripts must follow these rules, or they take down the other tables in the group:

- Use absolute paths; `os.chdir()` is forbidden
- Never modify `os.environ` at module level or outside functions; pass config via function parameters
- No runtime `sys.path.insert` / `append`; install dependencies with pip
- All external resources (files, DB connections, HTTP sessions) use `with` contexts and must be released before the function returns
- Prefer `tempfile.TemporaryDirectory()` for temp files; if writing to `/workspace/tmp/` directly, clean up before the script ends
- No stateful objects at module level (e.g. `driver = webdriver.Chrome()`); create inside functions and close in `finally`

If the rules genuinely cannot be followed, set `exclusive_sandbox=true` (passed in `uds_table_manage` update) to isolate that table's sandbox.

---

## 6. Data-source Script Templates

The templates below are all custom regions of the `fetch` entry. Common rules:
- Source databases are read-only; writing is **forbidden**
- Chunked reads are mandatory (CHUNK_SIZE ~5000), writing CSV chunk by chunk → `uds-cli import`, with `del df; gc.collect()` per chunk
- Release connections with `try/finally`
- Credential safety: non-sensitive config like host/port may live in the script; passwords/tokens must be stored via `uds_credential_store` and read from `os.environ`
- Incremental sync pairs with `update_mode=upsert`, using a timestamp or auto-increment ID as the incremental cursor
- Upsert mode: every chunk's import must carry `--upsert-keys` (taken from target_columns primary_key, see the 6.1 template) and every chunk keeps `--mode upsert` — never switch to append

### 6.1 External MySQL Pull

Prerequisite: `pip install pymysql` before the sandbox's first run (the snapshot persists; no reinstall needed later).

Credential setup:
```
uds_credential_store(action="store", credential_name="MYSQL_HOST", credential_value="rm-xxx.mysql.rds.aliyuncs.com", task_id=<task_id>)
uds_credential_store(action="store", credential_name="MYSQL_PASSWORD", credential_value="P@ssw0rd", task_id=<task_id>)
```

```python
TASK_ID = "tk_xxxxxxxx"  # replace with the current session's task_id when writing the script

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
                # cleaning: camelCase → snake_case
                df = df.rename(columns={"orderId": "order_id", "createdAt": "created_at"})

                os.makedirs("/workspace/tmp", exist_ok=True)
                tmp_csv = f"/workspace/tmp/chunk_{table_name.split('.')[-1]}.csv"
                df.to_csv(tmp_csv, index=False)
                chunk_rows = int(len(df))
                del df; gc.collect()

                mode = update_mode if update_mode == "upsert" else ("append" if total_rows > 0 else update_mode)  # upsert keeps upsert per chunk, avoiding key conflicts from append
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

**Incremental variant**: query the target table's max timestamp and pull only the delta:

```python
# add at the start of fetch:
r0 = subprocess.run(["uds-cli", "--task-id", TASK_ID, "exec", f"SELECT MAX(updated_at) FROM {table_name}", "--format", "csv"],
                    capture_output=True, text=True)
max_ts = None
if r0.returncode == 0:
    lines = r0.stdout.strip().split("\n")
    if len(lines) > 1 and lines[-1].strip() != "":
        max_ts = lines[-1].strip()

# change cursor.execute to:
if max_ts:
    cursor.execute("SELECT * FROM source_orders WHERE updated_at > %s ORDER BY id", (max_ts,))
else:
    cursor.execute("SELECT * FROM source_orders ORDER BY id")
```

### 6.2 REST API Paged Pull

```python
TASK_ID = "tk_xxxxxxxx"  # replace with the current session's task_id when writing the script

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

        # write CSV per page → import (no in-memory accumulation)
        os.makedirs("/workspace/tmp", exist_ok=True)
        tmp_csv = f"/workspace/tmp/page_{table_name.split('.')[-1]}.csv"
        with open(tmp_csv, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=[c["name"] for c in target_columns])
            writer.writeheader()
            for item in items:
                writer.writerow({c["name"]: item.get(c["name"], "") for c in target_columns})

        chunk_rows = len(items)
        mode = update_mode if update_mode == "upsert" else ("append" if total_rows > 0 else update_mode)  # upsert keeps upsert per chunk, avoiding key conflicts from append
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

### 6.3 External PostgreSQL Pull

Prerequisite: `pip install psycopg2-binary`

```python
TASK_ID = "tk_xxxxxxxx"  # replace with the current session's task_id when writing the script

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

                mode = update_mode if update_mode == "upsert" else ("append" if total_rows > 0 else update_mode)  # upsert keeps upsert per chunk, avoiding key conflicts from append
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

### 6.4 MongoDB Pull

Prerequisite: `pip install pymongo`

```python
TASK_ID = "tk_xxxxxxxx"  # replace with the current session's task_id when writing the script

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

            mode = update_mode if update_mode == "upsert" else ("append" if total_rows > 0 else update_mode)  # upsert keeps upsert per chunk, avoiding key conflicts from append
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

### 6.5 Cross-dataset SQL Aggregation (no file reads)

For aggregating data from other datasets' tables into the current table (summary tables, wide tables).

```python
TASK_ID = "tk_xxxxxxxx"  # replace with the current session's task_id when writing the script

def fetch(table_name, update_mode, target_columns, **kwargs):
    import subprocess

    # cross-schema aggregation SQL (source tables use fully-qualified names)
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

    # under full_replace, table_name already points at the temp table — just write; no manual TRUNCATE
    r = subprocess.run(["uds-cli", "--task-id", TASK_ID, "exec", agg_sql, "--mode", "writer"],
                       capture_output=True, text=True)
    if r.returncode != 0:
        return {"success": False, "error_code": "SCRIPT", "error": r.stderr, "rows_inserted": 0}

    # row count
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

## 7. Multi-table Coordination

### Sync Order

Tables in one dataset may depend on each other (e.g. sync dimension tables before fact tables). Control it via `sync_order`:

```
uds_table_manage(action="update", table_name="dim_products", sync_order=10, task_id=<task_id>)    # dimension table first
uds_table_manage(action="update", table_name="fact_orders", sync_order=100, task_id=<task_id>)    # fact table later
```

Smaller numbers run first. Default is 100 when unset.

### Shared-sandbox Troubleshooting

Tables with the same dataset and schedule run serially in a shared sandbox. When a table runs fine alone but keeps failing in the shared group, the usual cause is a preceding table's script polluting the sandbox environment.

Typical error patterns (check `error_message` in `uds_sync_logs`):

| Error | Likely cause |
|----------|----------|
| `FileNotFoundError` | A preceding script called `os.chdir()` and changed the working directory |
| `KeyError: 'XXX_ENV'` | A preceding script modified `os.environ` without restoring it |
| `ModuleNotFoundError` | A preceding script polluted `sys.path` |
| `Connection already closed` | A preceding script held a connection without releasing it |

Troubleshooting steps:
1. Confirm the table runs fine alone: compare against its historical successes in `uds_sync_logs`
2. Locate the other scripts on the same schedule and find the code violating the shared-sandbox rules
3. Fix the polluting script (fix one, save the whole group)
4. If it truly cannot be fixed → set `exclusive_sandbox=true` on the polluting table to isolate it

---

## 8. Failure Notifications (optional)

GoalfyData Managed Refresh can fail while unattended. Before changing notification channels, load the account's current configuration:

```
uds_notify_config(
    action="get",
    task_id=<task_id>,
    op_summary="Review the account notification channels before changing scheduled dataset failure alerts."
)
```

If the user only wants to disable a channel, preserve the binding and pause delivery:

```
uds_notify_config(
    action="set_enabled",
    channel="dingtalk",
    enabled=false,
    task_id=<task_id>,
    op_summary="Pause DingTalk delivery while preserving its credentials and notification event preferences."
)
```

To bind Webhook, Slack, Telegram, Feishu, DingTalk, WhatsApp, or another non-email channel, call Hub directly:

```
uds_notify_config(
    action="bind",
    channel="dingtalk",
    config={"url": "https://oapi.dingtalk.com/robot/send?access_token=...", "secret": "..."},
    notify_on=["datasetUpdateFailed"],
    task_id=<task_id>,
    op_summary="Bind DingTalk to receive scheduled dataset update failures and verify the channel configuration."
)
```

To bind or rebind email, call `action="bind", channel="email"` and give the returned
`https://goalfydata.ai/settings/notifications/email` URL to the user. The page shows the previous email and lets the user enter a new one and complete six-digit verification; the Agent must not request the verification code.

Supported channels: webhook / slack / dingtalk / feishu / telegram / whatsapp / email. If the user needs a visual guide, provide the existing settings page at `https://goalfydata.ai/settings`.

Once configured, the `datasetUpdateFailed` event is delivered automatically to enabled channels subscribed to that event.

---

## 9. Full Sync-verification Flow

The build phase verified data correctness via direct `uds-cli import` (column matching, type compatibility, business sanity). The verification phase runs `uds_sync_task` through the full async pipeline (trigger → sandbox execution → callback → atomic write) to prove the production path works. **Every table configured for GoalfyData Managed Refresh must go through this verification, or the refresh may be configured yet unable to run.**

### 9.1 Trigger the sync task

For every table with sources configured, trigger verification by source type:

Precondition contract (mandatory scripts, on every trigger path): the table must have script_file registered, or the trigger is rejected (`SCRIPT_NOT_CONFIGURED`).
Scripts are always uploaded via `uds-cli upload script.py --type script` (landing in /workspace/goalfydata_dataset_scripts/;
without --type they land in the data directory and fail the table config's path-prefix check).

**Script-source tables** (verifies the script execution path; the script was registered at build time — re-upload + update only if it changed):
```
(if the script changed) uds-cli --task-id <task_id> upload fetch_script.py --dataset dataset_id --type script → workspace_path
(if the script changed) uds_table_manage(action="update", script_file=workspace_path, sources=[...], task_id=<task_id>)
uds_sync_task(action="run", dataset_id=..., source_type="script", table_name=..., import_mode=..., task_id=<task_id>)
→ returns group_id → poll status until a terminal state
```

Suggested polling intervals: < 10k rows wait 30s; 10k-100k rows wait 60s; above 100k rows wait 180s.

### 9.2 Failure Handling and Retry

First: check recent failures via `uds_sync_logs(dataset_id=..., status="failed", task_id=<task_id>)`. Each record carries `error_code`, `error_message`, `log_url`, `started_at`.

Compare the latest error's `started_at` against the table config's last update time — an error older than the config change is historical residue; tell the user to wait for the next verification round, no script changes needed.

| Status / case | Handling |
|------|------|
| `success` | The table passes; move to the next |
| `failed` + `SCRIPT` | Script error. Check `error_message` and `log_url` → fix the script → `uds-cli --task-id <task_id> upload --type script` re-upload → `uds_table_manage(update, script_file=..., task_id=<task_id>)` update the config → `uds_sync_task(action="run", dataset_id=..., task_id=<task_id>)` re-trigger |
| `failed` + `SCRIPT_NOT_CONFIGURED` | No update script registered (registration incomplete). Complete SKILL.md Step 2.1 steps 9-10: write the fetch script → `uds-cli upload --type script` → `uds_table_manage(update, script_file=..., sources=[{type: script, entry: fetch, schedule: ...}])`, then retry |
| `failed` + `INFRA` | System error. Inform the user and suggest retrying later |
| Task stuck in `running` | The script crashed without returning. The zombie sweep marks it failed after 70 minutes. Use `log_url` to read the full execution log |
| `failed` + `STORAGE_QUOTA_EXCEEDED` | Dataset storage exceeds the plan's available amount. Billing model: each dataset includes 300MB by default; larger datasets are not blocked outright but count as multiple dataset usages by capacity (e.g. 900MB ≈ 3 datasets); this error means the plan's dataset usage is exhausted. Explain and offer options: clean up old data / check quota via `uds_billing_info` then upgrade or buy an add-on pack. Truncating data on your own is forbidden |
| `failed` + `GROUP_ABORTED` | An earlier item in the sync group failed and the rest were aborted. Fix the failure first, then re-trigger the whole group |

### 9.3 Post-fix Retry Flow

```
Fix the problem (script or data file)
  → if the script changed: uds-cli --task-id <task_id> upload --type script re-upload + uds_table_manage(update, script_file=..., task_id=<task_id>) sync the config
  → uds_sync_task(action="run", dataset_id=..., task_id=<task_id>) re-trigger
  → poll status until it passes
```

### 9.4 Final Report

After all tables pass, report in the three-part "Done / Partially done / Not done" format.

**Tables with GoalfyData Managed Refresh: verify the real `cron_enabled` state before reporting**

Before reporting, call `uds_dataset_get(dataset_id, task_id=<task_id>)` and read `cron_enabled` for every table with a `script` + `schedule` source:

- `cron_enabled=false` (default): tell the user "the schedule is configured (e.g. daily at 03:00 Beijing time) but not yet enabled — enable it?". After confirmation, enable via `uds_table_manage(action="update", cron_enabled=true, task_id=<task_id>)`
- `cron_enabled=true`: tell the user "GoalfyData Managed Refresh is already running; new rules take effect next cycle"

Claiming "GoalfyData Managed Refresh is all set" without verifying the state is forbidden.

Report template:
```
Dataset build results:

[Done]
- Dataset "{name}" created with N tables
- X rows imported; sync verification passed for all tables
- M governance rules recorded

[Partially done / Pending confirmation]
- "xx table" GoalfyData Managed Refresh is configured (daily 03:00 scheduled trigger) but not yet enabled — enable it?

[Not done]
- (none)
```
