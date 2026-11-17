extends Control

signal intro_finished

@onready var video_player: VideoStreamPlayer = $VideoPlayer

func _ready() -> void:
	video_player.finished.connect(_finish_intro)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_finish_intro()
	elif event is InputEventMouseButton and event.pressed:
		_finish_intro()

func _finish_intro() -> void:
	set_process_unhandled_input(false)
	intro_finished.emit()
