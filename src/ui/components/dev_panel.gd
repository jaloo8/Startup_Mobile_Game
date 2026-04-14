class_name DevPanel
extends CanvasLayer
## Developer testing overlay — only accessible in dev mode.
##
## Full-featured test harness: state inspector, resource injection, time skip,
## god mode, difficulty swap, hiring/firing, fundraising, event trigger,
## economy control, world events, product tuning, quick save/load.
## Entirely code-driven (no .tscn needed).

signal closed

const DEV_ORANGE := Color(1.0, 0.6, 0.2, 1.0)
const DEV_BG     := Color(0.05, 0.07, 0.12, 0.96)

var _god_mode: bool = false
var _scroll: ScrollContainer
var _vbox: VBoxContainer
var _inspector_label: Label
var _status_label: Label
var _god_mode_btn: Button
var _load_btns: Array[Button] = []


static func create() -> DevPanel:
	if not AdManager.is_dev_mode():
		push_warning("DevPanel: not available outside dev mode")
		return null
	var panel := DevPanel.new()
	# Restore god mode state from meta if it was toggled previously
	if GameState.has_meta("god_mode"):
		panel._god_mode = GameState.get_meta("god_mode")
	return panel


func _ready() -> void:
	layer = 120  # above game UI, below SceneLoader transition (128)
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close()
		get_viewport().set_input_as_handled()


# ===========================================================================
# UI Construction
# ===========================================================================

func _build_ui() -> void:
	# Full-screen dimmed backdrop that blocks clicks
	var backdrop := ColorRect.new()
	backdrop.color = DEV_BG
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	_scroll = ScrollContainer.new()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.offset_left = 14; _scroll.offset_right = -14
	_scroll.offset_top = 10; _scroll.offset_bottom = -10
	add_child(_scroll)

	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 8)
	_scroll.add_child(_vbox)

	_build_header()
	_build_inspector()
	_build_cash_and_users()
	_build_time_skip()
	_build_mode_and_difficulty()
	_build_team()
	_build_product()
	_build_fundraising()
	_build_economy()
	_build_events()
	_build_chips()
	_build_state_export()
	_build_save_load()
	_build_footer()

	UITouchHelper.harden_tree(self)


# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------

func _build_header() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_vbox.add_child(row)

	var title := Label.new()
	title.text = "DEVELOPER TOOLS"
	title.add_theme_font_size_override("font_size", ThemeManager.FONT_XL)
	title.add_theme_color_override("font_color", DEV_ORANGE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)

	var close_btn := _make_btn("Close [Esc]", ThemeManager.C_RED)
	close_btn.pressed.connect(_close)
	row.add_child(close_btn)

	_vbox.add_child(_sep())


# ---------------------------------------------------------------------------
# State Inspector — live readout of all key metrics
# ---------------------------------------------------------------------------

func _build_inspector() -> void:
	_vbox.add_child(_section("State Inspector"))

	var panel := PanelContainer.new()
	var style := ThemeManager._flat_box_static(
		ThemeManager.C_SURFACE_LOW, ThemeManager.C_BORDER, ThemeManager.CORNER_SM)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)
	_vbox.add_child(panel)

	_inspector_label = Label.new()
	_inspector_label.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	_inspector_label.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
	_inspector_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_inspector_label)
	_refresh_inspector()

	# Status toast label (shows action confirmations)
	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	_status_label.add_theme_color_override("font_color", ThemeManager.C_GREEN)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.text = ""
	_vbox.add_child(_status_label)

	_vbox.add_child(_sep())


# ---------------------------------------------------------------------------
# Cash / Users injection
# ---------------------------------------------------------------------------

func _build_cash_and_users() -> void:
	_vbox.add_child(_section("Resources"))

	var cash_lbl := _dim_label("Cash:")
	_vbox.add_child(cash_lbl)
	var cash_row := _hbox()
	_vbox.add_child(cash_row)
	for pair in [["+$10K", 10_000.0], ["+$100K", 100_000.0], ["+$1M", 1_000_000.0], ["+$10M", 10_000_000.0]]:
		var btn := _make_btn(pair[0], ThemeManager.C_GREEN)
		btn.pressed.connect(_add_cash.bind(float(pair[1])))
		cash_row.add_child(btn)

	var user_lbl := _dim_label("Users:")
	_vbox.add_child(user_lbl)
	var user_row := _hbox()
	_vbox.add_child(user_row)
	for pair in [["+100", 100], ["+1K", 1_000], ["+10K", 10_000], ["+100K", 100_000]]:
		var btn := _make_btn(pair[0], ThemeManager.C_TEAL)
		btn.pressed.connect(_add_users.bind(int(pair[1])))
		user_row.add_child(btn)

	_vbox.add_child(_sep())


