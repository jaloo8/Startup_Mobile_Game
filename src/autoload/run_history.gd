extends Node
## RunHistory — persistent cross-run history and hall of fame tracking.
##
## Records the outcome of every completed run (win or loss) and persists
## them to user:// so they survive across sessions.  Provides a sorted
## leaderboard, aggregate stats, and per-run detail lookups.
##
## Usage:
##   RunHistory.get_all()   -> Array[Dictionary]  — all runs, best score first
##   RunHistory.get_best()  -> Dictionary          — highest-scoring run
##   RunHistory.get_stats() -> Dictionary          — aggregate stats

const SAVE_PATH := "user://run_history.dat"
const MAX_RUNS := 100


## Internal storage — newest entries appended, sorted on read.
var _runs: Array[Dictionary] = []


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_load()
	if GameState.has_signal("game_won"):
		GameState.game_won.connect(_on_game_won)
	if GameState.has_signal("game_over"):
		GameState.game_over.connect(_on_game_over)


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_game_won(win_type: String) -> void:
	record_run(GameState, "win", win_type)


func _on_game_over(reason: String) -> void:
	record_run(GameState, "loss", reason)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Capture a snapshot of the current run and persist it.
func record_run(state: Node, outcome: String, reason: String = "") -> void:
	var company: Variant = state.get("company")
	var product: Variant = state.get("product")
	var financials: Variant = state.get("financials")
	var employees: Variant = state.get("employees")

	var company_name: String = ""
	var company_type: String = ""
	var niche: String = ""
	var final_cash: float = 0.0
	if company != null:
		company_name = str(company.get("company_name")) if company.get("company_name") != null else ""
		if company.has_method("type_name"):
			company_type = company.type_name()
		else:
			company_type = str(CompanyData.TYPE_NAMES.get(int(company.get("type")), "Unknown"))
		var niche_val: Variant = company.get("niche_name")
		niche = str(niche_val) if niche_val != null and str(niche_val).strip_edges() != "" else ""
		final_cash = float(company.get("cash")) if company.get("cash") != null else 0.0

	var peak_users: int = _calculate_peak_users(state)
	var team_size: int = 0
	if employees is Array:
		team_size = employees.size()

	var features_shipped: int = 0
	if product != null:
		if product.has_method("feature_count"):
			features_shipped = product.feature_count()
		elif product.get("features") is Array:
			features_shipped = product.get("features").size()

	var quarters_survived: int = 0
	if state.has_method("total_quarters_elapsed"):
		quarters_survived = state.total_quarters_elapsed()
	else:
		quarters_survived = (int(state.get("current_year")) - 1) * 4 + (int(state.get("current_quarter")) - 1)

	var scoring_result: Dictionary = ScoringEngine.calculate(state)
	var founder_score: int = scoring_result.get("score", 0)
	var grade: String = scoring_result.get("grade", "F")
	var difficulty_val: Variant = state.get("difficulty")
	var diff_str: String = str(difficulty_val) if difficulty_val != null else "normal"

	var entry: Dictionary = {
		"company_name": company_name,
		"company_type": company_type,
		"niche": niche,
		"difficulty": diff_str,
		"outcome": outcome,
		"reason": reason,
		"quarters_survived": quarters_survived,
		"final_cash": final_cash,
		"peak_users": peak_users,
		"team_size": team_size,
		"features_shipped": features_shipped,
		"founder_score": founder_score,
		"grade": grade,
		"timestamp": Time.get_unix_time_from_system(),
	}

	_runs.append(entry)

	# Trim oldest runs if over the limit.
	if _runs.size() > MAX_RUNS:
		# Sort by timestamp ascending, remove the oldest.
		_runs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a.get("timestamp", 0)) < float(b.get("timestamp", 0)))
		_runs = _runs.slice(_runs.size() - MAX_RUNS)

	_save()



## Returns all runs sorted by founder_score descending (leaderboard order).
func get_all() -> Array[Dictionary]:
	var sorted: Array[Dictionary] = _runs.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("founder_score", 0)) > int(b.get("founder_score", 0)))
	return sorted


## Returns the highest-scoring run, or an empty Dictionary if no runs exist.
func get_best() -> Dictionary:
	if _runs.is_empty():
		return {}
	var best: Dictionary = _runs[0]
	for run: Dictionary in _runs:
		if int(run.get("founder_score", 0)) > int(best.get("founder_score", 0)):
			best = run
	return best


## Returns aggregate statistics across all recorded runs.
func get_stats() -> Dictionary:
	var total_runs: int = _runs.size()
	var wins: int = 0
	var losses: int = 0
	var best_grade: String = "F"
	var best_grade_score: int = -1
	var total_score: int = 0
	var total_quarters: int = 0
	var fastest_win: int = -1

	for run: Dictionary in _runs:
		var outcome: String = str(run.get("outcome", ""))
		if outcome == "win":
			wins += 1
			var q: int = int(run.get("quarters_survived", 0))
			if fastest_win < 0 or q < fastest_win:
				fastest_win = q
		else:
			losses += 1

		var score: int = int(run.get("founder_score", 0))
		total_score += score
		total_quarters += int(run.get("quarters_survived", 0))

		if score > best_grade_score:
			best_grade_score = score
			best_grade = str(run.get("grade", "F"))

	var avg_score: int = 0
	if total_runs > 0:
		avg_score = roundi(float(total_score) / float(total_runs))

	return {
		"total_runs": total_runs,
		"wins": wins,
		"losses": losses,
		"best_grade": best_grade,
		"avg_score": avg_score,
		"total_quarters_played": total_quarters,
		"fastest_win": fastest_win,
	}


## Returns total number of recorded runs.
func run_count() -> int:
	return _runs.size()


# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------

func _save() -> void:
	var data: Array = []
	for run: Dictionary in _runs:
		data.append(run)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func _load() -> void:
	_runs.clear()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return  # No history yet — clean slate.
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_warning("RunHistory: corrupted history file, starting fresh")
		return
	var data: Variant = json.data
	if not data is Array:
		return
	for item in data:
		if item is Dictionary:
			_runs.append(item)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _calculate_peak_users(state: Node) -> int:
	var peak: int = 0
	var history_data: Variant = state.get("history")
	if history_data is Array:
		for snap in history_data:
			if snap is Dictionary:
				var u: int = int(snap.get("users", 0))
				if u > peak:
					peak = u
	var product: Variant = state.get("product")
	if product != null:
		var current_users: Variant = product.get("users")
		if current_users != null and int(current_users) > peak:
			peak = int(current_users)
	return peak
