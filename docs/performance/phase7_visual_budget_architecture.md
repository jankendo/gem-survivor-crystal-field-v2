# Phase 7 Visual Budget Architecture

## Separation Contract

| Simulation source | Render-only view |
| --- | --- |
| `state.projectiles` | deterministic selected projectiles |
| `state.enemy_projectiles` | critical enemy attack rendering |
| `state.gems` | deterministic visible gems |
| damage and collision | hit flash commands |
| rewards and EXP | damage/reward text commands |

`PerformanceProfileSystem` sets only a profile identifier. It does not write
iOS quality values into `max_simulation_projectiles`,
`max_simulation_enemy_projectiles` or `max_simulation_gems`.

## Priorities

1. CRITICAL: enemy/boss warnings, player hit, danger and important rewards
2. SIGNATURE: evolved weapon identity
3. COMBAT: nearby and ordinary combat feedback
4. DECORATIVE: trails, secondary glow and background particles

CRITICAL commands can exceed a soft visual limit. Lower priorities are selected
deterministically by priority and source order.

## Command Buffer

`VisualEffectCommandBuffer` uses pooled Dictionaries and an O(1) recent-cell
index keyed by source, effect kind and 48-pixel world cell. Commands within
60 ms merge life, radius, brightness, line width and represented count.
Shrinking an owner array invalidates the recent index.

Explosion-start and per-enemy hit commands therefore become a representative
ring/flash instead of stacked translucent circles. Damage, collision and event
records are not coalesced.

## Style Cache

`WeaponRenderStyleCache` resolves:

* colors, shape, trail and opacity
* lifetime and arc segment base
* glow and line width
* priority and evolved style

The key is weapon ID, evolution, quality profile and renderer. Definitions,
quality or renderer changes invalidate the cache. Returned Dictionaries are
read-only.

## Adaptive Quality

The frame pacing controller requires four seconds of sustained pressure before
dropping one level and ten seconds of stability before restoring one level.
Nominal/fair/serious keep 60 FPS. Critical temporarily selects 30 FPS while
retaining Critical and Signature feedback. Only rendered counts, background
decoration and arc segments change.

Native `ProcessInfo.thermalState` integration was not added because a native
plugin would expand the build and failure surface without a physical-device
validation environment.

