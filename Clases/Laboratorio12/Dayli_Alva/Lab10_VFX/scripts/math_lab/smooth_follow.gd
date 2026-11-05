extends Node2D

@export var smoothness := 7.0
@export var target: Node2D

func _process(delta: float) -> void:
	if target == null:
		return

	var weight := 1.0 - exp(-smoothness * delta)
	global_position = global_position.lerp(
		target.global_position,
		weight
	)
