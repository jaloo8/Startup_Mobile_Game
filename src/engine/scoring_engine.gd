class_name ScoringEngine
## ScoringEngine — calculates end-of-run Founder Score and letter grade.
##
## Evaluates performance across multiple axes to produce a composite score (0-100)
## and a letter grade (S/A/B/C/D/F). Used on victory and game-over screens.
##
## Usage:
##   var result: Dictionary = ScoringEngine.calculate(GameState)
##   # result = {score: 78, grade: "A", breakdown: {...}, summary: "..."}


## Score thresholds for each letter grade.
const GRADE_THRESHOLDS: Dictionary = {
	"S": 90, "A": 75, "B": 60, "C": 45, "D": 30, "F": 0,
}

## Grade display colors.
const GRADE_COLORS: Dictionary = {
	"S": Color(1.0, 0.84, 0.0),    # Gold
	"A": Color(0.30, 0.85, 0.45),   # Green
	"B": Color(0.29, 0.62, 1.0),    # Blue
	"C": Color(0.96, 0.74, 0.31),   # Gold/amber
	"D": Color(0.88, 0.50, 0.22),   # Orange
	"F": Color(0.88, 0.32, 0.32),   # Red
}


static func calculate(state: Node) -> Dictionary:
	var breakdown: Dictionary = {}
	var total_weight := 0.0
	var weighted_sum := 0.0

	# --- Financial Health (25%) ---
	var finance_score := _score_finances(state)
	breakdown["finances"] = {"score": finance_score, "weight": 0.25, "label": "Financial Health"}
	weighted_sum += finance_score * 0.25
	total_weight += 0.25

	# --- Growth (20%) ---
	var growth_score := _score_growth(state)
	breakdown["growth"] = {"score": growth_score, "weight": 0.20, "label": "User Growth"}
	weighted_sum += growth_score * 0.20
	total_weight += 0.20

	# --- Product Quality (20%) ---
	var product_score := _score_product(state)
	breakdown["product"] = {"score": product_score, "weight": 0.20, "label": "Product Quality"}
	weighted_sum += product_score * 0.20
	total_weight += 0.20

	# --- Team (15%) ---
	var team_score := _score_team(state)
	breakdown["team"] = {"score": team_score, "weight": 0.15, "label": "Team & Culture"}
	weighted_sum += team_score * 0.15
	total_weight += 0.15

	# --- Speed (10%) ---
	var speed_score := _score_speed(state)
	breakdown["speed"] = {"score": speed_score, "weight": 0.10, "label": "Execution Speed"}
	weighted_sum += speed_score * 0.10
	total_weight += 0.10

	# --- Reputation (10%) ---
	var rep_score := _score_reputation(state)
	breakdown["reputation"] = {"score": rep_score, "weight": 0.10, "label": "Industry Reputation"}
	weighted_sum += rep_score * 0.10
	total_weight += 0.10

	var final_score: int = clampi(roundi(weighted_sum / maxf(total_weight, 0.01)), 0, 100)

	# Win bonus: winning adds a flat bonus to push winners into higher tiers.
	var win_bonus := 0
	if state.get("is_game_active") == false:
		var wins: Array = []
		if state.has_method("get") and state.get("_achieved_wins") is Array:
			wins = state.get("_achieved_wins")
		if not wins.is_empty():
			win_bonus = 15
	final_score = clampi(final_score + win_bonus, 0, 100)

	var grade := _to_grade(final_score)
	var summary := _build_summary(grade, final_score, breakdown)

	return {
		"score": final_score,
		"grade": grade,
		"grade_color": GRADE_COLORS.get(grade, Color.WHITE),
		"breakdown": breakdown,
		"summary": summary,
		"win_bonus": win_bonus,
	}


static func _to_grade(score: int) -> String:
	for grade in ["S", "A", "B", "C", "D"]:
		if score >= GRADE_THRESHOLDS[grade]:
			return grade
	return "F"


# ---------------------------------------------------------------------------
# Scoring axes
# ---------------------------------------------------------------------------

static func _score_finances(state: Node) -> float:
	var score := 0.0
	var company = state.get("company")
	var financials = state.get("financials")
	if company == null or financials == null:
		return 0.0

	# Cash position: more cash = better (log scale).
	var cash: float = maxf(float(company.get("cash")), 0.0)
	if cash >= 1_000_000:
		score += 35
	elif cash >= 100_000:
		score += 25
	elif cash >= 10_000:
		score += 15
	elif cash > 0:
		score += 5

	# Revenue strength.
	var revenue: float = maxf(float(financials.get("revenue")), 0.0)
	if revenue >= 100_000:
		score += 30
	elif revenue >= 50_000:
		score += 22
	elif revenue >= 10_000:
		score += 15
	elif revenue > 0:
		score += 8

	# Valuation.
	var valuation: float = maxf(float(company.get("valuation")), 0.0)
	if valuation >= 100_000_000:
		score += 35
	elif valuation >= 10_000_000:
		score += 28
	elif valuation >= 1_000_000:
		score += 18
	elif valuation > 0:
		score += 8

	return clampf(score, 0, 100)


