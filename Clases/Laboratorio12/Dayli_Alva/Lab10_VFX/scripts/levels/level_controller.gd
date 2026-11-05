extends Node

@export var level_data: LevelData
@export var player_path: NodePath = NodePath("../Player")
@export var default_spawn_path: NodePath = NodePath("../DefaultSpawn")
@export var ui_path: NodePath = NodePath("../CanvasLayer")
@export var require_all_items_before_exit: bool = false

var player: CharacterBody2D
var default_spawn: Marker2D
var checkpoint_positions: Dictionary = {}
var _respawn_in_progress: bool = false
var _next_level_button: Button
var _restart_button: Button


func _ready() -> void:
	assert(level_data != null, "LevelController requiere LevelData.")
	player = get_node_or_null(player_path) as CharacterBody2D
	default_spawn = get_node_or_null(default_spawn_path) as Marker2D
	assert(player != null, "LevelController no encuentra al Player.")
	assert(default_spawn != null, "LevelController no encuentra DefaultSpawn.")

	GameState.current_level_id = level_data.level_id
	_register_checkpoints()
	_connect_hazards()
	_connect_player_death()
	_place_player_from_state()
	_setup_level_buttons()

func _register_checkpoints() -> void:
	checkpoint_positions.clear()
	for node in get_tree().get_nodes_in_group("checkpoint"):
		var checkpoint := node as Area2D
		if checkpoint == null:
			continue
		var checkpoint_id := StringName(checkpoint.get("checkpoint_id"))
		var spawn_point := checkpoint.get_node_or_null("SpawnPoint") as Marker2D
		if checkpoint_id == &"" or spawn_point == null:
			push_warning("Checkpoint inválido en nivel %s." % level_data.level_id)
			continue
		checkpoint_positions[checkpoint_id] = spawn_point.global_position
		var active := checkpoint_id == GameState.active_checkpoint_id
		if checkpoint.has_method("set_active"):
			checkpoint.call("set_active", active)
		if checkpoint.has_signal("activated"):
			var callback := _on_checkpoint_activated.bind(checkpoint)
			if not checkpoint.is_connected("activated", callback):
				checkpoint.connect("activated", callback)


func _connect_hazards() -> void:
	for hazard in get_tree().get_nodes_in_group("hazard"):
		if hazard.has_signal("player_touched_hazard"):
			var callback := _on_hazard_touched
			if not hazard.is_connected("player_touched_hazard", callback):
				hazard.connect("player_touched_hazard", callback)

func _connect_player_death() -> void:
	if player.has_signal("died") and not player.is_connected("died", _on_player_died):
		player.connect("died", _on_player_died)

func _place_player_from_state() -> void:
	var spawn_position := default_spawn.global_position
	var checkpoint_id := GameState.active_checkpoint_id
	if checkpoint_id != &"":
		if checkpoint_positions.has(checkpoint_id):
			spawn_position = checkpoint_positions[checkpoint_id]
		else:
			GameState.set_checkpoint(&"")
	player.global_position = spawn_position
	player.velocity = Vector2.ZERO
	var health := player.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		health.reset_health()

func _setup_level_buttons() -> void:
	var ui_root := get_node_or_null(ui_path)
	if ui_root == null:
		return
	_next_level_button = ui_root.get_node_or_null("NextLevelButton") as Button
	_restart_button = ui_root.get_node_or_null("RestartCheckpointButton") as Button
	if _next_level_button != null:
		_next_level_button.text = "Finalizar" if level_data.next_level_id == &"" else "Continuar"
		_next_level_button.pressed.connect(complete_level)
		_next_level_button.disabled = require_all_items_before_exit
	if _restart_button != null:
		_restart_button.pressed.connect(respawn_from_checkpoint)

func unlock_exit() -> void:
	if _next_level_button != null:
		_next_level_button.disabled = false

func complete_level() -> void:
	if level_data.next_level_id == &"":
		GameState.set_checkpoint(&"")
		EventBus.level_completed.emit(level_data.level_id)
		SaveManager.save_game()
		if _next_level_button != null:
			_next_level_button.text = "Nivel completado"
			_next_level_button.disabled = true
		return

	GameState.set_checkpoint(&"")
	EventBus.level_completed.emit(level_data.level_id)
	GameState.current_level_id = level_data.next_level_id
	SaveManager.save_game()
	SceneFlow.go_to_level(level_data.next_level_id)

func _on_checkpoint_activated(
	checkpoint_id: StringName,
	spawn_position: Vector2,
	checkpoint: Area2D
) -> void:
	GameState.set_checkpoint(checkpoint_id)
	checkpoint_positions[checkpoint_id] = spawn_position
	for node in get_tree().get_nodes_in_group("checkpoint"):
		if node.has_method("set_active"):
			node.call("set_active", node == checkpoint)
	SaveManager.save_game()

func _on_hazard_touched() -> void:
	respawn_from_checkpoint()

func _on_player_died() -> void:
	if not _respawn_in_progress:
		_respawn_in_progress = true
		_respawn_after_delay()

func _respawn_after_delay() -> void:
	await get_tree().create_timer(0.8).timeout
	_respawn_player()
	_respawn_in_progress = false

func respawn_from_checkpoint() -> void:
	_respawn_player()

func _respawn_player() -> void:
	if not is_instance_valid(player):
		return
	var spawn_position := default_spawn.global_position
	if checkpoint_positions.has(GameState.active_checkpoint_id):
		spawn_position = checkpoint_positions[GameState.active_checkpoint_id]
	if player.has_method("reset_for_respawn"):
		player.call("reset_for_respawn", spawn_position)
	else:
		player.global_position = spawn_position
		player.velocity = Vector2.ZERO
		var health := player.get_node_or_null("HealthComponent") as HealthComponent
		if health != null:
			health.reset_health()
	GameState.player_is_dead = false
	_respawn_in_progress = false
