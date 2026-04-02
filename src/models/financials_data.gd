class_name FinancialsData
extends Resource

@export var revenue: float = 0.0
@export var burn_rate: float = 0.0
@export var costs_breakdown: Dictionary = {
	"salaries": 0.0,
	"infrastructure": 0.0,
	"hosting": 0.0,
	"office": 0.0,
	"marketing": 0.0,
	"legal": 0.0,
	"tools": 0.0,
}
@export var funding_rounds: Array[Dictionary] = []  # [{round, amount, valuation, quarter}]
@export var investors: Array[Dictionary] = []       # [{name, equity_pct, board_seat}]


func total_costs() -> float:
	var total := 0.0
	for cost in costs_breakdown.values():
		if cost is float or cost is int:
			total += float(cost)
	return maxf(0.0, total)


func net_income() -> float:
	return revenue - total_costs()


func runway_quarters(cash: float) -> float:
	var net := net_income()
	if net >= 0.0:
		return INF
	return cash / absf(net)


func total_raised() -> float:
	var total := 0.0
	for r in funding_rounds:
		total += r.get("amount", 0.0)
	return total
