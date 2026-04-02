class_name GlossaryPopup
extends PanelContainer
## Reusable popup that displays a glossary term definition.
## Add as a child to any screen, then call show_term().

@onready var term_label: Label = $Margin/VBox/TermLabel
@onready var body_label: Label = $Margin/VBox/BodyLabel
@onready var close_btn: Button = $Margin/VBox/CloseButton

var _tween: Tween


func _ready() -> void:
	visible = false
	close_btn.pressed.connect(dismiss)
	Glossary.term_requested.connect(show_term)
	UITouchHelper.harden_tree(self)


func _exit_tree() -> void:
	if Glossary.term_requested.is_connected(show_term):
		Glossary.term_requested.disconnect(show_term)


func show_term(key: String) -> void:
	if not Glossary.has_term(key):
		return

	term_label.text = "%s — %s" % [Glossary.get_term(key), Glossary.get_short(key)]
	body_label.text = Glossary.get_tip(key)

	modulate.a = 0.0
	visible = true
	# Placeholder hook: future polish can swap this fade for a richer authored
	# slide/bounce animation while keeping this public API unchanged.

	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.15)


func dismiss() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.1)
	_tween.tween_callback(func(): visible = false)
