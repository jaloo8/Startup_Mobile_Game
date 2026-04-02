extends Node
## Holds all game state. Access via GameState.

signal quarter_advanced(quarter_number: int)
signal game_over(reason: String)
signal save_error(message: String)
@warning_ignore("unused_signal")
signal game_won(win_type: String)
@warning_ignore("unused_signal")
signal event_triggered(event: EventData)
@warning_ignore("unused_signal")
signal employee_quit(employee: EmployeeData)
@warning_ignore("unused_signal")
signal feature_shipped(feature_name: String, quality: int)

var company: CompanyData
var employees: Array[EmployeeData] = []
var product: ProductData
var financials: FinancialsData
var market: MarketData

var current_quarter: int = 1
var current_year: int = 1
var difficulty: String = "normal"
var starting_scenario: String = "garage"

var history: Array[Dictionary] = []
var event_log: Array[Dictionary] = []
var fired_one_time_events: Array[String] = []
var pending_events: Array[EventData] = []
var active_world_event_id: String = ""
var active_world_event_title: String = ""
var active_world_event_description: String = ""
var active_world_event_quarters_left: int = 0
var active_world_event_effects: Dictionary = {}

var is_game_active: bool = false
var current_slot: String = ""
var angel_bailout_used: bool = false
var profit_streak: int = 0
var founder_energy: int = 100
var board_patience: int = 4
var _milestones_hit: Array[String] = []
var _achieved_wins: Array[String] = []
var interviewer_busy_quarters: Dictionary = {}  # employee_uid -> quarters remaining

const SAVE_DIR := "user://saves/"
const SLOT_NAMES := ["slot_1", "slot_2", "slot_3", "slot_4", "slot_5"]


static func _safe_array(value) -> Array:
	return value if value is Array else []


static func _safe_dict(value) -> Dictionary:
	return value if value is Dictionary else {}


static func _dict_array(value) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for item in _safe_array(value):
		if item is Dictionary:
			out.append(item)
	return out


static func _string_array(value) -> Array[String]:
	var out: Array[String] = []
	for item in _safe_array(value):
		out.append(str(item))
	return out
const MAX_SLOTS := 5
const MAX_HISTORY_SIZE := 200
const MAX_EVENT_LOG_SIZE := 500
const MAX_HISTORY_SAVE_SIZE := 120
const MAX_EVENT_LOG_SAVE_SIZE := 280
const MAX_EVENT_ID_LEN := 64
const MAX_EVENT_TITLE_LEN := 220
const MAX_EMPLOYEES := 500
const MAX_SAVE_BYTES := 4 * 1024 * 1024
const SAVE_BACKUP_SUFFIX := ".bak"
const SAVE_TMP_SUFFIX := ".tmp"
# Sustainable win is intentionally later-game to preserve early momentum while
# extending run length. Feature build speed stays unchanged.
const SUSTAINABLE_MIN_QUARTERS := 20
const SUSTAINABLE_PROFIT_STREAK := 6
const SUSTAINABLE_DEFAULT_REQUIREMENTS := {
	"users": 12_000,
	"features": 8,
	"revenue_per_q": 250_000.0,
}
const SUSTAINABLE_REQUIREMENTS_BY_TYPE := {
	CompanyData.CompanyType.SAAS: {
		"users": 10_000,
		"features": 8,
		"revenue_per_q": 220_000.0,
	},
	CompanyData.CompanyType.CONSUMER: {
		"users": 16_000,
		"features": 9,
		"revenue_per_q": 240_000.0,
	},
	CompanyData.CompanyType.MARKETPLACE: {
		"users": 14_000,
		"features": 8,
		"revenue_per_q": 260_000.0,
	},
	CompanyData.CompanyType.DEV_TOOLS: {
		"users": 9_000,
		"features": 8,
		"revenue_per_q": 210_000.0,
	},
}
# Centralized difficulty knobs consumed by simulation, fundraising, and events.
# Keep these in one place so balancing passes stay predictable.
const DIFFICULTY_MULTS := {
	"sandbox": {
		"cash_mult": 2.0,
		"churn_mult": 0.5,
		"competitor_mult": 0.5,
		"fundraise_amount_mult": 1.12,
		"fundraise_threshold_shift": -0.05,
		"event_pressure_mult": 0.85,
	},
	"normal": {
		"cash_mult": 1.0,
		"churn_mult": 1.0,
		"competitor_mult": 1.0,
		"fundraise_amount_mult": 1.0,
		"fundraise_threshold_shift": 0.0,
		"event_pressure_mult": 1.0,
	},
	"hardcore": {
		"cash_mult": 0.6,
		"churn_mult": 1.5,
		"competitor_mult": 1.5,
		"fundraise_amount_mult": 0.90,
		"fundraise_threshold_shift": 0.06,
		"event_pressure_mult": 1.20,
	},
}

var _save_thread: Thread
var _save_mutex: Mutex
var _last_lifecycle_autosave_ms: int = -1
const LIFECYCLE_AUTOSAVE_DEBOUNCE_MS := 1500


func _ready() -> void:
	var err := DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_error("GameState: failed to create save directory (%d)" % err)
	_save_mutex = Mutex.new()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			_lifecycle_autosave("wm_close_request")
		NOTIFICATION_APPLICATION_PAUSED:
			_lifecycle_autosave("application_paused")
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_lifecycle_autosave("application_focus_out")


func _exit_tree() -> void:
	if _save_thread and _save_thread.is_started():
		_save_thread.wait_to_finish()
	_save_thread = null


func new_game(config: Dictionary) -> void:
	company = CompanyData.new()
	company.company_name = config.get("name", "My Startup")
	company.type = config.get("type", CompanyData.CompanyType.SAAS)
	CompanyData.load_niche_catalog()
	company.apply_niche(str(config.get("niche_id", "")))

	var bg_key: int = config.get("founder_background", CompanyData.FounderBackground.ENGINEER)
	company.founder_background = bg_key as CompanyData.FounderBackground
	var arch: Dictionary = CompanyData.FOUNDER_ARCHETYPES.get(bg_key, {})
	company.founder_stats = arch.get("stats", {"technical": 5, "finance": 5, "people": 5, "business": 5}).duplicate()

	product = ProductData.new()
	financials = FinancialsData.new()
	market = MarketData.new()
	employees.clear()
	history.clear()
	event_log.clear()
	fired_one_time_events.clear()
	pending_events.clear()
	clear_world_event_state()
	_milestones_hit.clear()
	_achieved_wins.clear()
	interviewer_busy_quarters.clear()
	angel_bailout_used = false
	profit_streak = 0
	founder_energy = 100
	board_patience = 4

	difficulty = config.get("difficulty", "normal")
	starting_scenario = config.get("scenario", "garage")
	current_quarter = 1
	current_year = 1
	_apply_starting_scenario()

	is_game_active = true


