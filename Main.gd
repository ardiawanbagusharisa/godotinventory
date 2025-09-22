extends Node

@onready var inv_panel: Panel = $CanvasLayer/UI/InventoryPanel
@onready var spawner: WorldSpawner = $World/WorldSpawner

func _ready() -> void:
	inv_panel.throw_requested.connect(_on_throw_requested)

	# Demo inventory: populate here
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

#func _on_spawn_requested(item_id: StringName) -> void:
	#var inst := spawner.spawn_item_by_id(item_id)
	#if inst:
		#Inventory.remove_item(item_id, 1)
