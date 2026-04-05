extends Control
## Settings screen — analytics toggle, privacy policy, premium status, game info.

@onready var back_btn: Button = %BackButton
@onready var analytics_toggle: CheckButton = %AnalyticsToggle
@onready var analytics_desc: Label = %AnalyticsDesc
@onready var analytics_header: Label = %AnalyticsHeader
@onready var analytics_row: HBoxContainer = %AnalyticsRow
@onready var privacy_btn: Button = %PrivacyButton
@onready var privacy_panel: PanelContainer = %PrivacyPanel
@onready var privacy_text: RichTextLabel = %PrivacyText
@onready var close_privacy_btn: Button = %ClosePrivacyButton
@onready var version_label: Label = %VersionLabel
@onready var consent_banner: PanelContainer = %ConsentBanner
@onready var dismiss_banner_btn: Button = %DismissBannerButton
@onready var age_gate_panel: PanelContainer = %AgeGatePanel
@onready var age_confirm_btn: Button = %AgeConfirmButton
@onready var age_deny_btn: Button = %AgeDenyButton

# Dynamically created premium + tutorial controls.
var _premium_row: Control
var _tutorial_btn: Button


func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	analytics_toggle.toggled.connect(_on_analytics_toggled)
	privacy_btn.pressed.connect(_on_privacy)
	close_privacy_btn.pressed.connect(_on_close_privacy)
	dismiss_banner_btn.pressed.connect(_on_dismiss_banner)
	age_confirm_btn.pressed.connect(_on_age_confirmed)
	age_deny_btn.pressed.connect(_on_age_denied)

	privacy_panel.visible = false
	version_label.text = "Venture v%s · %s Mode" % [GameState.GAME_VERSION, AdManager.build_mode_label()]

	if AdManager.is_premium():
		analytics_header.text = "Analytics"
		analytics_row.visible = false
		analytics_toggle.visible = false
		analytics_desc.text = "Analytics are not collected in the premium version."
		consent_banner.visible = false
		age_gate_panel.visible = false
	else:
		analytics_toggle.button_pressed = Analytics.is_consent_given()
		_update_analytics_desc()

		if Analytics.is_first_launch() and not Analytics.is_age_confirmed():
			age_gate_panel.visible = true
			consent_banner.visible = false
		elif Analytics.is_first_launch():
			age_gate_panel.visible = false
			consent_banner.visible = true
		else:
			age_gate_panel.visible = false
			consent_banner.visible = false

	_build_premium_section()
	AdManager.premium_unlocked.connect(_on_premium_unlocked)
	UITouchHelper.harden_tree(self)
	Analytics.track_screen("settings")


func _on_age_confirmed() -> void:
	Analytics.confirm_age()
	age_gate_panel.visible = false
	consent_banner.visible = true


func _on_age_denied() -> void:
	Analytics.set_consent(false)
	age_gate_panel.visible = false
	consent_banner.visible = false
	analytics_toggle.button_pressed = false
	_update_analytics_desc()


func _on_analytics_toggled(enabled: bool) -> void:
	if not Analytics.is_age_confirmed() and enabled:
		analytics_toggle.button_pressed = false
		age_gate_panel.visible = true
		return
	Analytics.set_consent(enabled)
	_update_analytics_desc()


func _update_analytics_desc() -> void:
	if Analytics.is_consent_given():
		analytics_desc.text = "Anonymous gameplay data helps us improve the game.\nNo personal information is collected."
	else:
		analytics_desc.text = "Analytics are disabled. No data is being collected."


func _on_privacy() -> void:
	privacy_panel.visible = true
	var path := "res://PRIVACY_POLICY.txt"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			privacy_text.text = file.get_as_text()
			file = null
	else:
		privacy_text.text = "Privacy policy file not found."


func _on_close_privacy() -> void:
	privacy_panel.visible = false


func _on_dismiss_banner() -> void:
	consent_banner.visible = false


func _on_back() -> void:
	SceneLoader.goto_scene("res://src/ui/main_menu/main_menu.tscn")


# ─────────────────────────────────────────────────────────────────────────────
# Premium section (injected programmatically below the version label)
# ─────────────────────────────────────────────────────────────────────────────

