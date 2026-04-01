class_name SimulationEngine
extends RefCounted
## Runs one quarter of simulation.

const BASE_ORGANIC_USERS_PER_QUARTER := 10
const MARKETING_USER_MULT := 0.5

const DEFAULT_GROWTH_BALANCE := {
	"maturity_start_users": 25_000.0,
	"maturity_full_users": 500_000.0,
	"maturity_target_mult": 0.62,
	"maturity_floor_mult": 0.55,
	"expansion_bonus_mult": 3.0,
	"late_churn_users": 50_000,
	"late_churn_ux_threshold": 60,
	"late_churn_penalty_rate": 0.003,
}

const GROWTH_BALANCE_BY_TYPE := {
	CompanyData.CompanyType.SAAS: {
		"maturity_start_users": 35_000.0,
		"maturity_full_users": 480_000.0,
		"maturity_target_mult": 0.70,
		"maturity_floor_mult": 0.60,
		"expansion_bonus_mult": 3.4,
		"late_churn_users": 90_000,
		"late_churn_ux_threshold": 55,
		"late_churn_penalty_rate": 0.0018,
	},
	CompanyData.CompanyType.CONSUMER: {
		"maturity_start_users": 22_000.0,
		"maturity_full_users": 420_000.0,
		"maturity_target_mult": 0.60,
		"maturity_floor_mult": 0.52,
		"expansion_bonus_mult": 3.0,
		"late_churn_users": 45_000,
		"late_churn_ux_threshold": 62,
		"late_churn_penalty_rate": 0.0035,
	},
	CompanyData.CompanyType.MARKETPLACE: {
		"maturity_start_users": 30_000.0,
		"maturity_full_users": 500_000.0,
		"maturity_target_mult": 0.64,
		"maturity_floor_mult": 0.56,
		"expansion_bonus_mult": 3.5,
		"late_churn_users": 70_000,
		"late_churn_ux_threshold": 58,
		"late_churn_penalty_rate": 0.0025,
	},
	CompanyData.CompanyType.DEV_TOOLS: {
		"maturity_start_users": 26_000.0,
		"maturity_full_users": 380_000.0,
		"maturity_target_mult": 0.67,
		"maturity_floor_mult": 0.58,
		"expansion_bonus_mult": 3.1,
		"late_churn_users": 55_000,
		"late_churn_ux_threshold": 60,
		"late_churn_penalty_rate": 0.0028,
	},
}

static var _feature_names := [
	"User Dashboard", "Search", "Notifications", "Analytics",
	"API v2", "Mobile View", "Export", "Integrations",
	"Admin Panel", "Onboarding Flow", "Settings Page", "Reports",
	"Multi-tenancy", "SSO Login", "Audit Log", "Billing",
]


static func process_quarter(state: Node) -> void:
	_apply_work_output(state)
	_update_product_metrics(state)
	_calculate_user_growth(state)
	_calculate_revenue(state)
	_update_valuation(state)
	_calculate_costs(state)
	_update_cash(state)
	_run_competitor_ai(state)
	_update_economy(state)
	_roll_events(state)
	_update_employee_morale(state)
	_process_employee_turnover(state)
	_grow_employee_skills(state)
	_update_founder_energy(state)
	_update_board_patience(state)
	_clamp_all_state(state)


static func _growth_balance(company_type: int) -> Dictionary:
	var cfg := GROWTH_BALANCE_BY_TYPE.get(company_type, DEFAULT_GROWTH_BALANCE)
	return cfg if cfg is Dictionary else DEFAULT_GROWTH_BALANCE


