extends Node2D

var remaining: int = 0

@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var remaining_label: Label = $CanvasLayer/RemainingLabel
@onready var victory_label: Label = $CanvasLayer/VictoryLabel


func _ready() -> void:
	GameState.start_new_run(&"main")
	EventBus.score_changed.connect(_on_score_changed)
	var collectibles = get_tree().get_nodes_in_group("collectible")
	remaining = collectibles.size()

	for collectible in collectibles:
		collectible.collected.connect(_on_collectible_collected)

	victory_label.visible = false

	_on_score_changed(GameState.score)
	_update_remaining()


func _on_collectible_collected(points: int) -> void:
	GameState.add_score(points)
	remaining -= 1

	_update_remaining()

	if remaining == 0:
		EventBus.level_completed.emit(&"main")
		victory_label.visible = true


func _on_score_changed(new_score: int) -> void:
	score_label.text = "Puntos: %d" % new_score


func _update_remaining() -> void:
	remaining_label.text = "Restantes: %d" % remaining
