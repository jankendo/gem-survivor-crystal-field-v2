extends RefCounted
class_name CrystalWall

var id: String = ""
var position: Vector2 = Vector2.ZERO
var size: Vector2 = Vector2(120, 120)
var hp: int = 1
var max_hp: int = 1
var base_hp: int = 1
var breakable: bool = true
var blocks: bool = true
var kind: String = "internal"
var wall_type: String = "wall_crystal"
var name_ja: String = "結晶壁"
var biome_id: String = "star_plain"
var reward_multiplier: float = 1.0
var pulse: float = 0.0

func _init(wall_id: String = "", pos: Vector2 = Vector2.ZERO, wall_size: Vector2 = Vector2(120, 120), wall_hp: int = 30, can_break: bool = true, wall_kind: String = "internal", type_id: String = "wall_crystal", biome: String = "star_plain") -> void:
	id = wall_id
	position = pos
	size = wall_size
	base_hp = wall_hp
	max_hp = wall_hp
	hp = max_hp
	breakable = can_break
	blocks = true
	kind = wall_kind
	wall_type = type_id
	biome_id = biome
	_apply_type_defaults()

func rect() -> Rect2:
	return Rect2(position - size * 0.5, size)

func hp_ratio() -> float:
	if max_hp <= 0:
		return 0.0
	return clampf(float(hp) / float(max_hp), 0.0, 1.0)

func rescale_hp(multiplier: float) -> void:
	var old_ratio = hp_ratio()
	max_hp = maxi(1, int(round(float(base_hp) * multiplier)))
	hp = maxi(1, int(round(float(max_hp) * old_ratio)))

func _apply_type_defaults() -> void:
	match wall_type:
		"small_crystal":
			name_ja = "小結晶"
			reward_multiplier = 0.75
		"rich_crystal":
			name_ja = "宝石結晶"
			reward_multiplier = 1.8
		"cursed_crystal":
			name_ja = "呪晶"
			reward_multiplier = 2.2
		"shortcut_wall":
			name_ja = "近道結晶壁"
			reward_multiplier = 1.35
		"ancient_wall":
			name_ja = "古代構造壁"
			reward_multiplier = 0.0
		_:
			name_ja = "結晶壁"
			reward_multiplier = 1.0
