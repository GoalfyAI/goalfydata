# 贡献指南

感谢你对 GoalfyData 的关注!

## 如何贡献

### 报告问题

请使用 [Bug 报告模板](https://github.com/GoalfyAI/goalfydata/issues/new?template=bug_report.md)，包含以下信息：

1. 你在做什么操作
2. 实际发生了什么
3. Agent和环境信息（Claude Code / Codex、操作系统、版本）
4. 错误日志或消息

### 功能请求

请使用[功能请求模板](https://github.com/GoalfyAI/goalfydata/issues/new?template=feature_request.md)，描述以下内容：

1. 你想解决的问题
2. 你提议的解决方案
3. 你考虑过的替代方案

### 提交代码

1. Fork 本仓库
2. 创建功能分支（`git checkout -b feat/my-feature`）
3. 进行修改
4. 测试你的修改
5. 提交（`git commit -m "feat: add XX feature"`）
6. 推送到你的 Fork（`git push origin feat/my-feature`）
7. 创建 Pull Request

### 提交规范

遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

- `feat:` — 新功能
- `fix:` — Bug 修复
- `docs:` — 文档变更
- `refactor:` — 代码重构
- `test:` — 测试相关

## 开发环境搭建

```bash
git clone https://github.com/GoalfyAI/goalfydata.git
cd goalfydata
```

### 插件开发

每个平台目录（`claude-code/`、`codex/`）是独立的。本地测试方法：

**Claude Code：**
```bash
claude --plugin-dir ./claude-code
```

### 编辑 SKILL.md

修改 SKILL.md 或 references 时，需要同时更新所有平台目录（`claude-code/`、`codex/`、`manus/`、`generic/`）。Manus 的 skill zip 会在 `manus/skill/` 变更后由 GitHub Actions 自动重新打包。

## 行为准则

本项目遵循[贡献者公约行为准则](./CODE_OF_CONDUCT.md)。

## 许可证

提交贡献即表示你同意你的贡献将依据 [Apache-2.0](./LICENSE) 许可证进行授权。
