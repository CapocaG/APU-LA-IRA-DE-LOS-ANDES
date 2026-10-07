extends Node2D

@export var center: Marker2D
@export_range(20.0, 400.0, 1.0) var radius_x := 175.0
@export_range(20.0, 400.0, 1.0) var radius_y := 85.0
@export var angular_speed := 1.2

var angle_radians := 0.0

func _physics_process(delta: float) -> void:
	if center == null:
		return
	angle_radians = wrapf(
		angle_radians + angular_speed * delta,
		0.0,
		TAU
	)

	global_position = center.global_position + Vector2(
		cos(angle_radians) * radius_x,
		sin(angle_radians) * radius_y
	)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 13.0, Color("#EDAE49"))
	draw_arc(
		Vector2.ZERO,
		16.0,
		0.0,
		TAU,
		32,
		Color("#183E64"),
		2.0
	)
