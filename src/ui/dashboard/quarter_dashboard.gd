extends Control
## Main gameplay screen.
##
## AI INTEGRATION OPPORTUNITY: The office scene (workers, furniture, decorations)
## could use AI-generated background art via ComfyUI + SDXL pixel-art LoRA.
## Generate unique office backgrounds per office_level at build time, replacing
## the static PNGs. See docs/AI_TECH_OPPORTUNITIES.md for the workflow.

@onready var quarter_label: Label = %QuarterLabel
@onready var company_label: Label = %CompanyLabel
@onready var office_banner: TextureRect = %OfficeBanner
@onready var stats_grid: GridContainer = $MarginContainer/VBox/StatsGrid
@onready var cash_label: Label = %CashLabel
@onready var users_label: Label = %UsersLabel
@onready var runway_label: Label = %RunwayLabel
@onready var employees_label: Label = %EmployeesLabel
@onready var revenue_label: Label = %RevenueLabel
@onready var burn_label: Label = %BurnLabel
@onready var cash_title_btn: Button = %CashTitle
@onready var revenue_title_btn: Button = %RevenueTitle
@onready var burn_title_btn: Button = %BurnTitle
@onready var runway_title_btn: Button = %RunwayTitle
@onready var advance_btn: Button = %AdvanceButton
@onready var people_btn: Button = %PeopleButton
@onready var product_btn: Button = %ProductButton
@onready var finance_btn: Button = %FinanceButton
@onready var market_btn: Button = %MarketButton
@onready var menu_btn: Button = %MenuButton
@onready var event_log_container: VBoxContainer = %EventLogContainer
@onready var team_container: VBoxContainer = %TeamContainer
@onready var event_popup: EventPopup = %EventPopup
@onready var report_panel: PanelContainer = %ReportPanel
@onready var report_header: Label = %ReportHeader
@onready var report_body: Label = %ReportBody
@onready var events_label: Label = $MarginContainer/VBox/EventsLabel
@onready var headline_label: Label = %HeadlineLabel
@onready var economy_label: Label = %EconomyLabel
@onready var energy_label: Label = %EnergyLabel
@onready var key_metric_title: Button = %KeyMetricTitle
@onready var key_metric_label: Label = %KeyMetricLabel
@onready var ticker_strip: Label = %TickerStrip
@onready var quarter_transition_tint: ColorRect = %QuarterTransitionTint

const MAX_VISIBLE_EVENTS := 10
const HEADLINE_ROTATE_SECONDS := 4.0
const DASHBOARD_REPORT_BULLET_LIMIT := 5

const OFFICE_BANNER_PATHS: Array = [
	"res://assets/office/office_0_garage.png",
	"res://assets/office/office_1_coworking.png",
	"res://assets/office/office_2_small.png",
	"res://assets/office/office_3_hq.png",
]
const QUARTER_TRANSITION_WHOOSH_PATHS: Array = [
	"res://assets/audio/sfx/quarter_whoosh.ogg",
	"res://assets/audio/sfx/quarter_whoosh.wav",
]
const QUARTER_TRANSITION_DING_PATHS: Array = [
	"res://assets/audio/sfx/quarter_ding.ogg",
	"res://assets/audio/sfx/quarter_ding.wav",
]
const OFFICE_WORKSPACE_STYLES: Dictionary = {
	0: {"rows": 1, "per_row": 3, "base_y_ratio": 0.70, "row_gap": 14.0, "desk_w": 16.0, "desk_h": 4.0},
	1: {"rows": 1, "per_row": 5, "base_y_ratio": 0.66, "row_gap": 14.0, "desk_w": 17.0, "desk_h": 4.0},
	2: {"rows": 2, "per_row": 5, "base_y_ratio": 0.60, "row_gap": 15.0, "desk_w": 18.0, "desk_h": 4.0},
	3: {"rows": 2, "per_row": 6, "base_y_ratio": 0.56, "row_gap": 14.0, "desk_w": 18.0, "desk_h": 4.0},
}

var _pending_events: Array[EventData] = []
var _headlines: Array[String] = []
var _headline_index: int = 0
var _headline_timer: Timer
var _prev_valuation: float = 0.0

# Dynamically created delta labels next to each stat
var _cash_delta_label: Label
var _revenue_delta_label: Label
var _burn_delta_label: Label
# Feature-shipped celebration shown briefly on the dashboard
var _feature_banner: Label
var _turn_summary_panel: PanelContainer
var _turn_summary_label: Label
var _next_action_label: Label
var _advance_hint_label: Label
var _advance_toast_panel: PanelContainer
var _advance_toast_label: Label
var _hosting_status_label: Label
var _transition_sweep: ColorRect
var _transition_label: Label
var _transition_sfx_player: AudioStreamPlayer
var _transition_whoosh_stream: AudioStream
var _transition_ding_stream: AudioStream
var _transition_tween: Tween
var _office_worker_layer: Control
var _finance_plain_label: Label
var _key_metric_glossary_key: String = "valuation"

# Idle engine / soft currency HUD
var _chip_hud_label: Label
var _passive_ticker_label: Label
var _boost_idle_btn: Button
var _offline_summary_backdrop: ColorRect
# Economy mood lighting — subtle edge tint for bull/bear atmosphere.
var _economy_vignette: ColorRect

# --- Performance caches (avoid per-refresh allocations on mobile) ---
# Avatar textures loaded once, keyed by index (1-8). Avoids ResourceLoader.load() per employee per refresh.
static var _avatar_cache: Dictionary = {}  # int -> Texture2D
# Debounce guard for office banner resize to prevent rebuild spam.
var _office_resize_pending: bool = false

# Previous stat values for animated counter rolls.
var _first_refresh: bool = true
var _prev_cash: float = 0.0
var _prev_revenue: float = 0.0
var _prev_burn: float = 0.0
var _prev_users: float = 0.0


func _ready() -> void:
	advance_btn.pressed.connect(_on_advance)
	people_btn.pressed.connect(_on_people)
	product_btn.pressed.connect(_on_product)
	finance_btn.pressed.connect(_on_finance)
	market_btn.pressed.connect(_on_market)
	menu_btn.pressed.connect(_on_menu)
	event_popup.event_resolved.connect(_on_event_resolved)

	_apply_plain_finance_titles()
	_wire_glossary_button(cash_title_btn, "cash_on_hand")
	_wire_glossary_button(revenue_title_btn, "quarterly_revenue")
	_wire_glossary_button(burn_title_btn, "quarterly_burn")
	_wire_glossary_button(runway_title_btn, "runway")
	if key_metric_title:
		key_metric_title.pressed.connect(_on_key_metric_info_pressed)

	GameState.quarter_advanced.connect(_refresh)
	GameState.game_over.connect(_on_game_over)
	GameState.game_won.connect(_on_game_won)
	GameState.event_triggered.connect(_on_event)
	GameState.save_error.connect(_on_save_error)
	GameState.feature_shipped.connect(_on_feature_shipped_dashboard)

	_headline_timer = Timer.new()
	_headline_timer.wait_time = HEADLINE_ROTATE_SECONDS
	_headline_timer.timeout.connect(_rotate_headline)
	add_child(_headline_timer)

	_build_delta_labels()
	_build_feature_banner()
	_build_turn_summary_panel()
	_build_next_action_label()
	_build_advance_hint_label()
	_build_advance_toast()
	_build_quarter_transition_fx()
	_build_hosting_status_label()
	_build_office_worker_layer()
	_build_finance_plain_label()
	_move_nav_to_top()
	_build_chip_hud()
	_build_passive_ticker()

	IdleEngine.passive_tick.connect(_on_passive_tick)
	IdleEngine.offline_income_ready.connect(_show_offline_summary)
	CurrencyManager.chips_changed.connect(_on_chips_changed)

	_refresh(GameState.current_quarter)
	UITouchHelper.harden_tree(self)
	Analytics.track_screen("dashboard")

	_build_dev_button()

	# Entrance animations on child elements (safe — never on self).
	AnimHelper.stagger_list(stats_grid, 0.04, 0.0, 18.0)
	AnimHelper.fade_in(event_log_container, 0.12, 0.20)

	# Start tutorial on first run (deferred so all nodes are fully laid out).
	TutorialManager.start_if_needed.call_deferred()


func _wire_glossary_button(btn: Button, glossary_key: String) -> void:
	if btn == null:
		return
	btn.pressed.connect(Glossary.show_term.bind(glossary_key))
	_set_glossary_tooltip(btn, glossary_key)


func _set_glossary_tooltip(btn: Control, glossary_key: String) -> void:
	if not Glossary.has_term(glossary_key):
		btn.tooltip_text = "Click for metric details."
		return
	var term: String = Glossary.get_term(glossary_key)
	var short_desc: String = Glossary.get_short(glossary_key)
	var tip: String = Glossary.get_tip(glossary_key)

	var first_line: String = term
	if first_line.is_empty():
		first_line = short_desc
	elif not short_desc.is_empty():
		first_line = "%s — %s" % [term, short_desc]

	var parts: Array[String] = []
	if not first_line.is_empty():
		parts.append(first_line)
	if not tip.is_empty():
		parts.append(tip)
	if parts.is_empty():
		return
	btn.tooltip_text = "\n".join(parts)


func _apply_plain_finance_titles() -> void:
	if cash_title_btn:
		cash_title_btn.text = "Cash (On Hand) ⓘ"
	if revenue_title_btn:
		revenue_title_btn.text = "Revenue (Qtr) ⓘ"
	if burn_title_btn:
		burn_title_btn.text = "Burn Rate (Qtr) ⓘ"
	if runway_title_btn:
		runway_title_btn.text = "Runway (Time Left) ⓘ"