static func _apply_work_output(state: Node) -> void:
	if state.employees.is_empty():
		return

	for emp: EmployeeData in state.employees:
		# Employees assigned as interviewers are unavailable for normal work output
		# this quarter (opportunity cost of deeper interview process).
		if state.is_interviewer_busy(emp.employee_uid):
			state.consume_interviewer_busy_quarter(emp.employee_uid)
			emp.tenure_quarters += 1
			continue

		if emp.assignment == EmployeeData.Assignment.UNASSIGNED:
			emp.tenure_quarters += 1
			continue

		var spec_mult: float = EmployeeData.specialty_mult(emp.specialty, emp.assignment, state.company.type)
		var output: float = emp.work_output() * state.product.dev_speed_multiplier() * spec_mult
		var tech_bonus: float = state.company.founder_stat("technical") * 0.05

		match emp.assignment:
			EmployeeData.Assignment.FEATURES:
				var target_def: Dictionary = state.product.get_target_feature(state.company.type)
				if target_def.is_empty() and state.product.target_feature_id.is_empty():
					var available: Array[Dictionary] = state.product.available_features(state.company.type)
					if available.is_empty():
						continue
				var cost: float = float(target_def.get("cost", ProductData.FEATURE_COST))
				state.product.feature_progress += output * 0.5
				if state.product.feature_progress >= cost:
					state.product.feature_progress -= cost
					var quality := clampi(ceili(output * 0.8) + randi_range(-10, 10) + roundi(tech_bonus * 5), 20, 100)
					var fname: String = target_def.get("name", _feature_names.pick_random())
					var fid: String = target_def.get("id", "")
					state.product.add_feature(fname, quality, state.current_quarter, fid)
					if not target_def.is_empty():
						state.product.apply_feature_effects(target_def)
					state.product.target_feature_id = ""
			EmployeeData.Assignment.BUGS:
				var bug_mult := 1.0 + tech_bonus
				state.product.bugs = maxi(0, state.product.bugs - maxi(1, ceili(output * 0.1 * bug_mult)))
			EmployeeData.Assignment.TECH_DEBT:
				state.product.tech_debt = maxi(0, state.product.tech_debt - maxi(1, ceili(output * 0.05)))
			EmployeeData.Assignment.INFRA:
				state.product.stability = mini(100, state.product.stability + maxi(1, ceili(output * 0.05)))
			EmployeeData.Assignment.RND:
				state.product.ux_score = mini(100, state.product.ux_score + maxi(0, ceili(output * 0.02)))
		emp.tenure_quarters += 1


static func _update_product_metrics(state: Node) -> void:
	if state.product.tech_debt > 75:
		state.product.bugs += randi_range(2, 5)
	elif state.product.tech_debt > 50:
		state.product.bugs += randi_range(1, 3)

	if state.product.stability < 30:
		state.product.churn_rate += 0.02
	elif state.product.stability < 50:
		state.product.churn_rate += 0.005
	elif state.product.stability > 80:
		state.product.churn_rate = maxf(ProductData.CHURN_RATE_MIN, state.product.churn_rate - 0.005)

	if state.product.bugs > 20:
		state.product.churn_rate += 0.01


