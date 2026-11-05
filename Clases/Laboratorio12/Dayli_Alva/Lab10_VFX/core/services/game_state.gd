extends Node

var current_level_id: StringName = &""
var active_checkpoint_id: StringName = &""
var score: int = 0
var collected_items: Array[StringName] = []
var completed_levels: Array[StringName] = []
var player_is_dead: bool = false

func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)
	EventBus.checkpoint_activated.connect(_on_checkpoint_activated)
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.level_completed.connect(_on_level_completed)

func start_new_game(level_id: StringName = &"level_01") -> void:
	current_level_id = level_id
	active_checkpoint_id = &""
	score = 0
	collected_items.clear()
	completed_levels.clear()
	player_is_dead = false

func start_new_run(level_id: StringName) -> void:
	start_new_game(level_id)

func restore_session(
	level_id: StringName,
	checkpoint_id: StringName,
	new_score: int,
	item_ids: Array[StringName]
) -> void:
	current_level_id = level_id
	active_checkpoint_id = checkpoint_id
	score = maxi(new_score, 0)
	collected_items = item_ids.duplicate()
	completed_levels.clear()
	player_is_dead = false

func set_checkpoint(checkpoint_id: StringName) -> void:
	active_checkpoint_id = checkpoint_id

func add_score(points: int) -> void:
	score = maxi(score + points, 0)
	EventBus.score_changed.emit(score)

func add_collected_item(item_id: StringName) -> void:
	if item_id == &"" or collected_items.has(item_id):
		return
	collected_items.append(item_id)

func has_collected_item(item_id: StringName) -> bool:
	return collected_items.has(item_id)

func _on_player_died() -> void:
	player_is_dead = true

func _on_checkpoint_activated(checkpoint_id: StringName) -> void:
	active_checkpoint_id = checkpoint_id

func _on_score_changed(new_score: int) -> void:
	score = maxi(new_score, 0)

func _on_level_completed(level_id: StringName) -> void:
	if not completed_levels.has(level_id):
		completed_levels.append(level_id)
