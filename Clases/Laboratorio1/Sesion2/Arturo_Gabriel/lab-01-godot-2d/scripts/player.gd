extends CharacterBody2D

@export var speed:float = 250.0
func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left","move_right","move_up","move_down")
	velocity = direction * speed
	move_and_slide()
	position.x = clamp(position.x, 32.0, 1248.0)
	position.y = clamp(position.y, 32.0, 688.0)