# ---------------------------------------------------------------------------
# Time skip
# ---------------------------------------------------------------------------

func _build_time_skip() -> void:
	_vbox.add_child(_section("Time Skip"))
	var row := _hbox()
	_vbox.add_child(row)
	for pair in [["Skip 1Q", 1], ["Skip 4Q (1yr)", 4], ["Skip 8Q (2yr)", 8], ["Skip 20Q (5yr)", 20]]:
		var btn := _make_btn(pair[0], ThemeManager.C_BLUE)
		btn.pressed.connect(_skip_quarters.bind(int(pair[1])))
		row.add_child(btn)

	_vbox.add_child(_sep())


# ---------------------------------------------------------------------------
# God mode + Difficulty
# ---------------------------------------------------------------------------

func _build_mode_and_difficulty() -> void:
	_vbox.add_child(_section("Mode & Difficulty"))

	var mode_row := _hbox()
	_vbox.add_child(mode_row)

	_god_mode_btn = _make_btn(
		"God Mode: %s" % ("ON" if _god_mode else "OFF"),
		ThemeManager.C_PURPLE if _god_mode else ThemeManager.C_SURFACE_HIGH)
	_god_mode_btn.pressed.connect(_toggle_god_mode)
	mode_row.add_child(_god_mode_btn)

	var diff_row := _hbox()
	_vbox.add_child(diff_row)
	diff_row.add_child(_dim_label("Difficulty:"))
	for d in ["sandbox", "normal", "hardcore"]:
		var is_current := d == GameState.difficulty
		var btn := _make_btn(d.capitalize(), ThemeManager.C_GOLD if is_current else ThemeManager.C_SURFACE_HIGH)
		btn.pressed.connect(_set_difficulty.bind(d))
		diff_row.add_child(btn)

	# Restore section
	_vbox.add_child(_dim_label("Quick Restore:"))
	var restore_row := _hbox()
	_vbox.add_child(restore_row)

	_add_action_btn(restore_row, "Energy=100", ThemeManager.C_GREEN, func():
		GameState.founder_energy = 100
		_flash("Founder energy restored to 100")
	)
	_add_action_btn(restore_row, "Board=4", ThemeManager.C_GREEN, func():
		GameState.board_patience = 4
		_flash("Board patience restored to 4")
	)
	_add_action_btn(restore_row, "Morale=80", ThemeManager.C_GREEN, func():
		for emp in GameState.employees:
			emp.morale = 80; emp.stress = 20
		_flash("All employees: morale=80, stress=20")
	)

	_vbox.add_child(_sep())


# ---------------------------------------------------------------------------
# Team management
# ---------------------------------------------------------------------------

func _build_team() -> void:
	_vbox.add_child(_section("Team"))

	var row1 := _hbox()
	_vbox.add_child(row1)

	_add_action_btn(row1, "Hire Random", ThemeManager.C_BLUE, func():
		if GameState.company == null or GameState.market == null:
			_flash("No active game"); return
		var candidates := HiringEngine.generate_candidates(1, GameState.market, GameState)
		if candidates.is_empty():
			_flash("Failed to generate candidate"); return
		var emp: EmployeeData = candidates[0]
		var ok := GameState.hire_employee(emp)
		if ok:
			_flash("Hired: %s (%s, %s)" % [emp.employee_name,
				EmployeeData.Specialty.keys()[emp.specialty],
				EmployeeData.Seniority.keys()[emp.seniority]])
		else:
			_flash("Hire failed — office full?")
	)

	_add_action_btn(row1, "Hire 5 Random", ThemeManager.C_BLUE, func():
		if GameState.company == null or GameState.market == null:
			_flash("No active game"); return
		var candidates := HiringEngine.generate_candidates(5, GameState.market, GameState)
		var count := 0
		for c in candidates:
			if GameState.hire_employee(c):
				count += 1
		_flash("Hired %d / %d candidates" % [count, candidates.size()])
	)

	_add_action_btn(row1, "Fire Last", ThemeManager.C_RED, func():
		if GameState.employees.is_empty():
			_flash("No employees to fire"); return
		var emp: EmployeeData = GameState.employees.back()
		var emp_name := emp.employee_name
		GameState.fire_employee(emp)
		_flash("Fired: %s" % emp_name)
	)

	# Employee skill boost
	var row2 := _hbox()
	_vbox.add_child(row2)

	_add_action_btn(row2, "Skill All +10", ThemeManager.C_TEAL, func():
		for emp in GameState.employees:
			emp.skill = clampi(emp.skill + 10, 0, 100)
			emp.speed = clampi(emp.speed + 5, 0, 100)
		_flash("All employees: skill+10, speed+5")
	)

	_add_action_btn(row2, "Team Size: %d" % GameState.employees.size(), ThemeManager.C_SURFACE_HIGH, func():
		_flash("Current: %d / %d capacity" % [
			GameState.employees.size(),
			GameState.company.office_capacity() if GameState.company else 0])
	)

	_vbox.add_child(_sep())


