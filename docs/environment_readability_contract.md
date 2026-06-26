# Environment Readability Contract

## Source Of Truth

- `data/environment_asset_manifest.json`
- `data/environment_visual_quality.json`
- `tools/environment/measure_environment_contrast.py`
- `tools/environment/audit_collectible_confusion.py`

## Thresholds

- Floor/wall luma delta: 0.16 or higher.
- Floor/void luma delta: 0.14 or higher.
- Pickup/floor luma delta: 0.18 or higher, unless color distance is clearly separated.

## Current Results

- All biomes pass `test-output/phase5/environment_contrast.json`.
- All pickup/surface pairs pass `test-output/phase5/collectible_confusion.json`.
- Contact sheets:
  - `test-output/phase5/environment_grayscale_contact_sheet.png`
  - `test-output/phase5/environment_colorblind_contact_sheet.png`

## Rule

Environment art never changes collision, pickup placement, reachability, enemy targeting, reward placement, or RNG streams.