static func _calculate_user_growth(state: Node) -> void:
	var quality_factor: float = state.product.avg_feature_quality() / 100.0
	var feature_pull := minf(state.product.feature_count() * 0.5, 5.0)
	var reputation_bonus: float = state.company.reputation / 100.0

	var biz_bonus: float = 1.0 + state.company.founder_stat("business") * 0.04
	var base_new := BASE_ORGANIC_USERS_PER_QUARTER + ceili(feature_pull * 5)
	var organic_rate := remap(quality_factor, 0.0, 1.0, 0.01, 0.05)

	match state.company.type:
		CompanyData.CompanyType.SAAS:
			organic_rate *= 0.7
			if state.product.feature_count() >= 3:
				organic_rate *= 1.4
		CompanyData.CompanyType.CONSUMER:
			base_new = ceili(base_new * 1.6)
			organic_rate *= 1.3
		CompanyData.CompanyType.MARKETPLACE:
			if state.product.users < 500:
				organic_rate *= 0.4
			else:
				organic_rate *= 1.5
		CompanyData.CompanyType.DEV_TOOLS:
			organic_rate *= 0.6
			reputation_bonus *= 1.8

	var growth_from_existing := ceili(state.product.users * organic_rate * biz_bonus)
	var reputation_pull := ceili(base_new * reputation_bonus * biz_bonus)
	var feature_bonus: int = state.product.user_growth_flat_bonus
	var total_new := maxi(0, base_new + growth_from_existing + reputation_pull + feature_bonus)

	var econ_growth_mult: float
	var econ_churn_mult: float
	match state.market.economy_state:
		MarketData.EconomyState.BULL:
			econ_growth_mult = 1.2
			econ_churn_mult = 0.8
		MarketData.EconomyState.BEAR:
			econ_growth_mult = 0.7
			econ_churn_mult = 1.3
		_:
			econ_growth_mult = 1.0
			econ_churn_mult = 1.0

	total_new = ceili(total_new * econ_growth_mult)

	# Growth naturally gets harder at scale; early game stays punchy.
	# Per-type thresholds keep each company archetype on a believable trajectory.
	var balance := _growth_balance(state.company.type)
	var maturity_start := float(balance.get("maturity_start_users", 25_000.0))
	var maturity_full := maxf(maturity_start + 1.0, float(balance.get("maturity_full_users", 500_000.0)))
	var maturity_target_mult := float(balance.get("maturity_target_mult", 0.62))
	var maturity_floor := float(balance.get("maturity_floor_mult", 0.55))
	var expansion_bonus_mult := float(balance.get("expansion_bonus_mult", 3.0))
	if state.product.users > maturity_start:
		var maturity_mult := remap(float(state.product.users), maturity_start, maturity_full, 1.0, maturity_target_mult)
		total_new = ceili(total_new * clampf(maturity_mult, maturity_floor, 1.0))
		# Great product quality/stability helps beat maturity headwinds.
		var expansion_quality := clampf((state.product.ux_score / 100.0) * (state.product.stability / 100.0), 0.4, 1.0)
		var expansion_bonus := ceili(feature_pull * expansion_bonus_mult * expansion_quality)
		total_new += expansion_bonus

	var type_churn_mult := 1.0
	match state.company.type:
		CompanyData.CompanyType.SAAS:
			if state.product.feature_count() >= 5:
				type_churn_mult = 0.7
		CompanyData.CompanyType.CONSUMER:
			type_churn_mult = 1.4
		CompanyData.CompanyType.MARKETPLACE:
			if state.product.users >= 500:
				type_churn_mult = 0.8
		CompanyData.CompanyType.DEV_TOOLS:
			type_churn_mult = 0.9

	var difficulty_churn_mult := 1.0
	if state.has_method("difficulty_mult"):
		difficulty_churn_mult = clampf(float(state.difficulty_mult("churn_mult")), 0.4, 2.0)

	var churn_count := ceili(state.product.users * state.product.churn_rate * econ_churn_mult * type_churn_mult * difficulty_churn_mult)
	var bug_churn := ceili(state.product.bugs * 0.5)
	var total_churn := churn_count + bug_churn
	var late_churn_users := int(balance.get("late_churn_users", 50_000))
	var late_churn_ux := int(balance.get("late_churn_ux_threshold", 60))
	var late_churn_rate := float(balance.get("late_churn_penalty_rate", 0.003))
	if state.product.users > late_churn_users and state.product.ux_score < late_churn_ux:
		# Retention discipline matters more as audience size grows.
		total_churn += ceili(state.product.users * late_churn_rate)

	state.product.users = maxi(0, state.product.users + total_new - total_churn)

	var dau_ratio: float = 0.3 - state.product.bugs * 0.002 + state.product.dau_bonus
	match state.company.type:
		CompanyData.CompanyType.CONSUMER:
			dau_ratio += 0.1
		CompanyData.CompanyType.DEV_TOOLS:
			dau_ratio -= 0.05
	state.product.dau = maxi(0, ceili(state.product.users * clampf(dau_ratio, 0.05, 0.7)))


static func _calculate_revenue(state: Node) -> void:
	state.financials.revenue = RevenueEngine.calculate(state.company, state.product)


static func _update_valuation(state: Node) -> void:
	state.company.valuation = ValuationEngine.estimate(state)


static func _calculate_costs(state: Node) -> void:
	var salary_total := 0.0
	for emp: EmployeeData in state.employees:
		salary_total += emp.salary_per_quarter
	state.financials.costs_breakdown["salaries"] = salary_total

	var finance_discount: float = 1.0 - state.company.founder_stat("finance") * 0.02
	var infra_cost := maxf(10.0, state.product.users * 0.01) * maxf(0.6, finance_discount)
	state.financials.costs_breakdown["infrastructure"] = infra_cost

	var office_cost := [0.0, 2_000.0, 5_000.0, 12_000.0]
	state.financials.costs_breakdown["office"] = office_cost[clampi(state.company.office_level, 0, 3)]

	state.financials.burn_rate = state.financials.total_costs()


static func _update_cash(state: Node) -> void:
	state.company.cash += state.financials.net_income()


static func _run_competitor_ai(state: Node) -> void:
	var growth_mult := 1.0
	if state.has_method("difficulty_mult"):
		growth_mult = clampf(float(state.difficulty_mult("competitor_mult")), 0.5, 2.5)
	CompetitorAI.step(state.market, growth_mult)


