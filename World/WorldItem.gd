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
		set_deferred("freeze_mode", RigidBody2D.FREEZE_MODE_KINEMATIC)
		set_deferred("freeze", true)
		
		#if _over_inventory_panel(): 
			#_inv_panel.call_deferred("set_hover", true) 
			#print("Set hover true")
		#else: 
			#_inv_panel.call_deferred("set_hover", false)

func _input(event: InputEvent) -> void:
	if not _dragging: return
	
	if event is InputEventMouseMotion and follow_while_dragging:
		global_position = get_global_mouse_position()
		_update_inventory_slot_highlight() # [Bug]
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
		
		#if _over_inventory_panel(): 
			#_inv_panel.call_deferred("set_hover", true) 
			#print("Set hover true")
		#else: 
			#_inv_panel.call_deferred("set_hover", false)

func _over_inventory_panel() -> bool:
	if _inv_panel == null or not _inv_panel.visible: return false
	var rect: Rect2 = _inv_panel.get_global_rect()
	var mouse_screen := get_viewport().get_mouse_position()
	return rect.has_point(mouse_screen)

func _update_inventory_slot_highlight() -> void:
	var hovered := get_viewport().gui_get_hovered_control()
	var slot: ItemSlot = null

	# climb up through parents until we hit the ItemSlot (or run out)
	while hovered:
		if hovered is ItemSlot:
			slot = hovered
			break
		hovered = hovered.get_parent() as Control

	# now apply highlight if the IDs match; otherwise clear
	if slot and slot.item_id == item_id:
		print("hovered:", hovered, "  slot:", slot, "  id:", item_id)
		if _last_highlighted_slot and _last_highlighted_slot != slot:
			_last_highlighted_slot.set_highlight(false)
		slot.set_highlight(true)
		_last_highlighted_slot = slot
	else:
		_clear_inventory_slot_highlight()

func _clear_inventory_slot_highlight() -> void:    
	if _last_highlighted_slot:
		_last_highlighted_slot.set_highlight(false)
		_last_highlighted_slot = null
