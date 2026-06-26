# Environment Performance Budget

## Budget

- Texture size: 512x512 maximum per environment map.
- Visible environment tiles: 520 maximum budget.
- Environment draw CPU target: 2.1 ms or lower.
- iOS low profile: texture enabled, material maps disabled, no environment lights.
- High profile: material maps tracked and enabled for future richer rendering, but collision unchanged.
- iOS low profile Phase 5: decal budget 14 per screen, tile texture alpha 0.62, no material maps.
- High profile Phase 5: decal budget 44 per screen, tile texture alpha 0.84.

## Rules

- Do not add per-tile nodes for environment art.
- Do not create AudioStreamPlayer, BGM, SE, or sound-driven effects.
- Do not add full-screen translucent layers that hide pickups or enemies.
- Use deterministic visual variant selection; do not consume gameplay RNG streams.
- Visual reductions may reduce environment detail, but never collision, pickup reachability, enemy count, or reward logic.
