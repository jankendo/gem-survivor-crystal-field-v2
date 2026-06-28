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
minutes. They remain in nightly coverage, so the 90-minute nightly target is
not yet proven and may remain unmet until those simulations gain validated
snapshot/resume acceleration without changing their test horizon.
