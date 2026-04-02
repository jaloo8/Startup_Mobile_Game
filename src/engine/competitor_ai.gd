class_name CompetitorAI
extends RefCounted
## Loads competitors from JSON and simulates their growth each quarter.

const BASE_USER_GROWTH_PER_QUARTER := 50
const COMPETITORS_PATH := "res://src/data/competitors.json"

const TYPE_TO_FOCUS := {
	CompanyData.CompanyType.SAAS: "saas",
	CompanyData.CompanyType.CONSUMER: "consumer",
	CompanyData.CompanyType.MARKETPLACE: "marketplace",
	CompanyData.CompanyType.DEV_TOOLS: "dev_tools",
}

const SIZE_PRESETS := {
	"startup": {"users_min": 50, "users_max": 2_000, "funding_min": 10_000, "funding_max": 200_000, "quality_min": 20, "quality_max": 45, "growth_min": 0.04, "growth_max": 0.10},
	"growth": {"users_min": 2_000, "users_max": 50_000, "funding_min": 500_000, "funding_max": 10_000_000, "quality_min": 40, "quality_max": 65, "growth_min": 0.03, "growth_max": 0.08},
	"enterprise": {"users_min": 100_000, "users_max": 5_000_000, "funding_min": 50_000_000, "funding_max": 500_000_000, "quality_min": 55, "quality_max": 80, "growth_min": 0.01, "growth_max": 0.04},
}

static var _pool: Array[Dictionary] = []


static func _load_pool() -> void:
	_pool.clear()

	if not FileAccess.file_exists(COMPETITORS_PATH):
		push_warning("CompetitorAI: competitors.json not found, using fallback")
		_pool = _fallback_pool()
		return

	var file := FileAccess.open(COMPETITORS_PATH, FileAccess.READ)
	if file == null:
		_pool = _fallback_pool()
		return

	var text := file.get_as_text()
	file = null
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("CompetitorAI: JSON parse error — %s" % json.get_error_message())
		_pool = _fallback_pool()
		return

	var data: Dictionary = json.data if json.data is Dictionary else {}
	var entries: Array = data.get("competitors", [])

	for entry in entries:
		if not entry is Dictionary:
			continue
		var name_val: String = str(entry.get("name", "")).strip_edges()
		if name_val.is_empty():
			continue
		_pool.append({
			"name": name_val,
			"focus": str(entry.get("focus", "")),
			"size": str(entry.get("size", "startup")),
			"tagline": str(entry.get("tagline", "")),
			"niches": _string_array(entry.get("niches", [])),
		})

	if _pool.is_empty():
		_pool = _fallback_pool()

	print("CompetitorAI: loaded %d competitors from JSON" % _pool.size())


static func generate_starting_competitors(
	count: int,
	company_type: CompanyData.CompanyType = CompanyData.CompanyType.SAAS,
	company_niche_id: String = ""
) -> Array[Dictionary]:
	if _pool.is_empty():
		_load_pool()

	var player_focus: String = TYPE_TO_FOCUS.get(company_type, "saas")
	var niche_id: String = company_niche_id.strip_edges()

	var same_niche: Array[Dictionary] = []
	var same_industry: Array[Dictionary] = []
	var enterprises: Array[Dictionary] = []
	var others: Array[Dictionary] = []

	for entry in _pool:
		if _entry_niche_score(entry, niche_id) > 0:
			same_niche.append(entry)
		if str(entry.get("focus", "")) == player_focus:
			same_industry.append(entry)
		elif str(entry.get("size", "startup")) == "enterprise":
			enterprises.append(entry)
		else:
			others.append(entry)

	if not same_niche.is_empty() and not niche_id.is_empty():
		same_niche.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return _entry_niche_score(a, niche_id) > _entry_niche_score(b, niche_id)
		)
	same_industry.shuffle()
	enterprises.shuffle()
	others.shuffle()

	var picked: Array[Dictionary] = []
	var used_names: Dictionary = {}

	var niche_count: int = 0
	if not niche_id.is_empty():
		niche_count = mini(count, maxi(1, ceili(float(count) * 0.34)))
	var same_count := ceili(count * 0.45)
	var enterprise_count := ceili(count * 0.20)
	var wild_count := maxi(0, count - niche_count - same_count - enterprise_count)

	_pick_from_pool(same_niche, niche_count, picked, used_names, count)
	_pick_from_pool(same_industry, same_count, picked, used_names, count)
	_pick_from_pool(enterprises, enterprise_count, picked, used_names, count)
	_pick_from_pool(others, wild_count, picked, used_names, count)

	while picked.size() < count:
		var all_remaining := same_industry + enterprises + others
		all_remaining.shuffle()
		var added_this_pass := false
		for entry in all_remaining:
			if picked.size() >= count:
				break
			if used_names.has(entry.get("name", "")):
				continue
			picked.append(_make_competitor(entry))
			used_names[entry.get("name", "")] = true
			added_this_pass = true
		if not added_this_pass:
			break

	return picked