# ---------------------------------------------------------------------------
# Product tuning
# ---------------------------------------------------------------------------

func _build_product() -> void:
	_vbox.add_child(_section("Product"))

	var row1 := _hbox()
	_vbox.add_child(row1)

	_add_action_btn(row1, "Debt/Bugs=0", ThemeManager.C_GREEN, func():
		if GameState.product == null: return
		GameState.product.tech_debt = 0
		GameState.product.bugs = 0
		_flash("Tech debt=0, bugs=0")
	)

	_add_action_btn(row1, "Stability=100", ThemeManager.C_GREEN, func():
		if GameState.product == null: return
		GameState.product.stability = 100
		_flash("Stability set to 100")
	)

	_add_action_btn(row1, "UX=80", ThemeManager.C_GREEN, func():
		if GameState.product == null: return
		GameState.product.ux_score = 80
		_flash("UX score set to 80")
	)

	# Sabotage row (for testing failure states)
	var row2 := _hbox()
	_vbox.add_child(row2)
	_vbox.add_child(_dim_label("Sabotage (test failure paths):"))

	var sab_row := _hbox()
	_vbox.add_child(sab_row)

	_add_action_btn(sab_row, "Debt=80", ThemeManager.C_RED, func():
		if GameState.product == null: return
		GameState.product.tech_debt = 80
		_flash("Tech debt set to 80")
	)

	_add_action_btn(sab_row, "Bugs=50", ThemeManager.C_RED, func():
		if GameState.product == null: return
		GameState.product.bugs = 50
		_flash("Bugs set to 50")
	)

	_add_action_btn(sab_row, "Cash=$0", ThemeManager.C_RED, func():
		if GameState.company == null: return
		GameState.company.cash = 0.0
		_flash("Cash set to $0 — bankruptcy imminent")
	)

	_add_action_btn(sab_row, "Energy=5", ThemeManager.C_RED, func():
		GameState.founder_energy = 5
		_flash("Founder energy=5 — burnout imminent")
	)

	# Quick product actions
	_vbox.add_child(_dim_label("Quick Actions:"))
	var quick_row := _hbox()
	_vbox.add_child(quick_row)

	_add_action_btn(quick_row, "Ship Feature", ThemeManager.C_BLUE, func():
		if GameState.product == null: return
		if GameState.product.current_feature_name.is_empty():
			_flash("No feature in progress"); return
		var fid: String = GameState.product.slot_feature_id(0)
		var fname := GameState.product.current_feature_name
		GameState.product.add_feature(fname, 80, GameState.current_quarter, fid)
		GameState.product.remove_build(fid)
		GameState.product.current_feature_name = ""
		_flash("Shipped feature: %s (quality 80)" % fname)
	)

	_add_action_btn(quick_row, "Quality Max", ThemeManager.C_GREEN, func():
		if GameState.product == null: return
		GameState.product.stability = 100
		GameState.product.ux_score = 100
		_flash("Stability=100, UX=100")
	)

	_add_action_btn(quick_row, "Bugs=0", ThemeManager.C_GREEN, func():
		if GameState.product == null: return
		GameState.product.bugs = 0
		_flash("All bugs cleared")
	)

	# Hosting controls
	if GameState.company != null:
		_vbox.add_child(_dim_label("Hosting:"))
		var host_row := _hbox()
		_vbox.add_child(host_row)

		_add_action_btn(host_row, "Max Hosting", ThemeManager.C_TEAL, func():
			if GameState.company == null: return
			var co := GameState.company
			co.hosting_upgrade_web_level = CompanyData.HOSTING_LANE_UPGRADE_MAX
			co.hosting_upgrade_cache_level = CompanyData.HOSTING_LANE_UPGRADE_MAX
			co.hosting_upgrade_data_level = CompanyData.HOSTING_LANE_UPGRADE_MAX
			co.hosting_optimization_level = CompanyData.HOSTING_OPTIMIZATION_MAX
			co.hosting_reliability = 99.99
			co.hosting_incidents_last_quarter = 0
			co.hosting_overage_cost = 0.0
			_flash("Hosting maxed: all lanes L%d, opt L%d, 99.99%% reliability" % [
				CompanyData.HOSTING_LANE_UPGRADE_MAX, CompanyData.HOSTING_OPTIMIZATION_MAX])
		)

		_add_action_btn(host_row, "Reliability=99.99", ThemeManager.C_GREEN, func():
			if GameState.company == null: return
			GameState.company.hosting_reliability = 99.99
			GameState.company.hosting_incidents_last_quarter = 0
			_flash("Hosting reliability=99.99%, incidents cleared")
		)

	_vbox.add_child(_sep())