static func _score_growth(state: Node) -> float:
	var score := 0.0
	var product = state.get("product")
	if product == null:
		return 0.0

	var users: int = maxi(int(product.get("users")), 0)
	if users >= 100_000:
		score += 50
	elif users >= 10_000:
		score += 40
	elif users >= 1_000:
		score += 28
	elif users >= 100:
		score += 15
	elif users > 0:
		score += 5

	# DAU ratio (engagement).
	var dau: int = maxi(int(product.get("dau")), 0)
	if users > 0:
		var dau_ratio: float = float(dau) / float(users)
		if dau_ratio >= 0.25:
			score += 30
		elif dau_ratio >= 0.15:
			score += 20
		elif dau_ratio >= 0.08:
			score += 10

	# Low churn is good.
	var churn: float = float(product.get("churn_rate"))
	if churn <= 0.03:
		score += 20
	elif churn <= 0.06:
		score += 12
	elif churn <= 0.10:
		score += 5

	return clampf(score, 0, 100)


static func _score_product(state: Node) -> float:
	var score := 0.0
	var product = state.get("product")
	if product == null:
		return 0.0

	# Features shipped.
	var features: Array = product.get("features") if product.get("features") is Array else []
	var feature_count: int = features.size()
	score += clampf(float(feature_count) * 8.0, 0, 40)

	# Stability.
	var stability: int = int(product.get("stability"))
	if stability >= 90:
		score += 25
	elif stability >= 75:
		score += 18
	elif stability >= 60:
		score += 10

	# Low tech debt.
	var tech_debt: int = int(product.get("tech_debt"))
	if tech_debt <= 10:
		score += 20
	elif tech_debt <= 25:
		score += 12
	elif tech_debt <= 40:
		score += 5

	# Low bugs.
	var bugs: int = int(product.get("bugs"))
	if bugs == 0:
		score += 15
	elif bugs <= 5:
		score += 8
	elif bugs <= 10:
		score += 3

	return clampf(score, 0, 100)


static func _score_team(state: Node) -> float:
	var score := 0.0
	var employees: Array = state.get("employees") if state.get("employees") is Array else []
	var count: int = employees.size()

	# Team size.
	if count >= 8:
		score += 30
	elif count >= 5:
		score += 22
	elif count >= 3:
		score += 15
	elif count >= 1:
		score += 8

	# Average morale.
	if count > 0:
		var total_morale := 0
		var total_skill := 0
		for emp in employees:
			total_morale += int(emp.get("morale")) if emp is Dictionary else int(emp.morale)
			total_skill += int(emp.get("skill")) if emp is Dictionary else int(emp.skill)
		var avg_morale: float = float(total_morale) / float(count)
		var avg_skill: float = float(total_skill) / float(count)

		if avg_morale >= 80:
			score += 35
		elif avg_morale >= 60:
			score += 22
		elif avg_morale >= 40:
			score += 10

		if avg_skill >= 75:
			score += 35
		elif avg_skill >= 55:
			score += 22
		elif avg_skill >= 40:
			score += 10

	return clampf(score, 0, 100)


static func _score_speed(state: Node) -> float:
	# Faster progression = higher score. Based on quarters elapsed vs achievements.
	var total_q: int = int(state.get("current_quarter")) + (int(state.get("current_year")) - 1) * 4
	if total_q <= 0:
		return 0.0

	var score := 0.0

	# Fewer quarters for the same achievements = better, but long runs still
	# earn meaningful credit — patient strategy shouldn't be heavily punished.
	if total_q <= 8:
		score += 50  # Reached this point in 2 years or less.
	elif total_q <= 12:
		score += 40
	elif total_q <= 20:
		score += 28
	else:
		score += 18

	# Profit streak bonus (achieving profit quickly).
	var streak: int = int(state.get("profit_streak"))
	if streak >= 6:
		score += 50
	elif streak >= 3:
		score += 30
	elif streak >= 1:
		score += 15

	return clampf(score, 0, 100)


static func _score_reputation(state: Node) -> float:
	var company = state.get("company")
	if company == null:
		return 0.0
	var rep: int = int(company.get("reputation"))

	if rep >= 90:
		return 100.0
	elif rep >= 75:
		return 80.0
	elif rep >= 60:
		return 60.0
	elif rep >= 45:
		return 40.0
	elif rep >= 30:
		return 20.0
	return 10.0


# ---------------------------------------------------------------------------
# Summary text
# ---------------------------------------------------------------------------

static func _build_summary(grade: String, score: int, _breakdown: Dictionary) -> String:
	match grade:
		"S":
			return "Legendary founder. You built something remarkable — a company that defines its generation."
		"A":
			return "Outstanding performance. Your startup thrived under your leadership and left a lasting mark."
		"B":
			return "Strong execution. You navigated the startup gauntlet well and built something real."
		"C":
			return "Decent run. You kept the lights on and made progress, but there's room to grow."
		"D":
			return "Rough going. The startup survived but struggled. Lessons learned for next time."
		"F":
			return "The startup didn't make it. But every great founder has a failure story. Try again."
		_:
			return "Your founder journey has concluded. Score: %d" % score
