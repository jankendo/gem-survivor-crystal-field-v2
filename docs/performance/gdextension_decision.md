# GDExtension Decision

## Decision

Do not add GDExtension in Phase 5.

## Reason

- The current bottleneck evidence still supports GDScript-level structural fixes first.
- iOS GDExtension requires additional static build and export integration risk.
- The game result contract is more important than introducing a native hot loop before parity tests are complete.

## Revisit When

- Real iOS Time Profiler confirms a specific GDScript function remains dominant after spatial hash and allocation fixes.
- The SoA buffers are the source of truth for that function.
- A C++ implementation can be tested against the same deterministic parity suite.
