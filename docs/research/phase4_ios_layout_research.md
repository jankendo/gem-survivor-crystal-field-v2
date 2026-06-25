# Phase 4 iOS Layout Research

Research date: 2026-06-25

## Sources checked

- Apple Human Interface Guidelines: [Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- Apple Human Interface Guidelines: [Playing games](https://developer.apple.com/design/human-interface-guidelines/playing-games)
- Apple Human Interface Guidelines: [Game controls](https://developer.apple.com/design/human-interface-guidelines/game-controls)
- Apple Human Interface Guidelines: [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- Apple Developer Documentation: [Positioning content relative to the safe area](https://developer.apple.com/documentation/uikit/positioning-content-relative-to-the-safe-area)
- Apple Developer Documentation: [UIView safeAreaLayoutGuide](https://developer.apple.com/documentation/uikit/uiview/2891102-safearealayoutguide)
- Apple Developer Documentation: [UIViewController viewWillTransition](https://developer.apple.com/documentation/uikit/uiviewcontroller/viewwilltransition(to:with:))
- Godot 4.2 Docs: [Multiple resolutions](https://docs.godotengine.org/en/4.2/tutorials/rendering/multiple_resolutions.html)
- Godot 4.2 Docs: [Window](https://docs.godotengine.org/en/4.2/classes/class_window.html)
- Godot 4.2 Docs: [DisplayServer](https://docs.godotengine.org/en/4.2/classes/class_displayserver.html)
- Godot 4.2 Docs: [GUI containers](https://docs.godotengine.org/en/4.2/tutorials/ui/gui_containers.html)
- Godot 4.2 Docs: [Exporting for iOS](https://docs.godotengine.org/en/4.2/tutorials/export/exporting_for_ios.html)
- GitHub Blog: [Deprecation of Node 20 on GitHub Actions runners](https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/)
- GitHub runner-images issue: [macos-latest migration to macOS 26](https://github.com/actions/runner-images/issues/14167)

Apple pages are JavaScript-rendered in the crawler, so this document records the official URLs checked and uses Godot/GitHub pages as the text-verifiable implementation sources.

## Findings

- Godot 4.2 recommends `canvas_items` with `expand` for many mobile landscape cases when a fixed 16:9 base must fill wider or taller devices without shrinking the logical UI into a letterboxed area.
- `Window.content_scale_aspect` can be changed at runtime. The project already switches touch mode to `CONTENT_SCALE_ASPECT_EXPAND` in `Main.gd`; Windows defaults remain `keep` through `project.godot`.
- `DisplayServer.screen_get_usable_rect()` is the runtime source for obstructed areas on supported platforms, but deterministic tests still need simulated iPhone/iPad notch and home-indicator profiles because headless CI cannot expose real iOS safe-area values.
- `ScrollContainer` is the correct fallback for a title menu that cannot fit all controls on the shortest landscape phone profile. The title must avoid horizontal scroll and keep the primary start button visible before vertical scrolling.
- iOS export from Windows still requires a macOS runner with Xcode. GitHub Actions remains the build authority for unsigned IPA output.
- GitHub announced Node 24 migration for JavaScript actions in 2026. The workflow should avoid obsolete actions and should be validated under current runner behavior.
- `macos-latest` is moving to macOS 26 in mid-2026. The iOS export job should pin `macos-15` to avoid unplanned Xcode changes while this Godot 4.2 export path is validated.

## Phase 4 decision

- Keep project-level Windows stretch settings unchanged: `canvas_items` + `keep`.
- Use `IosTitleLayoutSystem.gd` for deterministic Safe Area contract tests.
- Use a full Safe Area `ScrollContainer` for touch title content.
- Hide the desktop-only quit button on iOS/touch.
- Keep start, status, and all navigation buttons reachable without clipping; allow vertical scroll only when the content height exceeds the safe viewport.
