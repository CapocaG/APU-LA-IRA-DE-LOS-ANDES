extends Area2D

signal activated(new_spawn_position: Vector2)

@onready var spawn_point: Marker2D = $SpawnPoint
@export var checkpoint_id: StringName = &""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var resolved_id := checkpoint_id if checkpoint_id != &"" else StringName(name)
		EventBus.checkpoint_activated.emit(resolved_id)
		activated.emit(spawn_point.global_position)
