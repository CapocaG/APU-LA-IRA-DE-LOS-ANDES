extends Node

signal connection_status_changed(text: String)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)

const PORT: int = 7000
const MAX_CLIENTS: int = 8
const DEFAULT_ADDRESS: String = "127.0.0.1"
var current_status: String = "Sin conexión."


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host_game() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_CLIENTS)

	if error != OK:
		_set_status("No se pudo crear el servidor.")
		return error

	multiplayer.multiplayer_peer = peer
	_set_status("Servidor LAN activo.")
	return OK


func join_game(address: String) -> Error:
	var target := address.strip_edges()
	if target.is_empty():
		target = DEFAULT_ADDRESS

	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(target, PORT)

	if error != OK:
		_set_status("No se pudo iniciar la conexión.")
		return error

	multiplayer.multiplayer_peer = peer
	_set_status("Conectando a %s..." % target)
	return OK


func get_local_peer_id() -> int:
	return multiplayer.get_unique_id()


func is_host() -> bool:
	return multiplayer.is_server()


func disconnect_game() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_set_status("Sin conexión.")


func _on_peer_connected(peer_id: int) -> void:
	peer_joined.emit(peer_id)
	_set_status("Peer %d conectado." % peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	peer_left.emit(peer_id)
	_set_status("Peer %d desconectado." % peer_id)


func _on_connected_to_server() -> void:
	_set_status("Conectado al servidor.")


func _on_connection_failed() -> void:
	_set_status("Conexión fallida.")
	disconnect_game()
	_set_status("Conexión fallida.")


func _on_server_disconnected() -> void:
	_set_status("El servidor se desconectó.")
	disconnect_game()




func _set_status(text: String) -> void:
	current_status = text
	connection_status_changed.emit(text)


