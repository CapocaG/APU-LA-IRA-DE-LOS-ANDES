class_name InventoryComponent
extends Node

signal inventory_changed
signal item_added(item_id: StringName, quantity: int)
signal item_used(item_id: StringName)

@export var max_slots: int = 20
@export var item_database: ItemDatabase

var slots: Array[Dictionary] = []
var selected_hotbar_slot: int = 0

func _ready() -> void:
	_ensure_slots()
	if not GameState.inventory_data.is_empty():
		import_inventory(GameState.inventory_data)
	else:
		GameState.inventory_data = export_inventory()

func _ensure_slots() -> void:
	slots.clear()
	for _index in range(max_slots):
		slots.append({})

func add_item(item: ItemData, quantity: int = 1) -> bool:
	if item == null:
		return false

	var amount := maxi(quantity, 1)
	var stack_index := _find_stack(item.item_id)
	if stack_index >= 0:
		var current := int(slots[stack_index].get("quantity", 0))
		if current + amount <= item.max_stack:
			slots[stack_index]["quantity"] = current + amount
			item_added.emit(item.item_id, amount)
			inventory_changed.emit()
			_sync_to_game_state()
			return true

	var empty_index := _find_empty_slot()
	if empty_index < 0:
		return false

	slots[empty_index] = {
		"item_id": String(item.item_id),
		"quantity": amount,
	}
	item_added.emit(item.item_id, amount)
	inventory_changed.emit()
	_sync_to_game_state()
	return true

func _find_stack(item_id: StringName) -> int:
	for index in range(slots.size()):
		var slot := slots[index]
		if slot.is_empty():
			continue
		if StringName(slot.get("item_id", "")) == item_id:
			return index
	return -1

func _find_empty_slot() -> int:
	for index in range(slots.size()):
		if slots[index].is_empty():
			return index
	return -1

func consume_one(item_id: StringName) -> bool:
	var index := _find_stack(item_id)
	if index < 0:
		return false

	var quantity := int(slots[index].get("quantity", 0)) - 1
	if quantity <= 0:
		slots[index] = {}
	else:
		slots[index]["quantity"] = quantity

	item_used.emit(item_id)
	inventory_changed.emit()
	_sync_to_game_state()
	return true

func export_inventory() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot in slots:
		result.append(slot.duplicate(true))
	return result

func import_inventory(saved_slots: Array) -> void:
	_ensure_slots()
	var count := mini(saved_slots.size(), max_slots)
	for index in range(count):
		if typeof(saved_slots[index]) != TYPE_DICTIONARY:
			continue
		var saved_slot: Dictionary = saved_slots[index]
		var item_id := StringName(saved_slot.get("item_id", ""))
		var quantity_value: Variant = saved_slot.get("quantity", 0)
		if item_id == &"" or typeof(quantity_value) not in [TYPE_INT, TYPE_FLOAT]:
			continue
		var quantity := int(quantity_value)
		var item := item_database.get_item(item_id) if item_database != null else null
		if item == null or quantity <= 0:
			continue
		slots[index] = {
			"item_id": String(item_id),
			"quantity": mini(quantity, item.max_stack),
		}
	inventory_changed.emit()
	_sync_to_game_state(false)

func select_hotbar_slot(index: int) -> void:
	selected_hotbar_slot = posmod(index, mini(5, max_slots))

func use_selected_item() -> bool:
	if selected_hotbar_slot < 0 or selected_hotbar_slot >= slots.size():
		return false
	var slot := slots[selected_hotbar_slot]
	if slot.is_empty():
		return false
	var item_id := StringName(slot.get("item_id", ""))
	var item := item_database.get_item(item_id) if item_database != null else null
	if item == null or not item.consumable:
		return false
	return consume_one(item_id)

func get_item(item_id: StringName) -> ItemData:
	if item_database == null:
		return null
	return item_database.get_item(item_id)

func _sync_to_game_state(save: bool = true) -> void:
	GameState.inventory_data = export_inventory()
	if save:
		SaveManager.save_game()
