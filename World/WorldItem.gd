extends RigidBody2D
class_name WorldItem

@export var item_id: StringName
@export var follow_while_dragging := true

var _dragging := false
var _inv_panel: Control
var _hover_state := false
var _last_highlighted_slot: ItemSlot

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
		#_update_inventory_slot_highlight()
		set_deferred("freeze_mode", RigidBody2D.FREEZE_MODE_KINEMATIC)
		set_deferred("freeze", true)

func _input(event: InputEvent) -> void:
	if not _dragging: return
	
	if event is InputEventMouseMotion and follow_while_dragging:
		global_position = get_global_mouse_position()
		_update_inventory_slot_highlight()
		var over := _over_inventory_panel()
		if over != _hover_state:
			_hover_state = over
			if _inv_panel and _inv_panel.has_method("set_hover"):
				_inv_panel.set_hover(_hover_state)
				
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false
		_clear_inventory_slot_highlight()
		 
		if _inv_panel and _inv_panel.has_method("set_hover"):
			_inv_panel.set_hover(false)
		if _over_inventory_panel():
			if item_id != &"": Inventory.add_item(item_id, 1)
			else: push_warning("WorldItem has empty item_id; set it in the Inspector")
			queue_free()
			SFXManager.play_ui(&"ui_drag")
		else:
			set_deferred("freeze", false)

func _over_inventory_panel() -> bool:
	if _inv_panel == null or not _inv_panel.visible: return false
	var rect: Rect2 = _inv_panel.get_global_rect()
	var mouse_screen := get_viewport().get_mouse_position()
	return rect.has_point(mouse_screen)

func _update_inventory_slot_highlight() -> void:
	var target: ItemSlot = null

	# Hovered matching slot UI.
	var hovered := get_viewport().gui_get_hovered_control()
	while hovered:
		if hovered is ItemSlot and hovered.item_id == item_id:
			target = hovered
			break
		hovered = hovered.get_parent() as Control

	# Fallback: find a matching slot anywhere. 
	if target == null:
		target = _find_matching_inventory_slot(item_id)

	# Clear previously different or invalid.
	if _last_highlighted_slot != null:
		if not is_instance_valid(_last_highlighted_slot) or _last_highlighted_slot != target:
			if is_instance_valid(_last_highlighted_slot):
				_last_highlighted_slot.set_highlight(false)
			_last_highlighted_slot = null

	# Apply highlight if valid only. 
	if target != null and is_instance_valid(target):
		target.set_highlight(true)
		_last_highlighted_slot = target
	else:
		_clear_inventory_slot_highlight()

func _clear_inventory_slot_highlight() -> void:
	if _last_highlighted_slot != null and is_instance_valid(_last_highlighted_slot):
		_last_highlighted_slot.set_highlight(false)
	_last_highlighted_slot = null

func _find_matching_inventory_slot(id: StringName) -> ItemSlot:
	if _inv_panel and _inv_panel.is_inside_tree():
		if _inv_panel.has_method("get_slots"):
			for s in _inv_panel.get_slots():
				if s and s.is_visible_in_tree() and s.item_id == id:
					return s

	for n in get_tree().get_nodes_in_group("ItemSlot"):
		if n is ItemSlot and n.is_visible_in_tree() and n.item_id == id:
			return n

	return null
