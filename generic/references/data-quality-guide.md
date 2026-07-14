# GoalfyData Universal Dataset Data Quality Guide

> This document is a supplementary reference to SKILL.md, covering "dirty-data classification / pre-create checks / template re-upload / idempotency verification". The per-table build entry point requires a data quality check; route the table according to this guide.

---

## 1. Dirty Data Classification: Two Categories by Fixability

**Category A — auto-fixable** (programmatic fixes after user confirmation)

Including but not limited to: flattening multi-level headers, dropping aggregate rows, BOM/encoding, column-name normalization, date/numeric type conversion, placeholder normalization, duplicate-row deduplication, upsert deduplication.

**Category B — not auto-fixable** (route to the template re-upload branch, see Section 4)

Uncontrolled data layout, multiple header blocks in a single sheet, structure whose semantics cannot be inferred at all — these cannot be fixed programmatically; you **must** guide the user to re-upload.

Once Category B is determined: **immediately stop all subsequent steps for this table** (no data profiling, no table creation, no update-mode questions) and go straight to the template re-upload branch. It is **forbidden** to "let the user pick one field structure as the standard and keep building on the dirty data" — that is equivalent to bypassing this constraint.

---

## 2. Detection Method: Machine Signals + Semantic Judgment

### 2.1 Machine-detectable signals (programmatic, deterministic)

- Non-empty merged cells (`openpyxl ws.merged_cells`) → suspected multi-level header
- Some row's numeric columns ≈ Σ of other rows (group by dimension + sum check) → suspected aggregate row
- Some numeric column ≈ Σ of other columns (same granularity) → suspected aggregate dimension column
- Inconsistent dtype within a column (numbers mixed with text/dates mixed with strings) → parsing noise
- Entire column fails to parse (nothing converts to the target type) → hard failure
- Duplicate values in the primary-key column → needs user confirmation for upsert/dedup

### 2.2 Semantic signals (understanding the first N rows, not keyword lists)

- Whether a row is a "summary/subtotal/cumulative over other rows"
- Whether a column is an aggregate of other columns (judge jointly from the SUM relation + column-name semantics)
- Whether nulls/placeholders carry business meaning
- Whether column-name semantics match the data content

**Never use hardcoded keyword/value lists** (e.g. total/subtotal/summary/N/A/currency symbols) for detection — keyword lists are never complete and misjudge business fields (e.g. a `total_amount` order-total column is itself a normal detail column).

---

## 3. Category A Handling Flow

Core principle: any modification to the data (cleaning, dropping, replacing, flattening, dropping aggregate rows, etc.) **must** be executed only after the user is informed and confirms. There is no "default handling for common issues" exemption — BOM, column-name normalization, date inference, currency symbols, and null placeholders are no exceptions.

1. **Describe the problem**: explain the dirty spots in business language (location, affected row count, share, sample values)
2. **Give a recommendation**: list candidate treatments with the recommended option first
3. **Wait for confirmation**: execute only after the user chooses; skipping is not allowed
4. **Apply the fix**: execute as the user chose
5. **Report the result**: report "X rows before cleaning → Y rows after cleaning"
6. **Persist the rule**: if the cleaning also applies to future imports from the same source, persist it via `uds_rule_manage(action="create", rule_type="cleaning", task_id=<task_id>)` to avoid asking again

Merge multiple dirty spots into one round of questions, each with concrete evidence (affected rows, sample values, share). **Never** ask about them one by one in scattered messages.

---

## 4. Category B Template Re-upload Branch

**Goal**: use a template so the user re-uploads in a clean format, instead of building a dirty table directly. This branch does template generation and re-upload guidance only — **never** mix in business interviews, update-mode questions, or field-structure choices; handle those after the user re-uploads, the new file is judged clean, and the standard loop begins.

### 4.1 Steps

1. **Identify and report**: tell the user the detected dirty spots in business language (which rows are aggregate rows, which columns are multi-level headers, which columns are aggregate dimensions that must **never** participate in sums, why building the table directly would produce wrong results — give one concrete example of a wrong analysis). This step only communicates; do not re-run detection.
2. **Confirm template acceptance** (ask this one thing only; do not mix in other questions):
   - Re-upload using a clean template (recommended) — generate a well-formatted xlsx for the user to fill in and re-upload
   - The user has concerns / does not want the template → enter the communication loop in step 4
