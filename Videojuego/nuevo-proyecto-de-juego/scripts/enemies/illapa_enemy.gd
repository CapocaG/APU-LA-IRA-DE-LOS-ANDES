extends CharacterBody2D

signal died(exp_reward: int)
enum State { IDLE, CHASE, RETURN, MELEE, STORM, BOLT, HURT, DEAD }
const BOLT_SCENE: PackedScene = preload("res://scenes/enemies/illapa_bolt.tscn")

@export_category("Illapa")
@export var max_health: int = 600
@export var move_speed: float = 115.0
@export var melee_damage: int = 28
@export var storm_damage: int = 24
@export var bolt_damage: int = 20
@export var aggro_range: float = 360.0
@export var melee_range: float = 95.0
@export var storm_range: float = 160.0
@export var leash_distance: float = 460.0
@export var attack_cooldown: float = 1.6
@export var exp_reward: int = 1800

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var detection_area: Area2D = $DetectionArea
@onready var hit_box: Area2D = $HitBox
@onready var health_bar: ProgressBar = $HealthBar
@onready var body_shape: CollisionShape2D = $CollisionShape2D

var state: State = State.IDLE
var home_position: Vector2
var player: CharacterBody2D
var current_health: int
var attack_ready_in: float = 0.0
var attack_number: int = 0
var hit_registered: bool = false
var current_animation: StringName = &""

func _ready() -> void:
	home_position = global_position
	current_health = max_health
	health_bar.max_value = max_health
	health_bar.value = max_health
	health_bar.hide()
	hit_box.set_deferred("monitoring", false)
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	hit_box.area_entered.connect(_on_hit_box_area_entered)
	animation_tree.active = true
	_play(&"idle_front")

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if not _living_target():
		player = null
		if state == State.MELEE or state == State.STORM or state == State.BOLT:
			hit_box.set_deferred("monitoring", false)
			state = State.RETURN
			_play(&"idle_front")
	attack_ready_in = maxf(0.0, attack_ready_in - delta)
	if state in [State.MELEE, State.STORM, State.BOLT, State.HURT]:
		velocity = Vector2.ZERO
		return
	if _living_target():
		var distance := global_position.distance_to(player.global_position)
		if player.global_position.distance_to(home_position) <= leash_distance and distance <= aggro_range:
			if attack_ready_in <= 0.0:
				if distance <= melee_range:
					_start_melee()
					return
				if attack_number % 3 == 2 and distance <= storm_range:
					_start_storm()
					return
				if distance <= 270.0:
					_start_bolt()
					return
			state = State.CHASE
			_move_toward(player.global_position)
			return
	if global_position.distance_to(home_position) > 12.0:
		state = State.RETURN
		_move_toward(home_position)
	else:
		state = State.IDLE
		velocity = Vector2.ZERO
		sprite.flip_h = false
		_play(&"idle_front")

func _living_target() -> bool:
	return is_instance_valid(player) and (not player.has_method("is_dead") or not bool(player.call("is_dead")))

func _move_toward(target: Vector2) -> void:
	nav_agent.target_position = target
	var next_position := target
	if NavigationServer2D.map_get_iteration_id(nav_agent.get_navigation_map()) > 0:
		if nav_agent.get_current_navigation_path().size() > 1:
			next_position = nav_agent.get_next_path_position()
	velocity = global_position.direction_to(next_position) * move_speed
	move_and_slide()
	if absf(velocity.x) > absf(velocity.y) * 0.5:
		sprite.flip_h = velocity.x < 0.0
		_play(&"walk_right")
	else:
		sprite.flip_h = false
		_play(&"walk_back" if velocity.y < 0.0 else &"walk_front")

