extends RefCounted

const SCHEMA := 5
const TEMP := ".tmp"
const BACKUP := ".backup"
const BACKUP_TEMP := ".backup.tmp"

var path := "user://roadside.cfg"
var sequence := 0
var read_only := false

func restore() -> Dictionary:
	read_only = false
	var best := {}
	for suffix in ["", TEMP, BACKUP, BACKUP_TEMP]:
		var candidate := read_candidate(path + suffix)
		if not candidate.is_empty() and (best.is_empty() or candidate.sequence > best.sequence):
			best = candidate
	if best.is_empty():
		return {}
	sequence = best.sequence
	read_only = int(best.schema) > SCHEMA
	if read_only:
		return {}
	best.data["_schema"] = best.schema
	return best.data

func read_candidate(filename: String) -> Dictionary:
	# Saves never need arbitrary resources or objects reconstructed from untrusted files.
	var source := FileAccess.open(filename, FileAccess.READ)
	if source == null or source.get_length() > 524_288:
		return {}
	var raw := source.get_as_text()
	if raw.begins_with("{"):
		var document := JSON.new()
		if document.parse(raw) != OK:
			return {}
		var envelope: Variant = document.data
		if not envelope is Dictionary:
			return {}
		var payload: Variant = envelope.get("payload")
		if not payload is String or payload.sha256_text() != envelope.get("sha256"):
			return {}
		if document.parse(payload) != OK:
			return {}
		var data: Variant = document.data
		var schema := int(envelope.get("schema", 0))
		var serial := int(envelope.get("sequence", 0))
		if not data is Dictionary or schema < 2 or serial <= 0:
			return {}
		if schema <= SCHEMA and not valid_wallet(data.get("wallet")):
			return {}
		return {"data": data, "sequence": serial, "schema": schema}
	# The original release stored five levels in a ConfigFile. Keep its path.
	if not raw.begins_with("[station]"):
		return {}
	var legacy := ConfigFile.new()
	if legacy.parse(raw) != OK or not legacy.has_section_key("station", "cash"):
		return {}
	return {"sequence": 0, "schema": 1, "data": {
		"legacy": true,
		"wallet": {"cash": str(maxi(0, int(legacy.get_value("station", "cash", 120))))},
		"levels": {"fuel": clampi(int(legacy.get_value("station", "level", 1)), 1, 5)},
		"customers": maxi(0, int(legacy.get_value("station", "customers", 0))),
		"language": legacy.get_value("settings", "language", "pl"),
		"low_power": legacy.get_value("settings", "low_power", false),
	}}

func valid_wallet(value: Variant) -> bool:
	if not value is Dictionary or not value.get("cash") is String:
		return false
	for currency in ["cash", "diamond", "reputation", "event"]:
		var amount: Variant = value.get(currency, "0")
		if not amount is String or not HbtAmount.valid_decimal(amount):
			return false
	return true

func store(snapshot: Dictionary) -> Error:
	if read_only:
		return ERR_UNAVAILABLE
	var payload := JSON.stringify(snapshot)
	var envelope := JSON.stringify({"schema": SCHEMA, "sequence": sequence + 1,
		"sha256": payload.sha256_text(), "payload": payload})
	# Preserve the best previous complete copy even when the primary file is corrupt.
	var main := read_candidate(path)
	var staged := read_candidate(path + TEMP)
	var backup := read_candidate(path + BACKUP)
	var backup_tmp := read_candidate(path + BACKUP_TEMP)
	var previous := main
	var previous_path := path
	if not staged.is_empty() and (previous.is_empty() or staged.sequence > previous.sequence):
		previous = staged
		previous_path = path + TEMP
	if not backup_tmp.is_empty() and (previous.is_empty() or backup_tmp.sequence > previous.sequence):
		previous = backup_tmp
		previous_path = path + BACKUP_TEMP
	var absolute := ProjectSettings.globalize_path(path)
	if not previous.is_empty() and (backup.is_empty() or previous.sequence > backup.sequence):
		if previous_path != path + BACKUP_TEMP:
			var copy := DirAccess.copy_absolute(ProjectSettings.globalize_path(previous_path), absolute + BACKUP_TEMP)
			if copy != OK:
				return copy
		var rotate := DirAccess.rename_absolute(absolute + BACKUP_TEMP, absolute + BACKUP)
		if rotate != OK:
			return rotate
	var file := FileAccess.open(path + TEMP, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(envelope)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or read_candidate(path + TEMP).is_empty():
		return ERR_CANT_CREATE
	var result := DirAccess.rename_absolute(absolute + TEMP, absolute)
	if result == OK:
		sequence += 1
	return result
