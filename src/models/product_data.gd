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
@export var revenue_mult: float = 1.0
@export var user_growth_flat_bonus: int = 0
@export var dau_bonus: float = 0.0

var feature_progress: float = 0.0
var current_feature_name: String = ""
var target_feature_id: String = ""

const CHURN_RATE_MIN := 0.01
const CHURN_RATE_MAX := 0.40
const FEATURE_COST := 100.0

static var _feature_catalog: Dictionary = {}


static func load_feature_catalog(path: String) -> void:
	_feature_catalog.clear()
	if not FileAccess.file_exists(path):
		push_warning("ProductData: features file not found: %s" % path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("ProductData: failed to open features file: %s" % path)
		return
	var text := file.get_as_text()
	file = null
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("ProductData: JSON parse error in features")
		return
	if json.data is Dictionary:
		_feature_catalog = json.data


static func _type_key(company_type: int) -> String:
	match company_type:
		CompanyData.CompanyType.SAAS: return "saas"
		CompanyData.CompanyType.CONSUMER: return "consumer"
		CompanyData.CompanyType.MARKETPLACE: return "marketplace"
		CompanyData.CompanyType.DEV_TOOLS: return "dev_tools"
	return "saas"


func completed_feature_ids() -> Array[String]:
	var ids: Array[String] = []
	for f in features:
		var fid: String = f.get("id", "")
		if not fid.is_empty():
			ids.append(fid)
	return ids


func available_features(company_type: int) -> Array[Dictionary]:
	var key := _type_key(company_type)
	var catalog: Array = _feature_catalog.get(key, [])
	var completed := completed_feature_ids()
	var result: Array[Dictionary] = []
	for entry in catalog:
		if not entry is Dictionary:
			continue
		var fid: String = entry.get("id", "")
		if fid in completed:
			continue
		var prereqs: Array = entry.get("prerequisites", [])
		var prereqs_met := true
		for p in prereqs:
			if str(p) not in completed:
				prereqs_met = false
				break
		if prereqs_met:
			result.append(entry)
	return result


func get_target_feature(company_type: int) -> Dictionary:
	if target_feature_id.is_empty():
		return {}
	var key := _type_key(company_type)
	var catalog: Array = _feature_catalog.get(key, [])
	for entry in catalog:
		if entry is Dictionary and entry.get("id", "") == target_feature_id:
			return entry
	return {}


func apply_feature_effects(feature_def: Dictionary) -> void:
	var effects: Dictionary = feature_def.get("effects", {})
	if effects.has("ux_bonus"):
		ux_score = mini(100, ux_score + int(effects["ux_bonus"]))
	if effects.has("stability_bonus"):
		stability = mini(100, stability + int(effects["stability_bonus"]))
	if effects.has("churn_reduction"):
		churn_rate = maxf(CHURN_RATE_MIN, churn_rate - float(effects["churn_reduction"]))
	if effects.has("revenue_mult"):
		revenue_mult *= float(effects["revenue_mult"])
	if effects.has("user_growth_bonus"):
		user_growth_flat_bonus += int(effects["user_growth_bonus"])
	if effects.has("reputation_bonus"):
		pass
	if effects.has("dau_bonus"):
		dau_bonus += float(effects["dau_bonus"])


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


func add_feature(feature_name: String, quality: int, quarter: int, feature_id: String = "") -> void:
	var entry := {
		"name": feature_name,
		"quality": clampi(quality, 1, 100),
		"quarter_shipped": quarter,
	}
	if not feature_id.is_empty():
		entry["id"] = feature_id
	features.append(entry)
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
