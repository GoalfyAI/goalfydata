# GoalfyData 通用数据集应用开发部署指南

> 本文档是 SKILL.md 的补充参考，提供应用模板结构、开发规范、版本管理和完整部署流程。
>
> 关键前提：MCP 是远程服务，**不能**读写本地文件——`uds_init_project` 只返回下载地址，`uds_app_deploy` 第一步只返回预签名上传地址，下载、打包、PUT 上传都由本地 Agent 完成。

---

## 1. 应用模板结构

`uds_init_project(mode="template", task_id=<task_id>)` 下载的源码包为全栈应用骨架：

```
{project-root}/
├── backend/                 # Express + TypeScript 后端
│   ├── src/
│   │   ├── index.ts         # 启动入口
│   │   ├── app.ts           # Express 实例 + 路由注册
│   │   ├── db.ts            # PG 连接抽象（DATASETS_DATABASE_URL）
│   │   ├── datasets.ts      # tableOf(dataset_id, table) 辅助函数
│   │   ├── response.ts      # 统一 API 响应格式
│   │   ├── models/          # 类型定义
│   │   ├── services/        # 业务逻辑
│   │   └── routes/          # 路由（薄层，调 service）
│   └── tests/
├── frontend/                # React + Vite + Tailwind
│   ├── src/
│   │   ├── App.tsx          # 根组件
│   │   ├── api/index.ts     # API 请求封装
│   │   └── ...
│   └── index.html
├── Dockerfile               # 三阶段构建（前端 build → 后端 build → 生产镜像）
├── run-dev.sh               # 本地开发启动脚本
└── README.md                # 开发流程说明（必读）
```

---

## 2. 开发规范

### 数据库连接

- 开发态：`uds-cli --task-id <task_id> connect --mode reader --schema uds_{dataset_id} | head -3 > backend/.env`（凭证 1h 有效）
- 部署后：平台自动注入应用级凭证（`DATASETS_DATABASE_URL`），永不过期，无需在应用里处理凭证刷新
- 代码中用 `tableOf(dataset_id, table)` 引用数据集表，不硬编码 schema 名（不同环境可能不同）
- 单数据集场景可直接写裸表名（search_path 已指到数据集 schema）；跨多个数据集 JOIN 时用 `tableOf` 显式限定
- `db` 可能为 `null`（应用未绑数据集），判空**必须**在函数体内做，**禁止**写在模块顶层

### 后端开发

- 分层架构：models → services → routes，先开发 service 层再写 route
- PG 占位符用 `$1 $2`，不是 SQLite/MySQL 的 `?`
- async route **必须** try-catch（Express 4 不自动捕获 async rejected promise）
- 健康检查 `/api/health` 已内置，不需要额外实现

### 前端开发

- 先运行 `npx tsx scripts/gen-types.ts` 从 backend models 生成前端类型
- 源码放 `frontend/src/` 下，**禁止**在项目根建 `src/`
- `vite.config.ts` 已配 `/api` `/auth` 代理到后端，用相对路径即可
- `npm run build` **必须**能成功执行

### 打包注意事项

- **必须**从项目根目录内部打包，Dockerfile **必须**在 tar 包根层
- 正确：`cd <project-root> && tar czf /tmp/app.tar.gz --exclude=node_modules --exclude=.git --exclude=.venv --exclude=.env .`
- 错误：从父目录打包导致 tar 内多一层目录（`myproject/Dockerfile` 而非 `./Dockerfile`）
- 包大小限制 50MB

---

## 3. 版本管理细节

系统保留最近 2 个版本（keep-2），支持在相邻两版之间切换。

**新应用 vs 新版本**：
- 不传 `app_id` = 创建全新应用（新 app_id + 新 URL）
- 传 `app_id` = 更新已有应用（复用 app_name + 数据集绑定，URL 不变）
- 同名 + 同数据集但不传 app_id = 另一个全新应用（不会覆盖旧的）

**回滚行为**：
- `direction="back"` — 当前版下线、上一版上线，秒切同 URL
- `direction="forward"` — 撤销回滚，把更新的版本切回来
- 回滚前先 `uds_app_status(task_id=<task_id>)` 检查 `can_rollback`

**下线与恢复**：
- `offline` 拆容器，URL 不可访问，代码和配置保留
- `online` 重新拉起（重建容器），URL 恢复可访问
- `delete` 永久删除，不可恢复

---

## 4. 完整部署流程（Step by Step）

以下是从起项目到确认上线的完整流程：

```
1. 起项目
   uds_init_project(mode="template", task_id=<task_id>) → 返回 download_url（tar.gz 源码包）
   本地下载解包到工作目录

2. 配置数据库连接
   uds-cli --task-id <task_id> connect --mode reader --schema uds_{dataset_id} | head -3 > backend/.env
   → 写入 DATASETS_DATABASE_URL / DATASETS_DATABASE_TYPE / DATASETS_MANIFEST（临时凭证，1h 有效）

3. 本地开发
   按模板 README.md 开发（后端 Express + TypeScript，前端 React + Vite）
   代码中用 tableOf(dataset_id, table) 引用数据集表，不硬编码 schema 名

4. 打包（从项目根目录内部打，Dockerfile 必须在 tar 包根层）
   cd <project-root> && tar czf /tmp/app.tar.gz --exclude=node_modules --exclude=.git --exclude=.venv --exclude=.env .

5. 部署
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

---

## 5. 版本管理操作

- `uds_app_status(deploy_id, task_id=<task_id>)` — 查状态、URL、版本号、是否可回滚
- `uds_app_manage(action="rollback", deploy_id, direction="back", task_id=<task_id>)` — 回滚到上一版
- `uds_app_manage(action="rollback", deploy_id, direction="forward", task_id=<task_id>)` — 撤销回滚
- `uds_app_manage(action="offline", deploy_id, task_id=<task_id>)` — 下线应用
- `uds_app_manage(action="online", deploy_id, task_id=<task_id>)` — 恢复上线
- `uds_app_manage(action="delete", deploy_id, task_id=<task_id>)` — 永久删除（不可恢复）

---

## 6. 二次开发（fork）

```
uds_init_project(mode="fork", from_deploy_id=<deploy_id>, task_id=<task_id>)
→ 下载源码包 + 继承原应用绑定的数据集 → 本地修改 → 按上述第 4-6 步打包部署为新应用
```

---

## 7. app_name 命名规则

小写字母、数字、连字符，必须以字母或数字开头，长度不超过 41 个字符（如 `sales-dashboard`、`order-tracker`）。
