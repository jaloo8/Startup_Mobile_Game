extends Node
## Ad placement hooks and free-tier gate.
##
## Free tier: full gameplay up to FREE_QUARTER_LIMIT quarters (end of Year 2).
## After that, show_paywall() blocks progression until the player unlocks.
## On PC/Mac (dev builds) the unlock is instant — no real IAP needed.
## On iOS/Android the IAP stub is called (wire up StoreKit/Google Play later).

signal ad_shown(slot: String)
signal ad_reward_granted(slot: String)
signal premium_unlocked   # emitted after successful purchase or dev unlock

var _last_interstitial_quarter: int = -10
var _ad_sdk_available: bool = false
var _paywall_canvas: CanvasLayer = null  # nil when paywall not shown

const INTERSTITIAL_COOLDOWN_QUARTERS := 3
## Quarters of free gameplay before the paywall triggers (8 = end of Year 2).
const FREE_QUARTER_LIMIT := 8


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


# ─────────────────────────────────────────────────────────────────────────────
# Free-tier gate
# ─────────────────────────────────────────────────────────────────────────────

## Returns true when the player has used up their free quarters and must pay
## to keep playing.  Always false for premium players and on desktop dev builds.
func is_game_locked() -> bool:
	if is_premium():
		return false
	# Desktop builds are always unlocked (dev / TestFlight convenience).
	if OS.has_feature("pc") or OS.has_feature("macos") or OS.has_feature("windows") or OS.has_feature("linux"):
		return false
	return GameState.total_quarters_elapsed() >= FREE_QUARTER_LIMIT


## Shows the paywall overlay.  `on_unlock` is called (with no args) if the
## player successfully unlocks; `on_cancel` is called if they dismiss.
func show_paywall(on_unlock: Callable = Callable(), on_cancel: Callable = Callable()) -> void:
	if _paywall_canvas and is_instance_valid(_paywall_canvas):
		return  # already visible
	_paywall_canvas = _build_paywall(on_unlock, on_cancel)
	get_tree().root.add_child(_paywall_canvas)
	_paywall_canvas.modulate.a = 0.0
	var tw := _paywall_canvas.create_tween()
	tw.tween_property(_paywall_canvas, "modulate:a", 1.0, 0.35)


func _dismiss_paywall() -> void:
	if _paywall_canvas and is_instance_valid(_paywall_canvas):
		var tw := _paywall_canvas.create_tween()
		tw.tween_property(_paywall_canvas, "modulate:a", 0.0, 0.25)
		tw.finished.connect(func() -> void:
			if _paywall_canvas and is_instance_valid(_paywall_canvas):
				_paywall_canvas.queue_free()
			_paywall_canvas = null
		)


func _do_purchase(on_unlock: Callable) -> void:
	# On desktop / dev builds unlock immediately so development stays friction-free.
	if OS.has_feature("pc") or OS.has_feature("macos") or OS.has_feature("windows") or OS.has_feature("linux"):
		Analytics.set_premium(true)
		_dismiss_paywall()
		premium_unlocked.emit()
		if on_unlock.is_valid():
			on_unlock.call()
		return

	# Mobile — call the platform IAP.
	# TODO: hook up StoreKit (iOS) or Google Play Billing (Android).
	# On success: Analytics.set_premium(true), _dismiss_paywall(), premium_unlocked.emit(), on_unlock.call()
	# On failure / cancel: just _dismiss_paywall() or show an error.
	push_warning("AdManager: IAP not yet wired — purchase ignored on this platform.")


func _build_paywall(on_unlock: Callable, on_cancel: Callable) -> CanvasLayer:
	var cl := CanvasLayer.new()
	cl.layer = 60  # above tutorial (50), below nothing

	# Full-screen blocking backdrop
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.07, 0.94)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(bg)

	# Center card
	var card := PanelContainer.new()
	card.anchor_left = 0.1
	card.anchor_right = 0.9
	card.anchor_top = 0.5
	card.anchor_bottom = 0.5
	card.offset_top = -175.0
	card.offset_bottom = 175.0
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.10, 0.12, 0.22)
	cs.set_corner_radius_all(16)
	cs.set_content_margin_all(24.0)
	cs.border_width_top = 1
	cs.border_width_left = 1
	cs.border_width_right = 1
	cs.border_width_bottom = 1
	cs.border_color = Color(0.30, 0.35, 0.60, 0.5)
	card.add_theme_stylebox_override("panel", cs)
	cl.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	# Lock icon + title
	var lock_lbl := Label.new()
	lock_lbl.text = "🔒  Year 3 Locked"
	lock_lbl.add_theme_font_size_override("font_size", 20)
	lock_lbl.add_theme_color_override("font_color", Color(0.96, 0.96, 1.0))
	lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lock_lbl)

	# Sub-message
	var sub := Label.new()
	sub.text = "You've played 2 years free!\nUnlock the full game to keep building."
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.68, 0.70, 0.82))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(sub)

	# What you get
	var perks_lbl := Label.new()
	perks_lbl.text = "✓  Play until IPO or acquisition\n✓  All company types unlocked\n✓  No ads — ever"
	perks_lbl.add_theme_font_size_override("font_size", 13)
	perks_lbl.add_theme_color_override("font_color", Color(0.45, 0.85, 0.55))
	perks_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(perks_lbl)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.20, 0.24, 0.40, 0.5))
	vbox.add_child(sep)

	# Buy button
	var buy_btn := Button.new()
	buy_btn.text = "Unlock Full Game — $2.99"
	buy_btn.add_theme_font_size_override("font_size", 15)
	buy_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	var buy_n := StyleBoxFlat.new()
	buy_n.bg_color = Color(0.18, 0.44, 0.88)
	buy_n.set_corner_radius_all(10)
	buy_n.set_content_margin_all(14.0)
	buy_btn.add_theme_stylebox_override("normal", buy_n)
	var buy_h := buy_n.duplicate() as StyleBoxFlat
	buy_h.bg_color = buy_n.bg_color.lightened(0.10)
	buy_btn.add_theme_stylebox_override("hover", buy_h)
	var buy_p := buy_n.duplicate() as StyleBoxFlat
	buy_p.bg_color = buy_n.bg_color.darkened(0.12)
	buy_btn.add_theme_stylebox_override("pressed", buy_p)
	buy_btn.add_theme_stylebox_override("focus", buy_n)
	buy_btn.pressed.connect(func() -> void: _do_purchase(on_unlock))
	vbox.add_child(buy_btn)

	# Restore / Cancel
	var cancel_btn := Button.new()
	cancel_btn.text = "Maybe Later"
	cancel_btn.add_theme_font_size_override("font_size", 12)
	cancel_btn.add_theme_color_override("font_color", Color(0.38, 0.40, 0.55))
	var blank := StyleBoxFlat.new()
	blank.bg_color = Color(0, 0, 0, 0)
	blank.set_content_margin_all(8.0)
	cancel_btn.add_theme_stylebox_override("normal", blank)
	cancel_btn.add_theme_stylebox_override("hover", blank)
	cancel_btn.add_theme_stylebox_override("pressed", blank)
	cancel_btn.add_theme_stylebox_override("focus", blank)
	cancel_btn.pressed.connect(func() -> void:
		_dismiss_paywall()
		if on_cancel.is_valid():
			on_cancel.call()
	)
	vbox.add_child(cancel_btn)

	return cl
