class_name ItemDatabase
extends Resource

@export var items: Array[ItemData] = []

func get_item(item_id: StringName) -> ItemData:
	for item in items:
		if item != null and item.item_id == item_id:
			return item
	return null
