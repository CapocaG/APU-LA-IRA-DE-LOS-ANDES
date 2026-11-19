class_name MovementComponent
extends Node

@export var max_speed: float = 280.0
@export var acceleration: float = 1700.0
@export var deceleration: float = 1900.0

func configure_from_stats(stats: CharacterStats) -> void:
	assert(stats != null, "MovementComponent requiere CharacterStats.")
	max_speed = stats.move_speed
	acceleration = stats.acceleration

func calculate_horizontal_velocity(
	current_velocity_x: float,
	input_axis: float,
	delta: float
) -> float:
	var target := input_axis * max_speed
	var rate := acceleration if input_axis != 0.0 else deceleration
	return move_toward(current_velocity_x, target, rate * delta)
