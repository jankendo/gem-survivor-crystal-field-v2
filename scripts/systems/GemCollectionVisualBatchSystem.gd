extends RefCounted
class_name GemCollectionVisualBatchSystem

func make_batch(source: String, positions: Array, total_count: int, total_exp: int, player_position: Vector2, max_representatives: int = 4) -> Dictionary:
	var representative_positions: Array = []
	var limit = clampi(max_representatives, 0, 16)
	for pos in positions:
		if representative_positions.size() >= limit:
			break
		representative_positions.append(pos)
	var centroid := player_position
	if not representative_positions.is_empty():
		centroid = Vector2.ZERO
		for pos in representative_positions:
			centroid += pos
		centroid /= float(representative_positions.size())
	return {
		"batch_id": "%s:%d:%d" % [source, total_count, total_exp],
		"source": source,
		"total_count": total_count,
		"total_exp": total_exp,
		"source_centroid": centroid,
		"player_position": player_position,
		"representative_positions": representative_positions,
		"representative_count": representative_positions.size(),
		"visual_duration": 0.26,
		"priority": "signature" if total_count >= 100 else "combat"
	}