static func _update_economy(state: Node) -> void:
	if randf() > 0.12:
		return

	var old_state: MarketData.EconomyState = state.market.economy_state
	var direction := randi_range(-1, 1)
	var new_val := clampi(int(old_state) + direction, 0, 2)
	var new_state: MarketData.EconomyState = new_val as MarketData.EconomyState

	if new_state == old_state:
		return

	state.market.economy_state = new_state
	var label: String
	match new_state:
		MarketData.EconomyState.BULL:
			label = "Bull market — investors are optimistic, valuations rising"
		MarketData.EconomyState.NEUTRAL:
			if old_state == MarketData.EconomyState.BULL:
				label = "Markets cooling off — back to normal conditions"
			else:
				label = "Economy stabilizing — worst may be over"
		MarketData.EconomyState.BEAR:
			label = "Bear market — funding dries up, growth slows across the sector"
		_:
			label = "Economic shift"

	state.append_event_log({
		"quarter": state.current_quarter,
		"year": state.current_year,
		"event_id": "economy_shift",
		"title": label,
	})


static func _roll_events(state: Node) -> void:
	var events := EventEngine.roll_quarter_events(state)
	for ev in events:
		state.event_triggered.emit(ev)
		state.append_event_log({
			"quarter": state.current_quarter,
			"year": state.current_year,
			"event_id": ev.id,
			"title": ev.title,
		})


static func _update_employee_morale(state: Node) -> void:
	var people_shield: int = roundi(state.company.founder_stat("people") * 0.3)

	for emp: EmployeeData in state.employees:
		if emp.stress > 70:
			emp.morale -= maxi(1, randi_range(5, 12) - people_shield)
		elif emp.stress > 50:
			emp.morale -= maxi(0, randi_range(2, 8) - people_shield)
		elif emp.stress < 20:
			emp.morale += randi_range(0, 3)

		if state.company.cash < state.financials.burn_rate * 2:
			emp.morale -= randi_range(1, 5)

		if emp.assignment != EmployeeData.Assignment.UNASSIGNED:
			emp.stress += randi_range(1, 5)
		emp.stress = maxi(0, emp.stress - randi_range(2, 5))


static func _process_employee_turnover(state: Node) -> void:
	var quitters: Array[EmployeeData] = []
	for emp: EmployeeData in state.employees:
		if emp.quit_probability() > randf():
			quitters.append(emp)
	for emp in quitters:
		state.employees.erase(emp)
		state.append_event_log({
			"quarter": state.current_quarter,
			"year": state.current_year,
			"event_id": "employee_quit",
			"title": "%s resigned" % emp.employee_name,
		})


static func _grow_employee_skills(state: Node) -> void:
	for emp: EmployeeData in state.employees:
		emp.try_grow_skill()


static func _update_founder_energy(state: Node) -> void:
	var delta: int = 0

	var rw: float = state.financials.runway_quarters(state.company.cash)
	if rw < 2.0 and rw != INF:
		delta -= 8
	elif rw < 4.0 and rw != INF:
		delta -= 3

	var quitters_this_q: int = 0
	for entry: Dictionary in state.event_log:
		if entry.get("quarter") == state.current_quarter and entry.get("year") == state.current_year:
			if entry.get("event_id") == "employee_quit":
				quitters_this_q += 1
	delta -= quitters_this_q * 4

	if state.employees.is_empty() and state.total_quarters_elapsed() > 1:
		delta -= 5

	if state.financials.revenue > state.financials.burn_rate:
		delta += 6

	var avg_morale: float = 0.0
	if not state.employees.is_empty():
		for emp: EmployeeData in state.employees:
			avg_morale += emp.morale
		avg_morale /= state.employees.size()
		if avg_morale >= 70:
			delta += 3
		elif avg_morale < 40:
			delta -= 3

	if state.employees.size() <= 5 and state.employees.size() > 0 and avg_morale >= 60:
		delta += 2

	state.founder_energy = clampi(state.founder_energy + delta, 0, 100)


static func _update_board_patience(state: Node) -> void:
	if state.financials.funding_rounds.is_empty():
		return

	var history: Array[Dictionary] = state.history
	if history.size() < 2:
		return

	var curr: Dictionary = history[-1]
	var prev: Dictionary = history[-2]

	var users_grew: bool = curr.get("users", 0) > prev.get("users", 0)
	var rev_grew: bool = curr.get("revenue", 0.0) > prev.get("revenue", 0.0)
	var shipped: bool = state.product.feature_count() > 0

	if users_grew or rev_grew or shipped:
		state.board_patience = mini(state.board_patience + 1, 6)
	else:
		state.board_patience -= 1
		state.append_event_log({
			"quarter": state.current_quarter,
			"year": state.current_year,
			"event_id": "board_warning",
			"title": "Your board is concerned about lack of growth",
		})


static func _clamp_all_state(state: Node) -> void:
	state.company.clamp_all()
	state.product.clamp_all()
	for emp: EmployeeData in state.employees:
		emp.clamp_all()
