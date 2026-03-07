class_name EmployeeData
extends Resource

enum Specialty { FRONTEND, BACKEND, MOBILE, DESIGN, DATA_ML, DEVOPS, SALES, MARKETING, OPERATIONS }
enum Seniority { JUNIOR, MID, SENIOR, LEAD, PRINCIPAL }
enum Assignment { FEATURES, BUGS, TECH_DEBT, INFRA, RND, UNASSIGNED }
enum GrowthPotential { LOW, MEDIUM, HIGH }

@export var employee_name: String = ""
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

const SALARY_RANGES := {
	Seniority.JUNIOR: Vector2(15_000, 22_000),
	Seniority.MID: Vector2(22_000, 35_000),
	Seniority.SENIOR: Vector2(35_000, 55_000),
	Seniority.LEAD: Vector2(50_000, 75_000),
	Seniority.PRINCIPAL: Vector2(70_000, 100_000),
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


func work_output() -> float:
	var clamped_skill := clampi(skill, 0, 100)
	var clamped_speed := clampi(speed, 0, 100)
	var base := clamped_skill * clamped_speed / 100.0
	var morale_mult := lerpf(0.5, 1.2, clampi(morale, 0, 100) / 100.0)
	var stress_penalty := lerpf(1.0, 0.5, clampi(stress, 0, 100) / 100.0)
	return maxf(0.0, base * morale_mult * stress_penalty)


func quit_probability() -> float:
	var m := clampi(morale, 0, 100)
	if m > 60:
		return 0.0
	return remap(float(m), 0.0, 60.0, 0.3, 0.0)


func try_grow_skill() -> void:
	var growth_chance: float
	match growth_potential:
		GrowthPotential.HIGH: growth_chance = 0.4
		GrowthPotential.MEDIUM: growth_chance = 0.2
		GrowthPotential.LOW: growth_chance = 0.08
		_: growth_chance = 0.1
	if assignment != Assignment.UNASSIGNED and randf() < growth_chance:
		skill = mini(100, skill + randi_range(1, 3))


func display_title() -> String:
	return "%s %s" % [SENIORITY_NAMES.get(seniority, ""), SPECIALTY_NAMES.get(specialty, "")]


func clamp_all() -> void:
	skill = clampi(skill, 0, 100)
	speed = clampi(speed, 0, 100)
	morale = clampi(morale, 0, 100)
	stress = clampi(stress, 0, 100)
	culture_fit = clampi(culture_fit, 0, 100)
	salary_per_quarter = maxf(0.0, salary_per_quarter)
