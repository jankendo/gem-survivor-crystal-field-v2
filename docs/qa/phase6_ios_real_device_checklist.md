# Phase 6 iOS Real Device Checklist

CIの未署名IPA成功は実機性能保証ではない。署名可能な端末環境で次を確認する。

## Install / UI

- [ ] 署名して実iPhoneへinstall
- [ ] landscape左右rotation
- [ ] notch / Dynamic Island / home indicator Safe Area
- [ ] title、pause、level-up、chest、shop、collection、result
- [ ] touch joystick、action buttons、expanded map
- [ ] 既存save読込

## Renderer / Visual

- [ ] runtime rendererをCompatibilityとして記録
- [ ] 4 biome screenshot
- [ ] enemy、gem、drop、danger zoneの視認性
- [ ] static cacheの古いterrain残留なし
- [ ] resize/rotation後のcache更新

## Instruments

- [ ] Metal System Trace
- [ ] Time Profiler
- [ ] memory graph / peak memory
- [ ] thermal state推移
- [ ] battery drain
- [ ] 30分以上のframe pacing
- [ ] low power mode
- [ ] 複数device世代比較

## 合格記録

device、iOS version、build SHA、平均/p95/p99 FPS、thermal、battery、screenshot、trace保存先を記録する。未実施項目は合格扱いにしない。
