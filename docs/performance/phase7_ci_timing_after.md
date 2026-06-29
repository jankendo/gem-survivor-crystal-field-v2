# Phase 7 CI Timing After

## Local Pre-push Evidence

| Gate | Local wall time |
| --- | ---: |
| Fast manifest, 68 assertions | 9.831 s |
| Phase 7 performance manifest | 4.981 s |
| Five evolved-effect scenarios | approximately 5-6 s |

These values are Windows local evidence and are not GitHub Actions wall time.
The final GitHub run IDs, cache status and job durations must be added after the
public branch workflows complete.

## Workflow Targets

| Workflow | Configured timeout | Target |
| --- | ---: | ---: |
| Phase 7 Fast Gate | 15 min | <= 15 min |
| Phase 7 iOS Performance | 20 min | <= 20 min |
| Windows/iOS release jobs | 25 min | <= 25 min |
| Nightly full shards | 360 min hard limit | <= 90 min wall target |

Fast and performance workflows cancel stale runs on the same branch. Release
and nightly workflows intentionally do not cancel. Editor/import/template/Python
caches include OS and Godot version in their keys.

## Remaining Timing Risk

The Phase 6 baseline density-45 and density-60 jobs took 161.73 and 148.27
minutes. Phase 7 keeps 0-30 minutes continuous in the canonical
`auto_play_ios_perf_30min.gd` shard, then covers 30-60 minutes with six parallel
five-minute snapshots at 600 enemies and the corresponding spawn/difficulty
curve. `auto_play_phase5_density_30min.gd` is an exact wrapper-level duplicate
of the canonical 30-minute harness call, so the file remains available but is
not executed twice in Nightly. The final 17-shard wall time is recorded after
the deduplicated run completes.
