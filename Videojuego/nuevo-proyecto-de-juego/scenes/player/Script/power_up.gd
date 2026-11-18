extends Area2D

enum PowerType {
	COCA,
	CHICHA_DE_JORA,
	ILLA,
	QUIPU,
	ESCAMA_DE_AMARU,
	FRAGMENTO_DE_ILLAPA,
	SEMILLA_DE_PACHAMAMA
}

@export var power_type: PowerType = PowerType.COCA
@export var randomize_common_on_spawn: bool = false
@export var icon_size_px: float = 32.0

@export_group("Sprites")
@export var tex_coca: Texture2D
@export var tex_chicha: Texture2D
@export var tex_illa: Texture2D
@export var tex_quipu: Texture2D
@export var tex_escama_amaru: Texture2D
@export var tex_fragmento_illapa: Texture2D
@export var tex_semilla_pachamama: Texture2D

@onready var sprite: Sprite2D = $Sprite2D

var base_y: float
var time_passed: float = 0.0

func _ready() -> void:
	base_y = position.y
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	if randomize_common_on_spawn:
		var common := [PowerType.COCA, PowerType.CHICHA_DE_JORA, PowerType.ILLA, PowerType.QUIPU]
		power_type = common.pick_random()

	match power_type:
		PowerType.COCA: sprite.texture = tex_coca
		PowerType.CHICHA_DE_JORA: sprite.texture = tex_chicha
		PowerType.ILLA: sprite.texture = tex_illa
		PowerType.QUIPU: sprite.texture = tex_quipu
		PowerType.ESCAMA_DE_AMARU: sprite.texture = tex_escama_amaru
		PowerType.FRAGMENTO_DE_ILLAPA: sprite.texture = tex_fragmento_illapa
		PowerType.SEMILLA_DE_PACHAMAMA: sprite.texture = tex_semilla_pachamama

	# Ajusta automáticamente cualquier imagen al tamaño indicado en icon_size_px
	if sprite.texture != null:
		var tex_size: Vector2 = sprite.texture.get_size()
		var max_side: float = maxf(tex_size.x, tex_size.y)
		if max_side > 0.0:
			var factor: float = icon_size_px / max_side
			sprite.scale = Vector2(factor, factor)

func _process(delta: float) -> void:
	time_passed += delta
	position.y = base_y + sin(time_passed * 4.0) * 3.5

func _on_body_entered(body: Node2D) -> void:
	_try_collect(body)

func _on_area_entered(area: Area2D) -> void:
	if area.owner != null:
		_try_collect(area.owner)

func _try_collect(target: Node) -> void:
	if (target.is_in_group("player") or target.name == "Player") and target.has_method("apply_powerup"):
		target.apply_powerup(PowerType.keys()[power_type])
		queue_free()
