class_name PauseMenu
extends Control

signal resume_requested
signal main_menu_requested
signal quit_requested

@onready var menu_page: VBoxContainer = $CenterContainer/PanelContainer/VBoxContainer/MenuPage
@onready var settings_page: VBoxContainer = $CenterContainer/PanelContainer/VBoxContainer/SettingsPage
@onready var resume_button: Button = $CenterContainer/PanelContainer/VBoxContainer/MenuPage/ResumeButton
@onready var settings_button: Button = $CenterContainer/PanelContainer/VBoxContainer/MenuPage/SettingsButton
@onready var settings_back_button: Button = $CenterContainer/PanelContainer/VBoxContainer/SettingsPage/SettingsBackButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	resume_button.pressed.connect(close_menu)
	settings_button.pressed.connect(_show_settings)
	settings_back_button.pressed.connect(_show_menu)
	$CenterContainer/PanelContainer/VBoxContainer/MenuPage/MainMenuButton.pressed.connect(func() -> void: main_menu_requested.emit())
	$CenterContainer/PanelContainer/VBoxContainer/MenuPage/QuitButton.pressed.connect(func() -> void: quit_requested.emit())

func open_menu() -> void:
	get_tree().paused = true
	visible = true
	_show_menu()
	resume_button.grab_focus()

func close_menu() -> void:
	visible = false
	get_tree().paused = false
	resume_requested.emit()

func _show_settings() -> void:
	menu_page.visible = false
	settings_page.visible = true
	settings_back_button.grab_focus()

func _show_menu() -> void:
	settings_page.visible = false
	menu_page.visible = true
	settings_button.grab_focus()
