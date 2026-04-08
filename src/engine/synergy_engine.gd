class_name SynergyEngine
extends RefCounted
## SynergyEngine — detects and applies feature synergy combos.
##
## When a player ships features that match a synergy pattern, the combo
## fires once, grants bonus effects, and shows a celebration toast.
## Synergies make strategic feature selection feel rewarding — players
## discover combos through play rather than being told what to build.
##
## Evaluated after each feature ship. Already-fired synergies are tracked
## per run and won't re-fire.
##
## Usage:
##   SynergyEngine.check_synergies(GameState)  # call after feature_shipped

const SYNERGIES_PATH := "res://src/data/feature_synergies.json"

static var _definitions: Array[Dictionary] = []
static var _fired: Dictionary = {}  # synergy_id -> true, reset each run


static func load_synergies() -> void:
	_definitions.clear()
	if not FileAccess.file_exists(SYNERGIES_PATH):
		return
	var file := FileAccess.open(SYNERGIES_PATH, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return
	file.close()
	var data: Variant = json.data
	if data is Dictionary and data.has("synergies"):
		for item: Variant in data["synergies"]:
			if item is Dictionary and item.has("id"):
				_definitions.append(item as Dictionary)


static func reset() -> void:
	_fired.clear()


## Check all synergies against current shipped features.
## Returns an array of newly-fired synergy dicts (may be empty).
static func check_synergies(state: Node) -> Array[Dictionary]:
	if _definitions.is_empty():
		load_synergies()

	var product: Variant = state.get("product")
	if product == null:
		return []

	# Build a set of shipped feature IDs for fast lookup.
	var shipped: Dictionary = {}
	var features: Array = product.features if product.features is Array else []
	for feat: Variant in features:
		if feat is Dictionary:
			var fid: String = str(feat.get("id", feat.get("name", "")))
			if not fid.is_empty():
				shipped[fid.to_lower().replace(" ", "_")] = true
			# Also store the original name lowercased for fuzzy matching.
			var fname: String = str(feat.get("name", ""))
			if not fname.is_empty():
				shipped[fname.to_lower().replace(" ", "_")] = true

	var newly_fired: Array[Dictionary] = []

	for synergy in _definitions:
		var sid: String = synergy.get("id", "")
		if sid.is_empty() or _fired.has(sid):
			continue

		var required: Array = synergy.get("required_features", []) if synergy.get("required_features") is Array else []
		if required.is_empty():
			continue

		var all_present := true
		for req: Variant in required:
			var req_key: String = str(req).to_lower().replace(" ", "_")
			if not shipped.has(req_key):
				all_present = false
				break

		if all_present:
			_fired[sid] = true
			_apply_synergy(synergy, state)
			newly_fired.append(synergy)

	return newly_fired


## Apply the synergy's effects to the game state.
static func _apply_synergy(synergy: Dictionary, state: Node) -> void:
	var effects: Variant = synergy.get("effects")
	if not effects is Dictionary:
		return
	var fx: Dictionary = effects as Dictionary
	var product: Variant = state.get("product")
	var company: Variant = state.get("company")

	# Apply effects.
	if product != null:
		if fx.has("churn_reduction"):
			product.churn_rate = maxf(product.churn_rate - float(fx["churn_reduction"]), 0.01)
		if fx.has("ux_bonus"):
			product.ux_score = mini(product.ux_score + int(fx["ux_bonus"]), 100)
		if fx.has("user_growth_bonus"):
			product.user_growth_flat_bonus += int(fx["user_growth_bonus"])
		if fx.has("dau_bonus"):
			product.dau_bonus += float(fx["dau_bonus"])
		if fx.has("revenue_mult"):
			product.revenue_mult *= float(fx["revenue_mult"])
		if fx.has("stability_bonus"):
			product.stability = mini(product.stability + int(fx["stability_bonus"]), 100)

	if company != null:
		if fx.has("reputation_bonus"):
			company.reputation = mini(company.reputation + int(fx["reputation_bonus"]), 100)

	# Celebration.
	var title: String = synergy.get("name", "Synergy")
	var icon: String = synergy.get("icon", "✨")
	var desc: String = synergy.get("description", "")

	SfxPlayer.play("achievement")
	AnimHelper.haptic(&"heavy")
	ToastManager.show_milestone("%s %s" % [icon, title], icon)

	# Log the event.
	if state.has_method("append_event_log"):
		state.append_event_log({
			"quarter": state.current_quarter,
			"year": state.current_year,
			"event_id": "synergy_%s" % synergy.get("id", ""),
			"title": "Synergy discovered: %s — %s" % [title, desc],
		})



## Get all synergy definitions with their current status (fired or not).
static func get_all_with_status() -> Array[Dictionary]:
	if _definitions.is_empty():
		load_synergies()
	var result: Array[Dictionary] = []
	for synergy in _definitions:
		var copy: Dictionary = synergy.duplicate()
		copy["fired"] = _fired.has(synergy.get("id", ""))
		result.append(copy)
	return result


## Get list of synergies the player is close to completing (missing 1 feature).
static func get_near_misses(state: Node) -> Array[Dictionary]:
	if _definitions.is_empty():
		load_synergies()

	var product: Variant = state.get("product")
	if product == null:
		return []

	var shipped: Dictionary = {}
	var features: Array = product.features if product.features is Array else []
	for feat: Variant in features:
		if feat is Dictionary:
			var fid: String = str(feat.get("id", feat.get("name", "")))
			if not fid.is_empty():
				shipped[fid.to_lower().replace(" ", "_")] = true
			var fname: String = str(feat.get("name", ""))
			if not fname.is_empty():
				shipped[fname.to_lower().replace(" ", "_")] = true

	var near: Array[Dictionary] = []
	for synergy in _definitions:
		var sid: String = synergy.get("id", "")
		if _fired.has(sid):
			continue
		var required: Array = synergy.get("required_features", []) if synergy.get("required_features") is Array else []
		var missing := 0
		var missing_name := ""
		for req: Variant in required:
			var req_key: String = str(req).to_lower().replace(" ", "_")
			if not shipped.has(req_key):
				missing += 1
				missing_name = str(req).replace("_", " ").capitalize()
		if missing == 1 and required.size() >= 2:
			var copy: Dictionary = synergy.duplicate()
			copy["missing_feature"] = missing_name
			near.append(copy)

	return near


## Serialization support for save/load.
static func get_fired_ids() -> Array[String]:
	var result: Array[String] = []
	for key: Variant in _fired:
		result.append(str(key))
	return result


static func restore_fired(ids: Array) -> void:
	_fired.clear()
	for id: Variant in ids:
		_fired[str(id)] = true
