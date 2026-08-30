extends Node2D

var score: int = 0
var remaining: int = 0

@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var remaining_label: Label = $CanvasLayer/RemainingLabel
@onready var victory_label: Label = $CanvasLayer/VictoryLabel


func _ready() -> void:
	var collectibles = get_tree().get_nodes_in_group("collectible")
	remaining = collectibles.size()

	for collectible in collectibles:
		collectible.collected.connect(_on_collectible_collected)

	victory_label.visible = false

	_update_score()
	_update_remaining()


func _on_collectible_collected(points: int) -> void:
	score += points
	remaining -= 1

	_update_score()
	_update_remaining()

	if remaining == 0:
		victory_label.visible = true


func _update_score() -> void:
	score_label.text = "Puntos: %d" % score


func _update_remaining() -> void:
	remaining_label.text = "Restantes: %d" % remaining
