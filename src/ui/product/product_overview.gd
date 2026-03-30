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

# Dynamically created ETA + team info label below the build bar
var _eta_label: Label
# Celebration banner shown when a feature ships
var _celebration_panel: PanelContainer


func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	pick_btn.pressed.connect(_on_pick_feature)
	%TechDebtTitle.pressed.connect(Glossary.show_term.bind("tech_debt"))
	%StabilityTitle.pressed.connect(Glossary.show_term.bind("stability"))
	%UxTitle.pressed.connect(Glossary.show_term.bind("ux_score"))
	%ChurnTitle.pressed.connect(Glossary.show_term.bind("churn_rate"))
	picker_panel.visible = false

	_build_eta_label()
	_build_celebration_panel()

	GameState.feature_shipped.connect(_on_feature_shipped)
	_refresh()
	Analytics.track_screen("product")


func _exit_tree() -> void:
	if GameState.feature_shipped.is_connected(_on_feature_shipped):
		GameState.feature_shipped.disconnect(_on_feature_shipped)


func _build_eta_label() -> void:
	# Insert an ETA / team-count hint right below the build_progress bar.
	# Since we can't directly reorder scene nodes here, we add it as a
	# sibling after build_progress inside its parent VBox.
	_eta_label = Label.new()
	_eta_label.add_theme_font_size_override("font_size", 13)
	_eta_label.add_theme_color_override("font_color", Color(0.55, 0.8, 0.95))
	_eta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# build_progress lives in a VBoxContainer — add the label right after it
	var parent := build_progress.get_parent()
	if parent:
		var idx := build_progress.get_index()
		parent.add_child(_eta_label)
		parent.move_child(_eta_label, idx + 1)


func _build_celebration_panel() -> void:
	# Full-width banner that slides in when a feature ships, then auto-hides.
	_celebration_panel = PanelContainer.new()
	_celebration_panel.name = "CelebrationPanel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.55, 0.28, 0.95)
	style.set_corner_radius_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_celebration_panel.add_theme_stylebox_override("panel", style)

	var lbl := Label.new()
	lbl.name = "CelebLabel"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_celebration_panel.add_child(lbl)

	_celebration_panel.visible = false
	# Add at top of the screen's root VBox so it's always visible
	var root_parent := feature_list_container.get_parent()
	if root_parent:
		root_parent.add_child(_celebration_panel)
		root_parent.move_child(_celebration_panel, 0)


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
	_refresh_milestone_roadmap()
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

	# Count engineers on Features
	var engineers_on_features: int = 0
	var total_output: float = 0.0
	for emp: EmployeeData in GameState.employees:
		if emp.assignment == EmployeeData.Assignment.FEATURES:
			engineers_on_features += 1
			var spec_m := EmployeeData.specialty_mult(emp.specialty, EmployeeData.Assignment.FEATURES, GameState.company.type)
			total_output += emp.work_output() * p.dev_speed_multiplier() * spec_m

	if target.is_empty():
		build_status.text = "No feature selected — pick one below"
		build_progress.value = 0
		build_progress.max_value = 100
		pick_btn.text = "Choose Next Feature"
		pick_btn.disabled = false
		if _eta_label:
			if engineers_on_features == 0:
				_eta_label.text = "Tip: assign your team to Features (in People) to start building"
				_eta_label.add_theme_color_override("font_color", Color(0.85, 0.65, 0.3))
			else:
				_eta_label.text = "%d engineer%s ready — pick a feature to start" % [
					engineers_on_features,
					"s" if engineers_on_features != 1 else "",
				]
				_eta_label.add_theme_color_override("font_color", Color(0.55, 0.8, 0.95))
	else:
		var cost: float = float(target.get("cost", 100))
		build_status.text = "Building: %s" % target.get("name", "???")
		build_progress.max_value = cost
		build_progress.value = p.feature_progress
		pick_btn.text = "Building %s..." % target.get("name", "")
		pick_btn.disabled = true

		if _eta_label:
			var eta_text: String = _build_eta_text(p, target, engineers_on_features, total_output)
			_eta_label.text = eta_text
			if engineers_on_features == 0:
				_eta_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.3))
			else:
				_eta_label.add_theme_color_override("font_color", Color(0.55, 0.8, 0.95))


func _build_eta_text(p: ProductData, target: Dictionary, engineer_count: int, total_output: float) -> String:
	if engineer_count == 0:
		return "Nobody is assigned to Features — go to People to assign your team"

	var cost: float = float(target.get("cost", 100))
	var remaining: float = cost - p.feature_progress
	var progress_per_quarter: float = total_output * 0.5  # mirrors SimulationEngine multiplier

	if progress_per_quarter <= 0.0:
		return "Team morale is too low to make progress right now"

	var quarters: float = remaining / progress_per_quarter
	var eta_str: String
	if quarters <= 0.5:
		eta_str = "Almost done — wrapping up this quarter!"
	elif quarters <= 1.0:
		eta_str = "Est. done this quarter"
	elif quarters <= 1.5:
		eta_str = "Est. done next quarter"
	elif quarters <= 2.5:
		eta_str = "Est. ~2 quarters"
	else:
		eta_str = "Est. ~%d quarters" % ceili(quarters)

	var eng_word := "engineer" if engineer_count == 1 else "engineers"
	var base := "%d %s working on this · %s" % [engineer_count, eng_word, eta_str]

	# Count how many on Features are a great/good fit and mention it
	var great_fits: int = 0
	var good_fits: int = 0
	for emp: EmployeeData in GameState.employees:
		if emp.assignment != EmployeeData.Assignment.FEATURES:
			continue
		var m := EmployeeData.specialty_mult(emp.specialty, EmployeeData.Assignment.FEATURES, GameState.company.type)
		if m >= 1.3:
			great_fits += 1
		elif m >= 1.15:
			good_fits += 1

	if great_fits > 0 or good_fits > 0:
		var fit_parts: Array[String] = []
		if great_fits > 0:
			fit_parts.append("%d great fit%s" % [great_fits, "s" if great_fits > 1 else ""])
		if good_fits > 0:
			fit_parts.append("%d good fit%s" % [good_fits, "s" if good_fits > 1 else ""])
		base += "\n  ⚡ " + ", ".join(fit_parts) + " on the team — boosted speed"

	return base


