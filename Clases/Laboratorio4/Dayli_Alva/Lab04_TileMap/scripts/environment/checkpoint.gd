extends Area2D

signal activated(new_spawn_position: Vector2)

@onready var spawn_point: Marker2D = $SpawnPoint

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	print("ALGO TOCÓ EL CHECKPOINT: ", body.name)

	if body.is_in_group("player"):
		print("¡JUGADOR DETECTADO!")
		activated.emit(spawn_point.global_position)
