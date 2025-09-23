extends Node

class_name Main

@onready var inv_panel: Panel = $CanvasLayer/UI/InventoryPanel
@onready var spawner: WorldSpawner = $World/WorldSpawner

@export var label_satisfied: Label
@export var label_angry: Label

var satisfied_souls: int = 0
var angry_souls: int = 0

func _ready() -> void:
	inv_panel.throw_requested.connect(_on_throw_requested)

	# Demo inventory: populate here.
	Inventory.add_item(&"apple", 5)
	Inventory.add_item(&"stone", 998)
	Inventory.add_item(&"wood", 37)
	Inventory.add_item(&"corn", 99)
	Inventory.add_item(&"scroll", 1)
	Inventory.add_item(&"poison", 30)
	Inventory.add_item(&"potion", 7)
	Inventory.add_item(&"stone1", 1)
	
func _on_throw_requested(item_id: StringName) -> void:
	var ok = spawner.throw_from_mouse_to_player(item_id)
	if ok:
		Inventory.remove_item(item_id, 1)

func update_angry_souls(val: int) -> void: 
	angry_souls += val
	if angry_souls + val <= 0:
		angry_souls = 0
	label_angry.text = "Angry Souls: %s" %angry_souls 
	print(label_angry.text)

func update_satisfied_souls(val: int) -> void: 
	satisfied_souls += val
	if satisfied_souls + val <= 0: 
		satisfied_souls = 0
	label_satisfied.text = "Satisfied Souls: %s" %satisfied_souls 
	print(label_satisfied.text)
