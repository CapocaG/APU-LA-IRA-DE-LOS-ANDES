class_name ToastNotification
extends PanelContainer

@export var message: String = ""

@onready var label: Label = $Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = message
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.14)
	tween.tween_interval(1.8)
	tween.tween_property(self, "modulate:a", 0.0, 0.24)
	tween.tween_callback(queue_free)
