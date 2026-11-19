class_name Checkpoint
extends Area2D

signal activated(checkpoint_id: StringName, spawn_position: Vector2)

@export var checkpoint_id: StringName = &""

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var flag_sprite: Sprite2D = $Sprite2D

var is_active: bool = false

func _ready() -> void:
	add_to_group("checkpoint")
	body_entered.connect(_on_body_entered)
	set_active(false)

func set_active(active: bool) -> void:
	is_active = active
	if flag_sprite != null:
		flag_sprite.modulate = Color(0.55, 1.0, 0.58, 1.0) if active else Color.WHITE

func _on_body_entered(body: Node2D) -> void:
	if is_active or not body.is_in_group("player"):
		return
	if checkpoint_id == &"":
		push_warning("Checkpoint sin ID estable: %s" % name)
		return

	set_active(true)
	EventBus.checkpoint_activated.emit(checkpoint_id)
	activated.emit(checkpoint_id, spawn_point.global_position)
