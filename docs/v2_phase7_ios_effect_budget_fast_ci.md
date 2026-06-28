# Phase 7 iOS Visual Effect Budget / Thermal Stability / Fast CI

## Goal

Phase 7 reduces CPU allocation, Canvas draw complexity and translucent effect
pressure without changing simulation results. Godot 4.7, GDScript,
`gl_compatibility`, enemy count 600, weapon behavior, RNG, rewards, save
compatibility, Safe Area, Bundle ID and executable name remain unchanged.

## Delivered Architecture

* simulation limits and rendered limits are separate
* iOS quality selects visual views and never replaces projectile/gem state arrays
* visual commands use priority, pooling and deterministic coalescing
* weapon render styles are resolved once per weapon/evolution/quality/renderer
* projectile and timed-effect arrays no longer copy and erase in hot loops
* background grid uses one repeated texture draw
* minimap state traversal is cached at 4-8 Hz
* arc segments scale from screen radius and visual quality
* adaptive quality has pressure/restore hysteresis and changes rendering only
* release metrics remain disabled unless QA or a benchmark explicitly enables them

## Validation Scenario

`tests/fixtures/ios_effect_stress_scenarios.json` defines five 20-second
deterministic snapshots. Every scenario has 600 enemies, 500 active simulation
projectiles, 1,000 simulation gems and evolved weapons. The fixture samples
visual events at deterministic 2 Hz so CI does not wait for real-time progression.

The latest local run recorded 7,240 raw commands and 1,880 accepted commands,
a 74.03% reduction. Critical missing was zero and all before/after simulation
hashes matched.

## CI

* `ci-fast.yml`: push/PR parser, changed-file route, batch unit gate and targeted stress
* `ci-ios-perf.yml`: all Phase 7 deterministic stress cases and metrics artifact
* `build-release.yml`: Windows release and macOS/Xcode unsigned arm64 IPA
* `nightly-full.yml`: complete assertions and existing long simulations

No existing long test was deleted. Nightly remains the authority for broad
long-horizon balance coverage.

## External Verification

No real iPhone was available. Metal System Trace, Time Profiler, thermal state,
battery drain, touch latency and sustained physical-device FPS remain unverified.

