extends Node

var items: Dictionary = {}

func _ready() -> void:
	# Note: There are two alternatives to easily register and access an item: 
	# 1) Use tres 
	# 2) Make ItemDB global 
	_register_item("apple", "Apple", "Replenish your energy (maybe).","res://Sprites/apple64.png", "res://World/Apple.tscn")
	_register_item("wood", "Wood", "Build your dream AirBnb.","res://Sprites/wood64.png", "res://World/Wood.tscn")
	_register_item("stone", "Stone", "Useful for a protest.","res://Sprites/stone64.png", "res://World/Stone.tscn")
	_register_item("stone1", "Stone rare", "Even more useful for protest.", "res://Sprites/stone64.png", "res://World/Stone.tscn")
	_register_item("corn", "Corn", "Feed your hungry.", "res://Sprites/corn64.png", "res://World/Corn.tscn")
	_register_item("scroll", "Scroll", "Give you more knowledge. \nNo, you must study first, fool!", "res://Sprites/scroll64.png", "res://World/Scroll.tscn")
	_register_item("poison", "Poison", "Give this for wife.", "res://Sprites/poison64.png", "res://World/Poison.tscn")
	_register_item("potion", "Potion", "Give this for yourself.","res://Sprites/potion64.png", "res://World/Potion.tscn")

func _register_item(id: String, name: String, description: String, icon_path: String, scene_path: String) -> void:
	var data := ItemData.new()
	data.id = id
	data.display_name = name
	data.description = description
	data.icon = load(icon_path)
	data.spawn_scene = load(scene_path)
	items[id] = data

func get_item(id: StringName) -> ItemData:
	return items.get(id)
