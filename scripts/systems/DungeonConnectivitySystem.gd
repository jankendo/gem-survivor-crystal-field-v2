extends RefCounted
class_name DungeonConnectivitySystem

var graph = preload("res://scripts/systems/MapConnectivitySystem.gd").new()

func validate(map_data: Dictionary) -> Dictionary:
	var rooms: Array = map_data.get("rooms", [])
	var connections: Array = map_data.get("connections", [])
	var loop_count = 0
	for edge in connections:
		if String(edge.get("kind", "")) in ["loop", "secret_shortcut"]:
			loop_count += 1
	return {
		"all_reachable": graph.all_rooms_reachable(map_data),
		"important_reachable": graph.important_rooms_reachable(map_data),
		"branch_count": _branch_count(map_data),
		"loop_count": loop_count,
		"closed": rooms.is_empty() or connections.size() < rooms.size() - 1
	}

func _branch_count(map_data: Dictionary) -> int:
	var branch_nodes = 0
	for room in map_data.get("rooms", []):
		if graph.exit_count(map_data, String(room.get("id", ""))) >= 3:
			branch_nodes += 1
	return branch_nodes
