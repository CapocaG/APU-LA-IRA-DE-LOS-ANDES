extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://multiplayer/player_net.tscn")

@onready var players: Node2D = $Players
@onready var spawn_points: Node2D = $SpawnPoints
@onready var status_label: Label = $HUD/StatusLabel
@onready var peer_id_label: Label = $HUD/PeerIdLabel
@onready var role_label: Label = $HUD/RoleLabel


func _ready() -> void:
	NetworkManager.peer_joined.connect(_spawn_player)
	NetworkManager.peer_left.connect(_despawn_player)
	NetworkManager.connection_status_changed.connect(_on_connection_status_changed)
	_refresh_peer_info()

	if multiplayer.is_server():
		_spawn_player(multiplayer.get_unique_id())
		for peer_id in multiplayer.get_peers():
			_spawn_player(peer_id)


func _spawn_player(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	if players.has_node(str(peer_id)):
		return

	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	player.name = str(peer_id)
	players.add_child(player, true)
	player.global_position = _get_spawn_position(peer_id)


func _despawn_player(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	var player := players.get_node_or_null(str(peer_id))
	if player != null:
		player.queue_free()


func _get_spawn_position(peer_id: int) -> Vector2:
	if spawn_points.get_child_count() == 0:
		return Vector2.ZERO

	var index: int = abs(peer_id) % spawn_points.get_child_count()
	var spawn_point := spawn_points.get_child(index) as Marker2D
	return spawn_point.global_position


func _on_connection_status_changed(text: String) -> void:
	status_label.text = text
	_refresh_peer_info()
	if text == "El servidor se desconectó.":
		call_deferred("_return_to_network_menu")


func _refresh_peer_info() -> void:
	status_label.text = NetworkManager.current_status
	peer_id_label.text = "Peer ID: %d" % NetworkManager.get_local_peer_id()
	role_label.text = "HOST" if NetworkManager.is_host() else "CLIENT"


func _return_to_network_menu() -> void:
	get_tree().change_scene_to_file("res://network/network_menu.tscn")


