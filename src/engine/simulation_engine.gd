class_name SimulationEngine
extends RefCounted
## Runs one quarter of simulation.

const BASE_ORGANIC_USERS_PER_QUARTER := 10
const MARKETING_USER_MULT := 0.5
const OFFICE_COST_BY_LEVEL := [0.0, 1_000.0, 4_000.0, 10_000.0]
const HOSTING_BASE_CAPACITY_BY_OFFICE := [2_200.0, 7_500.0, 20_000.0, 52_000.0]
const HOSTING_WEB_CAPACITY_PER_UPGRADE := 0.16
const HOSTING_CACHE_CAPACITY_PER_UPGRADE := 0.14
const HOSTING_DATA_CAPACITY_PER_UPGRADE := 0.18
const HOSTING_OPTIMIZATION_DEMAND_REDUCTION_PER_LEVEL := 0.045
const HOSTING_WEB_MAINTENANCE_PER_UPGRADE := 95.0
const HOSTING_CACHE_MAINTENANCE_PER_UPGRADE := 78.0
const HOSTING_DATA_MAINTENANCE_PER_UPGRADE := 118.0
const HOSTING_OPTIMIZATION_MAINTENANCE_PER_LEVEL := 135.0

const HOSTING_PROFILE_BY_TYPE := {
	CompanyData.CompanyType.SAAS: {
		"demand_web": 0.95,
		"demand_cache": 0.80,
		"demand_data": 1.25,
		"split_web": 0.34,
		"split_cache": 0.25,
		"split_data": 0.41,
	},
	CompanyData.CompanyType.CONSUMER: {
		"demand_web": 1.25,
		"demand_cache": 1.05,
		"demand_data": 0.75,
		"split_web": 0.45,
		"split_cache": 0.35,
		"split_data": 0.20,
	},
	CompanyData.CompanyType.MARKETPLACE: {
		"demand_web": 1.10,
		"demand_cache": 1.00,
		"demand_data": 1.10,
		"split_web": 0.38,
		"split_cache": 0.30,
		"split_data": 0.32,
	},
	CompanyData.CompanyType.DEV_TOOLS: {
		"demand_web": 0.90,
		"demand_cache": 1.20,
		"demand_data": 1.00,
		"split_web": 0.30,
		"split_cache": 0.42,
		"split_data": 0.28,
	},
}

const HOSTING_PLAN_CONFIG := {
	CompanyData.HostingPlan.MANAGED_CLOUD: {
		"fixed_cost": 350.0,
		"usage_cost_per_cu": 0.020,
		"overage_cost_per_cu": 0.064,
		"elastic_buffer": 0.22,
		"incident_penalty_mult": 0.70,
	},
	CompanyData.HostingPlan.HYBRID: {
		"fixed_cost": 1_100.0,
		"usage_cost_per_cu": 0.016,
		"overage_cost_per_cu": 0.048,
		"elastic_buffer": 0.12,
		"incident_penalty_mult": 0.88,
	},
	CompanyData.HostingPlan.IN_HOUSE: {
		"fixed_cost": 2_450.0,
		"usage_cost_per_cu": 0.012,
		"overage_cost_per_cu": 0.038,
		"elastic_buffer": 0.04,
		"incident_penalty_mult": 1.0,
	},
}

const HOSTING_WORKLOAD_KEYWORDS := {
	"ai_ml": [
		"ai",
		"ml",
		"model",
		"inference",
		"training",
		"recommend",
		"vector",
		"embedding",
		"gpu",
	],
	"streaming": [
		"stream",
		"video",
		"media",
		"live",
		"stories",
		"playback",
		"feed",
	],
	"marketplace": [
		"market",
		"search",
		"listing",
		"seller",
		"payment",
		"escrow",
		"delivery",
		"tracking",
		"rating",
		"review",
	],
	"api_platform": [
		"api",
		"sdk",
		"webhook",
		"rate",
		"auth",
		"token",
		"usage",
		"integration",
		"plugin",
		"cicd",
		"cli",
		"sandbox",
	],
	"realtime": [
		"realtime",
		"real_time",
		"chat",
		"live",
		"webhook",
		"notification",
		"stream",
		"tracking",
	],
}

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


