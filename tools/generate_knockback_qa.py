from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "test-output" / "knockback_qa.md"


def main() -> int:
    resolver = ROOT / "scripts" / "systems" / "KnockbackResolver.gd"
    recovery = ROOT / "scripts" / "systems" / "EnemyPositionRecoverySystem.gd"
    weapon = ROOT / "scripts" / "systems" / "WeaponSystem.gd"
    failures = []
    if not resolver.is_file():
        failures.append("missing KnockbackResolver.gd")
    if not recovery.is_file():
        failures.append("missing EnemyPositionRecoverySystem.gd")
    weapon_text = weapon.read_text(encoding="utf-8")
    if "enemy.position +=" in weapon_text:
        failures.append("WeaponSystem still directly offsets enemy.position")
    if "knockback_resolver" not in weapon_text:
        failures.append("WeaponSystem does not use knockback resolver")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        "\n".join([
            "# Knockback QA",
            "",
            f"Resolver present: {resolver.is_file()}",
            f"Recovery system present: {recovery.is_file()}",
            f"Direct enemy.position += remaining: {'enemy.position +=' in weapon_text}",
            f"Failures: {len(failures)}",
        ]) + "\n",
        encoding="utf-8",
    )
    if failures:
        raise SystemExit("\n".join(failures))
    print(f"Knockback QA written: {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
