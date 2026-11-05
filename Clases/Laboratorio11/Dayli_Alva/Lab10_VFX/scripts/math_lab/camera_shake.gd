class_name MathCamera
extends Camera2D

@export var decay_rate := 8.0
@export var shake_frequency_x := 22.0
@export var shake_frequency_y := 31.0

var shake_time := 0.0
var shake_strength := 0.0


func trigger_shake(strength: float) -> void:
	shake_strength = max(
		shake_strength,
		max(strength, 0.0)
	)
	shake_time = 0.0


func _process(delta: float) -> void:
	if shake_strength < 0.05:
		shake_strength = 0.0
		offset = Vector2.ZERO
		return

	shake_time += delta
	shake_strength *= exp(-decay_rate * delta)

	offset = Vector2(
		sin(shake_time * shake_frequency_x),
		sin(shake_time * shake_frequency_y)
	) * shake_strength
