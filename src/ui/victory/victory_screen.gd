extends Control
## Victory screen — shown when the player wins via any of the 4 win conditions.

@onready var win_title: Label = %WinTitle
@onready var win_subtitle: Label = %WinSubtitle
@onready var stats_label: Label = %StatsLabel
@onready var timeline_container: VBoxContainer = %TimelineContainer
@onready var continue_btn: Button = %ContinueButton
@onready var menu_btn: Button = %MenuButton
@onready var new_game_btn: Button = %NewGameButton

const WIN_DATA: Dictionary = {
	"ipo": {
		"title": "IPO",
		"subtitle": "You took %s public.",
		"flavor": "The bell rings on the trading floor. Your stock symbol flashes across every financial news screen in the world. You did it.",
	},
	"acquisition": {
		"title": "Acquired",
		"subtitle": "%s has been acquired.",
		"flavor": "The deal is done. Your team gets payouts. Some cry, some cheer, some do both. It's bittersweet — but it's a win.",
	},
	"sustainable": {
		"title": "Sustainable Business",
		"subtitle": "%s is profitable and self-sustaining.",
		"flavor": "No more fundraising. No more runway anxiety. You built something that pays for itself. Most founders never get here.",
	},
	"unicorn": {
		"title": "Unicorn",
		"subtitle": "%s is valued at over $1 Billion.",
		"flavor": "The mythical creature is real. $1B valuation. Magazine covers. Conference keynotes. The garage feels like a lifetime ago.",
	},
}


func _ready() -> void:
	continue_btn.pressed.connect(_on_continue)
	menu_btn.pressed.connect(_on_menu)
	new_game_btn.pressed.connect(_on_new_game)
	UITouchHelper.harden_tree(self)
	Analytics.track_screen("victory")

	var win_type: String = GameState.get_meta("win_type", "ipo") if GameState.has_meta("win_type") else "ipo"
	var data: Dictionary = WIN_DATA.get(win_type, WIN_DATA["ipo"])
	var company_name: String = GameState.company.company_name if GameState.company else "Your Company"

	win_title.text = data["title"]
	win_subtitle.text = data["subtitle"] % company_name

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

	stats_label.text = "%s\n\nTime: %s\nFinal valuation: $%s\nRevenue: $%s per quarter\nUsers: %s\nTeam: %d people\nEquity retained: %d%%\nFeatures shipped: %d" % [
		data["flavor"],
		time_text,
		SceneLoader.format_money(GameState.company.valuation if GameState.company else 0.0),
		SceneLoader.format_money(GameState.financials.revenue if GameState.financials else 0.0),
		SceneLoader.format_number(GameState.product.users if GameState.product else 0),
		GameState.employees.size(),
		roundi(GameState.company.equity_owned) if GameState.company else 0,
		GameState.product.feature_count() if GameState.product else 0,
	]

	_build_founder_score()
	_build_prestige_summary()
	_build_timeline()
	_build_achievements_summary()
	_animate_entrance()
	SfxPlayer.play("victory")
	AnimHelper.haptic(&"heavy")


func _build_founder_score() -> void:
	var result: Dictionary = ScoringEngine.calculate(GameState)
	var grade: String = result.get("grade", "C")
	var score: int = result.get("score", 0)
	var grade_color: Color = result.get("grade_color", Color.WHITE)
	var summary: String = result.get("summary", "")

	# Insert score section before timeline.
	var score_section := VBoxContainer.new()
	score_section.add_theme_constant_override("separation", 8)

	var divider := HSeparator.new()
	divider.add_theme_stylebox_override("separator", StyleBoxLine.new())
	score_section.add_child(divider)

	var header := Label.new()
	header.text = "FOUNDER SCORE"
	header.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	header.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_section.add_child(header)

	var grade_label := Label.new()
	grade_label.text = grade
	grade_label.add_theme_font_size_override("font_size", 48)
	grade_label.add_theme_color_override("font_color", grade_color)
	grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_section.add_child(grade_label)

	var score_num := Label.new()
	score_num.text = "%d / 100" % score
	score_num.add_theme_font_size_override("font_size", ThemeManager.FONT_MD)
	score_num.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
	score_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_section.add_child(score_num)

	var summary_lbl := Label.new()
	summary_lbl.text = summary
	summary_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	summary_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT)
	summary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	score_section.add_child(summary_lbl)

	# Breakdown bars.
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

	# Insert before the timeline container.
	var parent := timeline_container.get_parent()
	if parent:
		var idx := timeline_container.get_index()
		parent.add_child(score_section)
		parent.move_child(score_section, idx)


