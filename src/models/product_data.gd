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
var _pending_reputation_bonus: int = 0

## Builder Slots — multi-feature parallel build system.
## Each slot: {"feature_id": String, "progress": float, "crunched": bool}
## The old single-feature fields (target_feature_id, feature_progress) alias
## slot 0 for backward compatibility.
var build_queue: Array[Dictionary] = []
var build_slots: int = 1               # current unlocked slot count (1-4)
var feature_upgrades: Dictionary = {}   # {feature_id: upgrade_tier (1-3)}

## Ad-rush tracking: how many ad-rushes used today per feature.
## Reset daily.  Keys = feature_id, values = count (max 3).
var _ad_rush_counts: Dictionary = {}    # {feature_id: int}
var _ad_rush_day_stamp: int = 0         # day-of-year when counts were last reset

const CHURN_RATE_MIN := 0.01
const CHURN_RATE_MAX := 0.40
const FEATURE_COST := 100.0
const MAX_BUILD_SLOTS := 4
const MAX_AD_RUSHES_PER_FEATURE := 3

## Ad rush diminishing returns: each ad reduces REMAINING build time.
const AD_RUSH_REDUCTIONS: Array[float] = [0.25, 0.15, 0.10]

## Slot unlock thresholds: how many feature-lane engineers unlock each slot.
## Index 0 = requirement for slot 2, index 1 = slot 3, index 2 = slot 4.
const SLOT_UNLOCK_ENGINEER_THRESHOLDS: Array[int] = [5, 12, 20]

## Upgrade tier effect multipliers: tier 2 = +50% base effects, etc.
const UPGRADE_TIER_EFFECT_MULTS: Array[float] = [1.0, 1.5, 2.0, 2.5]
## Upgrade tier build costs in quarters-worth of progress.
const UPGRADE_TIER_COSTS: Array[float] = [0.0, 200.0, 350.0, 550.0]

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
		revenue_mult = clampf(revenue_mult * float(effects["revenue_mult"]), 0.1, 5.0)
	if effects.has("user_growth_bonus"):
		user_growth_flat_bonus += int(effects["user_growth_bonus"])
	if effects.has("reputation_bonus"):
		_pending_reputation_bonus += int(effects["reputation_bonus"])
	if effects.has("dau_bonus"):
		dau_bonus += float(effects["dau_bonus"])


func drain_pending_reputation_bonus() -> int:
	var bonus := _pending_reputation_bonus
	_pending_reputation_bonus = 0
	return bonus


# ─────────────────────────────────────────────────────────────────────────────
# Build Queue Management
# ─────────────────────────────────────────────────────────────────────────────

## Sync the legacy single-feature fields with slot 0 of the build queue.
## Call after any mutation of build_queue so old code paths stay correct.
func _sync_legacy_fields() -> void:
	if build_queue.is_empty():
		target_feature_id = ""
		feature_progress = 0.0
	else:
		target_feature_id = build_queue[0].get("feature_id", "")
		feature_progress = build_queue[0].get("progress", 0.0)


## How many slots are currently occupied.
func active_build_count() -> int:
	return build_queue.size()


## True if the player can start another feature build.
func has_open_slot() -> bool:
	return build_queue.size() < build_slots


## Start building a feature in the next open slot.
## Returns false if no slot is available.
func start_build(fid: String) -> bool:
	if not has_open_slot():
		return false
	if fid.is_empty():
		return false
	# Don't allow building the same feature twice.
	for slot in build_queue:
		if slot.get("feature_id", "") == fid:
			return false
	build_queue.append({"feature_id": fid, "progress": 0.0, "crunched": false})
	_sync_legacy_fields()
	return true


## Remove a completed or cancelled build from the queue by feature_id.
func remove_build(fid: String) -> void:
	for i in range(build_queue.size() - 1, -1, -1):
		if build_queue[i].get("feature_id", "") == fid:
			build_queue.remove_at(i)
			break
	_sync_legacy_fields()


