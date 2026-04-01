extends Control

@onready var play_btn: Button = %PlayButton
@onready var settings_btn: Button = %SettingsButton
@onready var quit_btn: Button = %QuitButton


func _ready() -> void:
	play_btn.pressed.connect(_on_play)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	Analytics.track_screen("main_menu")


func _on_play() -> void:
	# Temporary gameplay-first flow: bypass save slot screen while we stabilize it.
	# Use a safe GameState lookup so Play still works even if autoload init had issues.
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		gs.current_slot = "slot_1"
	var err := get_tree().change_scene_to_file("res://src/ui/setup/new_game.tscn")
	if err != OK:
		push_error("MainMenu: failed to open New Game scene (err=%d)" % err)


func _on_settings() -> void:
	SceneLoader.goto_scene("res://src/ui/settings/settings_screen.tscn")


func _on_quit() -> void:
	get_tree().quit()
