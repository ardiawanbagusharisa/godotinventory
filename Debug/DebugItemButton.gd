extends Button
class_name DebugItemButton

signal clicked_item(item_id: StringName)

@export var item_id: StringName = &""
@export var title: String = ""
@export var icon_tex: Texture2D

const SLOT_SIZE := 64
const ICON_SIZE := 56
const COUNT_FONT := 14

var _icon: TextureRect
var _count: Label

func _ready() -> void:
	flat = false
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Icon
	_icon = TextureRect.new()
	_icon.texture = icon_tex
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)

	# Label
	_count = Label.new()
	_count.text = title
	_count.add_theme_font_size_override("font_size", COUNT_FONT)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	#_count.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_count.offset_right = -4
	_count.offset_bottom = -2
	_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_count)

	tooltip_text = "%s" % title + "\n+1: click, \n+10: shift+click, \n+100: ctrl+click."

	# Left-click action only
	pressed.connect(func():
		if item_id != &"": clicked_item.emit(item_id)
		SFXManager.play_ui(&"ui_click")
	)

func _gui_input(event: InputEvent) -> void:
	# Ignore right-click and any drag intents.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		accept_event()
