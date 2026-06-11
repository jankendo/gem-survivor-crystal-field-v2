extends RefCounted
class_name MapConnectivitySystem

func reachable_room_ids(map_data: Dictionary, start_id: String = "room_00") -> Array:
	var adjacency := {}
	for room in map_data.get("rooms", []):
		adjacency[String(room.get("id", ""))] = []
	for edge in map_data.get("connections", []):
		var from_id = String(edge.get("from", ""))
		var to_id = String(edge.get("to", ""))
		if adjacency.has(from_id) and adjacency.has(to_id):
			adjacency[from_id].append(to_id)
			adjacency[to_id].append(from_id)
	if not adjacency.has(start_id):
		return []
	var visited: Array = [start_id]
	var queue: Array = [start_id]
	while not queue.is_empty():
		var current = String(queue.pop_front())
		for neighbor in adjacency.get(current, []):
			if not visited.has(neighbor):
				visited.append(neighbor)
				queue.append(neighbor)
	return visited

func all_rooms_reachable(map_data: Dictionary) -> bool:
	var rooms: Array = map_data.get("rooms", [])
	return not rooms.is_empty() and reachable_room_ids(map_data).size() == rooms.size()

func important_rooms_reachable(map_data: Dictionary) -> bool:
	var reachable = reachable_room_ids(map_data)
	for room_id in map_data.get("important_room_ids", []):
		if not reachable.has(String(room_id)):
			return false
	return true

func exit_count(map_data: Dictionary, room_id: String) -> int:
	var count = 0
	for edge in map_data.get("connections", []):
		if String(edge.get("from", "")) == room_id or String(edge.get("to", "")) == room_id:
			count += 1
	return count
