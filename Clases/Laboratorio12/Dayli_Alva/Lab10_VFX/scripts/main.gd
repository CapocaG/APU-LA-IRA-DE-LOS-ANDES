extends Node2D

var remaining: int = 0

@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var remaining_label: Label = $CanvasLayer/RemainingLabel
@onready var victory_label: Label = $CanvasLayer/VictoryLabel
@onready var next_level_button: Button = $CanvasLayer/NextLevelButton
@onready var level_controller: Node = $LevelController


func _ready() -> void:
	EventBus.score_changed.connect(_on_score_changed)
	var collectibles: Array[Node] = []
	for collectible in get_tree().get_nodes_in_group("collectible"):
		if collectible.is_queued_for_deletion():
			continue
		collectibles.append(collectible)
	remaining = collectibles.size()

	for collectible in collectibles:
		collectible.connect("collected", _on_collectible_collected)

	victory_label.visible = remaining == 0
	next_level_button.disabled = remaining > 0
	if remaining == 0:
		level_controller.call("unlock_exit")

	_on_score_changed(GameState.score)
	_update_remaining()

func _on_collectible_collected(_points: int) -> void:
	remaining -= 1

	_update_remaining()

	if remaining == 0:
		victory_label.visible = true
		level_controller.unlock_exit()

func _on_score_changed(new_score: int) -> void:
	score_label.text = "Puntos: %d" % new_score

func _update_remaining() -> void:
	remaining_label.text = "Restantes: %d" % remaining
