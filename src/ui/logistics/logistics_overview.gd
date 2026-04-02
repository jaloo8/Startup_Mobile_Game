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


func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	plan_picker.item_selected.connect(_on_plan_selected)
	_populate_plan_picker()
	_refresh()
	Analytics.track_screen("logistics")


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
		reliability_label.add_theme_color_override("font_color", Color(0.95, 0.56, 0.45))
	elif reliability < 97.0:
		reliability_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4))
	else:
		reliability_label.add_theme_color_override("font_color", Color(0.56, 0.88, 0.56))

	_set_lane("Web", GameState.company.hosting_demand_web, GameState.company.hosting_capacity_web, GameState.company.hosting_util_web, web_bar, web_meta)
	_set_lane("Cache", GameState.company.hosting_demand_cache, GameState.company.hosting_capacity_cache, GameState.company.hosting_util_cache, cache_bar, cache_meta)
	_set_lane("Data", GameState.company.hosting_demand_data, GameState.company.hosting_capacity_data, GameState.company.hosting_util_data, data_bar, data_meta)

	var costs: Dictionary = GameState.financials.costs_breakdown
	hosting_cost_value.text = "$%s" % SceneLoader.format_money(float(costs.get("hosting", 0.0)))
	overage_cost_value.text = "$%s" % SceneLoader.format_money(GameState.company.hosting_overage_cost)
	infra_team_value.text = "%d assigned" % _infra_staff_count()
	objectives_body.text = "\n".join(_objective_lines())

	plan_hint.text = "Plan changes apply immediately and are fully reflected after the next quarter simulation."
	if reliability < 93.0:
		plan_hint.text += "\nUrgent: stabilize hosting this quarter to avoid more churn pressure."


func _set_lane(
	lane_name: String,
	demand: float,
	capacity: float,
	util: float,
	bar: ProgressBar,
	meta: Label
) -> void:
	if bar == null or meta == null:
		return
	bar.min_value = 0.0
	bar.max_value = 1.6
	bar.value = clampf(util, 0.0, 1.6)
	if util > 1.0:
		bar.add_theme_color_override("font_color", Color(0.95, 0.56, 0.45))
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


func _objective_lines() -> Array[String]:
	var lines: Array[String] = []
	var reliability_streak: int = _hosting_reliability_streak(97.0)
	var streak_goal: int = 2
	var streak_done: bool = reliability_streak >= streak_goal
	lines.append("%s Keep reliability >=97%% for 2 consecutive quarters (%d/%d)" % [
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
