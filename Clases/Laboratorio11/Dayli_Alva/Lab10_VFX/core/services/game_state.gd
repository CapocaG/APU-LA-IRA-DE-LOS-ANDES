extends Node

var score: int = 0
var active_checkpoint: StringName = &""
var current_level: StringName = &""
var completed_levels: Array[StringName] = []
var player_is_dead: bool = false

func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)
	EventBus.checkpoint_activated.connect(_on_checkpoint_activated)
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.level_completed.connect(_on_level_completed)

func start_new_run(level_id: StringName) -> void:
	score = 0
	active_checkpoint = &""
	current_level = level_id
	completed_levels.clear()
	player_is_dead = false

func add_score(points: int) -> void:
	score += points
	EventBus.score_changed.emit(score)

func _on_player_died() -> void:
	player_is_dead = true

func _on_checkpoint_activated(checkpoint_id: StringName) -> void:
	active_checkpoint = checkpoint_id

func _on_score_changed(new_score: int) -> void:
	score = new_score

func _on_level_completed(level_id: StringName) -> void:
	if not completed_levels.has(level_id):
		completed_levels.append(level_id)
