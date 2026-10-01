extends CharacterBody2D

enum EnemyState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	HURT,
	RETURN,
	DEAD
}

@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var detection_area: Area2D = $DetectionArea
@onready var attack_range: Area2D = $AttackRange

@onready var sight_ray: RayCast2D = $SightRay
@onready var floor_ahead_ray: RayCast2D = $FloorAheadRay
@onready var wall_ahead_ray: RayCast2D = $WallAheadRay

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var attack_collision: CollisionShape2D = $HitboxComponent/CollisionShape2D

@export_category("Patrol")
@export var patrol_point_a: Marker2D
@export var patrol_point_b: Marker2D
@export var patrol_speed: float = 90.0
@export var patrol_tolerance: float = 8.0

@export_category("Detection")
@export var lost_sight_grace_time: float = 0.75

@export_category("Movement")
@export var chase_speed: float = 150.0
@export var return_speed: float = 110.0
@export var return_tolerance: float = 10.0
@export var gravity: float = 1500.0

@export_category("Idle")
@export var idle_duration: float = 0.8

@export_category("Attack")
@export var attack_cooldown: float = 1.0

@export_category("Hurt")
@export var hurt_duration: float = 0.25
@export var hurt_knockback: float = 220.0

var current_state: EnemyState = EnemyState.IDLE

var current_patrol_target: Marker2D
var home_position: Vector2

var player: CharacterBody2D = null

var player_in_detection_area: bool = false
var player_in_attack_range: bool = false

var last_known_player_position: Vector2

var lost_sight_time_left: float = 0.0
var idle_time_left: float = 0.0
var attack_cooldown_left: float = 0.0
var hurt_time_left: float = 0.0


func _ready() -> void:
	home_position = global_position

	if patrol_point_b != null:
		current_patrol_target = patrol_point_b

	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)

	attack_range.body_entered.connect(_on_attack_range_body_entered)
	attack_range.body_exited.connect(_on_attack_range_body_exited)

	hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_died)

	_enter_state(current_state)
	_update_debug_label()


func _physics_process(delta: float) -> void:
	if current_state == EnemyState.DEAD:
		return

	_apply_gravity(delta)
	_update_perception(delta)

	attack_cooldown_left = maxf(
		attack_cooldown_left - delta,
		0.0
	)

	match current_state:
		EnemyState.IDLE:
			_update_idle(delta)

		EnemyState.PATROL:
			_update_patrol(delta)

		EnemyState.CHASE:
			_update_chase(delta)

		EnemyState.ATTACK:
			_update_attack(delta)

		EnemyState.HURT:
			_update_hurt(delta)

		EnemyState.RETURN:
			_update_return(delta)

	move_and_slide()
	_update_debug_label()


func _change_state(new_state: EnemyState) -> void:
	if new_state == current_state:
		return

	_exit_state(current_state)

	current_state = new_state

	_enter_state(current_state)


func _enter_state(state: EnemyState) -> void:
	match state:
		EnemyState.IDLE:
			_enter_idle()

		EnemyState.PATROL:
			_enter_patrol()

		EnemyState.CHASE:
			_enter_chase()

		EnemyState.ATTACK:
			_enter_attack()

		EnemyState.HURT:
			_enter_hurt()

		EnemyState.RETURN:
			_enter_return()

		EnemyState.DEAD:
			_enter_dead()


func _exit_state(state: EnemyState) -> void:
	if state == EnemyState.ATTACK:
		animation_player.stop()
		hitbox.end_attack()


# -------------------------
# PERCEPTION
# -------------------------

func _on_detection_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	player = body as CharacterBody2D
	player_in_detection_area = true


func _on_detection_body_exited(body: Node2D) -> void:
	if body != player:
		return

	player_in_detection_area = false


func _on_attack_range_body_entered(body: Node2D) -> void:
	if body == player or body.is_in_group("player"):
		if player == null:
			player = body as CharacterBody2D
		player_in_attack_range = true


func _on_attack_range_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_attack_range = false


func _has_line_of_sight_to_player() -> bool:
	if player == null:
		return false

	if not player_in_detection_area:
		return false

	sight_ray.target_position = sight_ray.to_local(
		player.global_position
	)

	sight_ray.force_raycast_update()

	if not sight_ray.is_colliding():
		return false

	return sight_ray.get_collider() == player


func _update_perception(delta: float) -> void:
	if _has_line_of_sight_to_player():
		last_known_player_position = player.global_position
		lost_sight_time_left = lost_sight_grace_time
	else:
		lost_sight_time_left = maxf(
			lost_sight_time_left - delta,
			0.0
		)


func _can_start_chase() -> bool:
	return (
		player != null
		and player_in_detection_area
		and _has_line_of_sight_to_player()
	)


# -------------------------
# MOVEMENT
# -------------------------

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta


func _move_horizontally_toward(
	target_x: float,
	speed: float
) -> void:
	var direction: float = signf(target_x - global_position.x)

	velocity.x = direction * speed

	_update_facing(direction)


func _should_turn_around() -> bool:
	return (
		not floor_ahead_ray.is_colliding()
		or wall_ahead_ray.is_colliding()
	)


func _switch_patrol_target() -> void:
	if current_patrol_target == patrol_point_a:
		current_patrol_target = patrol_point_b
	else:
		current_patrol_target = patrol_point_a


