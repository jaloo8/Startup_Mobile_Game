class_name MarketData
extends Resource

enum MarketTrend { BOOM, STABLE, DOWNTURN, RECESSION }
enum EconomyState { BULL, NEUTRAL, BEAR }

@export var competitors: Array[Dictionary] = []  # [{name, users, funding, product_quality}]
@export var market_trend: MarketTrend = MarketTrend.STABLE
@export var economy_state: EconomyState = EconomyState.NEUTRAL
@export var pending_events: Array[Dictionary] = []

func funding_difficulty_mult() -> float:
	match economy_state:
		EconomyState.BULL: return 0.7
		EconomyState.NEUTRAL: return 1.0
		EconomyState.BEAR: return 1.5
	return 1.0
