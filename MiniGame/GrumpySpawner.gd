extends Node2D
class_name GrumpySpawner

@export var villager_scene: PackedScene
@export var spawn_interval_sec: float = 5
@export var max_concurrent: int = 10
@export var allowed_item_ids: Array[StringName] = [&"apple", &"wood", &"corn", &"stone", &"stone1", &"poison", &"potion"]

var _timer := 0.0

func _process(delta: float) -> void:
	if villager_scene == null or allowed_item_ids.is_empty():
		return
	_timer += delta
	if _timer >= spawn_interval_sec:
		_timer = 0.0
		_try_spawn()

func _try_spawn() -> void:
	# population cap (unchanged)
	var alive := 0
	for n in get_tree().get_nodes_in_group("grumpy_villager"):
		if is_instance_valid(n):
			alive += 1
	if alive >= max_concurrent:
		return

	var v := villager_scene.instantiate() as Node2D
	if v == null:
		return

	var wanted := allowed_item_ids[randi() % allowed_item_ids.size()]

	# Read patrol width from the villager (fallback to 800 if missing)
	var width := 800.0
	if v is GrumpyVillager:
		width = (v as GrumpyVillager).patrol_width
	else:
		# generic fallback if you ever swap scripts
		if v.has_method("get"): # Objects always have get(), but safe anyway
			var pw = v.get("patrol_width")
			if typeof(pw) == TYPE_FLOAT or typeof(pw) == TYPE_INT:
				width = float(pw)

	var half := width * 0.5
	var left := global_position.x - half
	var right := global_position.x + half

	# Configure via villager API
	if v.has_method("set_wanted_id"):
		v.call("set_wanted_id", wanted)
	if v.has_method("set_patrol_bounds"):
		v.call("set_patrol_bounds", left, right)
	# NOTE: no set_speed here—speed lives on the villager now

	v.global_position = global_position + Vector2(0, -8)
	get_tree().current_scene.add_child(v)
