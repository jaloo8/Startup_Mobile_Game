extends Node
## PrestigeManager — cross-run meta-progression ("Serial Entrepreneur" system).
##
## Persists Founder XP and Founder Level to user://prestige.dat.
## Each completed run (win or loss) earns XP based on performance.
## Levelling up unlocks permanent perks that make future runs feel fresh.
##
## Perks are applied automatically at the end of GameState.new_game().
##
## Usage:
##   PrestigeManager.get_level()            # current founder level (1-50)
##   PrestigeManager.get_xp()               # total accumulated XP
##   PrestigeManager.get_xp_for_next()      # XP needed to reach next level
##   PrestigeManager.get_perks()            # list of unlocked perk IDs
##   PrestigeManager.apply_perks(GameState) # apply unlocked bonuses to game state


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const SAVE_PATH := "user://prestige.dat"

## Maximum founder level.
const MAX_LEVEL := 50

## XP formula components (used in award_run_xp).
const BASE_XP := 50
const QUARTER_XP_BONUS := 5
const SCORE_XP_BONUS := 2

## XP required for each level.  Index 0 is unused (no level 0).
## Level 1 = 0 XP (starting), Level 2 = 100, Level 3 = 250, ...
## Formula: xp_for(n) = round(100 * (n - 1)^1.55)  for n >= 2
## Pre-computed so we never recalculate at runtime.
const LEVEL_XP_TABLE: Array = [
	0,       # index 0 — unused
	0,       # Level 1
	100,     # Level 2
	250,     # Level 3
	450,     # Level 4
	700,     # Level 5
	1000,    # Level 6
	1350,    # Level 7
	1750,    # Level 8
	2200,    # Level 9
	2700,    # Level 10
	3250,    # Level 11
	3850,    # Level 12
	4500,    # Level 13
	5200,    # Level 14
	5950,    # Level 15
	6750,    # Level 16
	7600,    # Level 17
	8500,    # Level 18
	9450,    # Level 19
	10450,   # Level 20
	11500,   # Level 21
	12600,   # Level 22
	13750,   # Level 23
	14950,   # Level 24
	16200,   # Level 25
	17500,   # Level 26
	18850,   # Level 27
	20250,   # Level 28
	21700,   # Level 29
	23200,   # Level 30
	24750,   # Level 31
	26350,   # Level 32
	28000,   # Level 33
	29700,   # Level 34
	31450,   # Level 35
	33250,   # Level 36
	35100,   # Level 37
	37000,   # Level 38
	38950,   # Level 39
	40950,   # Level 40
	43000,   # Level 41
	45100,   # Level 42
	47250,   # Level 43
	49450,   # Level 44
	51700,   # Level 45
	54000,   # Level 46
	56350,   # Level 47
	58750,   # Level 48
	61200,   # Level 49
	63700,   # Level 50
]

## Perk definitions — unlocked when the player reaches the specified level.
## Each perk is applied once per run via apply_perks().
const PERKS: Array = [
	{
		"id": "networking",
		"level": 2,
		"title": "Networking",
		"description": "Start with +5 reputation",
		"icon": "🤝",
	},
	{
		"id": "seed_money",
		"level": 5,
		"title": "Seed Money",
		"description": "Start with +$5K extra cash",
		"icon": "💰",
	},
	{
		"id": "industry_insider",
		"level": 8,
		"title": "Industry Insider",
		"description": "First fundraise threshold lowered by 3%",
		"icon": "🔑",
	},
	{
		"id": "talent_magnet",
		"level": 10,
		"title": "Talent Magnet",
		"description": "Interview costs reduced by 10%",
		"icon": "🧲",
	},
	{
		"id": "market_research",
		"level": 15,
		"title": "Market Research",
		"description": "See competitor stats in more detail",
		"icon": "📊",
	},
	{
		"id": "serial_founder",
		"level": 20,
		"title": "Serial Founder",
		"description": "Start with 1 free junior hire",
		"icon": "🚀",
	},
	{
		"id": "vc_rolodex",
		"level": 25,
		"title": "VC Rolodex",
		"description": "Fundraise offers are 8% higher",
		"icon": "📇",
	},
	{
		"id": "product_instinct",
		"level": 30,
		"title": "Product Instinct",
		"description": "Features ship 5% faster",
		"icon": "🎯",
	},
	{
		"id": "cash_flow_master",
		"level": 35,
		"title": "Cash Flow Master",
		"description": "Burn rate reduced by 5%",
		"icon": "💵",
	},
	{
		"id": "industry_legend",
		"level": 40,
		"title": "Industry Legend",
		"description": "All starting bonuses doubled",
		"icon": "👑",
	},
	{
		"id": "unicorn_maker",
		"level": 50,
		"title": "Unicorn Maker",
		"description": "Cosmetic title — golden name on leaderboard",
		"icon": "🦄",
	},
]


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when the player crosses a level threshold after earning XP.
signal level_up(new_level: int)

