extends Control

signal repeat_level(origin: String) 
signal menu(origin: String)

var victoria: bool

func _ready() -> void: 
	if victoria: 
		$VB/Result.set_text("Victoria")

func _on_replay_pressed() -> void:
	repeat_level.emit("escena_final")
	
func _on_menu_pressed() -> void:
	menu.emit("escena_final")
