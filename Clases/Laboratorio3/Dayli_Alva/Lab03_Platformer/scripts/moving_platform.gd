extends AnimatableBody2D

@export var move_distance: float = 150.0
@export var move_speed: float = 100.0

var start_position: Vector2
var direction: float = 1.0

func _ready() -> void:
	start_position = position

func _physics_process(delta: float) -> void:
	position.x += direction * move_speed * delta

	if position.x >= start_position.x + move_distance:
		direction = -1.0

	elif position.x <= start_position.x:
		direction = 1.0