func _apply_starting_scenario() -> void:
	var cash_mult: float = DIFFICULTY_MULTS.get(difficulty, {}).get("cash_mult", 1.0)
	match starting_scenario:
		"garage":
			company.cash = 20_000.0 * cash_mult
			company.office_level = 0
			company.hosting_plan = CompanyData.HostingPlan.MANAGED_CLOUD
		"accelerator":
			company.cash = 125_000.0 * cash_mult
			company.office_level = 0
			company.hosting_plan = CompanyData.HostingPlan.MANAGED_CLOUD
		"spinoff":
			company.cash = 500_000.0 * cash_mult
			company.office_level = 1
			company.hosting_plan = CompanyData.HostingPlan.HYBRID
		"vc_backed":
			company.cash = 2_000_000.0 * cash_mult
			company.office_level = 1
			company.hosting_plan = CompanyData.HostingPlan.HYBRID
			financials = FinancialsData.new()
			financials.funding_rounds.append({
				"round": "Seed",
				"amount": 2_000_000.0 * cash_mult,
				"valuation": 8_000_000.0,
				"quarter": 0,
			})
			company.equity_owned = 75.0
		"growth_operator":
			company.cash = 8_000_000.0 * cash_mult
			company.office_level = 2
			company.hosting_plan = CompanyData.HostingPlan.HYBRID
			company.reputation = 60
			company.equity_owned = 62.0
			company.valuation = 120_000_000.0
			financials = FinancialsData.new()
			financials.funding_rounds.append({
				"round": "Series A",
				"amount": 14_000_000.0 * cash_mult,
				"valuation": 60_000_000.0,
				"quarter": 0,
			})
			board_patience = 3
			founder_energy = 88
		"scale_chief":
			company.cash = 30_000_000.0 * cash_mult
			company.office_level = 3
			company.hosting_plan = CompanyData.HostingPlan.IN_HOUSE
			company.reputation = 68
			company.equity_owned = 40.0
			company.valuation = 650_000_000.0
			financials = FinancialsData.new()
			financials.funding_rounds.append({
				"round": "Series A",
				"amount": 18_000_000.0 * cash_mult,
				"valuation": 75_000_000.0,
				"quarter": 0,
			})
			financials.funding_rounds.append({
				"round": "Series B",
				"amount": 80_000_000.0 * cash_mult,
				"valuation": 420_000_000.0,
				"quarter": 0,
			})
			board_patience = 2
			founder_energy = 80
		_:
			company.hosting_plan = CompanyData.HostingPlan.MANAGED_CLOUD

	_reset_hosting_state()
	_seed_starting_company_state()


func _seed_starting_company_state() -> void:
	match starting_scenario:
		"growth_operator":
			_seed_shipped_features(4, 58, 84)
			product.users = 24_000
			product.dau = 7_500
			product.stability = 72
			product.ux_score = 67
			product.tech_debt = mini(100, maxi(product.tech_debt, 26))
			product.bugs = maxi(product.bugs, 14)
			product.churn_rate = 0.058
			_seed_team(
				{
					EmployeeData.Assignment.FEATURES: 5,
					EmployeeData.Assignment.BUGS: 2,
					EmployeeData.Assignment.TECH_DEBT: 1,
					EmployeeData.Assignment.INFRA: 2,
					EmployeeData.Assignment.RND: 2,
				},
				12,
				EmployeeData.Seniority.MID,
				2,
				8
			)
			_seed_next_feature_progress(0.35)
			_seed_financial_snapshot_for_scenario()
		"scale_chief":
			_seed_shipped_features(7, 60, 90)
			product.users = 185_000
			product.dau = 56_000
			product.stability = 68
			product.ux_score = 63
			product.tech_debt = mini(100, maxi(product.tech_debt, 44))
			product.bugs = maxi(product.bugs, 30)
			product.churn_rate = 0.072
			_seed_team(
				{
					EmployeeData.Assignment.FEATURES: 8,
					EmployeeData.Assignment.BUGS: 4,
					EmployeeData.Assignment.TECH_DEBT: 3,
					EmployeeData.Assignment.INFRA: 4,
					EmployeeData.Assignment.RND: 3,
				},
				22,
				EmployeeData.Seniority.SENIOR,
				4,
				14
			)
			_seed_next_feature_progress(0.48)
			_seed_financial_snapshot_for_scenario()
		_:
			pass


func _seed_shipped_features(target_count: int, quality_min: int, quality_max: int) -> void:
	var remaining: int = maxi(0, target_count)
	while remaining > 0:
		var available: Array[Dictionary] = product.available_features(company.type)
		if available.is_empty():
			break
		var feature_def: Dictionary = available[0]
		var fid: String = str(feature_def.get("id", "")).strip_edges()
		var fname: String = str(feature_def.get("name", "")).strip_edges()
		if fname.is_empty():
			fname = "Feature"
		var quality: int = clampi(randi_range(quality_min, quality_max), 20, 100)
		product.add_feature(fname, quality, 0, fid)
		product.apply_feature_effects(feature_def)
		remaining -= 1


func _seed_next_feature_progress(progress_ratio: float) -> void:
	var available: Array[Dictionary] = product.available_features(company.type)
	if available.is_empty():
		product.target_feature_id = ""
		product.feature_progress = 0.0
		return
	var target: Dictionary = available[0]
	product.target_feature_id = str(target.get("id", "")).strip_edges()
	var cost: float = maxf(1.0, float(target.get("cost", ProductData.FEATURE_COST)))
	product.feature_progress = clampf(cost * progress_ratio, 0.0, cost * 0.95)


func _seed_financial_snapshot_for_scenario() -> void:
	financials.revenue = RevenueEngine.calculate(company, product)
	var salary_total := 0.0
	for emp: EmployeeData in employees:
		salary_total += emp.salary_per_quarter
	var finance_discount: float = 1.0 - company.founder_stat("finance") * 0.02
	var infra_cost := maxf(10.0, product.users * 0.006) * maxf(0.6, finance_discount)
	var office_costs := [0.0, 1_000.0, 4_000.0, 10_000.0]
	var office_idx: int = clampi(company.office_level, 0, office_costs.size() - 1)
	financials.costs_breakdown["salaries"] = salary_total
	financials.costs_breakdown["infrastructure"] = infra_cost
	financials.costs_breakdown["hosting"] = 0.0
	financials.costs_breakdown["office"] = float(office_costs[office_idx])
	financials.burn_rate = financials.total_costs()


func _seed_team(assignments: Dictionary, headcount: int, min_seniority: EmployeeData.Seniority, tenure_min: int, tenure_max: int) -> void:
	var desired: int = maxi(0, headcount)
	if desired <= 0:
		return
	var assignment_queue: Array[EmployeeData.Assignment] = []
	for assignment_key in assignments.keys():
		var assignment_val: int = int(assignment_key)
		var amount: int = maxi(0, int(assignments.get(assignment_key, 0)))
		for i in amount:
			assignment_queue.append(assignment_val as EmployeeData.Assignment)
	while assignment_queue.size() < desired:
		assignment_queue.append(EmployeeData.Assignment.FEATURES)
	assignment_queue.shuffle()

	var pool_size: int = maxi(desired + 4, desired * 2)
	var candidates: Array[EmployeeData] = HiringEngine.generate_candidates(pool_size, market, self)
	var seed_count: int = mini(desired, mini(candidates.size(), company.office_capacity()))
	var min_seniority_i: int = int(min_seniority)
	for i in seed_count:
		var emp: EmployeeData = candidates[i]
		if int(emp.seniority) < min_seniority_i:
			emp.seniority = min_seniority
			emp.skill = clampi(emp.skill + randi_range(6, 16), 30, 99)
			emp.speed = clampi(emp.speed + randi_range(5, 14), 30, 99)
			var salary_range: Vector2 = EmployeeData.SALARY_RANGES[min_seniority]
			var target_salary: float = randf_range(salary_range.x, salary_range.y)
			if emp.employment_type == EmployeeData.EmploymentType.CONTRACTOR:
				target_salary *= 0.78
			elif emp.employment_type == EmployeeData.EmploymentType.INTERN:
				target_salary *= 0.46
			emp.salary_per_quarter = maxf(emp.salary_per_quarter, target_salary)
		if min_seniority_i >= int(EmployeeData.Seniority.SENIOR) and emp.employment_type == EmployeeData.EmploymentType.INTERN:
			emp.employment_type = EmployeeData.EmploymentType.FULL_TIME

		emp.assignment = assignment_queue[i]
		emp.tenure_quarters = randi_range(maxi(0, tenure_min), maxi(tenure_min, tenure_max))
		emp.morale = clampi(emp.morale + randi_range(-6, 8), 45, 92)
		emp.stress = clampi(emp.stress + randi_range(4, 18), 0, 95)
		hire_employee(emp)


