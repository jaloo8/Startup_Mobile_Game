extends Control
## Run History / Hall of Fame — displays all completed runs as a leaderboard.

@onready var back_btn: Button = %BackButton

const TYPE_ICONS: Dictionary = {
	"SaaS B2B": "B",
	"Consumer App": "C",
	"Marketplace": "M",
	"Dev Tools": "D",
}

## Track which card is currently expanded so we can collapse it on next tap.
var _expanded_card_index: int = -1
var _card_containers: Array[Control] = []

var _scroll: ScrollContainer
var _list_vbox: VBoxContainer
var _stats_vbox: VBoxContainer
var _empty_label: Label


func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	UITouchHelper.harden_tree(self)
	Analytics.track_screen("run_history")
	_build_ui()


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# Main vertical layout below the back button.
	var root_vbox := VBoxContainer.new()
	root_vbox.layout_mode = 1
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.offset_top = 64.0
	root_vbox.offset_left = 16.0
	root_vbox.offset_right = -16.0
	root_vbox.offset_bottom = -16.0
	root_vbox.add_theme_constant_override("separation", 16)
	add_child(root_vbox)

	# Title.
	var title := Label.new()
	title.text = "HALL OF FAME"
	title.add_theme_font_size_override("font_size", ThemeManager.FONT_XL)
	title.add_theme_color_override("font_color", ThemeManager.C_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(title)

	var runs: Array[Dictionary] = RunHistory.get_all()

	if runs.is_empty():
		_build_empty_state(root_vbox)
		_animate_entrance_empty(title)
		return

	# Aggregate stats bar.
	_stats_vbox = VBoxContainer.new()
	_stats_vbox.add_theme_constant_override("separation", 8)
	root_vbox.add_child(_stats_vbox)
	_build_stats_bar()

	# Separator.
	var sep := HSeparator.new()
	root_vbox.add_child(sep)

	# Scrollable run list.
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(_scroll)

	_list_vbox = VBoxContainer.new()
	_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_vbox.add_theme_constant_override("separation", 10)
	_scroll.add_child(_list_vbox)

	_card_containers.clear()
	for i in runs.size():
		var card := _build_run_card(runs[i], i)
		_list_vbox.add_child(card)
		_card_containers.append(card)

	_animate_entrance(title)


func _build_empty_state(parent: VBoxContainer) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 80
	parent.add_child(spacer)

	_empty_label = Label.new()
	_empty_label.text = "No runs recorded yet.\n\nPlay a game and your results\nwill appear here!"
	_empty_label.add_theme_font_size_override("font_size", ThemeManager.FONT_MD)
	_empty_label.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(_empty_label)


func _build_stats_bar() -> void:
	var stats: Dictionary = RunHistory.get_stats()
	var total_runs: int = int(stats.get("total_runs", 0))
	var wins: int = int(stats.get("wins", 0))
	var win_rate: int = roundi(float(wins) / maxf(float(total_runs), 1.0) * 100.0)
	var best_grade: String = str(stats.get("best_grade", "—"))
	var avg_score: int = int(stats.get("avg_score", 0))

	# Row 1: Total Runs | Win Rate.
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 12)
	_stats_vbox.add_child(row1)
	_add_stat_cell(row1, "Total Runs", str(total_runs))
	_add_stat_cell(row1, "Win Rate", "%d%%" % win_rate)

	# Row 2: Best Grade | Avg Score.
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 12)
	_stats_vbox.add_child(row2)

	var grade_color: Color = ScoringEngine.GRADE_COLORS.get(best_grade, ThemeManager.C_TEXT)
	_add_stat_cell(row2, "Best Grade", best_grade, grade_color)
	_add_stat_cell(row2, "Avg Score", str(avg_score))


func _add_stat_cell(parent: HBoxContainer, label_text: String, value_text: String,
		value_color: Color = ThemeManager.C_TEXT) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := ThemeManager._flat_box_static(
		ThemeManager.C_SURFACE, ThemeManager.C_BORDER, ThemeManager.CORNER_MD)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)

	var val := Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", ThemeManager.FONT_LG)
	val.add_theme_color_override("font_color", value_color)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(val)


# ---------------------------------------------------------------------------
# Run card
# ---------------------------------------------------------------------------