# ---------------------------------------------------------------------------
# Fundraising
# ---------------------------------------------------------------------------

func _build_fundraising() -> void:
	_vbox.add_child(_section("Fundraising"))

	var row := _hbox()
	_vbox.add_child(row)

	_add_action_btn(row, "Generate Offer", ThemeManager.C_GOLD, func():
		if GameState.company == null:
			_flash("No active game"); return
		var offer := FundraisingEngine.generate_offer(GameState)
		if offer.get("rejected", false):
			_flash("Rejected: %s" % offer.get("reason", "unknown"))
		else:
			_flash("Offer: %s %s — $%s at $%s val (%.1f%% dilution)" % [
				offer.get("tier", "?"),
				offer.get("round", "?"),
				SceneLoader.format_money(offer.get("amount", 0.0)),
				SceneLoader.format_money(offer.get("valuation", 0.0)),
				offer.get("dilution", 0.0)])
	)

	_add_action_btn(row, "Accept Offer", ThemeManager.C_GREEN, func():
		if GameState.company == null:
			_flash("No active game"); return
		var offer := FundraisingEngine.generate_offer(GameState)
		if offer.get("rejected", false):
			_flash("No offer available: %s" % offer.get("reason", ""))
			return
		FundraisingEngine.accept_offer(GameState, offer)
		_flash("Accepted: $%s from %s" % [
			SceneLoader.format_money(offer.get("amount", 0.0)),
			offer.get("firm_name", "Unknown VC")])
	)

	_add_action_btn(row, "Next Round: %s" % _next_round_name(), ThemeManager.C_SURFACE_HIGH, func():
		_flash("Next round: %s | Can fundraise: %s" % [
			_next_round_name(),
			"Yes" if FundraisingEngine.can_fundraise(GameState) else "No"])
	)

	_vbox.add_child(_sep())


# ---------------------------------------------------------------------------
# Economy & World Events
# ---------------------------------------------------------------------------

