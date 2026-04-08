extends Control
## Shown when the player loses. Displays failure reason, stats, and options.

@onready var reason_label: Label = %ReasonLabel
@onready var stats_label: Label = %StatsLabel
@onready var angel_panel: PanelContainer = %AngelPanel
@onready var angel_title: Label = %AngelTitle
@onready var angel_flavor: Label = %AngelFlavor
@onready var angel_offer: Label = %AngelOffer
@onready var accept_angel_btn: Button = %AcceptAngelButton
@onready var decline_angel_btn: Button = %DeclineAngelButton
@onready var restart_btn: Button = %RestartButton
@onready var menu_btn: Button = %MenuButton

const GAME_OVER_MESSAGES: Dictionary = {
	"bankruptcy": "You Ran Out of Money",
	"dead_product": "Nobody's Using Your Product",
	"founder_burnout": "Founder Burnout",
	"board_takeover": "The Board Replaced You",
}

const ANGELS: Array = [
	{
		"name": "Peer Gregor",
		"firm": "Gregor Ventures",
		"title_text": "An Angel Appears...",
		"equity_mult": 1.0,
		"amount_mult": 1.0,
		"quotes": [
			"I don't invest in people. I invest in ideas. Your idea is... adequate.",
			"Your company is failing. That makes this a buying opportunity.",
			"I once mass-shorted Icelandic bonds. I can certainly save your little startup.",
			"Most founders fail because they care about being liked. I don't have that problem. Neither should you.",
		],
	},
	{
		"name": "Ross Hahneman",
		"firm": "Tres Commas Capital",
		"title_text": "A McLaren Pulls Up...",
		"equity_mult": 1.3,
		"amount_mult": 1.5,
		"quotes": [
			"This guy fucks. Wait, wrong meeting. Anyway — you need money? I HAVE money. Three commas.",
			"I put radio on the internet. You think I can't save a little startup? Please.",
			"Know what's cooler than a billion dollars? Owning a piece of YOUR company. Actually no, a billion dollars is cooler. But I'll do both.",
			"My doors go like THIS. ↑ Not like this →. That's the kind of energy I'm bringing to your cap table.",
		],
	},
]

var _chosen_angel: Dictionary


func _ready() -> void:
	accept_angel_btn.pressed.connect(_on_accept_angel)
	decline_angel_btn.pressed.connect(_on_decline_angel)
	restart_btn.pressed.connect(_on_restart)
	menu_btn.pressed.connect(_on_menu)
	UITouchHelper.harden_tree(self)
	Analytics.track_screen("game_over")
	_animate_entrance()

	var reason: String = GameState.get_meta("game_over_reason", "bankruptcy") if GameState.has_meta("game_over_reason") else "bankruptcy"
	var display_reason: String = GAME_OVER_MESSAGES.get(reason, reason.replace("_", " ").capitalize())
	reason_label.text = display_reason

	var quarters: int = GameState.total_quarters_elapsed()
	var years: int = quarters / 4
	var remaining_q: int = quarters % 4
	var time_text := ""
	if years > 0:
		time_text = "%d year%s" % [years, "s" if years != 1 else ""]
		if remaining_q > 0:
			time_text += ", %d quarter%s" % [remaining_q, "s" if remaining_q != 1 else ""]
	else:
		time_text = "%d quarter%s" % [remaining_q, "s" if remaining_q != 1 else ""]

	stats_label.text = "%s survived %s\n\nFinal cash: $%s\nPeak users: %s\nTeam size: %d\nFeatures shipped: %d" % [
		GameState.company.company_name if GameState.company else "Your Company",
		time_text,
		SceneLoader.format_money(GameState.company.cash if GameState.company else 0.0),
		SceneLoader.format_number(_peak_users()),
		GameState.employees.size(),
		GameState.product.feature_count() if GameState.product else 0,
	]

	_build_founder_score()
	_build_prestige_summary()
	SfxPlayer.play("game_over")

	if GameState.angel_bailout_used:
		angel_panel.visible = false
	else:
		_chosen_angel = ANGELS.pick_random()
		angel_panel.visible = true
		angel_title.text = _chosen_angel["title_text"]
		var quotes: Array = _chosen_angel["quotes"]
		var quote: String = quotes.pick_random()
		angel_flavor.text = "\"%s\"\n— %s, %s" % [quote, _chosen_angel["name"], _chosen_angel["firm"]]
		var offer := _calculate_angel_offer()
		angel_offer.text = "Offers $%sK for %d%% equity" % [
			str(snapped(offer["amount"] / 1000.0, 0.1)),
			roundi(offer["equity"]),
		]


func _calculate_angel_offer() -> Dictionary:
	var quarters_survived: int = GameState.total_quarters_elapsed()
	var base_amount := 50_000.0
	if quarters_survived >= 8:
		base_amount = 150_000.0
	elif quarters_survived >= 4:
		base_amount = 100_000.0

	var equity_cost := 35.0
	if quarters_survived >= 8:
		equity_cost = 25.0
	elif quarters_survived >= 4:
		equity_cost = 30.0

	base_amount *= _chosen_angel.get("amount_mult", 1.0)
	equity_cost *= _chosen_angel.get("equity_mult", 1.0)

	return {"amount": base_amount, "equity": equity_cost}


