#!/usr/bin/env bash
set -euo pipefail

NOTES="${*:-}"
if [ -z "${NOTES}" ]; then
  echo "usage: $0 "release notes"" >&2
  exit 2
fi
if [ "${#NOTES}" -gt 1024 ]; then
  echo "update reason must be 1024 characters or fewer" >&2
  exit 2
fi

VERSION="v$(date +%Y%m%d)-$(openssl rand -hex 3)"
export VERSION NOTES

python3 - <<'INNER_PY'
import hashlib
import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path

version = os.environ["VERSION"]
notes = os.environ["NOTES"]
candidates = [
    Path("claude-code/skills/goalfydata/SKILL.md"),
    Path("claude-code/skills/goalfydata/SKILL.zh-CN.md"),
    Path("codex/skills/goalfydata/SKILL.md"),
    Path("codex/skills/goalfydata/SKILL.zh-CN.md"),
    Path("cursor/skills/goalfydata/SKILL.md"),
    Path("cursor/SKILL.md"),
    Path("manus/skill/SKILL.md"),
    Path("manus/skill/SKILL.zh-CN.md"),
    Path("generic/SKILL.md"),
    Path("generic/SKILL.zh-CN.md"),
]
files = [p for p in candidates if p.exists()]
if not files:
    raise SystemExit("no SKILL.md files found")
marker = re.compile(r"\s*\[skill-version: v[0-9]{8}-[0-9a-f]{6}\]")
for path in files:
    lines = path.read_text().splitlines()
    for i, line in enumerate(lines):
        if line.startswith("description: "):
            line = marker.sub("", line)
            lines[i] = f"{line} [skill-version: {version}]"
            break
    else:
        raise SystemExit(f"missing description line: {path}")
    path.write_text("\n".join(lines) + "\n")

Path("skill-release.json").write_text(json.dumps({
    "version": version,
    "notes": notes,
    "update_reason": notes,
    "updated_at": datetime.now(timezone.utc).isoformat(),
    "files": [str(p) for p in files],
    # 内容指纹：CI 据此发现"改了 SKILL 没重新发版"的漂移
    "checksums": {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in files},
}, ensure_ascii=False, indent=2) + "\n")
INNER_PY

git add skill-release.json
python3 -c "import json; print('\n'.join(json.load(open('skill-release.json'))['files']))" | while read -r f; do
  git add "$f"
done

git commit -m "chore(skill): release ${VERSION}" -m "${NOTES}"
# 发版即打 tag：版本串 ↔ 提交点一一对应，GitHub 侧由 publish-skill-release.yml 生成 Release
git tag -a "skill/${VERSION}" -m "${NOTES}"
echo "released ${VERSION}"
echo "push with: git push --follow-tags && git push --follow-tags git@github.com:GoalfyAI/goalfydata.git main"
