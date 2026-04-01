class_name FundraisingEngine
extends RefCounted
## Generates VC funding offers from company metrics and JSON firms data.

enum Round { PRE_SEED, SEED, SERIES_A, SERIES_B, GROWTH }

const ROUND_NAMES := {
	Round.PRE_SEED: "Pre-Seed",
	Round.SEED: "Seed",
	Round.SERIES_A: "Series A",
	Round.SERIES_B: "Series B",
	Round.GROWTH: "Growth",
}

const ROUND_RANGES := {
	Round.PRE_SEED: {"min": 50_000, "max": 250_000, "val_mult": 3.0},
	Round.SEED: {"min": 250_000, "max": 2_000_000, "val_mult": 4.0},
	Round.SERIES_A: {"min": 2_000_000, "max": 15_000_000, "val_mult": 5.0},
	Round.SERIES_B: {"min": 10_000_000, "max": 50_000_000, "val_mult": 6.0},
	Round.GROWTH: {"min": 30_000_000, "max": 100_000_000, "val_mult": 7.0},
}

const TIER_THRESHOLDS := {
	"elite": 0.55,
	"top": 0.40,
	"mid": 0.25,
	"emerging": 0.10,
}

const TIER_VALUATION_BONUS := {
	"elite": 1.4,
	"top": 1.2,
	"mid": 1.0,
	"emerging": 0.85,
}

const TIER_ROUND_MATCH := {
	"emerging": [Round.PRE_SEED, Round.SEED],
	"mid": [Round.SEED, Round.SERIES_A],
	"top": [Round.SERIES_A, Round.SERIES_B],
	"elite": [Round.SERIES_A, Round.SERIES_B, Round.GROWTH],
}

const VCS_PATH := "res://src/data/vcs.json"
const TYPE_TO_FOCUS := {
	CompanyData.CompanyType.SAAS: "saas",
	CompanyData.CompanyType.CONSUMER: "consumer",
	CompanyData.CompanyType.MARKETPLACE: "marketplace",
	CompanyData.CompanyType.DEV_TOOLS: "dev_tools",
}

static var _firms: Array[Dictionary] = []


static func _load_firms() -> void:
	_firms.clear()

	if not FileAccess.file_exists(VCS_PATH):
		push_warning("FundraisingEngine: vcs.json not found")
		return

	var file := FileAccess.open(VCS_PATH, FileAccess.READ)
	if file == null:
		return

	var text := file.get_as_text()
	file = null
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("FundraisingEngine: JSON parse error — %s" % json.get_error_message())
		return

	var data: Dictionary = json.data if json.data is Dictionary else {}
	for entry in data.get("firms", []):
		if not entry is Dictionary:
			continue
		var name_val: String = str(entry.get("name", "")).strip_edges()
		if name_val.is_empty():
			continue
		_firms.append({
			"name": name_val,
			"tier": str(entry.get("tier", "mid")),
			"preferred_focus": entry.get("preferred_focus", []),
			"style": str(entry.get("style", "")),
			"check_min": entry.get("check_min", 0),
			"check_max": entry.get("check_max", 0),
		})

	print("FundraisingEngine: loaded %d VC firms" % _firms.size())


static func next_round(state: Node) -> Round:
	var count: int = state.financials.funding_rounds.size()
	if count == 0:
		return Round.SEED
	var last_round: String = state.financials.funding_rounds.back().get("round", "")
	match last_round:
		"Pre-Seed": return Round.SEED
		"Seed": return Round.SERIES_A
		"Series A": return Round.SERIES_B
		"Series B": return Round.GROWTH
	return Round.GROWTH


static func can_fundraise(state: Node) -> bool:
	if state.total_quarters_elapsed() < 2:
		return false
	return true


