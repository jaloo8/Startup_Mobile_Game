extends Control

@onready var play_btn: Button = %PlayButton
@onready var continue_btn: Button = %ContinueButton
@onready var settings_btn: Button = %SettingsButton
@onready var quit_btn: Button = %QuitButton

var _continue_slot: String = ""
var _badges_container: HBoxContainer
var _history_btn: Button
var _achievements_btn: Button


func _ready() -> void:
	play_btn.pressed.connect(_on_play)
	continue_btn.pressed.connect(_on_continue)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	_refresh_continue_state()
	_build_meta_badges()
	_build_extra_buttons()
	UITouchHelper.harden_tree(self)
	Analytics.track_screen("main_menu")
	_animate_entrance()
	# Check for daily login bonus on main menu load.
	_check_daily_bonus()


func _on_play() -> void:
	# Restore canonical flow: Play -> Save Slots.
	if get_node_or_null("/root/SceneLoader") != null:
		SceneLoader.goto_scene("res://src/ui/saves/save_slots.tscn")
		return
	var err := get_tree().change_scene_to_file("res://src/ui/saves/save_slots.tscn")
	if err != OK:
		push_error("MainMenu: failed to open Save Slots scene (err=%d)" % err)


func _on_continue() -> void:
	if _continue_slot.is_empty():
		_on_play()
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		_on_play()
		return
	gs.set("current_slot", _continue_slot)
	if not bool(gs.call("load_game", _continue_slot)):
		push_warning("MainMenu: failed to load continue slot '%s'" % _continue_slot)
		_refresh_continue_state()
		_on_play()
		return
	EventEngine.load_events("res://src/data/events.json")
	WorldEventEngine.load_events("res://src/data/world_events.json")
	ProductData.load_feature_catalog("res://src/data/features.json")
	CompanyData.load_niche_catalog()
	HeadlineEngine.load_headlines("res://src/data/headlines.json")
	SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")


func _refresh_continue_state() -> void:
	_continue_slot = ""
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		continue_btn.disabled = true
		continue_btn.text = "Continue Last Run"
		return

	if gs.has_method("latest_save_slot"):
		_continue_slot = str(gs.call("latest_save_slot"))

	continue_btn.disabled = _continue_slot.is_empty()
	if _continue_slot.is_empty():
		continue_btn.text = "Continue Last Run"
		return

	var label := "Continue Last Run"
	if gs.has_method("peek_save"):
		var info = gs.call("peek_save", _continue_slot)
		if info is Dictionary and bool(info.get("exists", false)):
			var company_name := str(info.get("company_name", "")).strip_edges()
			if not company_name.is_empty():
				label = "Continue: %s" % company_name
	continue_btn.text = label


func _animate_entrance() -> void:
	# Title: pop in with spring overshoot.
	var title: Label = get_node_or_null("CenterContainer/VBox/Title")
	if title:
		AnimHelper.pop_in(title, 0.0, 0.32)

	# Subtitle: fade in slightly delayed.
	var subtitle: Label = get_node_or_null("CenterContainer/VBox/Subtitle")
	if subtitle:
		AnimHelper.fade_in(subtitle, 0.12, 0.24)

	# Badges: fade in.
	if _badges_container and is_instance_valid(_badges_container):
		AnimHelper.fade_in(_badges_container, 0.16, 0.22)

	# Buttons: stagger slide up from below.
	var buttons: Array[Control] = []
	for btn in [play_btn, continue_btn, settings_btn, quit_btn]:
		if btn != null:
			buttons.append(btn)
	if _achievements_btn and is_instance_valid(_achievements_btn):
		buttons.append(_achievements_btn)
	if _history_btn and is_instance_valid(_history_btn):
		buttons.append(_history_btn)
	for i in buttons.size():
		AnimHelper.slide_in(buttons[i], Vector2(0, 32), 0.18 + i * 0.06)


func _on_settings() -> void:
	SceneLoader.goto_scene("res://src/ui/settings/settings_screen.tscn")


func _on_quit() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_method("autosave_now"):
			gs.call("autosave_now", "main_menu_quit")
		elif gs.has_method("save_game"):
			var slot_name: String = str(gs.get("current_slot"))
			if not slot_name.is_empty():
				gs.call("save_game", slot_name)
	get_tree().quit()


func _on_history() -> void:
	SceneLoader.goto_scene("res://src/ui/history/run_history_screen.tscn")


