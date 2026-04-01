extends Node
## TutorialManager — lightweight first-run walkthrough shown during a new game.
##
## Progress is stored in user://tutorial.dat as a single integer (current step).
## The overlay is a CanvasLayer built entirely in code — no .tscn required.
## Auto-advances on specific game events so the player is guided without being
## blocked: they can always act first and the tutorial reacts to what they do.

signal tutorial_step_changed(step: int)
signal tutorial_completed

const SAVE_PATH := "user://tutorial.dat"
const FREE_STEP_TO_SKIP := 99   # sentinel value written by skip()

# ── Step definitions ──────────────────────────────────────────────────────────
# auto_on: "" = manual only | "people" = fires when People screen opens
#          "quarter" = fires after the first quarter advance
const STEPS := [
	{
		"title": "Welcome to Venture!",
		"message": "You're the CEO. Build a product, grow your users, and reach profitability before your cash runs out.",
		"action": "Let's Build →",
		"auto_on": "",
	},
	{
		"title": "Watch Your Cash",
		"message": "These stats are your lifeline. When Cash hits zero — game over. Runway shows how many quarters you have left to survive.",
		"action": "Got it",
		"auto_on": "",
	},
	{
		"title": "Build a Team",
		"message": "Tap People to hire your first employee, then assign them to Features so your product starts getting built.",
		"action": "Open People →",
		"auto_on": "people",
	},
	{
		"title": "Advance the Quarter",
		"message": "Ready? Tap Advance Quarter. Your team works, revenue comes in, and surprises unfold — good and bad.",
		"action": "Got it",
		"auto_on": "quarter",
	},
	{
		"title": "You're in Business!",
		"message": "Read the quarterly report each time you advance. Use People, Product, Finances, and Market to manage every aspect of your company.",
		"action": "Start Building 🚀",
		"auto_on": "",
	},
]

var _step: int = -1
var _active: bool = false

# Direct node refs so we never use get_node_or_null path strings.
var _canvas: CanvasLayer
var _card: PanelContainer
var _title_lbl: Label
var _msg_lbl: Label
var _step_lbl: Label
var _action_btn: Button


# ─────────────────────────────────────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	SceneLoader.scene_changed.connect(_on_scene_changed)
	GameState.quarter_advanced.connect(_on_quarter_advanced)


# ─────────────────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────────────────

## Call from quarter_dashboard._ready().  Shows tutorial if not yet complete.
func start_if_needed() -> void:
	if not GameState.is_game_active:
		return
	_step = _load_step()
	if _step >= STEPS.size():
		return  # already finished or skipped

	_active = true
	if _canvas == null or not is_instance_valid(_canvas):
		_show_overlay()
	else:
		_canvas.visible = true
	tutorial_step_changed.emit(_step)


func is_active() -> bool:
	return _active


## Player pressed the action/next button.
func advance() -> void:
	if not _active:
		return
	_step += 1
	_save_step(_step)
	if _step >= STEPS.size():
		_finish()
	else:
		_refresh_card()
		tutorial_step_changed.emit(_step)


## Player pressed "Skip Tutorial".
func skip() -> void:
	_save_step(FREE_STEP_TO_SKIP)
	_finish()


## Reset tutorial progress (for testing or "replay tutorial" option in settings).
func reset() -> void:
	_save_step(0)
	_step = -1
	_active = false
	if _canvas and is_instance_valid(_canvas):
		_canvas.queue_free()
		_canvas = null


# ─────────────────────────────────────────────────────────────────────────────
# Signal handlers — auto-advance logic
# ─────────────────────────────────────────────────────────────────────────────

func _on_scene_changed(path: String) -> void:
	if not _active:
		return
	# Auto-advance when People screen opens (step expecting "people" trigger).
	if "people" in path:
		_try_auto_advance("people")
	# Show overlay only when the dashboard is the active scene.
	if _canvas and is_instance_valid(_canvas):
		_canvas.visible = "quarter_dashboard" in path


func _on_quarter_advanced(_quarter_number: int) -> void:
	_try_auto_advance("quarter")


func _try_auto_advance(trigger: String) -> void:
	if not _active or _step < 0 or _step >= STEPS.size():
		return
	if STEPS[_step].get("auto_on", "") == trigger:
		advance()


# ─────────────────────────────────────────────────────────────────────────────
# Internal — overlay lifecycle
# ─────────────────────────────────────────────────────────────────────────────

func _show_overlay() -> void:
	if _canvas and is_instance_valid(_canvas):
		_canvas.queue_free()
	_canvas = _build_canvas()
	get_tree().root.add_child(_canvas)
	_refresh_card()
	# Fade the whole canvas in.
	_canvas.modulate.a = 0.0
	var tw := _canvas.create_tween()
	tw.tween_property(_canvas, "modulate:a", 1.0, 0.45)


func _finish() -> void:
	_active = false
	if _canvas and is_instance_valid(_canvas):
		var tw := _canvas.create_tween()
		tw.tween_property(_canvas, "modulate:a", 0.0, 0.30)
		tw.finished.connect(func() -> void:
			if _canvas and is_instance_valid(_canvas):
				_canvas.queue_free()
			_canvas = null
		)
	tutorial_completed.emit()


