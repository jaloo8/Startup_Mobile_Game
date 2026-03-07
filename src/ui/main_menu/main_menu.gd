extends Control

@onready var play_btn: Button = %PlayButton
@onready var quit_btn: Button = %QuitButton


func _ready() -> void:
	play_btn.pressed.connect(_on_play)
	quit_btn.pressed.connect(_on_quit)


func _on_play() -> void:
	SceneLoader.goto_scene("res://src/ui/saves/save_slots.tscn")


func _on_quit() -> void:
	get_tree().quit()
