extends Area2D

signal activated(new_spawn_position: Vector2)
@onready var spawn_point: Marker2D = $SpawnPoint
var is_active: bool = false
func _ready() -> void:
	body_entered.connect(_on_body_entered)
func _on_body_entered(body: Node2D) -> void:
	if is_active:
		return
	if not body.is_in_group("player"):
		return
	is_active = true
	activated.emit(spawn_point.global_position)
