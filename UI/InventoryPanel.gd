extends Panel

signal throw_requested(item_id: StringName)


@onready var grid: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/Grid

const SLOT_SIZE := 64
const CELL_GAP := 8
const PADDING := 24

func _ready() -> void:
	add_to_group("InventoryUI")
	
	grid.add_theme_constant_override("h_separation", CELL_GAP)
	grid.add_theme_constant_override("v_separation", CELL_GAP)

	Inventory.changed.connect(_rebuild)
	resized.connect(_on_panel_resized)

	_on_panel_resized()
	_rebuild()

func _on_panel_resized() -> void:
	var w := size.x - PADDING
	var cell_full := SLOT_SIZE + CELL_GAP
	grid.columns = max(3, int(floor(w / cell_full)))

func _clear_grid() -> void:
	for c in grid.get_children():
		c.queue_free()

func _rebuild() -> void:
	_clear_grid()
	var pairs := Inventory.get_all_pairs_sorted()
	for p in pairs:
		var slot := ItemSlot.new()
		grid.add_child(slot)
		slot.set_item(p.data, p.count)
		slot.right_click.connect(_on_slot_right_click)

func _on_slot_right_click(item_id: StringName) -> void:
	throw_requested.emit(item_id)

func set_hover(on: bool) -> void:
	modulate = Color(0.7, 1.0, 0.7, 1.0) if on else Color(1, 1, 1, 1)