static func _safe_dict(value) -> Dictionary:
	return value if value is Dictionary else {}


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
	_record_employee_history(state)
	_update_founder_energy(state)
	_update_board_patience(state)
	_clamp_all_state(state)


static func _growth_balance(company_type: int) -> Dictionary:
	var cfg: Dictionary = _safe_dict(GROWTH_BALANCE_BY_TYPE.get(company_type, DEFAULT_GROWTH_BALANCE))
	if cfg.is_empty():
		return DEFAULT_GROWTH_BALANCE
	return cfg


static func _apply_work_output(state: Node) -> void:
	if state.employees.is_empty():
		return

	# Team personality mix slightly influences effective collaboration speed.
	var collaboration_mult: float = _team_collaboration_mult(state)

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
		var output: float = emp.work_output() * state.product.dev_speed_multiplier() * spec_mult * collaboration_mult
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
	total_new = ceili(total_new * clampf(state.company.niche_growth_mult, 0.6, 1.6))

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

	var niche_churn_mult := clampf(state.company.niche_churn_mult, 0.6, 1.6)
	var churn_count := ceili(state.product.users * state.product.churn_rate * econ_churn_mult * type_churn_mult * difficulty_churn_mult * niche_churn_mult)
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
	var infra_cost := maxf(10.0, state.product.users * 0.006) * maxf(0.6, finance_discount)
	state.financials.costs_breakdown["infrastructure"] = infra_cost
	var hosting: Dictionary = _simulate_hosting(state, finance_discount)
	state.financials.costs_breakdown["hosting"] = float(hosting.get("hosting_cost", 0.0))
	state.company.hosting_reliability = float(hosting.get("reliability", 99.5))
	state.company.hosting_demand_web = float(hosting.get("demand_web", 0.0))
	state.company.hosting_demand_cache = float(hosting.get("demand_cache", 0.0))
	state.company.hosting_demand_data = float(hosting.get("demand_data", 0.0))
	state.company.hosting_capacity_web = float(hosting.get("capacity_web", 0.0))
	state.company.hosting_capacity_cache = float(hosting.get("capacity_cache", 0.0))
	state.company.hosting_capacity_data = float(hosting.get("capacity_data", 0.0))
	state.company.hosting_util_web = float(hosting.get("util_web", 0.0))
	state.company.hosting_util_cache = float(hosting.get("util_cache", 0.0))
	state.company.hosting_util_data = float(hosting.get("util_data", 0.0))
	state.company.hosting_overage_cost = float(hosting.get("overage_cost", 0.0))
	state.company.hosting_incidents_last_quarter = int(hosting.get("incidents", 0))
	state.company.hosting_workload_profile = str(hosting.get("workload_label", "General Cloud"))
	state.company.hosting_data_center_pressure = float(hosting.get("data_center_pressure", 0.0))
	if state.company.hosting_incidents_last_quarter > 0:
		var title := "Hosting incidents: %d this quarter (%.1f%% reliability)" % [
			state.company.hosting_incidents_last_quarter,
			state.company.hosting_reliability,
		]
		state.append_event_log({
			"quarter": state.current_quarter,
			"year": state.current_year,
			"event_id": "hosting_incident",
			"title": title,
		})
	elif state.company.hosting_overage_cost >= 500.0:
		var title := "Hosting overage: +$%s this quarter" % SceneLoader.format_money(state.company.hosting_overage_cost)
		state.append_event_log({
			"quarter": state.current_quarter,
			"year": state.current_year,
			"event_id": "hosting_overage",
			"title": title,
		})

	state.financials.costs_breakdown["office"] = OFFICE_COST_BY_LEVEL[
		clampi(state.company.office_level, 0, OFFICE_COST_BY_LEVEL.size() - 1)
	]

	state.financials.burn_rate = state.financials.total_costs()


