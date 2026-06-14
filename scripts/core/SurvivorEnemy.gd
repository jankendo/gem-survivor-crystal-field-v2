extends RefCounted
class_name SurvivorEnemy

var type: String = "slime"
var name_ja: String = "スライム"
var hp: int = 1
var max_hp: int = 1
var position: Vector2 = Vector2.ZERO
var speed: float = 80.0
var damage: int = 8
var score: int = 20
var exp_value: int = 4
var radius: float = 18.0
var slow_timer: float = 0.0
var contact_cooldown: float = 0.0
var hit_cooldowns: Dictionary = {}
var behavior: String = ""
var elite: bool = false
var boss: bool = false
var guaranteed_chest: bool = false
var splits: int = 0
var split_type: String = ""
var action_timer: float = 0.0
var charge_timer: float = 0.0
var telegraph_timer: float = 0.0
var recovery_timer: float = 0.0
var special_phase: String = ""
var attack_target: Vector2 = Vector2.ZERO
var attack_direction: Vector2 = Vector2.ZERO
var shock_stacks: int = 0
var shock_timer: float = 0.0
var poison_timer: float = 0.0
var ai_update_timer: float = 0.0
var ai_accumulator: float = 0.0
var data: Dictionary = {}

func _init(enemy_type: String = "slime", data: Dictionary = {}, pos: Vector2 = Vector2.ZERO, hp_bonus: int = 0, speed_bonus: float = 1.0) -> void:
	reset(enemy_type, data, pos, hp_bonus, speed_bonus)

func reset(enemy_type: String = "slime", data: Dictionary = {}, pos: Vector2 = Vector2.ZERO, hp_bonus: int = 0, speed_bonus: float = 1.0) -> void:
	type = enemy_type
	self.data = data.duplicate(true)
	name_ja = String(data.get("name_ja", "スライム"))
	max_hp = int(data.get("hp", 3)) + hp_bonus
	hp = max_hp
	position = pos
	speed = float(data.get("speed", 70.0)) * speed_bonus
	damage = int(data.get("damage", 7))
	score = int(data.get("score", 20))
	exp_value = int(data.get("exp", 4))
	radius = float(data.get("radius", 18.0))
	behavior = String(data.get("behavior", ""))
	elite = bool(data.get("elite", false))
	boss = bool(data.get("boss", false))
	guaranteed_chest = bool(data.get("guaranteed_chest", false))
	splits = int(data.get("splits", 0))
	split_type = String(data.get("split_type", ""))
	slow_timer = 0.0
	contact_cooldown = 0.0
	hit_cooldowns.clear()
	action_timer = 0.0
	charge_timer = 0.0
	telegraph_timer = 0.0
	recovery_timer = 0.0
	special_phase = ""
	attack_target = Vector2.ZERO
	attack_direction = Vector2.ZERO
	shock_stacks = 0
	shock_timer = 0.0
	poison_timer = 0.0
	ai_update_timer = 0.0
	ai_accumulator = 0.0

func tick_cooldowns(delta: float) -> void:
	contact_cooldown = maxf(0.0, contact_cooldown - delta)
	shock_timer = maxf(0.0, shock_timer - delta)
	poison_timer = maxf(0.0, poison_timer - delta)
	if shock_timer <= 0.0:
		shock_stacks = 0
	for key in hit_cooldowns.keys():
		hit_cooldowns[key] = maxf(0.0, float(hit_cooldowns[key]) - delta)

func can_take_periodic_hit(key: String, cooldown: float) -> bool:
	if float(hit_cooldowns.get(key, 0.0)) > 0.0:
		return false
	hit_cooldowns[key] = cooldown
	return true
