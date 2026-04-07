extends Node
## CurrencyManager — VC Chip soft currency for Venture.
##
## VC Chips are a non-pay-to-win soft currency earned through gameplay.
## They can be spent on mild accelerators and cosmetics.
## Players can also earn bonus chips by watching rewarded ads (opt-in only).
##
## Philosophy: chips make the game feel more rewarding, never mandatory.
## Every chip purchase has a free alternative that just takes longer.
##
## Earn sources:
##   - Quarter completed with positive cash: +1 chip
##   - Feature shipped: +1–2 chips (quality-scaled)
##   - Milestone reached (users, revenue, IPO): +3–5 chips
##   - Returned after being away 2+ hours: +1–4 chips (via IdleEngine)
##   - Watched rewarded ad: +5 chips (opt-in, max 3 per day)
##
## Spend uses:
##   - Extra hiring candidate reveal: 3 chips
##   - Reroll event choice outcomes (see new options): 4 chips
##   - Speed boost: feature progress +10% this quarter: 5 chips
##   - Cosmetic: office theme unlock: 10 chips
##   - Double passive income for 1 hour: 6 chips


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const SAVE_PATH           := "user://currency_state.json"
const REWARDED_AD_REWARD  := 5
const MAX_REWARDED_ADS_PER_DAY := 3
const AD_COOLDOWN_HOURS   := 8  # minimum hours between ad sessions

## Chip costs (edit these to tune balance)
const COST_EXTRA_CANDIDATE  := 3
const COST_REROLL_EVENT     := 4
const COST_FEATURE_BOOST    := 5
const COST_DOUBLE_IDLE      := 6
const COST_OFFICE_THEME     := 10

## Earn amounts
const EARN_QUARTER_POSITIVE := 1
const EARN_FEATURE_QUALITY  := {0: 1, 1: 1, 2: 2}  # low/mid/high quality
const EARN_MILESTONE_SMALL  := 2
const EARN_MILESTONE_LARGE  := 5


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted after any earn/spend so UI can update the chip counter.
signal chips_changed(new_total: int, delta: int)

## Emitted when a rewarded ad should be shown (AdManager handles the actual SDK call).
signal rewarded_ad_requested()

## Emitted when a spend action completes successfully.
signal spend_completed(action: String, cost: int)


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var chips: int = 0
var total_earned: int = 0
var total_spent: int = 0

## Unix timestamp of the last rewarded ad watch.
var _last_ad_ts: int = 0
var _ads_today: int = 0
var _ads_day_stamp: int = 0  # day-of-year when _ads_today was last reset

## Active boosts: double idle income, etc.
var _double_idle_until: int = 0  # unix timestamp


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_load()


# ---------------------------------------------------------------------------
# Public — earn
# ---------------------------------------------------------------------------

## Called by SimulationEngine after a quarter is processed.
func on_quarter_completed(was_profitable: bool) -> void:
	if was_profitable:
		earn(EARN_QUARTER_POSITIVE, "quarter_positive")


## Called by GameState when a feature ships.
func on_feature_shipped(quality: int) -> void:
	# quality 0-100: low <40, mid 40-74, high 75+
	var tier := 0
	if quality >= 75:
		tier = 2
	elif quality >= 40:
		tier = 1
	var amount: int = EARN_FEATURE_QUALITY.get(tier, 1)
	earn(amount, "feature_shipped")


## Called by GameState when a milestone is hit.
func on_milestone(milestone_id: String) -> void:
	var big_milestones := ["ipo", "unicorn", "acquisition", "first_1k_users",
		"first_10k_users", "first_100k_users", "first_revenue"]
	var amount := EARN_MILESTONE_LARGE if milestone_id in big_milestones else EARN_MILESTONE_SMALL
	earn(amount, "milestone_%s" % milestone_id)


## Called by IdleEngine with the offline chip bonus.
func on_offline_return(chip_bonus: int) -> void:
	if chip_bonus > 0:
		earn(chip_bonus, "offline_return")


## Core earn — all paths go through here.
func earn(amount: int, source: String = "") -> void:
	if amount <= 0:
		return
	chips += amount
	total_earned += amount
	chips_changed.emit(chips, amount)
	_save()
	Analytics.track("chip_earned", {"amount": amount, "source": source,
		"total": total_earned})


# ---------------------------------------------------------------------------
# Public — spend
# ---------------------------------------------------------------------------

func can_afford(cost: int) -> bool:
	return chips >= cost