func _reset_hosting_state() -> void:
	company.hosting_reliability = 99.5
	company.hosting_demand_web = 0.0
	company.hosting_demand_cache = 0.0
	company.hosting_demand_data = 0.0
	company.hosting_capacity_web = 0.0
	company.hosting_capacity_cache = 0.0
	company.hosting_capacity_data = 0.0
	company.hosting_util_web = 0.0
	company.hosting_util_cache = 0.0
	company.hosting_util_data = 0.0
	company.hosting_overage_cost = 0.0
	company.hosting_incidents_last_quarter = 0
	company.hosting_upgrade_web_level = 0
	company.hosting_upgrade_cache_level = 0
	company.hosting_upgrade_data_level = 0
	company.hosting_optimization_level = 0
	company.hosting_workload_profile = "General Cloud"
	company.hosting_data_center_pressure = 0.0


func clear_world_event_state() -> void:
	active_world_event_id = ""
	active_world_event_title = ""
	active_world_event_description = ""
	active_world_event_quarters_left = 0
	active_world_event_effects.clear()


func active_world_event_brief() -> String:
	if active_world_event_quarters_left <= 0:
		return ""
	var title := active_world_event_title.strip_edges()
	if title.is_empty():
		return ""
	return "%s (%dQ left)" % [title, active_world_event_quarters_left]


func world_event_mult(key: String, default_value: float = 1.0) -> float:
	if active_world_event_quarters_left <= 0:
		return default_value
	var clean_key := key.strip_edges()
	if clean_key.is_empty():
		return default_value
	var value_raw = active_world_event_effects.get(clean_key, default_value)
	var value: float = default_value
	if value_raw is int or value_raw is float:
		value = float(value_raw)
	return clampf(value, 0.25, 3.0)


func difficulty_mult(key: String) -> float:
	return DIFFICULTY_MULTS.get(difficulty, {}).get(key, 1.0)


func advance_quarter() -> void:
	if not is_game_active:
		return
	if company == null or product == null or financials == null:
		push_error("GameState: cannot advance — game not initialized")
		return

	var features_before: int = product.feature_count()
	SimulationEngine.process_quarter(self)

	# Fire celebration signal if a new feature shipped this quarter
	if product.feature_count() > features_before:
		var newest: Dictionary = product.features.back()
		feature_shipped.emit(newest.get("name", "Feature"), newest.get("quality", 0))

	_take_snapshot()
	current_quarter += 1
	if current_quarter > 4:
		current_quarter = 1
		current_year += 1

	quarter_advanced.emit(current_quarter)
	_check_milestone_bonuses()
	_check_end_conditions()
	auto_save()


func total_quarters_elapsed() -> int:
	return (current_year - 1) * 4 + (current_quarter - 1)


func has_achieved_win(win_type: String) -> bool:
	var key := win_type.strip_edges().to_lower()
	return key in _achieved_wins


func register_achieved_win(win_type: String) -> void:
	var key := win_type.strip_edges().to_lower()
	if key.is_empty():
		return
	if key not in _achieved_wins:
		_achieved_wins.append(key)


func continue_after_victory() -> void:
	# Allows post-victory sandbox play (same save, same company).
	if company == null or product == null or financials == null:
		return
	is_game_active = true
	append_event_log({
		"quarter": current_quarter,
		"year": current_year,
		"event_id": "post_victory_continue",
		"title": "Chose to keep building after victory",
	})


func hire_employee(emp: EmployeeData) -> bool:
	if employees.size() >= company.office_capacity():
		return false
	if emp == null:
		return false
	emp.ensure_uid()
	while _has_employee_uid(emp.employee_uid):
		emp.employee_uid = EmployeeData._generate_uid()
	emp.clamp_all()
	employees.append(emp)
	emp.record_quarter_snapshot(current_year, current_quarter)
	return true


func fire_employee(emp: EmployeeData) -> void:
	if emp:
		interviewer_busy_quarters.erase(emp.employee_uid)
	employees.erase(emp)


func lock_interviewer(employee_uid: String, quarters: int = 1) -> void:
	var uid := employee_uid.strip_edges()
	if uid.is_empty():
		return
	var q := clampi(quarters, 1, 4)
	interviewer_busy_quarters[uid] = maxi(interviewer_busy_for(uid), q)


func interviewer_busy_for(employee_uid: String) -> int:
	var uid := employee_uid.strip_edges()
	if uid.is_empty():
		return 0
	return maxi(0, int(interviewer_busy_quarters.get(uid, 0)))


func is_interviewer_busy(employee_uid: String) -> bool:
	return interviewer_busy_for(employee_uid) > 0


func consume_interviewer_busy_quarter(employee_uid: String) -> void:
	var uid := employee_uid.strip_edges()
	if uid.is_empty():
		return
	var left := interviewer_busy_for(uid)
	if left <= 0:
		return
	left -= 1
	if left <= 0:
		interviewer_busy_quarters.erase(uid)
	else:
		interviewer_busy_quarters[uid] = left


func _has_employee_uid(uid: String) -> bool:
	for emp in employees:
		if emp.employee_uid == uid:
			return true
	return false


func get_employee_by_uid(uid: String) -> EmployeeData:
	var clean := uid.strip_edges()
	if clean.is_empty():
		return null
	for emp in employees:
		if emp.employee_uid == clean:
			return emp
	return null


func average_team_morale() -> float:
	if employees.is_empty():
		return 0.0
	var total := 0.0
	for emp: EmployeeData in employees:
		total += emp.morale
	return total / float(employees.size())


func _take_snapshot() -> void:
	var cost_lines: Dictionary = financials.costs_breakdown
	var salaries_cost: float = float(cost_lines.get("salaries", 0.0))
	var infra_cost: float = float(cost_lines.get("infrastructure", 0.0))
	var hosting_cost: float = float(cost_lines.get("hosting", 0.0))
	var office_cost: float = float(cost_lines.get("office", 0.0))
	history.append({
		"quarter": current_quarter,
		"year": current_year,
		"cash": company.cash,
		"users": product.users,
		"employees": employees.size(),
		"revenue": financials.revenue,
		"burn_rate": financials.burn_rate,
		"tech_debt": product.tech_debt,
		"valuation": company.valuation,
		"avg_morale": average_team_morale(),
		"hosting_reliability": company.hosting_reliability,
		"hosting_overage_cost": company.hosting_overage_cost,
		"hosting_incidents": company.hosting_incidents_last_quarter,
		"hosting_workload_profile": company.hosting_workload_profile,
		"hosting_data_center_pressure": company.hosting_data_center_pressure,
		"world_event_id": active_world_event_id,
		"world_event_title": active_world_event_title,
		"world_event_quarters_left": active_world_event_quarters_left,
		"salaries_cost": salaries_cost,
		"infrastructure_cost": infra_cost,
		"hosting_cost": hosting_cost,
		"office_cost": office_cost,
		"net_income": financials.revenue - (salaries_cost + infra_cost + hosting_cost + office_cost),
	})
	if history.size() > MAX_HISTORY_SIZE:
		history = history.slice(-MAX_HISTORY_SIZE)


