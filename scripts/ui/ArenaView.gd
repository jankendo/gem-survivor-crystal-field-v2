extends Control
class_name ArenaView

const ObjectiveIndicatorSystemScript = preload("res://scripts/systems/ObjectiveIndicatorSystem.gd")
const EnvironmentVisualSystemScript = preload("res://scripts/systems/EnvironmentVisualSystem.gd")
const VisualEffectBudgetSystemScript = preload("res://scripts/systems/VisualEffectBudgetSystem.gd")
const ProjectileRenderSelectionSystemScript = preload("res://scripts/systems/ProjectileRenderSelectionSystem.gd")
const MinimapRenderCacheScript = preload("res://scripts/systems/MinimapRenderCache.gd")

signal minimap_tapped

var state = null
var objective_indicator_system = ObjectiveIndicatorSystemScript.new()
var environment_visual_system = EnvironmentVisualSystemScript.new()
var visual_effect_budget_system = VisualEffectBudgetSystemScript.new()
var projectile_render_selection_system = ProjectileRenderSelectionSystemScript.new()
var minimap_render_cache = MinimapRenderCacheScript.new()
var visual_limits: Dictionary = {}
var camera_zoom := 1.0
var minimap_rect := Rect2()
var expanded_map_rect := Rect2()
var minimap_opacity := 0.76
var minimap_icon_size := 8.0
var minimap_tap_enabled := false
var map_expanded := false
var world_transform_active := false
var map_tile_draw_count := 0
var minimap_update_count := 0
var minimap_update_interval := 0.125
var last_minimap_update_time := -999.0
var phase6_metrics = null
var terrain_cache_key := ""
var terrain_draw_cache: Array = []
var terrain_cache_rebuild_count := 0
var background_grid_texture: ImageTexture = null
var background_grid_color := Color.TRANSPARENT

const ENEMY_COLORS = {
	"slime": Color(0.36, 0.92, 0.55),
	"bat": Color(0.92, 0.46, 1.0),
	"golem": Color(0.78, 0.58, 0.42),
	"ghost": Color(0.65, 0.82, 1.0, 0.84),
	"elite": Color(1.0, 0.66, 0.22),
	"splitter": Color(0.42, 0.98, 0.62),
	"splitter_child": Color(0.55, 1.0, 0.72),
	"charger": Color(1.0, 0.35, 0.28),
	"shooter": Color(0.95, 0.72, 0.32),
	"shield_bug": Color(0.55, 0.72, 0.92),
	"healer": Color(0.50, 1.0, 0.62),
	"crystal_golem": Color(0.46, 0.86, 1.0),
	"reaper": Color(0.80, 0.24, 0.92),
	"leech": Color(0.86, 0.12, 0.22),
	"bomber": Color(1.0, 0.45, 0.15),
	"crystal_sniper": Color(0.36, 0.92, 1.0),
	"swarm_mother": Color(0.56, 0.92, 0.38),
	"void_knight": Color(0.46, 0.28, 0.74),
	"curse_eye": Color(1.0, 0.24, 0.76)
}

func bind_state(value) -> void:
	state = value
	invalidate_static_cache("bind_state")
	minimap_render_cache.invalidate()
	queue_redraw()

func configure_visual_profile(profile_id: String, limits: Dictionary, qa_metrics_enabled: bool = false) -> void:
	visual_limits = limits.duplicate()
	visual_effect_budget_system.set_profile(profile_id)
	visual_effect_budget_system.configure_metrics(qa_metrics_enabled)
	minimap_render_cache.invalidate()

func configure_mobile(layout: Dictionary) -> void:
	camera_zoom = float(layout.get("camera_zoom", 1.0))
	minimap_rect = layout.get("minimap_rect", Rect2())
	expanded_map_rect = layout.get("expanded_map_rect", Rect2())
	minimap_opacity = float(layout.get("minimap_opacity", 0.76))
	minimap_icon_size = float(layout.get("minimap_icon", 8.0))
	minimap_tap_enabled = bool(layout.get("map_tap_expand", true))
	minimap_update_interval = 1.0 / maxf(1.0, float(layout.get("minimap_update_hz", 8)))
	invalidate_static_cache("configure_mobile")
	queue_redraw()

func set_map_expanded(value: bool) -> void:
	map_expanded = value
	queue_redraw()

func set_phase6_metrics(metrics) -> void:
	phase6_metrics = metrics

func invalidate_static_cache(reason: String = "") -> void:
	terrain_cache_key = ""
	terrain_draw_cache.clear()
	_phase6_metric("static_cache_invalidations")

func phase7_metrics_snapshot() -> Dictionary:
	return {
		"visual_budget": visual_effect_budget_system.snapshot(),
		"minimap_rebuilds": minimap_render_cache.rebuild_count,
		"weapon_style_cache": state.weapon_render_style_cache.stats() if state != null else {},
		"effect_commands": state.visual_effect_command_buffer.snapshot() if state != null else {},
	}

func update_adaptive_visual_quality(frame_time_ms: float, delta: float) -> int:
	visual_effect_budget_system.update_frame_pressure(frame_time_ms, delta)
	return visual_effect_budget_system.target_fps()

func _gui_input(event: InputEvent) -> void:
	var point := Vector2(-1, -1)
	if event is InputEventScreenTouch and event.pressed:
		point = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		point = event.position
	if point.x < 0.0 or not minimap_tap_enabled:
		return
	if (map_expanded and expanded_map_rect.has_point(point)) or (not map_expanded and minimap_rect.has_point(point)):
		minimap_tapped.emit()
		accept_event()

func _draw() -> void:
	if state == null:
		return
	_phase6_metric("arena_draw_calls")
	map_tile_draw_count = 0
	_draw_background()
	world_transform_active = true
	draw_set_transform(size * 0.5, 0.0, Vector2.ONE * camera_zoom)
	_draw_terrain_layout()
	_draw_danger_zones()
	_draw_boundary()
	_draw_crystal_walls()
	_draw_field_gimmicks()
	_draw_field_drops()
	_draw_field_equipment()
	_draw_gems()
	_draw_gem_ring_effects()
	_draw_chests()
	_draw_bombs()
	_draw_projectiles()
	_draw_enemy_attack_warnings()
	_draw_enemy_projectiles()
	_draw_enemies()
	_draw_orbits()
	_draw_player()
	_draw_effect_lines()
	_draw_hit_flashes()
	_draw_floating_texts()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	world_transform_active = false
	_draw_chest_indicators()
	_draw_navigation_indicators()
	_draw_minimap()
	_draw_screen_alerts()

func _draw_background() -> void:
	var biome = state.biome_system.current_biome(state)
	var biome_id = String(biome.get("id", "star_plain"))
	var bg = environment_visual_system.background_color(biome_id, Color(0.012, 0.014, 0.024))
	var grid = environment_visual_system.grid_color(biome_id, state.biome_system.grid_color(biome))
	var accent = environment_visual_system.accent_color(biome_id, state.biome_system.accent_color(biome))
	draw_rect(Rect2(Vector2.ZERO, size), bg, true)
	var camera = _camera_origin()
	var spacing = 48.0
	var start_x = -fmod(camera.x, spacing)
	var start_y = -fmod(camera.y, spacing)
	_ensure_background_grid_texture(Color(grid.r, grid.g, grid.b, 0.18), int(spacing))
	if background_grid_texture != null:
		draw_texture_rect(
			background_grid_texture,
			Rect2(Vector2(start_x, start_y), size + Vector2(spacing, spacing)),
			true
		)
	var background_particles := visual_effect_budget_system.select_visual_items(
		state.background_particles,
		state.camera_position,
		size / maxf(camera_zoom, 0.01),
		_visual_limit("background_particles", state.background_particles.size())
	)
	for particle in background_particles:
		var world_pos = particle.get("pos", Vector2.ZERO)
		if world_pos.distance_to(state.camera_position) > maxf(size.x, size.y) * 0.9:
			continue
		var p = world_to_screen(world_pos)
		var pulse = 0.45 + 0.35 * sin(state.elapsed_seconds + float(particle.get("phase", 0.0)))
		draw_circle(p, float(particle.get("radius", 1.5)) * (1.0 + pulse * 0.18), Color(accent.r, accent.g, accent.b, 0.16 + pulse * 0.12))
	if biome_id == "amethyst_forest":
		_draw_biome_spikes(camera, accent)
	elif biome_id == "red_mine":
		_draw_biome_ore(camera, accent)
	elif biome_id == "void_zone":
		_draw_biome_void(camera, accent)

