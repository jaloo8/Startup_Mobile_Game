class_name OfflineSummary
extends PanelContainer
## "While you were away" summary overlay shown when the player returns after
## being inactive long enough to accumulate meaningful passive income.
##
## Layout (top → bottom):
##   Moon icon + "While you were away…" header
##   Time away label  (e.g. "3 hours 22 minutes")
##   Passive income row  (+$12,400)
##   VC Chips row        (+2 VC Chips)  [only if chips > 0]
##   "Collect" button
##
## Driven entirely from code — no .tscn file needed.

signal collected(income: float, chips: int)

var _income: float = 0.0
var _chips:  int   = 0
var _tween:  Tween


static func create(income: float, chips: int, elapsed_seconds: float) -> OfflineSummary:
	var panel := OfflineSummary.new()
	panel._income = income
	panel._chips  = chips
	panel._elapsed_sec = elapsed_seconds
	return panel


var _elapsed_sec: float = 0.0


func _ready() -> void:
	_build_ui()
	UITouchHelper.harden_tree(self)
	_animate_in()


func _build_ui() -> void:
	# --- outer panel ---
	var style := ThemeManager._flat_box_static(
		ThemeManager.C_SURFACE, ThemeManager.C_BORDER_FOCUS, ThemeManager.CORNER_LG)
	style.set_border_width_all(2)
	add_theme_stylebox_override("panel", style)
	custom_minimum_size = Vector2(300, 0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   24)
	margin.add_theme_constant_override("margin_right",  24)
	margin.add_theme_constant_override("margin_top",    28)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	# --- header ---
	var header := Label.new()
	header.text = "🌙  While you were away…"
	header.add_theme_font_size_override("font_size", ThemeManager.FONT_LG)
	header.add_theme_color_override("font_color", ThemeManager.C_TEXT_HINT)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	# --- time away ---
	var time_lbl := Label.new()
	time_lbl.text = _format_duration(_elapsed_sec)
	time_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	time_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(time_lbl)

	# --- separator ---
	vbox.add_child(HSeparator.new())

	# --- income row ---
	vbox.add_child(_earn_row(
		"💰  Passive income",
		"+%s" % SceneLoader.format_money(_income),
		ThemeManager.C_GREEN))

	# --- chips row ---
	if _chips > 0:
		vbox.add_child(_earn_row(
			"🪙  VC Chips",
			"+%d" % _chips,
			ThemeManager.C_CHIP))

	# --- separator ---
	vbox.add_child(HSeparator.new())

	# --- collect button ---
	var btn := Button.new()
	btn.text = "Collect"
	btn.custom_minimum_size = Vector2(0, ThemeManager.TOUCH_MIN_H)
	# Override to accent-filled primary button style
	var btn_style := ThemeManager._flat_box_static(
		ThemeManager.C_BLUE, ThemeManager.C_TRANSPARENT,
		ThemeManager.CORNER_MD, 0)
	btn_style.content_margin_left   = 20.0
	btn_style.content_margin_right  = 20.0
	btn_style.content_margin_top    = 12.0
	btn_style.content_margin_bottom = 12.0
	btn.add_theme_stylebox_override("normal",  btn_style)
	btn.add_theme_stylebox_override("hover",   ThemeManager._flat_box_static(
		ThemeManager.C_BLUE.lightened(0.15), ThemeManager.C_TRANSPARENT,
		ThemeManager.CORNER_MD, 0))
	btn.add_theme_stylebox_override("pressed", ThemeManager._flat_box_static(
		ThemeManager.C_BLUE.darkened(0.15), ThemeManager.C_TRANSPARENT,
		ThemeManager.CORNER_MD, 0))
	btn.add_theme_color_override("font_color",       Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", ThemeManager.FONT_MD)
	btn.pressed.connect(_on_collect)
	vbox.add_child(btn)


func _earn_row(label_text: String, value_text: String, value_color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_MD)
	lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT)

	var val := Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", ThemeManager.FONT_LG)
	val.add_theme_color_override("font_color", value_color)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	row.add_child(lbl)
	row.add_child(val)
	return row


func _format_duration(seconds: float) -> String:
	var total := int(seconds)
	var h := total / 3600
	var m := (total % 3600) / 60
	if h > 0:
		return "%d hr %d min" % [h, m]
	return "%d min" % m


# ---------------------------------------------------------------------------
# Animation
# ---------------------------------------------------------------------------

func _animate_in() -> void:
	modulate.a = 0.0
	scale = Vector2(0.88, 0.88)
	pivot_offset = size * 0.5
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, 0.22).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.26) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Stagger child elements for dramatic reveal.
	var vbox: VBoxContainer = _find_vbox()
	if vbox:
		var delay := 0.3
		for child in vbox.get_children():
			if child is Control:
				child.modulate.a = 0.0
				var tw := child.create_tween()
				tw.tween_property(child, "modulate:a", 1.0, 0.18) \
					.set_delay(delay).set_ease(Tween.EASE_OUT)
				delay += 0.12
	# Sound for the return moment.
	SfxPlayer.play("cash_gain")
	AnimHelper.haptic(&"medium")


func _find_vbox() -> VBoxContainer:
	for child in get_children():
		if child is MarginContainer:
			for sub in child.get_children():
				if sub is VBoxContainer:
					return sub as VBoxContainer
	return null


func _animate_out(callback: Callable) -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "modulate:a", 0.0, 0.16).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "scale", Vector2(0.90, 0.90), 0.16)
	_tween.chain().tween_callback(callback)


# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------

var _collected: bool = false

func _on_collect() -> void:
	if _collected:
		return
	_collected = true

	# Deposit income and award chips
	IdleEngine.deposit_pending_income()
	IdleEngine.mark_offline_processed()
	if _chips > 0:
		CurrencyManager.on_offline_return(_chips)
	SfxPlayer.play("hire")  # celebratory chime

	_animate_out(func(): collected.emit(_income, _chips); queue_free())
