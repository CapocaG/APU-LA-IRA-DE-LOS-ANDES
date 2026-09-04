extends CharacterBody2D

@export_category("Horizontal Movement")
@export var max_speed: float = 280.0
@export var acceleration: float = 1700.0
@export var deceleration: float = 1900.0

@export_category("Jump")
@export var gravity: float = 1500.0
@export var jump_velocity: float = -540.0
@export var jump_cut_multiplier: float = 0.45
@export_category("Jump Assist")
@export var coyote_time: float = 0.12

var coyote_timer: float = 0.0

@export var jump_buffer_time: float = 0.12

var jump_buffer_timer: float = 0.0
var jumps_remaining: int = 1
var was_on_floor: bool = false

@export_category("Wall")
@export var wall_slide_speed: float = 110.0

@export var wall_jump_horizontal_speed: float = 320.0
@export var wall_jump_vertical_speed: float = -480.0

@export_category("Dash")
@export var dash_speed: float = 700.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.45
var air_dash_available: bool = true

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var facing_direction: float = 1.0

@onready var landing_particles: GPUParticles2D = $LandingParticles

func _physics_process(delta: float) -> void:
	_update_coyote_time(delta)
	_update_jump_buffer(delta)
	_update_dash(delta)

	if not is_dashing:
		_apply_gravity(delta)
		_update_horizontal_movement(delta)
		_try_jump()
		_try_wall_jump()
		_apply_jump_cut()
		_apply_wall_slide()

	_try_start_dash()
	move_and_slide()

	if is_on_floor() and not was_on_floor:
		landing_particles.restart()

	if is_on_floor():
		jumps_remaining = 1
		air_dash_available = true

	was_on_floor = is_on_floor()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta


func _update_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := direction * max_speed

	if direction != 0.0:
		facing_direction = sign(direction)
		velocity.x = move_toward(
			velocity.x,
			target_speed,
			acceleration * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			deceleration * delta
		)
		
func _update_coyote_time(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)
		
func _update_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(
			jump_buffer_timer - delta,
			0.0
		)
		
func _try_jump() -> void:
	if jump_buffer_timer > 0.0:
		if coyote_timer > 0.0:
			velocity.y = jump_velocity
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
			jumps_remaining = 1
		elif jumps_remaining > 0:
			velocity.y = jump_velocity
			jump_buffer_timer = 0.0
			jumps_remaining -= 1
		
func _apply_jump_cut() -> void:
	if (
		Input.is_action_just_released("jump")
		and velocity.y < 0.0
	):
		velocity.y *= jump_cut_multiplier
		
func _apply_wall_slide() -> void:
	if is_on_wall() and not is_on_floor() and velocity.y > 0.0:
		velocity.y = min(
			velocity.y,
			wall_slide_speed
		)
		
func _try_wall_jump() -> void:
	if (
		Input.is_action_just_pressed("jump")
		and is_on_wall()
		and not is_on_floor()
	):
		var wall_normal := get_wall_normal()
		velocity.x = wall_normal.x * wall_jump_horizontal_speed
		velocity.y = wall_jump_vertical_speed
		
func _try_start_dash() -> void:
	if (
		Input.is_action_just_pressed("dash")
		and dash_cooldown_timer <= 0.0
		and not is_dashing
		and (is_on_floor() or air_dash_available)
	):
		is_dashing = true
		if not is_on_floor():
			air_dash_available = false
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown
		
func _update_dash(delta: float) -> void:
	dash_cooldown_timer = max(
		dash_cooldown_timer - delta,
		0.0
	)

	if not is_dashing:
		return

	dash_timer -= delta
	velocity.x = facing_direction * dash_speed
	velocity.y = 0.0

	if dash_timer <= 0.0:
		is_dashing = false