func _draw_terrain_layout() -> void:
	var tile_size = float(state.map_data.get("tile_size", 64.0))
	var cache_key := _terrain_key(tile_size)
	if cache_key != terrain_cache_key:
		_rebuild_terrain_cache(tile_size, cache_key)
	for command in terrain_draw_cache:
		var world_rect: Rect2 = command.get("rect", Rect2())
		var screen_rect = Rect2(world_to_screen(world_rect.position), world_rect.size)
		_draw_environment_tile(screen_rect, String(command.get("biome", "star_plain")), String(command.get("surface", "floor")), command.get("fallback", Color.WHITE), command.get("border", Color.WHITE))
		map_tile_draw_count += 1
		_phase6_metric("static_tile_draw_submissions", 2)

func _rebuild_terrain_cache(tile_size: float, cache_key: String) -> void:
	terrain_cache_key = cache_key
	terrain_draw_cache.clear()
	terrain_cache_rebuild_count += 1
	_phase6_metric("static_terrain_rebuilds")
	var viewport_world = Rect2(_camera_origin() - Vector2(tile_size, tile_size), size / camera_zoom + Vector2(tile_size * 2.0, tile_size * 2.0))
	for corridor in state.map_data.get("corridors", []):
		for raw_key in corridor.get("cells", []):
			var world_rect = _cell_world_rect(String(raw_key), tile_size)
			if viewport_world.intersects(world_rect):
				var corridor_biome_id: String = state.biome_system.biome_id_for_position(state, world_rect.get_center())
				terrain_draw_cache.append({"rect": world_rect, "biome": corridor_biome_id, "surface": "floor", "fallback": Color(0.09, 0.15, 0.20, 0.96), "border": Color(0.24, 0.48, 0.58, 0.18)})
	for room in state.map_data.get("rooms", []):
		var terrain_id = String(room.get("terrain_id", "safe_room"))
		var terrain_data: Dictionary = state.terrain_type_defs.get(terrain_id, {})
		var color = _data_color(terrain_data, Color(0.12, 0.24, 0.32))
		for raw_key in room.get("floor_cells", []):
			var world_rect = _cell_world_rect(String(raw_key), tile_size)
			if viewport_world.intersects(world_rect):
				var room_biome_id: String = state.biome_system.biome_id_for_position(state, world_rect.get_center())
				var floor_color := environment_visual_system.terrain_color(room_biome_id, color, terrain_id)
				floor_color.a = 0.92
				terrain_draw_cache.append({"rect": world_rect, "biome": room_biome_id, "surface": "floor", "fallback": floor_color, "border": Color(color.r + 0.12, color.g + 0.12, color.b + 0.12, 0.16)})
	for raw_key in state.map_data.get("boundary_cells", []):
		var world_rect = _cell_world_rect(String(raw_key), tile_size)
		if viewport_world.intersects(world_rect):
			var boundary_biome_id: String = state.biome_system.biome_id_for_position(state, world_rect.get_center())
			terrain_draw_cache.append({"rect": world_rect, "biome": boundary_biome_id, "surface": "void", "fallback": Color(0.015, 0.012, 0.026, 1.0), "border": Color(0.30, 0.20, 0.42, 0.34)})

func _terrain_key(tile_size: float) -> String:
	var origin := _camera_origin()
	var cell := Vector2i(floori(origin.x / tile_size), floori(origin.y / tile_size))
	var renderer := String(ProjectSettings.get_setting("rendering/renderer/rendering_method", "gl_compatibility"))
	var quality_name := String(environment_visual_system.quality_config.get("default_profile", "medium"))
	var map_counts := "%d:%d:%d" % [
		(state.map_data.get("corridors", []) as Array).size(),
		(state.map_data.get("rooms", []) as Array).size(),
		(state.map_data.get("boundary_cells", []) as Array).size()
	]
	return "%s:%s:%s:%s:%s:%s:%s:%s:%s" % [
		str(cell),
		str(size),
		str(camera_zoom),
		str(state.map_seed),
		map_counts,
		renderer,
		quality_name,
		str(environment_visual_system.texture_enabled()),
		str(environment_visual_system.tile_texture_alpha())
	]

func _draw_environment_tile(screen_rect: Rect2, biome_id: String, surface: String, fallback_color: Color, border_color: Color) -> void:
	var surface_color := environment_visual_system.surface_color(biome_id, surface, fallback_color)
	surface_color.a = fallback_color.a
	if environment_visual_system.texture_enabled():
		var texture = environment_visual_system.surface_texture(biome_id, surface, "albedo")
		if texture != null:
			draw_texture_rect(texture, screen_rect, false, Color(1.0, 1.0, 1.0, environment_visual_system.tile_texture_alpha()))
			draw_rect(screen_rect, Color(surface_color.r, surface_color.g, surface_color.b, 0.18), true)
		else:
			draw_rect(screen_rect, surface_color, true)
	else:
		draw_rect(screen_rect, surface_color, true)
	draw_rect(screen_rect, border_color, false, 1.0)

func _draw_danger_zones() -> void:
	for zone in state.danger_zones:
		if not _is_world_visible(zone.get("position", Vector2.ZERO), float(zone.get("radius", 0.0))):
			continue
		var pos = world_to_screen(zone.get("position", Vector2.ZERO))
		var radius = float(zone.get("radius", 0.0))
		draw_circle(pos, radius, Color(0.76, 0.10, 0.34, 0.16))
		draw_arc(pos, radius, 0.0, TAU, 96, Color(1.0, 0.18, 0.42, 0.48), 3.0)
		draw_arc(pos, radius * 0.72, 0.0, TAU, 96, Color(0.62, 0.18, 0.95, 0.22), 2.0)

func _draw_boundary() -> void:
	var origin = world_to_screen(Vector2.ZERO)
	var rect = Rect2(origin, state.field_size)
	draw_rect(rect, Color(0.12, 0.03, 0.20, 0.92), false, 24.0)
	draw_rect(rect.grow(-14.0), Color(0.34, 0.84, 1.0, 0.82), false, 6.0)
	draw_rect(rect.grow(-28.0), Color(0.62, 0.38, 1.0, 0.35), false, 3.0)
	if state.boundary_touch_timer > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.42, 0.82, 1.0, state.boundary_touch_timer * 0.32), false, 18.0)

func _draw_crystal_walls() -> void:
	for wall in state.crystal_walls:
		if not _is_world_visible(wall.position, maxf(wall.size.x, wall.size.y)):
			continue
		var rect = wall.rect()
		var screen_rect = Rect2(world_to_screen(rect.position), rect.size)
		var hp_ratio = wall.hp_ratio()
		var fill = _wall_fill(wall)
		fill.a = 0.32 + 0.16 * sin(wall.pulse * 3.0)
		var edge = _wall_edge(wall)
		draw_rect(screen_rect, fill, true)
		draw_rect(screen_rect, edge, false, 3.0)
		draw_line(screen_rect.position + Vector2(8, 8), screen_rect.position + screen_rect.size - Vector2(8, 8), Color(0.92, 0.98, 1.0, 0.30), 2.0)
		var bar_pos = screen_rect.position + Vector2(8, -10)
		var bar_size = Vector2(maxf(36.0, screen_rect.size.x - 16.0), 5)
		draw_rect(Rect2(bar_pos, bar_size), Color(0.04, 0.05, 0.08, 0.9), true)
		draw_rect(Rect2(bar_pos, Vector2(bar_size.x * hp_ratio, bar_size.y)), Color(0.42, 0.92, 1.0), true)

