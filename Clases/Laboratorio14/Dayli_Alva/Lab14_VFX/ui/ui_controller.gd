class_name UIController
extends CanvasLayer

const ITEM_DATABASE: ItemDatabase = preload("res://resources/items/item_database.tres")
const TOAST_SCENE: PackedScene = preload("res://ui/notifications/Toast.tscn")

@onready var hud: HUD = $HUD
@onready var hotbar: HBoxContainer = $Hotbar
@onready var inventory_panel: InventoryPanel = $InventoryPanel
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var notification_container: VBoxContainer = $NotificationLayer/VBoxContainer

var inventory: InventoryComponent

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	inventory_panel.close_requested.connect(close_inventory)
	pause_menu.resume_requested.connect(_on_resume_requested)
	pause_menu.main_menu_requested.connect(_return_to_main_menu)
	pause_menu.quit_requested.connect(_quit_game)
	if not EventBus.score_changed.is_connected(_on_score_changed):
		EventBus.score_changed.connect(_on_score_changed)
	hud.set_score(GameState.score)
	_refresh_hotbar()

func bind_player(player: Node) -> void:
	inventory = player.get_node_or_null("InventoryComponent") as InventoryComponent
	if inventory == null:
		return
	inventory_panel.bind_inventory(inventory, ITEM_DATABASE)
	if not inventory.inventory_changed.is_connected(_refresh_hotbar):
		inventory.inventory_changed.connect(_refresh_hotbar)
	if not inventory.item_added.is_connected(_on_item_added):
		inventory.item_added.connect(_on_item_added)

	for index in range(mini(5, hotbar.get_child_count())):
		var slot := hotbar.get_child(index) as InventorySlotUI
		if slot == null:
			continue
		slot.slot_index = index
		slot.inventory = inventory
		slot.item_database = ITEM_DATABASE
		if not slot.slot_selected.is_connected(_on_hotbar_slot_selected):
			slot.slot_selected.connect(_on_hotbar_slot_selected)
	_refresh_hotbar()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if pause_menu.visible:
			pause_menu.close_menu()
		elif inventory_panel.visible:
			close_inventory()
		else:
			open_pause_menu()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("inventory"):
		if inventory_panel.visible:
			close_inventory()
		else:
			open_inventory()
		get_viewport().set_input_as_handled()
		return

	if pause_menu.visible or inventory_panel.visible or inventory == null:
		return

	if event.is_action_pressed("use_item"):
		inventory.use_selected_item()
		_refresh_hotbar()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_select_hotbar_slot(inventory.selected_hotbar_slot - 1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_select_hotbar_slot(inventory.selected_hotbar_slot + 1)
			get_viewport().set_input_as_handled()
		return

	for index in range(5):
		if event.is_action_pressed("hotbar_slot_%d" % (index + 1)):
			_select_hotbar_slot(index)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("hotbar_previous"):
		_select_hotbar_slot(inventory.selected_hotbar_slot - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("hotbar_next"):
		_select_hotbar_slot(inventory.selected_hotbar_slot + 1)
		get_viewport().set_input_as_handled()

func open_inventory() -> void:
	pause_menu.visible = false
	get_tree().paused = true
	inventory_panel.open_inventory()

func close_inventory() -> void:
	inventory_panel.visible = false
	get_tree().paused = false

func open_pause_menu() -> void:
	inventory_panel.visible = false
	pause_menu.open_menu()

func close_all_panels() -> void:
	pause_menu.visible = false
	inventory_panel.visible = false
	get_tree().paused = false

func show_message(message: String) -> void:
	var toast := TOAST_SCENE.instantiate() as ToastNotification
	toast.message = message
	notification_container.add_child(toast)

func _select_hotbar_slot(index: int) -> void:
	if inventory == null:
		return
	inventory.select_hotbar_slot(index)
	_refresh_hotbar()

func _on_hotbar_slot_selected(index: int) -> void:
	_select_hotbar_slot(index)

func _refresh_hotbar() -> void:
	if not is_node_ready():
		return
	var coin_count := 0
	if inventory != null:
		for slot_data in inventory.slots:
			if StringName(slot_data.get("item_id", "")) == &"coin_bundle":
				coin_count += int(slot_data.get("quantity", 0))
	hud.set_coins(coin_count)
	for index in range(hotbar.get_child_count()):
		var slot := hotbar.get_child(index) as InventorySlotUI
		if slot == null:
			continue
		slot.text = str(index + 1)
		slot.theme_type_variation = &"PrimaryButton" if inventory != null and index == inventory.selected_hotbar_slot else &""
		if inventory == null or index >= inventory.slots.size() or inventory.slots[index].is_empty():
			slot.display(null, 0)
			continue
		var slot_data := inventory.slots[index]
		var item := ITEM_DATABASE.get_item(StringName(slot_data.get("item_id", "")))
		slot.display(item, int(slot_data.get("quantity", 0)))

func _on_item_added(item_id: StringName, quantity: int) -> void:
	var item := ITEM_DATABASE.get_item(item_id)
	if item != null:
		show_message("%s x%d" % [item.display_name, quantity])

func _on_score_changed(value: int) -> void:
	hud.set_score(value)
	show_message("Score: %d" % value)

func _on_resume_requested() -> void:
	close_all_panels()

func _return_to_main_menu() -> void:
	close_all_panels()
	SaveManager.save_game()
	SceneFlow.change_to("res://scenes/ui/main_menu.tscn")

func _quit_game() -> void:
	SaveManager.save_game()
	get_tree().quit()
