class_name DialoguePanelUI
extends Control

signal dialogue_finished(npc: Node2D)

@export var text_characters_per_second: float = 48.0

@onready var portrait: AnimatedSprite2D = $Portrait
@onready var speaker_label: Label = $SpeakerLabel
@onready var body_label: Label = $BodyLabel
@onready var advance_button: Button = $AdvanceButton

var dialogue_open: bool = false
var current_npc: Node2D
var current_player: CharacterBody2D
var dialogue_lines: Array[String] = []
var dialogue_index: int = 0
var reveal_progress: float = 0.0
var panel_tween: Tween

func _ready() -> void:
	advance_button.pressed.connect(advance_dialogue)
	hide()

func _process(delta: float) -> void:
	if dialogue_open and body_label.visible_characters < body_label.text.length():
		reveal_progress += delta * text_characters_per_second
		body_label.visible_characters = mini(int(reveal_progress), body_label.text.length())

func _input(event: InputEvent) -> void:
	if not dialogue_open:
		return
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		advance_dialogue()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		close_dialogue()
		get_viewport().set_input_as_handled()

func start_dialogue(npc: Node2D, player: CharacterBody2D, speaker: String, lines: Array[String], portrait_frames: SpriteFrames) -> void:
	if dialogue_open or lines.is_empty():
		return
	current_npc = npc
	current_player = player
	dialogue_lines = lines.duplicate()
	dialogue_index = 0
	dialogue_open = true
	speaker_label.text = speaker
	portrait.sprite_frames = portrait_frames
	portrait.play(&"hablar")
	current_npc.set_talking(true)
	current_player.set_dialogue_active(true)
	show_line()
	show()
	modulate.a = 0.0
	pivot_offset = Vector2(size.x * 0.5, size.y)
	scale = Vector2(0.98, 0.92)
	if panel_tween and panel_tween.is_running():
		panel_tween.kill()
	panel_tween = create_tween().set_parallel(true)
	panel_tween.tween_property(self, "modulate:a", 1.0, 0.22)
	panel_tween.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func show_line() -> void:
	body_label.text = dialogue_lines[dialogue_index]
	body_label.visible_characters = 0
	reveal_progress = 0.0
	advance_button.text = "Continuar" if dialogue_index < dialogue_lines.size() - 1 else "Terminar"

func advance_dialogue() -> void:
	if not dialogue_open:
		return
	if body_label.visible_characters < body_label.text.length():
		body_label.visible_characters = body_label.text.length()
		reveal_progress = float(body_label.text.length())
		return
	dialogue_index += 1
	if dialogue_index >= dialogue_lines.size():
		close_dialogue()
	else:
		show_line()

func close_dialogue() -> void:
	if not dialogue_open:
		return
	dialogue_open = false
	if panel_tween and panel_tween.is_running():
		panel_tween.kill()
	hide()
	if is_instance_valid(current_npc):
		current_npc.set_talking(false)
	if is_instance_valid(current_player):
		current_player.set_dialogue_active(false)
	dialogue_finished.emit(current_npc)
	current_npc = null
	current_player = null
