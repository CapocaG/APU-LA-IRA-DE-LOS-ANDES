extends Area2D

@export var mud_speed: float = 120.0
@export var normal_speed: float = 320.0

func _on_mud_zone_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		body.max_speed = mud_speed

func _on_mud_zone_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		body.max_speed = normal_speed
