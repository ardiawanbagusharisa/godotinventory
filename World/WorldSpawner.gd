extends Node2D
class_name WorldSpawner

@export var target: Node2D
@export var throw_spin: float = 5.0 

func spawn_physics_item_by_id(item_id: StringName, at_world: Vector2) -> RigidBody2D:
	var data := ItemDB.get_item(item_id)
	if data == null or data.spawn_scene == null:
		push_warning("No spawn scene for '%s'." % item_id)
		return null

	var inst := data.spawn_scene.instantiate()
	add_child(inst)
	_apply_item_id_to_tree(inst, item_id)

	if inst is RigidBody2D:
		var rb: RigidBody2D = inst
		rb.global_position = at_world
		# Ensure active
		rb.set_deferred("freeze", false)  
		return rb

	if inst is Node2D:
		(inst as Node2D).global_position = at_world
	return null

func throw_from_mouse_to_player(item_id: StringName, arc_height: float = 96.0) -> bool:
	if item_id == &"": return false

	var start: Vector2 = get_global_mouse_position()
	var targetpos: Vector2 = target.global_position if is_instance_valid(target) else start + Vector2(200, 0)

	var g: float = _get_gravity_magnitude()
	var v0: Vector2 = _solve_ballistic_arc(start, targetpos, arc_height, g)

	var rb := spawn_physics_item_by_id(item_id, start)
	if rb == null: return false

	rb.linear_velocity = v0
	rb.angular_velocity = sign(v0.x) * throw_spin
	return true

func _solve_ballistic_arc(p0: Vector2, p1: Vector2, arc_height: float, g: float) -> Vector2:
	# Y+ is down in Godot. Apex is ABOVE (smaller Y) than both points.
	var y0: float = p0.y
	var y1: float = p1.y
	var dx: float = p1.x - p0.x

	var apex_y: float = min(y0, y1) - max(0.0, arc_height)
	var s_up: float = max(0.0, y0 - apex_y)   # vertical dist up to apex
	var s_down: float = max(0.0, y1 - apex_y) # vertical dist down from apex

	# v^2 = 2 g s (negative vertical v for "up")
	var v0y: float = -sqrt(2.0 * g * s_up)
	var t_up: float = sqrt(2.0 * s_up / g) if (s_up > 0.0) else 0.0
	var t_down: float = sqrt(2.0 * s_down / g) if (s_down > 0.0) else 0.0
	var T: float = max(0.001, t_up + t_down)

	var v0x: float = dx / T
	return Vector2(v0x, v0y)

func _get_gravity_magnitude() -> float:
	var g: float = 980.0
	if ProjectSettings.has_setting("physics/2d/default_gravity"):
		g = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	return g

func _apply_item_id_to_tree(node: Node, id: StringName) -> bool:
	if node is WorldItem:
		(node as WorldItem).item_id = id
		return true

	if node.has_method("set_item_id"):
		node.call("set_item_id", id)
		return true

	if node.has_variable("item_id"):
		node.set("item_id", id)
		return true

	for c in node.get_children():
		if _apply_item_id_to_tree(c, id):
			return true
	return false
