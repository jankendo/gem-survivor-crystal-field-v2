extends VBoxContainer
class_name EquipmentGridView

const EquipmentIconCellScript = preload("res://scripts/ui/components/EquipmentIconCell.gd")
const EquipmentDetailSheetScript = preload("res://scripts/ui/components/EquipmentDetailSheet.gd")
const EquipmentFilterChipsScript = preload("res://scripts/ui/components/EquipmentFilterChips.gd")
const EquipmentStatsPanelScript = preload("res://scripts/ui/components/EquipmentStatsPanel.gd")

var kind := "weapon"
var active_filter := "all"
var grid: GridContainer
var detail_sheet
var stats_panel
var source_state

func _ready() -> void:
	add_theme_constant_override("separation", 10)

func build_from_state(state, equipment_kind: String, columns: int = 4) -> void:
	source_state = state
	kind = equipment_kind
	for child in get_children():
		child.queue_free()
	var filters = EquipmentFilterChipsScript.new()
	filters.setup(["all", "owned", "unlocked", "locked"])
	filters.filter_changed.connect(func(value: String):
		active_filter = value
		_rebuild_cells()
	)
	add_child(filters)
	stats_panel = EquipmentStatsPanelScript.new()
	add_child(stats_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	grid = GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	detail_sheet = EquipmentDetailSheetScript.new()
	add_child(detail_sheet)
	_rebuild_cells()

func _rebuild_cells() -> void:
	if grid == null or source_state == null:
		return
	for child in grid.get_children():
		child.queue_free()
	var defs: Dictionary = source_state.weapon_defs if kind == "weapon" else source_state.passive_defs
	var owned: Dictionary = source_state.weapons if kind == "weapon" else source_state.passives
	var unlocked_ids: Array = source_state.unlocked_weapon_ids if kind == "weapon" else source_state.unlocked_passive_ids
	var disabled_ids: Array = source_state.disabled_weapon_ids if kind == "weapon" else source_state.disabled_passive_ids
	var unlocked_count := 0
	var first_cell = null
	for raw_id in defs.keys():
		var id := String(raw_id)
		var is_unlocked := unlocked_ids.has(id)
		if is_unlocked:
			unlocked_count += 1
		var level := int(owned.get(id, 0))
		if not _passes_filter(level, is_unlocked):
			continue
		var cell = EquipmentIconCellScript.new()
		cell.setup(kind, id, defs[id], level, is_unlocked, not disabled_ids.has(id))
		cell.pressed.connect(_show_detail.bind(id))
		grid.add_child(cell)
		if first_cell == null:
			first_cell = cell
	if stats_panel != null:
		var cap: int = source_state.normal_weapon_cap() if kind == "weapon" else source_state.normal_passive_cap()
		stats_panel.set_stats(kind, owned.size(), unlocked_count, defs.size(), maxi(0, owned.size() - cap))
	if first_cell != null:
		_show_detail(first_cell.equipment_id)

func _passes_filter(level: int, is_unlocked: bool) -> bool:
	match active_filter:
		"owned":
			return level > 0
		"unlocked":
			return is_unlocked
		"locked":
			return not is_unlocked
	return true

func _show_detail(id: String) -> void:
	if detail_sheet == null or source_state == null:
		return
	var defs: Dictionary = source_state.weapon_defs if kind == "weapon" else source_state.passive_defs
	var owned: Dictionary = source_state.weapons if kind == "weapon" else source_state.passives
	var unlocked_ids: Array = source_state.unlocked_weapon_ids if kind == "weapon" else source_state.unlocked_passive_ids
	detail_sheet.show_equipment(kind, id, defs.get(id, {}), int(owned.get(id, 0)), unlocked_ids.has(id))