static func _hosting_profile(company_type: int) -> Dictionary:
	var profile: Dictionary = _safe_dict(HOSTING_PROFILE_BY_TYPE.get(company_type, {}))
	if profile.is_empty():
		return {
			"demand_web": 1.0,
			"demand_cache": 1.0,
			"demand_data": 1.0,
			"split_web": 0.34,
			"split_cache": 0.33,
			"split_data": 0.33,
		}
	return profile


static func _hosting_plan_cfg(hosting_plan: int) -> Dictionary:
	var cfg: Dictionary = _safe_dict(HOSTING_PLAN_CONFIG.get(hosting_plan, {}))
	if cfg.is_empty():
		return {
			"fixed_cost": 350.0,
			"usage_cost_per_cu": 0.020,
			"overage_cost_per_cu": 0.064,
			"elastic_buffer": 0.22,
			"incident_penalty_mult": 0.70,
		}
	return cfg


static func _workload_base(company_type: int) -> Dictionary:
	match company_type:
		CompanyData.CompanyType.SAAS:
			return {
				"ai_ml": 0.10,
				"streaming": 0.06,
				"marketplace": 0.08,
				"api_platform": 0.28,
				"realtime": 0.14,
			}
		CompanyData.CompanyType.CONSUMER:
			return {
				"ai_ml": 0.08,
				"streaming": 0.36,
				"marketplace": 0.08,
				"api_platform": 0.09,
				"realtime": 0.30,
			}
		CompanyData.CompanyType.MARKETPLACE:
			return {
				"ai_ml": 0.08,
				"streaming": 0.10,
				"marketplace": 0.42,
				"api_platform": 0.16,
				"realtime": 0.22,
			}
		CompanyData.CompanyType.DEV_TOOLS:
			return {
				"ai_ml": 0.12,
				"streaming": 0.04,
				"marketplace": 0.06,
				"api_platform": 0.44,
				"realtime": 0.26,
			}
		_:
			return {
				"ai_ml": 0.10,
				"streaming": 0.10,
				"marketplace": 0.10,
				"api_platform": 0.18,
				"realtime": 0.12,
			}


static func _keyword_score(text: String, keywords: Array) -> float:
	if text.is_empty() or keywords.is_empty():
		return 0.0
	var score: float = 0.0
	for raw in keywords:
		var needle: String = str(raw).strip_edges().to_lower()
		if needle.is_empty():
			continue
		if text.find(needle) >= 0:
			score += 1.0
	return score


static func _dominant_workload_label(ai_ml: float, streaming: float, marketplace: float, api_rt: float) -> String:
	var dominant_label: String = "Balanced"
	var dominant_score: float = 0.0
	var labels: Array[String] = ["AI/ML", "Streaming", "Marketplace", "API/Realtime"]
	var scores: Array[float] = [ai_ml, streaming, marketplace, api_rt]
	for i in labels.size():
		var score: float = scores[i]
		if score > dominant_score:
			dominant_score = score
			dominant_label = labels[i]
	return dominant_label


