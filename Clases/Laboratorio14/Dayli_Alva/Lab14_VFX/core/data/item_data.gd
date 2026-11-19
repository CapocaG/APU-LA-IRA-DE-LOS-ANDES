class_name ItemData
extends Resource

@export var item_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var max_stack: int = 99
@export var consumable: bool = false
