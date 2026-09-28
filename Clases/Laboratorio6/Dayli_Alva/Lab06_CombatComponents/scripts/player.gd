extends CharacterBody2D

# =========================================================
# ANIMACIÓN Y MÁQUINA DE ESTADOS - SEMANA 5
# =========================================================

@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var state_label: Label = $StateLabel
@onready var sword_hitbox: HitboxComponent = $AttackOrigin/SwordHitbox
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent

var can_attack: bool = true

enum PlayerState {
	IDLE,
	RUN,
	JUMP,
	FALL,
	WALL_SLIDE,
	DASH,
	ATTACK,
	HURT,
	DEAD
}

var current_state: PlayerState = PlayerState.IDLE


# =========================================================
# MOVIMIENTO HORIZONTAL
# =========================================================

@export_category("Horizontal Movement")
@export var max_speed: float = 280.0
@export var acceleration: float = 1700.0
@export var deceleration: float = 1900.0


# =========================================================
# SALTO
# =========================================================

@export_category("Jump")
@export var gravity: float = 1500.0
@export var jump_velocity: float = -540.0
@export var jump_cut_multiplier: float = 0.45


# =========================================================
# ASISTENCIA DE SALTO
# =========================================================

@export_category("Jump Assist")
@export var coyote_time: float = 0.12

var coyote_timer: float = 0.0

@export var jump_buffer_time: float = 0.12

var jump_buffer_timer: float = 0.0
var jumps_remaining: int = 1
var was_on_floor: bool = true


# =========================================================
# PARED
# =========================================================

@export_category("Wall")
@export var wall_slide_speed: float = 110.0
@export var wall_jump_horizontal_speed: float = 320.0
@export var wall_jump_vertical_speed: float = -480.0


# =========================================================
# DASH
# =========================================================

@export_category("Dash")
@export var dash_speed: float = 700.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.45

var air_dash_available: bool = true

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0

var facing_direction: float = 1.0


# =========================================================
# PROCESO PRINCIPAL
# =========================================================

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
	_update_state()
	_update_facing()
	_try_attack()

	if is_on_floor():
		jumps_remaining = 1
		air_dash_available = true

		if not was_on_floor:
			$AnimationPlayer.play("land_squash")
	

	was_on_floor = is_on_floor()
	
	
func _try_attack() -> void:
	if not can_attack:
		return

	if Input.is_action_just_pressed("attack"):
		_change_state(PlayerState.ATTACK)
		

func _enable_attack_hitbox() -> void:
	sword_hitbox.begin_attack()

func _disable_attack_hitbox() -> void:
	sword_hitbox.end_attack()
	
func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		sword_hitbox.end_attack()
		can_attack = true

		if is_on_floor():
			_change_state(PlayerState.IDLE)
		else:
			_change_state(PlayerState.FALL)

# =========================================================
# GRAVEDAD
# =========================================================

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta


# =========================================================
# MOVIMIENTO HORIZONTAL
# =========================================================

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


# =========================================================
# COYOTE TIME
# =========================================================

func _update_coyote_time(delta: float) -> void:

	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(
			coyote_timer - delta,
			0.0
		)


# =========================================================
# JUMP BUFFER
# =========================================================

func _update_jump_buffer(delta: float) -> void:

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	else:
		jump_buffer_timer = max(
			jump_buffer_timer - delta,
			0.0
		)


# =========================================================
# SALTO
# =========================================================

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


# =========================================================
# CORTAR SALTO
# =========================================================

func _apply_jump_cut() -> void:

	if (
		Input.is_action_just_released("jump")
		and velocity.y < 0.0
	):

		velocity.y *= jump_cut_multiplier


# =========================================================
# WALL SLIDE
# =========================================================

func _apply_wall_slide() -> void:

	if (
		is_on_wall()
		and not is_on_floor()
		and velocity.y > 0.0
	):

		velocity.y = min(
			velocity.y,
			wall_slide_speed
		)


# =========================================================
# WALL JUMP
# =========================================================

func _try_wall_jump() -> void:

	if (
		Input.is_action_just_pressed("jump")
		and is_on_wall()
		and not is_on_floor()
	):

		var wall_normal := get_wall_normal()

		velocity.x = wall_normal.x * wall_jump_horizontal_speed
		velocity.y = wall_jump_vertical_speed


# =========================================================
# INICIAR DASH
# =========================================================

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


# =========================================================
# ACTUALIZAR DASH
# =========================================================

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


# =========================================================
# ESTADOS
# =========================================================

func _update_state() -> void:
	if current_state == PlayerState.ATTACK:
		return

	var new_state: PlayerState

	# DASH tiene prioridad
	if is_dashing:

		new_state = PlayerState.DASH

	# WALL SLIDE
	elif (
		is_on_wall()
		and not is_on_floor()
		and velocity.y > 0.0
	):

		new_state = PlayerState.WALL_SLIDE

	# JUMP / FALL
	elif not is_on_floor():

		if velocity.y < 0.0:
			new_state = PlayerState.JUMP
		else:
			new_state = PlayerState.FALL

	# RUN
	elif abs(velocity.x) > 10.0:

		new_state = PlayerState.RUN

	# IDLE
	else:

		new_state = PlayerState.IDLE

	_change_state(new_state)


# =========================================================
# CAMBIAR DE ESTADO
# =========================================================

func _change_state(new_state: PlayerState) -> void:

	# Si ya estamos en ese estado, no reiniciamos la animación
	if current_state == new_state:
		return

	current_state = new_state
	_update_state_label()

	_play_state_animation()

# =========================================================
# StateLabel con color diferente por estado
# =========================================================	
	
func _update_state_label() -> void:
	state_label.text = PlayerState.keys()[current_state]

	match current_state:
		PlayerState.IDLE:
			state_label.modulate = Color.WHITE
		PlayerState.RUN:
			state_label.modulate = Color.GREEN
		PlayerState.JUMP:
			state_label.modulate = Color.YELLOW
		PlayerState.FALL:
			state_label.modulate = Color.ORANGE
		PlayerState.WALL_SLIDE:
			state_label.modulate = Color.CYAN
		PlayerState.DASH:
			state_label.modulate = Color.RED


# =========================================================
# REPRODUCIR ANIMACIÓN SEGÚN ESTADO
# =========================================================

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
			
		PlayerState.ATTACK:
			animated_sprite.play("attack")
			animation_player.play("attack")

		PlayerState.HURT:
			animated_sprite.play("hurt")

		PlayerState.DEAD:
			velocity = Vector2.ZERO
			sword_hitbox.end_attack()
			animated_sprite.play("dead")
			set_process_input(false)

# =========================================================
# DIRECCIÓN DEL PERSONAJE
# =========================================================

func _update_facing() -> void:

	var direction := Input.get_axis(
		"move_left",
		"move_right"
	)

	if direction != 0.0:

		animated_sprite.flip_h = direction < 0.0
		
func _ready() -> void:
	animated_sprite.play("idle")
	hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_died)


func _on_hit_received(
	attack: AttackData,
	direction: Vector2
) -> void:
	if current_state == PlayerState.DEAD:
		return

	velocity = direction * attack.knockback_force
	_change_state(PlayerState.HURT)
	_play_invulnerability_feedback(attack.invulnerability_time)


func _on_died() -> void:
	_change_state(PlayerState.DEAD)
	
func _play_invulnerability_feedback(duration: float) -> void:
	var elapsed := 0.0

	while elapsed < duration:
		$Visuals.visible = not $Visuals.visible
		await get_tree().create_timer(0.06).timeout
		elapsed += 0.06

	$Visuals.visible = true
