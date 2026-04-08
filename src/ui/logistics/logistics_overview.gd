extends Control
## Logistics screen — hosting health, plan controls, and infra objectives.

@onready var back_btn: Button = %BackButton
@onready var plan_picker: OptionButton = %PlanPicker
@onready var reliability_label: Label = %ReliabilityLabel
@onready var web_bar: ProgressBar = %WebBar
@onready var web_meta: Label = %WebMeta
@onready var cache_bar: ProgressBar = %CacheBar
@onready var cache_meta: Label = %CacheMeta
@onready var data_bar: ProgressBar = %DataBar
@onready var data_meta: Label = %DataMeta
@onready var hosting_cost_value: Label = %HostingCostValue
@onready var overage_cost_value: Label = %OverageCostValue
@onready var infra_team_value: Label = %InfraTeamValue
@onready var objectives_body: Label = %ObjectivesBody
@onready var plan_hint: Label = %PlanHint

const UPGRADE_COST_GROWTH := 1.55
const WEB_UPGRADE_BASE_COST := 450.0
const CACHE_UPGRADE_BASE_COST := 380.0
const DATA_UPGRADE_BASE_COST := 520.0
const OPTIMIZATION_BASE_COST := 750.0

var _upgrade_level_labels: Dictionary = {}
var _upgrade_cost_labels: Dictionary = {}
var _upgrade_buttons: Dictionary = {}
var _upgrade_hint_label: Label


func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	plan_picker.item_selected.connect(_on_plan_selected)
	_populate_plan_picker()
	_build_upgrade_actions()
	_refresh()
	UITouchHelper.harden_tree(self)
	Analytics.track_screen("logistics")
	var _logistics_vbox := plan_hint.get_parent()
	if _logistics_vbox:
		AnimHelper.stagger_list(_logistics_vbox, 0.04, 0.0, 20.0)


func _populate_plan_picker() -> void:
	plan_picker.clear()
	plan_picker.add_item(CompanyData.HOSTING_PLAN_NAMES.get(CompanyData.HostingPlan.MANAGED_CLOUD, "Managed Cloud"))
	plan_picker.add_item(CompanyData.HOSTING_PLAN_NAMES.get(CompanyData.HostingPlan.HYBRID, "Hybrid"))
	plan_picker.add_item(CompanyData.HOSTING_PLAN_NAMES.get(CompanyData.HostingPlan.IN_HOUSE, "In-house"))


func _refresh() -> void:
	if GameState.company == null:
		return

	var selected_plan: int = clampi(GameState.company.hosting_plan, 0, maxi(0, plan_picker.get_item_count() - 1))
	if plan_picker.selected != selected_plan:
		plan_picker.select(selected_plan)

	var reliability: float = GameState.company.hosting_reliability
	var peak_load: float = maxf(
		GameState.company.hosting_util_web,
		maxf(GameState.company.hosting_util_cache, GameState.company.hosting_util_data)
	)
	reliability_label.text = "Reliability: %.1f%%  ·  Peak lane load: %.0f%%" % [reliability, peak_load * 100.0]
	if reliability < 93.0:
		reliability_label.add_theme_color_override("font_color", ThemeManager.C_ORANGE)
	elif reliability < 97.0:
		reliability_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4))
	else:
		reliability_label.add_theme_color_override("font_color", Color(0.56, 0.88, 0.56))

	_set_lane(
		"Web",
		GameState.company.hosting_demand_web,
		GameState.company.hosting_capacity_web,
		GameState.company.hosting_util_web,
		web_bar,
		web_meta,
		GameState.company.hosting_upgrade_web_level
	)
	_set_lane(
		"Cache",
		GameState.company.hosting_demand_cache,
		GameState.company.hosting_capacity_cache,
		GameState.company.hosting_util_cache,
		cache_bar,
		cache_meta,
		GameState.company.hosting_upgrade_cache_level
	)
	_set_lane(
		"Data",
		GameState.company.hosting_demand_data,
		GameState.company.hosting_capacity_data,
		GameState.company.hosting_util_data,
		data_bar,
		data_meta,
		GameState.company.hosting_upgrade_data_level
	)

	var costs: Dictionary = GameState.financials.costs_breakdown
	hosting_cost_value.text = "$%s" % SceneLoader.format_money(float(costs.get("hosting", 0.0)))
	overage_cost_value.text = "$%s" % SceneLoader.format_money(GameState.company.hosting_overage_cost)
	infra_team_value.text = "%d assigned" % _infra_staff_count()
	objectives_body.text = "\n".join(_objective_lines())
	_refresh_upgrade_rows()

	var workload_profile: String = GameState.company.hosting_workload_profile.strip_edges()
	if workload_profile.is_empty():
		workload_profile = "General Cloud"
	var pressure: float = GameState.company.hosting_data_center_pressure
	plan_hint.text = "Workload profile: %s. Plan changes apply immediately and take full effect next quarter." % workload_profile
	if pressure >= 2.2:
		plan_hint.text += "\nThis run is data-center-heavy: prioritize Data/Cache upgrades and Infra staffing."
	elif pressure >= 1.25:
		plan_hint.text += "\nScale pressure is building: queue lane upgrades before demand spikes."
	if reliability < 93.0:
		plan_hint.text += "\nUrgent: stabilize hosting this quarter to avoid more churn pressure."


