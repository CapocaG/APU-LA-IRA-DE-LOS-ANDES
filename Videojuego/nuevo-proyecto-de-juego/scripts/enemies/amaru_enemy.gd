extends CharacterBody2D

@export var max_health: int = 90
@export var move_speed: float = 55.0
@export var preferred_distance: float = 150.0
@export var melee_distance: float = 55.0
@export var melee_damage: int = 12
@export var attack_cooldown: float = 2.0
@export var exp_reward: int = 350
@export var fire_scene: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var fire_point: Marker2D = $FirePoint
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer
@onready var health_bar: Range = $HealthBar

var hp: int
var target_player: Node2D = null
var is_attacking: bool = false
var is_hurt: bool = false
var dead: bool = false
var fire_point_offset_x: float

func _ready() -> void:
	hp = max_health
	if is_instance_valid(health_bar):
		health_bar.max_value = max_health
		health_bar.value = hp

	fire_point_offset_x = absf(fire_point.position.x)
	if fire_point_offset_x < 10.0:
		fire_point_offset_x = 45.0

	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	attack_timer.wait_time = attack_cooldown
	anim_player.play("move_down")

func _physics_process(_delta: float) -> void:
	if dead or is_hurt:
		return

	if not is_instance_valid(target_player):
		velocity = Vector2.ZERO
		if not is_attacking and anim_player.current_animation != "move_down":
			sprite.flip_h = false
			anim_player.play("move_down")
		return

	var to_player: Vector2 = target_player.global_position - global_position
	var distance: float = to_player.length()
	var dir: Vector2 = to_player.normalized()

	# Actualiza el lado del punto de disparo según la posición de Kuya
	if dir.x != 0.0:
		var facing_left: bool = dir.x < 0.0
		fire_point.position.x = -fire_point_offset_x if facing_left else fire_point_offset_x

	if not is_attacking:
		if distance > preferred_distance:
			velocity = dir * move_speed
			_update_movement_animation(dir)
		else:
			velocity = Vector2.ZERO
			if attack_timer.is_stopped():
				if distance <= melee_distance:
					_start_melee_attack(dir)
				else:
					_start_fire_attack(dir)
			else:
				_update_movement_animation(dir)

	move_and_slide()

func _update_movement_animation(dir: Vector2) -> void:
	sprite.flip_h = false
	var anim_name: String
	if absf(dir.x) > absf(dir.y):
		anim_name = "move_right" if dir.x > 0.0 else "move_left"
	else:
		anim_name = "move_down" if dir.y > 0.0 else "move_up"

	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)

func _start_fire_attack(dir: Vector2) -> void:
	is_attacking = true
	velocity = Vector2.ZERO
	sprite.flip_h = dir.x < 0.0
	anim_player.play("attack")

	# Espera hasta el frame en que abre la boca (aprox. mitad de la animación de 0.6s)
	await get_tree().create_timer(0.32).timeout
	if dead or is_hurt or not is_instance_valid(target_player):
		is_attacking = false
		return

	_spawn_fire()
	attack_timer.start()

	await anim_player.animation_finished
	is_attacking = false

func _start_melee_attack(dir: Vector2) -> void:
	is_attacking = true
	velocity = Vector2.ZERO
	sprite.flip_h = dir.x < 0.0
	anim_player.play("roar")

	await get_tree().create_timer(0.25).timeout
	if not dead and not is_hurt and is_instance_valid(target_player):
		if global_position.distance_to(target_player.global_position) <= melee_distance + 15.0:
			if target_player.has_method("take_damage") and (not target_player.has_method("is_dead") or not bool(target_player.call("is_dead"))):
				target_player.take_damage(melee_damage)

	attack_timer.start()
	await anim_player.animation_finished
	is_attacking = false

func _spawn_fire() -> void:
	if fire_scene == null or not is_instance_valid(target_player):
		return
	var fire := fire_scene.instantiate()
	fire.global_position = fire_point.global_position
	fire.direction = (target_player.global_position - fire_point.global_position).normalized()
	get_parent().add_child(fire)

func take_damage(amount: int) -> void:
	if dead:
		return
	hp = max(0, hp - amount)
	if is_instance_valid(health_bar):
		health_bar.value = hp

	if hp <= 0:
		dead = true
		velocity = Vector2.ZERO
		$CollisionShape2D.set_deferred("disabled", true)
		if has_node("HurtBox/CollisionShape2D"):
			$HurtBox/CollisionShape2D.set_deferred("disabled", true)
		if is_instance_valid(health_bar):
			health_bar.visible = false
		anim_player.play("death")
		await anim_player.animation_finished
		queue_free()
	else:
		is_hurt = true
		is_attacking = false
		velocity = Vector2.ZERO
		anim_player.play("hurt")
		await anim_player.animation_finished
		is_hurt = false

func is_dead() -> bool:
	return dead

func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target_player = body

func _on_detection_body_exited(body: Node2D) -> void:
	if body == target_player:
		target_player = null