func _check_end_conditions() -> void:
	if financials.revenue > financials.burn_rate:
		profit_streak += 1
	else:
		profit_streak = 0

	var elapsed_q: int = total_quarters_elapsed()
	var arr: float = financials.revenue * 4.0
	if arr >= 100_000_000 and product.users >= 100_000 and not has_achieved_win("ipo"):
		_emit_victory("ipo")
		return
	if company.valuation >= 1_000_000_000 and not has_achieved_win("unicorn"):
		_emit_victory("unicorn")
		return
	if _meets_sustainable_victory(elapsed_q) and not has_achieved_win("sustainable"):
		_emit_victory("sustainable")
		return

	if founder_energy <= 0:
		is_game_active = false
		game_over.emit("founder_burnout")
		return

	if not financials.funding_rounds.is_empty() and board_patience <= 0:
		is_game_active = false
		game_over.emit("board_takeover")
		return

	if company.cash <= 0 and financials.revenue < financials.burn_rate:
		is_game_active = false
		game_over.emit("bankruptcy")
	elif product.users <= 0 and elapsed_q > 12:
		is_game_active = false
		game_over.emit("dead_product")


static func _sustainable_requirements(company_type: int) -> Dictionary:
	var req: Dictionary = _safe_dict(
		SUSTAINABLE_REQUIREMENTS_BY_TYPE.get(company_type, SUSTAINABLE_DEFAULT_REQUIREMENTS)
	)
	if req.is_empty():
		return SUSTAINABLE_DEFAULT_REQUIREMENTS
	return req


func _meets_sustainable_victory(elapsed_q: int) -> bool:
	if elapsed_q < SUSTAINABLE_MIN_QUARTERS:
		return false
	if profit_streak < SUSTAINABLE_PROFIT_STREAK:
		return false
	var req := _sustainable_requirements(company.type)
	var min_users := int(req.get("users", SUSTAINABLE_DEFAULT_REQUIREMENTS["users"]))
	var min_features := int(req.get("features", SUSTAINABLE_DEFAULT_REQUIREMENTS["features"]))
	var min_revenue := float(req.get("revenue_per_q", SUSTAINABLE_DEFAULT_REQUIREMENTS["revenue_per_q"]))
	if product.users < min_users:
		return false
	if product.feature_count() < min_features:
		return false
	if financials.revenue < min_revenue:
		return false
	return true


func _emit_victory(win_type: String) -> void:
	if has_achieved_win(win_type):
		return
	register_achieved_win(win_type)
	is_game_active = false
	game_won.emit(win_type)


const MILESTONES := {
	"100_users": {"threshold_users": 100, "bonus": 25_000.0, "title": "Milestone: 100 users — investors released a $25K tranche"},
	"1k_users": {"threshold_users": 1000, "bonus": 50_000.0, "title": "Milestone: 1K users — investors released a $50K tranche"},
	"first_revenue": {"threshold_revenue": 1.0, "bonus": 15_000.0, "title": "First revenue! Investors released a $15K bonus"},
	"10k_users": {"threshold_users": 10000, "bonus": 100_000.0, "title": "Milestone: 10K users — investors released a $100K tranche"},
}


func _check_milestone_bonuses() -> void:
	if financials.funding_rounds.is_empty():
		return

	for key: String in MILESTONES:
		if key in _milestones_hit:
			continue
		var m: Dictionary = MILESTONES[key]
		var hit := false
		if m.has("threshold_users") and product.users >= m["threshold_users"]:
			hit = true
		if m.has("threshold_revenue") and financials.revenue >= m["threshold_revenue"]:
			hit = true
		if hit:
			_milestones_hit.append(key)
			company.cash += m["bonus"]
			Analytics.track_milestone_bonus(key, m["bonus"])
			append_event_log({
				"quarter": current_quarter,
				"year": current_year,
				"event_id": "milestone_" + key,
				"title": m["title"],
			})


func _compact_history_for_save() -> Array[Dictionary]:
	var rows: Array[Dictionary] = _dict_array(history)
	if rows.size() > MAX_HISTORY_SAVE_SIZE:
		rows = rows.slice(-MAX_HISTORY_SAVE_SIZE)
	return rows


func _compact_event_log_for_save() -> Array[Dictionary]:
	var rows: Array[Dictionary] = _dict_array(event_log)
	if rows.size() > MAX_EVENT_LOG_SAVE_SIZE:
		rows = rows.slice(-MAX_EVENT_LOG_SAVE_SIZE)
	return rows


func append_event_log(entry: Dictionary) -> void:
	if entry.is_empty():
		return
	var year_val: int = maxi(1, int(entry.get("year", current_year)))
	var quarter_val: int = clampi(int(entry.get("quarter", current_quarter)), 1, 4)
	var event_id_val: String = str(entry.get("event_id", "")).strip_edges()
	if event_id_val.is_empty():
		event_id_val = "misc"
	if event_id_val.length() > MAX_EVENT_ID_LEN:
		event_id_val = event_id_val.substr(0, MAX_EVENT_ID_LEN)
	var title_val: String = str(entry.get("title", "")).strip_edges()
	if title_val.is_empty():
		title_val = event_id_val
	if title_val.length() > MAX_EVENT_TITLE_LEN:
		title_val = title_val.substr(0, MAX_EVENT_TITLE_LEN)

	var normalized := {
		"quarter": quarter_val,
		"year": year_val,
		"event_id": event_id_val,
		"title": title_val,
	}
	if not event_log.is_empty():
		var last_raw = event_log.back()
		if last_raw is Dictionary:
			var last: Dictionary = last_raw
			if int(last.get("quarter", 0)) == quarter_val \
			and int(last.get("year", 0)) == year_val \
			and str(last.get("event_id", "")) == event_id_val \
			and str(last.get("title", "")) == title_val:
				return

	event_log.append(normalized)
	if event_log.size() > MAX_EVENT_LOG_SIZE:
		event_log = event_log.slice(-MAX_EVENT_LOG_SIZE)


func event_count_this_quarter(event_id: String = "") -> int:
	if event_log.is_empty():
		return 0
	var target_id: String = event_id.strip_edges()
	var count := 0
	for idx in range(event_log.size() - 1, -1, -1):
		var raw = event_log[idx]
		if not (raw is Dictionary):
			continue
		var row: Dictionary = raw
		if int(row.get("quarter", -1)) != current_quarter or int(row.get("year", -1)) != current_year:
			break
		if target_id.is_empty() or str(row.get("event_id", "")) == target_id:
			count += 1
	return count


# --- Save / Load ---

func auto_save() -> void:
	if current_slot.is_empty():
		return
	save_game_async(current_slot)


func autosave_now(reason: String = "manual") -> bool:
	if current_slot.is_empty():
		return false
	if company == null or product == null or financials == null or market == null:
		return false
	var ok: bool = save_game(current_slot)
	if not ok:
		push_warning("GameState: autosave_now failed (%s)" % reason)
	return ok


func _lifecycle_autosave(reason: String) -> void:
	# Some platforms can fire multiple lifecycle notifications in quick succession.
	# Debounce to avoid redundant writes while still protecting player progress.
	var now_ms: int = Time.get_ticks_msec()
	if _last_lifecycle_autosave_ms >= 0 and (now_ms - _last_lifecycle_autosave_ms) < LIFECYCLE_AUTOSAVE_DEBOUNCE_MS:
		return
	_last_lifecycle_autosave_ms = now_ms
	autosave_now(reason)


func save_game_async(slot_name: String) -> void:
	if slot_name not in SLOT_NAMES:
		push_error("GameState: invalid slot name: %s" % slot_name)
		return

	# Reliability first: always flush the previous write before starting a new one,
	# so we never drop the latest autosave.
	if _save_thread and _save_thread.is_started():
		_save_thread.wait_to_finish()

	_save_mutex.lock()
	var data := _serialize()
	if data.is_empty():
		_save_mutex.unlock()
		push_warning("GameState: async save skipped — game state not initialized")
		return
	_save_mutex.unlock()

	_save_thread = Thread.new()
	_save_thread.start(_threaded_save.bind(slot_name, data))


