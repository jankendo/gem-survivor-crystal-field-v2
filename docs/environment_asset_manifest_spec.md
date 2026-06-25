# Environment Asset Manifest Spec

File: `data/environment_asset_manifest.json`

## Required top-level fields

- `schema_version`
- `source_concept_path`
- `source_generation_path`
- `generation_record`
- `visibility_contract`
- `collision_visual_contract`
- `biomes`

## Required biome fields

- `name_ja`
- `palette`
- `surfaces`

## Required surface fields

- `asset_id`
- `display_name`
- `albedo_path`
- `normal_path`
- `specular_path`
- `emission_path`
- `resolution`
- `usage`
- `walkable`
- `seamless`
- `replacement_status`
- `human_review_status`
- `checksum`
- `fallback_color`

## Status policy

- `replacement_status=integrated` means the engine may load the file.
- `human_review_status=needs_review` means the art is not approved for final public marketing use.
- Approval must be recorded per asset before changing to `approved`.
