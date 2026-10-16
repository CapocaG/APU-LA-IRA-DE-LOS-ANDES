extends CharacterBody2D
enum PlayerState {
IDLE,
RUN,
JUMP,
FALL,
WALL_SLIDE,
DASH
}
var current_state: PlayerState = PlayerState.IDLE


@onready var animated_sprite: AnimatedSprite2D = (
	$Visuals/AnimatedSprite2D
	)
@export_category("Horizontal Movement")
@export var max_speed: float = 260.0
@export var acceleration: float = 1500.0
@export var deceleration: float = 1900.0

@export_category("Jump")
@export var gravity: float = 1500.0
@export var jump_velocity: float = -520.0
@export var jump_cut_multiplier: float = 0.45
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

@export_category("Wall")
@export var wall_slide_speed: float = 110.0
@export var wall_jump_horizontal_speed: float = 320.0
@export var wall_jump_vertical_speed: float = -480.0

@export_category("Dash")
@export var dash_speed: float = 650.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.45

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_state_machine: AnimationNodeStateMachinePlayback = (
animation_tree.get("parameters/playback")
)

var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var facing_direction: float = 1.0

var was_on_floor: bool = false

func _ready() -> void:
	animation_tree.active = true
	animation_state_machine.start("Idle")

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
	move_and_slide()
	if is_on_floor() and not was_on_floor:
		$AnimationPlayer.play("land_squash")
		was_on_floor = is_on_floor()
	_update_state()
	_update_facing_from_input()


func _try_start_dash() -> void:
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing:
		is_dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown


func _update_dash(delta: float) -> void:
	dash_cooldown_timer = max(dash_cooldown_timer - delta, 0.0)
	
	if not is_dashing:
		return
		
	dash_timer -= delta
	velocity.x = facing_direction * dash_speed
	velocity.y = 0.0
	
	if dash_timer <= 0.0:
		is_dashing = false


func _apply_wall_slide() -> void:
	if is_on_wall() and not is_on_floor() and velocity.y > 0.0:
		velocity.y = min(velocity.y, wall_slide_speed)

	
func _try_wall_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_wall() and not is_on_floor():
		var wall_normal := get_wall_normal()
		velocity.x = wall_normal.x * wall_jump_horizontal_speed
		velocity.y = wall_jump_vertical_speed

	
func _apply_jump_cut() -> void:
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta


func _update_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := direction * max_speed
	
	if direction != 0.0:
		facing_direction = sign(direction)
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

		
func _update_coyote_time(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

		
func _update_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)


func _try_jump() -> void:
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

func _update_facing(direction: float) -> void:
	if direction == 0.0:
		return
	animated_sprite.flip_h = direction < 0.0

func _update_state() -> void:
	if is_dashing:
		_change_state(PlayerState.DASH)
		return
	if is_on_wall() and not is_on_floor() and velocity.y > 0.0:
		_change_state(PlayerState.WALL_SLIDE)
		return
	if not is_on_floor():
		if velocity.y < 0.0:
			_change_state(PlayerState.JUMP)
		else:
			_change_state(PlayerState.FALL)
		return
	if abs(velocity.x) > 10.0:
		_change_state(PlayerState.RUN)
	else:
		_change_state(PlayerState.IDLE)

func _change_state(new_state: PlayerState) -> void:
	if new_state == current_state:
		return
	_exit_state(current_state)
	current_state = new_state
	_enter_state(current_state)
func _enter_state(state: PlayerState) -> void:
	match state:
		PlayerState.DASH:
			animated_sprite.play("dash")
		_:
			_play_state_animation()
func _exit_state(state: PlayerState) -> void:
	match state:
		PlayerState.DASH:
			pass
	
func _play_state_animation() -> void:
	match current_state:
		PlayerState.IDLE:
			animated_sprite.play("idle")
		PlayerState.RUN:
			animated_sprite.play("run")
		PlayerState.JUMP:
			animated_sprite.play("jump")
		PlayerState.FALL:
			animated_sprite.play("fall")
		PlayerState.WALL_SLIDE:
			animated_sprite.play("wall_slide")
		PlayerState.DASH:
			animated_sprite.play("dash")

func _update_facing_from_input() -> void:
	var direction := Input.get_axis(
		"move_left",
		"move_right"
		)
	if direction != 0.0:
		animated_sprite.flip_h = direction < 0.0