func _draw_field_drops() -> void:
	for drop in state.field_drops:
		if bool(drop.get("collected", false)):
			continue
		if not _is_world_visible(drop.get("position", Vector2.ZERO), 36.0):
			continue
		var pos = world_to_screen(drop.get("position", Vector2.ZERO))
		var color = _data_color(drop, Color(1.0, 1.0, 1.0))
		var locked = state.elapsed_seconds < float(drop.get("unlock_seconds", 0.0))
		var alpha = 0.36 if locked else 0.90
		draw_circle(pos, 22.0, Color(color.r, color.g, color.b, 0.16 + alpha * 0.18))
		draw_polygon(PackedVector2Array([pos + Vector2(0, -15), pos + Vector2(14, 0), pos + Vector2(0, 15), pos + Vector2(-14, 0)]), PackedColorArray([Color.WHITE, Color(color.r, color.g, color.b, alpha), Color(color.r, color.g, color.b, alpha * 0.9), Color(color.r, color.g, color.b, alpha)]))
		draw_arc(pos, 26.0 + 3.0 * sin(state.elapsed_seconds * 3.0), 0.0, TAU, 36, Color(color.r, color.g, color.b, alpha * 0.65), 2.0)

func _draw_field_equipment() -> void:
	for equipment in state.field_equipment:
		if bool(equipment.get("collected", false)):
			continue
		if not _is_world_visible(equipment.get("position", Vector2.ZERO), 42.0):
			continue
		var pos = world_to_screen(equipment.get("position", Vector2.ZERO))
		var color = _data_color(equipment, Color(0.72, 0.92, 1.0))
		var rect := Rect2(pos - Vector2(16, 16), Vector2(32, 32))
		draw_rect(rect, Color(color.r, color.g, color.b, 0.24), true)
		draw_rect(rect, Color(color.r, color.g, color.b, 0.92), false, 3.0)
		draw_circle(pos, 6.0, Color(1.0, 1.0, 1.0, 0.92))
		draw_arc(pos, 26.0 + 2.0 * sin(state.elapsed_seconds * 2.5), 0.0, TAU, 28, Color(color.r, color.g, color.b, 0.58), 2.0)

func _draw_field_gimmicks() -> void:
	for gimmick in state.field_gimmicks:
		if bool(gimmick.get("destroyed", false)):
			continue
		if not _is_world_visible(gimmick.get("position", Vector2.ZERO), 48.0):
			continue
		var pos = world_to_screen(gimmick.get("position", Vector2.ZERO))
		var color = _data_color(gimmick, Color(0.8, 0.9, 1.0))
		var id = String(gimmick.get("id", ""))
		match id:
			"reflect_crystal":
				draw_polygon(PackedVector2Array([pos + Vector2(0, -26), pos + Vector2(22, -5), pos + Vector2(12, 24), pos + Vector2(-18, 20), pos + Vector2(-24, -8)]), PackedColorArray([Color.WHITE, color, color.darkened(0.1), color.darkened(0.18), color]))
				draw_arc(pos, 34.0, -0.8, 0.8, 24, Color(color.r, color.g, color.b, 0.55), 3.0)
			"lightning_crystal":
				draw_circle(pos, 24.0, Color(color.r, color.g, color.b, 0.22))
				draw_line(pos + Vector2(-18, 12), pos + Vector2(-2, -6), color, 4.0)
				draw_line(pos + Vector2(-2, -6), pos + Vector2(12, -2), Color.WHITE, 4.0)
				draw_line(pos + Vector2(12, -2), pos + Vector2(0, 18), color, 4.0)
			"explosive_vein":
				draw_rect(Rect2(pos - Vector2(26, 10), Vector2(52, 20)), Color(color.r, color.g, color.b, 0.28), true)
				draw_arc(pos, 42.0, 0.0, TAU, 32, color, 2.0)
			"healing_spring":
				draw_circle(pos, 26.0, Color(color.r, color.g, color.b, 0.20))
				draw_arc(pos, 34.0, 0.0, TAU, 48, color, 3.0)
				draw_line(pos + Vector2(-10, 0), pos + Vector2(10, 0), Color.WHITE, 3.0)
				draw_line(pos + Vector2(0, -10), pos + Vector2(0, 10), Color.WHITE, 3.0)
			"spawn_rift":
				draw_arc(pos, 30.0 + 4.0 * sin(state.elapsed_seconds * 4.0), 0.0, TAU, 40, color, 4.0)
				draw_circle(pos, 14.0, Color(color.r, color.g, color.b, 0.28))
			"sealed_chest_pillar":
				draw_rect(Rect2(pos - Vector2(18, 32), Vector2(36, 64)), Color(color.r, color.g, color.b, 0.22), true)
				draw_rect(Rect2(pos - Vector2(18, 32), Vector2(36, 64)), color, false, 3.0)
			_:
				draw_circle(pos, 22.0, color)

func _draw_player() -> void:
	var pos = world_to_screen(state.player_position)
	var blink = state.invincible_timer > 0.0 and int(state.invincible_timer * 20.0) % 2 == 0
	if blink:
		return
	_draw_character_avatar(pos, state.selected_character_id)
	draw_arc(pos, 30.0 + 3.0 * sin(state.elapsed_seconds * 5.0), 0.0, TAU, 48, Color(0.62, 0.95, 1.0, 0.7), 3.0)
	draw_arc(pos, state.get_magnet_radius(), 0.0, TAU, 64, Color(0.45, 0.85, 1.0, 0.16), 2.0)

func _draw_character_avatar(pos: Vector2, character_id: String) -> void:
	var colors = _character_colors(character_id)
	var primary: Color = colors.get("primary", Color(0.98, 0.88, 0.34))
	var accent: Color = colors.get("accent", Color(0.62, 0.95, 1.0))
	var scale = 1.0
	if character_id == "atlas" or character_id == "gantz":
		scale = 1.16
	elif character_id == "kaede" or character_id == "ghost":
		scale = 0.90
	draw_circle(pos, 28.0 * scale, Color(accent.r, accent.g, accent.b, 0.18))
	match character_id:
		"kaede", "nameless_reaper":
			draw_polygon(PackedVector2Array([pos + Vector2(0, -27 * scale), pos + Vector2(19 * scale, 18 * scale), pos + Vector2(-19 * scale, 18 * scale)]), PackedColorArray([primary, primary.darkened(0.12), primary.darkened(0.20)]))
			draw_arc(pos + Vector2(8, -4), 30.0, -0.8, 0.8, 24, accent, 4.0)
		"atlas", "gantz":
			draw_rect(Rect2(pos - Vector2(24, 24) * scale, Vector2(48, 48) * scale), primary, true)
			draw_rect(Rect2(pos - Vector2(24, 24) * scale, Vector2(48, 48) * scale), accent, false, 3.0)
			if character_id == "gantz":
				draw_line(pos + Vector2(14, -16), pos + Vector2(36, -30), accent, 6.0)
		"mio", "sera", "ghost":
			draw_circle(pos, 23.0 * scale, Color(primary.r, primary.g, primary.b, 0.82))
			draw_polygon(PackedVector2Array([pos + Vector2(0, -34), pos + Vector2(8, -18), pos + Vector2(-8, -18)]), PackedColorArray([accent, accent.lightened(0.2), accent]))
		"rai", "zero":
			draw_circle(pos, 22.0 * scale, primary)
			draw_line(pos + Vector2(-26, 16), pos + Vector2(26, -16), accent, 4.0)
			draw_arc(pos, 30.0, -0.5, 0.8, 18, accent, 3.0)
		"bomb", "nero", "lily", "rei", "collector":
			draw_circle(pos, 23.0 * scale, primary)
			draw_circle(pos + Vector2(-18, 14), 6.0, accent)
			draw_circle(pos + Vector2(18, 14), 6.0, accent)
		_:
			draw_circle(pos, 23.0 * scale, primary)
			draw_rect(Rect2(pos + Vector2(-16, -30), Vector2(32, 12)), accent, true)
	draw_circle(pos + Vector2(-7, -5), 2.6, Color(0.02, 0.04, 0.08))
	draw_circle(pos + Vector2(7, -5), 2.6, Color(0.02, 0.04, 0.08))
	draw_circle(pos, 9.0, Color(accent.r, accent.g, accent.b, 0.50))