## Generic spend — returns true if successful.
func spend(cost: int, action: String) -> bool:
	if not can_afford(cost):
		return false
	chips -= cost
	total_spent += cost
	chips_changed.emit(chips, -cost)
	spend_completed.emit(action, cost)
	_save()
	Analytics.track("chip_spent", {"amount": cost, "action": action,
		"remaining": chips})
	return true


## Reveal an extra hiring candidate (3 chips).
func spend_extra_candidate() -> bool:
	return spend(COST_EXTRA_CANDIDATE, "extra_candidate")


## Reroll event choices (4 chips).
func spend_reroll_event() -> bool:
	return spend(COST_REROLL_EVENT, "reroll_event")


## Boost current feature progress by 10% (5 chips).
func spend_feature_boost() -> bool:
	if not spend(COST_FEATURE_BOOST, "feature_boost"):
		return false
	# Apply the boost immediately to the active feature
	if GameState.product != null and not GameState.product.target_feature_id.is_empty():
		GameState.product.feature_progress = minf(
			GameState.product.feature_progress + 0.10, 1.0)
	return true


## Double passive income for 1 hour (6 chips).
func spend_double_idle() -> bool:
	if not spend(COST_DOUBLE_IDLE, "double_idle"):
		return false
	_double_idle_until = Time.get_unix_time_from_system() + 3_600
	_save()
	return true


## Returns the passive income multiplier from active boosts.
func idle_multiplier() -> float:
	if Time.get_unix_time_from_system() < _double_idle_until:
		return 2.0
	return 1.0


## Returns seconds remaining on the double-idle boost (0 if inactive).
func double_idle_remaining() -> int:
	var remaining := _double_idle_until - Time.get_unix_time_from_system()
	return maxi(0, remaining)


# ---------------------------------------------------------------------------
# Public — rewarded ads
# ---------------------------------------------------------------------------

## Returns true if the player can watch another rewarded ad today.
func can_watch_rewarded_ad() -> bool:
	_maybe_reset_daily_ad_count()
	if _ads_today >= MAX_REWARDED_ADS_PER_DAY:
		return false
	# Respect minimum cooldown between watches
	var elapsed_hours := float(Time.get_unix_time_from_system() - _last_ad_ts) / 3_600.0
	return elapsed_hours >= float(AD_COOLDOWN_HOURS) or _last_ad_ts == 0


## Initiates a rewarded ad watch. AdManager should call on_rewarded_ad_complete()
## when the SDK confirms the user watched to completion.
func request_rewarded_ad() -> void:
	if not can_watch_rewarded_ad():
		return
	rewarded_ad_requested.emit()


## Called by AdManager (or a stub in dev) when the user finishes watching.
func on_rewarded_ad_complete() -> void:
	_maybe_reset_daily_ad_count()
	_ads_today += 1
	_last_ad_ts = Time.get_unix_time_from_system()
	earn(REWARDED_AD_REWARD, "rewarded_ad")
	_save()


## How many rewarded ads remain today.
func rewarded_ads_remaining() -> int:
	_maybe_reset_daily_ad_count()
	return maxi(0, MAX_REWARDED_ADS_PER_DAY - _ads_today)


func _maybe_reset_daily_ad_count() -> void:
	var today := Time.get_date_dict_from_system()
	var day_stamp: int = today["year"] * 1000 + today["day_of_year"]
	if day_stamp != _ads_day_stamp:
		_ads_today = 0
		_ads_day_stamp = day_stamp


# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		return
	chips          = clampi(int(parsed.get("chips", 0)), 0, 999_999)
	total_earned   = maxi(0, int(parsed.get("total_earned", 0)))
	total_spent    = maxi(0, int(parsed.get("total_spent", 0)))
	_last_ad_ts    = int(parsed.get("last_ad_ts", 0))
	_ads_today     = clampi(int(parsed.get("ads_today", 0)), 0, MAX_REWARDED_ADS_PER_DAY)
	_ads_day_stamp = int(parsed.get("ads_day_stamp", 0))
	_double_idle_until = int(parsed.get("double_idle_until", 0))


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"chips":            chips,
		"total_earned":     total_earned,
		"total_spent":      total_spent,
		"last_ad_ts":       _last_ad_ts,
		"ads_today":        _ads_today,
		"ads_day_stamp":    _ads_day_stamp,
		"double_idle_until":_double_idle_until,
	}, "\t"))
