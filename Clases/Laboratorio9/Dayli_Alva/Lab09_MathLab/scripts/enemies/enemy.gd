extends CharacterBody2D

enum EnemyState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	HURT,
	FLEE,
	RETURN,
	DEAD
}

@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var detection_area: Area2D = $DetectionArea
@onready var attack_range: Area2D = $AttackRange

@onready var sight_ray: RayCast2D = $SightRay
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var hitbox: HitboxComponent = $HitboxComponent

@onready var attack_collision: CollisionShape2D = $HitboxComponent/CollisionShape2D

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

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

@export_category("Idle")

@export var idle_duration: float = 0.8
@export_category("Attack")

@export var attack_cooldown: float = 1.0
@export_category("Hurt")

@export var hurt_duration: float = 0.25
@export var hurt_knockback: float = 220.0

@export_category("Navigation")

@export var target_refresh_interval: float = 0.20

@export_category("Flee")
@export var flee_health_ratio: float = 0.25
@export var flee_distance: float = 220.0

@export_category("Wander")
@export var wander_radius: float = 40.0
@export var wander_distance: float = 80.0
@export var wander_jitter: float = 20.0

@export_category("Tactical Distance")
@export var preferred_attack_distance: float = 70.0
@export var flee_distance_tactical: float = 35.0

var wander_target := Vector2.ZERO

var current_state: EnemyState = EnemyState.IDLE
var current_patrol_target: Marker2D = null
var home_position: Vector2
var player: CharacterBody2D = null
var player_in_detection_area: bool = false
var player_in_attack_range: bool = false
var last_known_player_position: Vector2

var lost_sight_time_left: float = 0.0
var idle_time_left: float = 0.0
var attack_cooldown_left: float = 0.0
var hurt_time_left: float = 0.0

var navigation_target: Vector2
var has_navigation_target: bool = false

var navigation_refresh_left: float = 0.0

func _ready() -> void:
	home_position = global_position

	if patrol_point_b != null:
		current_patrol_target = patrol_point_b

	elif patrol_point_a != null:
		current_patrol_target = patrol_point_a

	navigation_agent.path_desired_distance = 8.0
	navigation_agent.target_desired_distance = 12.0
	navigation_agent.max_speed = chase_speed

	navigation_agent.avoidance_enabled = true
	navigation_agent.velocity_computed.connect(
		_on_navigation_velocity_computed
	)

	await get_tree().physics_frame

	detection_area.body_entered.connect(
		_on_detection_body_entered
	)
	detection_area.body_exited.connect(
		_on_detection_body_exited
	)
	attack_range.body_entered.connect(
		_on_attack_range_body_entered
	)
	attack_range.body_exited.connect(
		_on_attack_range_body_exited
	)

	hurtbox.hit_received.connect(
		_on_hit_received
	)
	health.died.connect(
		_on_died
	)
	navigation_agent.link_reached.connect(
		_on_navigation_link_reached
	)

	_enter_state(current_state)
	_update_debug_label()

func _on_navigation_link_reached(details: Dictionary) -> void:
	var link_owner = details.get("owner")

	if link_owner == null:
		return

	print("Link alcanzado: ", link_owner.name)
	
func _physics_process(delta: float) -> void:
	if current_state == EnemyState.DEAD:
		return

	attack_cooldown_left = maxf(
		attack_cooldown_left - delta,
		0.0
	)
	navigation_refresh_left = maxf(
		navigation_refresh_left - delta,
		0.0
	)

	_update_perception()

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
		EnemyState.FLEE:
			_update_flee(delta)
		EnemyState.RETURN:
			_update_return(delta)
		EnemyState.DEAD:
			pass

	move_and_slide()
	_update_facing()
	_update_debug_label()
	_update_debug_ui()
# =========================================================
# CAMBIO DE ESTADO
# =========================================================
func _change_state(new_state: EnemyState) -> void:
	if current_state == new_state:
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

func _exit_state(_state: EnemyState) -> void:
	pass

func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body as CharacterBody2D
		player_in_detection_area = true

func _on_detection_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_detection_area = false

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body as CharacterBody2D
		player_in_attack_range = true

func _on_attack_range_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_attack_range = false

func _update_perception() -> void:
	if player == null:
		return
	sight_ray.target_position = (
		sight_ray.to_local(player.global_position)
	)
	sight_ray.force_raycast_update()

func _can_see_player() -> bool:
	if player == null:
		return false
	sight_ray.target_position = (
		sight_ray.to_local(player.global_position)
	)
	sight_ray.force_raycast_update()
	if not sight_ray.is_colliding():
		return true
	return sight_ray.get_collider() == player

