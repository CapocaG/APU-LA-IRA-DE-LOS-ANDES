extends Node2D

var score: int = 0
@onready var score_label: Label = $CanvasLayer/ScoreLabel
func _ready() -> void:
	for collectible in get_tree().get_nodes_in_group("collectible"):
		collectible.collected.connect(_on_collectible_collected)
	_update_score()
	
func _on_collectible_collected(points: int) -> void:
	score += points
	_update_score()
func _update_score() -> void:
	score_label.text = "Puntos: %d" % score
