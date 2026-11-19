extends CharacterBody2D

@export_category("Patrulla")
@export var patrol_offsets: Array[Vector2] = [Vector2(-120, 20), Vector2(120, -20)]
@export var walk_speed: float = 48.0
@export var pause_seconds: float = 1.5
@export var stop_for_player_distance: float = 85.0

@export_category("Diálogo")
@export var display_name: String = "Curandera"
@export_multiline var dialogue_lines: Array[String] = [
	"Kuya, el viento de los Apus trae presagios oscuros desde las cumbres.",
	"Si las bestias te hieren, permite que las hierbas sagradas restauren tus fuerzas.",
	"Que la Pachamama guíe tu espada en esta travesía."
]

@export_category("Curación")
@export var heal_on_dialogue_end: bool = true
@export var heal_amount: int = 80
@export var restore_energy_amount: float = 40.0
@export var heal_only_once: bool = false

@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var prompt: Label = $NameLabel
@onready var heal_sfx: AudioStreamPlayer2D = get_node_or_null("HealSFX")

var nearby_player: CharacterBody2D
var current_talker: CharacterBody2D
var home_position: Vector2
var patrol_index: int = 0
var pause_remaining: float = 0.0
var talking: bool = false
var navigation_ready: bool = false
var has_healed_player: bool = false

func _ready() -> void:
	home_position = global_position
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	play_animation(&"idle")
	prompt.hide()
	await get_tree().physics_frame
	if is_inside_tree() and not patrol_offsets.is_empty():
		navigation_agent.target_position = home_position + patrol_offsets[patrol_index]
		navigation_ready = true

func _physics_process(delta: float) -> void:
	var player_is_close := is_instance_valid(nearby_player) and global_position.distance_to(nearby_player.global_position) < stop_for_player_distance
	if talking or player_is_close or not navigation_ready or patrol_offsets.is_empty():
		velocity = Vector2.ZERO
		move_and_slide()
		if not talking:
			play_animation(&"idle")
		return

	if pause_remaining > 0.0:
		pause_remaining -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		play_animation(&"idle")
		return

	var next_position: Vector2 = navigation_agent.get_next_path_position()
	if navigation_agent.is_navigation_finished():
		patrol_index = (patrol_index + 1) % patrol_offsets.size()
		navigation_agent.target_position = home_position + patrol_offsets[patrol_index]
		pause_remaining = pause_seconds
		velocity = Vector2.ZERO
		play_animation(&"idle")
		return

	var to_next: Vector2 = next_position - global_position
	velocity = to_next.normalized() * minf(walk_speed, to_next.length() / delta)
	move_and_slide()

	if absf(velocity.x) >= absf(velocity.y):
		play_animation(&"walk_right" if velocity.x >= 0.0 else &"walk_left")
	else:
		play_animation(&"walk_down" if velocity.y >= 0.0 else &"walk_up")

func play_animation(animation_name: StringName) -> void:
	if animated_sprite.sprite_frames == null:
		return
	var target_anim := animation_name
	if not animated_sprite.sprite_frames.has_animation(target_anim):
		target_anim = &"idle"
	if animated_sprite.sprite_frames.has_animation(target_anim):
		if animated_sprite.animation != target_anim or not animated_sprite.is_playing():
			animated_sprite.play(target_anim)

func _unhandled_input(event: InputEvent) -> void:
	if nearby_player == null or not event.is_action_pressed("interact"):
		return
	if event is InputEventKey and event.echo:
		return

	var dialogue_ui: DialoguePanelUI = get_tree().get_first_node_in_group("dialogue_ui") as DialoguePanelUI
	if dialogue_ui == null:
		dialogue_ui = get_tree().current_scene.get_node_or_null("CanvasLayer/DialoguePanel") as DialoguePanelUI

	if dialogue_ui == null:
		push_warning("CuranderaApu: No se encontró DialoguePanel en el nivel.")
		return
	if dialogue_ui.dialogue_open:
		return

	if not dialogue_ui.dialogue_finished.is_connected(_on_dialogue_finished):
		dialogue_ui.dialogue_finished.connect(_on_dialogue_finished)

	current_talker = nearby_player
	dialogue_ui.start_dialogue(self, nearby_player, display_name, dialogue_lines, animated_sprite.sprite_frames)
	prompt.hide()
	get_viewport().set_input_as_handled()

func set_talking(active: bool) -> void:
	talking = active
	velocity = Vector2.ZERO
	play_animation(&"hablar" if active else &"idle")

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("player") and body.has_method("set_dialogue_active"):
		nearby_player = body
		prompt.show()

func _on_body_exited(body: Node2D) -> void:
	if body == nearby_player:
		prompt.hide()
		nearby_player = null

func _on_dialogue_finished(npc: Node2D = null) -> void:
	if npc != null and npc != self:
		return

	var target: CharacterBody2D = current_talker if is_instance_valid(current_talker) else nearby_player
	current_talker = null

	if is_instance_valid(nearby_player):
		prompt.show()

	if not is_instance_valid(target):
		return

	if heal_on_dialogue_end and (not heal_only_once or not has_healed_player):
		has_healed_player = true
		target.heal(heal_amount)
		if restore_energy_amount > 0.0:
			target.restore_energy(restore_energy_amount)

		if is_instance_valid(heal_sfx) and heal_sfx.stream != null:
			heal_sfx.play()

		var heal_tween := create_tween()
		heal_tween.tween_property(target, "modulate", Color(0.55, 1.35, 0.75, 1.0), 0.2)
		heal_tween.tween_property(target, "modulate", Color.WHITE, 0.35)