func _update_facing(direction: float) -> void:
	if direction == 0.0:
		return

	var facing_left := direction < 0.0

	animated_sprite.flip_h = facing_left

	var sensor_sign := -1.0 if facing_left else 1.0

	wall_ahead_ray.target_position.x = (
		absf(wall_ahead_ray.target_position.x)
		* sensor_sign
	)

	floor_ahead_ray.position.x = (
		absf(floor_ahead_ray.position.x)
		* sensor_sign
	)

	attack_collision.position.x = (
		absf(attack_collision.position.x)
		* sensor_sign
	)


# -------------------------
# IDLE
# -------------------------

func _enter_idle() -> void:
	velocity.x = 0.0
	idle_time_left = idle_duration
	animated_sprite.play("idle")


func _update_idle(delta: float) -> void:
	velocity.x = 0.0

	if _can_start_chase():
		_change_state(EnemyState.CHASE)
		return

	idle_time_left -= delta

	if idle_time_left <= 0.0:
		_change_state(EnemyState.PATROL)


# -------------------------
# PATROL
# -------------------------

func _enter_patrol() -> void:
	animated_sprite.play("walk")


func _update_patrol(_delta: float) -> void:
	if _can_start_chase():
		_change_state(EnemyState.CHASE)
		return

	if current_patrol_target == null:
		_change_state(EnemyState.IDLE)
		return

	_move_horizontally_toward(
		current_patrol_target.global_position.x,
		patrol_speed
	)

	if _should_turn_around():
		_switch_patrol_target()
		return

	var distance_x := absf(
		global_position.x
		- current_patrol_target.global_position.x
	)

	if distance_x <= patrol_tolerance:
		_switch_patrol_target()
		_change_state(EnemyState.IDLE)


# -------------------------
# CHASE
# -------------------------

func _enter_chase() -> void:
	animated_sprite.play("run")


func _update_chase(_delta: float) -> void:
	if player == null:
		_change_state(EnemyState.RETURN)
		return

	if _has_line_of_sight_to_player():
		last_known_player_position = player.global_position

	if player_in_attack_range and _has_line_of_sight_to_player():
		_change_state(EnemyState.ATTACK)
		return

	if (
		not player_in_detection_area
		and lost_sight_time_left <= 0.0
	):
		_change_state(EnemyState.RETURN)
		return

	if lost_sight_time_left <= 0.0:
		_change_state(EnemyState.RETURN)
		return

	_move_horizontally_toward(
		last_known_player_position.x,
		chase_speed
	)


# -------------------------
# ATTACK
# -------------------------

func _enter_attack() -> void:
	velocity.x = 0.0
	_start_attack()


func _update_attack(_delta: float) -> void:
	velocity.x = 0.0

	if player == null:
		_change_state(EnemyState.RETURN)
		return

	if not player_in_attack_range:
		_change_state(EnemyState.CHASE)
		return

	if not _has_line_of_sight_to_player():
		_change_state(EnemyState.CHASE)
		return

	_update_facing(signf(player.global_position.x - global_position.x))

	if attack_cooldown_left <= 0.0:
		_start_attack()


func _start_attack() -> void:
	if attack_cooldown_left > 0.0:
		return

	attack_cooldown_left = attack_cooldown

	animated_sprite.play("attack")
	animation_player.play("attack")


func _enable_attack_hitbox() -> void:
	hitbox.begin_attack()


func _disable_attack_hitbox() -> void:
	hitbox.end_attack()


# -------------------------
# HURT
# -------------------------

func _on_hit_received(
	_attack: AttackData,
	direction: Vector2
) -> void:
	if current_state == EnemyState.DEAD:
		return

	hurt_time_left = hurt_duration

	velocity = direction * hurt_knockback

	_change_state(EnemyState.HURT)


func _enter_hurt() -> void:
	animation_player.stop()
	hitbox.end_attack()
	animated_sprite.play("hurt")


func _update_hurt(delta: float) -> void:
	hurt_time_left -= delta

	if hurt_time_left > 0.0:
		return

	if _can_start_chase():
		_change_state(EnemyState.CHASE)
	else:
		_change_state(EnemyState.RETURN)


# -------------------------
# RETURN
# -------------------------

func _enter_return() -> void:
	animated_sprite.play("walk")


func _update_return(_delta: float) -> void:
	if _can_start_chase():
		_change_state(EnemyState.CHASE)
		return

	_move_horizontally_toward(
		home_position.x,
		return_speed
	)

	if absf(
		global_position.x - home_position.x
	) <= return_tolerance:
		velocity.x = 0.0
		_change_state(EnemyState.IDLE)


# -------------------------
# DEAD
# -------------------------

func _on_died() -> void:
	_change_state(EnemyState.DEAD)


func _enter_dead() -> void:
	velocity = Vector2.ZERO
	animation_player.stop()
	hitbox.end_attack()

	detection_area.monitoring = false
	attack_range.monitoring = false

	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	hitbox.set_deferred("monitoring", false)

	animated_sprite.play("dead")
	_update_debug_label()


# -------------------------
# DEBUG
# -------------------------

func _update_debug_label() -> void:
	$StateDebugLabel.text = EnemyState.keys()[current_state]
