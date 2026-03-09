extends Node
## Ad placement hooks. Add SDK calls when ready.

signal ad_shown(slot: String)
signal ad_reward_granted(slot: String)

var _last_interstitial_quarter: int = -10
var _ad_sdk_available: bool = false

const INTERSTITIAL_COOLDOWN_QUARTERS := 3


func _ready() -> void:
	_ad_sdk_available = _detect_ad_sdk()


func is_premium() -> bool:
	return Analytics.is_premium()


func is_ads_enabled() -> bool:
	if is_premium():
		return false
	if OS.has_feature("pc") or OS.has_feature("macos") or OS.has_feature("windows") or OS.has_feature("linux"):
		return false
	return true


func is_ad_available(slot: String) -> bool:
	if not is_ads_enabled():
		return false

	match slot:
		"interstitial_quarter_end", "interstitial_game_over":
			return _can_show_interstitial()
		"rewarded_reveal_stats", "rewarded_cash_bonus":
			return _ad_sdk_available
		"banner_dashboard":
			return _ad_sdk_available
	return false


func show_ad(slot: String) -> bool:
	if not is_ad_available(slot):
		return false

	match slot:
		"interstitial_quarter_end":
			_last_interstitial_quarter = GameState.total_quarters_elapsed()
			_show_interstitial(slot)
			return true
		"interstitial_game_over":
			_show_interstitial(slot)
			return true
		"rewarded_reveal_stats", "rewarded_cash_bonus":
			_show_rewarded(slot)
			return true
		"banner_dashboard":
			_show_banner(slot)
			return true

	return false


func _can_show_interstitial() -> bool:
	if not _ad_sdk_available:
		return false
	var elapsed := GameState.total_quarters_elapsed()
	return (elapsed - _last_interstitial_quarter) >= INTERSTITIAL_COOLDOWN_QUARTERS


func _show_interstitial(_slot: String) -> void:
	# TODO: AdMob.show_interstitial()
	ad_shown.emit(_slot)


func _show_rewarded(_slot: String) -> void:
	# TODO: AdMob.show_rewarded(), emit ad_reward_granted on callback
	ad_reward_granted.emit(_slot)


func _show_banner(_slot: String) -> void:
	# TODO: AdMob.show_banner()
	ad_shown.emit(_slot)


func hide_banner() -> void:
	# TODO: AdMob.hide_banner()
	pass


static func _detect_ad_sdk() -> bool:
	# TODO: return Engine.has_singleton("AdMob")
	return false