func _exit_tree() -> void:
	_headline_timer.stop()
	if _transition_tween != null and is_instance_valid(_transition_tween):
		_transition_tween.kill()
	if _transition_sfx_player != null:
		_transition_sfx_player.stop()
	_safe_disconnect(GameState.quarter_advanced, _refresh)
	_safe_disconnect(GameState.game_over, _on_game_over)
	_safe_disconnect(GameState.game_won, _on_game_won)
	_safe_disconnect(GameState.event_triggered, _on_event)
	_safe_disconnect(GameState.save_error, _on_save_error)
	_safe_disconnect(GameState.feature_shipped, _on_feature_shipped_dashboard)
	if office_banner and office_banner.resized.is_connected(_refresh_office_worker_ambient):
		office_banner.resized.disconnect(_refresh_office_worker_ambient)


func _build_finance_plain_label() -> void:
	_finance_plain_label = Label.new()
	_finance_plain_label.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	_finance_plain_label.add_theme_color_override("font_color", Color(0.66, 0.74, 0.9))
	_finance_plain_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var vbox := quarter_label.get_parent().get_parent()
	if vbox == null:
		return
	vbox.add_child(_finance_plain_label)
	if stats_grid:
		vbox.move_child(_finance_plain_label, stats_grid.get_index() + 1)


func _build_delta_labels() -> void:
	# Insert small delta labels (e.g. "+$12K") below the main stat labels.
	# Each is parented to the same VBoxContainer as its stat value label.
	_cash_delta_label = _make_delta_label()
	_revenue_delta_label = _make_delta_label()
	_burn_delta_label = _make_delta_label()
	_insert_delta_after(cash_label, _cash_delta_label)
	_insert_delta_after(revenue_label, _revenue_delta_label)
	_insert_delta_after(burn_label, _burn_delta_label)


func _make_delta_label() -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	lbl.visible = false
	return lbl


func _insert_delta_after(stat_label: Label, delta_label: Label) -> void:
	var parent := stat_label.get_parent()
	if parent == null:
		return
	parent.add_child(delta_label)
	parent.move_child(delta_label, stat_label.get_index() + 1)


func _move_nav_to_top() -> void:
	# Move the navigation row (People / Product / Finances / Market) to sit
	# right after the header row, so it works like a proper top tab bar.
	var vbox := people_btn.get_parent().get_parent()  # NavRow -> VBox
	var nav_row: Node = people_btn.get_parent()       # NavRow itself
	if vbox == null or nav_row == null:
		return

	# Insert right after TopRow (index 0) — i.e. at index 1
	vbox.move_child(nav_row, 1)

	# Also style the nav buttons to look more like tabs
	for btn: Button in [people_btn, product_btn, finance_btn, market_btn]:
		btn.custom_minimum_size = Vector2(0, 46)
		btn.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)


func _build_quarter_transition_fx() -> void:
	if quarter_transition_tint == null:
		return
	quarter_transition_tint.visible = false
	quarter_transition_tint.modulate.a = 0.0

	_transition_sweep = ColorRect.new()
	_transition_sweep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_sweep.color = Color(0.70, 0.86, 1.0, 0.30)
	_transition_sweep.visible = false
	quarter_transition_tint.add_child(_transition_sweep)

	_transition_label = Label.new()
	_transition_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_transition_label.offset_left = -170.0
	_transition_label.offset_right = 170.0
	_transition_label.offset_top = -14.0
	_transition_label.offset_bottom = 14.0
	_transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_transition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_transition_label.add_theme_font_size_override("font_size", 17)
	_transition_label.add_theme_color_override("font_color", Color(0.90, 0.96, 1.0))
	_transition_label.visible = false
	quarter_transition_tint.add_child(_transition_label)

	_transition_sfx_player = AudioStreamPlayer.new()
	_transition_sfx_player.bus = "Master"
	add_child(_transition_sfx_player)
	_transition_whoosh_stream = _load_first_audio_stream(QUARTER_TRANSITION_WHOOSH_PATHS)
	_transition_ding_stream = _load_first_audio_stream(QUARTER_TRANSITION_DING_PATHS)


func _next_quarter_label_text() -> String:
	var next_year: int = GameState.current_year
	var next_quarter: int = GameState.current_quarter + 1
	if next_quarter > 4:
		next_quarter = 1
		next_year += 1
	return "Advancing to Year %d Q%d..." % [next_year, next_quarter]


func _last_closed_quarter_year() -> int:
	var report_year: int = GameState.current_year
	var report_quarter: int = GameState.current_quarter - 1
	if report_quarter < 1:
		report_quarter = 4
		report_year -= 1
	return maxi(1, report_year)


func _last_closed_quarter_number() -> int:
	var report_quarter: int = GameState.current_quarter - 1
	if report_quarter < 1:
		report_quarter = 4
	return report_quarter


func _load_first_audio_stream(paths: Array[String]) -> AudioStream:
	for path in paths:
		if not ResourceLoader.exists(path):
			continue
		var stream: AudioStream = ResourceLoader.load(path) as AudioStream
		if stream != null:
			return stream
	return null


func _play_transition_sfx(phase: String) -> void:
	if _transition_sfx_player == null:
		return
	var stream: AudioStream = null
	var volume_db: float = -7.0
	if phase == "start":
		stream = _transition_whoosh_stream
		volume_db = -6.0
	else:
		stream = _transition_ding_stream
		volume_db = -8.0

	if stream != null:
		_transition_sfx_player.stream = stream
		_transition_sfx_player.volume_db = volume_db
		_transition_sfx_player.pitch_scale = 1.0
		_transition_sfx_player.play()
		return

	# Fallback: synthesize a tiny transition tone when no assets exist yet.
	if phase == "start":
		_play_synth_transition_sfx(220.0, 0.16, 0.12, 8.0)
	else:
		_play_synth_transition_sfx(690.0, 0.12, 0.10, 12.5)


func _play_synth_transition_sfx(freq_hz: float, duration_s: float, amp: float, decay: float) -> void:
	if _transition_sfx_player == null:
		return
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 44_100.0
	generator.buffer_length = 0.30
	_transition_sfx_player.stream = generator
	_transition_sfx_player.volume_db = -5.0
	_transition_sfx_player.play()
	var playback: AudioStreamGeneratorPlayback = _transition_sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var samples: int = int(generator.mix_rate * duration_s)
	var safe_duration: float = maxf(0.001, duration_s)
	for i in samples:
		var t: float = float(i) / generator.mix_rate
		var env: float = exp(-decay * t)
		var pitch_glide: float = 1.0 + (0.18 * (1.0 - (t / safe_duration)))
		var wave: float = sin(TAU * (freq_hz * pitch_glide) * t)
		wave += sin(TAU * (freq_hz * 1.84) * t) * 0.22
		var sample: float = clampf(wave * env * amp, -1.0, 1.0)
		playback.push_frame(Vector2(sample, sample))


func _play_quarter_transition() -> float:
	if quarter_transition_tint == null:
		return 0.0
	if _transition_tween != null and is_instance_valid(_transition_tween):
		_transition_tween.kill()

	var viewport_size: Vector2 = get_viewport_rect().size
	var width: float = maxf(420.0, viewport_size.x)
	var height: float = maxf(240.0, viewport_size.y)
	var sweep_w: float = clampf(width * 0.34, 140.0, 420.0)
	quarter_transition_tint.visible = true
	quarter_transition_tint.modulate.a = 0.0

	if _transition_sweep != null:
		_transition_sweep.visible = true
		_transition_sweep.position = Vector2(-sweep_w, 0.0)
		_transition_sweep.size = Vector2(sweep_w, height)
		_transition_sweep.modulate.a = 0.0
	if _transition_label != null:
		_transition_label.visible = true
		_transition_label.text = _next_quarter_label_text()
		_transition_label.scale = Vector2(0.96, 0.96)
		_transition_label.modulate.a = 0.0

	_play_transition_sfx("start")

	# Subtle screen shake on quarter change — conveys "time moved forward."
	AnimHelper.screen_shake(get_tree(), 0.15, 0.18)

	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Phase 1: tint + label + sweep all animate in together.
	tw.tween_property(quarter_transition_tint, "modulate:a", 0.82, 0.10)
	if _transition_label != null:
		tw.parallel().tween_property(_transition_label, "modulate:a", 1.0, 0.08)
		# Disney overshoot: label pops in slightly larger then settles.
		tw.parallel().tween_property(_transition_label, "scale", Vector2(1.06, 1.06), 0.12) \
			.set_trans(Tween.TRANS_BACK)
	if _transition_sweep != null:
		tw.parallel().tween_property(_transition_sweep, "modulate:a", 0.38, 0.07)
		tw.parallel().tween_property(_transition_sweep, "position:x", width + sweep_w, 0.24) \
			.set_trans(Tween.TRANS_CUBIC)

	# Brief hold — let the player register the quarter label.
	tw.tween_interval(0.05)

	# Label settles to final scale during hold.
	if _transition_label != null:
		tw.parallel().tween_property(_transition_label, "scale", Vector2.ONE, 0.10)

	# Phase 2: everything fades out.
	tw.tween_property(quarter_transition_tint, "modulate:a", 0.0, 0.22)
	if _transition_label != null:
		tw.parallel().tween_property(_transition_label, "modulate:a", 0.0, 0.14)
	if _transition_sweep != null:
		tw.parallel().tween_property(_transition_sweep, "modulate:a", 0.0, 0.12)
	tw.tween_callback(func() -> void:
		if quarter_transition_tint:
			quarter_transition_tint.visible = false
		if _transition_sweep:
			_transition_sweep.visible = false
		if _transition_label:
			_transition_label.visible = false
	)
	_transition_tween = tw
	return 0.11


func _build_feature_banner() -> void:
	# A slim banner near the top of the event log area that shows when a
	# feature ships (for players who are on the dashboard when it happens).
	_feature_banner = Label.new()
	_feature_banner.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	_feature_banner.add_theme_color_override("font_color", Color(0.4, 0.95, 0.55))
	_feature_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feature_banner.visible = false
	var parent := event_log_container.get_parent()
	if parent:
		parent.add_child(_feature_banner)
		parent.move_child(_feature_banner, event_log_container.get_index())


