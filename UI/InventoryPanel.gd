extends Panel

signal throw_requested(item_id: StringName)

@onready var grid: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/Grid

var _slots_by_id: Dictionary = {}                 
var _drag_monitoring := false                    
var _current_highlight_id: StringName = &""      

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
		
		_slots_by_id[p.data.id] = slot
		slot.drag_started.connect(func(id: StringName): 
			_highlight_slot(id, true)
			_start_drag_end_watch()
		)
		slot.set_item(p.data, p.count)
		slot.right_click.connect(_on_slot_right_click)

func _on_slot_right_click(item_id: StringName) -> void:
	throw_requested.emit(item_id)

func set_hover(on: bool) -> void:
	modulate = Color(0.7, 1.0, 0.7, 1.0) if on else Color(1, 1, 1, 1)

func _highlight_slot(id: StringName, on: bool) -> void:   
	if _current_highlight_id != &"" and _current_highlight_id in _slots_by_id:
		_slots_by_id[_current_highlight_id].set_highlight(false)
	_current_highlight_id = id if on else &""
	if on and id in _slots_by_id:
		_slots_by_id[id].set_highlight(true)

func _clear_highlight() -> void:                           
	_highlight_slot(_current_highlight_id, false)

func _start_drag_end_watch() -> void:                      
	if _drag_monitoring: return
	_drag_monitoring = true
	set_process(true)

func _process(_dt: float) -> void:                         
	# Turn off highlight and stop polling when drag ends.
	if not get_viewport().gui_is_dragging():
		_clear_highlight()
		_drag_monitoring = false
		set_process(false)
