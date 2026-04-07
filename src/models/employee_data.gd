class_name EmployeeData
extends Resource

enum Specialty { FRONTEND, BACKEND, MOBILE, DESIGN, DATA_ML, DEVOPS, SALES, MARKETING, OPERATIONS }
enum Seniority { JUNIOR, MID, SENIOR, LEAD, PRINCIPAL }
enum Assignment { FEATURES, BUGS, TECH_DEBT, INFRA, RND, UNASSIGNED }
enum GrowthPotential { LOW, MEDIUM, HIGH }
enum EmploymentType { FULL_TIME, CONTRACTOR, INTERN }
enum Personality { STEADY, AMBITIOUS, PERFECTIONIST, TEAM_PLAYER, MENTOR, ADAPTABLE }

@export var employee_name: String = ""
@export var employee_uid: String = ""
@export var specialty: Specialty = Specialty.BACKEND
@export var seniority: Seniority = Seniority.JUNIOR
@export var skill: int = 50
@export var speed: int = 50
@export var growth_potential: GrowthPotential = GrowthPotential.MEDIUM
@export var salary_per_quarter: float = 20_000.0
@export var morale: int = 75
@export var stress: int = 0
@export var culture_fit: int = 50
@export var tenure_quarters: int = 0
@export var assignment: Assignment = Assignment.UNASSIGNED
@export var employment_type: EmploymentType = EmploymentType.FULL_TIME
@export var personality: Personality = Personality.STEADY
@export var bio: String = ""
@export var age: int = 0
@export var quarter_history: Array[Dictionary] = []

const SALARY_RANGES := {
	Seniority.JUNIOR: Vector2(9_000, 16_000),
	Seniority.MID: Vector2(20_000, 32_000),
	Seniority.SENIOR: Vector2(32_000, 52_000),
	Seniority.LEAD: Vector2(48_000, 72_000),
	Seniority.PRINCIPAL: Vector2(68_000, 98_000),
}

const SPECIALTY_NAMES := {
	Specialty.FRONTEND: "Frontend",
	Specialty.BACKEND: "Backend",
	Specialty.MOBILE: "Mobile",
	Specialty.DESIGN: "Design",
	Specialty.DATA_ML: "Data/ML",
	Specialty.DEVOPS: "DevOps",
	Specialty.SALES: "Sales",
	Specialty.MARKETING: "Marketing",
	Specialty.OPERATIONS: "Operations",
}

const SENIORITY_NAMES := {
	Seniority.JUNIOR: "Junior",
	Seniority.MID: "Mid",
	Seniority.SENIOR: "Senior",
	Seniority.LEAD: "Lead",
	Seniority.PRINCIPAL: "Principal",
}

const ASSIGNMENT_NAMES := {
	Assignment.FEATURES: "Features",
	Assignment.BUGS: "Bug Fixes",
	Assignment.TECH_DEBT: "Tech Debt",
	Assignment.INFRA: "Infrastructure",
	Assignment.RND: "R&D",
	Assignment.UNASSIGNED: "Unassigned",
}

const EMPLOYMENT_TYPE_NAMES := {
	EmploymentType.FULL_TIME: "Full-time",
	EmploymentType.CONTRACTOR: "Contractor",
	EmploymentType.INTERN: "Intern",
}

const PERSONALITY_NAMES := {
	Personality.STEADY: "Steady",
	Personality.AMBITIOUS: "Ambitious",
	Personality.PERFECTIONIST: "Perfectionist",
	Personality.TEAM_PLAYER: "Team Player",
	Personality.MENTOR: "Mentor",
	Personality.ADAPTABLE: "Adaptable",
}


func work_output() -> float:
	var clamped_skill := clampi(skill, 0, 100)
	var clamped_speed := clampi(speed, 0, 100)
	var base := clamped_skill * clamped_speed / 100.0
	var morale_mult := lerpf(0.5, 1.2, clampi(morale, 0, 100) / 100.0)
	var stress_penalty := lerpf(1.0, 0.5, clampi(stress, 0, 100) / 100.0)
	return maxf(0.0, base * morale_mult * stress_penalty * employment_output_mult() * personality_output_mult())


