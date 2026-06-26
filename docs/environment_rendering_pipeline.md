# Environment Rendering Pipeline

## Data

- `data/environment_asset_manifest.json`: source concept, biome surfaces, material paths, review status, collision visual contract.
- `data/environment_visual_quality.json`: profile-specific texture/material/budget settings.

## Runtime

1. `ArenaView.gd` asks `BiomeSystem` for the current or cell biome.
2. `EnvironmentVisualSystem.gd` resolves background, grid, floor, and void colors.
3. If texture drawing is enabled, albedo PNGs are loaded from the manifest and cached.
4. Terrain type color is blended back into the floor so room danger and reward meaning remain visible.
5. Collision, pickup placement, and pathing continue to use existing map and placement systems.

## Asset generation

1. Built-in image generation created `assets/v2/environment/generated/source/phase4_environment_master_concept.png`.
2. `tools/environment/generate_environment_assets.py` generated runtime 512x512 PNG sets and docs.
3. Human approval remains pending in the manifest.

## Phase 5 readability path

1. Built-in image generation created `assets/v2/environment/generated/source/phase5_environment_readability_concept.png`.
2. `tools/environment/generate_phase5_readability_assets.py` regenerated runtime textures in the existing surface paths.
3. `tools/environment/measure_environment_contrast.py` verifies floor/wall/void luma separation.
4. `tools/environment/audit_collectible_confusion.py` verifies pickups stay distinct from floor and decals.
5. `tools/environment/generate_grayscale_contact_sheet.py` and `tools/environment/generate_colorblind_contact_sheet.py` produce visual review sheets.
