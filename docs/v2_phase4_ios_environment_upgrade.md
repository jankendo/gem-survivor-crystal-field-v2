# v2 Phase 4 iOS + Environment Upgrade

Phase 4 covers two production risks: iOS title clipping and environment art readiness.

## Scope

- Rebuild the touch title screen inside the Safe Area using a deterministic layout contract.
- Keep Windows stretch and title layout behavior compatible.
- Add original environment texture candidates and a manifest-driven rendering path.
- Preserve Phase 3 gameplay contracts: shop-only permanent unlocks, pickup placement safety, Japanese UI, RNG determinism, and complete silence.

## Implemented systems

- `IosTitleLayoutSystem.gd`: device profiles, title metrics, scroll fallback, touch action contract.
- `EnvironmentVisualSystem.gd`: environment manifest loading, surface/material path resolution, quality profiles, deterministic visual variants.
- `tools/audit_ios_title_layout.py`: JSON/Markdown title layout QA.
- `tools/environment/*`: environment manifest, seam, import, and report audits.

## Non-goals

- No genre change.
- No online ranking, server, purchase flow, or audio.
- No collision changes from environment decals.
- No claim of iOS real-device pass without a physical device review.
