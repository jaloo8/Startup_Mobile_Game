class_name ProductData
extends Resource

@export var features: Array[Dictionary] = []   # [{name, quality, quarter_shipped}]
@export var tech_debt: int = 0                  # 0-100
@export var bugs: int = 0
@export var stability: int = 80                 # 0-100
@export var ux_score: int = 50                  # 0-100
@export var users: int = 0
@export var dau: int = 0
@export var churn_rate: float = 0.05

var feature_progress: float = 0.0
var current_feature_name: String = ""

const CHURN_RATE_MIN := 0.01
const CHURN_RATE_MAX := 0.40
const FEATURE_COST := 100.0


func dev_speed_multiplier() -> float:
	if tech_debt > 75:
		return 0.5
	elif tech_debt > 50:
		return 0.75
	return 1.0


func feature_count() -> int:
	return features.size()


func avg_feature_quality() -> float:
	if features.is_empty():
		return 0.0
	var total := 0.0
	for f in features:
		total += f.get("quality", 0)
	return total / features.size()


func add_feature(feature_name: String, quality: int, quarter: int) -> void:
	features.append({
		"name": feature_name,
		"quality": clampi(quality, 1, 100),
		"quarter_shipped": quarter,
	})
	if quality < 50:
		tech_debt = mini(100, tech_debt + 10)
	elif quality < 70:
		tech_debt = mini(100, tech_debt + 5)


func clamp_all() -> void:
	tech_debt = clampi(tech_debt, 0, 100)
	stability = clampi(stability, 0, 100)
	ux_score = clampi(ux_score, 0, 100)
	bugs = maxi(0, bugs)
	users = maxi(0, users)
	dau = clampi(dau, 0, users)
	churn_rate = clampf(churn_rate, CHURN_RATE_MIN, CHURN_RATE_MAX)
