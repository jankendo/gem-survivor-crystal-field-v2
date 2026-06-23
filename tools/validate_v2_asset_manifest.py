from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "data" / "asset_manifest.json"

REQUIRED_FIELDS = {
    "asset_id",
    "category",
    "display_name",
    "preferred_path",
    "fallback_path",
    "target_resolution",
    "aspect_ratio",
    "transparent",
    "usage",
    "priority",
    "replacement_status",
    "style_profile",
    "prompt_document",
    "checksum_optional",
}
ALLOWED_CATEGORIES = {
    "character_portrait",
    "character_sprite",
    "enemy_sprite",
    "boss_sprite",
    "weapon_icon",
    "passive_icon",
    "evolution_icon",
    "biome_background",
    "ui_panel",
    "ui_icon",
}
ALLOWED_STATUS = {"fallback", "prompt_ready", "generated", "integrated", "approved", "rejected"}
P0_REQUIRED = {
    "character.noah",
    "enemy.slime",
    "enemy.bat",
    "enemy.golem",
    "boss.boss_5",
    "weapon.magic_bolt",
    "weapon.ice_orbit",
    "passive.move_speed",
    "passive.magnet",
    "evolution.starbreaker_bolt",
    "biome.star_plain",
    "ui.title_key_visual",
    "ui.primary_crystal_panel",
    "ui.reward_card_frame",
    "ui.momentum_badge",
    "ui.boss_alert_frame",
}
IMAGE_SUFFIXES = {".png", ".webp", ".svg"}


def res_to_path(value: str) -> Path | None:
    if not isinstance(value, str) or not value.startswith("res://"):
        return None
    return ROOT / value.removeprefix("res://")


def exists_exact(path: Path) -> bool:
    try:
        relative = path.resolve().relative_to(ROOT.resolve())
    except ValueError:
        return False
    current = ROOT
    for part in relative.parts:
        names = {child.name for child in current.iterdir()}
        if part not in names:
            return False
        current = current / part
    return current.exists()


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate() -> list[str]:
    errors: list[str] = []
    if not MANIFEST.exists():
        return [f"missing manifest: {MANIFEST}"]
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    assets = manifest.get("assets", [])
    if not isinstance(assets, list):
        return ["assets must be a list"]
    seen: set[str] = set()
    integrated = {"generated", "integrated", "approved"}
    for index, entry in enumerate(assets):
        if not isinstance(entry, dict):
            errors.append(f"entry {index} is not an object")
            continue
        asset_id = str(entry.get("asset_id", ""))
        missing = sorted(REQUIRED_FIELDS - set(entry))
        if missing:
            errors.append(f"{asset_id or index}: missing fields {missing}")
        if asset_id in seen:
            errors.append(f"duplicate asset_id: {asset_id}")
        seen.add(asset_id)
        if str(entry.get("category", "")) not in ALLOWED_CATEGORIES:
            errors.append(f"{asset_id}: invalid category {entry.get('category')}")
        status = str(entry.get("replacement_status", ""))
        if status not in ALLOWED_STATUS:
            errors.append(f"{asset_id}: invalid replacement_status {status}")
        if not re.match(r"^\d+x\d+$", str(entry.get("target_resolution", ""))):
            errors.append(f"{asset_id}: target_resolution must be WIDTHxHEIGHT")
        if "transparent" in entry and not isinstance(entry.get("transparent"), bool):
            errors.append(f"{asset_id}: transparent must be boolean")
        for field in ("preferred_path", "fallback_path"):
            value = str(entry.get(field, ""))
            path = res_to_path(value)
            if path is None:
                errors.append(f"{asset_id}: {field} must be a res:// path")
                continue
            if field == "preferred_path" and status not in integrated and not value:
                continue
            if not exists_exact(path):
                errors.append(f"{asset_id}: {field} does not exist with exact case: {value}")
            elif path.suffix.lower() not in IMAGE_SUFFIXES:
                errors.append(f"{asset_id}: {field} is not an expected image format: {value}")
        preferred = res_to_path(str(entry.get("preferred_path", "")))
        if status in integrated and preferred is not None and preferred.exists():
            checksum = str(entry.get("checksum_optional", ""))
            if checksum and checksum != sha256(preferred):
                errors.append(f"{asset_id}: checksum_optional does not match preferred_path")
        prompt_doc = res_to_path(str(entry.get("prompt_document", "")))
        if prompt_doc is None or not exists_exact(prompt_doc):
            errors.append(f"{asset_id}: prompt_document missing or invalid")
        if asset_id in P0_REQUIRED and status not in integrated:
            errors.append(f"{asset_id}: P0 asset must be integrated in Phase 2")
    missing_p0 = sorted(P0_REQUIRED - seen)
    if missing_p0:
        errors.append(f"missing P0 assets: {missing_p0}")
    return errors


def main() -> int:
    errors = validate()
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(f"V2 asset manifest OK: {len(P0_REQUIRED)} P0 assets validated.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
