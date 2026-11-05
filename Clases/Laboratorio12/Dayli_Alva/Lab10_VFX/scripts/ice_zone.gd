extends Area2D

@export var ice_deceleration: float = 120.0
@export var normal_deceleration: float = 1800.0

func _on_ice_zone_body_entered(body: Node2D) -> void:
	var movement := body.get_node_or_null("MovementComponent") as MovementComponent
	if movement != null:
		movement.deceleration = ice_deceleration

func _on_ice_zone_body_exited(body: Node2D) -> void:
	var movement := body.get_node_or_null("MovementComponent") as MovementComponent
	if movement != null:
		movement.deceleration = normal_deceleration