func _build_turn_summary_panel() -> void:
	var vbox := quarter_label.get_parent().get_parent()
	if vbox == null:
		return

	_turn_summary_panel = PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.14, 0.2, 0.9)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	_turn_summary_panel.add_theme_stylebox_override("panel", panel_style)

	_turn_summary_label = Label.new()
	_turn_summary_label.add_theme_font_size_override("font_size", 12)
	_turn_summary_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.9))
	_turn_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_turn_summary_panel.add_child(_turn_summary_label)
	_turn_summary_panel.visible = false

	vbox.add_child(_turn_summary_panel)
	var status_row := economy_label.get_parent()
	vbox.move_child(_turn_summary_panel, status_row.get_index() + 1)


func _build_next_action_label() -> void:
	_next_action_label = Label.new()
	_next_action_label.add_theme_font_size_override("font_size", 12)
	_next_action_label.add_theme_color_override("font_color", Color(0.66, 0.8, 0.96))
	_next_action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var parent := advance_btn.get_parent()
	if parent:
		parent.add_child(_next_action_label)
		parent.move_child(_next_action_label, advance_btn.get_index())


func _build_advance_hint_label() -> void:
	_advance_hint_label = Label.new()
	_advance_hint_label.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	_advance_hint_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.35))
	_advance_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_advance_hint_label.visible = false
	var parent := advance_btn.get_parent()
	if parent:
		parent.add_child(_advance_hint_label)
		parent.move_child(_advance_hint_label, advance_btn.get_index() + 1)


func _build_advance_toast() -> void:
	_advance_toast_panel = PanelContainer.new()
	_advance_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_advance_toast_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_advance_toast_panel.offset_left = 60
	_advance_toast_panel.offset_right = -60
	_advance_toast_panel.offset_top = 8
	_advance_toast_panel.offset_bottom = 52
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.24, 0.38, 0.96)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	_advance_toast_panel.add_theme_stylebox_override("panel", panel_style)

	_advance_toast_label = Label.new()
	_advance_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_advance_toast_label.add_theme_font_size_override("font_size", 12)
	_advance_toast_label.add_theme_color_override("font_color", Color(0.9, 0.96, 1.0))
	_advance_toast_panel.add_child(_advance_toast_label)

	_advance_toast_panel.visible = false
	_advance_toast_panel.modulate.a = 0.0
	add_child(_advance_toast_panel)
	move_child(_advance_toast_panel, get_child_count() - 1)


func _build_hosting_status_label() -> void:
	_hosting_status_label = Label.new()
	_hosting_status_label.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	var status_row := economy_label.get_parent()
	if status_row:
		status_row.add_child(_hosting_status_label)


func _build_office_worker_layer() -> void:
	if office_banner == null:
		return
	_office_worker_layer = Control.new()
	_office_worker_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_office_worker_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	office_banner.add_child(_office_worker_layer)
	if not office_banner.resized.is_connected(_debounced_office_refresh):
		office_banner.resized.connect(_debounced_office_refresh)


func _refresh(_q: int) -> void:
	if GameState.company == null:
		return
	quarter_label.text = "Year %d, Q%d" % [GameState.current_year, GameState.current_quarter]
	company_label.text = "%s — %s" % [GameState.company.company_name, GameState.company.type_name_with_niche()]
	employees_label.text = "%d / %d" % [GameState.employees.size(), GameState.company.office_capacity()]

	# Animate key financial counters when values change; static set on first load.
	var new_cash: float = GameState.company.cash
	var new_revenue: float = GameState.financials.revenue
	var new_burn: float = GameState.financials.burn_rate
	var new_users: float = float(GameState.product.users)

	if _first_refresh:
		_first_refresh = false
		# First refresh — set text directly, no animation.
		cash_label.text = "$%s" % SceneLoader.format_money(new_cash)
		revenue_label.text = "$%s/qtr" % SceneLoader.format_money(new_revenue)
		burn_label.text = "$%s/qtr" % SceneLoader.format_money(new_burn)
		users_label.text = "%s users" % SceneLoader.format_number(int(new_users))
	else:
		AnimHelper.roll_money(cash_label, _prev_cash, new_cash, 0.45, "$")
		AnimHelper.roll_number(revenue_label, _prev_revenue, new_revenue, 0.45,
			func(v: float) -> String: return "$%s/qtr" % SceneLoader.format_money(v))
		AnimHelper.roll_number(burn_label, _prev_burn, new_burn, 0.45,
			func(v: float) -> String: return "$%s/qtr" % SceneLoader.format_money(v))
		AnimHelper.roll_number(users_label, _prev_users, new_users, 0.55,
			func(v: float) -> String: return "%s users" % SceneLoader.format_number(int(v)))

	_prev_cash = new_cash
	_prev_revenue = new_revenue
	_prev_burn = new_burn
	_prev_users = new_users

	var rw: float = GameState.financials.runway_quarters(GameState.company.cash)
	if rw == INF:
		runway_label.text = "Profitable"
	elif rw < 0:
		runway_label.text = "In debt"
	elif rw < 1.0:
		runway_label.text = "< 1 quarter"
	elif rw < 2.0:
		runway_label.text = "~1 quarter"
	else:
		runway_label.text = "~%d quarters" % roundi(rw)

	_colorize_health_indicators(rw)
	_refresh_deltas()
	_refresh_headlines()
	_refresh_ticker_strip()
	_refresh_key_metric()
	_refresh_economy()
	_refresh_energy()
	_refresh_hosting_status()
	_refresh_team()
	_refresh_office_banner()
	_refresh_turn_summary()
	_refresh_next_action_hint()
	_refresh_events_heading()
	_update_advance_button_label()
	_refresh_finance_plain_hint()


func _refresh_deltas() -> void:
	# Use the last two history snapshots for quarter-over-quarter changes.
	var hist := GameState.history
	if hist.size() < 2:
		if _cash_delta_label:
			_cash_delta_label.visible = false
		if _revenue_delta_label:
			_revenue_delta_label.visible = false
		if _burn_delta_label:
			_burn_delta_label.visible = false
		return

	var prev: Dictionary = hist[-2]
	var curr: Dictionary = hist[-1]

	_apply_delta(_cash_delta_label,
		curr.get("cash", 0.0) - prev.get("cash", 0.0), true)
	_apply_delta(_revenue_delta_label,
		curr.get("revenue", 0.0) - prev.get("revenue", 0.0), true)
	_apply_delta(_burn_delta_label,
		curr.get("burn_rate", 0.0) - prev.get("burn_rate", 0.0), false)


func _apply_delta(lbl: Label, delta: float, higher_is_good: bool) -> void:
	if lbl == null:
		return
	if absf(delta) < 1.0:
		lbl.visible = false
		return
	lbl.visible = true
	var sign_str := "+" if delta >= 0 else ""
	lbl.text = "%s$%s vs last Q" % [sign_str, SceneLoader.format_money(delta)]
	var positive: bool = delta > 0
	var good: bool = positive == higher_is_good
	if good:
		lbl.add_theme_color_override("font_color", Color(0.35, 0.85, 0.45))
	else:
		lbl.add_theme_color_override("font_color", Color(0.9, 0.4, 0.35))


## Tint stat labels based on company health — instant visual feedback.
func _colorize_health_indicators(runway_q: float) -> void:
	# Cash coloring: green when healthy, gold when cautious, red when critical.
	var cash: float = GameState.company.cash
	var burn: float = maxf(GameState.financials.burn_rate, 1.0)
	var comfort_cash: float = burn * 6.0  # 6 quarters of runway = comfortable

	if cash <= 0:
		cash_label.add_theme_color_override("font_color", ThemeManager.C_RED)
	elif cash < burn * 2.0:
		cash_label.add_theme_color_override("font_color", ThemeManager.C_RED)
	elif cash < comfort_cash:
		cash_label.add_theme_color_override("font_color", ThemeManager.C_GOLD)
	else:
		cash_label.add_theme_color_override("font_color", ThemeManager.C_GREEN)

	# Runway coloring.
	if runway_q == INF:
		runway_label.add_theme_color_override("font_color", ThemeManager.C_GREEN)
	elif runway_q < 0:
		runway_label.add_theme_color_override("font_color", ThemeManager.C_RED)
	elif runway_q < 2.0:
		runway_label.add_theme_color_override("font_color", ThemeManager.C_RED)
	elif runway_q < 4.0:
		runway_label.add_theme_color_override("font_color", ThemeManager.C_GOLD)
	else:
		runway_label.add_theme_color_override("font_color", ThemeManager.C_GREEN)

	# User count coloring: based on quarter-over-quarter growth trend.
	var hist: Array = GameState.history
	if hist.size() >= 2:
		var prev_users: int = int(hist[-2].get("users", 0))
		var curr_users: int = GameState.product.users
		if curr_users > prev_users:
			users_label.add_theme_color_override("font_color", ThemeManager.C_GREEN)
		elif curr_users < prev_users:
			users_label.add_theme_color_override("font_color", ThemeManager.C_RED)
		else:
			users_label.add_theme_color_override("font_color", ThemeManager.C_TEXT)
	else:
		users_label.add_theme_color_override("font_color", ThemeManager.C_TEXT)

	# Revenue vs burn: green if profitable, gold if close, red if heavy losses.
	var revenue: float = GameState.financials.revenue
	if revenue >= burn:
		revenue_label.add_theme_color_override("font_color", ThemeManager.C_GREEN)
	elif revenue >= burn * 0.5:
		revenue_label.add_theme_color_override("font_color", ThemeManager.C_GOLD)
	elif revenue > 0:
		revenue_label.add_theme_color_override("font_color", ThemeManager.C_TEXT)
	else:
		revenue_label.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)

	# Burn rate: red when high relative to cash, normal otherwise.
	if burn > cash * 0.5 and cash > 0:
		burn_label.add_theme_color_override("font_color", ThemeManager.C_RED)
	elif burn > cash * 0.25 and cash > 0:
		burn_label.add_theme_color_override("font_color", ThemeManager.C_GOLD)
	else:
		burn_label.add_theme_color_override("font_color", ThemeManager.C_TEXT)