func _can_start_chase() -> bool:
	if player == null:
		return false
	if not player_in_detection_area:
		return false
	return _can_see_player()

func _enter_idle() -> void:
	velocity = Vector2.ZERO
	idle_time_left = idle_duration
	if animated_sprite != null:
		animated_sprite.play("idle")

func _update_idle(delta: float) -> void:
	velocity = Vector2.ZERO

	if _can_start_chase():
		_change_state(EnemyState.CHASE)
		return

	idle_time_left -= delta
	if idle_time_left <= 0.0:
		_change_state(EnemyState.PATROL)

func _enter_patrol() -> void:
	if animated_sprite != null:
		animated_sprite.play("walk")
func _update_patrol(_delta: float) -> void:
	if _can_start_chase():
		_change_state(EnemyState.CHASE)
		return
	if current_patrol_target == null:
		velocity = Vector2.ZERO
		_change_state(EnemyState.IDLE)
		return
	# Dirección hacia el punto
	var direction := global_position.direction_to(
		current_patrol_target.global_position
	)

	velocity = direction * patrol_speed

	if global_position.distance_to(
		current_patrol_target.global_position
	) <= patrol_tolerance:
		_switch_patrol_target()

func _switch_patrol_target() -> void:
	if current_patrol_target == patrol_point_a:
		current_patrol_target = patrol_point_b
	else:
		current_patrol_target = patrol_point_a

func _enter_chase() -> void:
	lost_sight_time_left = 0.0
	navigation_refresh_left = 0.0
	if animated_sprite != null:
		animated_sprite.play("run")

func _update_chase(delta: float) -> void:
	if health.current_health <= health.max_health * flee_health_ratio:
		_change_state(EnemyState.FLEE)
		return

	if player == null:
		_change_state(EnemyState.RETURN)
		return

	var distance_to_player := _get_distance_to_player()
	if distance_to_player < flee_distance_tactical:
		_change_state(EnemyState.FLEE)
		return
	if player_in_attack_range and _can_see_player():
		_change_state(EnemyState.ATTACK)
		return

	if distance_to_player <= preferred_attack_distance:
		velocity = Vector2.ZERO
		navigation_agent.velocity = Vector2.ZERO
		return
	if _can_see_player():
		last_known_player_position = player.global_position
		lost_sight_time_left = 0.0
	else:
		lost_sight_time_left += delta
	if lost_sight_time_left >= lost_sight_grace_time:
		_change_state(EnemyState.RETURN)
		return
	if navigation_refresh_left <= 0.0:
		_set_navigation_target(
			last_known_player_position
		)
		navigation_refresh_left = target_refresh_interval
	_follow_navigation_path(chase_speed)

func _enter_attack() -> void:
	velocity = Vector2.ZERO
	animation_player.stop()
	if animated_sprite != null:
		animated_sprite.play("attack")

func _update_attack(_delta: float) -> void:
	velocity = Vector2.ZERO
	# Salió del rango
	if not player_in_attack_range:
		_change_state(EnemyState.CHASE)
		return
	if not _can_see_player():
		_change_state(EnemyState.CHASE)
		return
	# Atacar
	if attack_cooldown_left <= 0.0:
		_enable_attack_hitbox()
		attack_cooldown_left = attack_cooldown

func _enable_attack_hitbox() -> void:
	hitbox.begin_attack()

func _disable_attack_hitbox() -> void:
	hitbox.end_attack()

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
	if animated_sprite != null:
		animated_sprite.play("hurt")

func _update_hurt(delta: float) -> void:
	hurt_time_left -= delta
	if hurt_time_left > 0.0:
		return

	if _can_start_chase():
		_change_state(EnemyState.CHASE)
	else:
		_change_state(EnemyState.RETURN)
		
func _enter_flee() -> void:
	animated_sprite.play("run")
	has_navigation_target = false
	navigation_agent.target_position = global_position

func _update_flee(_delta: float) -> void:
	if player == null:
		_change_state(EnemyState.RETURN)
		return
	var escape_direction := player.global_position.direction_to(global_position)
	if escape_direction == Vector2.ZERO:
		velocity = Vector2.ZERO
		navigation_agent.velocity = Vector2.ZERO
		return

	var escape_target := global_position + escape_direction * flee_distance

	_set_navigation_target(escape_target)
	_follow_navigation_path(chase_speed)

