class_name HUD
extends CanvasLayer

@onready var health_bar: ProgressBar = $HUD/SafeMargin/MainRow/HealthPanel/HealthBar
@onready var score_label: Label = $HUD/SafeMargin/MainRow/ScorePanel/ScoreLabel
@onready var coins_label: Label = $HUD/SafeMargin/MainRow/ScorePanel/CoinsLabel

func bind_health(health: HealthComponent) -> void:
	if not health.health_changed.is_connected(_on_health_changed):
		health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.current_health, health.max_health)

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current

func set_score(value: int) -> void:
	score_label.text = str(value)

func set_coins(value: int) -> void:
	coins_label.text = "Coins: %d" % value
