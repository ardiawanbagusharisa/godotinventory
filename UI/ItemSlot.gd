extends Button
class_name ItemSlot

signal right_click(item_id: StringName)
signal drag_started(item_id: StringName)

var item_id: StringName
var icon_rect: TextureRect
var count_label: Label

# drag state
var _highlight_on := false
var _pressed := false
var _drag_started := false
var _press_local_pos := Vector2.ZERO
const DRAG_PIX := 8.0

# build guard
var _built := false

const SLOT_SIZE := 64
const ICON_SIZE := 56

func _build_ui() -> void:
	if _built: return
	_built = true

	flat = false
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	#clip_contents = true 

	# Icon centered
	icon_rect = TextureRect.new()
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_rect)

	# Count label in bottom-right
	count_label = Label.new()
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_label.z_index = 10
	add_child(count_label)

	# Anchor to the corner (all anchors = 1) and we’ll compute offsets later
	count_label.anchor_left = 1.0
	count_label.anchor_right = 1.0
	count_label.anchor_top = 1.0
	count_label.anchor_bottom = 1.0

func _ready() -> void:
	_build_ui()
	add_to_group("ItemSlot")

func set_item(data: ItemData, count: int) -> void:
	_build_ui()
	if data == null:
		push_warning("ItemSlot.set_item got null ItemData")
		return
	item_id = data.id
	icon_rect.texture = data.icon
	count_label.text = "999+" if (count > 999) else str(count)
	_position_count_label()  # position after text is known
	tooltip_text = "%s x%s.\n\nThis item is super\nuseful to replenish\nyour energy." % [data.display_name, count]

func _position_count_label() -> void:
	# size needed for current text (accounts for ‘999+’ vs ‘5’ etc.)
	var sz := count_label.get_minimum_size()
	# inset from edges
	var inset_r := 4.0
	var inset_b := 0.0
	# for bottom/right-anchored controls, left/top offsets must be negative width/height
	count_label.offset_right = -inset_r
	count_label.offset_bottom = -inset_b
	count_label.offset_left = -inset_r - sz.x
	count_label.offset_top = -inset_b - sz.y

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			right_click.emit(item_id)
			SFXManager.play_ui(&"ui_rightclick")
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressed = true
			_drag_started = false
			_press_local_pos = get_local_mouse_position()
			SFXManager.play_ui(&"ui_click")
		else:
			_pressed = false
			_drag_started = false
		return

	if event is InputEventMouseMotion and _pressed and not _drag_started and item_id != &"":
		var d := (get_local_mouse_position() - _press_local_pos).length()
		if d >= DRAG_PIX:
			_drag_started = true
			drag_started.emit(item_id)
			var data := {"type":"inventory_item","id": item_id}
			var preview := TextureRect.new()
			if icon_rect and icon_rect.texture:
				preview.texture = icon_rect.texture
			preview.custom_minimum_size = Vector2(48, 48)
			force_drag(data, preview)
			accept_event()
			SFXManager.play_ui(&"ui_dragout")

func get_drag_data(_p: Vector2) -> Variant:
	return {"type":"inventory_item","id": item_id} if item_id != &"" else null

func set_highlight(on: bool) -> void:             # NEW
	if _highlight_on == on: return
	_highlight_on = on
	# Simple tint; swap to a Theme style if you prefer.
	modulate = Color(0.88, 1.0, 0.88, 1.0) if on else Color(1, 1, 1, 1)


# Old script that doesn't apply manual offset and inset
#extends Button
#class_name ItemSlot
#
#signal right_click(item_id: StringName)
#
#var item_id: StringName
#
#var icon_rect: TextureRect
#var count_label: Label
#
## drag state
#var _pressed := false
#var _drag_started := false
#var _press_local_pos := Vector2.ZERO
#const DRAG_PIX := 8.0
#
## build guard
#var _built := false
#
## visuals
#const SLOT_SIZE := 64
#const ICON_SIZE := 56
#
#func _build_ui() -> void:
	#if _built: return
	#_built = true
#
	## button baseline — use built-in hover/pressed
	#flat = false
	#focus_mode = Control.FOCUS_NONE
	#custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	#mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
#
	## icon — centered, aspect kept
	#icon_rect = TextureRect.new()
	#icon_rect.texture = null
	#icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	#icon_rect.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	#icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	#icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	#icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#add_child(icon_rect)
#
	## count label — bottom-right with insets, drawn above icon
	#count_label = Label.new()
	#count_label.add_theme_font_size_override("font_size", 14)
	#count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	#count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	##count_label.custom_minimum_size = Vector2(18, 18)
	##count_label.z_index = 10
	##count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	##count_label.offset_right = -4
	##count_label.offset_bottom = -2
	#add_child(count_label)
#
#func _ready() -> void:
	#_build_ui()
#
#func set_item(data: ItemData, count: int) -> void:
	#_build_ui()
	#if data == null:
		#push_warning("ItemSlot.set_item got null ItemData")
		#return
#
	#item_id = data.id
	#icon_rect.texture = data.icon
	#count_label.text = "999+" if (count > 999) else str(count)
	#tooltip_text = "%s x%s.\n\nThis item is super\nuseful to replenish\nyour energy." % [data.display_name, count]
#
#func _gui_input(event: InputEvent) -> void:
	## RMB = throw
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		#if event.pressed:
			#right_click.emit(item_id)
		#return
#
	## LMB press/release = manage drag state
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		#if event.pressed:
			#_pressed = true
			#_drag_started = false
			#_press_local_pos = get_local_mouse_position()
		#else:
			#_pressed = false
			#_drag_started = false
		#return
#
	## LMB drag threshold
	#if event is InputEventMouseMotion:
		#if _pressed and not _drag_started and item_id != &"":
			#var d := (get_local_mouse_position() - _press_local_pos).length()
			#if d >= DRAG_PIX:
				#_drag_started = true
				#var data := {"type":"inventory_item","id": item_id}
				#var preview := TextureRect.new()
				#if icon_rect and icon_rect.texture:
					#preview.texture = icon_rect.texture
				#preview.custom_minimum_size = Vector2(48, 48)
				#force_drag(data, preview)
				#accept_event()
#
#func get_drag_data(_p: Vector2) -> Variant:
	## fallback if engine auto-detects a drag
	#return {"type":"inventory_item","id": item_id} if item_id != &"" else null