static func generate_offer(state: Node) -> Dictionary:
	if _firms.is_empty():
		_load_firms()

	var round_type: Round = next_round(state)
	var round_info: Dictionary = ROUND_RANGES[round_type]
	var round_name: String = ROUND_NAMES[round_type]
	var quality_signal: float = _company_strength(state)
	var amount_mult := 1.0
	var threshold_shift := 0.0
	if state.has_method("difficulty_mult"):
		# Difficulty hooks:
		# - amount mult scales check size up/down.
		# - threshold shift makes fundraising acceptance easier/harder.
		amount_mult = clampf(float(state.difficulty_mult("fundraise_amount_mult")), 0.7, 1.3)
		threshold_shift = clampf(float(state.difficulty_mult("fundraise_threshold_shift")), -0.15, 0.15)

	var firm: Dictionary = _pick_firm(state, round_type, quality_signal)
	var tier: String = firm.get("tier", "mid")

	var threshold: float = clampf(float(TIER_THRESHOLDS.get(tier, 0.25)) + threshold_shift, 0.05, 0.95)
	if quality_signal < threshold:
		return {
			"rejected": true,
			"firm_name": firm["name"],
			"firm_style": firm.get("style", ""),
			"tier": tier,
			"round": round_name,
			"reason": _rejection_reason(tier, quality_signal),
		}

	var effective_min: float = float(round_info["min"])
	var effective_max: float = float(round_info["max"])
	if firm.get("check_min", 0) > 0:
		effective_min = maxf(effective_min, float(firm["check_min"]))
	if firm.get("check_max", 0) > 0:
		effective_max = minf(effective_max, float(firm["check_max"]))
	effective_max = maxf(effective_min, effective_max)

	var amount: float = lerpf(effective_min, effective_max, clampf(quality_signal, 0.0, 1.0))
	amount *= amount_mult
	amount = snappedf(amount, 10_000)

	var val_bonus: float = TIER_VALUATION_BONUS.get(tier, 1.0)
	var valuation: float = amount * round_info["val_mult"] * val_bonus
	valuation *= lerpf(0.8, 1.3, quality_signal) * lerpf(0.94, 1.06, amount_mult)
	valuation = snappedf(valuation, 50_000)

	var dilution: float = (amount / (valuation + amount)) * 100.0
	dilution = snappedf(dilution, 0.1)

	var wants_board_seat: bool = round_type >= Round.SERIES_A

	return {
		"rejected": false,
		"firm_name": firm["name"],
		"firm_style": firm.get("style", ""),
		"tier": tier,
		"round": round_name,
		"amount": amount,
		"valuation": valuation,
		"dilution": dilution,
		"board_seat": wants_board_seat,
	}


static func accept_offer(state: Node, offer: Dictionary) -> void:
	state.company.cash += offer["amount"]
	state.company.equity_owned = maxf(0.0, state.company.equity_owned - offer["dilution"])
	state.company.valuation = offer["valuation"] + offer["amount"]
	state.financials.funding_rounds.append({
		"round": offer["round"],
		"amount": offer["amount"],
		"valuation": offer["valuation"],
		"firm": offer.get("firm_name", ""),
		"quarter": state.current_quarter,
		"year": state.current_year,
	})
	state.append_event_log({
		"quarter": state.current_quarter,
		"year": state.current_year,
		"event_id": "fundraise_closed",
		"title": "Closed %s with %s — raised $%s" % [offer["round"], offer.get("firm_name", "investors"), SceneLoader.format_money(offer["amount"])],
	})


static func _pick_firm(state: Node, round_type: Round, quality: float) -> Dictionary:
	if _firms.is_empty():
		return {"name": "Angel Investors", "tier": "emerging", "style": "A group of angel investors pooling together."}

	var player_focus: String = TYPE_TO_FOCUS.get(state.company.type, "saas")

	var scored: Array[Dictionary] = []
	for firm in _firms:
		var score := 1.0
		var tier: String = firm.get("tier", "mid")

		var round_match: Array = TIER_ROUND_MATCH.get(tier, [])
		if round_type in round_match:
			score += 2.0

		var prefs: Array = firm.get("preferred_focus", [])
		if prefs.is_empty():
			score += 0.5
		elif player_focus in prefs:
			score += 1.5

		score += randf() * 0.5

		scored.append({"firm": firm, "score": score})

	if scored.is_empty():
		return {"name": "Angel Investors", "tier": "emerging", "preferred_focus": []}

	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.get("score", 0.0) > b.get("score", 0.0))

	var top_count := mini(5, scored.size())
	var pick: Dictionary = scored[randi_range(0, maxi(0, top_count - 1))]
	return pick.get("firm", {"name": "Angel Investors", "tier": "emerging", "preferred_focus": []})


static func _rejection_reason(tier: String, _quality: float) -> String:
	match tier:
		"elite":
			return ["Not enough traction for our thesis right now.", "We loved the pitch, but we need to see stronger unit economics.", "Impressive team, but the market fit isn't there yet for us."].pick_random()
		"top":
			return ["We're going to pass for now — come back when you hit $1M ARR.", "The space is interesting but we need more proof points.", "Good foundation, but we'd want to see faster growth before committing."].pick_random()
		_:
			return ["We'll keep in touch. Not the right time for us.", "Interesting business, but not quite the fit we're looking for this fund.", "We appreciate the meeting. Let's reconnect next quarter."].pick_random()


static func _company_strength(state: Node) -> float:
	var user_score: float = clampf(state.product.users / 50_000.0, 0.0, 1.0)
	var revenue_score: float = clampf(state.financials.revenue / 100_000.0, 0.0, 1.0)
	var team_score: float = clampf(state.employees.size() / 15.0, 0.0, 1.0)
	var rep_score: float = state.company.reputation / 100.0
	var score: float = (user_score * 0.3) + (revenue_score * 0.3) + (team_score * 0.2) + (rep_score * 0.2)
	return clampf(score, 0.0, 1.0)


