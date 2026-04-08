class_name HiringEngine
extends RefCounted
## Generates candidates and handles the hiring pipeline.
##
## AI INTEGRATION OPPORTUNITY: Use an LLM to generate unique employee bios,
## personality quirks, and interview dialogue. Could also generate unique
## portrait sprites via Retro Diffusion API at hire time (cache results so
## the same employee always looks the same across sessions).

static var _bio_pool: Dictionary = {}
static var _seniority_prefixes: Dictionary = {}

static func _ensure_bio_pool() -> void:
	if not _bio_pool.is_empty():
		return
	var f := FileAccess.open("res://src/data/bios.json", FileAccess.READ)
	if f == null:
		return
	var parsed := JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		_bio_pool = parsed.get("by_personality", {})
		_seniority_prefixes = parsed.get("by_seniority_prefix", {})


static func _pick_bio(personality: EmployeeData.Personality, seniority: EmployeeData.Seniority) -> String:
	_ensure_bio_pool()
	var key: String = EmployeeData.PERSONALITY_NAMES.get(personality, "Steady")
	var pool: Array = _bio_pool.get(key, [])
	if pool.is_empty():
		return ""
	var base: String = pool.pick_random()
	# Occasionally prepend a seniority-flavoured prefix for variety.
	if randf() < 0.40:
		var sen_key: String = EmployeeData.SENIORITY_NAMES.get(seniority, "Mid")
		var prefixes: Array = _seniority_prefixes.get(sen_key, [])
		if not prefixes.is_empty():
			base = prefixes.pick_random() + " " + base
	return base


static func _age_for_seniority(seniority: EmployeeData.Seniority) -> int:
	match seniority:
		EmployeeData.Seniority.JUNIOR:  return randi_range(21, 28)
		EmployeeData.Seniority.MID:     return randi_range(26, 35)
		EmployeeData.Seniority.SENIOR:  return randi_range(30, 45)
		EmployeeData.Seniority.LEAD:    return randi_range(35, 52)
		EmployeeData.Seniority.PRINCIPAL: return randi_range(40, 62)
	return 30


static func generate_candidates(count: int, _market: MarketData, state: Node = null) -> Array[EmployeeData]:
	var candidates: Array[EmployeeData] = []
	for i in count:
		var emp := EmployeeData.new()
		emp.employee_name = _random_name()
		emp.ensure_uid()
		emp.employment_type = _weighted_employment_type(state)
		emp.seniority = _weighted_seniority()
		emp.specialty = EmployeeData.Specialty.values().pick_random()
		emp.skill = _stat_for_seniority(emp.seniority)
		emp.speed = _stat_for_seniority(emp.seniority)
		if emp.employment_type == EmployeeData.EmploymentType.INTERN:
			emp.seniority = EmployeeData.Seniority.JUNIOR
			emp.skill = randi_range(18, 42)
			emp.speed = randi_range(25, 52)
		elif emp.employment_type == EmployeeData.EmploymentType.CONTRACTOR:
			emp.skill = clampi(emp.skill + randi_range(-4, 6), 15, 100)
			emp.speed = clampi(emp.speed + randi_range(0, 8), 15, 100)
		emp.growth_potential = EmployeeData.GrowthPotential.values().pick_random()
		emp.personality = _weighted_personality()
		emp.culture_fit = randi_range(30, 90)
		emp.morale = randi_range(60, 90)
		emp.age = _age_for_seniority(emp.seniority)
		emp.bio = _pick_bio(emp.personality, emp.seniority)
		var salary_range: Vector2 = EmployeeData.SALARY_RANGES[emp.seniority]
		emp.salary_per_quarter = _salary_for_candidate(salary_range, emp.employment_type, state)
		candidates.append(emp)
	return candidates