static func _hosting_workload_profile(state: Node) -> Dictionary:
	var buckets: Dictionary = _workload_base(state.company.type)
	var ai_keywords: Array = HOSTING_WORKLOAD_KEYWORDS.get("ai_ml", [])
	var streaming_keywords: Array = HOSTING_WORKLOAD_KEYWORDS.get("streaming", [])
	var marketplace_keywords: Array = HOSTING_WORKLOAD_KEYWORDS.get("marketplace", [])
	var api_keywords: Array = HOSTING_WORKLOAD_KEYWORDS.get("api_platform", [])
	var realtime_keywords: Array = HOSTING_WORKLOAD_KEYWORDS.get("realtime", [])

	for feature_v in state.product.features:
		if not (feature_v is Dictionary):
			continue
		var feature_row: Dictionary = feature_v
		var token: String = ("%s %s" % [str(feature_row.get("id", "")), str(feature_row.get("name", ""))]).to_lower()
		if token.strip_edges().is_empty():
			continue
		buckets["ai_ml"] = float(buckets.get("ai_ml", 0.0)) + (_keyword_score(token, ai_keywords) * 0.18)
		buckets["streaming"] = float(buckets.get("streaming", 0.0)) + (_keyword_score(token, streaming_keywords) * 0.16)
		buckets["marketplace"] = float(buckets.get("marketplace", 0.0)) + (_keyword_score(token, marketplace_keywords) * 0.14)
		buckets["api_platform"] = float(buckets.get("api_platform", 0.0)) + (_keyword_score(token, api_keywords) * 0.14)
		buckets["realtime"] = float(buckets.get("realtime", 0.0)) + (_keyword_score(token, realtime_keywords) * 0.15)

	var users_scale: float = clampf(float(state.product.users) / 250_000.0, 0.0, 1.0)
	var dau_scale: float = clampf(float(state.product.dau) / 120_000.0, 0.0, 1.0)
	buckets["marketplace"] = float(buckets.get("marketplace", 0.0)) + (users_scale * 0.18)
	buckets["api_platform"] = float(buckets.get("api_platform", 0.0)) + (users_scale * 0.20)
	buckets["streaming"] = float(buckets.get("streaming", 0.0)) + (dau_scale * 0.24)
	buckets["realtime"] = float(buckets.get("realtime", 0.0)) + (dau_scale * 0.26)
	if float(buckets.get("ai_ml", 0.0)) > 0.35:
		buckets["ai_ml"] = float(buckets.get("ai_ml", 0.0)) + (users_scale * 0.22)

	var ai_ml: float = clampf(float(buckets.get("ai_ml", 0.0)), 0.0, 2.4)
	var streaming: float = clampf(float(buckets.get("streaming", 0.0)), 0.0, 2.4)
	var marketplace: float = clampf(float(buckets.get("marketplace", 0.0)), 0.0, 2.4)
	var api_platform: float = clampf(float(buckets.get("api_platform", 0.0)), 0.0, 2.4)
	var realtime: float = clampf(float(buckets.get("realtime", 0.0)), 0.0, 2.4)
	var api_realtime: float = api_platform + (realtime * 0.70)

	var web_mult: float = 1.0 + (streaming * 0.20) + (marketplace * 0.16) + (realtime * 0.13) + (api_platform * 0.06)
	var cache_mult: float = 1.0 + (api_platform * 0.18) + (realtime * 0.16) + (streaming * 0.12) + (ai_ml * 0.08)
	var data_mult: float = 1.0 + (ai_ml * 0.30) + (marketplace * 0.18) + (api_platform * 0.14) + (realtime * 0.14) + (streaming * 0.10)
	web_mult = clampf(web_mult, 1.0, 2.25)
	cache_mult = clampf(cache_mult, 1.0, 2.25)
	data_mult = clampf(data_mult, 1.0, 2.35)

	var data_center_pressure: float = (
		(ai_ml * 0.55)
		+ (streaming * 0.30)
		+ (marketplace * 0.26)
		+ (api_platform * 0.10)
		+ (realtime * 0.14)
	)
	data_center_pressure = clampf(data_center_pressure, 0.0, 3.0)

	var dominant: String = _dominant_workload_label(ai_ml, streaming, marketplace, api_realtime)
	var profile_label: String
	if data_center_pressure >= 2.2:
		profile_label = "Data-Center Heavy (%s)" % dominant
	elif data_center_pressure >= 1.25:
		profile_label = "Scale-Intensive (%s)" % dominant
	else:
		profile_label = "General Cloud (%s)" % dominant

	return {
		"web_mult": web_mult,
		"cache_mult": cache_mult,
		"data_mult": data_mult,
		"data_center_pressure": data_center_pressure,
		"workload_label": profile_label,
		"dominant_workload": dominant,
	}