func _set_lane(
	lane_name: String,
	demand: float,
	capacity: float,
	util: float,
	bar: ProgressBar,
	meta: Label,
	lane_upgrade_level: int
) -> void:
	if bar == null or meta == null:
		return
	bar.min_value = 0.0
	bar.max_value = 1.6
	bar.value = clampf(util, 0.0, 1.6)
	if util > 1.0:
		bar.add_theme_color_override("font_color", ThemeManager.C_ORANGE)
	elif util > 0.85:
		bar.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4))
	else:
		bar.add_theme_color_override("font_color", Color(0.56, 0.88, 0.56))
	meta.text = "%s demand %s / capacity %s  ·  %.0f%% used" % [
		lane_name,
		SceneLoader.format_number(roundi(demand)),
		SceneLoader.format_number(roundi(capacity)),
		util * 100.0,
	]
	if lane_upgrade_level > 0:
		meta.text += "  ·  Upgrade L%d" % lane_upgrade_level


func _build_upgrade_actions() -> void:
	var vbox := plan_hint.get_parent()
	if vbox == null:
		return

	var panel := PanelContainer.new()
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	panel.add_child(body)
	vbox.add_child(panel)
	vbox.move_child(panel, plan_hint.get_index())

	var title := Label.new()
	title.text = "Capacity Actions"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.67, 0.82, 0.98))
	body.add_child(title)

	_add_upgrade_row(body, "web", "Scale Web lane")
	_add_upgrade_row(body, "cache", "Scale Cache lane")
	_add_upgrade_row(body, "data", "Scale Data lane")
	_add_upgrade_row(body, "optimization", "Optimize request pipeline")

	_upgrade_hint_label = Label.new()
	_upgrade_hint_label.add_theme_font_size_override("font_size", 12)
	_upgrade_hint_label.add_theme_color_override("font_color", Color(0.66, 0.74, 0.9))
	_upgrade_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_upgrade_hint_label)


