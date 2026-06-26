# Phase 5 Environment Readability Research

## Goal

床、壁、奈落、デカールを一瞬で判別できるようにする。敵、pickup、ボス予兆、HUDより環境が前に出ないことを優先する。

## Findings

- グレースケールで床/壁/奈落が分離していない環境は、色覚差や輝度の低い端末で破綻しやすい。
- 床は低ノイズで、壁は床より明るく輪郭が強く、奈落は床より暗くするのが読みやすい。
- デカールは報酬に見えてはいけない。小さく、低alphaで、pickup色から離す。

## Adopted Work

- Phase 5 concept: `assets/v2/environment/generated/source/phase5_environment_readability_concept.png`
- Runtime textures regenerated in existing `assets/v2/environment/*` paths.
- Manifest updated in `data/environment_asset_manifest.json`.
- Quality budgets updated in `data/environment_visual_quality.json`.

## Automated Checks

- `tools/environment/measure_environment_contrast.py`
- `tools/environment/audit_collectible_confusion.py`
- `tools/environment/audit_environment_readability.py`
- `tools/environment/generate_grayscale_contact_sheet.py`
- `tools/environment/generate_colorblind_contact_sheet.py`

## Current Results

- `test-output/phase5/environment_contrast.json`: all biomes pass.
- Minimum floor/wall delta: 0.229.
- Minimum floor/void delta: 0.143.
- Minimum wall/void delta: 0.372.
- `test-output/phase5/collectible_confusion.json`: all pickup/surface pairs pass.