func _enter_return() -> void:
	velocity = Vector2.ZERO
	_set_navigation_target(home_position)
	if animated_sprite != null:
		animated_sprite.play("walk")

func _update_return(_delta: float) -> void:
	if _can_start_chase():
		_change_state(EnemyState.CHASE)
		return

	_follow_navigation_path(return_speed)

	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		_change_state(EnemyState.IDLE)

func _set_navigation_target(
	target_position: Vector2
) -> void:
	navigation_target = target_position
	has_navigation_target = true
	navigation_agent.target_position = target_position

func _get_navigation_direction() -> Vector2:
	if not has_navigation_target:
		return Vector2.ZERO

	if navigation_agent.is_navigation_finished():
		return Vector2.ZERO

	var next_path_position := (
		navigation_agent.get_next_path_position()
	)

	var direction := global_position.direction_to(
		next_path_position
	)
	return direction

func _follow_navigation_path(speed: float) -> void:
	var steering_velocity := _get_navigation_steering(speed)

	if steering_velocity == Vector2.ZERO:
		navigation_agent.velocity = Vector2.ZERO
		velocity = Vector2.ZERO
		return

	navigation_agent.velocity = steering_velocity
	
func _on_navigation_velocity_computed(
	safe_velocity: Vector2
) -> void:
	velocity = safe_velocity

func _update_facing() -> void:
	if animated_sprite == null:
		return

	if absf(velocity.x) > 0.1:
		animated_sprite.flip_h = velocity.x < 0

func _on_died() -> void:
	_change_state(EnemyState.DEAD)

func _enter_dead() -> void:
	velocity = Vector2.ZERO
	animation_player.stop()
	hitbox.end_attack()
	detection_area.monitoring = false
	attack_range.monitoring = false
	hurtbox.set_deferred(
		"monitoring",
		false
	)
	hurtbox.set_deferred(
		"monitorable",
		false
	)
	hitbox.set_deferred(
		"monitoring",
		false
	)

	if animated_sprite != null:
		animated_sprite.play("dead")
		
func _update_debug_label() -> void: 
	$StateDebugLabel.text = "%s\nHP: %.1f / %.1f" % [ 
		EnemyState.keys()[current_state], 
		health.current_health, health.max_health ]

func _update_debug_ui() -> void:
	var path := navigation_agent.get_current_navigation_path()

	var debug_ui := get_tree().get_first_node_in_group("debug_ui")

	if debug_ui == null:
		return

	var info: Label = debug_ui.get_node("Info")

	info.text = (
		"STATE: %s\n"
		+ "HP: %.1f / %.1f\n"
		+ "PATH POINTS: %d\n"
		+ "DISTANCE: %.1f\n"
		+ "FINISHED: %s"
	) % [
		EnemyState.keys()[current_state],
		health.current_health,
		health.max_health,
		path.size(),
		navigation_agent.distance_to_target(),
		str(navigation_agent.is_navigation_finished())
	]
	
func _steering_seek(target_position: Vector2, speed: float) -> Vector2:
	var direction := global_position.direction_to(target_position)
	return direction * speed
	
func _steering_flee(target_position: Vector2, speed: float) -> Vector2:
	var direction := target_position.direction_to(global_position)
	return direction * speed
	
func _get_distance_to_player() -> float:
	if player == null:
		return INF

	return global_position.distance_to(player.global_position)

func _steering_arrive(
	target_position: Vector2,
	max_speed: float,
	slow_radius: float,
	stop_distance: float = 8.0
) -> Vector2:
	var offset := target_position - global_position
	var distance := offset.length()

	if distance <= stop_distance:
		return Vector2.ZERO

	var direction := offset.normalized()
	var speed := max_speed

	if distance < slow_radius:
		speed = max_speed * (distance / slow_radius)

	return direction * speed
	
func _steering_wander(speed: float) -> Vector2:
	var jitter := Vector2(
		randf_range(-wander_jitter, wander_jitter),
		randf_range(-wander_jitter, wander_jitter)
	)

	wander_target += jitter

	if wander_target.length() > wander_radius:
		wander_target = wander_target.normalized() * wander_radius

	var target_position := (
		global_position
		+ wander_target
		+ Vector2.RIGHT * wander_distance
	)

	return _steering_seek(target_position, speed)

func _get_navigation_steering(speed: float) -> Vector2:
	if navigation_agent.is_navigation_finished():
		return Vector2.ZERO

	var next_path_position := navigation_agent.get_next_path_position()

	return _steering_seek(next_path_position, speed)
