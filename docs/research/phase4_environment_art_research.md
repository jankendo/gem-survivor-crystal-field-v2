# Phase 4 Environment Art Research

Research date: 2026-06-25

## Sources checked

- Godot 4.2 Docs: [2D lights and shadows](https://docs.godotengine.org/en/4.2/tutorials/2d/2d_lights_and_shadows.html)
- Godot 4.2 Docs: [CanvasTexture](https://docs.godotengine.org/en/4.2/classes/class_canvastexture.html)
- Godot 4.2 Docs: [Importing images](https://docs.godotengine.org/en/4.2/tutorials/assets_pipeline/importing_images.html)
- Godot 4.2 Docs: [GPU optimization](https://docs.godotengine.org/en/4.2/tutorials/performance/gpu_optimization.html)
- Godot 4.2 Docs: [2D rendering optimization](https://docs.godotengine.org/en/4.2/tutorials/performance/gpu_optimization.html)

## Findings

- Godot 2D can combine ambient modulation, lights, normal/specular maps, and texture filtering, but this project has an iOS energy budget and a complete silence policy. Phase 4 should not add animated light spam or audio-coupled effects.
- `CanvasTexture` supports diffuse, normal, and specular textures. The manifest should track albedo, normal-like, specular, and emission maps even if the first runtime integration uses albedo-only drawing for performance.
- Godot image import documentation notes that mipmaps can reduce grain when images scale down, but they increase memory. For 512px 2D tiles, Phase 4 keeps import sidecars auditable and uses a quality profile to decide when maps are active.
- Mobile GPUs are sensitive to overdraw and excess draw work. The environment refresh should improve floor/wall/void readability without placing large translucent layers over every gameplay object.
- Procedural deterministic variants are safer than random per-frame decoration. Environment art must not change collision, pickup placement, or RNG gameplay streams.

## Phase 4 decision

- Add original project-local 512x512 environment PNGs for four biomes and four surface types.
- Track all environment art in `data/environment_asset_manifest.json` with human review status.
- Use `EnvironmentVisualSystem.gd` to resolve colors, paths, quality profiles, and deterministic visual variants.
- Draw textures only as world background/floor/void surfaces; gameplay collision remains sourced from map data and existing wall systems.
- Keep `data/environment_visual_quality.json` as the performance budget switchboard.
