extends Control

@onready var play_btn: Button = %PlayButton
@onready var continue_btn: Button = %ContinueButton
@onready var settings_btn: Button = %SettingsButton
@onready var quit_btn: Button = %QuitButton

var _continue_slot: String = ""


func _ready() -> void:
	play_btn.pressed.connect(_on_play)
	continue_btn.pressed.connect(_on_continue)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	_refresh_continue_state()
	Analytics.track_screen("main_menu")


func _on_play() -> void:
	# Restore canonical flow: Play -> Save Slots.
	if get_node_or_null("/root/SceneLoader") != null:
		SceneLoader.goto_scene("res://src/ui/saves/save_slots.tscn")
		return
	var err := get_tree().change_scene_to_file("res://src/ui/saves/save_slots.tscn")
	if err != OK:
		push_error("MainMenu: failed to open Save Slots scene (err=%d)" % err)


func _on_continue() -> void:
	if _continue_slot.is_empty():
		_on_play()
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		_on_play()
		return
	gs.set("current_slot", _continue_slot)
	if not bool(gs.call("load_game", _continue_slot)):
		push_warning("MainMenu: failed to load continue slot '%s'" % _continue_slot)
		_refresh_continue_state()
		_on_play()
		return
	EventEngine.load_events("res://src/data/events.json")
	WorldEventEngine.load_events("res://src/data/world_events.json")
	ProductData.load_feature_catalog("res://src/data/features.json")
	CompanyData.load_niche_catalog()
	HeadlineEngine.load_headlines("res://src/data/headlines.json")
	SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")


func _refresh_continue_state() -> void:
	_continue_slot = ""
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		continue_btn.disabled = true
		continue_btn.text = "Continue Last Run"
		return

	if gs.has_method("latest_save_slot"):
		_continue_slot = str(gs.call("latest_save_slot"))

	continue_btn.disabled = _continue_slot.is_empty()
	if _continue_slot.is_empty():
		continue_btn.text = "Continue Last Run"
		return

	var label := "Continue Last Run"
	if gs.has_method("peek_save"):
		var info = gs.call("peek_save", _continue_slot)
		if info is Dictionary and bool(info.get("exists", false)):
			var company_name := str(info.get("company_name", "")).strip_edges()
			if not company_name.is_empty():
				label = "Continue: %s" % company_name
	continue_btn.text = label


func _on_settings() -> void:
	SceneLoader.goto_scene("res://src/ui/settings/settings_screen.tscn")


func _on_quit() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_method("autosave_now"):
			gs.call("autosave_now", "main_menu_quit")
		elif gs.has_method("save_game"):
			var slot_name: String = str(gs.get("current_slot"))
			if not slot_name.is_empty():
				gs.call("save_game", slot_name)
	get_tree().quit()