3. **Generate and deliver the template** (when accepted): generate `<table_name>_template.xlsx` in the user's current working directory (spec in 4.2), and tell them the file path and format key points. After the user fills it in and re-provides the file → run the data quality check again on the new file → judged clean → enter the standard loop.
4. **Communication loop** (user declines the template): adjust the approach per the reason, then return to step 2. Common concerns:

   | User concern | Response |
   |---|---|
   | "Too many columns to fill" | Trim to core columns and add extension columns later as needed; or split into multiple tables |
   | "Large data volume, filling repeatedly is tedious" | Write conversion logic: the user provides the original format and you convert it locally to the template format before import |
   | "Not sure which columns should aggregate" | Confirm the business meaning column by column with the user, then redefine the template |
   | "The original file IS the standard" | Show concrete dirty-spot evidence (row numbers, content, an example wrong analysis) for the user to confirm |
   | "The template doesn't match business habits" | Adapt to the user's habits (any layout works as long as it has a single-level header and no aggregate rows) |

If sufficient communication still yields no consensus: report honestly per Constraint 6 and terminate the flow — do not create base tables, do not persist the dataset, do not write any dataset_table records.

### 4.2 Template File Spec

| Item | Rule |
|---|---|
| Header | Row 1 English column names (snake_case, matching target_columns), single level, no merged cells |
| Sample data | 2-3 rows of real business sample values after the header, just enough to show what each column roughly looks like — no format requirements on users (business meaning already lives in table COMMENTs and governance rules) |
| No aggregate rows | Summary/subtotal/cumulative rows over other rows are **forbidden** |
| Reasonable column count | Keep core columns only; split into multiple tables when there are too many |

### 4.2.1 Template Generation Skeleton (openpyxl)

Generate locally (you are a local agent — write the local file directly). Sample rows are the template's core value —
a header-only template cannot teach the user what each column should contain; writing only the header is forbidden.

The following is a **structural skeleton, not a ready-to-use product**: fill `COLUMNS` with the column names/sample values from this table's
target_columns and the interview conclusions; sample values should be real business values, no format processing needed:

```python
from openpyxl import Workbook

# (column name, sample value): names strictly match target_columns; samples are real business values
COLUMNS = [
    ("<column1>", "<real business sample value>"),
    # ... one line per column, covering all of target_columns
]

wb = Workbook()
ws = wb.active
for col_idx, (name, _) in enumerate(COLUMNS, start=1):
    ws.cell(row=1, column=col_idx, value=name)
for row_idx in range(2, 4):  # 2-3 sample rows
    for col_idx, (_, example) in enumerate(COLUMNS, start=1):
        ws.cell(row=row_idx, column=col_idx, value=example)
wb.save("<table_name>_template.xlsx")
```

## 5. Mandatory Pre-create Checklist

Before creating the table (standard loop step 3), you **must** confirm:

- The chosen primary key is unique (no duplicates, no nulls); if no single column qualifies, check composite-key uniqueness
- For every time-semantic column, the profiled format matches the DDL type (DATE ≠ TIMESTAMP ≠ TIME)
- VARCHAR length ≥ measured max length × 1.5 (headroom against `value too long`)
- Columns containing nulls must **not** be NOT NULL
- Numeric columns containing decimals use DECIMAL, not BIGINT (avoids scientific-notation import failures)
- Upsert mode **must** pre-check the candidate key combination for duplicate rows (PG **cannot** upsert the same row twice in one batch; deduplicate in the script via `drop_duplicates`)
- The actual numeric range decides INTEGER vs BIGINT vs DECIMAL
- The DDL contains **no** `FOREIGN KEY` / `REFERENCES` (dataset schemas forbid foreign keys, enforced server-side; register table relations via `uds_relations_set` instead of physical FKs)

---

## 6. Upsert Idempotency Verification

Required when `update_mode=upsert`. After the first successful import, import the same data again, then check:

1. `SELECT COUNT(*) FROM uds_{dataset_id}.<table>` — row count should match the first import (no duplicate rows)
2. `SELECT COUNT(*) FROM uds_{dataset_id}.<table> GROUP BY <upsert_keys> HAVING COUNT(*) > 1` — should return nothing (no duplicate keys)
3. If rows doubled or keys duplicated → the script's `drop_duplicates` or `--upsert-keys` is wrong; fix and re-import

`append` mode skips the idempotency test (it naturally adds rows). `full_replace` run twice should yield the same row count (the second replaces the first).

---

## 7. Cross-table Overall Validation

After all tables are built, run cross-table quality checks and business validation. Pause on any problem and let the user decide (Constraint 4: never make business decisions for the user).

