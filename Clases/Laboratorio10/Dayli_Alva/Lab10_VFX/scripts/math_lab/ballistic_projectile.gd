class_name BallisticProjectile
extends Node2D

@export var lifetime := 3.0
@export var debug_radius := 7.0

var origin := Vector2.ZERO
var initial_velocity := Vector2.ZERO
var acceleration := Vector2.ZERO
var age := 0.0
var launched := false

func launch(
	from_position: Vector2,
	velocity_at_start: Vector2,
	gravity_vector: Vector2
) -> void:
	origin = from_position
	global_position = origin
	initial_velocity = velocity_at_start
	acceleration = gravity_vector
	age = 0.0
	launched = true

func _physics_process(delta: float) -> void:
	if not launched:
		return

	age += delta
	global_position = (
		origin
		+ initial_velocity * age
		+ 0.5 * acceleration * age * age
	)

	if age >= lifetime:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, debug_radius, Color("#E89042"))
	draw_circle(Vector2.ZERO, 2.0, Color.WHITE)