func _add_upgrade_row(parent: VBoxContainer, lane_key: String, label_text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var title := Label.new()
	title.custom_minimum_size = Vector2(210, 0)
	title.text = label_text
	row.add_child(title)

	var level_label := Label.new()
	level_label.custom_minimum_size = Vector2(70, 0)
	row.add_child(level_label)
	_upgrade_level_labels[lane_key] = level_label

	var cost_label := Label.new()
	cost_label.custom_minimum_size = Vector2(120, 0)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(cost_label)
	_upgrade_cost_labels[lane_key] = cost_label

	var action_btn := Button.new()
	action_btn.custom_minimum_size = Vector2(140, ThemeManager.TOUCH_MIN_H)
	action_btn.pressed.connect(_on_upgrade_pressed.bind(lane_key))
	row.add_child(action_btn)
	_upgrade_buttons[lane_key] = action_btn


func _refresh_upgrade_rows() -> void:
	if GameState.company == null:
		return
	var lane_keys: Array[String] = ["web", "cache", "data", "optimization"]
	for lane_key in lane_keys:
		_refresh_upgrade_row(lane_key)

	var total_lane_levels: int = GameState.company.hosting_upgrade_web_level \
		+ GameState.company.hosting_upgrade_cache_level \
		+ GameState.company.hosting_upgrade_data_level
	var max_cash_spend: float = _next_upgrade_cost("web")
	max_cash_spend = maxf(max_cash_spend, _next_upgrade_cost("cache"))
	max_cash_spend = maxf(max_cash_spend, _next_upgrade_cost("data"))
	max_cash_spend = maxf(max_cash_spend, _next_upgrade_cost("optimization"))
	if _upgrade_hint_label:
		_upgrade_hint_label.text = "Built lane upgrades: %d  ·  Optimization level: %d  ·  Largest next upgrade: $%s" % [
			total_lane_levels,
			GameState.company.hosting_optimization_level,
			SceneLoader.format_money(max_cash_spend),
		]


func _refresh_upgrade_row(lane_key: String) -> void:
	var level_label := _upgrade_level_labels.get(lane_key, null) as Label
	var cost_label := _upgrade_cost_labels.get(lane_key, null) as Label
	var action_btn := _upgrade_buttons.get(lane_key, null) as Button
	if level_label == null or cost_label == null or action_btn == null:
		return

	var current_level: int = _upgrade_level(lane_key)
	var max_level: int = _upgrade_max_level(lane_key)
	level_label.text = "L%d/%d" % [current_level, max_level]

	if current_level >= max_level:
		cost_label.text = "Maxed"
		action_btn.disabled = true
		action_btn.text = "Maxed"
		return

	var cost: float = _next_upgrade_cost(lane_key)
	cost_label.text = "Next $%s" % SceneLoader.format_money(cost)
	var can_afford: bool = GameState.company.cash >= cost
	action_btn.disabled = not can_afford
	if lane_key == "optimization":
		action_btn.text = "Optimize"
	else:
		action_btn.text = "Buy +Capacity"


func _upgrade_level(lane_key: String) -> int:
	match lane_key:
		"web":
			return GameState.company.hosting_upgrade_web_level
		"cache":
			return GameState.company.hosting_upgrade_cache_level
		"data":
			return GameState.company.hosting_upgrade_data_level
		"optimization":
			return GameState.company.hosting_optimization_level
		_:
			return 0


func _upgrade_max_level(lane_key: String) -> int:
	if lane_key == "optimization":
		return CompanyData.HOSTING_OPTIMIZATION_MAX
	return CompanyData.HOSTING_LANE_UPGRADE_MAX


func _next_upgrade_cost(lane_key: String) -> float:
	var base_cost: float = WEB_UPGRADE_BASE_COST
	match lane_key:
		"cache":
			base_cost = CACHE_UPGRADE_BASE_COST
		"data":
			base_cost = DATA_UPGRADE_BASE_COST
		"optimization":
			base_cost = OPTIMIZATION_BASE_COST
		_:
			base_cost = WEB_UPGRADE_BASE_COST
	var next_level: int = _upgrade_level(lane_key)
	return roundf(base_cost * pow(UPGRADE_COST_GROWTH, float(next_level)))


func _on_upgrade_pressed(lane_key: String) -> void:
	if GameState.company == null:
		return
	var level: int = _upgrade_level(lane_key)
	var max_level: int = _upgrade_max_level(lane_key)
	if level >= max_level:
		return

	var cost: float = _next_upgrade_cost(lane_key)
	if GameState.company.cash < cost:
		return

	GameState.company.cash -= cost
	match lane_key:
		"web":
			GameState.company.hosting_upgrade_web_level += 1
		"cache":
			GameState.company.hosting_upgrade_cache_level += 1
		"data":
			GameState.company.hosting_upgrade_data_level += 1
		"optimization":
			GameState.company.hosting_optimization_level += 1

	var pretty_name := "Web capacity"
	match lane_key:
		"cache":
			pretty_name = "Cache capacity"
		"data":
			pretty_name = "Data capacity"
		"optimization":
			pretty_name = "Request pipeline optimization"
		_:
			pretty_name = "Web capacity"
	GameState.append_event_log({
		"quarter": GameState.current_quarter,
		"year": GameState.current_year,
		"event_id": "hosting_capacity_upgrade",
		"title": "Infra upgrade: %s purchased for $%s" % [pretty_name, SceneLoader.format_money(cost)],
	})

	if not GameState.current_slot.is_empty():
		GameState.auto_save()
	_refresh()


func _objective_lines() -> Array[String]:
	var lines: Array[String] = []
	var reliability_streak: int = _hosting_reliability_streak(97.0)
	var streak_goal: int = 2
	var streak_done: bool = reliability_streak >= streak_goal
	lines.append("%s Keep reliability above 97%% for 2 consecutive quarters (%d/%d)" % [
		"✓" if streak_done else "•",
		mini(reliability_streak, streak_goal),
		streak_goal,
	])

	var overage_done: bool = GameState.company.hosting_overage_cost <= 200.0
	lines.append("%s Keep hosting overage <= $200 this quarter (current: $%s)" % [
		"✓" if overage_done else "•",
		SceneLoader.format_money(GameState.company.hosting_overage_cost),
	])

	var target_infra: int = clampi(1 + ceili(float(GameState.product.users) / 15_000.0), 1, 6)
	var infra_count: int = _infra_staff_count()
	lines.append("%s Keep at least %d Infra staff assigned (%d/%d)" % [
		"✓" if infra_count >= target_infra else "•",
		target_infra,
		infra_count,
		target_infra,
	])
	var upgrades_done: int = GameState.company.hosting_upgrade_web_level \
		+ GameState.company.hosting_upgrade_cache_level \
		+ GameState.company.hosting_upgrade_data_level
	var upgrades_goal: int = clampi(1 + GameState.company.office_level, 1, 4)
	lines.append("%s Build at least %d lane upgrades (%d/%d)" % [
		"✓" if upgrades_done >= upgrades_goal else "•",
		upgrades_goal,
		upgrades_done,
		upgrades_goal,
	])
	var pressure: float = GameState.company.hosting_data_center_pressure
	if pressure >= 1.25:
		var data_util: float = GameState.company.hosting_util_data
		lines.append("%s Keep Data lane under 95%% load for current workload (%.0f%%)" % [
			"✓" if data_util <= 0.95 else "•",
			data_util * 100.0,
		])
	return lines


func _hosting_reliability_streak(min_reliability: float) -> int:
	var streak := 0
	if GameState.company.hosting_reliability >= min_reliability:
		streak += 1
	for idx in range(GameState.history.size() - 1, -1, -1):
		var row = GameState.history[idx]
		if not (row is Dictionary):
			break
		var rel: float = float(row.get("hosting_reliability", 0.0))
		if rel >= min_reliability:
			streak += 1
		else:
			break
	return streak


func _infra_staff_count() -> int:
	var count := 0
	for emp: EmployeeData in GameState.employees:
		if emp.assignment == EmployeeData.Assignment.INFRA:
			count += 1
	return count


func _on_plan_selected(index: int) -> void:
	if GameState.company == null:
		return
	var new_plan := clampi(index, 0, 2) as CompanyData.HostingPlan
	if GameState.company.hosting_plan == new_plan:
		return
	GameState.company.hosting_plan = new_plan
	if not GameState.current_slot.is_empty():
		GameState.auto_save()
	_refresh()


func _on_back() -> void:
	SceneLoader.goto_scene("res://src/ui/finance/finance_overview.tscn")
