extends RefCounted
class_name SmoothWallSlideSystem

const TileCollisionResolverScript = preload("res://scripts/systems/TileCollisionResolver.gd")

var resolver = TileCollisionResolverScript.new()
var skin_width := 3.0
var max_step := 8.0

func move(state, origin: Vector2, motion: Vector2, radius: float) -> Dictionary:
	if motion.length_squared() <= 0.0001:
		return {"position": origin, "collided": false, "slide": Vector2.ZERO}
	var steps := maxi(1, int(ceil(motion.length() / max_step)))
	var step_motion := motion / float(steps)
	var position := origin
	var collided := false
	var total_slide := Vector2.ZERO
	for i in range(steps):
		var target := position + step_motion
		if resolver.can_occupy(state, target, radius, skin_width):
			position = target
			continue
		collided = true
		var x_first := absf(step_motion.x) >= absf(step_motion.y)
		var first := Vector2(step_motion.x, 0.0) if x_first else Vector2(0.0, step_motion.y)
		var second := Vector2(0.0, step_motion.y) if x_first else Vector2(step_motion.x, 0.0)
		var moved_first := _move_component(state, position, first, radius)
		total_slide += moved_first - position
		position = moved_first
		var moved_second := _move_component(state, position, second, radius)
		total_slide += moved_second - position
		position = moved_second
	return {"position": position, "collided": collided, "slide": total_slide}

func _move_component(state, origin: Vector2, component: Vector2, radius: float) -> Vector2:
	if component.length_squared() <= 0.0001:
		return origin
	var target := origin + component
	if resolver.can_occupy(state, target, radius, skin_width):
		return target
	return resolver.sweep_axis(state, origin, component, radius, skin_width)
