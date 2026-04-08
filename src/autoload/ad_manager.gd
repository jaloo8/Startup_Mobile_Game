extends Node
## Ad placement hooks and free-tier gate.
##
## Free tier: full gameplay up to FREE_QUARTER_LIMIT quarters (end of Year 2).
## After that, show_paywall() blocks progression until the player unlocks.
## In dev mode, unlock/paywall are bypassed for faster iteration.
## In release mode, monetization follows premium + store bridge behavior.

signal ad_shown(slot: String)
signal ad_reward_granted(slot: String)
signal premium_unlocked   # emitted after successful purchase or dev unlock
signal purchase_failed(message: String)

var _last_interstitial_quarter: int = -10
var _ad_sdk_available: bool = false
var _paywall_canvas: CanvasLayer = null  # nil when paywall not shown
var _iap_provider: Object = null
var _purchase_in_flight := false
var _restore_in_flight := false
var _pending_purchase_unlock: Callable = Callable()
var _pending_purchase_cancel: Callable = Callable()
var _pending_restore_ok: Callable = Callable()
var _pending_restore_fail: Callable = Callable()

const INTERSTITIAL_COOLDOWN_QUARTERS := 3
## Quarters of free gameplay before the paywall triggers (8 = end of Year 2).
const FREE_QUARTER_LIMIT := 8
const FREE_SAVE_SLOT_LIMIT := 2
const PREMIUM_SAVE_SLOT_LIMIT := 5
const PREMIUM_UNLOCK_PRODUCT_ID := "venture.full_game_unlock"
# Temporary gameplay-first mode: disable monetization/purchase flows.
const MONETIZATION_TEMP_DISABLED := true
const BUILD_MODE_DEV := "dev"
const BUILD_MODE_RELEASE := "release"
# Optional local override for testing:
#   ""         -> auto (editor/debug = dev, export = release)
#   "dev"      -> force dev behavior
#   "release"  -> force release behavior
const BUILD_MODE_OVERRIDE := ""


static func current_build_mode() -> String:
	var forced := BUILD_MODE_OVERRIDE.strip_edges().to_lower()
	if forced == BUILD_MODE_DEV or forced == BUILD_MODE_RELEASE:
		return forced
	if OS.has_feature("editor") or OS.is_debug_build():
		return BUILD_MODE_DEV
	return BUILD_MODE_RELEASE


static func is_dev_mode() -> bool:
	return current_build_mode() == BUILD_MODE_DEV


static func build_mode_label() -> String:
	return "Dev" if is_dev_mode() else "Release"


func _ready() -> void:
	if MONETIZATION_TEMP_DISABLED:
		_ad_sdk_available = false
		return
	_ad_sdk_available = _detect_ad_sdk()
	_setup_iap_provider()
	if _iap_provider == null and not _is_desktop_platform():
		push_warning("AdManager: no IAP bridge found (InAppStore / GodotGooglePlayBilling). Purchases will fail on this build.")


func is_premium() -> bool:
	if MONETIZATION_TEMP_DISABLED:
		return true
	if is_dev_mode():
		return true
	return Analytics.is_premium()


func is_ads_enabled() -> bool:
	if MONETIZATION_TEMP_DISABLED:
		return false
	if is_premium():
		return false
	if _is_desktop_platform():
		return false
	return true


func max_save_slots() -> int:
	if MONETIZATION_TEMP_DISABLED:
		return PREMIUM_SAVE_SLOT_LIMIT
	if is_premium():
		return PREMIUM_SAVE_SLOT_LIMIT
	if _is_desktop_platform() and _iap_provider == null:
		return PREMIUM_SAVE_SLOT_LIMIT
	return FREE_SAVE_SLOT_LIMIT


static func _is_desktop_platform() -> bool:
	return OS.has_feature("pc") or OS.has_feature("macos") or OS.has_feature("windows") or OS.has_feature("linux")


func is_ad_available(slot: String) -> bool:
	if MONETIZATION_TEMP_DISABLED:
		return false
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
	if MONETIZATION_TEMP_DISABLED:
		return false
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


