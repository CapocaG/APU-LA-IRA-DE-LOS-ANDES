extends Control

@onready var address_input: LineEdit = $CenterContainer/PanelContainer/VBoxContainer/AddressInput
@onready var host_button: Button = $CenterContainer/PanelContainer/VBoxContainer/HostButton
@onready var join_button: Button = $CenterContainer/PanelContainer/VBoxContainer/JoinButton
@onready var disconnect_button: Button = $CenterContainer/PanelContainer/VBoxContainer/DisconnectButton
@onready var status_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatusLabel
@onready var peer_id_label: Label = $CenterContainer/PanelContainer/VBoxContainer/PeerIdLabel
@onready var role_label: Label = $CenterContainer/PanelContainer/VBoxContainer/RoleLabel


func _ready() -> void:
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	disconnect_button.pressed.connect(_on_disconnect_button_pressed)
	NetworkManager.connection_status_changed.connect(_on_connection_status_changed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	_refresh_peer_info()


func _on_host_button_pressed() -> void:
	var error: Error = NetworkManager.host_game()
	if error == OK:
		_open_lan_game()


func _on_join_button_pressed() -> void:
	NetworkManager.join_game(address_input.text)


func _on_disconnect_button_pressed() -> void:
	NetworkManager.disconnect_game()
	_refresh_peer_info()


func _on_connected_to_server() -> void:
	_open_lan_game()


func _open_lan_game() -> void:
	get_tree().change_scene_to_file("res://multiplayer/game_lan.tscn")


func _on_connection_status_changed(text: String) -> void:
	status_label.text = text
	_refresh_peer_info()


func _refresh_peer_info() -> void:
	status_label.text = NetworkManager.current_status
	peer_id_label.text = "Peer ID: %d" % NetworkManager.get_local_peer_id()
	role_label.text = "HOST" if NetworkManager.is_host() else "CLIENT"
