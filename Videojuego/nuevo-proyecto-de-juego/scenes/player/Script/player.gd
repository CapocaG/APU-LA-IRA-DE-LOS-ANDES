extends CharacterBody2D

signal game_over(victoria: bool)
signal update_hp_bar(hp_bar_value: int)
signal stats_changed(health: int, max_health: int, current_energy: float, max_energy: float)

enum State {
	IDLE,
	RUN,
	ATTACK,
	DEAD
}



@export_category("Stats")
@export var speed: int = 480
@export var attack_damage: int = 60
@export var hitpoints: int = 150
@export var max_energy: float = 100.0
@export var sprint_multiplier: float = 1.25
@export var sprint_energy_per_second: float = 18.0
@export var energy_regeneration_per_second: float = 6.0
@export var attack_energy_cost: float = 12.0

var state: State = State.IDLE
var move_direction: Vector2 = Vector2.ZERO
var attack_speed: float
var hitpoints_max: int
var dialogue_active: bool = false
var energy: float = 100.0

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]

# Efectos de sonido de Kuya
@onready var attack_sfx: AudioStreamPlayer2D = get_node_or_null("AttackSFX")
@onready var walking_sfx: AudioStreamPlayer2D = get_node_or_null("WalkingSFX")
@onready var hurt_sfx: AudioStreamPlayer2D = get_node_or_null("HurtSFX")
@onready var pickup_sfx: AudioStreamPlayer2D = get_node_or_null("PickupSFX")

var damage_multiplier_taken: float = 1.0

func _ready() -> void:
	load_stats_from_global()
	hitpoints_max = hitpoints
	energy = max_energy
	animation_tree.set_active(true)
	calculate_stats()
	_emit_stats()

func _play_sfx(sfx_node: AudioStreamPlayer2D, min_pitch: float = 0.92, max_pitch: float = 1.08) -> void:
	if is_instance_valid(sfx_node) and sfx_node.stream != null:
		sfx_node.pitch_scale = randf_range(min_pitch, max_pitch)
		sfx_node.play()

func _stop_walking_sfx() -> void:
	if is_instance_valid(walking_sfx) and walking_sfx.playing:
		walking_sfx.stop()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		attack()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Q:
				PlayerData.cycle_next_available_slot()
			KEY_R:
				use_inventory_item(PlayerData.get_selected_item_name())
			KEY_1, KEY_KP_1:
				use_inventory_item("COCA")
			KEY_2, KEY_KP_2:
				use_inventory_item("CHICHA_DE_JORA")
			KEY_3, KEY_KP_3:
				use_inventory_item("FRAGMENTO_DE_ILLAPA")
			KEY_4, KEY_KP_4:
				use_inventory_item("QUIPU")
			KEY_5, KEY_KP_5:
				use_inventory_item("ILLA")
			KEY_6, KEY_KP_6:
				use_inventory_item("SEMILLA_DE_PACHAMAMA")
			KEY_7, KEY_KP_7:
				use_inventory_item("ESCAMA_DE_AMARU")

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if state != State.ATTACK:
		movement_loop(delta)
	else:
		_set_energy(energy + energy_regeneration_per_second * delta)

func set_dialogue_active(active: bool) -> void:
	dialogue_active = active
	if active:
		_stop_movement()

func _stop_movement() -> void:
	move_direction = Vector2.ZERO
	velocity = Vector2.ZERO
	_stop_walking_sfx()
	if state != State.DEAD:
		state = State.IDLE
		update_animation()

func calculate_stats() -> void:
	attack_speed = Equations.calculate_attack_speed()
	var time_factor: float = Equations.BASE_ATTACK_SPEED / attack_speed
	animation_tree.set("parameters/attack/TimeScale/scale", time_factor)

func movement_loop(delta: float) -> void:
	move_direction.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	move_direction.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	var sprinting: bool = move_direction != Vector2.ZERO and Input.is_action_pressed("sprint") and energy > 0.0 and not dialogue_active
	var motion: Vector2 = move_direction.normalized() * speed * (sprint_multiplier if sprinting else 1.0)
	if sprinting:
		_set_energy(energy - sprint_energy_per_second * delta)
	else:
		_set_energy(energy + energy_regeneration_per_second * delta)
	set_velocity(motion)
	move_and_slide()

	if state == State.IDLE or state == State.RUN:
		if move_direction.x < -0.01:
			$Sprite2D.flip_h = true
		elif move_direction.x > 0.01:
			$Sprite2D.flip_h = false

	if motion != Vector2.ZERO and state == State.IDLE:
		state = State.RUN
		update_animation()
	elif motion == Vector2.ZERO and state == State.RUN:
		state = State.IDLE
		update_animation()

	# Control del sonido de pasos al moverse
	if is_instance_valid(walking_sfx) and walking_sfx.stream != null:
		if state == State.RUN and motion != Vector2.ZERO:
			if not walking_sfx.playing:
				walking_sfx.pitch_scale = randf_range(0.95, 1.05)
				walking_sfx.play()
		else:
			_stop_walking_sfx()