func employment_output_mult() -> float:
	match employment_type:
		EmploymentType.CONTRACTOR:
			return 0.93
		EmploymentType.INTERN:
			return 0.68
		_:
			return 1.0


func personality_output_mult() -> float:
	match personality:
		Personality.AMBITIOUS:
			return 1.05 if morale >= 45 else 0.96
		Personality.PERFECTIONIST:
			if assignment == Assignment.BUGS or assignment == Assignment.TECH_DEBT:
				return 1.08
			return 0.98
		Personality.TEAM_PLAYER:
			return 1.03
		Personality.MENTOR:
			return 0.97
		Personality.ADAPTABLE:
			return 1.02
		_:
			return 1.0


## Returns a productivity multiplier based on how well this employee's specialty
## matches the given assignment and company type.
## 1.35 = great fit, 1.2 = good fit, 1.0 = neutral, 0.9 = poor fit.
static func specialty_mult(spec: Specialty, assign: Assignment, company_type: int) -> float:
	match assign:
		Assignment.FEATURES:
			# Each company type rewards different specialists on feature work.
			match company_type:
				0:  # SAAS
					match spec:
						Specialty.BACKEND: return 1.35
						Specialty.FRONTEND: return 1.2
						Specialty.DESIGN: return 1.15
						_: return 1.0
				1:  # CONSUMER
					match spec:
						Specialty.MOBILE: return 1.35
						Specialty.DESIGN: return 1.25
						Specialty.FRONTEND: return 1.2
						Specialty.BACKEND: return 1.0
						_: return 0.9
				2:  # MARKETPLACE
					match spec:
						Specialty.BACKEND: return 1.3
						Specialty.FRONTEND: return 1.2
						Specialty.MOBILE: return 1.15
						Specialty.DESIGN: return 1.1
						_: return 1.0
				3:  # DEV_TOOLS
					match spec:
						Specialty.BACKEND: return 1.4
						Specialty.DEVOPS: return 1.25
						Specialty.DATA_ML: return 1.15
						Specialty.FRONTEND: return 1.1
						_: return 1.0
			return 1.0
		Assignment.BUGS:
			match spec:
				Specialty.BACKEND: return 1.3
				Specialty.DEVOPS: return 1.2
				Specialty.FRONTEND: return 1.1
				_: return 1.0
		Assignment.TECH_DEBT:
			match spec:
				Specialty.BACKEND: return 1.3
				Specialty.DEVOPS: return 1.2
				_: return 1.0
		Assignment.INFRA:
			match spec:
				Specialty.DEVOPS: return 1.4
				Specialty.BACKEND: return 1.2
				_: return 1.0
		Assignment.RND:
			match spec:
				Specialty.DATA_ML: return 1.35
				Specialty.DESIGN: return 1.3
				Specialty.BACKEND: return 1.1
				_: return 1.0
	return 1.0


## Human-readable label for how good the specialty match is (for UI display).
static func specialty_match_label(spec: Specialty, assign: Assignment, company_type: int) -> String:
	var m := specialty_mult(spec, assign, company_type)
	if m >= 1.3:
		return "Great fit"
	elif m >= 1.15:
		return "Good fit"
	elif m < 1.0:
		return "Off-specialty"
	return ""


func quit_probability() -> float:
	var m := clampi(morale, 0, 100)
	var base := 0.0
	if m <= 60:
		base = remap(float(m), 0.0, 60.0, 0.3, 0.0)

	match employment_type:
		EmploymentType.CONTRACTOR:
			base += 0.08
		EmploymentType.INTERN:
			base += 0.03
		_:
			pass

	match personality:
		Personality.STEADY:
			base -= 0.02
		Personality.AMBITIOUS:
			if morale < 50:
				base += 0.04
		Personality.MENTOR:
			base -= 0.01
		_:
			pass

	return clampf(base, 0.0, 0.60)


