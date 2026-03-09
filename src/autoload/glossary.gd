extends Node
## In-game glossary for startup terms.

signal term_requested(term_key: String)

var _entries: Dictionary = {}
var _loaded: bool = false

const GLOSSARY_PATH := "res://src/data/glossary.json"


func _ready() -> void:
	_load_glossary()


func _load_glossary() -> void:
	if not FileAccess.file_exists(GLOSSARY_PATH):
		push_warning("Glossary: file not found")
		return

	var file := FileAccess.open(GLOSSARY_PATH, FileAccess.READ)
	if file == null:
		return

	var text := file.get_as_text()
	file = null
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("Glossary: parse error")
		return

	if json.data is Dictionary:
		_entries = json.data
		_loaded = true


func has_term(key: String) -> bool:
	return _entries.has(key)


func get_term(key: String) -> String:
	if not _entries.has(key):
		return ""
	return _entries[key].get("term", key)


func get_short(key: String) -> String:
	if not _entries.has(key):
		return ""
	return _entries[key].get("short", "")


func get_tip(key: String) -> String:
	if not _entries.has(key):
		return ""
	return _entries[key].get("tip", "")


func get_full_text(key: String) -> String:
	if not _entries.has(key):
		return ""
	var entry: Dictionary = _entries[key]
	var term_name: String = entry.get("term", key)
	var short_desc: String = entry.get("short", "")
	var tip: String = entry.get("tip", "")
	return "%s — %s\n\n%s" % [term_name, short_desc, tip]


func all_keys() -> Array:
	return _entries.keys()


func show_term(key: String) -> void:
	if has_term(key):
		term_requested.emit(key)