## Get progress for a specific slot (0-indexed).
func slot_progress(slot_index: int) -> float:
	if slot_index < 0 or slot_index >= build_queue.size():
		return 0.0
	return build_queue[slot_index].get("progress", 0.0)


## Get feature_id for a specific slot.
func slot_feature_id(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= build_queue.size():
		return ""
	return build_queue[slot_index].get("feature_id", "")


## Add progress to a specific slot.  Returns the new progress value.
func add_slot_progress(slot_index: int, amount: float) -> float:
	if slot_index < 0 or slot_index >= build_queue.size():
		return 0.0
	var current: float = build_queue[slot_index].get("progress", 0.0)
	build_queue[slot_index]["progress"] = current + amount
	_sync_legacy_fields()
	return build_queue[slot_index]["progress"]


## Mark a slot as crunched (free rush with morale cost).
func set_slot_crunched(slot_index: int, crunched: bool) -> void:
	if slot_index >= 0 and slot_index < build_queue.size():
		build_queue[slot_index]["crunched"] = crunched


## Whether a slot has been crunched this build.
func is_slot_crunched(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= build_queue.size():
		return false
	return build_queue[slot_index].get("crunched", false)


# ─────────────────────────────────────────────────────────────────────────────
# Ad Rush
# ─────────────────────────────────────────────────────────────────────────────

## How many ad rushes remain today for a given feature.
func ad_rushes_remaining(fid: String) -> int:
	_maybe_reset_ad_rush_counts()
	var used: int = _ad_rush_counts.get(fid, 0)
	return maxi(0, MAX_AD_RUSHES_PER_FEATURE - used)


## Get the reduction factor for the NEXT ad rush on this feature.
## Returns 0.0 if no rushes remain.
func next_ad_rush_reduction(fid: String) -> float:
	var remaining := ad_rushes_remaining(fid)
	if remaining <= 0:
		return 0.0
	var used: int = _ad_rush_counts.get(fid, 0)
	if used >= AD_RUSH_REDUCTIONS.size():
		return 0.0
	return AD_RUSH_REDUCTIONS[used]


## Apply an ad rush: reduce remaining build time by the diminishing percentage.
## Returns the progress amount added (0 if no rushes left).
func apply_ad_rush(fid: String, cost: float) -> float:
	var reduction := next_ad_rush_reduction(fid)
	if reduction <= 0.0:
		return 0.0
	# Find the slot with this feature.
	for i in range(build_queue.size()):
		if build_queue[i].get("feature_id", "") == fid:
			var current_progress: float = build_queue[i].get("progress", 0.0)
			var remaining_cost: float = maxf(0.0, cost - current_progress)
			var boost: float = remaining_cost * reduction
			build_queue[i]["progress"] = current_progress + boost
			_ad_rush_counts[fid] = _ad_rush_counts.get(fid, 0) + 1
			_sync_legacy_fields()
			return boost
	return 0.0


func _maybe_reset_ad_rush_counts() -> void:
	var today := Time.get_date_dict_from_system()
	var day_stamp: int = today["year"] * 1000 + today["day_of_year"]
	if day_stamp != _ad_rush_day_stamp:
		_ad_rush_counts.clear()
		_ad_rush_day_stamp = day_stamp


# ─────────────────────────────────────────────────────────────────────────────
# Feature Upgrades
# ─────────────────────────────────────────────────────────────────────────────

## Current upgrade tier for a shipped feature (0 = base, 1 = Scaled, etc.)
func upgrade_tier(fid: String) -> int:
	return feature_upgrades.get(fid, 0)


## Cost to upgrade a feature to the next tier.
func upgrade_cost(fid: String) -> float:
	var current_tier: int = upgrade_tier(fid)
	if current_tier >= UPGRADE_TIER_COSTS.size() - 1:
		return 0.0  # already max
	return UPGRADE_TIER_COSTS[current_tier + 1]


## Effect multiplier for a feature based on its upgrade tier.
func upgrade_effect_mult(fid: String) -> float:
	var tier: int = clampi(upgrade_tier(fid), 0, UPGRADE_TIER_EFFECT_MULTS.size() - 1)
	return UPGRADE_TIER_EFFECT_MULTS[tier]


## Count of features upgraded to at least the given tier.
func features_at_tier(min_tier: int) -> int:
	var count := 0
	for tier: int in feature_upgrades.values():
		if tier >= min_tier:
			count += 1
	return count


# ─────────────────────────────────────────────────────────────────────────────
# Crunch Mode
# ─────────────────────────────────────────────────────────────────────────────

## Crunch bonus: crunched slots get 1.5x progress this quarter.
const CRUNCH_PROGRESS_MULT := 1.5
## Crunch penalty: applied to ALL feature-assigned employees.
const CRUNCH_STRESS_COST := 15
const CRUNCH_MORALE_COST := 10


func dev_speed_multiplier() -> float:
	if tech_debt > 75:
		return 0.5
	elif tech_debt > 50:
		return 0.75
	return 1.0


## Idle-game progression: later features cost more based on how many are shipped.
## Early features are discounted to hook the player; mid/late features escalate.
func feature_cost_multiplier() -> float:
	var shipped := features.size()
	if shipped <= 1:
		return 0.7
	elif shipped == 2:
		return 0.85
	elif shipped == 3:
		return 1.0
	else:
		# Exponential ramp: 1.2, 1.5, 1.9, 2.4, 3.0, 3.8, 4.8 ...
		return 1.0 * pow(1.26, shipped - 3)


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
	var entry: Dictionary = {
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
	revenue_mult = clampf(revenue_mult, 0.1, 5.0)
	build_slots = clampi(build_slots, 1, MAX_BUILD_SLOTS)
	# Trim queue if it somehow exceeds slot count.
	while build_queue.size() > build_slots:
		build_queue.pop_back()
	_sync_legacy_fields()


## Serialize build-queue state for save files.
func serialize_build_state() -> Dictionary:
	var queue_data: Array = []
	for slot in build_queue:
		queue_data.append({
			"feature_id": slot.get("feature_id", ""),
			"progress": slot.get("progress", 0.0),
			"crunched": slot.get("crunched", false),
		})
	return {
		"build_queue": queue_data,
		"build_slots": build_slots,
		"feature_upgrades": feature_upgrades.duplicate(),
		"ad_rush_counts": _ad_rush_counts.duplicate(),
		"ad_rush_day_stamp": _ad_rush_day_stamp,
	}


## Restore build-queue state from a save file.  Falls back to legacy
## single-feature fields if build_queue data is missing (old saves).
func deserialize_build_state(data: Dictionary) -> void:
	build_slots = clampi(int(data.get("build_slots", 1)), 1, MAX_BUILD_SLOTS)
	feature_upgrades = data.get("feature_upgrades", {}) if data.get("feature_upgrades") is Dictionary else {}
	_ad_rush_counts = data.get("ad_rush_counts", {}) if data.get("ad_rush_counts") is Dictionary else {}
	_ad_rush_day_stamp = int(data.get("ad_rush_day_stamp", 0))

	var queue_data: Array = data.get("build_queue", []) if data.get("build_queue") is Array else []
	build_queue.clear()
	if queue_data.is_empty():
		# Legacy save: migrate single-feature fields into slot 0.
		if not target_feature_id.is_empty():
			build_queue.append({
				"feature_id": target_feature_id,
				"progress": feature_progress,
				"crunched": false,
			})
	else:
		for entry in queue_data:
			if entry is Dictionary and not str(entry.get("feature_id", "")).is_empty():
				build_queue.append({
					"feature_id": str(entry.get("feature_id", "")),
					"progress": float(entry.get("progress", 0.0)),
					"crunched": bool(entry.get("crunched", false)),
				})
	# Trim to current slot count.
	while build_queue.size() > build_slots:
		build_queue.pop_back()
	_sync_legacy_fields()


## Reset build state for new game.
func reset_build_state() -> void:
	build_queue.clear()
	build_slots = 1
	feature_upgrades.clear()
	_ad_rush_counts.clear()
	_ad_rush_day_stamp = 0
	target_feature_id = ""
	feature_progress = 0.0