func _character_colors(character_id: String) -> Dictionary:
	match character_id:
		"mio":
			return {"primary": Color(0.78, 0.94, 1.0), "accent": Color(0.42, 0.84, 1.0)}
		"rai":
			return {"primary": Color(0.20, 0.20, 0.32), "accent": Color(1.0, 0.82, 0.22)}
		"bomb":
			return {"primary": Color(0.66, 0.22, 0.18), "accent": Color(1.0, 0.44, 0.16)}
		"gantz":
			return {"primary": Color(0.24, 0.30, 0.36), "accent": Color(0.52, 0.92, 1.0)}
		"kaede":
			return {"primary": Color(0.06, 0.16, 0.12), "accent": Color(0.34, 1.0, 0.50)}
		"sera":
			return {"primary": Color(0.16, 0.12, 0.34), "accent": Color(1.0, 0.82, 1.0)}
		"rei":
			return {"primary": Color(0.34, 0.60, 0.74), "accent": Color(0.86, 0.96, 1.0)}
		"atlas":
			return {"primary": Color(0.30, 0.38, 0.52), "accent": Color(0.76, 0.86, 1.0)}
		"nero":
			return {"primary": Color(0.10, 0.04, 0.16), "accent": Color(0.74, 0.34, 1.0)}
		"lily":
			return {"primary": Color(0.90, 0.42, 0.74), "accent": Color(1.0, 0.82, 0.22)}
		"zero":
			return {"primary": Color(0.90, 0.92, 0.96), "accent": Color(0.58, 0.94, 1.0)}
		"ghost":
			return {"primary": Color(0.60, 0.94, 1.0, 0.64), "accent": Color(0.74, 0.34, 1.0)}
		"collector":
			return {"primary": Color(1.0, 0.82, 0.25), "accent": Color(1.0, 0.96, 0.58)}
		"nameless_reaper":
			return {"primary": Color(0.03, 0.03, 0.07), "accent": Color(1.0, 0.12, 0.22)}
	return {"primary": Color(0.98, 0.88, 0.34), "accent": Color(0.42, 0.86, 1.0)}

func _draw_enemies() -> void:
	for enemy in state.enemies:
		if not _is_world_visible(enemy.position, enemy.radius + 20.0):
			continue
		_phase6_metric("dynamic_enemy_draws")
		var pos = world_to_screen(enemy.position)
		var color = Color(1.0, 0.35, 0.20) if enemy.boss else ENEMY_COLORS.get(enemy.type, Color.WHITE)
		if enemy.boss:
			draw_circle(pos, enemy.radius + 10.0, Color(1.0, 0.20, 0.20, 0.22))
			draw_arc(pos, enemy.radius + 13.0, 0.0, TAU, 64, Color(1.0, 0.72, 0.26), 4.0)
			draw_rect(Rect2(pos + Vector2(-enemy.radius, -enemy.radius), Vector2(enemy.radius * 2.0, enemy.radius * 2.0)), color, true)
		else:
			match enemy.type:
				"slime", "splitter", "splitter_child":
					draw_circle(pos, enemy.radius, color)
					draw_circle(pos + Vector2(-6, -4), 2.4, Color(0.02, 0.04, 0.03))
					draw_circle(pos + Vector2(6, -4), 2.4, Color(0.02, 0.04, 0.03))
				"bat":
					draw_polygon(PackedVector2Array([pos + Vector2(0, -15), pos + Vector2(24, 8), pos + Vector2(6, 17), pos, pos + Vector2(-6, 17), pos + Vector2(-24, 8)]), PackedColorArray([color, color, color.darkened(0.2), color, color.darkened(0.2), color]))
				"golem", "crystal_golem", "shield_bug":
					draw_rect(Rect2(pos + Vector2(-enemy.radius, -enemy.radius), Vector2(enemy.radius * 2.0, enemy.radius * 2.0)), color, true)
					draw_rect(Rect2(pos + Vector2(-enemy.radius, -enemy.radius), Vector2(enemy.radius * 2.0, enemy.radius * 2.0)), Color(0.12, 0.10, 0.18), false, 2.0)
					if enemy.type == "shield_bug":
						draw_arc(pos, enemy.radius + 8.0, -0.2, PI + 0.2, 32, Color(0.88, 0.96, 1.0), 4.0)
				"ghost":
					draw_circle(pos, enemy.radius, color)
					draw_rect(Rect2(pos + Vector2(-enemy.radius, 0), Vector2(enemy.radius * 2.0, enemy.radius)), color, true)
				"elite":
					draw_circle(pos, enemy.radius + 5.0, Color(1.0, 0.86, 0.28, 0.25))
					draw_rect(Rect2(pos + Vector2(-enemy.radius, -enemy.radius), Vector2(enemy.radius * 2.0, enemy.radius * 2.0)), color, true)
					draw_arc(pos, enemy.radius + 8.0, 0.0, TAU, 40, Color(1.0, 0.95, 0.45), 3.0)
				"charger":
					draw_polygon(PackedVector2Array([pos + Vector2(0, -enemy.radius), pos + Vector2(enemy.radius + 9, 0), pos + Vector2(0, enemy.radius), pos + Vector2(-enemy.radius * 0.7, 0)]), PackedColorArray([color, color.darkened(0.08), color, color.darkened(0.22)]))
				"shooter":
					draw_circle(pos, enemy.radius, color)
					draw_line(pos, pos + (state.player_position - enemy.position).normalized() * 26.0, Color(1.0, 0.96, 0.52), 3.0)
				"healer":
					draw_circle(pos, enemy.radius, color)
					draw_line(pos + Vector2(-8, 0), pos + Vector2(8, 0), Color.WHITE, 3.0)
					draw_line(pos + Vector2(0, -8), pos + Vector2(0, 8), Color.WHITE, 3.0)
				"reaper":
					draw_circle(pos, enemy.radius, color)
					draw_line(pos + Vector2(-enemy.radius, -enemy.radius), pos + Vector2(enemy.radius, enemy.radius), Color(0.98, 0.92, 1.0), 3.0)
				_:
					draw_circle(pos, enemy.radius, color)
		var hp_ratio = clampf(float(enemy.hp) / float(enemy.max_hp), 0.0, 1.0)
		var width = 54.0 if enemy.boss else 36.0
		draw_rect(Rect2(pos + Vector2(-width * 0.5, -enemy.radius - 12), Vector2(width, 5)), Color(0.05, 0.06, 0.08), true)
		draw_rect(Rect2(pos + Vector2(-width * 0.5, -enemy.radius - 12), Vector2(width * hp_ratio, 5)), Color(1.0, 0.25, 0.22), true)
		if enemy.shock_stacks > 0:
			var shock_color = Color(0.62, 0.82, 1.0, 0.55 + 0.12 * float(enemy.shock_stacks))
			draw_circle(pos + Vector2(enemy.radius * 0.55, -enemy.radius * 0.65), 5.0 + float(enemy.shock_stacks), shock_color)
			draw_line(pos + Vector2(enemy.radius * 0.55, -enemy.radius * 0.65), pos + Vector2(enemy.radius * 0.30, -enemy.radius * 0.15), Color.WHITE, 2.0)
		if enemy.poison_timer > 0.0:
			draw_circle(pos + Vector2(-enemy.radius * 0.55, -enemy.radius * 0.65), 5.0, Color(0.48, 1.0, 0.34, 0.72))