func _start_melee() -> void:
	if not _living_target():
		return
	state = State.MELEE
	attack_ready_in = attack_cooldown
	attack_number += 1
	hit_registered = false
	velocity = Vector2.ZERO
	var direction := global_position.direction_to(player.global_position)
	sprite.flip_h = direction.x < 0.0
	_play(&"melee")
	await get_tree().process_frame
	if not is_inside_tree() or state != State.MELEE:
		return
	hit_box.position = direction * 58.0 + Vector2(0, -43)
	hit_box.rotation = direction.angle()
	await get_tree().create_timer(0.22).timeout
	if not is_inside_tree() or state != State.MELEE or not _living_target():
		return
	if global_position.distance_to(player.global_position) <= melee_range:
		_apply_melee_damage(player)
	await get_tree().create_timer(0.18).timeout
	if not is_inside_tree() or state != State.MELEE:
		return
	await _wait_animation(&"melee")
	if is_inside_tree() and state == State.MELEE:
		state = State.IDLE

func _start_storm() -> void:
	if not _living_target():
		return
	state = State.STORM
	attack_ready_in = attack_cooldown + 1.0
	attack_number += 1
	velocity = Vector2.ZERO
	sprite.flip_h = false
	_play(&"storm")
	await get_tree().create_timer(0.6).timeout
	if not is_inside_tree() or state != State.STORM or not _living_target():
		return
	if global_position.distance_to(player.global_position) <= storm_range:
		player.take_damage(storm_damage)
	await _wait_animation(&"storm")
	if is_inside_tree() and state == State.STORM:
		state = State.IDLE

func _start_bolt() -> void:
	if not _living_target():
		return
	state = State.BOLT
	attack_ready_in = attack_cooldown + 0.5
	attack_number += 1
	velocity = Vector2.ZERO
	var direction := global_position.direction_to(player.global_position)
	sprite.flip_h = direction.x < 0.0
	_play(&"bolt")
	await get_tree().create_timer(0.58).timeout
	if not is_inside_tree() or state != State.BOLT or not _living_target():
		return
	var bolt := BOLT_SCENE.instantiate()
	bolt.direction = direction
	bolt.damage = bolt_damage
	get_parent().add_child(bolt)
	bolt.global_position = global_position + direction * 50.0 + Vector2(0, -45)
	await _wait_animation(&"bolt")
	if is_inside_tree() and state == State.BOLT:
		state = State.IDLE

func _apply_melee_damage(target: Node) -> void:
	if hit_registered or not is_instance_valid(target) or not target.has_method("take_damage"):
		return
	if target.has_method("is_dead") and bool(target.call("is_dead")):
		return
	hit_registered = true
	target.take_damage(melee_damage)

func take_damage(amount: int) -> void:
	if state == State.DEAD or amount <= 0:
		return
	current_health = maxi(0, current_health - amount)
	health_bar.value = current_health
	health_bar.show()
	if current_health <= 0:
		_die()
	elif state != State.HURT:
		_stagger()

func is_dead() -> bool:
	return state == State.DEAD

func _stagger() -> void:
	state = State.HURT
	velocity = Vector2.ZERO
	hit_box.set_deferred("monitoring", false)
	sprite.flip_h = false
	_play(&"hurt")
	await _wait_animation(&"hurt")
	if is_inside_tree() and state == State.HURT:
		state = State.IDLE

func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	hit_box.set_deferred("monitoring", false)
	detection_area.set_deferred("monitoring", false)
	body_shape.set_deferred("disabled", true)
	sprite.flip_h = false
	_play(&"death")
	await _wait_animation(&"death")
	if is_inside_tree():
		died.emit(exp_reward)
		queue_free()

func _play(animation_name: StringName) -> void:
	if current_animation == animation_name:
		return
	current_animation = animation_name
	var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
	playback.travel(animation_name)

func _wait_animation(animation_name: StringName) -> void:
	await get_tree().create_timer(animation_player.get_animation(animation_name).length).timeout

func _on_detection_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("player") and (not body.has_method("is_dead") or not bool(body.call("is_dead"))):
		player = body

func _on_detection_body_exited(body: Node2D) -> void:
	if body == player:
		player = null

func _on_hit_box_area_entered(area: Area2D) -> void:
	if state == State.MELEE and _living_target() and area.owner == player:
		_apply_melee_damage(player)
