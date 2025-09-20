extends Node

var items: Dictionary = {}

func _ready() -> void:
	_register_item("apple", "Apple", "res://icons/apple64.png", "res://World/Apple.tscn")
	_register_item("wood", "Wood", "res://icons/wood64.png", "res://World/Wood.tscn")
	_register_item("stone", "Stone", "res://icons/stone64.png", "res://World/Stone.tscn")
	_register_item("stone1", "Stone1", "res://icons/stone64.png", "res://World/Stone.tscn")
	_register_item("stone2", "Stone2", "res://icons/stone64.png", "res://World/Stone.tscn")
	_register_item("stone3", "Stone3", "res://icons/stone64.png", "res://World/Stone.tscn")
	_register_item("stone4", "Stone4", "res://icons/stone64.png", "res://World/Stone.tscn")

func _register_item(id: String, name: String, icon_path: String, scene_path: String) -> void:
	var data := ItemData.new()
	data.id = id
	data.display_name = name
	data.icon = load(icon_path)
	data.spawn_scene = load(scene_path)
	items[id] = data

func get_item(id: StringName) -> ItemData:
	return items.get(id)
