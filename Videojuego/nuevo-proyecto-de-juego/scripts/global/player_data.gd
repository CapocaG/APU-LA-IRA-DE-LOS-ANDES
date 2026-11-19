extends Node

signal inventory_changed(inventory: Dictionary)
signal selected_slot_changed(slot_index: int)

const ITEM_ORDER: Array[String] = [
	"COCA",
	"CHICHA_DE_JORA",
	"FRAGMENTO_DE_ILLAPA",
	"QUIPU",
	"ILLA",
	"SEMILLA_DE_PACHAMAMA",
	"ESCAMA_DE_AMARU"
]

var level: int = 1
var experience: int = 0

var bonus_damage: int = 0
var bonus_speed: int = 0
var bonus_max_hp: int = 0
var bonus_max_energy: float = 0.0

var selected_slot: int = 0

var inventory: Dictionary = {
	"COCA": 0,
	"CHICHA_DE_JORA": 0,
	"FRAGMENTO_DE_ILLAPA": 0,
	"QUIPU": 0,
	"ILLA": 0,
	"SEMILLA_DE_PACHAMAMA": 0,
	"ESCAMA_DE_AMARU": 0
}

func add_item(item_name: String, amount: int = 1) -> bool:
	if not inventory.has(item_name):
		return false
	var was_empty := _has_no_items()
	inventory[item_name] += amount
	if was_empty:
		selected_slot = ITEM_ORDER.find(item_name)
		selected_slot_changed.emit(selected_slot)
	inventory_changed.emit(inventory)
	return true

func consume_item(item_name: String) -> bool:
	if inventory.get(item_name, 0) <= 0:
		return false
	inventory[item_name] -= 1
	inventory_changed.emit(inventory)
	if inventory[item_name] <= 0:
		cycle_next_available_slot()
	return true

func cycle_next_available_slot() -> void:
	for offset in range(1, ITEM_ORDER.size() + 1):
		var idx: int = (selected_slot + offset) % ITEM_ORDER.size()
		if inventory.get(ITEM_ORDER[idx], 0) > 0:
			selected_slot = idx
			selected_slot_changed.emit(selected_slot)
			return

func get_selected_item_name() -> String:
	if selected_slot >= 0 and selected_slot < ITEM_ORDER.size():
		return ITEM_ORDER[selected_slot]
	return ""

func _has_no_items() -> bool:
	for count in inventory.values():
		if count > 0:
			return false
	return true

func reset_run() -> void:
	level = 1
	experience = 0
	bonus_damage = 0
	bonus_speed = 0
	bonus_max_hp = 0
	bonus_max_energy = 0.0
	selected_slot = 0
	for key in inventory.keys():
		inventory[key] = 0
	inventory_changed.emit(inventory)
	selected_slot_changed.emit(selected_slot)