## Emitted after XP is awarded at the end of a run.
signal xp_awarded(amount: int, new_total: int)


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _xp: int = 0
var _level: int = 1
var _total_runs: int = 0
var _total_wins: int = 0


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_load()
	# Connect to game-end signals to auto-award XP.
	if GameState.has_signal("game_won"):
		GameState.game_won.connect(_on_game_won)
	if GameState.has_signal("game_over"):
		GameState.game_over.connect(_on_game_over)


# ---------------------------------------------------------------------------
# Public API — read-only queries
# ---------------------------------------------------------------------------

## Current founder level (1 to MAX_LEVEL).
func get_level() -> int:
	return _level


## Total accumulated Founder XP.
func get_xp() -> int:
	return _xp


## XP required to reach the next level.  Returns 0 if already at max.
func get_xp_for_next() -> int:
	if _level >= MAX_LEVEL:
		return 0
	return LEVEL_XP_TABLE[_level + 1]


## XP required for a specific level.
func get_xp_for_level(lvl: int) -> int:
	var clamped: int = clampi(lvl, 1, MAX_LEVEL)
	return LEVEL_XP_TABLE[clamped]


## Returns an array of perk IDs that the player has unlocked.
func get_perks() -> Array[String]:
	var result: Array[String] = []
	for perk: Dictionary in PERKS:
		var req_level: int = int(perk.get("level", 999))
		if _level >= req_level:
			result.append(str(perk.get("id", "")))
	return result


## Returns true if a specific perk ID is unlocked.
func has_perk(perk_id: String) -> bool:
	for perk: Dictionary in PERKS:
		if str(perk.get("id", "")) == perk_id:
			return _level >= int(perk.get("level", 999))
	return false


## Returns the full perk definition dictionaries for all unlocked perks.
func get_unlocked_perk_defs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for perk: Dictionary in PERKS:
		var req_level: int = int(perk.get("level", 999))
		if _level >= req_level:
			result.append(perk)
	return result


## Returns all perk definitions (for UI display of locked + unlocked).
func get_all_perk_defs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for perk: Dictionary in PERKS:
		result.append(perk)
	return result


## Returns the total number of completed runs.
func get_total_runs() -> int:
	return _total_runs


## Returns the total number of wins.
func get_total_wins() -> int:
	return _total_wins


## Progress through the current level as a 0.0-1.0 ratio (for progress bars).
func get_level_progress() -> float:
	if _level >= MAX_LEVEL:
		return 1.0
	var current_threshold: int = LEVEL_XP_TABLE[_level]
	var next_threshold: int = LEVEL_XP_TABLE[_level + 1]
	var range_size: int = next_threshold - current_threshold
	if range_size <= 0:
		return 1.0
	return clampf(float(_xp - current_threshold) / float(range_size), 0.0, 1.0)


# ---------------------------------------------------------------------------
# Public API — perk application
# ---------------------------------------------------------------------------

## Apply all unlocked perks to the current game state at the start of a run.
## Called automatically from GameState.new_game() after scenario setup.
func apply_perks(state: Node) -> void:
	var unlocked: Array[String] = get_perks()
	if unlocked.is_empty():
		return

	var has_legend: bool = "industry_legend" in unlocked  # doubles starting bonuses

	# --- Networking: +5 reputation (doubled to +10 with Industry Legend) ---
	if "networking" in unlocked:
		var bonus: int = 10 if has_legend else 5
		if state.get("company") != null:
			state.company.reputation = mini(state.company.reputation + bonus, 100)

	# --- Seed Money: +$5K cash (doubled to +$10K with Industry Legend) ---
	if "seed_money" in unlocked:
		var bonus: float = 10_000.0 if has_legend else 5_000.0
		if state.get("company") != null:
			state.company.cash += bonus

	# --- Industry Insider: stored as a flag for FundraisingEngine to read ---
	# The fundraise threshold shift is consumed in FundraisingEngine.
	# We store the value on the state node so the engine can pick it up.
	if "industry_insider" in unlocked:
		var shift: float = -0.06 if has_legend else -0.03
		state.set_meta("prestige_fundraise_threshold_shift", shift)

	# --- Talent Magnet: stored as a flag for HiringEngine to read ---
	if "talent_magnet" in unlocked:
		var discount: float = 0.20 if has_legend else 0.10
		state.set_meta("prestige_interview_cost_discount", discount)

	# --- Market Research: flag for CompetitorAI to expose more stats ---
	if "market_research" in unlocked:
		state.set_meta("prestige_competitor_detail", true)

	# --- Serial Founder: add 1 free junior hire ---
	if "serial_founder" in unlocked:
		var hire_count: int = 2 if has_legend else 1
		for _i in hire_count:
			_add_free_junior(state)

	# --- VC Rolodex: fundraise offers boosted ---
	if "vc_rolodex" in unlocked:
		var boost: float = 0.16 if has_legend else 0.08
		state.set_meta("prestige_fundraise_amount_boost", boost)

	# --- Product Instinct: features ship faster ---
	if "product_instinct" in unlocked:
		var boost: float = 0.10 if has_legend else 0.05
		state.set_meta("prestige_feature_speed_boost", boost)

	# --- Cash Flow Master: burn rate reduction ---
	if "cash_flow_master" in unlocked:
		var reduction: float = 0.10 if has_legend else 0.05
		state.set_meta("prestige_burn_rate_reduction", reduction)

	# --- Unicorn Maker: cosmetic flag ---
	if "unicorn_maker" in unlocked:
		state.set_meta("prestige_unicorn_maker", true)



