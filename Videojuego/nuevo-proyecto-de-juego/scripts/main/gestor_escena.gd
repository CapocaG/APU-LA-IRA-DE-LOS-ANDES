extends Node

@export var menu_packed: PackedScene
@export var intro_packed: PackedScene
@export var level_packed: PackedScene

func _ready() -> void:
	load_menu("game_start")

func load_menu(origin: String) -> void:
	if origin == "escena_final":
		get_node("GameScene").queue_free()
	var menu: Control = menu_packed.instantiate()
	menu.nuevo_juego_pressed.connect(nuevo_juego)
	menu.continuar_pressed.connect(settings_open)
	menu.opciones_pressed.connect(about_open)
	menu.salir_pressed.connect(exit_game)
	add_child(menu)

func nuevo_juego(origin: String) -> void:
	if origin == "menu":
		get_node("Menu").queue_free()
		_start_intro()
		return
	if origin == "escena_final":
		get_node("GameScene").queue_free()
		await get_tree().process_frame
	_start_level()

func _start_intro() -> void:
	var intro: Control = intro_packed.instantiate()
	intro.intro_finished.connect(_on_intro_finished.bind(intro))
	add_child(intro)

func _on_intro_finished(intro_node: Control) -> void:
	if is_instance_valid(intro_node):
		intro_node.queue_free()
	await get_tree().process_frame
	_start_level()

func _start_level() -> void:
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
