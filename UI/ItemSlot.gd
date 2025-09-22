extends Button
class_name ItemSlot

signal right_click(item_id: StringName)
signal drag_started(item_id: StringName)

var item_id: StringName
var icon_rect: TextureRect
var count_label: Label

var _highlight_on := false
var _pressed := false
var _drag_started := false
var _press_local_pos := Vector2.ZERO
const DRAG_PIX := 8.0

var _built := false

const SLOT_SIZE := 64
const ICON_SIZE := 56

func _build_ui() -> void:
	if _built: return
	_built = true

	flat = false
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	
	# Turn on if clip is expected. 
	#clip_contents = true 

	# Icon
	icon_rect = TextureRect.new()
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_rect)

	# Count label 
	count_label = Label.new()
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_label.z_index = 10
	add_child(count_label)
	# Anchor to the corner (all anchors = 1), compute offsets later
	count_label.anchor_left = 1.0
	count_label.anchor_right = 1.0
	count_label.anchor_top = 1.0
	count_label.anchor_bottom = 1.0

func _ready() -> void:
	add_to_group("ItemSlot")
	_build_ui()

func set_item(data: ItemData, count: int) -> void:
	_build_ui()
	if data == null:
		push_warning("ItemSlot.set_item got null ItemData")
		return
	item_id = data.id
	icon_rect.texture = data.icon
	count_label.text = "999+" if (count > 999) else str(count)
	
	# Reposition after text is known
	_position_count_label()  
	tooltip_text = "%s x%s. \n%s" % [data.display_name, count, data.description]
	
func _position_count_label() -> void:
	# Size needed for current text (accounts for ‘999+’ vs ‘5’ etc.).
	var sz := count_label.get_minimum_size()
	# Inset from edges
	var inset_r := 4.0
	var inset_b := 0.0
	# For bottom/right-anchored controls, left/top offsets must be negative width/height
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

func set_highlight(on: bool) -> void:             
	if _highlight_on == on: return
	_highlight_on = on
	modulate = Color(1.0, 0.5, 0.5, 1.0) if on else Color(1, 1, 1, 1) 
