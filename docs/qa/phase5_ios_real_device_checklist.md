# Phase 5 iOS Real Device Checklist

## Required

- Install a signed local build or sideloaded unsigned IPA with user-owned signing flow.
- Run 10 min, 30 min, 45 min, and 60 min sessions.
- Capture Time Profiler, Allocations, Energy Diagnostics, and Metal System Trace.
- Record device model, iOS version, thermal state, battery percentage before/after, and whether Low Power Mode is on.

## Pass Criteria

- No iOS-only enemy count reduction.
- No boss or elite missing compared with same seed expectation.
- No offscreen enemy deletion.
- No pickup/reward loss from performance budgets.
- UI controls stay inside Safe Area.
- Floor, wall, void, pickups, enemies, and boss warnings remain readable in grayscale and normal color.

## Current Block

This Windows environment cannot run Xcode Instruments or a physical iOS device. GitHub Actions can build the unsigned IPA, but it does not replace real device profiling.