func _build_economy() -> void:
	_vbox.add_child(_section("Economy & World"))

	var econ_row := _hbox()
	_vbox.add_child(econ_row)
	econ_row.add_child(_dim_label("Economy:"))

	for state_name in ["BULL", "NEUTRAL", "BEAR"]:
		var val: int = {"BULL": 0, "NEUTRAL": 1, "BEAR": 2}[state_name]
		var is_current: bool = GameState.market != null and GameState.market.economy_state == val
		var color: Color = ThemeManager.C_GREEN if state_name == "BULL" else (
			ThemeManager.C_GOLD if state_name == "NEUTRAL" else ThemeManager.C_RED)
		var btn := _make_btn(state_name, color if is_current else ThemeManager.C_SURFACE_HIGH)
		btn.pressed.connect(_set_economy.bind(val, state_name))
		econ_row.add_child(btn)

	# World events
	var world_row := _hbox()
	_vbox.add_child(world_row)

	_add_action_btn(world_row, "Trigger World Event", ThemeManager.C_PURPLE, func():
		WorldEventEngine.resolve_quarter(GameState)
		if GameState.active_world_event_id != "":
			_flash("World event: %s (%dQ left)" % [
				GameState.active_world_event_title,
				GameState.active_world_event_quarters_left])
		else:
			_flash("No world event triggered (RNG)")
	)

	_add_action_btn(world_row, "Clear World Event", ThemeManager.C_TEXT_DIM, func():
		GameState.clear_world_event_state()
		_flash("World event cleared")
	)

	# Current world event display
	if GameState.active_world_event_id != "":
		var we_label := _dim_label("Active: %s (%dQ left)" % [
			GameState.active_world_event_title,
			GameState.active_world_event_quarters_left])
		we_label.add_theme_color_override("font_color", ThemeManager.C_PURPLE)
		_vbox.add_child(we_label)

	_vbox.add_child(_sep())


# ---------------------------------------------------------------------------
# Events
# ---------------------------------------------------------------------------

func _build_events() -> void:
	_vbox.add_child(_section("Events"))

	var row1 := _hbox()
	_vbox.add_child(row1)

	_add_action_btn(row1, "Trigger Random Event", DEV_ORANGE, _trigger_random_event)

	_add_action_btn(row1, "Clear Cooldowns", ThemeManager.C_TEXT_DIM, func():
		EventEngine.reset_cooldowns()
		_flash("All event cooldowns cleared")
	)

	_add_action_btn(row1, "Clear Fired Events", ThemeManager.C_TEXT_DIM, func():
		GameState.fired_one_time_events.clear()
		_flash("One-time event flags cleared — all events eligible again")
	)

	# Event log excerpt
	if not GameState.event_log.is_empty():
		_vbox.add_child(_dim_label("Recent events (%d total):" % GameState.event_log.size()))
		var log_count := mini(5, GameState.event_log.size())
		for i in range(GameState.event_log.size() - log_count, GameState.event_log.size()):
			var entry: Dictionary = GameState.event_log[i]
			var log_line := _dim_label("  Y%d Q%d: %s" % [
				entry.get("year", 0), entry.get("quarter", 0),
				entry.get("title", entry.get("event_id", "?"))])
			log_line.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
			_vbox.add_child(log_line)

	_vbox.add_child(_sep())


# ---------------------------------------------------------------------------
# VC Chips
# ---------------------------------------------------------------------------

func _build_chips() -> void:
	_vbox.add_child(_section("VC Chips"))
	_vbox.add_child(_dim_label("Current: %d chips (earned: %d, spent: %d)" % [
		CurrencyManager.chips, CurrencyManager.total_earned, CurrencyManager.total_spent]))

	var row := _hbox()
	_vbox.add_child(row)

	_add_action_btn(row, "+10", ThemeManager.C_GREEN, func():
		CurrencyManager.earn(10, "dev_panel")
		_flash("Earned 10 chips — total %d" % CurrencyManager.chips)
	)
	_add_action_btn(row, "+50", ThemeManager.C_GREEN, func():
		CurrencyManager.earn(50, "dev_panel")
		_flash("Earned 50 chips — total %d" % CurrencyManager.chips)
	)
	_add_action_btn(row, "+100", ThemeManager.C_GREEN, func():
		CurrencyManager.earn(100, "dev_panel")
		_flash("Earned 100 chips — total %d" % CurrencyManager.chips)
	)
	_add_action_btn(row, "Reset to 0", ThemeManager.C_RED, func():
		CurrencyManager.chips = 0
		CurrencyManager.total_earned = 0
		CurrencyManager.total_spent = 0
		CurrencyManager.chips_changed.emit(0, 0)
		_flash("Chips reset to 0")
	)

	_vbox.add_child(_sep())


# ---------------------------------------------------------------------------
# State Export
# ---------------------------------------------------------------------------

func _build_state_export() -> void:
	_vbox.add_child(_section("State Export"))

	var row := _hbox()
	_vbox.add_child(row)

	_add_action_btn(row, "Print State JSON", DEV_ORANGE, _on_export_state)

	_vbox.add_child(_sep())


