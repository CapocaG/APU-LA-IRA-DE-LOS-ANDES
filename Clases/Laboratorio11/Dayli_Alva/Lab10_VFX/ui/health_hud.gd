extends Control

@onready var health_bar: ProgressBar = $HealthBar

@export var player: Node

func _ready() -> void:
	assert(player != null, "HealthHUD requiere una referencia explícita a Player.")
	bind_player(player)

func bind_player(target: Node) -> void:
	var health_component := target.get_node_or_null("HealthComponent") as HealthComponent
	assert(health_component != null, "HealthHUD necesita un Player con HealthComponent.")
	health_component.health_changed.connect(_on_health_changed)

	_on_health_changed(
		health_component.current_health,
		health_component.max_health
	)

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