func _on_feature_shipped(feature_name: String, quality: int) -> void:
	if _celebration_panel == null:
		return

	var quality_word: String
	var quality_color: Color
	if quality >= 80:
		quality_word = "Excellent"
		quality_color = Color(0.3, 0.95, 0.5)
	elif quality >= 60:
		quality_word = "Good"
		quality_color = Color(0.55, 0.9, 0.35)
	elif quality >= 40:
		quality_word = "Decent"
		quality_color = Color(0.9, 0.85, 0.25)
	else:
		quality_word = "Rough"
		quality_color = Color(0.9, 0.55, 0.25)

	var lbl := _celebration_panel.get_node_or_null("CelebLabel") as Label
	if lbl:
		lbl.text = "Feature shipped: %s  ·  %s quality (%d/100)" % [feature_name, quality_word, quality]
		# Tint the banner to reflect quality
		var style := StyleBoxFlat.new()
		style.bg_color = quality_color.darkened(0.45)
		style.bg_color.a = 0.95
		style.set_corner_radius_all(10)
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		_celebration_panel.add_theme_stylebox_override("panel", style)

	_celebration_panel.modulate.a = 0.0
	_celebration_panel.visible = true

	var tw := create_tween()
	tw.tween_property(_celebration_panel, "modulate:a", 1.0, 0.35)
	tw.tween_interval(3.5)
	tw.tween_property(_celebration_panel, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void: _celebration_panel.visible = false)

	_refresh()


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


func _refresh_milestone_roadmap() -> void:
	# Build or update a milestone strip showing next product + user goals.
	# We look for an existing node or create one dynamically below the health bars.
	var strip := feature_list_container.get_parent().get_node_or_null("MilestoneStrip") as VBoxContainer
	if strip == null:
		strip = _create_milestone_strip()

	SceneLoader.free_children(strip)

	var milestones := _get_next_milestones()
	if milestones.is_empty():
		strip.visible = false
		return
	strip.visible = true

	var heading := Label.new()
	heading.text = "ROADMAP"
	heading.add_theme_font_size_override("font_size", 11)
	heading.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	strip.add_child(heading)

	for m: Dictionary in milestones:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		strip.add_child(row)

		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(0, 18)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.min_value = 0.0
		bar.max_value = 1.0
		bar.value = clampf(m.get("progress", 0.0), 0.0, 1.0)
		bar.show_percentage = false
		row.add_child(bar)

		var lbl := Label.new()
		lbl.text = m.get("label", "")
		lbl.add_theme_font_size_override("font_size", 12)
		var done: bool = m.get("done", false)
		if done:
			lbl.add_theme_color_override("font_color", Color(0.35, 0.85, 0.45))
			lbl.text = "✓ " + lbl.text
		else:
			lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
		lbl.custom_minimum_size = Vector2(220, 0)
		row.add_child(lbl)


func _create_milestone_strip() -> VBoxContainer:
	var strip := VBoxContainer.new()
	strip.name = "MilestoneStrip"
	strip.add_theme_constant_override("separation", 6)
	var parent := feature_list_container.get_parent()
	parent.add_child(strip)
	# Place it just above the shipped-features list
	parent.move_child(strip, feature_list_container.get_index())
	return strip


func _get_next_milestones() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var p: ProductData = GameState.product
	var users: int = p.users
	var features: int = p.feature_count()

	# User milestones
	var user_targets := [100, 1_000, 10_000, 50_000, 100_000]
	for target in user_targets:
		if users < target:
			result.append({
				"label": "%s users" % SceneLoader.format_number(target),
				"progress": float(users) / float(target),
				"done": false,
			})
			break
		else:
			result.append({
				"label": "%s users" % SceneLoader.format_number(target),
				"progress": 1.0,
				"done": true,
			})

	# Feature milestones
	var feat_targets := [1, 3, 5, 8, 10]
	for target in feat_targets:
		if features < target:
			result.append({
				"label": "%d features shipped" % target,
				"progress": float(features) / float(target),
				"done": false,
			})
			break
		else:
			result.append({
				"label": "%d features shipped" % target,
				"progress": 1.0,
				"done": true,
			})

	# Revenue milestone
	var rev: float = GameState.financials.revenue
	var rev_targets := [1.0, 1_000.0, 10_000.0, 100_000.0, 1_000_000.0]
	for target in rev_targets:
		if rev < target:
			result.append({
				"label": "Earn $%s/qtr" % SceneLoader.format_money(target),
				"progress": rev / target,
				"done": false,
			})
			break

	# Cap to the 4 most interesting (mix of done + in-progress)
	var in_progress: Array[Dictionary] = result.filter(func(m: Dictionary) -> bool: return not m.get("done", false))
	var done_recent: Array[Dictionary] = result.filter(func(m: Dictionary) -> bool: return m.get("done", false))
	# Show last 1 completed + next 2 in progress
	var final_list: Array[Dictionary] = []
	if not done_recent.is_empty():
		final_list.append(done_recent.back())
	for i in mini(2, in_progress.size()):
		final_list.append(in_progress[i])
	return final_list


func _on_back() -> void:
	SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")
