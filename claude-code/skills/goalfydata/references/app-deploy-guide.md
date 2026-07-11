# GoalfyData Universal Dataset App Development & Deployment Guide

> This document is a supplementary reference to SKILL.md, covering the app template structure, development conventions, version management, and the complete deployment flow.
>
> Key premise: the MCP is a remote service and **cannot** read or write local files — `uds_init_project` only returns a download URL, and step 1 of `uds_app_deploy` only returns a presigned upload URL. Downloading, packaging, and the PUT upload are all done by the local Agent.

---

## 1. App Template Structure

The source package downloaded via `uds_init_project(mode="template", task_id=<task_id>)` is a full-stack app skeleton:

```
{project-root}/
├── backend/                 # Express + TypeScript backend
│   ├── src/
│   │   ├── index.ts         # Startup entry
│   │   ├── app.ts           # Express instance + route registration
│   │   ├── db.ts            # PG connection abstraction (DATASETS_DATABASE_URL)
│   │   ├── datasets.ts      # tableOf(dataset_id, table) helper
│   │   ├── response.ts      # Unified API response format
│   │   ├── models/          # Type definitions
│   │   ├── services/        # Business logic
│   │   └── routes/          # Routes (thin layer, delegating to services)
│   └── tests/
├── frontend/                # React + Vite + Tailwind
│   ├── src/
│   │   ├── App.tsx          # Root component
│   │   ├── api/index.ts     # API request wrapper
│   │   └── ...
│   └── index.html
├── Dockerfile               # Three-stage build (frontend build → backend build → production image)
├── run-dev.sh               # Local development startup script
└── README.md                # Development workflow guide (required reading)
```

---

## 2. Development Conventions

### Publish Mode (Online by Default)

When the user asks to "redeploy after changes" or "see the result", default to an online release: package → `uds_app_deploy(app_id=...)` to publish a new version (URL unchanged) → hand the `app_url` to the user for verification. The template's `run-dev.sh` is only for local preview explicitly requested by the user; a local preview does not count as delivery. When resuming development in a new session, first locate the `app_id` via `uds_app_list`; if there is no local source, retrieve it with `uds_init_project(mode="fork", from_deploy_id=...)`. Iterating on the same app requires passing `app_id` — otherwise a brand-new app with a new URL is created.

### Data Placement (Every Version)

App code must read business data live from the bound dataset — on the first build and on every iteration alike. When a change adds or modifies business data, write it into the dataset first (`uds-cli exec --mode writer ...` / `uds-cli import ...`), then read it through backend APIs. Never bake business data into frontend mock arrays, static JSON, or backend constants: hardcoded data goes stale, breaks dataset updates and sharing, and is invisible to other agents. Keep in code only UI copy, design tokens, route names, feature flags, client-only view state, and test fixtures.

### Database Connection

- Development: `uds-cli --task-id <task_id> connect --mode reader --schema uds_{dataset_id} | head -3 > backend/.env` (credentials valid for 1h)
- After deployment: the platform automatically injects app-level credentials (`DATASETS_DATABASE_URL`) that never expire — the app does not need to handle credential refresh
- Reference dataset tables in code via `tableOf(dataset_id, table)`; do not hardcode schema names (they may differ across environments)
- With a single dataset you may use bare table names (search_path already points to the dataset schema); when JOINing across multiple datasets, qualify explicitly with `tableOf`
- `db` may be `null` (app not bound to a dataset); the null check **must** be inside function bodies, **never** at module top level

### Backend Development

- Layered architecture: models → services → routes; develop the service layer before writing routes
- PG placeholders are `$1 $2`, not the SQLite/MySQL `?`
- Async routes **must** be wrapped in try-catch (Express 4 does not auto-capture rejected async promises)
- The health check `/api/health` is built in; no extra implementation needed

### Frontend Development

- Before development, read `DESIGN_CHARTER.md` in the project root (visual design discipline); the frontend implementation must comply
- First run `npx tsx scripts/gen-types.ts` to generate frontend types from backend models
- Source lives under `frontend/src/`; **never** create `src/` at the project root
- `vite.config.ts` already proxies `/api` and `/auth` to the backend; use relative paths
- `npm run build` **must** succeed

### Packaging Notes

- **Must** package from inside the project root; the Dockerfile **must** be at the tar root
- Correct: `cd <project-root> && tar czf /tmp/app.tar.gz --exclude=node_modules --exclude=.git --exclude=.venv --exclude=.env .`
- Wrong: packaging from the parent directory adds an extra directory level inside the tar (`myproject/Dockerfile` instead of `./Dockerfile`)
- Package size limit: 50MB

---

## 3. Version Management Details

The system keeps the latest 2 versions (keep-2) and supports switching between the two adjacent versions.

**New app vs new version**:
- Omitting `app_id` = create a brand-new app (new app_id + new URL)
- Passing `app_id` = update an existing app (reuses app_name + dataset binding, URL unchanged)
- Same name + same dataset but no app_id = yet another brand-new app (does not overwrite the original)