func _draw_gems() -> void:
	var rendered_gems := visual_effect_budget_system.select_visual_items(
		state.gems,
		state.camera_position,
		size / maxf(camera_zoom, 0.01),
		_visual_limit("gems", state.gems.size()),
		32.0
	)
	for gem in rendered_gems:
		if not _is_world_visible(gem.position, 16.0):
			continue
		_phase6_metric("dynamic_gem_draws")
		var pos = world_to_screen(gem.position)
		var color = Color(0.35, 0.86, 1.0) if gem.value < 12 else Color(0.75, 0.42, 1.0)
		draw_polygon(PackedVector2Array([pos + Vector2(0, -8), pos + Vector2(7, 0), pos + Vector2(0, 8), pos + Vector2(-7, 0)]), PackedColorArray([Color.WHITE, color, color.darkened(0.1), color]))
		draw_circle(pos, 12.0, Color(color.r, color.g, color.b, 0.12))

func _draw_gem_ring_effects() -> void:
	for effect in state.gem_ring_effects:
		var duration = maxf(0.1, float(effect.get("duration", 0.78)))
		var t = clampf((state.elapsed_seconds - float(effect.get("start_time", state.elapsed_seconds))) / duration, 0.0, 1.0)
		var collapse_start = clampf(float(effect.get("collapse_start", 0.48)), 0.05, 0.90)
		var collapse_t = clampf((t - collapse_start) / maxf(0.01, 1.0 - collapse_start), 0.0, 1.0)
		var ring_count = maxi(1, int(effect.get("ring_count", 1)))
		var proxy_count = maxi(1, int(effect.get("proxy_nodes", 1)))
		var center = world_to_screen(state.player_position)
		var source = String(effect.get("source", "magnet"))
		var color = Color(0.42, 0.95, 1.0)
		if source == "drone":
			color = Color(0.74, 0.58, 1.0)
		elif source == "resonance_magnet_core":
			color = Color(0.58, 1.0, 0.82)
		var alpha = 0.90 * (1.0 - maxf(0.0, t - 0.72) / 0.28)
		for ring in range(ring_count):
			var radius = lerpf(58.0 + float(ring) * 28.0, 6.0 + float(ring) * 2.0, collapse_t)
			draw_arc(center, radius, 0.0, TAU, _arc_segments(radius), Color(color.r, color.g, color.b, alpha * 0.30), 2.0)
		var per_ring = maxi(1, int(ceil(float(proxy_count) / float(ring_count))))
		for i in range(proxy_count):
			var ring_index = int(floor(float(i) / float(per_ring)))
			var ring_slot = i % per_ring
			var radius = lerpf(58.0 + float(ring_index) * 28.0, 5.0, collapse_t)
			var angle = TAU * float(ring_slot) / float(per_ring) + state.elapsed_seconds * 5.0 + float(ring_index) * 0.72
			var pos = center + Vector2(cos(angle), sin(angle)) * radius
			var size = lerpf(5.5, 2.0, collapse_t)
			draw_polygon(PackedVector2Array([pos + Vector2(0, -size), pos + Vector2(size, 0), pos + Vector2(0, size), pos + Vector2(-size, 0)]), PackedColorArray([Color.WHITE, Color(color.r, color.g, color.b, alpha), Color(color.r, color.g, color.b, alpha * 0.85), Color(color.r, color.g, color.b, alpha)]))

func _draw_chests() -> void:
	for chest in state.chests:
		if not _is_world_visible(chest.position, 28.0):
			continue
		var pos = world_to_screen(chest.position)
		var fill = _chest_color(String(chest.rarity))
		draw_rect(Rect2(pos + Vector2(-17, -12), Vector2(34, 24)), fill.darkened(0.25), true)
		draw_rect(Rect2(pos + Vector2(-17, -12), Vector2(34, 24)), fill, false, 2.0)
		draw_line(pos + Vector2(-15, -1), pos + Vector2(15, -1), fill, 2.0)
		var ttl_ratio = clampf(1.0 - float(chest.age) / maxf(1.0, float(chest.ttl)), 0.0, 1.0)
		draw_rect(Rect2(pos + Vector2(-17, 16), Vector2(34.0 * ttl_ratio, 4)), fill, true)

func _draw_projectiles() -> void:
	var rendered_projectiles := projectile_render_selection_system.select(
		state.projectiles,
		state.camera_position,
		size / maxf(camera_zoom, 0.01),
		_visual_limit("projectiles", state.projectiles.size())
	)
	for projectile in rendered_projectiles:
		if not _is_world_visible(projectile.position, maxf(projectile.radius, projectile.splash_radius)):
			continue
		_phase6_metric("dynamic_projectile_draws")
		var pos = world_to_screen(projectile.position)
		var effect: Dictionary = state.weapon_effect(projectile.kind)
		var color = _effect_color(effect, Color(1.0, 0.88, 0.38))
		var shape = String(effect.get("shape", "orb"))
		if bool(effect.get("trail", false)) and projectile.velocity.length() > 0.1:
			var tail = -projectile.velocity.normalized() * (36.0 if projectile.evolved else 22.0)
			draw_line(pos + tail, pos, Color(color.r, color.g, color.b, 0.34), 5.0 if projectile.evolved else 3.0)
		if projectile.kind == "black_hole":
			draw_circle(pos, projectile.splash_radius, Color(0.18, 0.08, 0.28, 0.22))
			draw_arc(pos, projectile.splash_radius, 0.0, TAU, _arc_segments(projectile.splash_radius), Color(0.74, 0.38, 1.0, 0.52), 3.0)
			color = _effect_color(effect, Color(0.80, 0.55, 1.0))
		elif projectile.evolved:
			color = _effect_color(effect, _evolved_projectile_color(projectile.kind))
		elif projectile.kind == "blade_fan":
			color = _effect_color(effect, Color(0.90, 0.95, 1.0))
		elif projectile.kind == "drone_bit":
			color = _effect_color(effect, Color(0.45, 1.0, 0.90))
		elif projectile.kind in ["rune_gate", "burning_afterglow", "comet_crater"]:
			draw_arc(pos, projectile.splash_radius, 0.0, TAU, _arc_segments(projectile.splash_radius), Color(1.0, 0.42, 0.22, 0.26), 3.0)
			color = _effect_color(effect, Color(1.0, 0.52, 0.24))
		elif projectile.kind == "mirror_shard":
			color = _effect_color(effect, Color(0.78, 0.94, 1.0))
		elif projectile.kind == "gem_turret":
			color = _effect_color(effect, Color(0.42, 1.0, 0.82))
		_draw_projectile_shape(pos, projectile.radius, color, shape, projectile.evolved)

func _draw_enemy_projectiles() -> void:
	for shot in state.enemy_projectiles:
		if not _is_world_visible(shot.get("position", Vector2.ZERO), float(shot.get("radius", 7.0)) + 10.0):
			continue
		_phase6_metric("dynamic_projectile_draws")
		var pos = world_to_screen(shot.get("position", Vector2.ZERO))
		var radius = float(shot.get("radius", 7.0))
		var color = Color(1.0, 0.25, 0.34)
		if String(shot.get("kind", "")) == "crystal_shard":
			color = Color(0.44, 0.90, 1.0)
		elif String(shot.get("kind", "")) == "doom_core":
			color = Color(1.0, 0.25, 0.95)
		draw_circle(pos, radius + 8.0, Color(color.r, color.g, color.b, 0.20))
		draw_circle(pos, radius, color)

