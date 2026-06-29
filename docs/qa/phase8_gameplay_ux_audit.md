# Phase 8 Gameplay UX Audit

## Confirmed Defects

| Requirement | Current implementation | Defect |
| --- | --- | --- |
| speed lock | `SpeedHoldSystem` supports pressed-only speed | no run-local long-press lock |
| manual run exit | `game.title_requested.connect(show_title)` | bypasses result settlement |
| settings scroll | choice callback calls `show_settings()` | rebuild resets scroll/focus |
| settings choices | `_add_choice()` advances to the next raw value | no in-place Japanese list |
| core candidates | iterates all definitions with capacity only | locked/OFF candidates can appear |
| core identity | field uses one diamond and minimap one circle | weapon/passive cores are ambiguous |
| unlock visibility | Arena draws locked drops at low alpha; minimap omits time check | unavailable objects leak visually |
| event navigation | event targets are not bound to spawned runtime objects | generic danger/event candidate arrows |
| shop conditions | generic sink card mixes brief description and partial progress | no complete current/target/shortage presentation |

## Integration Boundaries

* `Main.gd`, `GameScreen.gd` and `ArenaView.gd` receive only narrow controller
  calls and rendering hooks.
* settings retain stored user values; battery saver changes effective runtime
  values only.
* manual exit produces one summary with `end_reason=manual_exit`,
  `run_completed=false` and `manually_ended=true`.
* availability is resolved by one system shared by pickup, field drawing,
  minimap, scanner, goals and indicators.
* event navigation is valid only while its exact runtime target exists.

## Resolution

上記9件は専用system/componentへ分離して実装した。Phase 8専用27 suite、189 assertionsと全5,015 assertionsが成功している。端末上のSafe Area、長押し感触、発熱は実機チェックリストへ残す。