func _on_export_state() -> void:
	var state := {}
	if GameState.company:
		state["company"] = {
			"name": GameState.company.company_name,
			"type": GameState.company.type,
			"cash": GameState.company.cash,
			"valuation": GameState.company.valuation,
			"reputation": GameState.company.reputation,
			"employee_count": GameState.employees.size(),
		}
	if GameState.product:
		state["product"] = {
			"users": GameState.product.users,
			"dau": GameState.product.dau,
			"stability": GameState.product.stability,
			"ux_score": GameState.product.ux_score,
			"bugs": GameState.product.bugs,
			"tech_debt": GameState.product.tech_debt,
			"features_shipped": GameState.product.features.size(),
		}
	if GameState.financials:
		state["financials"] = {
			"revenue": GameState.financials.revenue,
			"burn": GameState.financials.burn_rate,
			"runway_quarters": GameState.financials.runway_quarters(
				GameState.company.cash if GameState.company else 0.0),
		}
	state["quarter"] = GameState.current_quarter
	state["year"] = GameState.current_year
	state["total_quarters"] = GameState.total_quarters_elapsed()
	print(JSON.stringify(state, "\t"))
	ToastManager.show("State exported to console")


# ---------------------------------------------------------------------------
# Save / Load
# ---------------------------------------------------------------------------

func _build_save_load() -> void:
	_vbox.add_child(_section("Quick Save / Load"))

	_vbox.add_child(_dim_label("Save to slot:"))
	var save_row := _hbox()
	_vbox.add_child(save_row)
	for i in range(1, 6):
		var slot := "slot_%d" % i
		var has := GameState.has_save(slot)
		var label_text := "Save %d" % i
		if has:
			label_text += " *"  # indicate slot is occupied
		var btn := _make_btn(label_text, ThemeManager.C_BLUE)
		btn.pressed.connect(_quick_save.bind(slot, i))
		save_row.add_child(btn)

	_vbox.add_child(_dim_label("Load from slot:"))
	var load_row := _hbox()
	_vbox.add_child(load_row)
	_load_btns.clear()
	for i in range(1, 6):
		var slot := "slot_%d" % i
		var has := GameState.has_save(slot)
		var btn := _make_btn("Load %d" % i, ThemeManager.C_GOLD if has else ThemeManager.C_SURFACE_LOW)
		btn.disabled = not has
		btn.pressed.connect(_quick_load.bind(slot))
		load_row.add_child(btn)
		_load_btns.append(btn)

	_vbox.add_child(_sep())


# ---------------------------------------------------------------------------
# Footer
# ---------------------------------------------------------------------------

func _build_footer() -> void:
	var info := "Y%d Q%d (elapsed: %d) | %s | %s | Slot: %s | v%s" % [
		GameState.current_year, GameState.current_quarter,
		GameState.total_quarters_elapsed(),
		GameState.difficulty.capitalize(),
		GameState.starting_scenario.capitalize().replace("_", " "),
		GameState.current_slot if GameState.current_slot != "" else "(unsaved)",
		GameState.GAME_VERSION,
	]
	var footer := Label.new()
	footer.text = info
	footer.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	footer.add_theme_color_override("font_color", ThemeManager.C_TEXT_MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(footer)


# ===========================================================================
# Shared UI helpers
# ===========================================================================

func _section(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_MD)
	lbl.add_theme_color_override("font_color", DEV_ORANGE)
	return lbl


func _dim_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl


func _hbox(gap: int = 6) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", gap)
	return h


func _sep() -> HSeparator:
	return HSeparator.new()


func _make_btn(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, ThemeManager.TOUCH_MIN_H)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := ThemeManager._flat_box_static(color.darkened(0.6), color, ThemeManager.CORNER_MD)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", ThemeManager._flat_box_static(
		color.darkened(0.4), color, ThemeManager.CORNER_MD))
	btn.add_theme_stylebox_override("pressed", ThemeManager._flat_box_static(
		color.darkened(0.7), color.darkened(0.2), ThemeManager.CORNER_MD))
	var disabled_style := ThemeManager._flat_box_static(
		ThemeManager.C_SURFACE_LOW, ThemeManager.C_BORDER, ThemeManager.CORNER_MD)
	disabled_style.content_margin_left = 8.0
	disabled_style.content_margin_right = 8.0
	disabled_style.content_margin_top = 6.0
	disabled_style.content_margin_bottom = 6.0
	btn.add_theme_stylebox_override("disabled", disabled_style)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", ThemeManager.C_TEXT_MUTED)
	btn.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	return btn