static func _weighted_employment_type(state: Node = null) -> EmployeeData.EmploymentType:
	var elapsed_q := 0
	var cash := 150_000.0
	if state != null:
		if state.has_method("total_quarters_elapsed"):
			elapsed_q = int(state.total_quarters_elapsed())
		if state.get("company") != null:
			cash = float(state.company.cash)

	var full_time_share := 0.55
	var contractor_share := 0.30
	var intern_share := 0.15

	# Early game: lower commitment hiring keeps first-year economics survivable.
	if elapsed_q <= 8 and cash < 300_000.0:
		full_time_share = 0.25
		contractor_share = 0.55
		intern_share = 0.20
	# Late game: mature orgs lean more full-time.
	elif elapsed_q >= 20 or cash > 1_500_000.0:
		full_time_share = 0.72
		contractor_share = 0.18
		intern_share = 0.10

	var roll := randf()
	if roll < full_time_share:
		return EmployeeData.EmploymentType.FULL_TIME
	if roll < full_time_share + contractor_share:
		return EmployeeData.EmploymentType.CONTRACTOR
	return EmployeeData.EmploymentType.INTERN


static func _salary_for_candidate(salary_range: Vector2, employment_type: EmployeeData.EmploymentType, state: Node = null) -> float:
	var base := randf_range(salary_range.x, salary_range.y)
	match employment_type:
		EmployeeData.EmploymentType.CONTRACTOR:
			base *= randf_range(0.58, 0.84)
		EmployeeData.EmploymentType.INTERN:
			base *= randf_range(0.28, 0.44)
		_:
			pass

	# Tiny difficulty coupling: hardcore market is slightly tighter on comp.
	if state != null and state.get("difficulty") != null:
		if String(state.difficulty) == "hardcore":
			base *= 0.96
		elif String(state.difficulty) == "sandbox":
			base *= 1.03

	return maxf(2_500.0, base)


static func _weighted_personality() -> EmployeeData.Personality:
	var roll := randf()
	if roll < 0.20:
		return EmployeeData.Personality.STEADY
	elif roll < 0.36:
		return EmployeeData.Personality.AMBITIOUS
	elif roll < 0.52:
		return EmployeeData.Personality.PERFECTIONIST
	elif roll < 0.70:
		return EmployeeData.Personality.TEAM_PLAYER
	elif roll < 0.84:
		return EmployeeData.Personality.MENTOR
	return EmployeeData.Personality.ADAPTABLE


static func _weighted_seniority() -> EmployeeData.Seniority:
	var roll := randf()
	if roll < 0.35:
		return EmployeeData.Seniority.JUNIOR
	elif roll < 0.65:
		return EmployeeData.Seniority.MID
	elif roll < 0.85:
		return EmployeeData.Seniority.SENIOR
	elif roll < 0.95:
		return EmployeeData.Seniority.LEAD
	return EmployeeData.Seniority.PRINCIPAL


static func _stat_for_seniority(seniority: EmployeeData.Seniority) -> int:
	match seniority:
		EmployeeData.Seniority.JUNIOR: return randi_range(20, 45)
		EmployeeData.Seniority.MID: return randi_range(40, 65)
		EmployeeData.Seniority.SENIOR: return randi_range(60, 80)
		EmployeeData.Seniority.LEAD: return randi_range(70, 90)
		EmployeeData.Seniority.PRINCIPAL: return randi_range(80, 98)
	return 50


static func _random_name() -> String:
	var firsts: Array = ["Alex", "Jordan", "Sam", "Morgan", "Riley", "Casey",
		"Taylor", "Avery", "Quinn", "Blake", "Drew", "Reese",
		"Sage", "Parker", "Rowan", "Skyler", "Jamie", "Ellis",
		"Finley", "Hayden", "Emery", "Micah", "Noel", "Ari"]
	var lasts: Array = ["Chen", "Patel", "Kim", "Garcia", "Nguyen", "Lee",
		"Williams", "Singh", "Brown", "Martinez", "Davis", "Wilson",
		"Anderson", "Thomas", "Jackson", "White", "Harris", "Clark",
		"Okafor", "Sato", "Muller", "Costa", "Johansson", "Ali"]
	return firsts.pick_random() + " " + lasts.pick_random()
