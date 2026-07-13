#!/usr/bin/env python3
"""Validate deterministic gf_ref rendering in Agent and Skill guidance."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AGENT_FILES = [ROOT / "claude-code/AGENTS.md", ROOT / "codex/AGENTS.md"]
SKILL_FILES = [
    ROOT / "claude-code/skills/goalfydata/SKILL.md",
    ROOT / "codex/skills/goalfydata/SKILL.md",
    ROOT / "generic/SKILL.md",
    ROOT / "manus/skill/SKILL.md",
]

CONNECT_WITH_CODE = (
    "https://goalfydata.ai/connect/skill?gf_ref=<supplied-installation-code>"
)
SETTINGS_WITH_CODE = (
    "https://goalfydata.ai/settings?gf_ref=<supplied-installation-code>"
)


def action_template(text: str) -> str:
    start = text.index("```markdown\n# ACTION REQUIRED: Connect GoalfyData")
    end = text.index("\n```", start)
    return text[start:end]


for path in AGENT_FILES:
    text = path.read_text(encoding="utf-8")
    template = action_template(text)
    assert "exactly one `gf_ref` query parameter" in text, path
    assert "use `?gf_ref=<installation-code>`" in text, path
    assert "use `&gf_ref=<installation-code>`" in text, path
    assert "replace or deduplicate an existing `gf_ref`" in text, path
    assert CONNECT_WITH_CODE in text, path
    assert SETTINGS_WITH_CODE in text, path
    assert "<connect-skill-url>" in template, path
    assert "<settings-url>" in template, path
    assert "Never output the placeholders or angle brackets" in text, path
    assert "\nhttps://goalfydata.ai/connect/skill\n" not in template, path

canonical = SKILL_FILES[0].read_text(encoding="utf-8")
for path in SKILL_FILES:
    text = path.read_text(encoding="utf-8")
    template = action_template(text)
    assert text == canonical, f"Skill copies differ: {path}"
    assert "**Attribution-aware setup URLs**" in text, path
    assert CONNECT_WITH_CODE in text, path
    assert SETTINGS_WITH_CODE in text, path
    assert "<connect-skill-url>" in template, path
    assert "<settings-url>" in template, path
    assert "Never output the placeholders or angle brackets" in text, path
    assert "\nhttps://goalfydata.ai/connect/skill\n" not in template, path

print("install attribution guidance: OK")
