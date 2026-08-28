extends CharacterBody2D
@export_category("Movement")
@export var max_speed: float = 320.0
@export var acceleration: float = 1400.0
@export var deceleration: float = 1800.0
func _physics_process(delta: float) -> void:
	_update_movement(delta)
	move_and_slide()
	_inspect_collisions()
func _update_movement(delta: float) -> void:
	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)
	var target_velocity := input_direction * max_speed

	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(
			target_velocity,
			acceleration * delta
		)
	else:
		velocity = velocity.move_toward(
		Vector2.ZERO,
		deceleration * delta
		)
	
func _inspect_collisions() -> void:
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider != null:
			print(
				"Colisión con: ",
				collider.name,
				" | Normal: ",
				collision.get_normal()
				)
