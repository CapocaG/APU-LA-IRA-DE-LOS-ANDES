extends CharacterBody2D

@export_category("Patrulla")
@export var patrol_offsets: Array[Vector2] = [Vector2(-180, 40), Vector2(180, 35)]
@export var walk_speed: float = 52.0
@export var pause_seconds: float = 1.2
@export var stop_for_player_distance: float = 85.0

@export var display_name: String = "Yachaq"
@export var dialogue_lines: Array[String] = [
	"Viajero, nuestras tierras están en peligro. Illapa y Amaru han despertado y el equilibrio ancestral se ha perdido.",
	"Debes encontrar el fragmento de Illapa y la escama de Amaru.",
	"LLeva los objetos al altar ancetral. Solo así podrás restaurar el equilibrio de estas tierras."
]

@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var prompt: Label = $NameLabel

var nearby_player: CharacterBody2D
var home_position: Vector2
var patrol_index: int = 0
var pause_remaining: float = 0.0
var talking: bool = false
var navigation_ready: bool = false

func _ready() -> void:
	home_position = global_position
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	animated_sprite.play(&"idle")
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
	if animated_sprite.animation != animation_name or not animated_sprite.is_playing():
		animated_sprite.play(animation_name)

func _unhandled_input(event: InputEvent) -> void:
	if nearby_player == null or not event.is_action_pressed("interact"):
		return
	if event is InputEventKey and event.echo:
		return
	var dialogue_ui: DialoguePanelUI = get_tree().get_first_node_in_group("dialogue_ui") as DialoguePanelUI
	if dialogue_ui == null or dialogue_ui.dialogue_open:
		return
	if not dialogue_ui.dialogue_finished.is_connected(_on_dialogue_finished):
		dialogue_ui.dialogue_finished.connect(_on_dialogue_finished)
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

func _on_dialogue_finished(npc: Node2D) -> void:
	if npc == self and is_instance_valid(nearby_player):
		prompt.show()
