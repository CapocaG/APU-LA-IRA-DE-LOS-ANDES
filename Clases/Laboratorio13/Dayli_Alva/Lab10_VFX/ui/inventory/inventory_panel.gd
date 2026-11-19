class_name InventoryPanel
extends Control

signal close_requested

const SLOT_SCENE: PackedScene = preload("res://ui/inventory/InventorySlot.tscn")

@onready var grid: GridContainer = $CenterContainer/PanelContainer/VBoxContainer/Body/ScrollContainer/GridContainer
@onready var close_button: Button = $CenterContainer/PanelContainer/VBoxContainer/Header/CloseButton
@onready var name_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Body/DetailsPanel/Name
@onready var description_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Body/DetailsPanel/Description
@onready var use_button: Button = $CenterContainer/PanelContainer/VBoxContainer/Footer/UseButton

var inventory: InventoryComponent
var item_database: ItemDatabase
var selected_index: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	close_button.pressed.connect(close_inventory)
	use_button.pressed.connect(_use_selected_item)

func bind_inventory(source: InventoryComponent, database: ItemDatabase) -> void:
	inventory = source
	item_database = database
	if not inventory.inventory_changed.is_connected(refresh):
		inventory.inventory_changed.connect(refresh)
	refresh()

func open_inventory() -> void:
	visible = true
	refresh()
	if grid.get_child_count() > 0:
		var first_slot := grid.get_child(0) as InventorySlotUI
		if first_slot != null and not first_slot.disabled:
			first_slot.grab_focus()
		else:
			close_button.grab_focus()
	else:
		close_button.grab_focus()

func close_inventory() -> void:
	visible = false
	close_requested.emit()

func refresh() -> void:
	if grid == null or inventory == null or item_database == null:
		return
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	for index in range(inventory.slots.size()):
		var slot_ui := SLOT_SCENE.instantiate() as InventorySlotUI
		slot_ui.slot_index = index
		slot_ui.inventory = inventory
		slot_ui.item_database = item_database
		slot_ui.slot_selected.connect(_on_slot_selected)
		slot_ui.focus_entered.connect(_on_slot_focused.bind(index))
		grid.add_child(slot_ui)

		var slot_data := inventory.slots[index]
		if slot_data.is_empty():
			slot_ui.display(null, 0)
		else:
			var item := item_database.get_item(StringName(slot_data.get("item_id", "")))
			slot_ui.display(item, int(slot_data.get("quantity", 0)))

	if visible and grid.get_child_count() > 0:
		var focused_slot := grid.get_child(clampi(selected_index, 0, grid.get_child_count() - 1)) as Control
		if focused_slot is Button and not (focused_slot as Button).disabled:
			focused_slot.grab_focus()
		else:
			close_button.grab_focus()
	_update_details(selected_index)

func _on_slot_selected(index: int) -> void:
	selected_index = index
	_update_details(index)

func _on_slot_focused(index: int) -> void:
	selected_index = index
	_update_details(index)

func _update_details(index: int) -> void:
	if inventory == null or item_database == null or index < 0 or index >= inventory.slots.size():
		name_label.text = ""
		description_label.text = ""
		use_button.disabled = true
		return
	var slot_data := inventory.slots[index]
	if slot_data.is_empty():
		name_label.text = ""
		description_label.text = ""
		use_button.disabled = true
		return
	var item := item_database.get_item(StringName(slot_data.get("item_id", "")))
	if item == null:
		name_label.text = ""
		description_label.text = ""
		use_button.disabled = true
		return
	name_label.text = "%s x%d" % [item.display_name, int(slot_data.get("quantity", 0))]
	description_label.text = item.description
	use_button.disabled = not item.consumable

func _use_selected_item() -> void:
	if inventory == null or selected_index < 0 or selected_index >= inventory.slots.size():
		return
	var slot_data := inventory.slots[selected_index]
	if slot_data.is_empty():
		return
	var item_id := StringName(slot_data.get("item_id", ""))
	var item := item_database.get_item(item_id)
	if item == null or not item.consumable:
		return
	inventory.consume_one(item_id)
