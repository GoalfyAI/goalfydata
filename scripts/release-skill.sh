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
import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path

version = os.environ["VERSION"]
notes = os.environ["NOTES"]
candidates = [
    Path("claude-code/skills/goalfydata/SKILL.md"),
    Path("codex/skills/goalfydata/SKILL.md"),
    Path("cursor/skills/goalfydata/SKILL.md"),
    Path("cursor/SKILL.md"),
    Path("manus/skill/SKILL.md"),
    Path("generic/SKILL.md"),
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
}, ensure_ascii=False, indent=2) + "\n")
INNER_PY

git add skill-release.json claude-code/skills/goalfydata/SKILL.md codex/skills/goalfydata/SKILL.md manus/skill/SKILL.md generic/SKILL.md
if [ -f cursor/skills/goalfydata/SKILL.md ]; then
  git add cursor/skills/goalfydata/SKILL.md
fi
if [ -f cursor/SKILL.md ]; then
  git add cursor/SKILL.md
fi

git commit -m "chore(skill): release ${VERSION}" -m "${NOTES}"
echo "released ${VERSION}"
