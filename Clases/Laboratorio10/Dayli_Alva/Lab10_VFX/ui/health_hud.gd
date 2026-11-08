extends Control

@onready var health_component: HealthComponent = $"../../Player/HealthComponent"
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	if health_component == null:
		return

	health_component.health_changed.connect(_on_health_changed)

	_on_health_changed(
		health_component.current_health,
		health_component.max_health
	)

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
