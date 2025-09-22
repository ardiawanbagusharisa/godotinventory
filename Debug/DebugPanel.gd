extends Panel

@onready var grid: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/Grid

const SLOT_SIZE := 64
const CELL_GAP := 8
const PADDING := 24 

@export var base_add: int = 1
@export var shift_add: int = 10
@export var ctrl_add: int = 100

var _buttons: Array[DebugItemButton] = []

func _ready() -> void:
	add_to_group("DebugItemsPanel") 
	grid.add_theme_constant_override("h_separation", CELL_GAP)
	grid.add_theme_constant_override("v_separation", CELL_GAP)
	resized.connect(_on_panel_resized)
	Inventory.changed.connect(_refresh_counts)

	_on_panel_resized()
	_build_once()
	_refresh_counts()

func _on_panel_resized() -> void:
	var w := size.x - PADDING
	var cell_full := SLOT_SIZE + CELL_GAP
	grid.columns = max(3, int(floor(w / cell_full)))

func _build_once() -> void:
	_clear_grid()
	_buttons.clear()

	# Collect and sort ItemDB by display name.
	var entries: Array = []
	for id in ItemDB.items.keys():
		var data := ItemDB.get_item(id)
		if data != null:
			entries.append(data)
	entries.sort_custom(func(a, b): return a.display_name < b.display_name)

	for data in entries:
		var btn := DebugItemButton.new()
		btn.item_id = data.id
		btn.title = data.display_name
		btn.icon_tex = data.icon
		grid.add_child(btn)
		_buttons.append(btn)

		# Left-click to add to inventory.
		btn.clicked_item.connect(func(id: StringName):
			var amt := _pick_amount()
			Inventory.add_item(id, amt)
		)

func _refresh_counts() -> void:
	for btn in _buttons:
		var n := 0
		if Inventory.has_method("get_count"):
			n = Inventory.get_count(btn.item_id)

func _clear_grid() -> void:
	for c in grid.get_children():
		c.queue_free()

func _pick_amount() -> int:
	if Input.is_key_pressed(KEY_SHIFT): return shift_add
	if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META): return ctrl_add
	return base_add