func _build_prestige_summary() -> void:
	var level: int = PrestigeManager.get_level()
	var xp: int = PrestigeManager.get_xp()
	var xp_next: int = PrestigeManager.get_xp_for_next()
	var progress: float = PrestigeManager.get_level_progress()

	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)

	var header := Label.new()
	header.text = "FOUNDER LEVEL"
	header.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	header.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(header)

	var level_lbl := Label.new()
	level_lbl.text = "Level %d" % level
	level_lbl.add_theme_font_size_override("font_size", 22)
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

	# Show newly unlocked perks.
	var perks: Array[Dictionary] = PrestigeManager.get_unlocked_perk_defs()
	if not perks.is_empty():
		var perks_text: Array[String] = []
		for perk: Dictionary in perks:
			perks_text.append("%s %s" % [perk.get("icon", ""), perk.get("title", "")])
		if perks_text.size() > 4:
			perks_text.resize(4)
			perks_text.append("... +%d more" % (perks.size() - 4))
		var perks_lbl := Label.new()
		perks_lbl.text = "\n".join(perks_text)
		perks_lbl.add_theme_font_size_override("font_size", 11)
		perks_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
		perks_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		section.add_child(perks_lbl)

	var parent := timeline_container.get_parent()
	if parent:
		parent.add_child(section)
		parent.move_child(section, timeline_container.get_index())


func _build_achievements_summary() -> void:
	if not AchievementManager:
		return
	var unlocked := AchievementManager.get_unlock_count()
	var total := AchievementManager.get_total_count()
	if total <= 0:
		return

	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)

	var header := Label.new()
	header.text = "Achievements: %d / %d" % [unlocked, total]
	header.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	header.add_theme_color_override("font_color", ThemeManager.C_GOLD)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(header)

	# Show recently unlocked achievements from this run.
	var recent: Array[String] = []
	for def in AchievementManager.get_all():
		if AchievementManager.is_unlocked(def.get("id", "")):
			recent.append("%s %s" % [def.get("icon", "🏆"), def.get("title", "")])
	if recent.size() > 6:
		recent.resize(6)
		recent.append("... and more")

	if not recent.is_empty():
		var list_lbl := Label.new()
		list_lbl.text = "\n".join(recent)
		list_lbl.add_theme_font_size_override("font_size", 12)
		list_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
		list_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		section.add_child(list_lbl)

	var parent := timeline_container.get_parent()
	if parent:
		parent.add_child(section)
		parent.move_child(section, timeline_container.get_index())


func _build_timeline() -> void:
	for child in timeline_container.get_children():
		timeline_container.remove_child(child)
		child.queue_free()

	var key_moments: Array[Dictionary] = []
	for entry: Dictionary in GameState.event_log:
		var eid: String = entry.get("event_id", "")
		if eid.begins_with("milestone_") or eid.begins_with("synergy_") or eid == "angel_bailout" or eid == "acquisition_offer":
			key_moments.append(entry)

	if key_moments.is_empty():
		var lbl := Label.new()
		lbl.text = "A quiet journey — but you made it."
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		timeline_container.add_child(lbl)
		return

	for moment: Dictionary in key_moments:
		var lbl := Label.new()
		var yr: int = moment.get("year", 1)
		var qt: int = moment.get("quarter", 1)
		lbl.text = "Y%d Q%d — %s" % [yr, qt, moment.get("title", "")]
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.6, 0.75, 0.6))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		timeline_container.add_child(lbl)


func _animate_entrance() -> void:
	# Title: big celebratory pop.
	AnimHelper.pop_in(win_title, 0.0, 0.36)
	# Subtitle: slide up.
	AnimHelper.slide_in(win_subtitle, Vector2(0, 24), 0.10, 0.26)
	# Stats: fade in after title lands.
	AnimHelper.fade_in(stats_label, 0.28, 0.30)
	# Timeline: stagger the milestone entries.
	AnimHelper.stagger_list(timeline_container, 0.06, 0.40, 20.0)
	# Buttons: slide up from bottom, staggered.
	var buttons: Array[Control] = []
	for btn in [continue_btn, menu_btn, new_game_btn]:
		if btn != null:
			buttons.append(btn)
	for i in buttons.size():
		AnimHelper.slide_in(buttons[i], Vector2(0, 28), 0.55 + i * 0.06)
	# Celebratory pulse on the title after it lands.
	get_tree().create_timer(0.40).timeout.connect(func() -> void:
		if is_instance_valid(win_title):
			AnimHelper.pulse(win_title, 1.12, 0.20))


func _on_menu() -> void:
	SceneLoader.goto_scene("res://src/ui/main_menu/main_menu.tscn")


func _on_continue() -> void:
	GameState.continue_after_victory()
	SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")


func _on_new_game() -> void:
	SceneLoader.goto_scene("res://src/ui/saves/save_slots.tscn")