func _add_action_btn(parent: HBoxContainer, text: String, color: Color, callback: Callable) -> Button:
	var btn := _make_btn(text, color)
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


# ===========================================================================
# Inspector
# ===========================================================================

func _refresh_inspector() -> void:
	if not is_instance_valid(_inspector_label):
		return
	if GameState.company == null or GameState.product == null:
		_inspector_label.text = "(no active game)"
		return

	var co := GameState.company
	var pr := GameState.product
	var fi := GameState.financials
	var emp_count := GameState.employees.size()

	var avg_morale := 0.0
	var avg_stress := 0.0
	var avg_skill := 0.0
	if emp_count > 0:
		for emp in GameState.employees:
			avg_morale += emp.morale
			avg_stress += emp.stress
			avg_skill += emp.skill
		avg_morale /= emp_count
		avg_stress /= emp_count
		avg_skill /= emp_count

	var runway_str := "N/A"
	if fi != null:
		var rw := fi.runway_quarters(co.cash)
		if rw == INF:
			runway_str = "Profitable"
		elif rw < 0:
			runway_str = "In debt"
		else:
			runway_str = "%.1f Q" % rw

	var econ_str := "?"
	if GameState.market != null:
		econ_str = ["Bull", "Neutral", "Bear"][clampi(GameState.market.economy_state, 0, 2)]

	var lines: PackedStringArray = []
	lines.append("FINANCES: Cash $%s | Rev $%s/Q | Burn $%s/Q | Runway %s" % [
		SceneLoader.format_money(co.cash),
		SceneLoader.format_money(fi.revenue if fi else 0.0),
		SceneLoader.format_money(fi.burn_rate if fi else 0.0),
		runway_str])
	lines.append("PRODUCT: %s users | %s DAU | %d features | %.1f%% churn" % [
		SceneLoader.format_number(pr.users),
		SceneLoader.format_number(pr.dau),
		pr.feature_count(), pr.churn_rate * 100.0])
	lines.append("HEALTH: Debt %d | Bugs %d | Stability %d | UX %d" % [
		pr.tech_debt, pr.bugs, pr.stability, pr.ux_score])
	lines.append("TEAM: %d employees | Morale %.0f | Stress %.0f | Skill %.0f" % [
		emp_count, avg_morale, avg_stress, avg_skill])
	lines.append("FOUNDER: Energy %d | Board %d | Streak %d | Valuation $%s" % [
		GameState.founder_energy, GameState.board_patience,
		GameState.profit_streak, SceneLoader.format_money(co.valuation)])
	lines.append("WORLD: Economy %s | Equity %.1f%% | God Mode %s" % [
		econ_str, co.equity_owned, "ON" if _god_mode else "OFF"])
	if GameState.active_world_event_id != "":
		lines.append("EVENT: %s (%dQ left)" % [
			GameState.active_world_event_title,
			GameState.active_world_event_quarters_left])

	_inspector_label.text = "\n".join(lines)


# ===========================================================================
# Status flash — brief confirmation of actions
# ===========================================================================

func _flash(msg: String) -> void:
	_refresh_inspector()
	if not is_instance_valid(_status_label):
		return
	_status_label.text = msg
	_status_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(_status_label, "modulate:a", 0.0, 0.5)


# ===========================================================================
# Actions
# ===========================================================================

func _close() -> void:
	closed.emit()
	queue_free()


func _add_cash(amount: float) -> void:
	if GameState.company == null:
		return
	GameState.company.cash += amount
	_flash("+$%s cash" % SceneLoader.format_money(amount))


func _add_users(amount: int) -> void:
	if GameState.product == null:
		return
	GameState.product.users += amount
	# Keep DAU proportional (at least 25% of total)
	GameState.product.dau = maxi(GameState.product.dau, GameState.product.users / 4)
	_flash("+%s users (total: %s)" % [
		SceneLoader.format_number(amount),
		SceneLoader.format_number(GameState.product.users)])


