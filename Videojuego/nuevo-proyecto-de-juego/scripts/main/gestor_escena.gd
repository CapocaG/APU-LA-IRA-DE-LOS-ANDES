extends Node

@export var menu_packed: PackedScene
@export var level_packed: PackedScene

func _ready() -> void:
	load_menu("game_start")

@warning_ignore("unused_parameter")
func load_menu(origin: String) -> void:
	var menu: Control = menu_packed.instantiate()
	menu.nuevo_juego_pressed.connect(nuevo_juego)
	menu.continuar_pressed.connect(settings_open)
	menu.opciones_pressed.connect(about_open)
	menu.salir_pressed.connect(exit_game)
	add_child(menu)

@warning_ignore("unused_parameter")
func nuevo_juego(origin: String) -> void:
	if origin == "menu":
		get_node("Menu").queue_free()
		await get_tree().process_frame
	var level: Node2D = level_packed.instantiate()
	add_child(level)

@warning_ignore("unused_parameter")
func settings_open(origin: String) -> void:
	pass

@warning_ignore("unused_parameter")
func about_open(origin: String) -> void:
	pass
	
@warning_ignore("unused_parameter")
func exit_game(origin: String) -> void:
	get_tree().quit()