func _draw_enemy_attack_warnings() -> void:
	for warning in state.enemy_attack_warnings:
		if not _is_world_visible(warning.get("position", Vector2.ZERO), float(warning.get("radius", 52.0))):
			continue
		var kind = String(warning.get("kind", ""))
		var pos = world_to_screen(warning.get("position", Vector2.ZERO))
		var target = world_to_screen(warning.get("target", warning.get("position", Vector2.ZERO)))
		var life = clampf(float(warning.get("life", 0.0)), 0.0, 1.5)
		var pulse = 0.45 + 0.35 * sin(state.elapsed_seconds * 18.0)
		if kind in ["dash", "line"]:
			draw_line(pos, target, Color(1.0, 0.22, 0.18, 0.46 + pulse * 0.28), 5.0)
			draw_circle(target, float(warning.get("radius", 20.0)), Color(1.0, 0.18, 0.12, 0.16))
		else:
			var radius = float(warning.get("radius", 52.0))
			draw_circle(pos, radius, Color(1.0, 0.24, 0.18, 0.10 + pulse * 0.12))
			draw_arc(pos, radius, 0.0, TAU, _arc_segments(radius, true), Color(1.0, 0.36, 0.22, 0.72), 4.0)
			draw_arc(pos, radius * clampf(life, 0.15, 1.0), 0.0, TAU, _arc_segments(radius, true), Color(0.62, 0.94, 1.0, 0.78), 2.0)

func _draw_bombs() -> void:
	for bomb in state.bombs:
		if not _is_world_visible(bomb.position, bomb.splash_radius):
			continue
		var pos = world_to_screen(bomb.position)
		var color = Color(0.55, 0.90, 1.0) if bomb.kind == "crystal_mine" else Color(1.0, 0.40, 0.18)
		if bomb.kind in ["comet_staff", "meteor_rain"]:
			color = Color(1.0, 0.72, 0.28)
		draw_circle(pos, 11.0, color)
		draw_arc(pos, bomb.splash_radius, 0.0, TAU, _arc_segments(bomb.splash_radius), Color(color.r, color.g, color.b, 0.18), 2.0)

func _draw_orbits() -> void:
	if state == null or not state.weapons.has("ice_orbit"):
		return
	var level = int(state.weapons.get("ice_orbit", 1))
	var evolved = state.is_weapon_evolved("ice_orbit")
	var count = 1 + int(floor(float(level) / 3.0)) + (2 if evolved else 0)
	var radius = (78.0 + float(level) * 8.0) * state.get_area_multiplier() * (1.28 if evolved else 1.0)
	var center = world_to_screen(state.player_position)
	var effect: Dictionary = state.weapon_effect("ice_orbit")
	var color = _effect_color(effect, Color(0.32, 0.82, 1.0))
	draw_arc(center, radius, 0.0, TAU, _arc_segments(radius), Color(color.r, color.g, color.b, 0.20), 2.0)
	if evolved:
		draw_arc(center, radius * 0.72, 0.0, TAU, _arc_segments(radius * 0.72), Color(0.78, 0.94, 1.0, 0.24), 3.0)
		draw_arc(center, radius * 1.28, 0.0, TAU, _arc_segments(radius * 1.28), Color(color.r, color.g, color.b, 0.18), 3.0)
	for i in range(count):
		var angle = state.orbit_angle + TAU * float(i) / float(count)
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		draw_circle(pos, 14.0 if not evolved else 17.0, color)

func _draw_hit_flashes() -> void:
	var flashes := visual_effect_budget_system.select_visual_items(
		state.hit_flashes,
		state.camera_position,
		size / maxf(camera_zoom, 0.01),
		_visual_limit("effects", state.hit_flashes.size())
	)
	for flash in flashes:
		if not _is_world_visible(flash.get("pos", state.player_position), float(flash.get("radius", 32.0))):
			continue
		var pos = world_to_screen(flash.get("pos", state.player_position))
		var life = float(flash.get("life", 0.1))
		var effect = state.weapon_effect(String(flash.get("source", "")))
		var color = _effect_color(effect, Color(1.0, 0.92, 0.44))
		var radius = float(flash.get("radius", 22.0 * life * 5.0))
		if String(flash.get("source", "")) in ["soul_scythe", "blade_fan"]:
			var direction: Vector2 = flash.get("direction", Vector2.RIGHT)
			draw_arc(pos, radius * 0.55, direction.angle() - 0.95, direction.angle() + 0.95, 28, Color(color.r, color.g, color.b, 0.56), 6.0)
			draw_arc(pos, radius * 0.72, direction.angle() - 0.65, direction.angle() + 0.65, 24, Color(1.0, 1.0, 1.0, 0.42), 3.0)
		elif String(flash.get("source", "")) in ["shock_stack", "thunder_chain"]:
			draw_arc(pos, radius, 0.0, TAU, _arc_segments(radius), Color(0.78, 0.70, 1.0, life * 1.8), 4.0)
			draw_circle(pos, 12.0 * life * 5.0, Color(1.0, 1.0, 1.0, life))
		else:
			draw_circle(pos, radius, Color(color.r, color.g, color.b, life * 2.4))
		if bool(effect.get("trail", false)):
			var trail_radius: float = 28.0 * life * 5.0
			draw_arc(pos, trail_radius, 0.0, TAU, _arc_segments(trail_radius), Color(color.r, color.g, color.b, life), 2.0)

func _draw_effect_lines() -> void:
	var lines := visual_effect_budget_system.select_visual_items(
		state.effect_lines,
		state.camera_position,
		size / maxf(camera_zoom, 0.01),
		_visual_limit("effects", state.effect_lines.size())
	)
	for line in lines:
		if not _is_world_visible(line.get("start", state.player_position), 32.0) and not _is_world_visible(line.get("end", state.player_position), 32.0):
			continue
		var start = world_to_screen(line.get("start", state.player_position))
		var end = world_to_screen(line.get("end", state.player_position))
		var life = float(line.get("life", 0.1))
		var source = String(line.get("source", ""))
		var effect = state.weapon_effect(source)
		var color = _effect_color(effect, Color(0.78, 0.70, 1.0))
		var width = 7.0 if bool(line.get("evolved", false)) else 4.0
		if source == "thunder_chain":
			var segments = 5
			var prev = start
			for i in range(1, segments + 1):
				var t = float(i) / float(segments)
				var p = start.lerp(end, t)
				var normal = (end - start).orthogonal().normalized()
				p += normal * sin(float(i) * 1.7 + state.elapsed_seconds * 18.0) * (7.0 if bool(line.get("evolved", false)) else 4.0)
				draw_line(prev, p, Color(color.r, color.g, color.b, clampf(life * 5.0, 0.0, 0.95)), width)
				draw_line(prev, p, Color.WHITE, clampf(width * 0.36, 1.0, 3.0))
				prev = p
			draw_circle(end, 7.0 + float(line.get("index", 0)), Color(1.0, 1.0, 1.0, 0.68))
		elif source == "laser_lance":
			draw_line(start, end, Color(color.r, color.g, color.b, 0.20), width * 3.0)
			draw_line(start, end, Color(color.r, color.g, color.b, 0.75), width)
			draw_line(start, end, Color.WHITE, maxf(1.0, width * 0.35))

func _draw_floating_texts() -> void:
	var font = get_theme_default_font()
	var texts := visual_effect_budget_system.select_visual_items(
		state.floating_texts,
		state.camera_position,
		size / maxf(camera_zoom, 0.01),
		_visual_limit("damage_numbers", state.floating_texts.size())
	)
	for text_data in texts:
		if not _is_world_visible(text_data.get("pos", state.player_position), 60.0):
			continue
		var pos = world_to_screen(text_data.get("pos", state.player_position))
		var life = float(text_data.get("life", 1.0))
		var color = text_data.get("color", Color.WHITE)
		var alpha = clampf(life, 0.0, 1.0)
		draw_string(font, pos + Vector2(-55, -28.0 * (1.0 - life)), String(text_data.get("text", "")), HORIZONTAL_ALIGNMENT_CENTER, 110.0, 20, Color(color.r, color.g, color.b, alpha))

