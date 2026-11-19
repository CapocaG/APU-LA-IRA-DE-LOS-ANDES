class_name InventorySlotUI
extends Button

signal slot_selected(index: int)

@onready var icon_rect: TextureRect = $Icon
@onready var quantity_label: Label = $QuantityLabel

var slot_index: int = -1
var inventory: InventoryComponent
var item_database: ItemDatabase

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	slot_selected.emit(slot_index)

func display(item: ItemData, quantity: int) -> void:
	if item == null:
		icon_rect.texture = null
		quantity_label.text = ""
		disabled = true
		tooltip_text = ""
		return

	disabled = false
	icon_rect.texture = item.icon
	quantity_label.text = str(quantity) if quantity > 1 else ""
	tooltip_text = "%s\n%s" % [item.display_name, item.description]
