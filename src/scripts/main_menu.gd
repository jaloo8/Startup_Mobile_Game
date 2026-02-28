extends Control
## Main menu. Start run, settings, quit.
## Wire up buttons in the editor or via _ready().

func _ready() -> void:
	pass  # TODO: connect Start button to start_run()


func start_run() -> void:
	get_tree().change_scene_to_file("res://src/scenes/game_board.tscn")