func _threaded_save(slot_name: String, data: Dictionary) -> void:
	if slot_name not in SLOT_NAMES:
		push_error("GameState: invalid slot name: %s" % slot_name)
		return
	var ok := _atomic_write(_slot_path(slot_name), data)
	if not ok:
		push_warning("GameState: async save failed for slot %s" % slot_name)


func save_game(slot_name: String) -> bool:
	if slot_name not in SLOT_NAMES:
		push_error("GameState: invalid slot name: %s" % slot_name)
		return false
	if _save_thread and _save_thread.is_started():
		_save_thread.wait_to_finish()
	var data := _serialize()
	if data.is_empty():
		save_error.emit("Could not save — game state not initialized")
		return false
	var ok := _atomic_write(_slot_path(slot_name), data)
	if not ok:
		save_error.emit("Save failed — please check your device storage")
	return ok


static func _slot_path(slot_name: String) -> String:
	return SAVE_DIR + slot_name + ".json"


static func _backup_path(path: String) -> String:
	return path + SAVE_BACKUP_SUFFIX


static func _tmp_path(path: String) -> String:
	return path + SAVE_TMP_SUFFIX


static func _copy_file(src_path: String, dst_path: String) -> bool:
	if not FileAccess.file_exists(src_path):
		return false
	var src := FileAccess.open(src_path, FileAccess.READ)
	if src == null:
		return false
	var size: int = src.get_length()
	if size <= 0 or size > MAX_SAVE_BYTES:
		src = null
		return false
	var bytes := src.get_buffer(size)
	src = null
	var dst := FileAccess.open(dst_path, FileAccess.WRITE)
	if dst == null:
		return false
	dst.store_buffer(bytes)
	dst = null
	return true


static func _atomic_write(path: String, data: Dictionary) -> bool:
	var payload_text := JSON.stringify(data, "\t")
	var checksum := payload_text.sha256_text()
	var wrapper := {
		"_schema": 1,
		"_saved_at_unix": Time.get_unix_time_from_system(),
		"_checksum": checksum,
		"data": data,
	}
	var json_text := JSON.stringify(wrapper, "\t")
	if json_text.length() > MAX_SAVE_BYTES:
		push_error("GameState: save payload too large (%d bytes)" % json_text.length())
		return false

	var tmp_path := _tmp_path(path)
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("GameState: failed to write temp save: %s" % tmp_path)
		return false
	file.store_string(json_text)
	file = null

	# Roll the previous save into a .bak snapshot first (best effort).
	if FileAccess.file_exists(path):
		var bak_path := _backup_path(path)
		var bak_tmp := _tmp_path(bak_path)
		if _copy_file(path, bak_tmp):
			if FileAccess.file_exists(bak_path):
				DirAccess.remove_absolute(bak_path)
			var bak_err := DirAccess.rename_absolute(bak_tmp, bak_path)
			if bak_err != OK:
				DirAccess.remove_absolute(bak_tmp)
				push_warning("GameState: could not refresh backup (%d)" % bak_err)
		else:
			push_warning("GameState: could not snapshot previous save to backup")

	# Move temp file into place.
	var err := DirAccess.rename_absolute(tmp_path, path)
	if err == ERR_ALREADY_EXISTS:
		DirAccess.remove_absolute(path)
		err = DirAccess.rename_absolute(tmp_path, path)
	if err != OK:
		push_error("GameState: rename failed (%d) %s -> %s" % [err, tmp_path, path])
		DirAccess.remove_absolute(tmp_path)
		return false
	return true