func try_grow_skill() -> void:
	var growth_chance: float
	match growth_potential:
		GrowthPotential.HIGH: growth_chance = 0.4
		GrowthPotential.MEDIUM: growth_chance = 0.2
		GrowthPotential.LOW: growth_chance = 0.08
		_: growth_chance = 0.1
	if employment_type == EmploymentType.INTERN:
		growth_chance += 0.08
	if personality == Personality.AMBITIOUS:
		growth_chance += 0.05
	elif personality == Personality.STEADY:
		growth_chance += 0.02
	if assignment != Assignment.UNASSIGNED and randf() < growth_chance:
		skill = mini(100, skill + randi_range(1, 3))


func display_title() -> String:
	return "%s %s" % [SENIORITY_NAMES.get(seniority, ""), SPECIALTY_NAMES.get(specialty, "")]


func employment_label() -> String:
	return EMPLOYMENT_TYPE_NAMES.get(employment_type, "Full-time")


func personality_label() -> String:
	return PERSONALITY_NAMES.get(personality, "Steady")


func personality_effect_hint() -> String:
	match personality:
		Personality.AMBITIOUS:
			return "Pushes harder when morale is solid."
		Personality.PERFECTIONIST:
			return "Excellent on bugs/debt, slightly slower on raw feature shipping."
		Personality.TEAM_PLAYER:
			return "Consistent contributor across assignments."
		Personality.MENTOR:
			return "Develops teammates over time."
		Personality.ADAPTABLE:
			return "Small output bonus across most assignments."
		_:
			return "Reliable baseline performer."


func record_quarter_snapshot(year: int, quarter: int) -> void:
	quarter_history.append({
		"year": maxi(1, year),
		"quarter": clampi(quarter, 1, 4),
		"skill": clampi(skill, 0, 100),
		"morale": clampi(morale, 0, 100),
		"stress": clampi(stress, 0, 100),
		"assignment": int(assignment),
	})
	if quarter_history.size() > 36:
		quarter_history = quarter_history.slice(-36)


func recent_history(limit: int = 12) -> Array[Dictionary]:
	if quarter_history.is_empty():
		return []
	var n := maxi(1, limit)
	if quarter_history.size() <= n:
		return quarter_history.duplicate(true)
	return quarter_history.slice(-n)


## Ensures this employee has a stable unique ID for save/load identity.
func ensure_uid() -> void:
	if employee_uid.strip_edges().is_empty():
		employee_uid = _generate_uid()


static func _generate_uid() -> String:
	return "%d-%d-%d" % [Time.get_unix_time_from_system(), randi(), randi()]


## Returns true if this employee should retire this quarter.
## Employees aged 60-80 have an increasing probability of retiring each quarter.
func retirement_check() -> bool:
	if age < 60:
		return false
	if age >= 80:
		return true
	# Linear ramp from 3% at 60 to 25% at 80.
	var chance := remap(float(age), 60.0, 80.0, 0.03, 0.25)
	return randf() < chance


func clamp_all() -> void:
	ensure_uid()
	skill = clampi(skill, 0, 100)
	speed = clampi(speed, 0, 100)
	morale = clampi(morale, 0, 100)
	stress = clampi(stress, 0, 100)
	culture_fit = clampi(culture_fit, 0, 100)
	salary_per_quarter = maxf(0.0, salary_per_quarter)
	employment_type = clampi(employment_type, 0, 2) as EmploymentType
	personality = clampi(personality, 0, 5) as Personality
	assignment = clampi(assignment, 0, Assignment.UNASSIGNED) as Assignment
	age = clampi(age, 0, 99)
	if bio.length() > 300:
		bio = bio.substr(0, 300)
	if quarter_history.size() > 36:
		quarter_history = quarter_history.slice(-36)
	var sanitized: Array[Dictionary] = []
	for item in quarter_history:
		if item is Dictionary:
			sanitized.append({
				"year": maxi(1, int(item.get("year", 1))),
				"quarter": clampi(int(item.get("quarter", 1)), 1, 4),
				"skill": clampi(int(item.get("skill", 0)), 0, 100),
				"morale": clampi(int(item.get("morale", 0)), 0, 100),
				"stress": clampi(int(item.get("stress", 0)), 0, 100),
				"assignment": clampi(int(item.get("assignment", Assignment.UNASSIGNED)), 0, Assignment.UNASSIGNED),
			})
	quarter_history = sanitized
