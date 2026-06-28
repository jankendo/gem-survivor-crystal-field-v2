# Phase 7 CI Timing Baseline

## Source

GitHub Actions run `28320886727`, commit
`f56d4a3a163a054a9614e3341bcc3d16645d00d7`, completed successfully on
2026-06-28. Durations below are calculated from each job's recorded start and
completion timestamps.

## Before

| Job | Duration |
| --- | ---: |
| Whole workflow wall time | 161.83 min |
| density 45 | 161.73 min |
| density 60 | 148.27 min |
| density 30 | 49.03 min |
| iOS perf 30 | 31.25 min |
| core long | 18.12 min |
| Windows build and standard tests | 15.47 min |
| weapons shard | 11.55 min |
| iOS unsigned build | 1.92 min |

The old workflow combines standard validation, the complete unit runner,
many generated reports, release export and 28 separate artifact upload steps.
Long simulations are split into 13 jobs but remain attached to the same
workflow and are enabled by a dispatch input. Godot and templates are downloaded
from scratch in every job.

## Bottlenecks

1. Density 45 and 60 dominate wall time.
2. The standard Windows job runs broad unrelated QA for every release build.
3. Godot, export templates, imported resources and Python packages are not cached.
4. Tests launch a new Godot process for each long script.
5. There is no changed-file routing or branch concurrency cancellation.
6. Success artifacts are fragmented into many upload steps.
7. Step and suite timing is not retained as structured data.

## Phase 7 Targets

| Workflow | Target |
| --- | ---: |
| Fast Gate | 15 min |
| Phase 7 performance | 20 min |
| iOS unsigned release | 25 min |
| Nightly full | 90 min |

Existing long tests remain in nightly/manual coverage. Targets are not achieved
by deleting tests, lowering enemy/projectile density or relaxing correctness
thresholds. Actual after-times must come from GitHub Actions and are recorded in
`phase7_ci_timing_after.md`.