func update_animation() -> void:
	match state:
		State.IDLE:
			animation_playback.travel("idle")
		State.RUN:
			animation_playback.travel("run")
		State.ATTACK:
			animation_playback.travel("attack")

func attack() -> void:
	if state == State.ATTACK or state == State.DEAD or dialogue_active or energy < attack_energy_cost:
		return
	_stop_walking_sfx()
	_set_energy(energy - attack_energy_cost)
	state = State.ATTACK
	_play_sfx(attack_sfx, 0.90, 1.12)

	var mouse_pas: Vector2 = get_global_mouse_position()
	var attack_dir: Vector2 = (mouse_pas - global_position).normalized()
	$Sprite2D.flip_h = attack_dir.x < 0 and abs(attack_dir.x) >= abs(attack_dir.y)
	animation_tree.set("parameters/attack/BlendSpace2D/blend_position", attack_dir)
	update_animation()

	await get_tree().create_timer(attack_speed).timeout
	if state != State.DEAD:
		state = State.IDLE

func heal(amount: int) -> void:
	if state == State.DEAD or amount <= 0:
		return
	hitpoints = mini(hitpoints_max, hitpoints + amount)
	_emit_stats()

func restore_energy(amount: float) -> void:
	if state == State.DEAD or amount <= 0.0:
		return
	_set_energy(energy + amount)

func _set_energy(value: float) -> void:
	var next_energy := clampf(value, 0.0, max_energy)
	if not is_equal_approx(next_energy, energy):
		energy = next_energy
		_emit_stats()

func _emit_stats() -> void:
	stats_changed.emit(hitpoints, hitpoints_max, energy, max_energy)
	@warning_ignore("integer_division")
	update_hp_bar.emit((hitpoints * 100) / maxi(hitpoints_max, 1))

func take_damage(damage_taken: int) -> void:
	if state == State.DEAD or damage_taken <= 0:
		return
	var final_damage: int = maxi(1, int(round(damage_taken * damage_multiplier_taken)))
	hitpoints = maxi(0, hitpoints - final_damage)
	_emit_stats()
	if hitpoints <= 0:
		death()
	else:
		_play_sfx(hurt_sfx, 0.88, 1.02)

func is_dead() -> bool:
	return state == State.DEAD or hitpoints <= 0

func death() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	_stop_walking_sfx()
	velocity = Vector2.ZERO
	move_direction = Vector2.ZERO
	animation_tree.active = false
	$HitBox.set_deferred("monitoring", false)
	$HurtBox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	$Sprite2D.flip_h = false
	$AnimationPlayer.play(&"death")
	await $AnimationPlayer.animation_finished
	if is_inside_tree():
		game_over.emit(false)

func _on_hit_box_area_entered(area: Area2D) -> void:
	if not is_dead() and area.owner != null and area.owner.has_method("take_damage"):
		area.owner.take_damage(attack_damage)

func apply_powerup(item_name: String) -> void:
	_play_sfx(pickup_sfx, 0.96, 1.06)
	PlayerData.add_item(item_name, 1)

func load_stats_from_global() -> void:
	attack_damage += PlayerData.bonus_damage
	speed += PlayerData.bonus_speed
	hitpoints += PlayerData.bonus_max_hp
	max_energy += PlayerData.bonus_max_energy

func save_stats_to_global() -> void:
	PlayerData.bonus_damage = attack_damage - 60
	PlayerData.bonus_speed = speed - 480
	PlayerData.bonus_max_hp = hitpoints_max - 150
	PlayerData.bonus_max_energy = max_energy - 100.0

func use_inventory_item(item_name: String) -> void:
	if state == State.DEAD or dialogue_active:
		return
	if not PlayerData.consume_item(item_name):
		return

	_play_sfx(pickup_sfx, 1.05, 1.15)
	match item_name:
		"COCA":
			heal(35)
			restore_energy(30.0)
			var coca_tween := create_tween()
			coca_tween.tween_property(self, "modulate", Color(0.6, 1.35, 0.7), 0.18)
			coca_tween.tween_property(self, "modulate", Color.WHITE, 0.3)
		"CHICHA_DE_JORA":
			var bonus_speed: int = int(speed * 0.35)
			speed += bonus_speed
			modulate = Color(1.0, 0.9, 0.55)
			await get_tree().create_timer(8.0).timeout
			if is_inside_tree():
				speed = maxi(480 + PlayerData.bonus_speed, speed - bonus_speed)
				modulate = Color.WHITE
		"ILLA":
			damage_multiplier_taken = 0.5
			modulate = Color(0.55, 0.95, 1.0)
			await get_tree().create_timer(10.0).timeout
			if is_inside_tree():
				damage_multiplier_taken = 1.0
				modulate = Color.WHITE
		"QUIPU":
			restore_energy(max_energy)
			var bonus_regen: float = 10.0
			energy_regeneration_per_second += bonus_regen
			modulate = Color(0.85, 0.75, 1.0)
			await get_tree().create_timer(10.0).timeout
			if is_inside_tree():
				energy_regeneration_per_second = maxf(6.0, energy_regeneration_per_second - bonus_regen)
				modulate = Color.WHITE
