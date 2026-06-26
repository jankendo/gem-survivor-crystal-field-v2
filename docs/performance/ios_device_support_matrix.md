# iOS Device Support Matrix

## Target Classes

| Class | Example | Target | Notes |
| --- | --- | --- | --- |
| Minimum | A12/A13 iPhone | 60 FPS goal, visual reductions allowed | No enemy reduction |
| Standard | A14/A15 iPhone | 60 FPS goal | Default iOS profile |
| High | A16+ / M-series iPad | 60 FPS goal, higher visuals | No difficulty change |

## Required Real Device Metrics

- 10 min, 30 min, 45 min, 60 min runs.
- Time Profiler CPU hotspots.
- Allocations growth.
- Energy Diagnostics.
- Metal System Trace.
- Thermal state and battery drain notes.

## Current Status

Windows and GitHub Actions can prove export and synthetic headless behavior. They cannot prove real device Metal or thermal behavior.
