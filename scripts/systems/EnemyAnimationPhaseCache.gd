extends RefCounted
class_name EnemyAnimationPhaseCache

func phase_for(enemy_type: String, elapsed_seconds: float, hz: int = 8, steps: int = 8) -> int:
	var safe_hz := clampi(hz, 1, 60)
	var safe_steps := clampi(steps, 1, 16)
	var tick := int(floor(elapsed_seconds * float(safe_hz)))
	return (tick + abs(enemy_type.hash())) % safe_steps

func shared_clock(elapsed_seconds: float, hz: int = 8) -> float:
	var safe_hz := clampi(hz, 1, 60)
	return floor(elapsed_seconds * float(safe_hz)) / float(safe_hz)