func _refresh_turn_summary() -> void:
	if _turn_summary_panel == null or _turn_summary_label == null:
		return
	var hist: Array = GameState.history
	if hist.size() < 2:
		_turn_summary_panel.visible = false
		return

	var prev: Dictionary = _as_dict(hist[hist.size() - 2])
	var curr: Dictionary = _as_dict(hist[hist.size() - 1])
	var cash_delta: float = float(curr.get("cash", 0.0)) - float(prev.get("cash", 0.0))
	var rev_delta: float = float(curr.get("revenue", 0.0)) - float(prev.get("revenue", 0.0))
	var users_delta: int = int(curr.get("users", 0)) - int(prev.get("users", 0))
	var val_delta: float = float(curr.get("valuation", 0.0)) - float(prev.get("valuation", 0.0))

	var score: int = 0
	if cash_delta > 0.0:
		score += 1
	elif cash_delta < 0.0:
		score -= 1
	if rev_delta > 0.0:
		score += 1
	elif rev_delta < 0.0:
		score -= 1
	if users_delta > 0:
		score += 1
	elif users_delta < 0:
		score -= 1
	if val_delta > 0.0:
		score += 1
	elif val_delta < 0.0:
		score -= 1

	var mood: String = "Last quarter: mixed"
	if score >= 3:
		mood = "Last quarter: strong momentum"
	elif score <= -3:
		mood = "Last quarter: rough patch"

	_turn_summary_label.text = "%s  ·  Cash %s  ·  Rev %s  ·  Users %s  ·  Valuation %s" % [
		mood,
		_delta_money_text(cash_delta),
		_delta_money_text(rev_delta),
		_delta_int_text(users_delta),
		_delta_money_text(val_delta),
	]
	if score >= 2:
		_turn_summary_label.add_theme_color_override("font_color", Color(0.55, 0.9, 0.55))
	elif score <= -2:
		_turn_summary_label.add_theme_color_override("font_color", Color(0.95, 0.58, 0.5))
	else:
		_turn_summary_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.9))
	_turn_summary_panel.visible = true


func _refresh_next_action_hint() -> void:
	if _next_action_label == null or GameState.company == null or GameState.product == null:
		return

	var hint := ""
	if GameState.employees.is_empty():
		hint = "Next best action: hire your first teammate in People."
	elif _features_assigned_count() == 0:
		hint = "Next best action: assign at least 1 teammate to Features in People."
	elif GameState.product.get_target_feature(GameState.company.type).is_empty():
		hint = "Next best action: pick a feature in Product to keep progress moving."
	else:
		var stage: String = _responsibility_stage()
		var missing_lanes: Array[String] = []
		if stage != "early":
			if _assignment_count(EmployeeData.Assignment.BUGS) == 0:
				missing_lanes.append("Bug Fixes")
			if _assignment_count(EmployeeData.Assignment.TECH_DEBT) == 0:
				missing_lanes.append("Tech Debt")
			if _assignment_count(EmployeeData.Assignment.INFRA) == 0:
				missing_lanes.append("Infrastructure")
			if _assignment_count(EmployeeData.Assignment.RND) == 0:
				missing_lanes.append("R&D")
			if not missing_lanes.is_empty():
				hint = "Next best action: as you scale, assign specialists to %s." % ", ".join(missing_lanes)
				_next_action_label.text = hint
				return

		var rw: float = GameState.financials.runway_quarters(GameState.company.cash)
		var world_brief := GameState.active_world_event_brief()
		var world_cost_mult := GameState.world_event_mult("cost_mult", 1.0)
		var world_fundraise_mult := GameState.world_event_mult("fundraise_amount_mult", 1.0)
		var peak_util: float = maxf(
			GameState.company.hosting_util_web,
			maxf(GameState.company.hosting_util_cache, GameState.company.hosting_util_data)
		)
		var hosting_upgrade_total: int = GameState.company.hosting_upgrade_web_level \
			+ GameState.company.hosting_upgrade_cache_level \
			+ GameState.company.hosting_upgrade_data_level
		if peak_util > 1.05 and hosting_upgrade_total < 2:
			hint = "Next best action: open Logistics and buy a lane capacity upgrade before demand spikes."
		elif not world_brief.is_empty() and world_fundraise_mult < 0.95 and rw < 4.0:
			hint = "Next best action: capital markets are tighter (%s) — raise earlier and protect runway." % world_brief
		elif not world_brief.is_empty() and world_cost_mult > 1.06 and rw < 5.0:
			hint = "Next best action: costs are elevated (%s) — trim spend or add cash buffer." % world_brief
		elif GameState.company.hosting_reliability < 94.0:
			hint = "Next best action: hosting is unstable — add Infra staffing or switch to a safer hosting plan."
		elif rw < 1.0:
			hint = "Next best action: runway is critical — open Finances and raise now."
		elif rw < 3.0:
			hint = "Next best action: runway is tight — plan fundraising soon."
		elif GameState.product.feature_count() == 0:
			hint = "Next best action: keep shipping features to unlock user growth."
		else:
			hint = "Next best action: continue shipping and watch churn + runway."

	_next_action_label.text = hint


func _refresh_hosting_status() -> void:
	if _hosting_status_label == null or GameState.company == null:
		return
	var c: CompanyData = GameState.company
	var max_util: float = maxf(c.hosting_util_web, maxf(c.hosting_util_cache, c.hosting_util_data))
	var upgrades_total: int = c.hosting_upgrade_web_level + c.hosting_upgrade_cache_level + c.hosting_upgrade_data_level
	var workload_profile: String = c.hosting_workload_profile.strip_edges()
	if workload_profile.is_empty():
		workload_profile = "General Cloud"
	var pressure: float = c.hosting_data_center_pressure
	_hosting_status_label.text = "Hosting: %s · %.1f%% reliability · peak %.0f%% load · %s" % [
		c.hosting_plan_name(),
		c.hosting_reliability,
		max_util * 100.0,
		workload_profile,
	]
	if pressure >= 2.2:
		_hosting_status_label.text += " · data-center pressure high"
	elif pressure >= 1.25:
		_hosting_status_label.text += " · scaling pressure rising"
	if upgrades_total > 0 or c.hosting_optimization_level > 0:
		_hosting_status_label.text += " · upgrades %d · opt L%d" % [upgrades_total, c.hosting_optimization_level]
	if c.hosting_reliability < 93.0:
		_hosting_status_label.add_theme_color_override("font_color", Color(0.95, 0.50, 0.42))
	elif pressure >= 2.2:
		_hosting_status_label.add_theme_color_override("font_color", Color(0.95, 0.72, 0.42))
	elif c.hosting_reliability < 97.0 or pressure >= 1.25:
		_hosting_status_label.add_theme_color_override("font_color", Color(0.95, 0.80, 0.40))
	else:
		_hosting_status_label.add_theme_color_override("font_color", Color(0.55, 0.88, 0.56))


func _refresh_finance_plain_hint() -> void:
	if _finance_plain_label == null:
		return
	var net_q: float = GameState.financials.revenue - GameState.financials.burn_rate
	if net_q >= 0.0:
		_finance_plain_label.text = "Operator read: cashflow positive by about $%s per quarter (revenue > burn)." % [
			SceneLoader.format_money(net_q)
		]
		_finance_plain_label.add_theme_color_override("font_color", Color(0.56, 0.88, 0.56))
		return

	var shortfall: float = absf(net_q)
	var rw: float = GameState.financials.runway_quarters(GameState.company.cash)
	if rw == INF:
		_finance_plain_label.text = "Operator read: cashflow is currently stable."
	elif rw < 1.0:
		_finance_plain_label.text = "Operator read: cashflow negative by about $%s/qtr and runway is critical." % SceneLoader.format_money(shortfall)
	else:
		_finance_plain_label.text = "Operator read: cashflow negative by about $%s/qtr; runway is around %d quarter%s." % [
			SceneLoader.format_money(shortfall),
			maxi(1, roundi(rw)),
			"s" if roundi(rw) != 1 else "",
		]
	_finance_plain_label.add_theme_color_override("font_color", Color(0.95, 0.74, 0.46))


func _refresh_events_heading() -> void:
	if events_label == null:
		return
	var count: int = event_log_container.get_child_count()
	events_label.text = "This Quarter · %d event%s" % [count, "s" if count != 1 else ""]


func _update_advance_button_label() -> void:
	if advance_btn == null:
		return
	if not GameState.is_game_active:
		advance_btn.text = "Run Ended — Return to Menu"
		return
	if AdManager.is_game_locked():
		advance_btn.text = "Unlock Full Game to Continue"
		return
	if advance_btn.disabled and _pending_events.size() > 0:
		advance_btn.text = "Resolve Events to Continue"
		return
	if advance_btn.disabled:
		advance_btn.text = "Advancing..."
		return
	var next_year: int = GameState.current_year
	var next_quarter: int = GameState.current_quarter + 1
	if next_quarter > 4:
		next_quarter = 1
		next_year += 1
	advance_btn.text = "Advance to Y%d Q%d →" % [next_year, next_quarter]