func _build_run_card(run: Dictionary, index: int) -> PanelContainer:
	var is_win: bool = str(run.get("outcome", "")) == "win"
	var grade: String = str(run.get("grade", "F"))
	var grade_color: Color = ScoringEngine.GRADE_COLORS.get(grade, Color.WHITE)

	# Card panel with left-border tint.
	var card := PanelContainer.new()
	card.custom_minimum_size.y = ThemeManager.TOUCH_MIN_H
	var style := ThemeManager._flat_box_static(
		ThemeManager.C_SURFACE, ThemeManager.C_BORDER, ThemeManager.CORNER_MD)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	# Colored left border — green for win, red for loss.
	style.set_border_width_all(0)
	style.border_width_left = 3
	style.border_color = ThemeManager.C_GREEN if is_win else ThemeManager.C_RED
	card.add_theme_stylebox_override("panel", style)

	var outer_vbox := VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 6)
	card.add_child(outer_vbox)

	# --- Summary row (always visible) ---
	var summary_row := HBoxContainer.new()
	summary_row.add_theme_constant_override("separation", 8)
	outer_vbox.add_child(summary_row)

	# Rank number.
	var rank_lbl := Label.new()
	rank_lbl.text = "#%d" % (index + 1)
	rank_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	rank_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT_MUTED)
	rank_lbl.custom_minimum_size.x = 30
	summary_row.add_child(rank_lbl)

	# Type badge.
	var type_str: String = str(run.get("company_type", ""))
	var type_char: String = TYPE_ICONS.get(type_str, "?")
	var type_badge := Label.new()
	type_badge.text = type_char
	type_badge.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	type_badge.add_theme_color_override("font_color", ThemeManager.C_TEAL)
	type_badge.custom_minimum_size.x = 16
	type_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_row.add_child(type_badge)

	# Company name + outcome.
	var name_col := VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_col.add_theme_constant_override("separation", 1)
	summary_row.add_child(name_col)

	var name_lbl := Label.new()
	name_lbl.text = str(run.get("company_name", "Unknown"))
	name_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_MD)
	name_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT)
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_col.add_child(name_lbl)

	var outcome_lbl := Label.new()
	if is_win:
		var reason_str: String = str(run.get("reason", ""))
		var win_labels: Dictionary = {
			"ipo": "IPO", "acquisition": "Acquired",
			"sustainable": "Sustainable", "unicorn": "Unicorn",
		}
		outcome_lbl.text = "WIN — %s" % win_labels.get(reason_str, reason_str.capitalize())
		outcome_lbl.add_theme_color_override("font_color", ThemeManager.C_GREEN)
	else:
		var reason_str: String = str(run.get("reason", ""))
		var loss_labels: Dictionary = {
			"bankruptcy": "Bankruptcy", "dead_product": "Dead Product",
			"founder_burnout": "Burnout", "board_takeover": "Board Takeover",
		}
		outcome_lbl.text = "LOSS — %s" % loss_labels.get(reason_str, reason_str.replace("_", " ").capitalize())
		outcome_lbl.add_theme_color_override("font_color", ThemeManager.C_RED)
	outcome_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	name_col.add_child(outcome_lbl)

	# Grade badge.
	var grade_lbl := Label.new()
	grade_lbl.text = grade
	grade_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_XL)
	grade_lbl.add_theme_color_override("font_color", grade_color)
	grade_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_lbl.custom_minimum_size.x = 32
	summary_row.add_child(grade_lbl)

	# Score + quarters.
	var score_col := VBoxContainer.new()
	score_col.add_theme_constant_override("separation", 0)
	score_col.custom_minimum_size.x = 42
	summary_row.add_child(score_col)

	var score_lbl := Label.new()
	score_lbl.text = str(int(run.get("founder_score", 0)))
	score_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_MD)
	score_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_col.add_child(score_lbl)

	var q_lbl := Label.new()
	var quarters: int = int(run.get("quarters_survived", 0))
	q_lbl.text = "%dQ" % quarters
	q_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	q_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
	q_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_col.add_child(q_lbl)

	# --- Detail section (hidden until tapped) ---
	var detail := VBoxContainer.new()
	detail.name = "DetailSection"
	detail.visible = false
	detail.add_theme_constant_override("separation", 4)
	outer_vbox.add_child(detail)

	var detail_sep := HSeparator.new()
	detail.add_child(detail_sep)

	_add_detail_row(detail, "Company Type", type_str)
	var niche_str: String = str(run.get("niche", ""))
	if not niche_str.is_empty():
		_add_detail_row(detail, "Niche", niche_str)
	_add_detail_row(detail, "Difficulty", str(run.get("difficulty", "normal")).capitalize())
	_add_detail_row(detail, "Quarters Survived", str(quarters))

	var years: int = quarters / 4
	var rem_q: int = quarters % 4
	var time_text: String = ""
	if years > 0:
		time_text = "%d year%s" % [years, "s" if years != 1 else ""]
		if rem_q > 0:
			time_text += ", %d quarter%s" % [rem_q, "s" if rem_q != 1 else ""]
	else:
		time_text = "%d quarter%s" % [rem_q, "s" if rem_q != 1 else ""]
	_add_detail_row(detail, "Time", time_text)

	_add_detail_row(detail, "Final Cash",
		"$%s" % SceneLoader.format_money(float(run.get("final_cash", 0))))
	_add_detail_row(detail, "Peak Users",
		SceneLoader.format_number(int(run.get("peak_users", 0))))
	_add_detail_row(detail, "Team Size", str(int(run.get("team_size", 0))))
	_add_detail_row(detail, "Features Shipped", str(int(run.get("features_shipped", 0))))
	_add_detail_row(detail, "Founder Score",
		"%d / 100" % int(run.get("founder_score", 0)))

	var ts: float = float(run.get("timestamp", 0))
	if ts > 0:
		var dt: Dictionary = Time.get_datetime_dict_from_unix_time(int(ts))
		var date_str: String = "%04d-%02d-%02d" % [
			int(dt.get("year", 2025)),
			int(dt.get("month", 1)),
			int(dt.get("day", 1)),
		]
		_add_detail_row(detail, "Date", date_str)

	# Make the card tappable.
	card.gui_input.connect(_on_card_input.bind(index))
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	return card


