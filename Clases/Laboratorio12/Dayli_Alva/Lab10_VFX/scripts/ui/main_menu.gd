extends Control

@onready var new_game_button: Button = $CenterContainer/PanelContainer/VBoxContainer/NewGameButton
@onready var continue_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ContinueButton
@onready var delete_save_button: Button = $CenterContainer/PanelContainer/VBoxContainer/DeleteSaveButton
@onready var status_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatusLabel


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	delete_save_button.pressed.connect(_on_delete_save_pressed)
	var has_valid_save := SaveManager.has_save()
	continue_button.disabled = not has_valid_save
	delete_save_button.disabled = not SaveManager.save_file_exists()
	if not has_valid_save and SaveManager.save_file_exists():
		status_label.text = SaveManager.last_error
	elif not has_valid_save:
		status_label.text = "No hay una partida guardada."


func _on_new_game_pressed() -> void:
	GameState.start_new_game(&"level_01")
	if not SaveManager.save_game():
		status_label.text = SaveManager.last_error
	SceneFlow.go_to_level(&"level_01")


func _on_continue_pressed() -> void:
	if not SaveManager.load_game():
		status_label.text = SaveManager.last_error
		continue_button.disabled = true
		return
	SceneFlow.go_to_level(GameState.current_level_id)


func _on_delete_save_pressed() -> void:
	if SaveManager.delete_save():
		continue_button.disabled = true
		delete_save_button.disabled = true
		status_label.text = "Partida guardada eliminada."
	else:
		status_label.text = SaveManager.last_error
