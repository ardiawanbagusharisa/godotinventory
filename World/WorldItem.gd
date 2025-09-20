extends RigidBody2D
class_name WorldItem

@export var item_id: StringName
@export var follow_while_dragging := true

var _dragging := false
var _inv_panel: Control

func _ready() -> void:
	input_pickable = true
	var panels := get_tree().get_nodes_in_group("InventoryUI")
	if panels.size() > 0 and panels[0] is Control:
		_inv_panel = panels[0]

func set_item_id(id: StringName) -> void:
	item_id = id
	
func _input_event(_vp: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_dragging = true
		set_deferred("freeze_mode", RigidBody2D.FREEZE_MODE_KINEMATIC)
		set_deferred("freeze", true)

func _input(event: InputEvent) -> void:
	if not _dragging: return
	if event is InputEventMouseMotion and follow_while_dragging:
		global_position = get_global_mouse_position()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false
		if _over_inventory_panel():
			if item_id != &"": Inventory.add_item(item_id, 1)
			else: push_warning("WorldItem has empty item_id; set it in the Inspector")
			queue_free()
		else:
			set_deferred("freeze", false)

func _over_inventory_panel() -> bool:
	if _inv_panel == null or not _inv_panel.visible: return false
	var rect: Rect2 = _inv_panel.get_global_rect()
	var mouse_screen := get_viewport().get_mouse_position()
	return rect.has_point(mouse_screen)