**Rollback behavior** (no direction parameter; a rollback redeploys the target historical version's source package, URL unchanged):
- First `uds_app_list(app_id=..., task_id=<task_id>)` to list the version history; pick the target version with `is_current=false` from `versions` and take its `deploy_id`
- `uds_app_manage(action="rollback", deploy_id=<target historical version's deploy_id>, task_id=<task_id>)` — the platform redeploys that version's source package as the current version (a rebuild taking ~1-2 minutes, not an instant switch; it returns a NEW current deploy_id — re-fetch via `uds_app_list` before further operations)
- Never pass the CURRENT version's deploy_id to rollback (the server rejects it: redeploying the current version is no rollback)
- "Undo the rollback" = run rollback again, passing the deploy_id of the pre-rollback version

**Offline and recovery**:
- `offline` tears down the container; the URL becomes inaccessible, code and config are kept
- `online` restarts (rebuilds the container); the URL becomes accessible again
- `delete` removes permanently and irreversibly

---

## 4. Complete Deployment Flow (Step by Step)

The complete flow from project initialization to confirming the app is online:

```
1. Initialize the project
   uds_init_project(mode="template", task_id=<task_id>) → returns download_url (tar.gz source package)
   Download and unpack locally into the working directory

2. Configure the database connection
   uds-cli --task-id <task_id> connect --mode reader --schema uds_{dataset_id} | head -3 > backend/.env
   → writes DATASETS_DATABASE_URL / DATASETS_DATABASE_TYPE / DATASETS_MANIFEST (temporary credentials, valid 1h)

3. Develop locally
   Follow the template README.md (backend Express + TypeScript, frontend React + Vite); the frontend must comply with DESIGN_CHARTER.md in the template root
   Reference dataset tables via tableOf(dataset_id, table); do not hardcode schema names

4. Pre-deploy self-check (required)
   cd backend && npm run preflight → must PASS; packaging and deployment are forbidden until it passes

5. Quota check (required)
   uds_billing_info(task_id=<task_id>) → confirm the deployed-app count / deployment quota is sufficient
   If quota is insufficient, stop and give the user three options: take an old app offline or delete it / buy an add-on pack / abandon this deployment

6. Package (from inside the project root; Dockerfile must be at the tar root)
   cd <project-root> && tar czf /tmp/app.tar.gz --exclude=node_modules --exclude=.git --exclude=.venv --exclude=.env .

7. Deploy
   Step 1: uds_app_deploy(dataset_id=..., app_name="my-app", filename="app.tar.gz", task_id=<task_id>)
           → returns upload_url + package_key
   Step 2: locally curl -X PUT --upload-file /tmp/app.tar.gz -H "Content-Type: application/gzip" '<upload_url>'
   Step 3: uds_app_deploy(dataset_id=..., app_name="my-app", package_key="<key from previous step>", task_id=<task_id>)
           → returns app_url + deploy_id + app_id

8. Confirm online
   uds_app_status(deploy_id=..., task_id=<task_id>) → status="online" means the deployment succeeded

9. Deploy a new version (overwrite at the same URL)
   Pass app_id (returned by the first deployment) → uds_app_deploy(app_id=..., filename=..., task_id=<task_id>) runs the same two-step flow
   No app_id = create a brand-new app (new URL); with app_id = update the existing app (URL unchanged, latest 2 versions kept for rollback)
```

---

## 5. Version Management Operations

- `uds_app_status(deploy_id, task_id=<task_id>)` — check status, URL, version number, and whether rollback is possible
- `uds_app_list(app_id=..., task_id=<task_id>)` — list the version history and take the deploy_id of the target version with `is_current=false`
- `uds_app_manage(action="rollback", deploy_id=<target historical version's deploy_id>, task_id=<task_id>)` — rollback: redeploys that version's source package as the current version (passing the current version is rejected; the rollback produces a NEW current deploy_id — re-fetch it via `uds_app_list` before further operations)
- `uds_app_manage(action="offline", deploy_id, task_id=<task_id>)` — take the app offline
- `uds_app_manage(action="online", deploy_id, task_id=<task_id>)` — bring it back online
- `uds_app_manage(action="delete", deploy_id, task_id=<task_id>)` — delete permanently (irreversible)

---

## 6. Secondary Development (fork)

```
uds_init_project(mode="fork", from_deploy_id=<deploy_id>, task_id=<task_id>)
→ download the source package + inherit the dataset bound to the original app → modify locally → follow steps 4-8 above to self-check, package, and deploy as a NEW app
```

Data Placement (section 2) applies to fork development too: new or changed business data goes into the inherited dataset, not into the code.

---

## 7. app_name Naming Rules

Lowercase letters, digits, and hyphens; must start with a letter or digit; at most 41 characters (e.g. `sales-dashboard`, `order-tracker`).
