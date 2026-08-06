#!/usr/bin/env python3

import hashlib
import json
import re
import sys
from pathlib import Path


def main() -> int:
    release = json.loads(Path("skill-release.json").read_text(encoding="utf-8"))
    version = release["version"]
    marker = re.compile(r"\[skill-version: ?(v[0-9]{8}-[0-9a-f]{6})\]")
    errors: list[str] = []
    files = release.get("files") or []
    checksums = release.get("checksums") or {}
    candidates = [
        Path("claude-code/skills/goalfydata/SKILL.md"),
        Path("codex/skills/goalfydata/SKILL.md"),
        Path("cursor/skills/goalfydata/SKILL.md"),
        Path("cursor/SKILL.md"),
        Path("manus/skill/SKILL.md"),
        Path("generic/SKILL.md"),
    ]
    expected_files = [str(path) for path in candidates if path.exists()]

    if not files:
        errors.append("skill-release.json has an empty files list")
    elif files != expected_files:
        errors.append(
            "skill-release.json files list does not match the current SKILL files"
        )
    if not checksums:
        print(
            "WARNING: no checksums in skill-release.json (legacy release); "
            "content drift cannot be detected"
        )

    for name in files:
        path = Path(name)
        if not path.exists():
            errors.append(f"{name}: listed in skill-release.json but missing")
            continue

        match = marker.search(path.read_text(encoding="utf-8"))
        if not match:
            errors.append(f"{name}: no [skill-version: ...] marker in description")
        elif match.group(1) != version:
            errors.append(f"{name}: version {match.group(1)} != skill-release.json {version}")

        if checksums:
            expected = checksums.get(name)
            actual = hashlib.sha256(path.read_bytes()).hexdigest()
            if not expected:
                errors.append(f"{name}: missing checksum entry in skill-release.json")
            elif actual != expected:
                errors.append(
                    f"{name}: content changed since release {version} "
                    "(sha256 mismatch)"
                )

    if errors:
        print("SKILL version check failed — a new release is required:")
        for error in errors:
            print(f"  - {error}")
        return 1

    print(f"all SKILL files carry {version}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