func _on_achievements() -> void:
	SceneLoader.goto_scene("res://src/ui/achievements/achievement_screen.tscn")


# ---------------------------------------------------------------------------
# Meta-progression badges (achievements, streak, founder level)
# ---------------------------------------------------------------------------

func _build_meta_badges() -> void:
	# Insert a compact badge row below the subtitle.
	var vbox: VBoxContainer = get_node_or_null("CenterContainer/VBox")
	if vbox == null:
		return

	_badges_container = HBoxContainer.new()
	_badges_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_badges_container.add_theme_constant_override("separation", 16)
	_badges_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Achievement badge: "🏆 12/40"
	var ach_mgr: Node = get_node_or_null("/root/AchievementManager")
	if ach_mgr and ach_mgr.has_method("get_unlock_count") and ach_mgr.has_method("get_total_count"):
		var unlocked: int = ach_mgr.call("get_unlock_count")
		var total: int = ach_mgr.call("get_total_count")
		if total > 0:
			_badges_container.add_child(_make_badge(
				"🏆 %d/%d" % [unlocked, total],
				ThemeManager.C_GOLD if unlocked > 0 else ThemeManager.C_TEXT_DIM
			))

	# Streak badge: "🔥 5 days"
	var daily: Node = get_node_or_null("/root/DailyBonus")
	if daily and daily.has_method("get_streak"):
		var streak: int = daily.call("get_streak")
		if streak > 0:
			_badges_container.add_child(_make_badge(
				"🔥 %d day%s" % [streak, "s" if streak != 1 else ""],
				ThemeManager.C_GREEN if streak >= 3 else ThemeManager.C_TEXT
			))

	# Founder level badge: "⭐ Lv.8"
	var prestige: Node = get_node_or_null("/root/PrestigeManager")
	if prestige and prestige.has_method("get_level"):
		var level: int = prestige.call("get_level")
		if level > 1:
			_badges_container.add_child(_make_badge(
				"⭐ Lv.%d" % level,
				ThemeManager.C_PURPLE
			))

	if _badges_container.get_child_count() > 0:
		# Insert after Spacer (index 2) or after Subtitle (index 1).
		var spacer: Control = vbox.get_node_or_null("Spacer")
		var idx := spacer.get_index() if spacer else 2
		vbox.add_child(_badges_container)
		vbox.move_child(_badges_container, idx)


func _make_badge(text: String, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl


func _build_extra_buttons() -> void:
	var vbox: VBoxContainer = get_node_or_null("CenterContainer/VBox")
	if vbox == null:
		return

	# Achievements button — always available once any achievement exists.
	var ach_mgr: Node = get_node_or_null("/root/AchievementManager")
	if ach_mgr and ach_mgr.has_method("get_total_count") and int(ach_mgr.call("get_total_count")) > 0:
		_achievements_btn = _make_ghost_button("Achievements", ThemeManager.C_GOLD.lerp(ThemeManager.C_TEXT_DIM, 0.4))
		_achievements_btn.pressed.connect(_on_achievements)
		vbox.add_child(_achievements_btn)

	# Run History button — only shown after at least one completed run.
	var rh: Node = get_node_or_null("/root/RunHistory")
	if rh == null:
		return
	var stats: Variant = rh.call("get_stats") if rh.has_method("get_stats") else null
	if stats is Dictionary and int(stats.get("total_runs", 0)) > 0:
		_history_btn = _make_ghost_button("Hall of Fame", ThemeManager.C_TEXT_DIM)
		_history_btn.pressed.connect(_on_history)
		vbox.add_child(_history_btn)


func _make_ghost_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 46)
	btn.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	btn.add_theme_color_override("font_color", color)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.20, 0.5)
	style.set_corner_radius_all(ThemeManager.CORNER_MD)
	style.set_content_margin_all(8.0)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = style.bg_color.lightened(0.08)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", style)
	return btn


func _check_daily_bonus() -> void:
	var daily: Node = get_node_or_null("/root/DailyBonus")
	if daily == null:
		return
	if daily.has_method("check_daily"):
		daily.call("check_daily")
	# Auto-claim if available (no modal needed for small daily bonuses).
	if daily.has_method("has_claimed_today") and not bool(daily.call("has_claimed_today")):
		if daily.has_method("claim"):
			# Small delay so the main menu is visible when the toast appears.
			get_tree().create_timer(0.8).timeout.connect(func() -> void:
				if is_instance_valid(daily) and daily.has_method("claim"):
					daily.call("claim")
			)
