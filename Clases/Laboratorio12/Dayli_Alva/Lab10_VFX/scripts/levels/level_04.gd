extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var vfx_lab_button: Button = get_node_or_null("CanvasLayer/VFXLabButton") as Button

var respawn_position: Vector2


func _ready() -> void:
	GameState.current_level_id = &"level_04"
	respawn_position = player_spawn.global_position
	_connect_hazards()
	_connect_checkpoints()
	_respawn_player()
	if vfx_lab_button != null:
		vfx_lab_button.pressed.connect(_on_vfx_lab_button_pressed)


func _on_vfx_lab_button_pressed() -> void:
	SceneFlow.change_to("res://scenes/levels/vfx_lab.tscn")


func _connect_hazards() -> void:
	for hazard in get_tree().get_nodes_in_group("hazard"):
		hazard.player_touched_hazard.connect(
			_on_player_touched_hazard
		)


func _connect_checkpoints() -> void:
	for checkpoint in get_tree().get_nodes_in_group("checkpoint"):
		checkpoint.activated.connect(
			_on_checkpoint_activated
		)


func _on_player_touched_hazard() -> void:
	_respawn_player()


func _on_checkpoint_activated(
	_checkpoint_id: StringName,
	new_spawn_position: Vector2
) -> void:
	respawn_position = new_spawn_position


func _respawn_player() -> void:
	player.global_position = respawn_position
	player.velocity = Vector2.ZERO
	player.health.reset_health()