func _show_advance_toast() -> void:
	if _advance_toast_panel == null or _advance_toast_label == null:
		return
	var hist: Array = GameState.history
	var cash_delta: float = 0.0
	var users_delta: int = 0
	if hist.size() >= 2:
		var prev: Dictionary = _as_dict(hist[hist.size() - 2])
		var curr: Dictionary = _as_dict(hist[hist.size() - 1])
		cash_delta = float(curr.get("cash", 0.0)) - float(prev.get("cash", 0.0))
		users_delta = int(curr.get("users", 0)) - int(prev.get("users", 0))

	_advance_toast_label.text = "Now in Year %d Q%d  ·  Cash %s  ·  Users %s" % [
		GameState.current_year,
		GameState.current_quarter,
		_delta_money_text(cash_delta),
		_delta_int_text(users_delta),
	]
	_advance_toast_panel.visible = true
	_advance_toast_panel.modulate.a = 0.0
	_advance_toast_panel.scale = Vector2(0.97, 0.97)
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_advance_toast_panel, "modulate:a", 1.0, 0.16)
	tw.parallel().tween_property(_advance_toast_panel, "scale", Vector2.ONE, 0.2)
	tw.tween_interval(2.1)
	tw.tween_property(_advance_toast_panel, "modulate:a", 0.0, 0.32)
	tw.tween_callback(func() -> void:
		if _advance_toast_panel:
			_advance_toast_panel.visible = false
	)


func _show_quarter_juice() -> void:
	var hist: Array = GameState.history
	if hist.size() < 2:
		return
	var prev: Dictionary = _as_dict(hist[hist.size() - 2])
	var curr: Dictionary = _as_dict(hist[hist.size() - 1])
	var cash_delta: float = float(curr.get("cash", 0.0)) - float(prev.get("cash", 0.0))
	var users_delta: int = int(curr.get("users", 0)) - int(prev.get("users", 0))

	# Floating money delta near cash display.
	if cash_label != null and absf(cash_delta) >= 100.0:
		AnimHelper.float_money(cash_label, cash_delta)

	# Floating users delta near the key metric area.
	if key_metric_label != null and users_delta != 0:
		AnimHelper.float_users(key_metric_label, users_delta)

	# Screen shake on significant cash drops (losing > $20K) or big fundraise (gaining > $100K).
	if cash_delta < -20_000.0:
		AnimHelper.screen_shake(get_tree(), 0.3, 0.3)
		AnimHelper.haptic(&"medium")
	elif cash_delta > 100_000.0:
		AnimHelper.screen_shake(get_tree(), 0.2, 0.25)
		AnimHelper.haptic(&"medium")
		SfxPlayer.play("cash_gain")
	elif cash_delta > 0:
		AnimHelper.haptic(&"light")

	# Medium haptic on quarter advance.
	AnimHelper.haptic(&"medium")


func _delta_money_text(delta: float) -> String:
	if absf(delta) < 1.0:
		return "$0"
	var sign := "+" if delta > 0.0 else "-"
	return "%s$%s" % [sign, SceneLoader.format_money(absf(delta))]


func _delta_int_text(delta: int) -> String:
	if delta == 0:
		return "0"
	var sign := "+" if delta > 0 else "-"
	return "%s%s" % [sign, SceneLoader.format_number(absi(delta))]


func _set_advance_hint(text: String, color: Color = Color(0.9, 0.7, 0.35)) -> void:
	if _advance_hint_label == null:
		return
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		_advance_hint_label.visible = false
		return
	_advance_hint_label.visible = true
	_advance_hint_label.text = trimmed
	_advance_hint_label.add_theme_color_override("font_color", color)


func _features_assigned_count() -> int:
	var count := 0
	for emp: EmployeeData in GameState.employees:
		if emp.assignment == EmployeeData.Assignment.FEATURES:
			count += 1
	return count


func _assignment_count(target: EmployeeData.Assignment) -> int:
	var count := 0
	for emp: EmployeeData in GameState.employees:
		if emp.assignment == target:
			count += 1
	return count


func _responsibility_stage() -> String:
	return SimulationEngine.responsibility_stage(GameState)


func _as_dict(v: Variant) -> Dictionary:
	if v is Dictionary:
		return v
	return {}


func _refresh_headlines() -> void:
	_headlines = HeadlineEngine.generate_headlines(GameState, 5)
	_headline_index = 0
	_headline_timer.stop()
	if _headlines.is_empty():
		headline_label.visible = false
		return
	headline_label.visible = true
	headline_label.modulate.a = 1.0
	headline_label.text = _headlines[0]
	if _headlines.size() > 1:
		_headline_timer.start()


func _rotate_headline() -> void:
	if _headlines.is_empty():
		return
	var tw := create_tween()
	tw.tween_property(headline_label, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func():
		_headline_index = (_headline_index + 1) % _headlines.size()
		headline_label.text = _headlines[_headline_index]
	)
	tw.tween_property(headline_label, "modulate:a", 1.0, 0.3)


func _refresh_ticker_strip() -> void:
	if GameState.company == null:
		ticker_strip.visible = false
		return
	var val: float = GameState.company.valuation
	var parts: Array[String] = []
	parts.append("$%s  %s" % [GameState.company.company_name.to_upper().replace(" ", ""), SceneLoader.format_money(val)])
	if _prev_valuation > 0.0 and val != _prev_valuation:
		var pct: float = ((val - _prev_valuation) / _prev_valuation) * 100.0
		if pct > 0:
			parts[0] += "  ▲%.1f%%" % pct
		else:
			parts[0] += "  ▼%.1f%%" % absf(pct)
	_prev_valuation = val

	match GameState.market.economy_state:
		MarketData.EconomyState.BULL:
			parts.append("MKTS ▲")
		MarketData.EconomyState.BEAR:
			parts.append("MKTS ▼")
		_:
			parts.append("MKTS —")

	if GameState.financials.revenue > 0:
		parts.append("REV %s" % SceneLoader.format_money(GameState.financials.revenue))

	ticker_strip.text = "    ".join(parts)
	ticker_strip.visible = true


func _refresh_key_metric() -> void:
	var p: ProductData = GameState.product
	match GameState.company.type:
		CompanyData.CompanyType.SAAS:
			key_metric_title.text = "MRR ⓘ"
			_set_key_metric_glossary("mrr")
			var mrr: float = GameState.financials.revenue / 3.0
			key_metric_label.text = "$%s" % SceneLoader.format_money(mrr)
		CompanyData.CompanyType.CONSUMER:
			key_metric_title.text = "DAU / MAU ⓘ"
			_set_key_metric_glossary("dau_mau")
			var mau: int = maxi(1, p.users)
			var ratio: float = float(p.dau) / float(mau)
			key_metric_label.text = "%.0f%%" % (ratio * 100)
		CompanyData.CompanyType.MARKETPLACE:
			key_metric_title.text = "GMV / Q ⓘ"
			_set_key_metric_glossary("gmv")
			var gmv: float = p.users * 50.0 * 3.0
			key_metric_label.text = "$%s" % SceneLoader.format_money(gmv)
		CompanyData.CompanyType.DEV_TOOLS:
			key_metric_title.text = "API Calls / Q ⓘ"
			_set_key_metric_glossary("api_calls")
			var calls: float = p.users * 1000.0 * 3.0
			key_metric_label.text = "%s" % SceneLoader.format_number(roundi(calls))
		_:
			key_metric_title.text = "Valuation ⓘ"
			_set_key_metric_glossary("valuation")
			key_metric_label.text = "$%s" % SceneLoader.format_money(GameState.company.valuation)


func _set_key_metric_glossary(glossary_key: String) -> void:
	_key_metric_glossary_key = glossary_key.strip_edges()
	_set_glossary_tooltip(key_metric_title, _key_metric_glossary_key)


func _on_key_metric_info_pressed() -> void:
	if _key_metric_glossary_key.is_empty():
		return
	Glossary.show_term(_key_metric_glossary_key)


func _refresh_economy() -> void:
	var market_text := "Market: Neutral"
	match GameState.market.economy_state:
		MarketData.EconomyState.BULL:
			market_text = "Market: Bull"
		MarketData.EconomyState.BEAR:
			market_text = "Market: Bear"

	var world_text := GameState.active_world_event_brief()
	if world_text.is_empty():
		economy_label.text = market_text
		economy_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.9))
	else:
		economy_label.text = "%s  ·  World: %s" % [market_text, world_text]
		var growth_mult := GameState.world_event_mult("growth_mult", 1.0)
		var cost_mult := GameState.world_event_mult("cost_mult", 1.0)
		if growth_mult < 0.97 or cost_mult > 1.03:
			economy_label.add_theme_color_override("font_color", Color(0.96, 0.72, 0.45))
		elif growth_mult > 1.03 and cost_mult <= 1.03:
			economy_label.add_theme_color_override("font_color", Color(0.58, 0.88, 0.56))
		else:
			economy_label.add_theme_color_override("font_color", Color(0.62, 0.82, 0.95))

	# Economy mood lighting — subtle colored vignette for market atmosphere.
	# Bull = warm green tint, Bear = cool red tint, Neutral = remove.
	if _economy_vignette and is_instance_valid(_economy_vignette):
		AnimHelper.remove_mood_vignette(_economy_vignette)
		_economy_vignette = null
	match GameState.market.economy_state:
		MarketData.EconomyState.BULL:
			_economy_vignette = AnimHelper.mood_vignette(self, Color(0.15, 0.55, 0.25), 0.06)
		MarketData.EconomyState.BEAR:
			_economy_vignette = AnimHelper.mood_vignette(self, Color(0.55, 0.12, 0.12), 0.08)


func _refresh_energy() -> void:
	var e: int = GameState.founder_energy
	var desc: String
	if e >= 80:
		desc = "Fresh"
	elif e >= 60:
		desc = "Steady"
	elif e >= 40:
		desc = "Tired"
	elif e >= 20:
		desc = "Exhausted"
	else:
		desc = "Burning out!"
	energy_label.text = "Energy: %d%% (%s)" % [e, desc]


