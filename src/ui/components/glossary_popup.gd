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

	visible = true
	scale = Vector2(0.88, 0.88)
	pivot_offset = size * 0.5
	modulate.a = 0.0

	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.22) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_tween.tween_property(self, "modulate:a", 1.0, 0.15) \
		.set_ease(Tween.EASE_OUT)


func dismiss() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	pivot_offset = size * 0.5
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", Vector2(0.92, 0.92), 0.12) \
		.set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "modulate:a", 0.0, 0.12) \
		.set_ease(Tween.EASE_IN)
	_tween.chain().tween_callback(func(): visible = false)
