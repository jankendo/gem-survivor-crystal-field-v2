# Threading Contract

## Rule

Godot SceneTree objects are not thread-safe. Worker threads must not touch nodes, Resources owned by the main thread, or gameplay objects with side effects.

## Allowed Future Worker Inputs

- PackedVector2Array snapshots.
- PackedFloat32Array and PackedInt32Array buffers.
- Plain dictionaries copied before task start.

## Main Thread Only

- `state.enemies` mutation.
- pickup creation.
- reward drops.
- SceneTree, CanvasItem, Control, Resource loading.
- RNG stream consumption that affects gameplay.

## Current Decision

Phase 5 does not introduce WorkerThreadPool runtime jobs. It adds SoA and scheduler contracts first, so a future worker migration has a safe data boundary.
