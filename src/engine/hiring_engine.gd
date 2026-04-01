class_name HiringEngine
extends RefCounted
## Generates candidates and handles the hiring pipeline.

static func generate_candidates(count: int, _market: MarketData) -> Array[EmployeeData]:
	var candidates: Array[EmployeeData] = []
	for i in count:
		var emp := EmployeeData.new()
		emp.employee_name = _random_name()
		emp.ensure_uid()
		emp.seniority = _weighted_seniority()
		emp.specialty = EmployeeData.Specialty.values().pick_random()
		emp.skill = _stat_for_seniority(emp.seniority)
		emp.speed = _stat_for_seniority(emp.seniority)
		emp.growth_potential = EmployeeData.GrowthPotential.values().pick_random()
		emp.culture_fit = randi_range(30, 90)
		emp.morale = randi_range(60, 90)
		var salary_range: Vector2 = EmployeeData.SALARY_RANGES[emp.seniority]
		emp.salary_per_quarter = randf_range(salary_range.x, salary_range.y)
		candidates.append(emp)
	return candidates


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
	var firsts := ["Alex", "Jordan", "Sam", "Morgan", "Riley", "Casey",
		"Taylor", "Avery", "Quinn", "Blake", "Drew", "Reese",
		"Sage", "Parker", "Rowan", "Skyler", "Jamie", "Ellis",
		"Finley", "Hayden", "Emery", "Micah", "Noel", "Ari"]
	var lasts := ["Chen", "Patel", "Kim", "Garcia", "Nguyen", "Lee",
		"Williams", "Singh", "Brown", "Martinez", "Davis", "Wilson",
		"Anderson", "Thomas", "Jackson", "White", "Harris", "Clark",
		"Okafor", "Sato", "Muller", "Costa", "Johansson", "Ali"]
	return firsts.pick_random() + " " + lasts.pick_random()
