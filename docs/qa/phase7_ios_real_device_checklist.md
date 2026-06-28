# Phase 7 iOS Real Device Checklist

CI and Windows/headless evidence do not verify physical-device thermal or GPU
performance. All items below are currently unverified.

## Device Conditions

- [ ] iPhone model
- [ ] iOS version
- [ ] build commit and IPA SHA-256
- [ ] battery percentage at start
- [ ] Low Power Mode state
- [ ] room temperature
- [ ] case attached or removed
- [ ] display brightness
- [ ] 60 FPS setting
- [ ] screen recording disabled baseline

## Sustained Run

Record at 10, 20 and 30 minutes:

- [ ] thermal state
- [ ] average FPS
- [ ] p95 / p99 frame time
- [ ] frames over 33 ms
- [ ] frames over 100 ms
- [ ] peak and current memory
- [ ] battery consumption
- [ ] visible hitching
- [ ] touch latency
- [ ] evolved weapon signature visibility
- [ ] boss warnings and player-hit feedback

## Instruments

- [ ] Metal System Trace
- [ ] Time Profiler
- [ ] Energy Log
- [ ] memory graph
- [ ] frame pacing capture
- [ ] second run with screen recording to isolate recording overhead

## Profiles

- [ ] nominal to fair transition
- [ ] fair to serious transition
- [ ] serious to critical transition
- [ ] ten-second stable one-level restoration
- [ ] no projectile, gem, damage, EXP, reward or RNG divergence

