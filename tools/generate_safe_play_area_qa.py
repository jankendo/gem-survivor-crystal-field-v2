#!/usr/bin/env python3
"""Generate Safe Play Area QA notes for CI artifacts."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def load_json(name: str) -> dict:
    path = ROOT / "data" / name
    if not path.exists():
        return {}
    with path.open(encoding="utf-8") as handle:
        value = json.load(handle)
    return value if isinstance(value, dict) else {}


def main() -> int:
    defaults = load_json("ios_lightweight_defaults.json")
    lines = [
        "# Safe Play Area QA",
        "",
        "## Policy",
        "",
        "- iPhone landscape uses a centered Safe Play Area.",
        "- Left and right notch-risk regions are treated as black letterbox bars.",
        "- HUD, reward cards, minimap, pause/result surfaces, and touch controls are constrained to the play rect.",
        "- Letterbox bars reject input through `SafePlayInputMapper`.",
        "- Windows and notch-off profiles keep the full viewport.",
        "",
        "## Default Settings",
        "",
        f"- Notch protection: `{defaults.get('notch_protection', True)}`",
        f"- Safe play display mode: `{defaults.get('safe_play_display_mode', 'letterbox')}`",
        f"- Target FPS: `{defaults.get('target_fps', 45)}`",
        "",
        "## Automated Coverage",
        "",
        "- `test_ios_safe_play_area_letterbox.gd` verifies symmetric bars, input rejection, notch-off behavior, and center acceptance.",
        "- `test_ios_default_lightweight_settings.gd` verifies default iOS settings remain lightweight and can switch high quality.",
        "- Existing iOS layout and touch suites still run through `test_runner.gd`.",
        "",
        "## Manual Follow-up",
        "",
        "- Check real iPhone landscapeLeft and landscapeRight for natural bar width.",
        "- Confirm Dynamic Island/notch and Home Indicator never cover important UI.",
        "- Confirm black bars feel intentional and do not accept combat or menu input.",
        "",
    ]
    output = ROOT / "test-output" / "safe_play_area_qa.md"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(f"Wrote {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
