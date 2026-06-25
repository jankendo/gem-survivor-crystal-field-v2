# iOS Responsive Title Spec

## Problem

The Phase 3 title used Safe Area offsets, but touch mode still stacked a status card, large key visual, two-column primary grid, and footer row in a fixed non-scroll root. On the shortest iPhone landscape profiles this could clip footer controls or place them too close to the home-indicator side.

## Contract

- The title root is exactly the simulated iOS Safe Area.
- The title content is a vertical `ScrollContainer` with horizontal scroll disabled.
- The start button must be visible before scrolling.
- All touch buttons must be at least 56px tall and wider than 88px.
- The desktop-only `終了` action is hidden on iOS/touch.
- Rotation between landscape-left and landscape-right must keep the same content width and control set.
- Windows project settings remain `canvas_items` + `keep`.

## Supported profiles

- iPhone SE landscape: 1334x750
- iPhone 11 landscape: 1792x828
- iPhone 13 landscape: 2532x1170
- iPhone 15 landscape: 2556x1179
- iPhone 15 Pro Max landscape: 2796x1290
- iPad 11 landscape: 2388x1668
- iPad 12.9 landscape: 2732x2048

## Tests

- `tests/test_ios_title_screen_fit.gd`
- `tests/test_ios_title_safe_area.gd`
- `tests/test_ios_title_button_visibility.gd`
- `tests/test_ios_title_button_hit_targets.gd`
- `tests/test_ios_title_rotation_relayout.gd`
- `tests/test_ios_title_all_device_profiles.gd`
- `tests/test_ios_title_scroll_fallback.gd`
- `tests/test_windows_title_layout_regression.gd`
- `tools/audit_ios_title_layout.py`
