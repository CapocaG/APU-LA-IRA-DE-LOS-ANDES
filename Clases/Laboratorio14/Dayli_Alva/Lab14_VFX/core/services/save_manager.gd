extends Node

signal save_started
signal save_finished(success: bool)

const SAVE_PATH := "user://savegame.json"
const CURRENT_SAVE_VERSION := 2

var last_error: String = ""

func _build_save_data() -> Dictionary:
	var item_ids: Array[String] = []
	for item_id in GameState.collected_items:
		item_ids.append(String(item_id))
	return {
		"save_version": CURRENT_SAVE_VERSION,
		"level_id": String(GameState.current_level_id),
		"checkpoint_id": String(GameState.active_checkpoint_id),
		"score": GameState.score,
		"collected_items": item_ids,
		"inventory": GameState.inventory_data,
	}

func save_game() -> bool:
	save_started.emit()
	last_error = ""

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		last_error = "No se pudo abrir el archivo para guardar: %s" % error_string(FileAccess.get_open_error())
		push_warning(last_error)
		save_finished.emit(false)
		return false

	file.store_string(JSON.stringify(_build_save_data(), "\t"))
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		last_error = "No se pudo escribir la partida: %s" % error_string(write_error)
		push_warning(last_error)
		save_finished.emit(false)
		return false

	last_error = ""
	save_finished.emit(true)
	return true

func save_file_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func has_save() -> bool:
	last_error = ""
	var parsed: Variant = _read_file(SAVE_PATH)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	return not _validated_data(parsed).is_empty()

func load_game() -> bool:
	last_error = ""
	var parsed: Variant = _read_file(SAVE_PATH)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false

	var data := _validated_data(parsed)
	if data.is_empty():
		return false

	GameState.restore_session(
		StringName(data["level_id"]),
		StringName(data["checkpoint_id"]),
		int(data["score"]),
		_string_array_to_ids(data["collected_items"]),
		_dictionary_array(data["inventory"])
	)
	return true

func delete_save() -> bool:
	last_error = ""
	return _remove_user_file(SAVE_PATH)

func _read_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		last_error = "No existe una partida guardada."
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = "No se pudo abrir la partida guardada."
		return null
	var content := file.get_as_text()
	file.close()

	var parser := JSON.new()
	var parse_error := parser.parse(content)
	if parse_error != OK:
		last_error = "El JSON está dañado: %s" % parser.get_error_message()
		return null
	if typeof(parser.data) != TYPE_DICTIONARY:
		last_error = "El contenido de la partida no es un objeto JSON."
		return null
	return parser.data

func _validated_data(raw: Dictionary) -> Dictionary:
	var data := raw.duplicate(true)
	var version_value: Variant = data.get("save_version", 0)
	if typeof(version_value) != TYPE_INT:
		last_error = "La versión de guardado no es válida."
		return {}

	var version := int(version_value)
	while version < CURRENT_SAVE_VERSION:
		data = _migrate_save(data, version)
		if data.is_empty():
			return {}
		version = int(data.get("save_version", version))
	if version != CURRENT_SAVE_VERSION:
		last_error = "Versión de partida no soportada: %d" % version
		return {}

	var level_value: Variant = data.get("level_id", "")
	if typeof(level_value) != TYPE_STRING or String(level_value).is_empty():
		last_error = "La partida no contiene un nivel válido."
		return {}
	if not SceneFlow.has_level(StringName(level_value)):
		last_error = "El nivel guardado ya no existe."
		return {}

	var checkpoint_value: Variant = data.get("checkpoint_id", "")
	if typeof(checkpoint_value) != TYPE_STRING:
		checkpoint_value = ""
	var score_value: Variant = data.get("score", 0)
	if typeof(score_value) != TYPE_INT and typeof(score_value) != TYPE_FLOAT:
		score_value = 0
	var items_value: Variant = data.get("collected_items", [])
	if typeof(items_value) != TYPE_ARRAY:
		items_value = []
	var inventory_value: Variant = data.get("inventory", [])
	if typeof(inventory_value) != TYPE_ARRAY:
		inventory_value = []

	var safe_items: Array[String] = []
	for item in items_value:
		if typeof(item) == TYPE_STRING and not String(item).is_empty() and not safe_items.has(item):
			safe_items.append(item)

	var safe_inventory: Array[Dictionary] = []
	for slot in inventory_value:
		if typeof(slot) != TYPE_DICTIONARY:
			safe_inventory.append({})
			continue
		var slot_data: Dictionary = slot
		var item_id := String(slot_data.get("item_id", ""))
		var quantity_value: Variant = slot_data.get("quantity", 0)
		var quantity := int(quantity_value) if typeof(quantity_value) in [TYPE_INT, TYPE_FLOAT] else 0
		if item_id.is_empty() or quantity <= 0:
			safe_inventory.append({})
		else:
			safe_inventory.append({"item_id": item_id, "quantity": quantity})

	return {
		"save_version": CURRENT_SAVE_VERSION,
		"level_id": String(level_value),
		"checkpoint_id": String(checkpoint_value),
		"score": maxi(int(score_value), 0),
		"collected_items": safe_items,
		"inventory": safe_inventory,
	}

func _migrate_save(data: Dictionary, from_version: int) -> Dictionary:
	var migrated := data.duplicate(true)
	if from_version == 0:
		migrated["checkpoint_id"] = String(migrated.get("checkpoint_id", ""))
		if typeof(migrated.get("collected_items", [])) != TYPE_ARRAY:
			migrated["collected_items"] = []
		migrated["save_version"] = 1
		return migrated
	if from_version == 1:
		return _migrate_v1_to_v2(migrated)
	return {}

func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	if not migrated.has("inventory") or typeof(migrated.get("inventory")) != TYPE_ARRAY:
		migrated["inventory"] = []
	migrated["save_version"] = 2
	return migrated

func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for entry in value:
		if typeof(entry) == TYPE_DICTIONARY:
			result.append(entry.duplicate(true))
		else:
			result.append({})
	return result

func _string_array_to_ids(values: Array) -> Array[StringName]:
	var ids: Array[StringName] = []
	for value in values:
		ids.append(StringName(value))
	return ids

func _remove_user_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return true
	var absolute_path := ProjectSettings.globalize_path(path)
	var error := DirAccess.remove_absolute(absolute_path)
	if error != OK:
		last_error = "No se pudo borrar el archivo: %s" % error_string(error)
		push_warning(last_error)
		return false
	return true
