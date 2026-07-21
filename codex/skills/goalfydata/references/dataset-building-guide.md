# GoalfyData Universal Dataset Building Guide

> This document is a supplementary reference to SKILL.md, carrying the detailed rules for "business interview / table naming / uds-cli & PG syntax / failure handling". Follow this guide when creating datasets and changing table structures.

---

## 1. Business Interview

### 1.1 Four-dimension Matrix

Organize the interview along 4 dimensions; finish one dimension before moving to the next. Generate concrete questions dynamically from the data type.

| Dimension | Goal | When to go deep |
|------|------|----------|
| Business background | What is this data? Which business step does it record? Time range? Update frequency? Source? | Always, for all data types |
| Business definitions | Field meanings? Primary key? Units (amount/date/timezone)? Null semantics? | When numeric, date, or status fields are present |
| Business rules | Calculation definitions (GMV/ROI/UV)? Status enums? Constraints? | When derived, status, or relation fields are present |
| Cross-table relations | Relation-field mapping? Integrity? Merge into one dataset? | Always, for multi-file scenarios |

### 1.2 Pacing

- Ask one group at a time (at most 5 related questions); asking 20 questions at once is **forbidden**
- After each group, restate and confirm in business language ("So your GMV is net of refunds but not shipping, correct?")
- Enter table creation only after all dimensions are covered — a shallow pass forces repeated rework later
- Persist business definitions discovered mid-interview via `uds_rule_manage(action="create", task_id=<task_id>)` in real time, and tell the user in one sentence

### 1.3 Three Hard Rules (with examples)

**Questions must be grounded in the data** — every question carries concrete findings from the scan; no questions out of thin air.

| Bad (ungrounded) | Good (grounded) |
|---|---|
| "What order statuses exist?" | "I scanned the status column and found 3 values: completed / cancelled / processing. Is this the complete set?" |

**Analyze first, then ask; never quiz the user on things they may not know** — infer from the data sample first and confirm with your conclusion attached.

| Bad (quizzing) | Good (conclusion-first) |
|---|---|
| "What currency is the amount in?" | "Based on the value range (10-5000) and the Malaysia site, I infer the amounts are in Malaysian Ringgit (MYR). Please confirm?" |

**Confirmation wording must be thorough** — spell out the key context (source, time range, units, definitions); never just say "please confirm the above".

| Bad (vague) | Good (thorough) |
|---|---|
| "Is the above correct?" | "Please confirm: source = TikTok Malaysia site, time range = 2025-01 to 2026-03, amounts in MYR (tax included), GMV = net of refunds, shipping not deducted. Correct?" |

### 1.4 Autonomous vs Must-confirm

- **May decide autonomously**: field naming (snake_case conversion), table-name prefix generation, derived-column naming, technical implementation of cleaning
- **Must pause and ask the user**: business definitions, table-structure plans, data-quality handling strategy, update mode, cross-table relations, large-data-volume handling, enabling schedule-triggered GoalfyData Managed Refresh

### 1.5 Persist Governance Rules Anytime

Capture governance rules (business definitions / constraints / formulas / cleaning conventions) throughout the flow; do not batch them at the end. The test: "if this is not persisted, future queries will be ambiguous or wrong". Judge semantically, not by keyword matching.

`rule_type` mapping: `cleaning` / `validation` / `computation` / `constraint`.

Tell the user upon persisting ("Recorded: amounts are in cents") — no silent persistence; rules affect all future queries and the user has the right to know.

---

## 2. Table Naming Rules

**Format**: `<business-domain prefix>_<table name>`

