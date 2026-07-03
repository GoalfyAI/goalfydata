# Manus 快速开始

> **注意：Manus 不支持把本文档粘贴给 Agent 自动完成安装。添加连接器和上传技能都必须由你在 Manus 网页界面手动操作，请按下面步骤逐步执行。**

3 分钟完成配置，让 Manus 帮你构建实时数据资产。

---

## 第 1 步 — 获取 API Key

到 [GoalfyData 控制台](https://goalfydata.ai/settings) 创建 API Key（形如 `gfk_xxx`）。

明文仅在创建时显示一次，请妥善保存。

## 第 2 步 — 添加 MCP 连接器（工具）

左侧 **插件** → 右上角 **创建** → 连接器区域选择添加方式，二选一：

### 方式 1：通过 JSON 导入 MCP（推荐）

复制以下 JSON，将 `gfk_YOUR_API_KEY_HERE` 替换为你的真实 API Key，粘贴后保存：

```json
{
  "mcpServers": {
    "goalfydata-mcp": {
      "url": "https://mcp.goalfydata.ai/mcp",
      "transport": "streamable_http",
      "headers": {
        "Authorization": "Bearer gfk_YOUR_API_KEY_HERE"
      }
    }
  }
}
```

### 方式 2：自定义 MCP

按表格逐项填写：

| 字段 | 填什么 |
|------|--------|
| **服务器名称** | `GoalfyData` |
| **传输类型** | `HTTP` |
| **服务器 URL** | `https://mcp.goalfydata.ai/mcp` |
| **自定义 headers** | 名：`Authorization`，值：`Bearer gfk_你的真实api_key` |

## 第 3 步 — 上传 Skill（技能）

左侧 **插件** → 右上角 **创建** → 技能区域 → **上传技能**。

Manus 要求上传 `.zip` 或 `.skill` 文件，且根目录下必须包含 `SKILL.md`。

**下载预构建 ZIP**：直接下载 [goalfydata-skill.zip](https://github.com/GoalfyAI/goalfydata/raw/main/manus/goalfydata-skill.zip)，跳到下方上传步骤。

**或克隆仓库手动打包**：

```bash
git clone https://github.com/GoalfyAI/goalfydata.git
cd goalfydata/manus/skill
zip -r goalfydata-skill.zip SKILL.md references/
```

将生成的 `goalfydata-skill.zip` 拖放到上传区域即可。

## 第 4 步 — 验证

连接器状态显示已连接 + Skills 中出现 `goalfydata` → 在对话中说「列出我的数据集」即可。

如果连接失败：
- 确认服务器 URL 正确
- 确认 API Key 填写正确，包含 `Bearer ` 前缀
- Manus 在云端运行，URL 必须公网可达

## 开始使用

验证通过后，在 Manus 对话中直接说：

### 从文件创建数据集

```
帮我把这个 CSV 文件创建成一个数据集
```

### 从 API 拉取数据

```
创建一个电商数据集，从 DummyJSON API 拉取商品和用户数据
```

### 查询数据

```
列出我的数据集
```

```
查询订单表的前 10 条数据
```

### 分享数据集

```
把这个数据集分享给 xxx@example.com
```

---

## 常见问题

### 连接器显示 Error

1. 服务器 URL 必须公网可达（Manus 在云端运行）
2. 检查 API Key 是否填错或漏了 `Bearer ` 前缀
3. 传输类型先用 `HTTP`，不行再看 Manus 是否有 `Streamable HTTP` 选项

### Skill 未识别

确认上传的是从 `manus/skill/` 目录打包的 `.zip` 文件，且 zip 根目录下包含 `SKILL.md`。不要上传其他平台的文件。

---

## 更新

### Skill 更新

MCP 连接器指向远程服务，无需更新。Skill 文件需要手动更新：

1. Skills 管理页面删除旧的 `goalfydata` Skill
2. 下载最新 [goalfydata-skill.zip](https://github.com/GoalfyAI/goalfydata/raw/main/manus/goalfydata-skill.zip) 并重新上传
3. 关闭当前对话，重新打开（Skill 仅在会话开始时加载）


---

## 下一步

- [核心概念](./concepts.zh-CN.md) — 理解 Build / Run / Share 架构
- [常见问题](../FAQ.zh-CN.md) — 更多问题解答
