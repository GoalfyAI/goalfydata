# Contributing Guide

Thanks for your interest in GoalfyData!

## How to Contribute

### Reporting Issues

Use the [Bug Report template](https://github.com/GoalfyAI/goalfydata/issues/new?template=bug_report.md), including:

1. What you were doing
2. What actually happened
3. Agent and environment info (Claude Code / Codex, OS, version)
4. Error logs or messages

### Feature Requests

Use the [Feature Request template](https://github.com/GoalfyAI/goalfydata/issues/new?template=feature_request.md), describing:

1. The problem you want to solve
2. Your proposed solution
3. Alternatives you considered

### Submitting Code

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/my-feature`)
3. Make your changes
4. Test your changes
5. Commit (`git commit -m "feat: add XX feature"`)
6. Push to your fork (`git push origin feat/my-feature`)
7. Create a Pull Request

### Commit Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` — New feature
- `fix:` — Bug fix
- `docs:` — Documentation changes
- `refactor:` — Code refactoring
- `test:` — Test related

## Development Setup

```bash
git clone https://github.com/GoalfyAI/goalfydata.git
cd goalfydata
```

### Plugin Development

Each platform directory (`claude-code/`, `codex/`) is self-contained. Local testing:

**Claude Code:**
```bash
claude --plugin-dir ./claude-code
```

### Editing SKILL.md

When modifying SKILL.md or references, update all platform directories (`claude-code/`, `codex/`, `manus/`, `generic/`) together. The Manus skill zip is automatically rebuilt by GitHub Actions when `manus/skill/` changes.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](./CODE_OF_CONDUCT.md).

## License

By submitting a contribution, you agree that your contribution will be licensed under the [Apache-2.0](./LICENSE) license.