static func _simulate_hosting(state: Node, finance_discount: float) -> Dictionary:
	var profile: Dictionary = _hosting_profile(state.company.type)
	var plan_cfg: Dictionary = _hosting_plan_cfg(state.company.hosting_plan)
	var workload_profile: Dictionary = _hosting_workload_profile(state)

	var traffic_units: float = maxf(
		900.0,
		(float(state.product.users) * 0.55)
		+ (float(state.product.dau) * 0.95)
		+ (float(state.product.feature_count()) * 220.0)
	)
	var demand_web: float = traffic_units * float(profile.get("demand_web", 1.0))
	var demand_cache: float = traffic_units * float(profile.get("demand_cache", 1.0))
	var demand_data: float = traffic_units * float(profile.get("demand_data", 1.0))
	demand_web *= float(workload_profile.get("web_mult", 1.0))
	demand_cache *= float(workload_profile.get("cache_mult", 1.0))
	demand_data *= float(workload_profile.get("data_mult", 1.0))
	var optimization_level: int = clampi(state.company.hosting_optimization_level, 0, CompanyData.HOSTING_OPTIMIZATION_MAX)
	var optimization_reduction: float = clampf(
		1.0 - (float(optimization_level) * HOSTING_OPTIMIZATION_DEMAND_REDUCTION_PER_LEVEL),
		0.75,
		1.0
	)
	demand_web *= optimization_reduction
	demand_cache *= optimization_reduction
	demand_data *= optimization_reduction

	var office_level: int = clampi(state.company.office_level, 0, HOSTING_BASE_CAPACITY_BY_OFFICE.size() - 1)
	var infra_staff := 0
	for emp: EmployeeData in state.employees:
		if emp.assignment == EmployeeData.Assignment.INFRA:
			infra_staff += 1
	var base_capacity: float = float(HOSTING_BASE_CAPACITY_BY_OFFICE[office_level])
	var infra_bonus := float(infra_staff) * 1_400.0
	var tech_bonus := float(state.company.founder_stat("technical")) * 260.0
	var total_capacity := base_capacity + infra_bonus + tech_bonus
	if state.company.hosting_plan == CompanyData.HostingPlan.IN_HOUSE and office_level >= 2:
		total_capacity *= 1.08

	var split_web: float = float(profile.get("split_web", 0.34))
	var split_cache: float = float(profile.get("split_cache", 0.33))
	var split_data: float = float(profile.get("split_data", 0.33))
	var web_upgrade_level: int = clampi(state.company.hosting_upgrade_web_level, 0, CompanyData.HOSTING_LANE_UPGRADE_MAX)
	var cache_upgrade_level: int = clampi(state.company.hosting_upgrade_cache_level, 0, CompanyData.HOSTING_LANE_UPGRADE_MAX)
	var data_upgrade_level: int = clampi(state.company.hosting_upgrade_data_level, 0, CompanyData.HOSTING_LANE_UPGRADE_MAX)
	var capacity_web: float = maxf(100.0, total_capacity * split_web)
	var capacity_cache: float = maxf(100.0, total_capacity * split_cache)
	var capacity_data: float = maxf(100.0, total_capacity * split_data)
	capacity_web *= 1.0 + (float(web_upgrade_level) * HOSTING_WEB_CAPACITY_PER_UPGRADE)
	capacity_cache *= 1.0 + (float(cache_upgrade_level) * HOSTING_CACHE_CAPACITY_PER_UPGRADE)
	capacity_data *= 1.0 + (float(data_upgrade_level) * HOSTING_DATA_CAPACITY_PER_UPGRADE)

	var elastic: float = clampf(float(plan_cfg.get("elastic_buffer", 0.0)), 0.0, 0.40)
	var effective_capacity_web: float = capacity_web * (1.0 + elastic)
	var effective_capacity_cache: float = capacity_cache * (1.0 + elastic)
	var effective_capacity_data: float = capacity_data * (1.0 + elastic)

	var util_web: float = demand_web / maxf(1.0, effective_capacity_web)
	var util_cache: float = demand_cache / maxf(1.0, effective_capacity_cache)
	var util_data: float = demand_data / maxf(1.0, effective_capacity_data)
	var overage_web: float = maxf(0.0, demand_web - effective_capacity_web)
	var overage_cache: float = maxf(0.0, demand_cache - effective_capacity_cache)
	var overage_data: float = maxf(0.0, demand_data - effective_capacity_data)
	var overage_total: float = overage_web + overage_cache + overage_data

	var avg_util: float = (util_web + util_cache + util_data) / 3.0
	var max_util: float = maxf(util_web, maxf(util_cache, util_data))
	var reliability: float = 99.6
	reliability -= maxf(0.0, avg_util - 0.82) * 24.0
	reliability -= maxf(0.0, max_util - 1.0) * 38.0
	reliability -= minf(5.0, overage_total / 6_500.0)
	reliability = clampf(reliability, 72.0, 99.95)

	var incidents := 0
	var incident_penalty_mult: float = float(plan_cfg.get("incident_penalty_mult", 1.0))
	var pressure_mult := 1.0
	if state.has_method("difficulty_mult"):
		pressure_mult = clampf(float(state.difficulty_mult("event_pressure_mult")), 0.8, 1.4)
	var incident_risk: float = maxf(0.0, max_util - 0.98) * incident_penalty_mult * pressure_mult
	if reliability < 96.5:
		incidents += 1
	if reliability < 92.5 and randf() < clampf(0.10 + incident_risk, 0.0, 0.95):
		incidents += 1
	if reliability < 87.5 and randf() < clampf(0.05 + (incident_risk * 0.8), 0.0, 0.85):
		incidents += 1

	if incidents > 0:
		var penalty_scale: float = clampf((99.0 - reliability) / 20.0, 0.0, 2.5)
		state.product.stability = maxi(0, state.product.stability - ceili(1.5 + penalty_scale * 3.5))
		state.product.bugs += ceili(1.0 + penalty_scale * 1.8)
		state.product.churn_rate = minf(ProductData.CHURN_RATE_MAX, state.product.churn_rate + 0.0015 + penalty_scale * 0.0012)

	var usage_total: float = demand_web + demand_cache + demand_data
	var hosting_cost: float = float(plan_cfg.get("fixed_cost", 0.0))
	hosting_cost += usage_total * float(plan_cfg.get("usage_cost_per_cu", 0.0))
	var overage_cost: float = overage_total * float(plan_cfg.get("overage_cost_per_cu", 0.0))
	hosting_cost += overage_cost
	var upgrade_maintenance: float = (
		float(web_upgrade_level) * HOSTING_WEB_MAINTENANCE_PER_UPGRADE
		+ float(cache_upgrade_level) * HOSTING_CACHE_MAINTENANCE_PER_UPGRADE
		+ float(data_upgrade_level) * HOSTING_DATA_MAINTENANCE_PER_UPGRADE
		+ float(optimization_level) * HOSTING_OPTIMIZATION_MAINTENANCE_PER_LEVEL
	)
	hosting_cost += upgrade_maintenance
	if incidents > 0:
		hosting_cost += float(incidents) * 350.0 * (1.0 + maxf(0.0, max_util - 1.0))
	hosting_cost *= maxf(0.7, finance_discount)

	return {
		"hosting_cost": maxf(0.0, hosting_cost),
		"overage_cost": maxf(0.0, overage_cost * maxf(0.7, finance_discount)),
		"upgrade_maintenance_cost": maxf(0.0, upgrade_maintenance * maxf(0.7, finance_discount)),
		"reliability": reliability,
		"incidents": incidents,
		"demand_web": demand_web,
		"demand_cache": demand_cache,
		"demand_data": demand_data,
		"capacity_web": effective_capacity_web,
		"capacity_cache": effective_capacity_cache,
		"capacity_data": effective_capacity_data,
		"util_web": util_web,
		"util_cache": util_cache,
		"util_data": util_data,
		"optimization_reduction": optimization_reduction,
		"workload_label": str(workload_profile.get("workload_label", "General Cloud")),
		"dominant_workload": str(workload_profile.get("dominant_workload", "Balanced")),
		"data_center_pressure": float(workload_profile.get("data_center_pressure", 0.0)),
	}


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
	var team_morale_pulse: int = _team_morale_pulse(state)

	for emp: EmployeeData in state.employees:
		if team_morale_pulse != 0:
			emp.morale += team_morale_pulse

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
		if emp.employment_type == EmployeeData.EmploymentType.CONTRACTOR:
			emp.stress += 1
		if emp.employment_type == EmployeeData.EmploymentType.INTERN:
			emp.morale += 1
		if emp.personality == EmployeeData.Personality.AMBITIOUS and emp.morale < 50:
			emp.morale -= 2
		elif emp.personality == EmployeeData.Personality.TEAM_PLAYER:
			emp.morale += 1
			if team_morale_pulse > 0:
				emp.morale += 1
		elif emp.personality == EmployeeData.Personality.PERFECTIONIST and state.product.bugs > 15:
			emp.morale -= 2
		elif emp.personality == EmployeeData.Personality.ADAPTABLE and team_morale_pulse < 0:
			# Adaptable employees absorb team turbulence slightly better.
			emp.morale += 1
		emp.stress = maxi(0, emp.stress - randi_range(2, 5))