**Prefix generation** (when confirming with the user, show only the business name — in the user's language, not the snake_case prefix):

1. Extract 2-4 keywords from the business background, in order: platform/source + subject + time granularity
2. Convert each keyword to snake_case independently (lowercase letters, digits, underscores)
3. Non-English words (e.g. Chinese shop names) use pinyin initials or a transliterated short form; when the user's language is English, take the English keywords directly
4. Join keywords with `_`
5. Prefix ≤ 30 characters; prefix + table name ≤ 63 (PG identifier limit)

**Constraints**:

- All tables in one dataset share the same prefix
- Lowercase letters, digits, and underscores only
- **Forbidden**: bare table names (`orders`), dataset-uid prefixes (`udsx7_orders`), camelCase or uppercase (`Orders`, `TikTokOrders`)

---

## 3. uds-cli & PG Syntax

### 3.1 Subcommand Quick Reference

| Command | Purpose |
|------|------|
| `uds-cli --task-id <task_id> schemas` | List visible datasets (with schema names) |
| `uds-cli --task-id <task_id> exec "<SQL>" --mode reader/writer` | Execute SQL (reader for queries, writer for DDL/DML); supports multiple statements separated by `;` |
| `uds-cli --task-id <task_id> exec --file x.sql --mode writer` | Execute multiple SQL statements from a file |
| `uds-cli --task-id <task_id> import <file> --table <name> --mode <mode>` | Import data, **CSV/NDJSON only** (convert xlsx to CSV via pandas true-value reads first); mode=append/full_replace/upsert; upsert adds `--upsert-keys k1,k2` |
| `uds-cli --task-id <task_id> inspect --table <name>` | View table structure (for reading back target_columns) |

Always use fully-qualified table names `uds_{dataset_id}.table`.

Excel is a supported source format, not a direct `uds-cli validate/import` format. Read it with pandas/openpyxl, clean headers and types, export UTF-8 CSV with `to_csv(..., index=False)`, and validate/import that CSV.

### 3.2 PG Syntax Pitfalls (the uds-cli backend is PostgreSQL; MySQL syntax is forbidden)

- Column comments: `COMMENT ON COLUMN <table>.<col> IS 'comment'` (a standalone statement). **Never** MySQL's `... COMMENT '...'`
- Auto-increment keys: `BIGSERIAL` / `SERIAL`, not `AUTO_INCREMENT`
- Changing a column type: `ALTER COLUMN <col> TYPE <type> USING <expr>`, not `MODIFY COLUMN`
- Strings use single quotes; identifiers use no quotes or double quotes. Backticks are forbidden
- Column aliases: `AS col_name` or `AS "alias"` (double quotes), **never** single quotes
- NULL checks: `IS NULL` / `IS NOT NULL`
- Type casts: `::type` or `CAST(x AS type)`
- Foreign keys: `FOREIGN KEY` / `REFERENCES` are **forbidden** (unsupported in dataset schemas, enforced server-side with error `FOREIGN_KEY_NOT_ALLOWED`). Register table relations via `uds_relations_set` as logical relations instead of physical FKs in DDL

### 3.3 Table COMMENT Convention

When creating tables, add a standalone `COMMENT ON COLUMN uds_{dataset_id}.<table>.<col> IS '<original column name/business name> - <meaning/unit/enum>'` for every column (business name in the user's language). The original column name serves as the display_name so other Agents can understand the field.

---

## 4. Failure Handling

### 4.1 Failure Decision Tree

```
uds-cli command fails
├── argument/usage error  → fix and retry (≤ 1 time)
├── SQL syntax error      → fix and retry (≤ 1 time)
├── data-quality problem  → pause; the user decides (Constraint 4)
└── anything else         → stop and report honestly (Constraint 6)
```

### 4.2 Retry Limit

A single command runs at most twice (first run + 1 corrected retry). Beyond that you **must** stop and report per Constraint 6.

**No blind retries**: after a failure you **must** analyze the error, locate the root cause, and confirm the fix before retrying; repeating the command unchanged is **forbidden**:

- Import failures (duplicate key / type mismatch / file not found) → locate the root cause (non-unique key? type mismatch? wrong path?), fix, then retry
- Rebuilding a table after a failed import → before DROP + CREATE, **must** confirm the new DDL fixes the failure cause
- Script failures → read the full error, locate the code line, fix, then retry

### 4.3 Storage Overrun STORAGE_QUOTA_EXCEEDED

There is **no per-table row limit**. Storage uses dataset-slot accounting: each dataset includes 300MB by default, and a dataset is not blocked just for exceeding 300MB — larger datasets count as multiple dataset usages by capacity (e.g. a 900MB dataset counts as roughly 3 datasets).

Writes are only blocked when the plan's dataset usage is exhausted: the GoalfyData Managed Refresh pipeline returns `STORAGE_QUOTA_EXCEEDED`; Agent Direct Edit (`uds-cli import` / `exec`) may hit the PG-level `SCHEMA_BYTES_EXCEEDED` (per-dataset byte hard limit as the backstop).

Blind batching/truncated retries are **forbidden** — they silently truncate data and violate Constraint 6. Correct handling: pause and let the user choose among three options:

1. **Switch to `full_replace`** — after the atomic table swap only the new data remains; storage usage = new data size. Precondition: the user confirms the old data can be discarded; switching on your own under append/upsert is **forbidden**
2. **Clean up old data** — provide a sample `uds-cli --task-id <task_id> exec "DELETE FROM uds_{dataset_id}.<table> WHERE <condition>"` (by time window / business dimension); run only after the user confirms the condition. Running TRUNCATE without asking is **forbidden**
3. **Upgrade the plan or buy an add-on pack** — check the current quota and available packs via `uds_billing_info` and guide the user to purchase on the GoalfyData website

**Forbidden**: silently dropping rows and retrying after a storage overrun; treating the overrun as an ordinary "import failure" and blindly retrying (it fails the same way).

---

## 5. Base Tables and Intermediate Tables

Tables in a dataset fall into two kinds with different build strategies:

**Base tables**: built directly from user files, one data file per base table (created automatically by the standard loop).

**Intermediate tables** (summary / wide / dimension tables): whether to build them, what dimensions to aggregate, and the refresh strategy are all business decisions — **must be confirmed with the user**; never build them proactively.

| Scenario | Action |
|------|------|
| The user only uploaded raw data files (clean or Category A) | Build base tables only; no proactive intermediate tables |
| The user explicitly wants summary / wide tables | Build base + intermediate tables (after the user confirms dimensions and granularity) |
| You spot an obvious aggregation need across base tables | Proactively suggest it; build only after agreement |
| Intermediate table data comes from SQL aggregation (not file import) | Register the intermediate table with a `script` source, entry `fetch`; the update script uses `uds-cli --task-id <task_id> exec` for SQL aggregation (`INSERT INTO intermediate SELECT ... FROM base GROUP BY ...`), reading no files |

Intermediate tables are tables too — **register metadata via `uds_table_manage` all the same** (Constraint 5); configure a `schedule` if they need scheduled refresh (see `scheduled-sync-guide.md`).

---

## 6. Standard Loop Detailed Steps

Repeat for every file/data source. **At the entry, first read** `references/data-quality-guide.md` and run the data quality check (dirty-data classification, machine signals + semantic judgment, pre-create checklist):

- Clean or auto-fixable (Category A) → enter the standard loop
- Not auto-fixable (Category B) → stop this table's remaining steps, explain the data-quality problem, and negotiate a plan with the user

**Standard loop**:

| Step | Action | Key constraint |
|------|------|----------|
| 1. Data profiling | Analyze row count, type distribution, nulls, sample values | Sampling mode; no full loads |
| 2. Confirm the table plan | Show the user each field's business meaning; confirm the structure | Constraint 4 |
| 3. Create the table | `uds-cli --task-id <task_id> exec --mode writer "CREATE TABLE uds_{dataset_id}.name (...)"` | snake_case fields; read Sections 2-3 of this guide first (naming rules + PG pitfalls) |
| 4. Register metadata | `uds_table_manage(action="create", dataset_id=..., table_name=..., task_id=...)` | Constraint 5 |
| 5. Import data | First `uds-cli --task-id <task_id> validate file.csv --table uds_{dataset_id}.name` to pre-check (column/type match, no write), then `uds-cli --task-id <task_id> import file.csv --table uds_{dataset_id}.name --mode full_replace` | CSV/NDJSON only; xlsx sources get true-value pandas reads to CSV first |
| 6. Quality check | `uds-cli --task-id <task_id> exec "SELECT COUNT(*) FROM uds_{dataset_id}.name"` — rows, nulls, duplicates | upsert requires two runs to verify idempotency |
| 7. Read back columns | `uds-cli --task-id <task_id> inspect --table uds_{dataset_id}.name` → target_columns | Never invent them |
| 8. Confirm the update mode | Ask the user: append / full_replace / upsert? Scheduled pulls afterwards? | |
| 9. Write the update script (only for tables that will use GoalfyData Managed Refresh; skip 9-10 otherwise) | Per SKILL.md 4.3's entry conventions and scheduled-sync-guide.md's script spec (script source `fetch`), `uds-cli --task-id <task_id> upload script.py --dataset ... --type script` → workspace_path | **Required**: the script must replicate every cleaning action from building this table (type conversions/column normalization/derived columns confirmed in steps 1-5); persist every non-obvious cleaning action via `uds_rule_manage(create, rule_type="cleaning")` (governance rules are the source of truth for business definitions). For cross-session edits use `uds-cli download-script <script_file> --dataset ...` to get a download URL, curl it, then modify |
| 10. Finalize the config | `uds_table_manage(action="update", update_mode=..., target_columns=..., task_id=<task_id>)`; for GoalfyData Managed Refresh tables additionally pass `sources=[{type: script, entry: fetch, schedule: ...}]` and `script_file` | **Mandatory script contract**: script sources must have script_file; registration is rejected if it is missing |

**Upsert idempotency verification** (required when update_mode=upsert):

After step 5's first successful import, run the same import again, then check:
1. `SELECT COUNT(*)` — should match the first run (no duplicate rows)
2. `SELECT ... GROUP BY <upsert_keys> HAVING COUNT(*) > 1` — should be empty (no duplicate keys)
3. Doubled rows or duplicate keys → fix `--upsert-keys` and restart from step 5

---

## 7. Overall Validation Checklist

After all tables are built, run cross-table quality checks and business validation:

- **Table existence**: `uds-cli --task-id <task_id> tables --schema uds_{dataset_id}` — confirm all expected tables exist
- **Row counts**: each table's `SELECT COUNT(*)` vs rows_inserted at import
- **Key-column nulls**: primary keys and core business columns should have no nulls
- **Relational integrity** (multi-table): IDs referenced by relation columns exist in the related table (logical-relation check; dataset schemas forbid physical FKs)
- **Business-logic sanity**: amounts >= 0, dates in reasonable ranges, enums within the expected set
- **Business query validation**: write 2-3 typical business queries and confirm the results with the user

Pause on any problem; the user decides (Constraint 4).

---

## 8. Deliverable Persistence Steps

Execute in order; report any failure honestly per Constraint 6:

1. **Table relations**: `uds_relations_set(action="replace", relations=[...], task_id=<task_id>)`
2. **Governance-rule backfill**: review the interview and fill in unpersisted rules (normally none — they were persisted in real time)
3. **Usage guide**: `uds_dataset_manage(action="update", tool_usage_guide="...", task_id=<task_id>)` (Constraint 5). Include: the dataset's business background, core-table descriptions, key business definitions, and common query entry points
4. **Permission policies** (optional): ask whether the user needs fine-grained table/column/row-level sharing controls
5. **Self-check list**: every table has a dataset_table record with non-empty target_columns? tool_usage_guide has real content? all table_names referenced by relations/rules exist? Report failures per Constraint 6

---

## 9. Changing Table Structure

After changing an existing table's structure (adding columns, changing types, adding indexes, renaming, etc.), the related metadata must be synced — otherwise sync tasks, the usage guide, and permission policies drift from the actual structure.

Before: `uds-cli --task-id <task_id> inspect --table uds_{dataset_id}.name` to view the current structure and confirm the change plan with the user.

Apply: `uds-cli --task-id <task_id> exec --mode writer "ALTER TABLE ..."`.

Follow-up sync:

| Change | Sync action |
|------|------|
| target_columns changed | `uds_table_manage(update, target_columns=[...], task_id=<task_id>)` — read back via `uds-cli --task-id <task_id> inspect`, never invent |
| Table list or field meanings changed | `uds_dataset_manage(update, tool_usage_guide=..., task_id=<task_id>)` |
| New relation field | `uds_relations_set(action="create", task_id=<task_id>)` incrementally, or replace wholesale |
| New calculation definition | `uds_rule_manage(action="create", task_id=<task_id>)` |
| Script logic affected | Modify the script → `uds-cli --task-id <task_id> upload --type script` re-upload → `uds_table_manage(update, script_file=..., task_id=<task_id>)` |
| Columns dropped/renamed on a table with policies | `uds_policy_manage(action="update", task_id=<task_id>)` to update columns referenced in row_filters/column_rules, or the policy View breaks |
