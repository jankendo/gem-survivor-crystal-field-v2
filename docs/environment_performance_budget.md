# Environment Performance Budget

## Budget

- Texture size: 512x512 maximum per environment map.
- Visible environment tiles: 520 maximum budget.
- Environment draw CPU target: 2.6 ms or lower.
- iOS low profile: texture enabled, material maps disabled, no environment lights.
- High profile: material maps tracked and enabled for future richer rendering, but collision unchanged.

## Rules

- Do not add per-tile nodes for environment art.
- Do not create AudioStreamPlayer, BGM, SE, or sound-driven effects.
- Do not add full-screen translucent layers that hide pickups or enemies.
- Use deterministic visual variant selection; do not consume gameplay RNG streams.