func _setup_iap_provider() -> void:
	if MONETIZATION_TEMP_DISABLED:
		return
	_iap_provider = null
	# iOS native bridge (StoreKit plugin commonly registered as "InAppStore")
	if Engine.has_singleton("InAppStore"):
		_iap_provider = Engine.get_singleton("InAppStore")
	# Android native bridge (common singleton name in billing plugins)
	elif Engine.has_singleton("GodotGooglePlayBilling"):
		_iap_provider = Engine.get_singleton("GodotGooglePlayBilling")
	if _iap_provider == null:
		return
	_wire_iap_signal("purchase_success", Callable(self, "_on_iap_purchase_success"))
	_wire_iap_signal("purchase_failed", Callable(self, "_on_iap_purchase_failed"))
	_wire_iap_signal("purchase_error", Callable(self, "_on_iap_purchase_failed"))
	_wire_iap_signal("purchase_cancelled", Callable(self, "_on_iap_purchase_cancelled"))
	_wire_iap_signal("purchases_restored", Callable(self, "_on_iap_restore_success"))
	_wire_iap_signal("restore_success", Callable(self, "_on_iap_restore_success"))
	_wire_iap_signal("restore_failed", Callable(self, "_on_iap_restore_failed"))


func _wire_iap_signal(signal_name: String, callable: Callable) -> void:
	if _iap_provider == null:
		return
	if not _iap_provider.has_signal(signal_name):
		return
	if not _iap_provider.is_connected(signal_name, callable):
		_iap_provider.connect(signal_name, callable)


func _try_iap_call(candidates: Array[String], args: Array = []) -> bool:
	if _iap_provider == null:
		return false
	for method_name in candidates:
		if _iap_provider.has_method(method_name):
			_iap_provider.callv(method_name, args)
			return true
	return false


func purchase_full_game(on_unlock: Callable = Callable(), on_cancel: Callable = Callable()) -> void:
	if MONETIZATION_TEMP_DISABLED:
		if on_unlock.is_valid():
			on_unlock.call()
		return
	if is_premium():
		if on_unlock.is_valid():
			on_unlock.call()
		return
	if _purchase_in_flight:
		return
	_pending_purchase_unlock = on_unlock
	_pending_purchase_cancel = on_cancel

	# Dev mode bypasses store purchase for fast local iteration.
	if is_dev_mode():
		_complete_premium_unlock()
		return

	# Desktop fallback while store bridge is unavailable.
	if _is_desktop_platform() and _iap_provider == null:
		_complete_premium_unlock()
		return

	_purchase_in_flight = true
	var started := _try_iap_call(
		["purchase", "purchase_product", "buy", "purchase_item"],
		[PREMIUM_UNLOCK_PRODUCT_ID]
	)
	if not started:
		_fail_purchase("In-app purchase bridge is unavailable on this build.")


func restore_purchases(on_restored: Callable = Callable(), on_failed: Callable = Callable()) -> void:
	if MONETIZATION_TEMP_DISABLED:
		if on_restored.is_valid():
			on_restored.call()
		return
	if is_premium():
		if on_restored.is_valid():
			on_restored.call()
		return
	if _restore_in_flight:
		return
	_pending_restore_ok = on_restored
	_pending_restore_fail = on_failed

	if is_dev_mode():
		_complete_premium_unlock()
		return

	if _is_desktop_platform() and _iap_provider == null:
		_complete_premium_unlock()
		return

	_restore_in_flight = true
	var started := _try_iap_call(
		["restore_purchases", "restore", "restore_transactions"],
		[]
	)
	if not started:
		_restore_in_flight = false
		_emit_restore_failed("Restore is not available on this build.")


func _complete_premium_unlock() -> void:
	_purchase_in_flight = false
	_restore_in_flight = false
	Analytics.set_premium(true)
	_dismiss_paywall()
	premium_unlocked.emit()

	var unlock_cb := _pending_purchase_unlock
	var restore_cb := _pending_restore_ok
	_pending_purchase_unlock = Callable()
	_pending_purchase_cancel = Callable()
	_pending_restore_ok = Callable()
	_pending_restore_fail = Callable()

	if unlock_cb.is_valid():
		unlock_cb.call()
	if restore_cb.is_valid():
		restore_cb.call()


func _fail_purchase(message: String) -> void:
	_purchase_in_flight = false
	_emit_purchase_failed(message)
	var cancel_cb := _pending_purchase_cancel
	_pending_purchase_unlock = Callable()
	_pending_purchase_cancel = Callable()
	if cancel_cb.is_valid():
		cancel_cb.call()


func _emit_purchase_failed(message: String) -> void:
	push_warning("AdManager: purchase failed: %s" % message)
	purchase_failed.emit(message)