func _on_feature_shipped_dashboard(feature_name: String, quality: int) -> void:
	if _feature_banner == null:
		return
	var q_word := "great" if quality >= 70 else ("decent" if quality >= 45 else "rough")
	_feature_banner.text = "Feature shipped: %s  (%s quality, %d/100) — check Product for details" % [feature_name, q_word, quality]
	_feature_banner.modulate.a = 0.0
	_feature_banner.visible = true

	# Celebration proportional to quality — Pixar's "staging" principle.
	if quality >= 70:
		# High quality: screen flash + confetti burst + strong haptic.
		AnimHelper.screen_flash(self, Color(0.3, 1.0, 0.5, 0.25), 0.35)
		AnimHelper.confetti_burst(self, Vector2(360, 300), [
			ThemeManager.C_GREEN, ThemeManager.C_GOLD, ThemeManager.C_BLUE,
		], 30, 200.0, 1.8)
		AnimHelper.haptic(&"heavy")
		SfxPlayer.play("feature_ship")
	elif quality >= 45:
		# Decent: small flash + medium haptic.
		AnimHelper.screen_flash(self, Color(0.3, 0.8, 0.5, 0.15), 0.25)
		AnimHelper.haptic(&"medium")
		SfxPlayer.play("feature_ship")
	else:
		# Rough: just the banner, light haptic.
		AnimHelper.haptic(&"light")

	# Banner entrance: slide in with spring overshoot.
	AnimHelper.slide_in(_feature_banner, Vector2(0, -16), 0.0, 0.22)
	var tw := create_tween()
	tw.tween_interval(5.0)
	tw.tween_property(_feature_banner, "modulate:a", 0.0, 0.8)
	tw.tween_callback(func() -> void: _feature_banner.visible = false)


func _on_event(event: EventData) -> void:
	_pending_events.append(event)

	var label := Label.new()
	label.text = "• %s" % event.title
	label.add_theme_font_size_override("font_size", 14)
	while event_log_container.get_child_count() >= MAX_VISIBLE_EVENTS:
		var oldest := event_log_container.get_child(0)
		event_log_container.remove_child(oldest)
		oldest.queue_free()
	event_log_container.add_child(label)
	_refresh_events_heading()
	_set_advance_hint(
		"Resolve %d pending event%s before the next quarter." % [
			_pending_events.size(),
			"s" if _pending_events.size() != 1 else "",
		],
		Color(0.95, 0.75, 0.4)
	)
	_update_advance_button_label()


func _on_advance() -> void:
	if not GameState.is_game_active:
		advance_btn.disabled = true
		_set_advance_hint("This run has ended. Return to menu to start or load a game.", Color(0.95, 0.55, 0.45))
		_update_advance_button_label()
		return

	# Free-tier gate: after FREE_QUARTER_LIMIT quarters the player must unlock.
	if AdManager.is_game_locked():
		AdManager.show_paywall(
			# on_unlock: re-enable the button so the player can continue immediately.
			func() -> void:
				advance_btn.disabled = false
				_set_advance_hint("Unlocked. You can continue the run.", Color(0.55, 0.88, 0.55))
				_update_advance_button_label(),
			# on_cancel: just re-enable the button so they can try again later.
			func() -> void:
				advance_btn.disabled = false
				_set_advance_hint("Unlock required to continue past the free limit.", Color(0.95, 0.55, 0.45))
				_update_advance_button_label(),
		)
		advance_btn.disabled = true
		_set_advance_hint("Unlock the full game to continue this run.", Color(0.95, 0.55, 0.45))
		_update_advance_button_label()
		return

	advance_btn.disabled = true
	_set_advance_hint("Simulating quarter...", Color(0.6, 0.78, 0.95))
	_update_advance_button_label()
	var transition_hold: float = _play_quarter_transition()
	if transition_hold > 0.0:
		await get_tree().create_timer(transition_hold).timeout
	SceneLoader.free_children(event_log_container)
	_pending_events.clear()
	_refresh_events_heading()
	Analytics.track_quarter_advanced(GameState.current_year, GameState.current_quarter)
	var prev_year: int = GameState.current_year
	var prev_quarter: int = GameState.current_quarter
	var was_profitable: bool = GameState.financials != null and GameState.financials.revenue > GameState.financials.burn_rate
	GameState.advance_quarter()
	# Deposit passive income and stamp timestamp before checking if we advanced.
	IdleEngine.deposit_pending_income()
	IdleEngine.stamp_active()
	CurrencyManager.on_quarter_completed(was_profitable)
	var did_advance: bool = (GameState.current_year != prev_year) or (GameState.current_quarter != prev_quarter)
	if not did_advance:
		advance_btn.disabled = false
		if not GameState.is_game_active:
			_set_advance_hint("This run has ended. Return to menu to start or load a game.", Color(0.95, 0.55, 0.45))
		else:
			_set_advance_hint("Quarter did not advance. Try returning to menu and reloading this save.", Color(0.95, 0.55, 0.45))
		_update_advance_button_label()
		return
	_play_transition_sfx("resolve")
	_show_advance_toast()
	_show_quarter_juice()
	Analytics.track_revenue(GameState.financials.revenue)

	_show_quarterly_report()

	AdManager.show_ad("interstitial_quarter_end")

	if not _pending_events.is_empty():
		advance_btn.disabled = true
		_set_advance_hint(
			"Resolve %d pending event%s before the next quarter." % [
				_pending_events.size(),
				"s" if _pending_events.size() != 1 else "",
			],
			Color(0.95, 0.75, 0.4)
		)
		_update_advance_button_label()
		_show_next_event()
	else:
		advance_btn.disabled = false
		_set_advance_hint("Tip: review your report, then advance when ready.", Color(0.7, 0.82, 0.95))
		_update_advance_button_label()


func _show_next_event() -> void:
	if _pending_events.is_empty():
		advance_btn.disabled = false
		_set_advance_hint("Tip: review your report, then advance when ready.", Color(0.7, 0.82, 0.95))
		_update_advance_button_label()
		_refresh(GameState.current_quarter)
		return
	var ev: EventData = _pending_events[0]
	event_popup.show_event(ev)


func _on_event_resolved(_event: EventData, _choice_index: int) -> void:
	Analytics.track_event_choice(_event.id, _choice_index)
	if not _pending_events.is_empty():
		_pending_events.remove_at(0)
	_refresh_events_heading()
	if _pending_events.is_empty():
		_set_advance_hint("All events resolved. You can advance again.", Color(0.55, 0.88, 0.55))
	else:
		_set_advance_hint(
			"Resolve %d pending event%s before the next quarter." % [
				_pending_events.size(),
				"s" if _pending_events.size() != 1 else "",
			],
			Color(0.95, 0.75, 0.4)
		)
	_update_advance_button_label()
	_show_next_event()


func _on_game_over(reason: String) -> void:
	Analytics.track_game_over(reason, GameState.current_year, GameState.current_quarter)
	GameState.set_meta("game_over_reason", reason)
	SceneLoader.goto_scene("res://src/ui/game_over/game_over_screen.tscn")


func _on_game_won(win_type: String) -> void:
	GameState.register_achieved_win(win_type)
	GameState.set_meta("win_type", win_type)
	SceneLoader.goto_scene("res://src/ui/victory/victory_screen.tscn")


func _refresh_office_banner() -> void:
	if office_banner == null or GameState.company == null:
		return
	var level: int = clampi(GameState.company.office_level, 0, OFFICE_BANNER_PATHS.size() - 1)
	var path: String = OFFICE_BANNER_PATHS[level]
	if office_banner.texture == null or not office_banner.texture.resource_path.ends_with(OFFICE_BANNER_PATHS[level].get_file()):
		var tex: Texture2D = ResourceLoader.load(path) as Texture2D
		if tex:
			office_banner.texture = tex
	_refresh_office_worker_ambient()


func _debounced_office_refresh() -> void:
	# Coalesce rapid resize events into a single rebuild (saves battery on layout shifts).
	if _office_resize_pending:
		return
	_office_resize_pending = true
	get_tree().create_timer(0.05).timeout.connect(func() -> void:
		_office_resize_pending = false
		_refresh_office_worker_ambient()
	)