## Reads and validates a save payload from disk.
## Returns {} for any invalid/corrupt/tampered payload.
static func _read_save_data(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("GameState: failed to open save file: %s" % path)
		return {}
	var byte_len: int = file.get_length()
	if byte_len <= 0 or byte_len > MAX_SAVE_BYTES:
		file = null
		push_warning("GameState: save file rejected by size policy (%d bytes)" % byte_len)
		return {}
	var text := file.get_as_text()
	file = null
	var json := JSON.new()
	if json.parse(text) != OK:
		push_warning("GameState: failed to parse save file: %s" % path)
		return {}
	var raw := _safe_dict(json.data)
	if raw.is_empty() and not (json.data is Dictionary):
		push_warning("GameState: save root is not a dictionary: %s" % path)
		return {}

	if raw.has("_checksum") and raw.has("data"):
		var payload := _safe_dict(raw.get("data", {}))
		if payload.is_empty() and not (raw.get("data") is Dictionary):
			push_warning("GameState: save payload is not a dictionary: %s" % path)
			return {}
		var stored_checksum: String = str(raw.get("_checksum", ""))
		var expected := JSON.stringify(payload, "\t").sha256_text()
		if stored_checksum != expected:
			push_warning("GameState: checksum mismatch: %s" % path)
			return {}
		return payload
	return raw


func load_game(slot_name: String) -> bool:
	if slot_name not in SLOT_NAMES:
		push_error("GameState: invalid slot name: %s" % slot_name)
		return false

	var path := _slot_path(slot_name)
	# Prefer primary save; fall back to backup if needed.
	var game_data := _read_save_data(path)
	var used_backup := false
	if game_data.is_empty():
		var bak_path := _backup_path(path)
		game_data = _read_save_data(bak_path)
		used_backup = not game_data.is_empty()

	if game_data.is_empty():
		save_error.emit("Load failed — save is missing or corrupted")
		push_error("GameState: no valid save data found for slot: %s" % slot_name)
		return false

	if not _deserialize(game_data):
		if not used_backup:
			var fallback := _read_save_data(_backup_path(path))
			if not fallback.is_empty() and _deserialize(fallback):
				push_warning("GameState: recovered slot %s via backup after deserialize failure" % slot_name)
				_atomic_write(path, fallback)
				return true
		save_error.emit("Load failed — save format is invalid")
		return false

	if used_backup:
		push_warning("GameState: recovered slot %s from backup file" % slot_name)
		_atomic_write(path, game_data)
	return true


func has_save(slot_name: String) -> bool:
	if slot_name not in SLOT_NAMES:
		return false
	var path := _slot_path(slot_name)
	return FileAccess.file_exists(path) or FileAccess.file_exists(_backup_path(path))


func latest_save_slot() -> String:
	var best_slot := ""
	var best_mtime: int = -1
	for slot_name in SLOT_NAMES:
		var info := peek_save(slot_name)
		if not bool(info.get("exists", false)):
			continue

		var primary_path := _slot_path(slot_name)
		var backup_path := _backup_path(primary_path)
		var slot_mtime: int = -1
		if FileAccess.file_exists(primary_path):
			slot_mtime = maxi(slot_mtime, int(FileAccess.get_modified_time(primary_path)))
		if FileAccess.file_exists(backup_path):
			slot_mtime = maxi(slot_mtime, int(FileAccess.get_modified_time(backup_path)))
		if slot_mtime > best_mtime:
			best_mtime = slot_mtime
			best_slot = slot_name
	return best_slot


func _serialize() -> Dictionary:
	if company == null or product == null or financials == null or market == null:
		push_error("GameState: cannot serialize — game state not initialized")
		return {}

	var emp_list: Array[Dictionary] = []
	for emp in employees:
		emp.ensure_uid()
		emp_list.append({
			"name": emp.employee_name,
			"uid": emp.employee_uid,
			"specialty": emp.specialty,
			"seniority": emp.seniority,
			"skill": emp.skill,
			"speed": emp.speed,
			"growth_potential": emp.growth_potential,
			"salary": emp.salary_per_quarter,
			"morale": emp.morale,
			"stress": emp.stress,
			"culture_fit": emp.culture_fit,
			"tenure": emp.tenure_quarters,
			"assignment": emp.assignment,
			"employment_type": emp.employment_type,
			"personality": emp.personality,
			"quarter_history": emp.quarter_history.duplicate(true),
		})

	return {
		"version": 1,
		"company": {
			"name": company.company_name,
			"type": company.type,
			"cash": company.cash,
			"valuation": company.valuation,
			"equity": company.equity_owned,
			"office_level": company.office_level,
			"reputation": company.reputation,
			"founder_background": company.founder_background,
			"founder_stats": company.founder_stats.duplicate(true),
			"niche_id": company.niche_id,
			"niche_name": company.niche_name,
			"niche_desc": company.niche_desc,
			"niche_growth_mult": company.niche_growth_mult,
			"niche_churn_mult": company.niche_churn_mult,
			"niche_revenue_mult": company.niche_revenue_mult,
			"hosting_plan": company.hosting_plan,
			"hosting_reliability": company.hosting_reliability,
			"hosting_demand_web": company.hosting_demand_web,
			"hosting_demand_cache": company.hosting_demand_cache,
			"hosting_demand_data": company.hosting_demand_data,
			"hosting_capacity_web": company.hosting_capacity_web,
			"hosting_capacity_cache": company.hosting_capacity_cache,
			"hosting_capacity_data": company.hosting_capacity_data,
			"hosting_util_web": company.hosting_util_web,
			"hosting_util_cache": company.hosting_util_cache,
			"hosting_util_data": company.hosting_util_data,
			"hosting_overage_cost": company.hosting_overage_cost,
			"hosting_incidents_last_quarter": company.hosting_incidents_last_quarter,
			"hosting_upgrade_web_level": company.hosting_upgrade_web_level,
			"hosting_upgrade_cache_level": company.hosting_upgrade_cache_level,
			"hosting_upgrade_data_level": company.hosting_upgrade_data_level,
			"hosting_optimization_level": company.hosting_optimization_level,
			"hosting_workload_profile": company.hosting_workload_profile,
			"hosting_data_center_pressure": company.hosting_data_center_pressure,
		},
		"product": {
			"features": product.features.duplicate(),
			"tech_debt": product.tech_debt,
			"bugs": product.bugs,
			"stability": product.stability,
			"ux_score": product.ux_score,
			"users": product.users,
			"dau": product.dau,
			"churn_rate": product.churn_rate,
			"feature_progress": product.feature_progress,
			"target_feature_id": product.target_feature_id,
			"revenue_mult": product.revenue_mult,
			"user_growth_flat_bonus": product.user_growth_flat_bonus,
			"dau_bonus": product.dau_bonus,
		},
		"financials": {
			"revenue": financials.revenue,
			"burn_rate": financials.burn_rate,
			"costs": financials.costs_breakdown.duplicate(true),
			"funding_rounds": financials.funding_rounds.duplicate(true),
			"investors": financials.investors.duplicate(true),
		},
		"market": {
			"competitors": market.competitors.duplicate(true),
			"trend": market.market_trend,
			"economy": market.economy_state,
		},
		"world_event": {
			"id": active_world_event_id,
			"title": active_world_event_title,
			"description": active_world_event_description,
			"quarters_left": active_world_event_quarters_left,
			"effects": active_world_event_effects.duplicate(true),
		},
		"employees": emp_list,
		"quarter": current_quarter,
		"year": current_year,
		"difficulty": difficulty,
		"scenario": starting_scenario,
		"history": _compact_history_for_save(),
		"event_log": _compact_event_log_for_save(),
		"fired_events": fired_one_time_events.duplicate(),
		"milestones_hit": _milestones_hit.duplicate(),
		"achieved_wins": _achieved_wins.duplicate(),
		"interviewer_busy_quarters": interviewer_busy_quarters.duplicate(true),
		"angel_bailout_used": angel_bailout_used,
		"profit_streak": profit_streak,
		"founder_energy": founder_energy,
		"board_patience": board_patience,
	}


func _deserialize(data: Dictionary) -> bool:
	var version := int(data.get("version", 0))
	if version != 1:
		push_error("GameState: unsupported save version")
		return false

	company = CompanyData.new()
	var cd: Dictionary = _safe_dict(data.get("company", {}))
	company.company_name = cd.get("name", "")
	company.type = cd.get("type", 0)
	company.cash = cd.get("cash", 0.0)
	company.valuation = cd.get("valuation", 0.0)
	company.equity_owned = cd.get("equity", 100.0)
	company.office_level = cd.get("office_level", 0)
	company.reputation = cd.get("reputation", 50)
	company.founder_background = cd.get("founder_background", 0) as CompanyData.FounderBackground
	company.founder_stats = _safe_dict(cd.get("founder_stats", {"technical": 5, "finance": 5, "people": 5, "business": 5}))
	if company.founder_stats.is_empty():
		company.founder_stats = {"technical": 5, "finance": 5, "people": 5, "business": 5}
	company.niche_id = str(cd.get("niche_id", ""))
	company.niche_name = str(cd.get("niche_name", ""))
	company.niche_desc = str(cd.get("niche_desc", ""))
	company.niche_growth_mult = float(cd.get("niche_growth_mult", 1.0))
	company.niche_churn_mult = float(cd.get("niche_churn_mult", 1.0))
	company.niche_revenue_mult = float(cd.get("niche_revenue_mult", 1.0))
	company.hosting_plan = int(cd.get("hosting_plan", CompanyData.HostingPlan.MANAGED_CLOUD)) as CompanyData.HostingPlan
	company.hosting_reliability = float(cd.get("hosting_reliability", 99.5))
	company.hosting_demand_web = float(cd.get("hosting_demand_web", 0.0))
	company.hosting_demand_cache = float(cd.get("hosting_demand_cache", 0.0))
	company.hosting_demand_data = float(cd.get("hosting_demand_data", 0.0))
	company.hosting_capacity_web = float(cd.get("hosting_capacity_web", 0.0))
	company.hosting_capacity_cache = float(cd.get("hosting_capacity_cache", 0.0))
	company.hosting_capacity_data = float(cd.get("hosting_capacity_data", 0.0))
	company.hosting_util_web = float(cd.get("hosting_util_web", 0.0))
	company.hosting_util_cache = float(cd.get("hosting_util_cache", 0.0))
	company.hosting_util_data = float(cd.get("hosting_util_data", 0.0))
	company.hosting_overage_cost = float(cd.get("hosting_overage_cost", 0.0))
	company.hosting_incidents_last_quarter = int(cd.get("hosting_incidents_last_quarter", 0))
	company.hosting_upgrade_web_level = int(cd.get("hosting_upgrade_web_level", 0))
	company.hosting_upgrade_cache_level = int(cd.get("hosting_upgrade_cache_level", 0))
	company.hosting_upgrade_data_level = int(cd.get("hosting_upgrade_data_level", 0))
	company.hosting_optimization_level = int(cd.get("hosting_optimization_level", 0))
	company.hosting_workload_profile = str(cd.get("hosting_workload_profile", "General Cloud"))
	company.hosting_data_center_pressure = float(cd.get("hosting_data_center_pressure", 0.0))
	if company.niche_name.strip_edges().is_empty() and not company.niche_id.strip_edges().is_empty():
		CompanyData.load_niche_catalog()
		company.apply_niche(company.niche_id)

	product = ProductData.new()
	var pd: Dictionary = _safe_dict(data.get("product", {}))
	product.features.assign(_safe_array(pd.get("features", [])))
	product.tech_debt = pd.get("tech_debt", 0)
	product.bugs = pd.get("bugs", 0)
	product.stability = pd.get("stability", 80)
	product.ux_score = pd.get("ux_score", 50)
	product.users = pd.get("users", 0)
	product.dau = pd.get("dau", 0)
	product.churn_rate = pd.get("churn_rate", 0.05)
	product.feature_progress = float(pd.get("feature_progress", 0.0))
	product.target_feature_id = pd.get("target_feature_id", "")
	product.revenue_mult = pd.get("revenue_mult", 1.0)
	product.user_growth_flat_bonus = pd.get("user_growth_flat_bonus", 0)
	product.dau_bonus = pd.get("dau_bonus", 0.0)

	financials = FinancialsData.new()
	var fd: Dictionary = _safe_dict(data.get("financials", {}))
	financials.revenue = fd.get("revenue", 0.0)
	financials.burn_rate = fd.get("burn_rate", 0.0)
	financials.costs_breakdown = _safe_dict(fd.get("costs", {}))
	financials.funding_rounds.assign(_safe_array(fd.get("funding_rounds", [])))
	financials.investors.assign(_safe_array(fd.get("investors", [])))

	market = MarketData.new()
	var md: Dictionary = _safe_dict(data.get("market", {}))
	market.competitors.assign(_safe_array(md.get("competitors", [])))
	market.market_trend = md.get("trend", 0)
	market.economy_state = md.get("economy", 0)

	var wd: Dictionary = _safe_dict(data.get("world_event", {}))
	active_world_event_id = str(wd.get("id", ""))
	active_world_event_title = str(wd.get("title", ""))
	active_world_event_description = str(wd.get("description", ""))
	active_world_event_quarters_left = int(wd.get("quarters_left", 0))
	active_world_event_effects = _safe_dict(wd.get("effects", {}))

	employees.clear()
	for raw_emp in _safe_array(data.get("employees", [])):
		var ed: Dictionary = _safe_dict(raw_emp)
		if ed.is_empty():
			continue
		var emp := EmployeeData.new()
		emp.employee_name = ed.get("name", "")
		emp.employee_uid = str(ed.get("uid", ""))
		emp.ensure_uid()
		emp.specialty = ed.get("specialty", 0)
		emp.seniority = ed.get("seniority", 0)
		emp.skill = ed.get("skill", 50)
		emp.speed = ed.get("speed", 50)
		emp.growth_potential = ed.get("growth_potential", 1)
		emp.salary_per_quarter = ed.get("salary", 20_000.0)
		emp.morale = ed.get("morale", 75)
		emp.stress = ed.get("stress", 0)
		emp.culture_fit = ed.get("culture_fit", 50)
		emp.tenure_quarters = ed.get("tenure", 0)
		emp.assignment = ed.get("assignment", EmployeeData.Assignment.UNASSIGNED)
		emp.employment_type = ed.get("employment_type", EmployeeData.EmploymentType.FULL_TIME)
		emp.personality = ed.get("personality", EmployeeData.Personality.STEADY)
		emp.quarter_history.assign(_dict_array(ed.get("quarter_history", [])))
		employees.append(emp)

	current_quarter = data.get("quarter", 1)
	current_year = data.get("year", 1)
	difficulty = data.get("difficulty", "normal")
	starting_scenario = data.get("scenario", "garage")
	history.assign(_dict_array(data.get("history", [])))
	event_log.assign(_dict_array(data.get("event_log", [])))
	fired_one_time_events.assign(_string_array(data.get("fired_events", [])))
	_milestones_hit.assign(_string_array(data.get("milestones_hit", [])))
	_achieved_wins.assign(_string_array(data.get("achieved_wins", [])))
	interviewer_busy_quarters = _safe_dict(data.get("interviewer_busy_quarters", {}))
	angel_bailout_used = data.get("angel_bailout_used", false)
	profit_streak = data.get("profit_streak", 0)
	founder_energy = data.get("founder_energy", 100)
	board_patience = data.get("board_patience", 4)

	_clamp_deserialized_values()
	is_game_active = true
	return true


func _clamp_deserialized_values() -> void:
	company.company_name = str(company.company_name).strip_edges()
	if company.company_name.is_empty():
		company.company_name = "My Startup"
	elif company.company_name.length() > 64:
		company.company_name = company.company_name.substr(0, 64)

	company.type = clampi(company.type, 0, 3)
	company.founder_background = clampi(company.founder_background, 0, 3) as CompanyData.FounderBackground
	company.cash = clampf(company.cash, -1_000_000.0, 1e12)
	company.valuation = clampf(company.valuation, 0.0, 1e13)
	company.equity_owned = clampf(company.equity_owned, 0.0, 100.0)
	company.reputation = clampi(company.reputation, 0, 100)
	company.office_level = clampi(company.office_level, 0, 10)
	company.niche_id = company.niche_id.strip_edges()
	company.niche_name = company.niche_name.strip_edges()
	company.niche_desc = company.niche_desc.strip_edges()
	company.niche_growth_mult = clampf(company.niche_growth_mult, 0.5, 2.0)
	company.niche_churn_mult = clampf(company.niche_churn_mult, 0.5, 2.0)
	company.niche_revenue_mult = clampf(company.niche_revenue_mult, 0.5, 2.0)
	company.hosting_plan = clampi(company.hosting_plan, 0, 2) as CompanyData.HostingPlan
	company.hosting_reliability = clampf(company.hosting_reliability, 60.0, 99.99)
	company.hosting_demand_web = clampf(company.hosting_demand_web, 0.0, 1e12)
	company.hosting_demand_cache = clampf(company.hosting_demand_cache, 0.0, 1e12)
	company.hosting_demand_data = clampf(company.hosting_demand_data, 0.0, 1e12)
	company.hosting_capacity_web = clampf(company.hosting_capacity_web, 0.0, 1e12)
	company.hosting_capacity_cache = clampf(company.hosting_capacity_cache, 0.0, 1e12)
	company.hosting_capacity_data = clampf(company.hosting_capacity_data, 0.0, 1e12)
	company.hosting_util_web = clampf(company.hosting_util_web, 0.0, 5.0)
	company.hosting_util_cache = clampf(company.hosting_util_cache, 0.0, 5.0)
	company.hosting_util_data = clampf(company.hosting_util_data, 0.0, 5.0)
	company.hosting_overage_cost = clampf(company.hosting_overage_cost, 0.0, 1e12)
	company.hosting_incidents_last_quarter = clampi(company.hosting_incidents_last_quarter, 0, 99)
	company.hosting_upgrade_web_level = clampi(company.hosting_upgrade_web_level, 0, CompanyData.HOSTING_LANE_UPGRADE_MAX)
	company.hosting_upgrade_cache_level = clampi(company.hosting_upgrade_cache_level, 0, CompanyData.HOSTING_LANE_UPGRADE_MAX)
	company.hosting_upgrade_data_level = clampi(company.hosting_upgrade_data_level, 0, CompanyData.HOSTING_LANE_UPGRADE_MAX)
	company.hosting_optimization_level = clampi(company.hosting_optimization_level, 0, CompanyData.HOSTING_OPTIMIZATION_MAX)
	company.hosting_workload_profile = str(company.hosting_workload_profile).strip_edges()
	if company.hosting_workload_profile.is_empty():
		company.hosting_workload_profile = "General Cloud"
	company.hosting_data_center_pressure = clampf(company.hosting_data_center_pressure, 0.0, 3.0)
	for stat_key in ["technical", "finance", "people", "business"]:
		company.founder_stats[stat_key] = clampi(int(company.founder_stats.get(stat_key, 5)), 1, 10)

	product.tech_debt = clampi(product.tech_debt, 0, 100)
	product.bugs = maxi(0, product.bugs)
	product.stability = clampi(product.stability, 0, 100)
	product.ux_score = clampi(product.ux_score, 0, 100)
	product.users = clampi(product.users, 0, 1_000_000_000)
	product.dau = clampi(product.dau, 0, product.users)
	product.churn_rate = clampf(product.churn_rate, 0.0, 1.0)
	product.feature_progress = clampf(product.feature_progress, 0.0, 1e9)
	product.revenue_mult = clampf(product.revenue_mult, 0.01, 100.0)
	product.dau_bonus = clampf(product.dau_bonus, 0.0, 1.0)

	financials.revenue = maxf(0.0, financials.revenue)
	financials.burn_rate = maxf(0.0, financials.burn_rate)
	for k in ["salaries", "infrastructure", "hosting", "office", "marketing", "legal", "tools"]:
		financials.costs_breakdown[k] = maxf(0.0, float(financials.costs_breakdown.get(k, 0.0)))

	current_quarter = clampi(current_quarter, 1, 4)
	current_year = maxi(1, current_year)
	if not DIFFICULTY_MULTS.has(difficulty):
		difficulty = "normal"

	founder_energy = clampi(founder_energy, 0, 200)
	board_patience = clampi(board_patience, 0, 20)
	profit_streak = maxi(0, profit_streak)
	active_world_event_id = active_world_event_id.strip_edges()
	active_world_event_title = active_world_event_title.strip_edges()
	active_world_event_description = active_world_event_description.strip_edges()
	if active_world_event_title.length() > 96:
		active_world_event_title = active_world_event_title.substr(0, 96)
	if active_world_event_description.length() > 260:
		active_world_event_description = active_world_event_description.substr(0, 260)
	active_world_event_quarters_left = clampi(active_world_event_quarters_left, 0, 8)
	var cleaned_world_effects: Dictionary = {}
	for raw_key in active_world_event_effects.keys():
		var key := str(raw_key).strip_edges()
		if key.is_empty():
			continue
		var value_raw = active_world_event_effects.get(raw_key, 1.0)
		if value_raw is int or value_raw is float:
			cleaned_world_effects[key] = clampf(float(value_raw), 0.25, 3.0)
	active_world_event_effects = cleaned_world_effects
	if active_world_event_quarters_left <= 0 or active_world_event_title.is_empty():
		clear_world_event_state()

	market.economy_state = clampi(market.economy_state, 0, 2)

	if employees.size() > MAX_EMPLOYEES:
		employees = employees.slice(0, MAX_EMPLOYEES)
	if history.size() > MAX_HISTORY_SIZE:
		history = history.slice(-MAX_HISTORY_SIZE)
	if event_log.size() > MAX_EVENT_LOG_SIZE:
		event_log = event_log.slice(-MAX_EVENT_LOG_SIZE)

	var seen_uids: Dictionary = {}
	for emp in employees:
		emp.employee_name = str(emp.employee_name).strip_edges()
		if emp.employee_name.is_empty():
			emp.employee_name = "Employee"
		elif emp.employee_name.length() > 64:
			emp.employee_name = emp.employee_name.substr(0, 64)
		emp.ensure_uid()
		while seen_uids.has(emp.employee_uid):
			emp.employee_uid = EmployeeData._generate_uid()
		seen_uids[emp.employee_uid] = true
		emp.specialty = clampi(emp.specialty, 0, 8)
		emp.seniority = clampi(emp.seniority, 0, 4)
		emp.assignment = clampi(emp.assignment, 0, 5) as EmployeeData.Assignment
		emp.growth_potential = clampi(emp.growth_potential, 0, 2)
		emp.skill = clampi(emp.skill, 1, 100)
		emp.speed = clampi(emp.speed, 1, 100)
		emp.morale = clampi(emp.morale, 0, 100)
		emp.stress = clampi(emp.stress, 0, 100)
		emp.culture_fit = clampi(emp.culture_fit, 0, 100)
		emp.salary_per_quarter = clampf(emp.salary_per_quarter, 0.0, 1_000_000.0)
		emp.employment_type = clampi(emp.employment_type, 0, 2) as EmployeeData.EmploymentType
		emp.personality = clampi(emp.personality, 0, 5) as EmployeeData.Personality
		if emp.quarter_history.size() > 36:
			emp.quarter_history = emp.quarter_history.slice(-36)
		emp.clamp_all()

	var cleaned_busy: Dictionary = {}
	for uid_raw in interviewer_busy_quarters.keys():
		var uid := str(uid_raw).strip_edges()
		if uid.is_empty() or not seen_uids.has(uid):
			continue
		var q := clampi(int(interviewer_busy_quarters.get(uid_raw, 0)), 0, 4)
		if q > 0:
			cleaned_busy[uid] = q
	interviewer_busy_quarters = cleaned_busy

	var dedup_wins: Dictionary = {}
	var valid_wins := ["ipo", "unicorn", "sustainable", "acquisition"]
	for w in _achieved_wins:
		var key := str(w).strip_edges().to_lower()
		if key in valid_wins:
			dedup_wins[key] = true
	_achieved_wins.assign(_string_array(dedup_wins.keys()))


# --- Slot Management ---

func list_saves() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []
	for slot in SLOT_NAMES:
		var info := peek_save(slot)
		info["slot"] = slot
		saves.append(info)
	return saves


func peek_save(slot_name: String) -> Dictionary:
	if slot_name not in SLOT_NAMES:
		return {"exists": false}

	var path := _slot_path(slot_name)
	var data := _read_save_data(path)
	var from_backup := false
	if data.is_empty():
		data = _read_save_data(_backup_path(path))
		from_backup = not data.is_empty()
	if data.is_empty():
		return {"exists": false}

	var cd: Dictionary = _safe_dict(data.get("company", {}))
	var pd: Dictionary = _safe_dict(data.get("product", {}))
	var fd: Dictionary = _safe_dict(data.get("financials", {}))
	var emp_count := _safe_array(data.get("employees", [])).size()

	return {
		"exists": true,
		"from_backup": from_backup,
		"company_name": cd.get("name", "Unknown"),
		"company_type": cd.get("type", 0),
		"cash": cd.get("cash", 0.0),
		"users": pd.get("users", 0),
		"quarter": data.get("quarter", 1),
		"year": data.get("year", 1),
		"difficulty": data.get("difficulty", "normal"),
		"revenue": fd.get("revenue", 0.0),
		"employees": emp_count,
	}


func delete_save(slot_name: String) -> void:
	if slot_name not in SLOT_NAMES:
		push_error("GameState: invalid slot name for delete: %s" % slot_name)
		return
	var path := _slot_path(slot_name)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var tmp_path := _tmp_path(path)
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(tmp_path)
	var bak_path := _backup_path(path)
	if FileAccess.file_exists(bak_path):
		DirAccess.remove_absolute(bak_path)
	var bak_tmp_path := _tmp_path(bak_path)
	if FileAccess.file_exists(bak_tmp_path):
		DirAccess.remove_absolute(bak_tmp_path)
	if current_slot == slot_name:
		current_slot = ""
		_clear_run_state()


func _clear_run_state() -> void:
	company = null
	product = null
	financials = null
	market = null
	employees.clear()
	history.clear()
	event_log.clear()
	fired_one_time_events.clear()
	pending_events.clear()
	clear_world_event_state()
	_milestones_hit.clear()
	_achieved_wins.clear()
	interviewer_busy_quarters.clear()
	angel_bailout_used = false
	profit_streak = 0
	founder_energy = 100
	board_patience = 4
	current_quarter = 1
	current_year = 1
	is_game_active = false