static func _make_competitor(entry: Dictionary) -> Dictionary:
	var size_key: String = entry.get("size", "startup")
	var preset: Dictionary = SIZE_PRESETS.get(size_key, SIZE_PRESETS["startup"])

	return {
		"name": entry.get("name", "Unknown"),
		"tagline": entry.get("tagline", ""),
		"focus": entry.get("focus", ""),
		"niches": _string_array(entry.get("niches", [])),
		"users": randi_range(int(preset.get("users_min", 100)), int(preset.get("users_max", 1000))),
		"funding": randi_range(int(preset.get("funding_min", 0)), int(preset.get("funding_max", 100000))),
		"product_quality": randi_range(int(preset.get("quality_min", 30)), int(preset.get("quality_max", 70))),
		"growth_rate": randf_range(float(preset.get("growth_min", 0.01)), float(preset.get("growth_max", 0.1))),
	}


static func step(market: MarketData, growth_mult: float = 1.0) -> void:
	growth_mult = clampf(growth_mult, 0.5, 2.5)
	for i in market.competitors.size():
		var comp: Dictionary = market.competitors[i]
		var growth_rate: float = comp.get("growth_rate", 0.05)
		var current_users: int = comp.get("users", 0)

		var organic := ceili(current_users * growth_rate * growth_mult)
		var base_min := maxi(1, ceili((BASE_USER_GROWTH_PER_QUARTER / 2.0) * growth_mult))
		var base_max := maxi(base_min, ceili(BASE_USER_GROWTH_PER_QUARTER * growth_mult))
		var base := randi_range(base_min, base_max)
		comp["users"] = current_users + organic + base

		comp["product_quality"] = mini(100, comp.get("product_quality", 50) + randi_range(0, 3))

		if randf() < 0.1:
			comp["funding"] = comp.get("funding", 0) + randi_range(1_000_000, 10_000_000)

		market.competitors[i] = comp


static func _fallback_pool() -> Array[Dictionary]:
	return [
		{"name": "Macrosoft", "focus": "saas", "size": "enterprise"},
		{"name": "Googlr", "focus": "consumer", "size": "enterprise"},
		{"name": "Amazn", "focus": "marketplace", "size": "enterprise"},
		{"name": "ClosedAI", "focus": "dev_tools", "size": "growth"},
		{"name": "Striipe", "focus": "dev_tools", "size": "growth"},
		{"name": "Slak", "focus": "saas", "size": "growth"},
	]


static func _pick_from_pool(
	source: Array[Dictionary],
	target: int,
	picked: Array[Dictionary],
	used_names: Dictionary,
	count_cap: int
) -> void:
	if target <= 0:
		return
	var added := 0
	for entry in source:
		if picked.size() >= count_cap or added >= target:
			break
		var name_val: String = str(entry.get("name", "")).strip_edges()
		if name_val.is_empty() or used_names.has(name_val):
			continue
		picked.append(_make_competitor(entry))
		used_names[name_val] = true
		added += 1


static func _entry_niche_score(entry: Dictionary, niche_id: String) -> int:
	if niche_id.is_empty():
		return 0
	var explicit_niches: Array = entry.get("niches", [])
	if explicit_niches is Array and niche_id in explicit_niches:
		return 5
	var keywords: Array[String] = _niche_keywords(niche_id)
	if keywords.is_empty():
		return 0
	var text: String = ("%s %s" % [entry.get("name", ""), entry.get("tagline", "")]).to_lower()
	var score := 0
	for kw in keywords:
		if kw.is_empty():
			continue
		if text.find(kw) >= 0:
			score += 1
	return score


static func _niche_keywords(niche_id: String) -> Array[String]:
	match niche_id:
		"streaming_service":
			return ["stream", "video", "music", "content", "media"]
		"fitness_companion":
			return ["fitness", "health", "wellness", "habit"]
		"local_discovery":
			return ["local", "city", "community", "events"]
		"vertical_crm":
			return ["crm", "sales", "customer", "pipeline"]
		"workflow_automation":
			return ["automation", "workflow", "productivity", "ops"]
		"compliance_ops":
			return ["compliance", "security", "risk", "audit"]
		"home_services":
			return ["home", "service", "booking", "provider"]
		"resale_goods":
			return ["resale", "seller", "listing", "auction"]
		"food_delivery_hub":
			return ["delivery", "food", "courier", "logistics"]
		"api_observability":
			return ["api", "observability", "monitor", "uptime"]
		"ci_automation":
			return ["ci", "deploy", "build", "pipeline"]
		"cloud_cost_tools":
			return ["cloud", "cost", "infrastructure", "optimization"]
		_:
			return []


static func _string_array(value) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for raw in value:
			var text: String = str(raw).strip_edges()
			if not text.is_empty():
				out.append(text)
	return out