func _draw_screen_alerts() -> void:
	if state.damage_flash_timer > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.04, 0.02, state.damage_flash_timer * 1.4), true)
	if state.hp_ratio() <= 0.10:
		var pulse = 0.28 + 0.22 * abs(sin(state.elapsed_seconds * 8.0))
		draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.02, 0.02, pulse), false, 22.0)
	if state.gem_fever_timer > 0.0:
		draw_string(get_theme_default_font(), Vector2(0, size.y * 0.18), "ジェムフィーバー！", HORIZONTAL_ALIGNMENT_CENTER, size.x, 34, Color(0.40, 0.95, 1.0, 0.82))
	if state.crystal_overdrive_timer > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.42, 0.24, 1.0, 0.08), true)

func world_to_screen(world_pos: Vector2) -> Vector2:
	if world_transform_active:
		return world_pos - state.camera_position
	return (world_pos - _camera_origin()) * camera_zoom

func _camera_origin() -> Vector2:
	var visible_world := size / camera_zoom
	var origin = state.camera_position - visible_world * 0.5
	origin.x = clampf(origin.x, 0.0, maxf(0.0, state.field_size.x - visible_world.x))
	origin.y = clampf(origin.y, 0.0, maxf(0.0, state.field_size.y - visible_world.y))
	return origin

func _is_world_visible(world_pos: Vector2, margin: float = 64.0) -> bool:
	var visible_world := size / maxf(camera_zoom, 0.01)
	return Rect2(_camera_origin(), visible_world).grow(margin).has_point(world_pos)

func _wall_fill(wall) -> Color:
	match wall.wall_type:
		"small_crystal":
			return Color(0.42, 0.88, 1.0, 0.40)
		"rich_crystal":
			return Color(0.38, 1.0, 0.82, 0.42)
		"cursed_crystal":
			return Color(0.82, 0.22, 1.0, 0.44)
	return Color(0.34, 0.76, 1.0, 0.40)

func _wall_edge(wall) -> Color:
	match wall.wall_type:
		"small_crystal":
			return Color(0.70, 0.95, 1.0, 0.88)
		"rich_crystal":
			return Color(0.95, 0.92, 0.44, 0.92)
		"cursed_crystal":
			return Color(1.0, 0.22, 0.80, 0.92)
	return Color(0.66, 0.42, 1.0, 0.86)

func _evolved_projectile_color(kind: String) -> Color:
	match kind:
		"magic_bolt":
			return Color(1.0, 0.94, 0.56)
		"blade_fan":
			return Color(0.55, 1.0, 0.72)
		"laser_lance":
			return Color(0.95, 0.55, 1.0)
		"poison_mist":
			return Color(0.55, 1.0, 0.36)
		"drone_bit":
			return Color(1.0, 0.82, 0.32)
	return Color(0.85, 0.95, 1.0)

func _draw_chest_indicators() -> void:
	var font = get_theme_default_font()
	for chest in state.chests:
		var screen_pos = world_to_screen(chest.position)
		if Rect2(Vector2(28, 28), size - Vector2(56, 56)).has_point(screen_pos):
			continue
		var center = size * 0.5
		var direction = (screen_pos - center).normalized()
		var edge = center + direction * (minf(size.x, size.y) * 0.44)
		edge.x = clampf(edge.x, 36.0, size.x - 36.0)
		edge.y = clampf(edge.y, 36.0, size.y - 36.0)
		var meters = int(round(chest.position.distance_to(state.player_position) / 10.0))
		var color = _chest_color(String(chest.rarity))
		var remain = int(ceil(maxf(0.0, float(chest.ttl) - float(chest.age))))
		draw_circle(edge, 24.0, Color(color.r, color.g, color.b, 0.88))
		draw_string(font, edge + Vector2(-70, -34), "%s -> %dm / %ds" % [_chest_label(String(chest.rarity)), meters, remain], HORIZONTAL_ALIGNMENT_CENTER, 140.0, 18, color.lightened(0.25))

func _draw_navigation_indicators() -> void:
	var targets = _navigation_indicator_targets()
	var font = get_theme_default_font()
	for i in range(targets.size()):
		var target = targets[i]
		var world_pos: Vector2 = target.get("pos", state.player_position)
		var screen_pos = world_to_screen(world_pos)
		if Rect2(Vector2(48, 48), size - Vector2(96, 96)).has_point(screen_pos):
			continue
		var center = size * 0.5
		var direction = (screen_pos - center).normalized()
		if direction == Vector2.ZERO:
			continue
		var edge = center + direction * (minf(size.x, size.y) * 0.42)
		edge.x = clampf(edge.x, 64.0, size.x - 64.0)
		edge.y = clampf(edge.y, 82.0 + float(i) * 28.0, size.y - 72.0)
		var color: Color = target.get("color", Color.WHITE)
		var label = String(target.get("label", "目標"))
		var meters = int(round(float(target.get("distance", world_pos.distance_to(state.player_position))) / 10.0))
		var left = direction.rotated(2.55) * 12.0
		var right = direction.rotated(-2.55) * 12.0
		draw_polygon(PackedVector2Array([edge + direction * 18.0, edge + left, edge + right]), PackedColorArray([color.lightened(0.2), color, color.darkened(0.1)]))
		draw_string(font, edge + Vector2(-78, 22), "%s %dm" % [label, meters], HORIZONTAL_ALIGNMENT_CENTER, 156.0, 16, color.lightened(0.18))

func _navigation_indicator_targets() -> Array:
	return objective_indicator_system.targets_for_state(state, int(state.ui_layout_defs.get("indicator_max_count", 3)))

func _draw_minimap() -> void:
	_phase6_metric("minimap_draw_calls")
	var rect := minimap_rect
	if rect.size == Vector2.ZERO:
		var map_size = float(state.ui_layout_defs.get("minimap_size", 144.0))
		rect = Rect2(size - Vector2(map_size + 24.0, map_size + 58.0), Vector2(map_size, map_size))
	if map_expanded and expanded_map_rect.size != Vector2.ZERO:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.015, 0.025, 0.72), true)
		rect = expanded_map_rect
	var cadence_elapsed: bool = state.elapsed_seconds - last_minimap_update_time >= minimap_update_interval
	if cadence_elapsed or minimap_render_cache.needs_rebuild(state, rect, map_expanded):
		last_minimap_update_time = state.elapsed_seconds
		minimap_update_count += 1
		minimap_render_cache.rebuild(state, rect, map_expanded)
		_phase6_metric("minimap_cadence_updates")
	_draw_minimap_content(rect, map_expanded)

func _draw_minimap_content(rect: Rect2, show_legend: bool) -> void:
	_phase6_metric("minimap_content_draws")
	var font = get_theme_default_font()
	for command in minimap_render_cache.commands:
		var kind := String(command.get("kind", ""))
		match kind:
			"background":
				draw_rect(rect, Color(0.02, 0.03, 0.05, minimap_opacity), true)
				draw_rect(rect, Color(0.42, 0.82, 1.0, 0.88), false, 3.0 if show_legend else 2.0)
			"rect":
				draw_rect(command.get("rect", Rect2()), command.get("color", Color.WHITE), true)
			"room":
				draw_rect(command.get("rect", Rect2()), command.get("color", Color.WHITE), true)
				draw_rect(command.get("rect", Rect2()), command.get("border", Color.WHITE), false, 1.0)
				if bool(command.get("important", false)):
					var icon := _terrain_minimap_icon(String(command.get("terrain_id", "safe_room")))
					var text := icon if bool(command.get("explored", false)) else "?"
					var pos: Vector2 = command.get("pos", Vector2.ZERO)
					draw_string(font, pos + Vector2(-minimap_icon_size * 0.6, minimap_icon_size * 0.45), text, HORIZONTAL_ALIGNMENT_CENTER, minimap_icon_size * 1.2, int(maxf(10.0, minimap_icon_size)), command.get("color_text", Color.WHITE))
			"circle":
				var radius := float(command.get("radius", 1.0))
				if bool(command.get("icon_scale", false)):
					radius *= minimap_icon_size
				draw_circle(command.get("pos", Vector2.ZERO), radius, command.get("color", Color.WHITE))
			"chest":
				var pos: Vector2 = command.get("pos", Vector2.ZERO)
				draw_rect(Rect2(pos - Vector2.ONE * minimap_icon_size * 0.5, Vector2.ONE * minimap_icon_size), _chest_color(String(command.get("rarity", "normal"))), true)
			"equipment":
				var pos: Vector2 = command.get("pos", Vector2.ZERO)
				draw_rect(Rect2(pos - Vector2.ONE * minimap_icon_size * 0.45, Vector2.ONE * minimap_icon_size * 0.90), command.get("color", Color.WHITE), true)
			"gimmick":
				var pos: Vector2 = command.get("pos", Vector2.ZERO)
				draw_rect(Rect2(pos - Vector2.ONE * minimap_icon_size * 0.35, Vector2.ONE * minimap_icon_size * 0.7), command.get("color", Color.WHITE), true)
			"boss":
				draw_circle(command.get("pos", Vector2.ZERO), minimap_icon_size * 0.65, Color(1.0, 0.20, 0.18))
			"player":
				draw_circle(command.get("pos", Vector2.ZERO), minimap_icon_size * 0.55, Color(1.0, 0.92, 0.34))
	if show_legend:
		draw_string(font, rect.position + Vector2(16, 28), "拡大マップ　上部の「閉じる」で戻る", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 32.0, 18, Color(0.94, 0.98, 1.0))
		var legend_y = rect.end.y - 34.0
		draw_string(font, Vector2(rect.position.x + 16.0, legend_y), "黄 破壊壁　灰 構造壁　緑 回復　赤 ボス　青 ドロップ　四角 装備", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 32.0, 16, Color(0.90, 0.94, 0.98))