func _on_accept_angel() -> void:
	var offer := _calculate_angel_offer()
	var angel_name: String = _chosen_angel.get("name", "unknown")
	Analytics.track_angel_decision(true, angel_name, offer["amount"])
	GameState.angel_bailout_used = true
	GameState.company.cash += offer["amount"]
	GameState.company.equity_owned -= offer["equity"]
	GameState.company.equity_owned = maxf(5.0, GameState.company.equity_owned)
	GameState.is_game_active = true

	GameState.append_event_log({
		"quarter": GameState.current_quarter,
		"year": GameState.current_year,
		"event_id": "angel_bailout",
		"title": "%s invested $%sK for %d%% equity" % [
			angel_name,
			str(snapped(offer["amount"] / 1000.0, 0.1)),
			roundi(offer["equity"]),
		],
	})
	GameState.auto_save()
	SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")


func _on_decline_angel() -> void:
	var angel_name: String = _chosen_angel.get("name", "unknown")
	Analytics.track_angel_decision(false, angel_name, 0.0)
	angel_panel.visible = false


func _on_restart() -> void:
	SceneLoader.goto_scene("res://src/ui/saves/save_slots.tscn")


func _on_menu() -> void:
	SceneLoader.goto_scene("res://src/ui/main_menu/main_menu.tscn")


func _build_founder_score() -> void:
	var result: Dictionary = ScoringEngine.calculate(GameState)
	var grade: String = result.get("grade", "F")
	var score: int = result.get("score", 0)
	var grade_color: Color = result.get("grade_color", Color.WHITE)
	var summary: String = result.get("summary", "")

	# Add score section after stats.
	var score_section := VBoxContainer.new()
	score_section.add_theme_constant_override("separation", 6)

	var divider := HSeparator.new()
	score_section.add_child(divider)

	var header := Label.new()
	header.text = "FOUNDER SCORE"
	header.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	header.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_section.add_child(header)

	var grade_label := Label.new()
	grade_label.text = "%s  (%d/100)" % [grade, score]
	grade_label.add_theme_font_size_override("font_size", 36)
	grade_label.add_theme_color_override("font_color", grade_color)
	grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_section.add_child(grade_label)

	var summary_lbl := Label.new()
	summary_lbl.text = summary
	summary_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	summary_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT)
	summary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	score_section.add_child(summary_lbl)

	# Breakdown bars — shows what the player did well (or poorly) across axes.
	var breakdown: Dictionary = result.get("breakdown", {})
	for key in ["finances", "growth", "product", "team", "speed", "reputation"]:
		if not breakdown.has(key):
			continue
		var axis: Dictionary = breakdown[key]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var axis_label := Label.new()
		axis_label.text = axis.get("label", key)
		axis_label.add_theme_font_size_override("font_size", 11)
		axis_label.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
		axis_label.custom_minimum_size.x = 120
		row.add_child(axis_label)

		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = axis.get("score", 0)
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 12)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ThemeManager.tint_bar(bar, bar.value, 100.0)
		row.add_child(bar)

		var val_label := Label.new()
		val_label.text = "%d" % int(axis.get("score", 0))
		val_label.add_theme_font_size_override("font_size", 11)
		val_label.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
		val_label.custom_minimum_size.x = 28
		val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(val_label)

		score_section.add_child(row)

	# Insert after stats_label.
	var parent := stats_label.get_parent()
	if parent:
		var idx := stats_label.get_index() + 1
		parent.add_child(score_section)
		parent.move_child(score_section, idx)


func _build_prestige_summary() -> void:
	var level: int = PrestigeManager.get_level()
	var xp: int = PrestigeManager.get_xp()
	var xp_next: int = PrestigeManager.get_xp_for_next()
	var progress: float = PrestigeManager.get_level_progress()

	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)

	var divider := HSeparator.new()
	section.add_child(divider)

	var header := Label.new()
	header.text = "FOUNDER LEVEL"
	header.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	header.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(header)

	var level_lbl := Label.new()
	level_lbl.text = "Level %d" % level
	level_lbl.add_theme_font_size_override("font_size", 20)
	level_lbl.add_theme_color_override("font_color", ThemeManager.C_PURPLE)
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(level_lbl)

	if xp_next > 0:
		var bar := ProgressBar.new()
		bar.min_value = 0.0
		bar.max_value = 1.0
		bar.value = progress
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 8)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		section.add_child(bar)

		var xp_lbl := Label.new()
		xp_lbl.text = "%d / %d XP" % [xp, xp_next]
		xp_lbl.add_theme_font_size_override("font_size", 11)
		xp_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
		xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		section.add_child(xp_lbl)

	# Insert after the score section.
	var parent := stats_label.get_parent()
	if parent:
		parent.add_child(section)


func _animate_entrance() -> void:
	# Somber, slower reveals — this is a loss screen.
	AnimHelper.fade_in(reason_label, 0.0, 0.40)
	AnimHelper.fade_in(stats_label, 0.25, 0.35)
	# Angel panel slides up as a dramatic reveal — hope after failure.
	if angel_panel.visible:
		AnimHelper.slide_in(angel_panel, Vector2(0, 40), 0.50, 0.30)
	# Buttons fade in last.
	for btn in [restart_btn, menu_btn]:
		if btn != null:
			AnimHelper.fade_in(btn, 0.70, 0.25)


func _peak_users() -> int:
	var peak := 0
	for snap: Dictionary in GameState.history:
		var u: int = snap.get("users", 0)
		if u > peak:
			peak = u
	if GameState.product and GameState.product.users > peak:
		peak = GameState.product.users
	return peak