func _refresh_office_worker_ambient() -> void:
	if _office_worker_layer == null or GameState.company == null:
		return
	SceneLoader.free_children(_office_worker_layer)
	if GameState.employees.is_empty():
		return

	var width: float = maxf(120.0, office_banner.size.x)
	var height: float = maxf(80.0, office_banner.size.y)
	var office_level: int = clampi(GameState.company.office_level, 0, 3)
	var style: Dictionary = OFFICE_WORKSPACE_STYLES.get(office_level, OFFICE_WORKSPACE_STYLES[0])
	var accent: Color = _office_accent_color()

	var tint := ColorRect.new()
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint.color = Color(accent.r, accent.g, accent.b, clampf(0.10 + float(office_level) * 0.02, 0.08, 0.18))
	_office_worker_layer.add_child(tint)

	# --- Office decorations (furniture makes the scene feel alive) ---
	_add_office_decorations(width, height, office_level, accent)

	var slots: Array[Vector2] = _build_desk_slots(style, width, height)
	var total_visible: int = mini(GameState.employees.size(), slots.size())
	var desk_w: float = float(style.get("desk_w", 16.0))
	var desk_h: float = float(style.get("desk_h", 4.0))
	for i in total_visible:
		var emp: EmployeeData = GameState.employees[i]
		var slot: Vector2 = slots[i]

		# Chair behind the desk (small dark rect, gives depth).
		var chair := ColorRect.new()
		chair.custom_minimum_size = Vector2(8, 6)
		chair.size = Vector2(8, 6)
		chair.color = Color(0.20, 0.18, 0.24, 0.75)
		chair.position = Vector2(slot.x - 4.0, slot.y - 4.0)
		_office_worker_layer.add_child(chair)

		# Desk surface.
		var desk := ColorRect.new()
		desk.custom_minimum_size = Vector2(desk_w, desk_h)
		desk.size = Vector2(desk_w, desk_h)
		desk.color = Color(0.18, 0.22, 0.3, 0.9).lerp(accent, 0.18)
		desk.position = Vector2(slot.x - (desk_w * 0.5), slot.y)
		_office_worker_layer.add_child(desk)

		# Monitor body (dark frame).
		var monitor := ColorRect.new()
		monitor.custom_minimum_size = Vector2(6, 4)
		monitor.size = Vector2(6, 4)
		monitor.color = Color(0.12, 0.14, 0.20, 0.95)
		monitor.position = Vector2(slot.x + (desk_w * 0.22), slot.y - 4.0)
		_office_worker_layer.add_child(monitor)

		# Monitor screen glow — color matches assignment, pulses gently.
		var screen := ColorRect.new()
		screen.custom_minimum_size = Vector2(4, 2)
		screen.size = Vector2(4, 2)
		var screen_color: Color = PixelCharacter.SHIRT_COLORS.get(emp.assignment, Color(0.4, 0.5, 0.6))
		screen.color = Color(screen_color.r, screen_color.g, screen_color.b, 0.65)
		screen.position = Vector2(slot.x + (desk_w * 0.22) + 1.0, slot.y - 3.0)
		_office_worker_layer.add_child(screen)
		# Gentle screen glow pulse — the room feels alive.
		var scr_tw := screen.create_tween().set_loops()
		scr_tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		scr_tw.tween_interval(float(hash(emp.employee_uid) % 7) * 0.1)
		scr_tw.tween_property(screen, "color:a", 0.85, 1.2)
		scr_tw.tween_property(screen, "color:a", 0.50, 1.2)

		# Coffee mug for ~30% of workers (adds whimsy).
		if hash(emp.employee_uid) % 3 == 0:
			var mug := ColorRect.new()
			mug.custom_minimum_size = Vector2(2, 3)
			mug.size = Vector2(2, 3)
			mug.color = Color(0.8, 0.6, 0.4, 0.8)
			mug.position = Vector2(slot.x - (desk_w * 0.35), slot.y - 2.0)
			_office_worker_layer.add_child(mug)

		# Worker sprite (now with morale expressions + 4-frame animation).
		var worker: Control = _make_worker_sprite(emp)
		worker.position = Vector2(slot.x - 7.0, slot.y - 20.0)
		_office_worker_layer.add_child(worker)

		# Disney-style positional bob: anticipation (slight down) then lift.
		# Each worker gets unique rhythm from their UID — no two bob in sync.
		var base_pos: Vector2 = worker.position
		var tw := worker.create_tween().set_loops()
		tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_interval(float(hash(emp.employee_uid) % 11) * 0.04)
		var bob: float = 0.8 + (float(emp.assignment % 3) * 0.2)
		# Anticipation: slight dip before the main bob (squash principle).
		tw.tween_property(worker, "position:y", base_pos.y + bob * 0.3, 0.12)
		tw.tween_property(worker, "position:y", base_pos.y - bob * 0.2, 0.38)
		tw.tween_property(worker, "position:y", base_pos.y + bob, 0.58)
		tw.tween_property(worker, "position:y", base_pos.y, 0.42)
		# Bug-fixers get extra lateral fidget (frustration animation).
		if emp.assignment == EmployeeData.Assignment.BUGS:
			tw.tween_property(worker, "position:x", base_pos.x + 0.6, 0.15)
			tw.tween_property(worker, "position:x", base_pos.x - 0.6, 0.15)
			tw.tween_property(worker, "position:x", base_pos.x, 0.12)
		# R&D gets a thoughtful lean.
		elif emp.assignment == EmployeeData.Assignment.RND:
			tw.tween_property(worker, "position:x", base_pos.x + 0.4, 0.80)
			tw.tween_property(worker, "position:x", base_pos.x, 0.60)


## Adds decorative furniture to the office scene — plants, whiteboard, water cooler.
## These scale with office level (bigger offices get more stuff).
func _add_office_decorations(width: float, height: float, level: int, accent: Color) -> void:
	# Potted plant in the corner (all levels).
	var plant := ColorRect.new()
	plant.custom_minimum_size = Vector2(4, 8)
	plant.size = Vector2(4, 8)
	plant.color = Color(0.25, 0.65, 0.35, 0.7)
	plant.position = Vector2(8, height * 0.55)
	_office_worker_layer.add_child(plant)
	# Plant pot.
	var pot := ColorRect.new()
	pot.custom_minimum_size = Vector2(5, 3)
	pot.size = Vector2(5, 3)
	pot.color = Color(0.55, 0.35, 0.25, 0.75)
	pot.position = Vector2(7, height * 0.55 + 8)
	_office_worker_layer.add_child(pot)

	# Whiteboard on the "wall" area (level 1+).
	if level >= 1:
		var board := ColorRect.new()
		board.custom_minimum_size = Vector2(20, 10)
		board.size = Vector2(20, 10)
		board.color = Color(0.88, 0.88, 0.90, 0.25)
		board.position = Vector2(width * 0.70, height * 0.15)
		_office_worker_layer.add_child(board)
		# Board frame.
		var frame := ColorRect.new()
		frame.custom_minimum_size = Vector2(22, 1)
		frame.size = Vector2(22, 1)
		frame.color = Color(0.50, 0.48, 0.44, 0.35)
		frame.position = Vector2(width * 0.70 - 1, height * 0.15 + 10)
		_office_worker_layer.add_child(frame)

	# Water cooler (level 2+).
	if level >= 2:
		var cooler := ColorRect.new()
		cooler.custom_minimum_size = Vector2(4, 10)
		cooler.size = Vector2(4, 10)
		cooler.color = Color(0.70, 0.75, 0.82, 0.5)
		cooler.position = Vector2(width - 14, height * 0.50)
		_office_worker_layer.add_child(cooler)
		# Water jug on top.
		var jug := ColorRect.new()
		jug.custom_minimum_size = Vector2(3, 4)
		jug.size = Vector2(3, 4)
		jug.color = Color(0.55, 0.75, 0.95, 0.45)
		jug.position = Vector2(width - 13.5, height * 0.50 - 4)
		_office_worker_layer.add_child(jug)

	# Second plant on the other side (level 3).
	if level >= 3:
		var plant2 := ColorRect.new()
		plant2.custom_minimum_size = Vector2(5, 10)
		plant2.size = Vector2(5, 10)
		plant2.color = Color(0.20, 0.58, 0.30, 0.65)
		plant2.position = Vector2(width - 16, height * 0.55 - 2)
		_office_worker_layer.add_child(plant2)
		var pot2 := ColorRect.new()
		pot2.custom_minimum_size = Vector2(6, 3)
		pot2.size = Vector2(6, 3)
		pot2.color = Color(0.50, 0.32, 0.22, 0.7)
		pot2.position = Vector2(width - 17, height * 0.55 + 8)
		_office_worker_layer.add_child(pot2)


func _build_desk_slots(style: Dictionary, width: float, height: float) -> Array[Vector2]:
	var slots: Array[Vector2] = []
	var rows: int = maxi(1, int(style.get("rows", 1)))
	var per_row: int = maxi(1, int(style.get("per_row", 4)))
	var base_y_ratio: float = clampf(float(style.get("base_y_ratio", 0.62)), 0.40, 0.86)
	var row_gap: float = clampf(float(style.get("row_gap", 14.0)), 10.0, 24.0)
	for row in rows:
		var y: float = clampf((height * base_y_ratio) + (float(row) * row_gap), 24.0, height - 9.0)
		for col in per_row:
			var tx: float = float(col + 1) / float(per_row + 1)
			var x: float = lerpf(12.0, width - 12.0, tx)
			slots.append(Vector2(x, y))
	return slots


func _make_worker_sprite(emp: EmployeeData) -> Control:
	# Pixel-art character sized to match desk scale (20px native, shown at ~18px).
	return PixelCharacter.create(emp, 18.0)


func _office_accent_color() -> Color:
	if GameState.company == null:
		return Color(0.38, 0.62, 0.88, 1.0)
	var base := Color(0.38, 0.62, 0.88, 1.0)
	match GameState.company.type:
		CompanyData.CompanyType.SAAS:
			base = Color(0.36, 0.62, 0.9, 1.0)
		CompanyData.CompanyType.CONSUMER:
			base = Color(0.86, 0.52, 0.78, 1.0)
		CompanyData.CompanyType.MARKETPLACE:
			base = Color(0.9, 0.64, 0.42, 1.0)
		CompanyData.CompanyType.DEV_TOOLS:
			base = Color(0.58, 0.52, 0.94, 1.0)
		_:
			base = Color(0.38, 0.62, 0.88, 1.0)
	match GameState.company.hosting_plan:
		CompanyData.HostingPlan.MANAGED_CLOUD:
			return base.lightened(0.08)
		CompanyData.HostingPlan.IN_HOUSE:
			return base.darkened(0.12)
		_:
			return base


func _refresh_team() -> void:
	SceneLoader.free_children(team_container)

	if GameState.employees.is_empty():
		var lbl := Label.new()
		lbl.text = "No team yet — visit People to hire"
		lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
		lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
		team_container.add_child(lbl)
		return

	for emp: EmployeeData in GameState.employees:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		team_container.add_child(row)

		var avatar := TextureRect.new()
		avatar.custom_minimum_size = Vector2(32, 32)
		avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		avatar.clip_contents = true
		var avatar_idx: int = (hash(emp.employee_name) % 8) + 1
		if not _avatar_cache.has(avatar_idx):
			_avatar_cache[avatar_idx] = ResourceLoader.load("res://assets/avatars/avatar_%d.png" % avatar_idx)
		var avatar_tex: Texture2D = _avatar_cache.get(avatar_idx) as Texture2D
		if avatar_tex:
			avatar.texture = avatar_tex
		row.add_child(avatar)

		var lbl := Label.new()
		var assign_name: String = EmployeeData.ASSIGNMENT_NAMES.get(emp.assignment, "Unassigned")
		lbl.text = "%s — %s · %s" % [emp.employee_name, emp.display_title(), assign_name]
		lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
		lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var morale_color: Color
		if emp.morale >= 70:
			morale_color = Color(0.55, 0.8, 0.55)
		elif emp.morale >= 40:
			morale_color = Color(0.85, 0.75, 0.35)
		else:
			morale_color = Color(0.9, 0.4, 0.35)
		lbl.add_theme_color_override("font_color", morale_color)
		row.add_child(lbl)


