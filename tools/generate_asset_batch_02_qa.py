from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "test-output"


def main() -> int:
    spec_path = ROOT / "docs" / "asset_generation" / "v2_batch_02.json"
    data = json.loads(spec_path.read_text(encoding="utf-8")) if spec_path.exists() else {"assets": []}
    summary = {
        "asset_count": len(data.get("assets", [])),
        "approved_count": 0,
        "prompt_ready_count": len(data.get("assets", [])),
        "generated_unreviewed_count": 0,
        "legal_review_status": "original_prompt_only_no_external_downloads",
    }
    OUT.mkdir(exist_ok=True)
    (OUT / "asset_batch_02_qa.md").write_text(
        "# Asset Batch 02 QA\n\n" + "\n".join(f"- {k}: {v}" for k, v in summary.items()) + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
