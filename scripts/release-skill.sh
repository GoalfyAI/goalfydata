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
    Path("codex/skills/goalfydata/SKILL.md"),
    Path("cursor/skills/goalfydata/SKILL.md"),
    Path("cursor/SKILL.md"),
    Path("manus/skill/SKILL.md"),
    Path("generic/SKILL.md"),
]
files = [p for p in candidates if p.exists()]
if not files:
    raise SystemExit("no SKILL.md files found")
marker = re.compile(r"\s*\[skill-version: ?v[0-9]{8}-[0-9a-f]{6}\]")
for path in files:
    lines = path.read_text().splitlines()
    for i, line in enumerate(lines):
        if line.startswith("description: "):
            line = marker.sub("", line)
            lines[i] = f"{line} [skill-version:{version}]"  # Keep the colon tight: YAML plain scalars forbid ": ".
            break
    else:
        raise SystemExit(f"missing description line: {path}")
    path.write_text("\n".join(lines) + "\n")

# Every Skill release must bump the plugin version: Claude and Codex update
# plugins from plugin.json versions, so installed users miss new content otherwise.
plugin_manifests = [
    Path("claude-code/.claude-plugin/plugin.json"),
    Path("codex/.codex-plugin/plugin.json"),
    Path(".claude-plugin/marketplace.json"),
    Path(".agents/plugins/marketplace.json"),
]
ver_re = re.compile(r'("version":\s*")(\d+)\.(\d+)\.(\d+)(")')
def _bump(m):
    return f"{m.group(1)}{m.group(2)}.{m.group(3)}.{int(m.group(4)) + 1}{m.group(5)}"
for p in plugin_manifests:
    if p.exists():
        p.write_text(ver_re.sub(_bump, p.read_text(), count=1))
        print(f"plugin version bumped: {p}")

Path("skill-release.json").write_text(json.dumps({
    "version": version,
    "notes": notes,
    "update_reason": notes,
    "updated_at": datetime.now(timezone.utc).isoformat(),
    "files": [str(p) for p in files],
    # Content fingerprints let CI detect Skill edits that were not released.
    "checksums": {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in files},
}, ensure_ascii=False, indent=2) + "\n")
INNER_PY

git add skill-release.json
for f in claude-code/.claude-plugin/plugin.json codex/.codex-plugin/plugin.json .claude-plugin/marketplace.json .agents/plugins/marketplace.json; do
  [ -f "$f" ] && git add "$f"
done
python3 -c "import json; print('\n'.join(json.load(open('skill-release.json'))['files']))" | while read -r f; do
  git add "$f"
done

git commit -m "chore(skill): release ${VERSION}" -m "${NOTES}"
# Tag every release so each version maps to one commit; GitHub publishes the Release.
git tag -a "skill/${VERSION}" -m "${NOTES}"
echo "released ${VERSION}"
echo "push with: git push --follow-tags && git push --follow-tags git@github.com:GoalfyAI/goalfydata.git main"
