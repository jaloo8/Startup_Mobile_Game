class_name ValuationEngine
extends RefCounted
## Estimates company valuation each quarter based on industry-standard
## revenue/user multiples, adjusted for growth, economy, and reputation.
## Fundraising valuations set a floor — investors don't un-value you.


static func estimate(state: Node) -> float:
	var company: CompanyData = state.company
	var product: ProductData = state.product
	var financials: FinancialsData = state.financials
	var market: MarketData = state.market
	var history: Array[Dictionary] = state.history

	var base: float = _base_valuation(company.type, product, financials)
	var growth_mult: float = _growth_multiplier(history)
	var economy_mult: float = _economy_multiplier(market.economy_state)
	var reputation_mult: float = lerpf(0.7, 1.3, company.reputation / 100.0)
	var team_mult: float = 1.0 + mini(state.employees.size(), 20) * 0.02

	var estimated: float = base * growth_mult * economy_mult * reputation_mult * team_mult
	estimated = maxf(0.0, snappedf(estimated, 10_000.0))

	var fundraise_floor: float = _fundraise_floor(financials)
	return maxf(estimated, fundraise_floor)


static func _base_valuation(type: CompanyData.CompanyType, product: ProductData, financials: FinancialsData) -> float:
	var arr: float = financials.revenue * 4.0

	match type:
		CompanyData.CompanyType.SAAS:
			return arr * 12.0
		CompanyData.CompanyType.CONSUMER:
			var per_user := lerpf(5.0, 20.0, clampf(product.dau / maxf(1.0, float(product.users)), 0.0, 1.0))
			return product.users * per_user
		CompanyData.CompanyType.MARKETPLACE:
			var gmv_run_rate: float = product.users * 50.0 * 4.0
			return gmv_run_rate * 2.5 + product.users * 3.0
		CompanyData.CompanyType.DEV_TOOLS:
			return arr * 10.0

	return arr * 8.0


static func _growth_multiplier(history: Array[Dictionary]) -> float:
	if history.size() < 2:
		return 1.0

	var current: Dictionary = history[-1]
	var previous: Dictionary = history[-2]

	var prev_users: int = previous.get("users", 0)
	var curr_users: int = current.get("users", 0)
	var prev_rev: float = previous.get("revenue", 0.0)
	var curr_rev: float = current.get("revenue", 0.0)

	var user_growth := 0.0
	if prev_users > 0:
		user_growth = float(curr_users - prev_users) / float(prev_users)

	var rev_growth := 0.0
	if prev_rev > 0:
		rev_growth = (curr_rev - prev_rev) / prev_rev

	var combined_growth: float = (user_growth + rev_growth) / 2.0
	return clampf(1.0 + combined_growth, 0.5, 3.0)


static func _economy_multiplier(economy: MarketData.EconomyState) -> float:
	match economy:
		MarketData.EconomyState.BULL:
			return 1.4
		MarketData.EconomyState.NEUTRAL:
			return 1.0
		MarketData.EconomyState.BEAR:
			return 0.6
	return 1.0


static func _fundraise_floor(financials: FinancialsData) -> float:
	if financials.funding_rounds.is_empty():
		return 0.0
	var last_round: Dictionary = financials.funding_rounds[-1]
	var last_val: float = last_round.get("valuation", 0.0)
	var last_amount: float = last_round.get("amount", 0.0)
	return last_val + last_amount
