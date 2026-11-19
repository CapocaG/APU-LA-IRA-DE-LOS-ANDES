extends Control

@onready var health_bar: ProgressBar = $HealthFrame/HealthBar
@onready var energy_bar: ProgressBar = $EnergyFrame/EnergyBar
@onready var health_value: Label = $HealthFrame/HealthValue
@onready var energy_value: Label = $EnergyFrame/EnergyValue
@onready var vignette: TextureRect = $VignetteOverlay

@onready var slot_1_count: Label = get_node_or_null("InventoryBar/Slot1/CountLabel")
@onready var slot_2_count: Label = get_node_or_null("InventoryBar/Slot2/CountLabel")
@onready var slot_3_count: Label = get_node_or_null("InventoryBar/Slot3/CountLabel")
@onready var slot_4_count: Label = get_node_or_null("InventoryBar/Slot4/CountLabel")

@onready var slot_1_icon: TextureRect = get_node_or_null("InventoryBar/Slot1/Icon")
@onready var slot_2_icon: TextureRect = get_node_or_null("InventoryBar/Slot2/Icon")
@onready var slot_3_icon: TextureRect = get_node_or_null("InventoryBar/Slot3/Icon")
@onready var slot_4_icon: TextureRect = get_node_or_null("InventoryBar/Slot4/Icon")

@export_range(0.05, 0.5) var low_health_threshold: float = 0.25
@export var pulse_speed: float = 4.0
@export_range(0.0, 1.0) var max_vignette_alpha: float = 0.85

var player: CharacterBody2D
var is_low_health: bool = false
var pulse_time: float = 0.0

func _ready() -> void:
	if is_instance_valid(vignette):
		vignette.modulate.a = 0.0
	bind_player(get_tree().get_first_node_in_group("player") as CharacterBody2D)

	PlayerData.inventory_changed.connect(_update_inventory)
	PlayerData.selected_slot_changed.connect(_update_selected_slot)
	_update_inventory(PlayerData.inventory)
	_update_selected_slot(PlayerData.selected_slot)

func _process(delta: float) -> void:
	if not is_instance_valid(vignette):
		return

	if is_low_health:
		pulse_time += delta * pulse_speed
		var wave: float = (sin(pulse_time) + 1.0) * 0.5
		vignette.modulate.a = lerpf(0.25, max_vignette_alpha, wave)
	elif vignette.modulate.a > 0.0:
		pulse_time = 0.0
		vignette.modulate.a = move_toward(vignette.modulate.a, 0.0, delta * 2.0)

func bind_player(current_player: CharacterBody2D) -> void:
	if is_instance_valid(player) and player.stats_changed.is_connected(_update_stats):
		player.stats_changed.disconnect(_update_stats)
	player = current_player
	if not is_instance_valid(player):
		return
	player.stats_changed.connect(_update_stats)
	_update_stats(player.hitpoints, player.hitpoints_max, player.energy, player.max_energy)

func _update_stats(health: int, max_health: int, energy: float, max_energy: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	energy_bar.max_value = max_energy
	energy_bar.value = energy
	health_value.text = "%d/%d" % [health, max_health]
	energy_value.text = "%d/%d" % [roundi(energy), roundi(max_energy)]

	var health_ratio: float = float(health) / float(maxi(max_health, 1))
	is_low_health = health > 0 and health_ratio <= low_health_threshold

func _update_inventory(inv: Dictionary) -> void:
	for i in range(PlayerData.ITEM_ORDER.size()):
		var item_name: String = PlayerData.ITEM_ORDER[i]
		var slot_node := get_node_or_null("InventoryBar/Slot%d" % (i + 1))
		if slot_node == null:
			continue
		var count_label := slot_node.get_node_or_null("CountLabel") as Label
		var icon := slot_node.get_node_or_null("Icon") as TextureRect
		var amount: int = inv.get(item_name, 0)
		if is_instance_valid(count_label):
			count_label.text = str(amount)
		if is_instance_valid(icon):
			icon.modulate.a = 1.0 if amount > 0 else 0.35

func _refresh_slot(count_label: Label, icon: TextureRect, amount: int) -> void:
	if is_instance_valid(count_label):
		count_label.text = str(amount)
	if is_instance_valid(icon):
		icon.modulate.a = 1.0 if amount > 0 else 0.35

func _update_selected_slot(selected_index: int) -> void:
	for i in range(PlayerData.ITEM_ORDER.size()):
		var slot_node := get_node_or_null("InventoryBar/Slot%d" % (i + 1)) as Control
		if is_instance_valid(slot_node):
			# Resalta en dorado brillante la ranura activa y deja normal las demás
			slot_node.modulate = Color(1.3, 1.18, 0.85, 1.0) if i == selected_index else Color.WHITE