func _build_premium_section() -> void:
	# Find the VBoxContainer that holds version_label and append after it.
	var parent := version_label.get_parent()
	if parent == null:
		return

	var insert_idx := version_label.get_index() + 1

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.18, 0.20, 0.30, 0.7))
	parent.add_child(sep)
	parent.move_child(sep, insert_idx)
	insert_idx += 1

	# Premium status / buy row
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	parent.move_child(row, insert_idx)
	insert_idx += 1
	_premium_row = row

	if AdManager.is_dev_mode():
		var icon_dev := Label.new()
		icon_dev.text = "DEV MODE - premium features unlocked for testing"
		icon_dev.add_theme_font_size_override("font_size", 14)
		icon_dev.add_theme_color_override("font_color", Color(0.66, 0.86, 1.0))
		row.add_child(icon_dev)
	elif AdManager.is_premium():
		var icon := Label.new()
		icon.text = "✓  Full Game — Unlocked"
		icon.add_theme_font_size_override("font_size", 14)
		icon.add_theme_color_override("font_color", Color(0.38, 0.88, 0.52))
		row.add_child(icon)
	else:
		var unlock_btn := Button.new()
		unlock_btn.text = "Unlock Full Game — $2.99"
		unlock_btn.add_theme_font_size_override("font_size", 14)
		unlock_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		var sn := StyleBoxFlat.new()
		sn.bg_color = Color(0.18, 0.44, 0.88)
		sn.set_corner_radius_all(9)
		sn.set_content_margin_all(12.0)
		unlock_btn.add_theme_stylebox_override("normal", sn)
		var sh := sn.duplicate() as StyleBoxFlat
		sh.bg_color = sn.bg_color.lightened(0.10)
		unlock_btn.add_theme_stylebox_override("hover", sh)
		var sp := sn.duplicate() as StyleBoxFlat
		sp.bg_color = sn.bg_color.darkened(0.12)
		unlock_btn.add_theme_stylebox_override("pressed", sp)
		unlock_btn.add_theme_stylebox_override("focus", sn)
		unlock_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		unlock_btn.pressed.connect(func() -> void:
			AdManager.show_paywall(
				func() -> void: _refresh_premium_row(),
				Callable()
			)
		)
		row.add_child(unlock_btn)

		var restore_btn := Button.new()
		restore_btn.text = "Restore"
		restore_btn.add_theme_font_size_override("font_size", 13)
		var rs := StyleBoxFlat.new()
		rs.bg_color = Color(0.14, 0.18, 0.30)
		rs.set_corner_radius_all(9)
		rs.set_content_margin_all(10.0)
		restore_btn.add_theme_stylebox_override("normal", rs)
		restore_btn.add_theme_stylebox_override("hover", rs)
		restore_btn.add_theme_stylebox_override("pressed", rs)
		restore_btn.pressed.connect(func() -> void:
			AdManager.restore_purchases(
				func() -> void: _refresh_premium_row(),
				Callable()
			)
		)
		row.add_child(restore_btn)

	# Replay tutorial button
	var sep2 := HSeparator.new()
	sep2.add_theme_color_override("color", Color(0.18, 0.20, 0.30, 0.5))
	parent.add_child(sep2)
	parent.move_child(sep2, insert_idx)
	insert_idx += 1

	var tut_btn := Button.new()
	tut_btn.text = "Replay Tutorial"
	tut_btn.add_theme_font_size_override("font_size", 13)
	tut_btn.add_theme_color_override("font_color", Color(0.55, 0.58, 0.72))
	var tb_style := StyleBoxFlat.new()
	tb_style.bg_color = Color(0.12, 0.14, 0.24)
	tb_style.set_corner_radius_all(7)
	tb_style.set_content_margin_all(10.0)
	tut_btn.add_theme_stylebox_override("normal", tb_style)
	var tb_hover := tb_style.duplicate() as StyleBoxFlat
	tb_hover.bg_color = tb_style.bg_color.lightened(0.08)
	tut_btn.add_theme_stylebox_override("hover", tb_hover)
	tut_btn.add_theme_stylebox_override("pressed", tb_style)
	tut_btn.add_theme_stylebox_override("focus", tb_style)
	tut_btn.pressed.connect(_on_replay_tutorial)
	parent.add_child(tut_btn)
	parent.move_child(tut_btn, insert_idx)
	_tutorial_btn = tut_btn


func _refresh_premium_row() -> void:
	# Rebuild the premium row to show "Unlocked" after purchase.
	if _premium_row and is_instance_valid(_premium_row):
		SceneLoader.free_children(_premium_row)
		var icon := Label.new()
		icon.text = "✓  Full Game — Unlocked"
		icon.add_theme_font_size_override("font_size", 14)
		icon.add_theme_color_override("font_color", Color(0.38, 0.88, 0.52))
		_premium_row.add_child(icon)


func _on_premium_unlocked() -> void:
	_refresh_premium_row()


func _on_replay_tutorial() -> void:
	TutorialManager.reset()
	# Confirmation toast via the button text itself.
	if _tutorial_btn:
		_tutorial_btn.text = "Tutorial reset — start a game to see it again"
		_tutorial_btn.disabled = true