static func _team_collaboration_mult(state: Node) -> float:
	var team_size: int = state.employees.size()
	if team_size < 2:
		return 1.0

	var mentors := 0
	var team_players := 0
	var ambitious := 0
	var perfectionists := 0
	for emp: EmployeeData in state.employees:
		match emp.personality:
			EmployeeData.Personality.MENTOR:
				mentors += 1
			EmployeeData.Personality.TEAM_PLAYER:
				team_players += 1
			EmployeeData.Personality.AMBITIOUS:
				ambitious += 1
			EmployeeData.Personality.PERFECTIONIST:
				perfectionists += 1

	var mult: float = 1.0
	mult += minf(0.06, float(team_players) * 0.012)
	if mentors > 0 and team_size >= 4:
		mult += minf(0.05, float(mentors) * 0.015)

	var perfectionist_threshold: int = maxi(2, ceili(float(team_size) * 0.4))
	if perfectionists >= perfectionist_threshold and state.product.bugs > 15:
		mult -= 0.05

	var ambitious_threshold: int = maxi(3, ceili(float(team_size) * 0.45))
	if ambitious >= ambitious_threshold and state.company.cash < state.financials.burn_rate * 2.0:
		mult -= 0.04

	return clampf(mult, 0.88, 1.18)


static func _team_morale_pulse(state: Node) -> int:
	if state.employees.is_empty():
		return 0
	var team_size: int = state.employees.size()
	var mentors := 0
	var team_players := 0
	var ambitious := 0
	var perfectionists := 0
	for emp: EmployeeData in state.employees:
		match emp.personality:
			EmployeeData.Personality.MENTOR:
				mentors += 1
			EmployeeData.Personality.TEAM_PLAYER:
				team_players += 1
			EmployeeData.Personality.AMBITIOUS:
				ambitious += 1
			EmployeeData.Personality.PERFECTIONIST:
				perfectionists += 1

	var delta := 0
	if team_players >= 2 and mentors >= 1 and team_size >= 4:
		delta += 1

	var ambitious_threshold: int = maxi(3, ceili(float(team_size) * 0.45))
	if ambitious >= ambitious_threshold and state.company.cash < state.financials.burn_rate * 1.5:
		delta -= 1

	var perfectionist_threshold: int = maxi(2, ceili(float(team_size) * 0.35))
	if perfectionists >= perfectionist_threshold and state.product.bugs > 20:
		delta -= 1

	return clampi(delta, -2, 2)


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
	var mentor_count := 0
	for emp: EmployeeData in state.employees:
		if emp.personality == EmployeeData.Personality.MENTOR:
			mentor_count += 1

	for emp: EmployeeData in state.employees:
		emp.try_grow_skill()
		if mentor_count > 0 and emp.seniority <= EmployeeData.Seniority.MID and emp.assignment != EmployeeData.Assignment.UNASSIGNED:
			var bonus_chance := clampf(mentor_count * 0.06, 0.0, 0.20)
			if randf() < bonus_chance:
				emp.skill = mini(100, emp.skill + 1)


static func _record_employee_history(state: Node) -> void:
	for emp: EmployeeData in state.employees:
		emp.record_quarter_snapshot(state.current_year, state.current_quarter)


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