func _emit_restore_failed(message: String) -> void:
	_restore_in_flight = false
	push_warning("AdManager: restore failed: %s" % message)
	purchase_failed.emit(message)
	if _pending_restore_fail.is_valid():
		_pending_restore_fail.call()
	_pending_restore_ok = Callable()
	_pending_restore_fail = Callable()


func _on_iap_purchase_success(_a = null, _b = null, _c = null) -> void:
	_complete_premium_unlock()


func _on_iap_purchase_failed(_a = null, _b = null, _c = null) -> void:
	_fail_purchase("Store declined the purchase.")


func _on_iap_purchase_cancelled(_a = null, _b = null, _c = null) -> void:
	_fail_purchase("Purchase canceled.")


func _on_iap_restore_success(_a = null, _b = null, _c = null) -> void:
	_complete_premium_unlock()


func _on_iap_restore_failed(_a = null, _b = null, _c = null) -> void:
	_restore_in_flight = false
	_emit_restore_failed("No eligible purchase found to restore.")


# ─────────────────────────────────────────────────────────────────────────────
# Free-tier gate
# ─────────────────────────────────────────────────────────────────────────────

## Returns true when the player has used up their free quarters and must pay
## to keep playing.  Always false for premium players and on desktop dev builds.
func is_game_locked() -> bool:
	if MONETIZATION_TEMP_DISABLED:
		return false
	if is_premium():
		return false
	if is_dev_mode():
		return false
	# Desktop fallback remains unlocked while no purchase bridge is available.
	if _is_desktop_platform() and _iap_provider == null:
		return false
	return GameState.total_quarters_elapsed() >= FREE_QUARTER_LIMIT


## Shows the paywall overlay.  `on_unlock` is called (with no args) if the
## player successfully unlocks; `on_cancel` is called if they dismiss.
func show_paywall(on_unlock: Callable = Callable(), on_cancel: Callable = Callable()) -> void:
	if MONETIZATION_TEMP_DISABLED:
		if on_unlock.is_valid():
			on_unlock.call()
		return
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
	purchase_full_game(on_unlock, Callable())


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
	sub.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	sub.add_theme_color_override("font_color", Color(0.68, 0.70, 0.82))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(sub)

	# What you get
	var perks_lbl := Label.new()
	perks_lbl.text = "✓  Play until IPO or acquisition\n✓  Full save slots unlocked\n✓  No ads — ever"
	perks_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	perks_lbl.add_theme_color_override("font_color", Color(0.45, 0.85, 0.55))
	perks_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(perks_lbl)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.20, 0.24, 0.40, 0.5))
	vbox.add_child(sep)

	# Buy button
	var buy_btn := Button.new()
	buy_btn.text = "Unlock Full Game — $2.99"
	buy_btn.add_theme_font_size_override("font_size", ThemeManager.FONT_MD)
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
	buy_btn.pressed.connect(func() -> void:
		_do_purchase(on_unlock)
	)
	vbox.add_child(buy_btn)

	var restore_btn := Button.new()
	restore_btn.text = "Restore Purchase"
	restore_btn.add_theme_font_size_override("font_size", 12)
	restore_btn.add_theme_color_override("font_color", Color(0.72, 0.80, 0.95))
	var restore_style := StyleBoxFlat.new()
	restore_style.bg_color = Color(0.16, 0.20, 0.32)
	restore_style.set_corner_radius_all(8)
	restore_style.set_content_margin_all(10.0)
	restore_btn.add_theme_stylebox_override("normal", restore_style)
	restore_btn.add_theme_stylebox_override("hover", restore_style)
	restore_btn.add_theme_stylebox_override("pressed", restore_style)
	restore_btn.pressed.connect(func() -> void:
		var restored_cb: Callable = func() -> void:
			if on_unlock.is_valid():
				on_unlock.call()
		var failed_cb: Callable = func() -> void:
			_emit_purchase_failed("No purchase found to restore.")
			_dismiss_paywall()
			if on_cancel.is_valid():
				on_cancel.call()
		restore_purchases(restored_cb, failed_cb)
	)
	vbox.add_child(restore_btn)

	var note_lbl := Label.new()
	note_lbl.text = "Purchases are processed by Apple App Store / Google Play."
	note_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	note_lbl.add_theme_color_override("font_color", Color(0.55, 0.58, 0.7))
	note_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(note_lbl)

	# Cancel
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