func _terrain_minimap_icon(terrain_id: String) -> String:
	match terrain_id:
		"healing_oasis":
			return "泉"
		"relic_vault", "sealed_room":
			return "宝"
		"boss_arena":
			return "B"
		"event_room":
			return "E"
		"mine_chamber":
			return "鉱"
		"danger_den":
			return "!"
	return ""

func _cell_world_rect(key: String, tile_size: float) -> Rect2:
	var parts = key.split(",")
	if parts.size() != 2:
		return Rect2()
	return Rect2(Vector2(int(parts[0]), int(parts[1])) * tile_size, Vector2(tile_size, tile_size))

func _draw_projectile_shape(pos: Vector2, radius: float, color: Color, shape: String, evolved: bool) -> void:
	var glow = Color(color.r, color.g, color.b, 0.18 if not evolved else 0.28)
	match shape:
		"meteor_bolt":
			draw_circle(pos, radius + 10.0, glow)
			draw_polygon(PackedVector2Array([pos + Vector2(0, -radius - 6), pos + Vector2(radius + 8, 0), pos + Vector2(0, radius + 6), pos + Vector2(-radius - 8, 0)]), PackedColorArray([Color.WHITE, color, color.darkened(0.08), color]))
		"thin_laser", "aurora_laser":
			draw_circle(pos, radius + 8.0, glow)
			draw_rect(Rect2(pos - Vector2(radius * 1.4, radius * 0.45), Vector2(radius * 2.8, radius * 0.9)), color, true)
		"fan_slash", "chain_slash_wave", "scythe_arc", "death_scythe_arc":
			draw_arc(pos, radius + 14.0, -0.8, 0.8, 18, color, 5.0 if evolved else 3.0)
			draw_circle(pos, radius * 0.55, Color(color.r, color.g, color.b, 0.22))
		"mirror_shard", "kaleido_shard":
			draw_polygon(PackedVector2Array([pos + Vector2(0, -radius - 5), pos + Vector2(radius + 7, 0), pos + Vector2(0, radius + 7), pos + Vector2(-radius - 6, 0)]), PackedColorArray([Color.WHITE, color, color.darkened(0.1), color]))
		"rune_gate", "large_rune_gate":
			draw_arc(pos, maxf(radius + 16.0, 24.0), 0.0, TAU, 32, color, 4.0 if evolved else 3.0)
			draw_rect(Rect2(pos - Vector2(radius, radius * 1.3), Vector2(radius * 2.0, radius * 2.6)), Color(color.r, color.g, color.b, 0.18), false, 3.0)
		_:
			draw_circle(pos, radius, color)
			draw_circle(pos, radius + 7.0, glow)

func _effect_color(effect: Dictionary, fallback: Color) -> Color:
	var values: Array = effect.get("color", effect.get("primary_color", []))
	if values.size() >= 3:
		return Color(float(values[0]), float(values[1]), float(values[2]))
	return fallback

func _data_color(data: Dictionary, fallback: Color) -> Color:
	var values: Array = data.get("color", [])
	if values.size() >= 3:
		return Color(float(values[0]), float(values[1]), float(values[2]))
	return fallback

func _chest_color(rarity: String) -> Color:
	match rarity:
		"evolution":
			return Color(0.42, 0.92, 1.0)
		"overclock":
			return Color(1.0, 0.55, 0.16)
		"cursed":
			return Color(0.92, 0.22, 1.0)
		"golden":
			return Color(1.0, 0.86, 0.18)
	return Color(1.0, 0.70, 0.24)

func _chest_label(rarity: String) -> String:
	match rarity:
		"evolution":
			return "進化宝箱"
		"overclock":
			return "過充電"
		"cursed":
			return "呪箱"
		"golden":
			return "黄金"
	return "宝箱"

func _draw_biome_spikes(camera: Vector2, accent: Color) -> void:
	for i in range(18):
		var p = Vector2(fmod(float(i * 383) - camera.x * 0.15, size.x), fmod(float(i * 211) - camera.y * 0.15, size.y))
		draw_polygon(PackedVector2Array([p + Vector2(0, -18), p + Vector2(9, 16), p + Vector2(-9, 16)]), PackedColorArray([Color(accent.r, accent.g, accent.b, 0.22), Color(accent.r, accent.g, accent.b, 0.07), Color(accent.r, accent.g, accent.b, 0.07)]))

func _draw_biome_ore(camera: Vector2, accent: Color) -> void:
	for i in range(16):
		var p = Vector2(fmod(float(i * 271) - camera.x * 0.18, size.x), fmod(float(i * 157) - camera.y * 0.18, size.y))
		draw_rect(Rect2(p, Vector2(28, 10)).grow(2.0), Color(accent.r, accent.g, accent.b, 0.14), true)

func _draw_biome_void(camera: Vector2, accent: Color) -> void:
	for i in range(12):
		var p = Vector2(fmod(float(i * 421) - camera.x * 0.11, size.x), fmod(float(i * 193) - camera.y * 0.11, size.y))
		var radius := 28.0 + float(i % 4) * 8.0
		draw_arc(p, radius, 0.0, TAU, _arc_segments(radius), Color(accent.r, accent.g, accent.b, 0.16), 2.0)

func _visual_limit(kind: String, fallback: int) -> int:
	var key := "max_rendered_%s" % kind
	var configured := int(visual_limits.get(key, fallback))
	return visual_effect_budget_system.rendered_limit(kind, configured)

func _arc_segments(radius: float, critical: bool = false) -> int:
	var segments := visual_effect_budget_system.adaptive_arc_segments(radius * camera_zoom, critical)
	_phase6_metric("phase7_arc_vertex_estimate", segments)
	return segments

func _ensure_background_grid_texture(color: Color, spacing: int) -> void:
	var safe_spacing := maxi(8, spacing)
	if background_grid_texture != null and background_grid_color.is_equal_approx(color):
		return
	var image := Image.create_empty(safe_spacing, safe_spacing, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for index in range(safe_spacing):
		image.set_pixel(index, 0, color)
		image.set_pixel(0, index, color)
	background_grid_texture = ImageTexture.create_from_image(image)
	background_grid_color = color
	_phase6_metric("phase7_background_grid_texture_rebuilds")

func _phase6_metric(name: String, amount: int = 1) -> void:
	if phase6_metrics != null:
		phase6_metrics.add(name, amount)
