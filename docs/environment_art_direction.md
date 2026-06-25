# Environment Art Direction

## Goal

Move the field from flat color blocks toward a crystal labyrinth while preserving gameplay readability.

## Biome identities

- 星屑平原: cyan star-crystal slabs, calm baseline, lowest visual noise.
- 紫晶の森: purple crystal growth and root silhouettes, moderate density.
- 赤熱鉱床: red ore, rail fragments, hot fissures, danger-adjacent but not warning-bright.
- 虚無領域: black-purple void, sparse stars, strong non-walkable border language.

## Readability rules

- Pickups, enemies, boss telegraphs, and touch UI stay brighter than floor texture.
- Floor texture must not imply collision.
- Wall/void visuals can look dangerous, but collision remains data-driven.
- Decals have no collision and must not be used for reward placement logic.
- Every generated image keeps `human_review_status` until approved.
