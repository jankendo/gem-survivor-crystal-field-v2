extends RefCounted
class_name SpeedLockSystem

const DEFAULT_THRESHOLD_SECONDS := 0.9

var threshold_seconds := DEFAULT_THRESHOLD_SECONDS
var multiplier := 2.0
var pressed := false
var locked := false
var hold_seconds := 0.0
var started_locked := false
var lock_feedback_pending := false

func configure(speed_multiplier: float, threshold: float = DEFAULT_THRESHOLD_SECONDS) -> void:
	multiplier = speed_multiplier if speed_multiplier in [1.5, 2.0] else 2.0
	threshold_seconds = clampf(threshold, 0.8, 1.0)

func reset_run() -> void:
	pressed = false
	locked = false
	hold_seconds = 0.0
	started_locked = false
	lock_feedback_pending = false

func begin_press() -> void:
	if pressed:
		return
	pressed = true
	hold_seconds = 0.0
	started_locked = locked
	lock_feedback_pending = false

func tick(delta: float) -> void:
	if not pressed:
		return
	hold_seconds += maxf(0.0, delta)
	if not started_locked and not locked and hold_seconds >= threshold_seconds:
		locked = true
		lock_feedback_pending = true

func end_press() -> void:
	if not pressed:
		return
	if started_locked and hold_seconds < threshold_seconds:
		locked = false
	pressed = false
	hold_seconds = 0.0
	started_locked = false

func cancel_press() -> void:
	pressed = false
	hold_seconds = 0.0
	started_locked = false

func active(blocked: bool) -> bool:
	return not blocked and (pressed or locked)

func simulation_multiplier(blocked: bool) -> float:
	return multiplier if active(blocked) else 1.0

func consume_lock_feedback() -> bool:
	var result := lock_feedback_pending
	lock_feedback_pending = false
	return result

func display_text() -> String:
	if locked:
		return "×%.1f\n固定中" % multiplier
	if pressed:
		return "×%.1f" % multiplier
	return "倍速\n長押し"