func _show_quarterly_report() -> void:
	var bullets := QuarterlyReport.generate(GameState)
	if bullets.is_empty():
		report_panel.visible = false
		return
	if report_header:
		report_header.text = "Quarterly Report · Year %d Q%d (just ended)" % [
			_last_closed_quarter_year(),
			_last_closed_quarter_number(),
		]
	var lines: Array[String] = []
	var shown: int = mini(bullets.size(), DASHBOARD_REPORT_BULLET_LIMIT)
	for i in shown:
		var b: String = bullets[i]
		lines.append("• " + b)
	if bullets.size() > DASHBOARD_REPORT_BULLET_LIMIT:
		lines.append("• ...and %d more items (check Finances for the full picture)" % [bullets.size() - DASHBOARD_REPORT_BULLET_LIMIT])
	report_body.text = "\n".join(lines)
	report_panel.visible = true


func _on_people() -> void:
	SceneLoader.goto_scene("res://src/ui/people/employee_list.tscn")


func _on_product() -> void:
	SceneLoader.goto_scene("res://src/ui/product/product_overview.tscn")


func _on_finance() -> void:
	SceneLoader.goto_scene("res://src/ui/finance/finance_overview.tscn")


func _on_market() -> void:
	SceneLoader.goto_scene("res://src/ui/market/market_leaderboard.tscn")


func _on_save_error(message: String) -> void:
	_headline_timer.stop()
	headline_label.text = message
	headline_label.modulate.a = 1.0
	headline_label.visible = true
	headline_label.add_theme_color_override("font_color", Color(0.95, 0.4, 0.3))
	var restore_tween := create_tween()
	restore_tween.tween_interval(4.0)
	restore_tween.tween_callback(func():
		headline_label.remove_theme_color_override("font_color")
		_refresh_headlines()
	)


func _on_menu() -> void:
	if not GameState.current_slot.is_empty():
		GameState.save_game(GameState.current_slot)
	SceneLoader.goto_scene("res://src/ui/main_menu/main_menu.tscn")


# ---------------------------------------------------------------------------
# Idle engine & soft currency HUD
# ---------------------------------------------------------------------------

func _build_chip_hud() -> void:
	# Small gold badge pinned to the top-right corner of the dashboard.
	var badge := PanelContainer.new()
	var style := ThemeManager._flat_box_static(
		Color(0.18, 0.14, 0.05, 0.92),
		ThemeManager.C_CHIP,
		ThemeManager.CORNER_XL, 1)
	badge.add_theme_stylebox_override("panel", style)
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge.offset_top  = 8
	badge.offset_right = -8
	badge.offset_bottom = 8 + ThemeManager.TOUCH_MIN_H
	badge.offset_left  = -120
	badge.z_index = 20
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(badge)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",  10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top",    6)
	margin.add_theme_constant_override("margin_bottom", 6)
	badge.add_child(margin)

	_chip_hud_label = Label.new()
	_chip_hud_label.add_theme_font_size_override("font_size", ThemeManager.FONT_MD)
	_chip_hud_label.add_theme_color_override("font_color", ThemeManager.C_CHIP)
	_chip_hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_chip_hud_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	margin.add_child(_chip_hud_label)
	_update_chip_hud()


func _build_passive_ticker() -> void:
	# Subtle income-ticking label at the bottom of the dashboard.
	_passive_ticker_label = Label.new()
	_passive_ticker_label.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	_passive_ticker_label.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
	_passive_ticker_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_passive_ticker_label.offset_bottom = -4
	_passive_ticker_label.offset_left   = 8
	_passive_ticker_label.offset_right  = 240
	_passive_ticker_label.offset_top    = -22
	_passive_ticker_label.z_index = 5
	_passive_ticker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_passive_ticker_label.text = ""
	add_child(_passive_ticker_label)
	_build_boost_idle_button()


func _build_boost_idle_button() -> void:
	var cost: int = CurrencyManager.COST_DOUBLE_IDLE
	_boost_idle_btn = Button.new()
	_boost_idle_btn.text = "2× (%d)" % cost
	_boost_idle_btn.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	_boost_idle_btn.add_theme_color_override("font_color", ThemeManager.C_CHIP)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.20, 0.7)
	style.set_corner_radius_all(ThemeManager.CORNER_SM)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	_boost_idle_btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = style.bg_color.lightened(0.08)
	_boost_idle_btn.add_theme_stylebox_override("hover", hover)
	_boost_idle_btn.add_theme_stylebox_override("pressed", style)
	_boost_idle_btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_boost_idle_btn.offset_left = 244
	_boost_idle_btn.offset_right = 320
	_boost_idle_btn.offset_bottom = -2
	_boost_idle_btn.offset_top = -24
	_boost_idle_btn.z_index = 6
	_boost_idle_btn.visible = false
	_boost_idle_btn.pressed.connect(_on_boost_idle)
	add_child(_boost_idle_btn)


func _on_boost_idle() -> void:
	if not CurrencyManager.spend_double_idle():
		return
	AnimHelper.float_text(self, "2× income for 1 hour!",
		ThemeManager.C_CHIP, Vector2(size.x * 0.5, size.y - 40))
	SfxPlayer.play("chip_spend")
	AnimHelper.haptic(&"light")
	_update_boost_idle_visibility()


func _update_chip_hud() -> void:
	if _chip_hud_label == null:
		return
	_chip_hud_label.text = "🪙 %d chips" % CurrencyManager.chips


func _on_chips_changed(_new_total: int, delta: int) -> void:
	_update_chip_hud()
	# Flash green for earn, red for spend.
	if _chip_hud_label and delta != 0:
		var flash := ThemeManager.C_GREEN if delta > 0 else ThemeManager.C_RED
		AnimHelper.flash_color(_chip_hud_label, flash)


func _on_passive_tick(amount: float) -> void:
	if _passive_ticker_label == null or not GameState.is_game_active:
		return
	if amount < 1.0:
		_passive_ticker_label.text = ""
		_update_boost_idle_visibility()
		return
	var mult := CurrencyManager.idle_multiplier()
	var mult_str := " (2×)" if mult > 1.0 else ""
	_passive_ticker_label.text = "+%s passive%s" % [SceneLoader.format_money(amount), mult_str]
	_update_boost_idle_visibility()


func _update_boost_idle_visibility() -> void:
	if _boost_idle_btn == null:
		return
	var has_revenue: bool = GameState.financials != null and GameState.financials.revenue > 0.0
	var boost_active: bool = CurrencyManager.double_idle_remaining() > 0
	var can_pay: bool = CurrencyManager.can_afford(CurrencyManager.COST_DOUBLE_IDLE)
	_boost_idle_btn.visible = has_revenue and not boost_active and can_pay and GameState.is_game_active


func _show_offline_summary(payload: Dictionary) -> void:
	if not is_instance_valid(self):
		return
	var income: float = float(payload.get("income", 0.0))
	var chips: int = int(payload.get("chips", 0))
	var elapsed: float = float(payload.get("seconds", 0.0))

	# Only show if there is meaningful income.
	if income < 1.0 and chips <= 0:
		return

	_offline_summary_backdrop = AnimHelper.show_backdrop(self, 0.55)
	_offline_summary_backdrop.z_index = 48

	var panel := OfflineSummary.create(income, chips, elapsed)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.z_index = 50
	add_child(panel)

	# Re-centre after layout pass.
	await get_tree().process_frame
	if not is_instance_valid(self) or not is_instance_valid(panel):
		return
	panel.offset_left  = -panel.size.x * 0.5
	panel.offset_right =  panel.size.x * 0.5
	panel.offset_top   = -panel.size.y * 0.5
	panel.offset_bottom =  panel.size.y * 0.5

	panel.collected.connect(func(_inc: float, _ch: int) -> void:
		AnimHelper.hide_backdrop(_offline_summary_backdrop)
		_offline_summary_backdrop = null
		_update_chip_hud()
	)


func _safe_disconnect(sig: Signal, callable: Callable) -> void:
	if sig.is_connected(callable):
		sig.disconnect(callable)


func _build_dev_button() -> void:
	if not AdManager.is_dev_mode():
		return
	var btn := Button.new()
	btn.text = "DEV"
	btn.custom_minimum_size = Vector2(54, 32)
	var style := ThemeManager._flat_box_static(
		Color(1.0, 0.6, 0.2, 0.25), Color(1.0, 0.6, 0.2, 0.7),
		ThemeManager.CORNER_SM)
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", ThemeManager._flat_box_static(
		Color(1.0, 0.6, 0.2, 0.4), Color(1.0, 0.6, 0.2, 0.9),
		ThemeManager.CORNER_SM))
	btn.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	btn.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	btn.pressed.connect(_open_dev_panel)
	# Place in top-right corner via a CanvasLayer so it floats above scroll
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	var anchor := Control.new()
	anchor.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	anchor.offset_left = -66
	anchor.offset_top = 6
	anchor.offset_right = -8
	anchor.offset_bottom = 38
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(anchor)
	anchor.add_child(btn)
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP


func _open_dev_panel() -> void:
	var panel := DevPanel.create()
	if panel == null:
		return
	get_tree().root.add_child(panel)
	panel.closed.connect(func():
		# Refresh dashboard after dev changes
		_refresh(GameState.current_quarter)
	)


