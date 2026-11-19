extends Node2D

@export_file("*.tscn") var next_level_path: String = "res://scenes/levels/level_2.tscn"
@export var next_level_title: String = "Nivel II: Dominios de Illapa"
@export var transition_video: VideoStream # Opcional: arrastra aquí un archivo .ogv si tienes uno
@export var is_final_level: bool = false

@export_group("Final Level Ending")
@export_file("*.tscn") var main_menu_path: String = "res://scenes/ui/main_menu.tscn"
@export var final_chapter_title: String = "FIN - APU: LA IRA DE LOS ANDES"

@onready var exit_portal: Area2D = $ExitPortal

var enemies_remaining: int = 0
var portal_unlocked: bool = false
var entering_portal: bool = false

func _ready() -> void:
	exit_portal.visible = false
	exit_portal.set_deferred("monitoring", false)
	if exit_portal.has_node("PillarCollisions/LeftPillarShape"):
		$ExitPortal/PillarCollisions/LeftPillarShape.set_deferred("disabled", true)
		$ExitPortal/PillarCollisions/RightPillarShape.set_deferred("disabled", true)

	exit_portal.body_entered.connect(_on_exit_portal_body_entered)
	exit_portal.area_entered.connect(_on_exit_portal_area_entered)

	var enemies := get_tree().get_nodes_in_group("enemies")
	enemies_remaining = enemies.size()
	print("Enemigos detectados en el nivel: ", enemies_remaining)
	for enemy in enemies:
		enemy.tree_exited.connect(_on_enemy_defeated)

func _on_enemy_defeated() -> void:
	if not is_inside_tree():
		return
	enemies_remaining -= 1
	print("Enemigos restantes: ", enemies_remaining)
	if enemies_remaining <= 0 and not portal_unlocked:
		_unlock_portal()

func _unlock_portal() -> void:
	portal_unlocked = true
	exit_portal.visible = true
	exit_portal.set_deferred("monitoring", true)
	if exit_portal.has_node("PillarCollisions/LeftPillarShape"):
		$ExitPortal/PillarCollisions/LeftPillarShape.set_deferred("disabled", false)
		$ExitPortal/PillarCollisions/RightPillarShape.set_deferred("disabled", false)

	# Animación de aparición y brillo pulsante
	exit_portal.scale = Vector2(0.5, 0.5)
	exit_portal.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var intro := create_tween().set_parallel(true)
	intro.tween_property(exit_portal, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro.tween_property(exit_portal, "modulate:a", 1.0, 0.35)

	var pulse := create_tween().set_loops()
	pulse.tween_property(exit_portal, "modulate", Color(1.3, 1.45, 1.6, 1.0), 0.8)
	pulse.tween_property(exit_portal, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.8)

func _on_exit_portal_area_entered(area: Area2D) -> void:
	if area.owner != null:
		_on_exit_portal_body_entered(area.owner)

func _on_exit_portal_body_entered(body: Node2D) -> void:
	if not portal_unlocked or entering_portal:
		return
	if body.is_in_group("player") or body.name == "Player":
		entering_portal = true

		# Inmoviliza a Kuya para que no siga caminando durante la animación
		body.set_physics_process(false)
		body.set_process_unhandled_input(false)

		# Efecto de succión hacia el centro del vórtice
		var vortex_center := exit_portal.global_position + Vector2(0, -16)
		var suck_tween := create_tween().set_parallel(true)
		suck_tween.tween_property(body, "global_position", vortex_center, 0.65).set_ease(Tween.EASE_IN)
		suck_tween.tween_property(body, "scale", Vector2(0.1, 0.1), 0.65).set_ease(Tween.EASE_IN)
		suck_tween.tween_property(body, "rotation", TAU, 0.65)
		suck_tween.tween_property(body, "modulate", Color(0.4, 0.9, 1.5, 0.0), 0.65)
		await suck_tween.finished

		if is_final_level:
			if has_node("/root/PlayerData"):
				var data := get_node("/root/PlayerData")
				if data.has_method("reset_run"):
					data.call("reset_run")

			if transition_video != null and ResourceLoader.exists(main_menu_path):
				SceneTransition.change_level(main_menu_path, final_chapter_title, transition_video)
			elif body.has_signal("game_over"):
				body.game_over.emit(true)
			elif ResourceLoader.exists(main_menu_path):
				SceneTransition.change_level(main_menu_path, final_chapter_title, null)
		elif ResourceLoader.exists(next_level_path):
			SceneTransition.change_level(next_level_path, next_level_title, transition_video)
		else:
			push_error("Ruta de Nivel 2 inválida: " + next_level_path)
