extends Node2D

const PROJECTILE_SCENE: PackedScene = preload(
	"res://scenes/math_lab/ballistic_projectile.tscn"
)

@export var projectile_speed := 550.0
@export var gravity_strength := 900.0

@onready var launch_point: Marker2D = $LaunchPoint
@onready var game_camera: MathCamera = $Camera2D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if (
			event.button_index == MOUSE_BUTTON_LEFT
			and event.pressed
		):
			_fire_projectile()
	if event is InputEventKey:
		if (
			event.keycode == KEY_SPACE
			and event.pressed
			and not event.echo
		):
			game_camera.trigger_shake(9.0)

func _fire_projectile() -> void:
	var from_position := launch_point.global_position
	var target := get_global_mouse_position()
	var difference := target - from_position

	if difference.length_squared() < 0.0001:
		return

	var direction := difference.normalized()
	var projectile := (
		PROJECTILE_SCENE.instantiate()
		as BallisticProjectile
	)
	add_child(projectile)

	projectile.launch(
		from_position,
		direction * projectile_speed,
		Vector2(0.0, gravity_strength)
	)	
var active_tween: Tween

func highlight_visual(visual: Node2D) -> void:
	if active_tween != null:
		active_tween.kill()

	visual.scale = Vector2.ONE
	active_tween = create_tween()
	active_tween.tween_property(
		visual,
		"scale",
		Vector2(1.25, 1.25),
		0.12
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_OUT
	)
	active_tween.tween_property(
		visual,
		"scale",
		Vector2.ONE,
		0.18
	)

func is_target_in_fov(
	enemy_position: Vector2,
	target_position: Vector2,
	facing: Vector2,
	half_angle_degrees: float
) -> bool:
	var offset := target_position - enemy_position
	if offset.length_squared() < 0.0001:
		return true
	var look := facing.normalized()
	var toward := offset.normalized()

	var threshold := cos(
		deg_to_rad(half_angle_degrees)
	)
	return look.dot(toward) >= threshold
