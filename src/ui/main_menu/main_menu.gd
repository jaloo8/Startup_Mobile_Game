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
	SceneLoader.goto_scene("res://src/ui/saves/save_slots.tscn")


func _on_settings() -> void:
	SceneLoader.goto_scene("res://src/ui/settings/settings_screen.tscn")


func _on_quit() -> void:
	get_tree().quit()
