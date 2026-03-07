extends Control

@onready var new_game_btn: Button = %NewGameButton
@onready var continue_btn: Button = %ContinueButton
@onready var quit_btn: Button = %QuitButton


func _ready() -> void:
	continue_btn.disabled = not GameState.has_save("autosave")
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	quit_btn.pressed.connect(_on_quit)


func _on_new_game() -> void:
	SceneLoader.goto_scene("res://src/ui/setup/new_game.tscn")


func _on_continue() -> void:
	if GameState.load_game("autosave"):
		EventEngine.load_events("res://src/data/events.json")
		SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")


func _on_quit() -> void:
	get_tree().quit()
