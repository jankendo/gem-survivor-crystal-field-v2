from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
PRESETS = ROOT / "export_presets.cfg"
WORKFLOW = ROOT / ".github" / "workflows" / "build-release.yml"
UNSIGNED_README = ROOT / "IOS_UNSIGNED_README.md"
PROJECT = ROOT / "project.godot"


def require(text: str, token: str, label: str, failures: list[str]) -> None:
    if token not in text:
        failures.append(f"{label}: expected {token!r}")


def main() -> int:
    failures: list[str] = []
    for path in (PRESETS, WORKFLOW, UNSIGNED_README, PROJECT):
        if not path.is_file():
            failures.append(f"missing file: {path.relative_to(ROOT)}")
    if failures:
        for failure in failures:
            print(f"ERROR: {failure}", file=sys.stderr)
        return 1

    presets = PRESETS.read_text(encoding="utf-8")
    workflow = WORKFLOW.read_text(encoding="utf-8")
    readme = UNSIGNED_README.read_text(encoding="utf-8")
    project = PROJECT.read_text(encoding="utf-8")

    require(presets, 'name="iOS"', "iOS preset", failures)
    require(presets, 'application/bundle_identifier="com.jankendo14.gemsurvivor"', "bundle identifier", failures)
    require(presets, 'application/app_store_team_id="ABCDE12345"', "team id", failures)
    require(presets, "application/export_project_only=true", "Xcode project export", failures)
    require(workflow, "CODE_SIGNING_ALLOWED=NO", "unsigned build flag", failures)
    require(workflow, "CODE_SIGNING_REQUIRED=NO", "unsigned build flag", failures)
    require(workflow, "runs-on: macos-26", "Godot 4.7 Xcode 26 runner", failures)
    require(workflow, "mkdir -p builds/ios/Payload", "Payload creation", failures)
    require(workflow, "GemSurvivor-unsigned.ipa", "IPA packaging", failures)
    require(workflow, 'GODOT_VERSION: "4.7-stable"', "Godot 4.7 workflow", failures)
    require(workflow, "SHA256SUMS-iOS.txt", "IPA integrity report", failures)
    require(project, 'config/features=PackedStringArray("4.7", "GL Compatibility")', "Godot 4.7 project format", failures)
    require(project, 'renderer/rendering_method.mobile="gl_compatibility"', "iOS Compatibility renderer", failures)
    require(project, "textures/vram_compression/import_etc2_astc=true", "iOS texture compression", failures)
    require(readme, "This IPA is unsigned.", "English unsigned warning", failures)
    require(readme, "このIPAは未署名です。", "Japanese unsigned warning", failures)

    if failures:
        for failure in failures:
            print(f"ERROR: {failure}", file=sys.stderr)
        return 1

    print("iOS workflow validation passed: preset, unsigned build, Payload and warnings")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
