extends Control
## Product overview screen — see product health and feature list.

@onready var features_label: Label = %FeaturesLabel
@onready var tech_debt_bar: ProgressBar = %TechDebtBar
@onready var bugs_label: Label = %BugsLabel
@onready var stability_bar: ProgressBar = %StabilityBar
@onready var ux_bar: ProgressBar = %UxBar
@onready var users_label: Label = %UsersLabel
@onready var churn_label: Label = %ChurnLabel
@onready var feature_list_container: VBoxContainer = %FeatureListContainer
@onready var back_btn: Button = %BackButton
@onready var build_status: Label = %BuildStatus
@onready var build_progress: ProgressBar = %BuildProgress
@onready var pick_btn: Button = %PickFeatureButton
@onready var picker_panel: PanelContainer = %FeaturePickerPanel
@onready var picker_container: VBoxContainer = %FeaturePickerContainer

const MAX_VISIBLE_FEATURES := 50


func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	pick_btn.pressed.connect(_on_pick_feature)
	%TechDebtTitle.pressed.connect(Glossary.show_term.bind("tech_debt"))
	%StabilityTitle.pressed.connect(Glossary.show_term.bind("stability"))
	%UxTitle.pressed.connect(Glossary.show_term.bind("ux_score"))
	%ChurnTitle.pressed.connect(Glossary.show_term.bind("churn_rate"))
	picker_panel.visible = false
	_refresh()
	Analytics.track_screen("product")


func _refresh() -> void:
	var p: ProductData = GameState.product
	if p == null or GameState.company == null:
		return

	if p.feature_count() == 0:
		features_label.text = "No features shipped yet"
	elif p.feature_count() == 1:
		features_label.text = "1 feature shipped"
	else:
		features_label.text = "%d features shipped · avg quality %d/100" % [p.feature_count(), roundi(p.avg_feature_quality())]
	tech_debt_bar.value = p.tech_debt
	if p.bugs == 0:
		bugs_label.text = "None"
	elif p.bugs == 1:
		bugs_label.text = "1 known bug"
	else:
		bugs_label.text = "%d known bugs" % p.bugs
	stability_bar.value = p.stability
	ux_bar.value = p.ux_score
	if p.users == 0:
		users_label.text = "No users yet"
	else:
		users_label.text = "%s users · %s daily active" % [SceneLoader.format_number(p.users), SceneLoader.format_number(p.dau)]
	churn_label.text = "%.1f%% per quarter" % (p.churn_rate * 100)

	_refresh_build_status()
	SceneLoader.free_children(feature_list_container)

	if p.features.is_empty():
		var lbl := Label.new()
		lbl.text = "Assign engineers to Features to start building."
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		feature_list_container.add_child(lbl)
		return

	var visible_features: Array = p.features
	if visible_features.size() > MAX_VISIBLE_FEATURES:
		visible_features = visible_features.slice(-MAX_VISIBLE_FEATURES)

	for f in visible_features:
		var lbl := Label.new()
		var quality: int = f.get("quality", 0)
		var color: Color
		if quality >= 70:
			color = Color(0.3, 0.85, 0.4)
		elif quality >= 50:
			color = Color(0.9, 0.8, 0.2)
		else:
			color = Color(0.9, 0.3, 0.3)
		lbl.text = "%s · %d/100 · shipped Q%d" % [f.get("name", "?"), quality, f.get("quarter_shipped", 0)]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", color)
		feature_list_container.add_child(lbl)


func _refresh_build_status() -> void:
	var p: ProductData = GameState.product
	var target: Dictionary = p.get_target_feature(GameState.company.type)
	if target.is_empty():
		build_status.text = "No feature selected — pick one below"
		build_progress.value = 0
		build_progress.max_value = 100
		pick_btn.text = "Choose Next Feature"
		pick_btn.disabled = false
	else:
		var cost: float = float(target.get("cost", 100))
		build_status.text = "Building: %s" % target.get("name", "???")
		build_progress.max_value = cost
		build_progress.value = p.feature_progress
		pick_btn.text = "Building %s..." % target.get("name", "")
		pick_btn.disabled = true


func _on_pick_feature() -> void:
	picker_panel.visible = not picker_panel.visible
	if picker_panel.visible:
		_refresh_picker()


func _refresh_picker() -> void:
	SceneLoader.free_children(picker_container)
	var available: Array[Dictionary] = GameState.product.available_features(GameState.company.type)

	if available.is_empty():
		var lbl := Label.new()
		lbl.text = "All features built — nice work!"
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		picker_container.add_child(lbl)
		return

	for fdef in available:
		var card := _create_feature_card(fdef)
		picker_container.add_child(card)


func _create_feature_card(fdef: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.16)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = fdef.get("name", "???")
	name_lbl.add_theme_font_size_override("font_size", 15)
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = fdef.get("description", "")
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	var effects: Dictionary = fdef.get("effects", {})
	var effect_parts: Array[String] = []
	if effects.has("revenue_mult"):
		effect_parts.append("+%d%% revenue" % roundi((float(effects["revenue_mult"]) - 1.0) * 100))
	if effects.has("churn_reduction"):
		effect_parts.append("-%s%% churn" % str(snapped(float(effects["churn_reduction"]) * 100, 0.1)))
	if effects.has("user_growth_bonus"):
		effect_parts.append("+%d users/Q" % int(effects["user_growth_bonus"]))
	if effects.has("ux_bonus"):
		effect_parts.append("+%d UX" % int(effects["ux_bonus"]))
	if effects.has("stability_bonus"):
		effect_parts.append("+%d stability" % int(effects["stability_bonus"]))
	if effects.has("reputation_bonus"):
		effect_parts.append("+%d reputation" % int(effects["reputation_bonus"]))
	if effects.has("dau_bonus"):
		effect_parts.append("+%d%% DAU" % roundi(float(effects["dau_bonus"]) * 100))

	if not effect_parts.is_empty():
		var fx_lbl := Label.new()
		fx_lbl.text = " · ".join(effect_parts)
		fx_lbl.add_theme_font_size_override("font_size", 12)
		fx_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
		vbox.add_child(fx_lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = "Effort: %d points" % int(fdef.get("cost", 100))
	cost_lbl.add_theme_font_size_override("font_size", 11)
	cost_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	vbox.add_child(cost_lbl)

	var btn := Button.new()
	btn.text = "Build This"
	btn.custom_minimum_size = Vector2(0, 36)
	btn.pressed.connect(_on_select_feature.bind(fdef))
	vbox.add_child(btn)

	return panel


func _on_select_feature(fdef: Dictionary) -> void:
	GameState.product.target_feature_id = fdef.get("id", "")
	GameState.product.feature_progress = 0.0
	picker_panel.visible = false
	_refresh()


func _on_back() -> void:
	SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")
