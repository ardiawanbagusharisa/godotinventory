extends Button
class_name ItemSlot

signal right_click(item_id: StringName)

var item_id: StringName

# Children
var icon_holder: CenterContainer
var icon_rect: TextureRect
var count_label: Label

var _press_local_pos := Vector2.ZERO
var _drag_started := false
const DRAG_PIX := 8.0

func _build_ui() -> void:
	if icon_holder: return  

	# Slot baseline
	flat = false
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(64, 64)
	clip_contents = true

	# A container that keeps the icon centered and sized by its minimum
	icon_holder = CenterContainer.new()
	icon_holder.set_anchors_preset(Control.PRESET_FULL_RECT)  # fill the 64×64 slot
	add_child(icon_holder)

	# The icon itself: hard clamp to 56×56, aspect kept, centered by holder
	icon_rect = TextureRect.new()
	#icon_rect.custom_minimum_size = Vector2(56, 56)
	#icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	#icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	#icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_rect.size
	icon_holder.add_child(icon_rect)

	# Count label (bottom-right)
	count_label = Label.new()
	count_label.add_theme_font_size_override("font_size", 14)
	#count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	#count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	add_child(count_label)
	#count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	#count_label.offset_right = -4
	#count_label.offset_bottom = -2

func _ready() -> void:
	_build_ui()

func set_item(data: ItemData, count: int) -> void:
	_build_ui()
	if data == null:
		push_warning("ItemSlot.set_item got null ItemData")
		return
	item_id = data.id
	icon_rect.texture = data.icon           # any PNG size is fine
	count_label.text = "999+" if (count > 999) else str(count)
	tooltip_text = "%s x%s" % [data.display_name, count]

#func _gui_input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		#right_click.emit(item_id)
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		right_click.emit(item_id)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_local_pos = get_local_mouse_position()
			_drag_started = false
		else:
			_drag_started = false
	elif event is InputEventMouseMotion:
		if item_id != &"" and not _drag_started:
			var d := (get_local_mouse_position() - _press_local_pos).length()
			if d >= DRAG_PIX:
				_drag_started = true
				var data := {"type":"inventory_item","id":item_id}
				var preview := TextureRect.new()
				if icon_rect and icon_rect.texture:
					preview.texture = icon_rect.texture
				preview.custom_minimum_size = Vector2(48, 48)
				force_drag(data, preview) 
				accept_event()              # don't let parent (scroll) eat it

func get_drag_data(_p: Vector2) -> Variant:
	# still keep this for fallback; engine may call it when drag auto-detected
	return {"type":"inventory_item","id": item_id} if item_id != &"" else null
