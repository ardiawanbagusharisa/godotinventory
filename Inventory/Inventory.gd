extends Node

signal changed

var _counts: Dictionary = {}  # id -> count

enum SortMode { BY_NAME_ASC, BY_ID_ASC }
var sort_mode: SortMode = SortMode.BY_NAME_ASC

func add_item(id: StringName, amount: int = 1) -> void:
	if amount <= 0: return
	var before := int(_counts.get(id, 0))
	_counts[id] = before + amount
	#print("[Inventory.add_item] id=", id, " before=", before, " after=", _counts[id])
	changed.emit()

func remove_item(id: StringName, amount: int = 1) -> void:
	if not _counts.has(id): return
	_counts[id] = max(0, int(_counts[id]) - amount)
	if _counts[id] == 0:
		_counts.erase(id)
	changed.emit()

func get_all_pairs_sorted() -> Array:
	var out: Array = []
	for id in _counts.keys():
		var data := ItemDB.get_item(id)
		if data:
			out.append({ "id": id, "count": _counts[id], "data": data })
	match sort_mode:
		SortMode.BY_NAME_ASC:
			out.sort_custom(func(a, b): return a.data.display_name < b.data.display_name)
		SortMode.BY_ID_ASC:
			out.sort_custom(func(a, b): return String(a.id) < String(b.id))
	return out
