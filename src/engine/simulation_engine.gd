class_name SimulationEngine
extends RefCounted
## Processes one quarter. Called from GameState.advance_quarter().
## Steps follow GDD Section 4.3 order.

const BASE_ORGANIC_USERS_PER_QUARTER := 10
const MARKETING_USER_MULT := 0.5

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
	_calculate_costs(state)
	_update_cash(state)
	_run_competitor_ai(state)
	_roll_events(state)
	_update_employee_morale(state)
	_process_employee_turnover(state)
	_grow_employee_skills(state)
	_clamp_all_state(state)


static func _apply_work_output(state: Node) -> void:
	if state.employees.is_empty():
		return

	for emp: EmployeeData in state.employees:
		if emp.assignment == EmployeeData.Assignment.UNASSIGNED:
			emp.tenure_quarters += 1
			continue

		var output: float = emp.work_output() * state.product.dev_speed_multiplier()
		var tech_bonus: float = state.company.founder_stat("technical") * 0.05

		match emp.assignment:
			EmployeeData.Assignment.FEATURES:
				state.product.feature_progress += output * 0.15
				if state.product.feature_progress >= ProductData.FEATURE_COST:
					state.product.feature_progress -= ProductData.FEATURE_COST
					var quality := clampi(ceili(output * 0.8) + randi_range(-10, 10) + roundi(tech_bonus * 5), 20, 100)
					var fname: String = _feature_names.pick_random()
					state.product.add_feature(fname, quality, state.current_quarter)
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
	var growth_from_existing := ceili(state.product.users * organic_rate * biz_bonus)
	var reputation_pull := ceili(base_new * reputation_bonus * biz_bonus)
	var total_new := base_new + growth_from_existing + reputation_pull

	var churn_count := ceili(state.product.users * state.product.churn_rate)
	var bug_churn := ceili(state.product.bugs * 0.5)
	var total_churn := churn_count + bug_churn

	state.product.users = maxi(0, state.product.users + total_new - total_churn)
	state.product.dau = maxi(0, ceili(state.product.users * clampf(0.3 - state.product.bugs * 0.002, 0.05, 0.5)))


static func _calculate_revenue(state: Node) -> void:
	state.financials.revenue = RevenueEngine.calculate(state.company, state.product)


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
	CompetitorAI.step(state.market)


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


static func _clamp_all_state(state: Node) -> void:
	state.company.clamp_all()
	state.product.clamp_all()
	for emp: EmployeeData in state.employees:
		emp.clamp_all()
