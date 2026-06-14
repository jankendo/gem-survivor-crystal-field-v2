extends RefCounted
class_name IosLayoutOverlapSystem

func overlaps(named_rects: Dictionary, allowed_pairs: Array = []) -> Array:
	var names := named_rects.keys()
	var result: Array = []
	for i in range(names.size()):
		for j in range(i + 1, names.size()):
			var pair := "%s|%s" % [names[i], names[j]]
			var reverse := "%s|%s" % [names[j], names[i]]
			if allowed_pairs.has(pair) or allowed_pairs.has(reverse):
				continue
			if (named_rects[names[i]] as Rect2).intersects(named_rects[names[j]]):
				result.append(pair)
	return result
