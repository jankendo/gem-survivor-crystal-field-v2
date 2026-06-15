extends RefCounted
class_name IosBackgroundThrottleSystem

func set_branch_active(node: Node, active: bool) -> void:
	if node == null:
		return
	node.set_process(active)
	node.set_physics_process(active)
	node.set_process_input(active)
	node.set_process_unhandled_input(active)
	for child in node.get_children():
		set_branch_active(child, active)
