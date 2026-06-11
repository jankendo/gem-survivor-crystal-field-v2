extends RefCounted
class_name Projectile

var kind: String = "bolt"
var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var damage: int = 1
var pierce_left: int = 0
var radius: float = 8.0
var lifetime: float = 2.0
var splash_radius: float = 0.0
var evolved: bool = false
var hit_targets: Array = []
var bounce_left: int = 0

func _init(projectile_kind: String = "bolt", pos: Vector2 = Vector2.ZERO, vel: Vector2 = Vector2.ZERO, dmg: int = 1, pierce: int = 0, life: float = 2.0, hit_radius: float = 8.0, splash: float = 0.0, is_evolved: bool = false) -> void:
	kind = projectile_kind
	position = pos
	velocity = vel
	damage = dmg
	pierce_left = pierce
	lifetime = life
	radius = hit_radius
	splash_radius = splash
	evolved = is_evolved