# ---------------------------------------------------------------------------
# XP calculation and awarding
# ---------------------------------------------------------------------------

## Calculate and award XP for a completed run.
## Called automatically by signal handlers; can also be called manually.
func award_run_xp(is_win: bool) -> int:
	var quarters_survived: int = _total_quarters()
	var founder_score: int = _get_founder_score()

	# XP formula: base + quarter bonus + score bonus, wins get 2x
	var base_xp: int = BASE_XP + (quarters_survived * QUARTER_XP_BONUS) + (founder_score * SCORE_XP_BONUS)
	if is_win:
		base_xp *= 2

	_xp += base_xp
	_total_runs += 1
	if is_win:
		_total_wins += 1

	# Check for level-ups.
	var old_level: int = _level
	_recalculate_level()
	if _level > old_level:
		level_up.emit(_level)
		# Play celebration for level-ups.
		SfxPlayer.play("achievement")
		AnimHelper.haptic(&"heavy")
		var perk_def: Dictionary = _perk_at_level(_level)
		if not perk_def.is_empty():
			var icon: String = str(perk_def.get("icon", "⭐"))
			var title: String = str(perk_def.get("title", ""))
			ToastManager.show_achievement(
				"Founder Lv.%d — %s" % [_level, title], icon)
		else:
			ToastManager.show_achievement(
				"Founder Level %d!" % _level, "⭐")

	xp_awarded.emit(base_xp, _xp)
	_save()


	return base_xp


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_game_won(_win_type: String) -> void:
	award_run_xp(true)


func _on_game_over(_reason: String) -> void:
	award_run_xp(false)


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

## Recalculate _level from _xp (walk the table).
func _recalculate_level() -> void:
	_level = 1
	for i in range(2, MAX_LEVEL + 1):
		if _xp >= LEVEL_XP_TABLE[i]:
			_level = i
		else:
			break


## Get total quarters played in the current run.
func _total_quarters() -> int:
	if GameState == null or GameState.company == null:
		return 0
	return GameState.current_quarter + (GameState.current_year - 1) * 4


## Get the founder score from ScoringEngine for the current run.
func _get_founder_score() -> int:
	if GameState == null or GameState.company == null:
		return 0
	var result: Dictionary = ScoringEngine.calculate(GameState)
	return int(result.get("score", 0))


## Find the perk definition that unlocks at exactly the given level, or empty.
func _perk_at_level(lvl: int) -> Dictionary:
	for perk: Dictionary in PERKS:
		if int(perk.get("level", 0)) == lvl:
			return perk
	return {}


## Add a free junior employee to the game state.
func _add_free_junior(state: Node) -> void:
	if state.get("employees") == null:
		return
	var junior := EmployeeData.new()
	junior.employee_name = _random_junior_name()
	junior.employee_uid = "prestige_junior_%d" % randi()
	junior.specialty = EmployeeData.Specialty.BACKEND
	junior.seniority = EmployeeData.Seniority.JUNIOR
	junior.skill = 35
	junior.speed = 40
	junior.morale = 80
	junior.salary_per_quarter = 0.0  # Free hire — no salary cost first quarter
	junior.tenure_quarters = 0
	junior.assignment = EmployeeData.Assignment.FEATURES
	junior.bio = "A scrappy junior dev who joined through your founder network."
	state.employees.append(junior)


## Pick a random name for the free junior hire.
func _random_junior_name() -> String:
	var names: Array = [
		"Alex Chen", "Jordan Lee", "Sam Rivera", "Casey Kim",
		"Morgan Park", "Riley Nguyen", "Avery Shah", "Dakota Wells",
		"Quinn Torres", "Reese Patel",
	]
	return names[randi() % names.size()]


# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		return
	var data: Dictionary = parsed as Dictionary
	_xp         = maxi(0, int(data.get("xp", 0)))
	_total_runs = maxi(0, int(data.get("total_runs", 0)))
	_total_wins = maxi(0, int(data.get("total_wins", 0)))
	_recalculate_level()


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("PrestigeManager: failed to save to %s" % SAVE_PATH)
		return
	f.store_string(JSON.stringify({
		"xp":         _xp,
		"total_runs": _total_runs,
		"total_wins": _total_wins,
	}, "\t"))


## Erase all prestige progress (for debug / testing).
func reset_progress() -> void:
	_xp = 0
	_level = 1
	_total_runs = 0
	_total_wins = 0
	_save()
