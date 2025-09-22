# res://UI/WorldDropLayer.gd
extends Control
@export var spawner: WorldSpawner

var _is_dragging := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE 
	visible = true
	set_process(true)

func _process(_dt: float) -> void:
	var dragging := get_viewport().gui_is_dragging()
	if dragging != _is_dragging:
		_is_dragging = dragging
		mouse_filter = MOUSE_FILTER_STOP if dragging else MOUSE_FILTER_IGNORE
		# Tint while catching drops:
		modulate = Color(0.5, 1.0, 0.5, 0.2) if dragging else Color(1,1,1,0)

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("type","") == "inventory_item"

func _drop_data(_pos: Vector2, data: Variant) -> void:
	var item_id: StringName = data.get("id", &"")
	if item_id == &"": return
	var at_world := spawner.get_global_mouse_position()
	if spawner.spawn_physics_item_by_id(item_id, at_world):
		Inventory.remove_item(item_id, 1)
