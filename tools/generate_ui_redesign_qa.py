from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "test-output" / "ui_redesign_qa.md"


def exists(path: str) -> bool:
    return (ROOT / path).is_file()


def main() -> int:
    components = [
        "scripts/ui/components/EquipmentGridView.gd",
        "scripts/ui/components/EquipmentIconCell.gd",
        "scripts/ui/components/EquipmentDetailSheet.gd",
        "scripts/ui/components/EquipmentFilterChips.gd",
        "scripts/ui/components/EquipmentStatsPanel.gd",
    ]
    failures = [path for path in components if not exists(path)]
    result_text = (ROOT / "scripts" / "ui" / "ResultView.gd").read_text(encoding="utf-8")
    for required in ["今回の成果", "成長", "次の目標"]:
        if required not in result_text:
            failures.append(f"ResultView missing {required}")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        "\n".join([
            "# UI Redesign QA",
            "",
            "Equipment grid/detail/filter/stat components are present.",
            "",
            *[f"- {path}: {'OK' if path not in failures else 'MISSING'}" for path in components],
            "",
            f"Result outcome/growth/next-goal copy: {'OK' if not any('ResultView' in f for f in failures) else 'NG'}",
            f"Failures: {len(failures)}",
        ]) + "\n",
        encoding="utf-8",
    )
    if failures:
        raise SystemExit("\n".join(failures))
    print(f"UI redesign QA written: {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