func _skip_quarters(count: int) -> void:
	var skipped := 0
	for _i in count:
		if not GameState.is_game_active:
			break
		GameState.advance_quarter()
		skipped += 1
	if skipped < count:
		_flash("Skipped %d/%d quarters (game ended)" % [skipped, count])
	else:
		_flash("Skipped %d quarters — now Y%d Q%d" % [
			skipped, GameState.current_year, GameState.current_quarter])


func _toggle_god_mode() -> void:
	_god_mode = not _god_mode
	GameState.set_meta("god_mode", _god_mode)
	_god_mode_btn.text = "God Mode: %s" % ("ON" if _god_mode else "OFF")
	# Update button style
	var color := ThemeManager.C_PURPLE if _god_mode else ThemeManager.C_SURFACE_HIGH
	var style := ThemeManager._flat_box_static(color.darkened(0.6), color, ThemeManager.CORNER_MD)
	style.content_margin_left = 8.0; style.content_margin_right = 8.0
	style.content_margin_top = 6.0; style.content_margin_bottom = 6.0
	_god_mode_btn.add_theme_stylebox_override("normal", style)
	if _god_mode:
		GameState.founder_energy = maxi(GameState.founder_energy, 50)
		GameState.board_patience = maxi(GameState.board_patience, 2)
	_flash("God Mode %s — loss conditions %s" % [
		"ON" if _god_mode else "OFF",
		"disabled" if _god_mode else "enabled"])


func _set_difficulty(diff: String) -> void:
	GameState.difficulty = diff
	_flash("Difficulty changed to %s" % diff.capitalize())
	# Rebuild panel to update highlighted button
	_close()
	var new_panel := DevPanel.create()
	if new_panel:
		get_tree().root.add_child(new_panel)


func _set_economy(state: int, name: String) -> void:
	if GameState.market == null:
		_flash("No market data"); return
	GameState.market.economy_state = state
	_flash("Economy set to %s" % name)
	# Rebuild panel to update highlighted button
	_close()
	var new_panel := DevPanel.create()
	if new_panel:
		get_tree().root.add_child(new_panel)


func _trigger_random_event() -> void:
	var events := EventEngine.roll_quarter_events(GameState)
	if events.is_empty():
		_flash("No eligible events (try clearing cooldowns)")
		return
	var ev: EventData = events[0]
	GameState.pending_events.append(ev)
	GameState.event_triggered.emit(ev)
	_flash("Event: %s" % ev.title)


func _next_round_name() -> String:
	if GameState.financials == null:
		return "?"
	var round_val = FundraisingEngine.next_round(GameState)
	var names: Array = ["Pre-Seed", "Seed", "Series A", "Series B", "Growth"]
	if round_val >= 0 and round_val < names.size():
		return names[round_val]
	return "?"


func _quick_save(slot: String, slot_num: int) -> void:
	var old_slot := GameState.current_slot
	GameState.current_slot = slot
	var ok := GameState.save_game(slot)
	GameState.current_slot = old_slot
	if ok:
		_flash("Saved to slot %d (Y%dQ%d, $%s, %s users)" % [
			slot_num, GameState.current_year, GameState.current_quarter,
			SceneLoader.format_money(GameState.company.cash) if GameState.company else "?",
			SceneLoader.format_number(GameState.product.users) if GameState.product else "?"])
		# Update load buttons to reflect new save
		_refresh_load_buttons()
	else:
		_flash("SAVE FAILED for slot %d" % slot_num)


func _refresh_load_buttons() -> void:
	for i in _load_btns.size():
		var slot := "slot_%d" % (i + 1)
		var has := GameState.has_save(slot)
		var btn := _load_btns[i]
		btn.disabled = not has
		var color := ThemeManager.C_GOLD if has else ThemeManager.C_SURFACE_LOW
		var style := ThemeManager._flat_box_static(color.darkened(0.6), color, ThemeManager.CORNER_MD)
		style.content_margin_left = 8.0; style.content_margin_right = 8.0
		style.content_margin_top = 6.0; style.content_margin_bottom = 6.0
		btn.add_theme_stylebox_override("normal", style)


func _quick_load(slot: String) -> void:
	if not GameState.has_save(slot):
		_flash("No save in that slot")
		return
	var ok := GameState.load_game(slot)
	if ok:
		_close()
		SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")
	else:
		_flash("LOAD FAILED for %s" % slot)
