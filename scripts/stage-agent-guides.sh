#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 1 || -z "$1" || "$1" == "/" ]]; then
  echo "usage: $0 <new-empty-staging-directory>" >&2
  exit 2
fi

STAGING_DIR="$1"
if [[ -e "$STAGING_DIR" ]]; then
  echo "staging directory already exists: $STAGING_DIR" >&2
  exit 2
fi

# The four published SKILL copies are one release artifact. Refuse to publish
# if a platform copy drifted before the normal skill-release checksum gate runs.
cmp -s claude-code/skills/goalfydata/SKILL.md codex/skills/goalfydata/SKILL.md
cmp -s claude-code/skills/goalfydata/SKILL.md manus/skill/SKILL.md
cmp -s claude-code/skills/goalfydata/SKILL.md generic/SKILL.md

mkdir -p \
  "$STAGING_DIR/claude-code" \
  "$STAGING_DIR/codex" \
  "$STAGING_DIR/manus" \
  "$STAGING_DIR/generic"

install -m 0644 claude-code/AGENTS.md claude-code/README.md claude-code/UPDATE.md "$STAGING_DIR/claude-code/"
install -m 0644 claude-code/skills/goalfydata/SKILL.md "$STAGING_DIR/claude-code/SKILL.md"
install -m 0644 codex/AGENTS.md codex/AGENTS.windows.md codex/README.md codex/UPDATE.md "$STAGING_DIR/codex/"
install -m 0644 codex/skills/goalfydata/SKILL.md "$STAGING_DIR/codex/SKILL.md"
install -m 0644 manus/README.md manus/UPDATE.md "$STAGING_DIR/manus/"
install -m 0644 manus/skill/SKILL.md "$STAGING_DIR/manus/SKILL.md"
install -m 0644 generic/README.md generic/UPDATE.md "$STAGING_DIR/generic/"
install -m 0644 generic/SKILL.md "$STAGING_DIR/generic/SKILL.md"

python3 - "$STAGING_DIR" <<'PY'
from pathlib import Path
import sys
import zipfile

staging = Path(sys.argv[1])


def write_zip(output: Path, root: Path, entries: list[str]) -> None:
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for entry in entries:
            source = root / entry
            if source.is_dir():
                for child in sorted(path for path in source.rglob("*") if path.is_file()):
                    archive.write(child, child.relative_to(root))
            else:
                archive.write(source, source.relative_to(root))


write_zip(
    staging / "manus/goalfydata-skill.zip",
    Path("manus/skill"),
    ["SKILL.md", "references"],
)
write_zip(
    staging / "generic/goalfydata-generic.zip",
    Path("generic"),
    [".mcp.json", "SKILL.md", "references", "README.md"],
)
PY

echo "Agent guides staged at $STAGING_DIR"