func _refresh_card() -> void:
	if _card == null or not is_instance_valid(_card):
		return
	if _step < 0 or _step >= STEPS.size():
		return

	var data: Dictionary = STEPS[_step]
	if _title_lbl:
		_title_lbl.text = data.get("title", "")
	if _msg_lbl:
		_msg_lbl.text = data.get("message", "")
	if _action_btn:
		_action_btn.text = data.get("action", "Next →")
	if _step_lbl:
		_step_lbl.text = "%d / %d" % [_step + 1, STEPS.size()]

	# Subtle slide-up + fade per step change.
	_card.modulate.a = 0.0
	# Animate via the card's margin offset so anchor layout is respected.
	var start_top: float = _card.offset_top + 18.0
	var end_top: float = _card.offset_top
	_card.offset_top = start_top
	var tw := _card.create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(_card, "modulate:a", 1.0, 0.28)
	tw.parallel().tween_property(_card, "offset_top", end_top, 0.28)


# ─────────────────────────────────────────────────────────────────────────────
# Internal — UI construction
# ─────────────────────────────────────────────────────────────────────────────

func _build_canvas() -> CanvasLayer:
	var cl := CanvasLayer.new()
	cl.layer = 50

	# --- Dim backdrop (passes all input through so game remains interactive) ---
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.10, 0.60)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(bg)

	# --- Gradient band at bottom where the card sits ---
	var band := ColorRect.new()
	band.color = Color(0.06, 0.07, 0.13, 0.80)
	band.anchor_left = 0.0
	band.anchor_right = 1.0
	band.anchor_top = 0.68
	band.anchor_bottom = 1.0
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(band)

	# --- Card ---
	var card := PanelContainer.new()
	card.anchor_left = 0.0
	card.anchor_right = 1.0
	card.anchor_top = 1.0
	card.anchor_bottom = 1.0
	card.offset_left = 16.0
	card.offset_right = -16.0
	card.offset_top = -218.0   # card height from bottom
	card.offset_bottom = -16.0
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.10, 0.12, 0.22)
	card_style.set_corner_radius_all(14)
	card_style.set_content_margin_all(20.0)
	card_style.border_width_top = 1
	card_style.border_width_left = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(0.28, 0.32, 0.55, 0.55)
	card.add_theme_stylebox_override("panel", card_style)
	cl.add_child(card)
	_card = card

	# --- VBox inside card ---
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	# Step counter row
	var step_row := HBoxContainer.new()
	step_row.add_theme_constant_override("separation", 0)
	vbox.add_child(step_row)
	var h_spacer := Control.new()
	h_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	step_row.add_child(h_spacer)
	var step_lbl := Label.new()
	step_lbl.add_theme_font_size_override("font_size", 11)
	step_lbl.add_theme_color_override("font_color", Color(0.40, 0.44, 0.60))
	step_row.add_child(step_lbl)
	_step_lbl = step_lbl

	# Title
	var title_lbl := Label.new()
	title_lbl.add_theme_font_size_override("font_size", 17)
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.96, 1.0))
	vbox.add_child(title_lbl)
	_title_lbl = title_lbl

	# Message
	var msg_lbl := Label.new()
	msg_lbl.add_theme_font_size_override("font_size", 13)
	msg_lbl.add_theme_color_override("font_color", Color(0.70, 0.72, 0.82))
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(msg_lbl)
	_msg_lbl = msg_lbl

	# Divider
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.20, 0.24, 0.40, 0.6))
	vbox.add_child(sep)

	# Button row
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	# Skip button (transparent, dim text)
	var skip_btn := Button.new()
	skip_btn.text = "Skip Tutorial"
	skip_btn.add_theme_font_size_override("font_size", 12)
	skip_btn.add_theme_color_override("font_color", Color(0.38, 0.40, 0.55))
	var blank := StyleBoxFlat.new()
	blank.bg_color = Color(0, 0, 0, 0)
	blank.set_content_margin_all(6.0)
	skip_btn.add_theme_stylebox_override("normal", blank)
	skip_btn.add_theme_stylebox_override("hover", blank)
	skip_btn.add_theme_stylebox_override("pressed", blank)
	skip_btn.add_theme_stylebox_override("focus", blank)
	skip_btn.pressed.connect(skip)
	btn_row.add_child(skip_btn)

	var h_spacer2 := Control.new()
	h_spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(h_spacer2)

	# Action button (primary, blue)
	var action_btn := Button.new()
	action_btn.add_theme_font_size_override("font_size", 14)
	action_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	var act_n := StyleBoxFlat.new()
	act_n.bg_color = Color(0.20, 0.44, 0.88)
	act_n.set_corner_radius_all(9)
	act_n.set_content_margin_all(12.0)
	action_btn.add_theme_stylebox_override("normal", act_n)
	var act_h := act_n.duplicate() as StyleBoxFlat
	act_h.bg_color = act_n.bg_color.lightened(0.10)
	action_btn.add_theme_stylebox_override("hover", act_h)
	var act_p := act_n.duplicate() as StyleBoxFlat
	act_p.bg_color = act_n.bg_color.darkened(0.12)
	action_btn.add_theme_stylebox_override("pressed", act_p)
	action_btn.add_theme_stylebox_override("focus", act_n)
	action_btn.pressed.connect(advance)
	btn_row.add_child(action_btn)
	_action_btn = action_btn

	return cl


# ─────────────────────────────────────────────────────────────────────────────
# Persistence
# ─────────────────────────────────────────────────────────────────────────────

func _load_step() -> int:
	if not FileAccess.file_exists(SAVE_PATH):
		return 0
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return 0
	var line := f.get_line().strip_edges()
	f = null
	return line.to_int() if line.is_valid_int() else 0


func _save_step(step: int) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_line(str(step))
		f = null
