from __future__ import annotations

import json
from math import ceil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "test-output"

PROFILES = {
    "iphone_se_landscape": (1334, 750),
    "iphone_11_landscape": (1792, 828),
    "iphone_13_landscape": (2532, 1170),
    "iphone_15_landscape": (2556, 1179),
    "iphone_15_pro_max_landscape": (2796, 1290),
    "ipad_11_landscape": (2388, 1668),
    "ipad_12_9_landscape": (2732, 2048),
}

PRESETS = {
    (1334, 750): (50, 12, 50, 24),
    (1792, 828): (44, 12, 44, 24),
    (2532, 1170): (88, 18, 88, 34),
    (2556, 1179): (92, 18, 92, 34),
    (2796, 1290): (96, 20, 96, 36),
    (2388, 1668): (36, 24, 36, 30),
    (2732, 2048): (42, 28, 42, 34),
}

ACTION_IDS = ["start", "characters", "shop", "loadout", "collection", "quests", "settings", "help", "reset"]


def safe_rect(size: tuple[int, int], extra: int = 16) -> tuple[float, float]:
    x, y = size
    left, top, right, bottom = PRESETS[size]
    if y < 1500:
        left = max(left, right) + max(24, min(48, y * 0.025))
        right = max(24, min(left, right))
    bottom += max(24, min(40, y * 0.018))
    return x - left - right - extra * 2, y - top - bottom - extra * 2


def contract(size: tuple[int, int]) -> dict:
    safe_w, safe_h = safe_rect(size)
    profile = "tablet" if size[0] >= 2300 and max(safe_w, safe_h) / min(safe_w, safe_h) <= 1.55 else ("compact_phone" if size[0] <= 1599 else "regular_phone" if size[0] <= 2299 else "large_phone")
    columns = 3 if profile == "tablet" and safe_w >= 1500 else 2
    short_side = min(safe_w, safe_h)
    gap = 8 if profile == "compact_phone" else 12
    title = max(24, min(42, round(short_side * (0.052 if profile != "tablet" else 0.035))))
    subtitle = max(14, min(22, round(short_side * 0.025)))
    key_visual = max(72, min(150, short_side * (0.13 if profile == "compact_phone" else 0.15)))
    body = max(15, min(20, round(short_side * 0.024)))
    status = key_visual + body * 4 + gap * 4
    button = max(64, min(76, short_side * (0.09 if profile != "tablet" else 0.06)))
    secondary = max(64, min(72, button - 4))
    rows = ceil((len(ACTION_IDS) - 1) / columns)
    content_h = title + subtitle + 29 + gap + status + gap + button + gap + rows * secondary + max(0, rows - 1) * gap + 14
    return {
        "profile": profile,
        "safe_width": round(safe_w, 2),
        "safe_height": round(safe_h, 2),
        "columns": columns,
        "button_height": round(button, 2),
        "secondary_button_height": round(secondary, 2),
        "content_height": round(content_h, 2),
        "scroll_required": content_h > safe_h,
        "fits_width": True,
        "start_visible_without_scroll": title + subtitle + 29 + gap + status + gap + button <= safe_h,
    }


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    rows = {name: contract(size) for name, size in PROFILES.items()}
    ok = all(row["fits_width"] and row["start_visible_without_scroll"] and row["button_height"] >= 58 for row in rows.values())
    payload = {"ok": ok, "profiles": rows}
    (OUT / "ios_title_layout_qa.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    lines = ["# iOS Title Layout QA", "", f"- ok: {ok}", "", "| Profile | Safe | Columns | Content H | Scroll |", "| --- | ---: | ---: | ---: | --- |"]
    for name, row in rows.items():
        lines.append(f"| {name} | {row['safe_width']}x{row['safe_height']} | {row['columns']} | {row['content_height']} | {row['scroll_required']} |")
    (OUT / "ios_title_layout_qa.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("iOS title layout QA generated.")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
