extends Control
## Settings screen — analytics toggle, privacy policy, game info.

@onready var back_btn: Button = %BackButton
@onready var analytics_toggle: CheckButton = %AnalyticsToggle
@onready var analytics_desc: Label = %AnalyticsDesc
@onready var privacy_btn: Button = %PrivacyButton
@onready var privacy_panel: PanelContainer = %PrivacyPanel
@onready var privacy_text: RichTextLabel = %PrivacyText
@onready var close_privacy_btn: Button = %ClosePrivacyButton
@onready var version_label: Label = %VersionLabel
@onready var consent_banner: PanelContainer = %ConsentBanner
@onready var dismiss_banner_btn: Button = %DismissBannerButton


func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	analytics_toggle.toggled.connect(_on_analytics_toggled)
	privacy_btn.pressed.connect(_on_privacy)
	close_privacy_btn.pressed.connect(_on_close_privacy)
	dismiss_banner_btn.pressed.connect(_on_dismiss_banner)

	analytics_toggle.button_pressed = Analytics.is_consent_given()
	_update_analytics_desc()

	privacy_panel.visible = false
	version_label.text = "Venture v0.1.0"

	if Analytics.is_first_launch() and not Analytics.is_premium():
		consent_banner.visible = true
	else:
		consent_banner.visible = false

	Analytics.track_screen("settings")


func _on_analytics_toggled(enabled: bool) -> void:
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