func _add_detail_row(parent: VBoxContainer, key: String, value: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var key_lbl := Label.new()
	key_lbl.text = key
	key_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	key_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
	key_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(key_lbl)

	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	val_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_lbl)

	parent.add_child(row)


# ---------------------------------------------------------------------------
# Interaction
# ---------------------------------------------------------------------------

func _on_card_input(event: InputEvent, index: int) -> void:
	if not event is InputEventMouseButton:
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return

	if index < 0 or index >= _card_containers.size():
		return

	# Collapse previously expanded card.
	if _expanded_card_index >= 0 and _expanded_card_index < _card_containers.size():
		var prev_detail: Control = _card_containers[_expanded_card_index].get_node_or_null("VBoxContainer/DetailSection")
		if prev_detail == null:
			# Try the outer_vbox name pattern.
			for child in _card_containers[_expanded_card_index].get_children():
				if child is VBoxContainer:
					prev_detail = child.get_node_or_null("DetailSection")
					break
		if prev_detail:
			prev_detail.visible = false

	# Toggle tapped card.
	var tapped_detail: Control = null
	for child in _card_containers[index].get_children():
		if child is VBoxContainer:
			tapped_detail = child.get_node_or_null("DetailSection")
			break

	if tapped_detail:
		if _expanded_card_index == index:
			# Same card — collapse (already collapsed above).
			_expanded_card_index = -1
			SfxPlayer.play("click")
		else:
			tapped_detail.visible = true
			_expanded_card_index = index
			AnimHelper.fade_in(tapped_detail, 0.0, 0.15)
			SfxPlayer.play("click")
			AnimHelper.haptic(&"light")


func _on_back() -> void:
	SceneLoader.goto_scene("res://src/ui/main_menu/main_menu.tscn")


# ---------------------------------------------------------------------------
# Animations
# ---------------------------------------------------------------------------

func _animate_entrance(title: Label) -> void:
	AnimHelper.pop_in(title, 0.0, 0.28)
	if _stats_vbox:
		AnimHelper.fade_in(_stats_vbox, 0.12, 0.22)
	if _list_vbox:
		AnimHelper.stagger_list(_list_vbox, 0.05, 0.25, 24.0)
	AnimHelper.slide_in(back_btn, Vector2(-40, 0), 0.0, 0.20)


func _animate_entrance_empty(title: Label) -> void:
	AnimHelper.pop_in(title, 0.0, 0.28)
	if _empty_label:
		AnimHelper.fade_in(_empty_label, 0.20, 0.30)
	AnimHelper.slide_in(back_btn, Vector2(-40, 0), 0.0, 0.20)
