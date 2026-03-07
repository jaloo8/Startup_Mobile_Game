class_name FundraisingEngine
extends RefCounted
## Generates VC offers based on company metrics.
## Handles dilution, term evaluation, and round progression.

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
	var round_type: Round = next_round(state)
	var round_info: Dictionary = ROUND_RANGES[round_type]
	var round_name: String = ROUND_NAMES[round_type]

	var quality_signal: float = _company_strength(state)

	var amount: float = lerpf(
		float(round_info["min"]),
		float(round_info["max"]),
		clampf(quality_signal, 0.0, 1.0)
	)
	amount = snappedf(amount, 10_000)

	var valuation: float = amount * round_info["val_mult"]
	valuation *= lerpf(0.8, 1.3, quality_signal)
	valuation = snappedf(valuation, 50_000)

	var dilution: float = (amount / (valuation + amount)) * 100.0
	dilution = snappedf(dilution, 0.1)

	var wants_board_seat: bool = round_type >= Round.SERIES_A

	return {
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
		"quarter": state.current_quarter,
		"year": state.current_year,
	})
	state.append_event_log({
		"quarter": state.current_quarter,
		"year": state.current_year,
		"event_id": "fundraise_closed",
		"title": "Closed %s — raised $%s" % [offer["round"], _fmt_money(offer["amount"])],
	})


static func _company_strength(state: Node) -> float:
	var score := 0.0
	var user_score: float = clampf(state.product.users / 50_000.0, 0.0, 1.0)
	var revenue_score: float = clampf(state.financials.revenue / 100_000.0, 0.0, 1.0)
	var team_score: float = clampf(state.employees.size() / 15.0, 0.0, 1.0)
	var rep_score: float = state.company.reputation / 100.0
	score = (user_score * 0.3) + (revenue_score * 0.3) + (team_score * 0.2) + (rep_score * 0.2)
	return clampf(score, 0.0, 1.0)


static func _fmt_money(amount: float) -> String:
	if amount >= 1_000_000:
		return "%.1fM" % (amount / 1_000_000)
	elif amount >= 1_000:
		return "%.0fK" % (amount / 1_000)
	return "%.0f" % amount