### 7.1 Table Existence

Confirm all expected tables exist, none missing:

```bash
uds-cli --task-id <task_id> tables --schema uds_{dataset_id}
```

Compare the output table list against the build list agreed in the interview. For missing tables, trace the cause (creation failure / skipped / misspelled name).

### 7.2 Row Count Validation

Each table's actual row count should match `rows_inserted` from the import:

```sql
-- check table by table
SELECT COUNT(*) FROM uds_{dataset_id}.orders;
SELECT COUNT(*) FROM uds_{dataset_id}.order_items;
SELECT COUNT(*) FROM uds_{dataset_id}.customers;
```

Compare against `rows_inserted` in the import logs. If inconsistent, investigate:
- Fewer rows: rows may have failed to parse during import (encoding / type mismatch)
- More rows: possibly imported twice without `full_replace`
- Zero rows: the import may have failed silently; check the task logs

### 7.3 Nulls in Key Columns

Primary-key and core business columns should have no nulls:

```sql
-- primary-key null check (should return 0)
SELECT COUNT(*) FROM uds_{dataset_id}.orders WHERE order_id IS NULL;
SELECT COUNT(*) FROM uds_{dataset_id}.order_items WHERE item_id IS NULL;

-- core business column null check
SELECT COUNT(*) FROM uds_{dataset_id}.orders WHERE customer_id IS NULL;
SELECT COUNT(*) FROM uds_{dataset_id}.order_items WHERE order_id IS NULL;
```

Should return 0. If not, decide:
- Nulls in the primary key → data-source problem, must be fixed (back to standard-loop cleaning or template re-upload)
- Nulls in business columns → confirm with the user whether that is a normal business case (e.g. optional fields allow nulls)

### 7.4 Relational Integrity (multi-table)

IDs referenced by relation columns must exist in the related table (logical-relation check — dataset schemas forbid physical foreign keys); otherwise the data is incomplete or the relation config is wrong:

```sql
-- order_items.order_id must exist in orders (should return 0 rows)
SELECT a.order_id
FROM uds_{dataset_id}.order_items a
LEFT JOIN uds_{dataset_id}.orders b ON a.order_id = b.order_id
WHERE b.order_id IS NULL;

-- orders.customer_id must exist in customers (should return 0 rows)
SELECT a.customer_id
FROM uds_{dataset_id}.orders a
LEFT JOIN uds_{dataset_id}.customers b ON a.customer_id = b.customer_id
WHERE b.customer_id IS NULL;
```

If orphan records exist (non-empty result), confirm with the user:
- Missing source data (some related data not provided) → upload the missing part
- Wrong relation field (column name / meaning misunderstood) → fix the relation config

### 7.5 Business-logic Sanity

Basic sanity checks based on business semantics:

**Amount fields**:

```sql
-- amounts should not be negative (except special business like refunds; confirm with the user)
SELECT COUNT(*) FROM uds_{dataset_id}.orders WHERE total_amount < 0;
SELECT COUNT(*) FROM uds_{dataset_id}.order_items WHERE unit_price < 0;
```

**Date fields**:

```sql
-- check whether the date range is reasonable
SELECT MIN(order_date), MAX(order_date) FROM uds_{dataset_id}.orders;
```

Verify the min/max dates fall in the expected range. Values like `1970-01-01` or `2099-12-31` indicate default-value pollution or parsing errors.

**Enum fields**:

```sql
-- check enum values against the expected set
SELECT DISTINCT status FROM uds_{dataset_id}.orders;
SELECT DISTINCT payment_method FROM uds_{dataset_id}.orders;
```

Compare the result with the business's expected enum set. On unknown values, confirm with the user whether it is a new legitimate value or dirty data.

### 7.6 Business Query Validation

Write 2-3 typical business queries and show the results to the user to confirm the data supports real analysis:

```sql
-- example 1: monthly order count and revenue
SELECT
    DATE_TRUNC('month', order_date) AS month,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_revenue
FROM uds_{dataset_id}.orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

-- example 2: per-customer order summary (verifies multi-table joins)
SELECT
    c.customer_name,
    COUNT(o.order_id) AS order_count,
    SUM(o.total_amount) AS total_spent
FROM uds_{dataset_id}.customers c
LEFT JOIN uds_{dataset_id}.orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name
ORDER BY total_spent DESC
LIMIT 10;

-- example 3: cross-check item amounts against order totals
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

Show the query results to the user for business confirmation. If the user spots anomalies (a missing month, wrong amounts), trace back and fix.
