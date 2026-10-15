extends Camera2D

@export var target: Node2D
@export var follow_speed: float = 8.0
func _process(delta: float) -> void:
	if target == null:
		return
	global_position = global_position.lerp(
		target.global_position,
		1.0 - exp(-follow_speed * delta)
)
