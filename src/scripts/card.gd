extends Control
## Single card UI. Displays card data and emits when played/selected.
## Attach to card.tscn.

signal card_played(slot: String)
signal card_selected(card_control: Control)

var card_id: String = ""
var card_type: String = "player"  # "player" | "joker" (coach/stadium/scheme)
var stats: Dictionary = {}       # e.g. { "offense": 10, "defense": 8 }


func set_card_data(id: String, type: String, card_stats: Dictionary) -> void:
	card_id = id
	card_type = type
	stats = card_stats
	# TODO: update labels/sprites from stats


func _on_play_pressed(slot: String) -> void:
	card_played.emit(slot)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			card_selected.emit(self)
