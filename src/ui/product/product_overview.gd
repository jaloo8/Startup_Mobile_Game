extends Control
## Product overview screen — see product health and feature list.

@onready var product_visual: Control = %ProductMockup
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
@onready var visual_hook_layer: Control = %VisualHookLayer

const MAX_VISIBLE_FEATURES := 50

const VISUAL_PRESET_LABELS := [
	"Live run",
	"Starter shell",
	"Engagement core",
	"Monetization",
	"Fully built",
]
const SHOWCASE_PRESET_ORDER := [1, 2, 3, 4]
const SHOWCASE_STEP_SECONDS := 2.8
const PRODUCT_PREVIEW_PROTOTYPES_PATH := "res://src/data/product_preview_prototypes.json"

const VISUAL_PRESET_FEATURES := {
	CompanyData.CompanyType.CONSUMER: [
		[],
		["profile_pages", "push_notifications"],
		["profile_pages", "push_notifications", "social_feed", "stories", "recommendations"],
		["profile_pages", "push_notifications", "social_feed", "stories", "recommendations", "sharing", "offline_mode", "iap", "live_chat", "dark_mode"],
		["profile_pages", "push_notifications", "social_feed", "stories", "dark_mode", "sharing", "offline_mode", "recommendations", "iap", "live_chat"],
	],
	CompanyData.CompanyType.SAAS: [
		[],
		["user_dashboard", "billing"],
		["user_dashboard", "billing", "analytics", "admin_panel", "api_v2", "sso_login"],
		["user_dashboard", "billing", "analytics", "api_v2", "sso_login", "admin_panel", "integrations", "audit_log", "multi_tenancy", "custom_reports"],
		["user_dashboard", "billing", "analytics", "api_v2", "sso_login", "admin_panel", "multi_tenancy", "audit_log", "integrations", "custom_reports"],
	],
	CompanyData.CompanyType.MARKETPLACE: [
		[],
		["seller_onboarding", "categories"],
		["seller_onboarding", "categories", "search_filters", "ratings", "payment_escrow", "seller_analytics"],
		["seller_onboarding", "search_filters", "ratings", "payment_escrow", "disputes", "seller_analytics", "promoted_listings", "categories", "delivery_tracking", "referral_program"],
		["seller_onboarding", "search_filters", "ratings", "payment_escrow", "disputes", "seller_analytics", "promoted_listings", "categories", "delivery_tracking", "referral_program"],
	],
	CompanyData.CompanyType.DEV_TOOLS: [
		[],
		["cli_tool", "api_docs"],
		["cli_tool", "sdk", "api_docs", "sandbox", "webhooks", "auth_tokens"],
		["cli_tool", "sdk", "api_docs", "sandbox", "webhooks", "rate_limiting", "auth_tokens", "usage_dashboard", "plugin_system", "cicd_integration"],
		["cli_tool", "sdk", "api_docs", "sandbox", "webhooks", "rate_limiting", "auth_tokens", "usage_dashboard", "plugin_system", "cicd_integration"],
	],
}

# Dynamically created ETA + team info label below the build bar
var _eta_label: Label
# Celebration banner shown when a feature ships
var _celebration_panel: PanelContainer
var _visual_preset_panel: PanelContainer
var _visual_preset_picker: OptionButton
var _visual_preset_hint: Label
var _visual_preset_mode: int = 0
var _showcase_btn: Button
var _showcase_timer: Timer
var _showcase_step_idx: int = 0
var _showcase_enabled: bool = false
var _prototype_picker: OptionButton
var _prototype_hint: Label
var _prototype_rows: Array[Dictionary] = []


func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	pick_btn.pressed.connect(_on_pick_feature)
	%TechDebtTitle.pressed.connect(Glossary.show_term.bind("tech_debt"))
	%StabilityTitle.pressed.connect(Glossary.show_term.bind("stability"))
	%UxTitle.pressed.connect(Glossary.show_term.bind("ux_score"))
	%ChurnTitle.pressed.connect(Glossary.show_term.bind("churn_rate"))
	picker_panel.visible = false
	build_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_build_eta_label()
	_build_celebration_panel()
	_build_visual_preset_controls()
	_setup_product_visual()

	GameState.feature_shipped.connect(_on_feature_shipped)
	_refresh()
	Analytics.track_screen("product")


func _exit_tree() -> void:
	if GameState.feature_shipped.is_connected(_on_feature_shipped):
		GameState.feature_shipped.disconnect(_on_feature_shipped)
	if _showcase_timer:
		_showcase_timer.stop()


func _setup_product_visual() -> void:
	if product_visual == null or GameState.company == null:
		return
	if product_visual.has_method("setup"):
		product_visual.setup(GameState.company.type)
	_refresh_product_visual()


func _refresh_product_visual() -> void:
	if product_visual == null or GameState.product == null:
		return
	var shipped_ids: Array[String] = _effective_visual_features()
	if product_visual.has_method("refresh"):
		product_visual.refresh(shipped_ids)

	if product_visual.has_method("set_build_preview"):
		if _visual_preset_mode != 0:
			product_visual.set_build_preview("", 0.0)
			return
		var target: Dictionary = GameState.product.get_target_feature(GameState.company.type)
		if target.is_empty():
			product_visual.set_build_preview("", 0.0)
		else:
			var cost: float = maxf(1.0, float(target.get("cost", 100)))
			var progress_01: float = clampf(GameState.product.feature_progress / cost, 0.0, 1.0)
			product_visual.set_build_preview(target.get("id", ""), progress_01)


func _build_eta_label() -> void:
	# Insert an ETA / team-count hint right below the build_progress bar.
	# Since we can't directly reorder scene nodes here, we add it as a
	# sibling after build_progress inside its parent VBox.
	_eta_label = Label.new()
	_eta_label.add_theme_font_size_override("font_size", 13)
	_eta_label.add_theme_color_override("font_color", Color(0.55, 0.8, 0.95))
	_eta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_eta_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# build_progress lives in a VBoxContainer — add the label right after it
	var parent := build_progress.get_parent()
	if parent:
		var idx := build_progress.get_index()
		parent.add_child(_eta_label)
		parent.move_child(_eta_label, idx + 1)


func _product_root_vbox() -> VBoxContainer:
	var scroll := feature_list_container.get_parent()
	if scroll == null:
		return null
	return scroll.get_parent() as VBoxContainer


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
	# Keep this outside the scroll area to avoid overlap with feature rows.
	var root_parent := _product_root_vbox()
	var scroll := feature_list_container.get_parent()
	if root_parent and scroll:
		root_parent.add_child(_celebration_panel)
		root_parent.move_child(_celebration_panel, scroll.get_index())


func _build_visual_preset_controls() -> void:
	if product_visual == null:
		return
	_prototype_rows = _load_product_preview_prototypes()

	_visual_preset_panel = PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.13, 0.18, 0.9)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	_visual_preset_panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	_visual_preset_panel.add_child(vbox)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vbox.add_child(row)

	var title := Label.new()
	title.text = "Visual Preview"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.75, 0.82, 0.98))
	row.add_child(title)

	_visual_preset_picker = OptionButton.new()
	for label in VISUAL_PRESET_LABELS:
		_visual_preset_picker.add_item(label)
	_visual_preset_picker.selected = _visual_preset_mode
	_visual_preset_picker.item_selected.connect(_on_visual_preset_selected)
	row.add_child(_visual_preset_picker)

	_showcase_btn = Button.new()
	_showcase_btn.text = "Showcase ▶"
	_showcase_btn.custom_minimum_size = Vector2(110, 0)
	_showcase_btn.pressed.connect(_on_showcase_pressed)
	row.add_child(_showcase_btn)

	var proto_row := HBoxContainer.new()
	proto_row.add_theme_constant_override("separation", 8)
	vbox.add_child(proto_row)

	var proto_title := Label.new()
	proto_title.text = "Prototype Concept"
	proto_title.add_theme_font_size_override("font_size", 11)
	proto_title.add_theme_color_override("font_color", Color(0.65, 0.74, 0.92))
	proto_row.add_child(proto_title)

	_prototype_picker = OptionButton.new()
	_prototype_picker.add_item("None")
	for row_data in _prototype_rows:
		_prototype_picker.add_item(str(row_data.get("name", "Concept")))
	_prototype_picker.selected = 0
	_prototype_picker.item_selected.connect(_on_prototype_selected)
	proto_row.add_child(_prototype_picker)

	_visual_preset_hint = Label.new()
	_visual_preset_hint.add_theme_font_size_override("font_size", 10)
	_visual_preset_hint.add_theme_color_override("font_color", Color(0.55, 0.58, 0.66))
	_visual_preset_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_visual_preset_hint)

	_prototype_hint = Label.new()
	_prototype_hint.add_theme_font_size_override("font_size", 10)
	_prototype_hint.add_theme_color_override("font_color", Color(0.48, 0.55, 0.66))
	_prototype_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_prototype_hint)

	var parent := product_visual.get_parent()
	if parent:
		var idx := product_visual.get_index()
		parent.add_child(_visual_preset_panel)
		parent.move_child(_visual_preset_panel, idx + 1)

	_showcase_timer = Timer.new()
	_showcase_timer.one_shot = false
	_showcase_timer.wait_time = SHOWCASE_STEP_SECONDS
	_showcase_timer.timeout.connect(_on_showcase_tick)
	add_child(_showcase_timer)

	_update_visual_preset_hint()
	_update_prototype_hint("")


func _load_product_preview_prototypes() -> Array[Dictionary]:
	if GameState.company == null:
		return _fallback_product_preview_prototypes()
	var type_key := _company_type_key(GameState.company.type)
	if type_key.is_empty():
		return _fallback_product_preview_prototypes()
	if not FileAccess.file_exists(PRODUCT_PREVIEW_PROTOTYPES_PATH):
		return _fallback_product_preview_prototypes()

	var file := FileAccess.open(PRODUCT_PREVIEW_PROTOTYPES_PATH, FileAccess.READ)
	if file == null:
		return _fallback_product_preview_prototypes()
	var text := file.get_as_text()
	file = null

	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return _fallback_product_preview_prototypes()

	var root: Dictionary = json.data
	var rows = root.get(type_key, [])
	if not (rows is Array):
		return _fallback_product_preview_prototypes()

	var out: Array[Dictionary] = []
	for raw in rows:
		if not (raw is Dictionary):
			continue
		var row: Dictionary = raw
		var label := str(row.get("name", "")).strip_edges()
		if label.is_empty():
			continue
		out.append({
			"id": str(row.get("id", "")).strip_edges(),
			"name": label,
			"description": str(row.get("description", "")).strip_edges(),
			"preview_mode": clampi(int(row.get("preview_mode", 1)), 1, VISUAL_PRESET_LABELS.size() - 1),
		})

	if out.is_empty():
		return _fallback_product_preview_prototypes()
	return out


func _fallback_product_preview_prototypes() -> Array[Dictionary]:
	return [
		{
			"id": "starter_usability",
			"name": "Starter Usability",
			"description": "Early concept focused on clean onboarding and easy first-session navigation.",
			"preview_mode": 1,
		},
		{
			"id": "engagement_loop",
			"name": "Engagement Loop",
			"description": "Mid concept focused on retention loops and repeat usage habits.",
			"preview_mode": 2,
		},
		{
			"id": "monetization_balance",
			"name": "Monetization Balance",
			"description": "Monetization-forward concept that still keeps the core experience readable.",
			"preview_mode": 3,
		},
		{
			"id": "premium_polish",
			"name": "Premium Polish",
			"description": "Near-final concept for polished visual hierarchy and production feel.",
			"preview_mode": 4,
		},
	]


static func _company_type_key(company_type: int) -> String:
	match company_type:
		CompanyData.CompanyType.SAAS:
			return "saas"
		CompanyData.CompanyType.CONSUMER:
			return "consumer"
		CompanyData.CompanyType.MARKETPLACE:
			return "marketplace"
		CompanyData.CompanyType.DEV_TOOLS:
			return "dev_tools"
		_:
			return ""


func _update_prototype_hint(text: String) -> void:
	if _prototype_hint == null:
		return
	if text.strip_edges().is_empty():
		_prototype_hint.text = "Add future concept ideas in src/data/product_preview_prototypes.json."
		return
	_prototype_hint.text = text


func _on_prototype_selected(index: int) -> void:
	if _showcase_enabled:
		_stop_showcase_mode()
	if index <= 0:
		_update_prototype_hint("")
		return
	var safe_idx := clampi(index - 1, 0, _prototype_rows.size() - 1)
	var row: Dictionary = _prototype_rows[safe_idx]
	var mode := clampi(int(row.get("preview_mode", 1)), 1, VISUAL_PRESET_LABELS.size() - 1)
	_set_visual_preset_mode(mode)
	_update_prototype_hint(str(row.get("description", "")))


func _on_visual_preset_selected(index: int) -> void:
	if _showcase_enabled:
		_stop_showcase_mode()
	if _prototype_picker and _prototype_picker.selected != 0:
		_prototype_picker.select(0)
		_update_prototype_hint("")
	_set_visual_preset_mode(index)


func _update_visual_preset_hint() -> void:
	if _visual_preset_hint == null:
		return
	if _showcase_enabled:
		_visual_preset_hint.text = "Showcase mode: auto-cycling Starter → Engagement → Monetization → Full."
	elif _visual_preset_mode == 0:
		_visual_preset_hint.text = "Using your real shipped features. No fake unlocks."
	else:
		_visual_preset_hint.text = "Preview mode only. This does not change save data or unlocks."


func _set_visual_preset_mode(index: int) -> void:
	_visual_preset_mode = clampi(index, 0, VISUAL_PRESET_LABELS.size() - 1)
	if _visual_preset_picker and _visual_preset_picker.selected != _visual_preset_mode:
		_visual_preset_picker.select(_visual_preset_mode)
	_update_visual_preset_hint()
	_animate_visual_rebuild()


func _animate_visual_rebuild() -> void:
	if product_visual == null:
		_setup_product_visual()
		return
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(product_visual, "modulate:a", 0.0, 0.14)
	tw.tween_callback(_setup_product_visual)
	tw.tween_property(product_visual, "modulate:a", 1.0, 0.20)


func _on_showcase_pressed() -> void:
	if _showcase_enabled:
		_stop_showcase_mode()
	else:
		_start_showcase_mode()


func _start_showcase_mode() -> void:
	if _showcase_enabled:
		return
	_showcase_enabled = true
	_showcase_step_idx = 0
	if _showcase_btn:
		_showcase_btn.text = "Showcase ■"
	_apply_showcase_step()
	if _showcase_timer:
		_showcase_timer.start()
	_update_visual_preset_hint()


func _stop_showcase_mode() -> void:
	if not _showcase_enabled:
		return
	_showcase_enabled = false
	if _showcase_timer:
		_showcase_timer.stop()
	if _showcase_btn:
		_showcase_btn.text = "Showcase ▶"
	_update_visual_preset_hint()


func _on_showcase_tick() -> void:
	_apply_showcase_step()


func _apply_showcase_step() -> void:
	if SHOWCASE_PRESET_ORDER.is_empty():
		return
	var i: int = _showcase_step_idx % SHOWCASE_PRESET_ORDER.size()
	var preset_mode: int = SHOWCASE_PRESET_ORDER[i]
	_showcase_step_idx += 1
	_set_visual_preset_mode(preset_mode)


func _effective_visual_features() -> Array[String]:
	var base_ids: Array[String] = []
	var seen: Dictionary = {}

	if GameState.product:
		for f: Dictionary in GameState.product.features:
			var fid := String(f.get("id", ""))
			if fid.is_empty() or seen.has(fid):
				continue
			seen[fid] = true
			base_ids.append(fid)

	if _visual_preset_mode == 0 or GameState.company == null:
		return base_ids

	var stage_sets: Array = VISUAL_PRESET_FEATURES.get(GameState.company.type, [])
	if _visual_preset_mode >= stage_sets.size():
		return base_ids

	for fid: String in stage_sets[_visual_preset_mode]:
		if fid.is_empty() or seen.has(fid):
			continue
		seen[fid] = true
		base_ids.append(fid)

	return base_ids


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
	_refresh_product_visual()
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
				var qtr_output: float = float(snapped(total_output * 0.5, 0.1))
				_eta_label.text += " (~%s effort/Q ready)" % str(qtr_output)
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
	base += " · ~%s effort/Q" % str(snapped(progress_per_quarter, 0.1))

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

	_play_visual_hook_flash()

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


func _play_visual_hook_flash() -> void:
	# Temporary visual hook: art teams can replace this with authored VFX nodes.
	if visual_hook_layer == null:
		return
	var flash := ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.35, 0.62, 0.95, 0.22)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual_hook_layer.add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.22)
	tw.finished.connect(func() -> void:
		if is_instance_valid(flash):
			flash.queue_free()
	)


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
	var root_vbox := _product_root_vbox()
	if root_vbox == null:
		return
	var strip := root_vbox.get_node_or_null("MilestoneStrip") as VBoxContainer
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
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		strip.add_child(row)

		var lbl := Label.new()
		lbl.text = m.get("label", "")
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var done: bool = m.get("done", false)
		if done:
			lbl.add_theme_color_override("font_color", Color(0.35, 0.85, 0.45))
			lbl.text = "✓ " + lbl.text
		else:
			lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
		row.add_child(lbl)

		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(0, 18)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.min_value = 0.0
		bar.max_value = 1.0
		bar.value = clampf(m.get("progress", 0.0), 0.0, 1.0)
		bar.show_percentage = false
		row.add_child(bar)


func _create_milestone_strip() -> VBoxContainer:
	var strip := VBoxContainer.new()
	strip.name = "MilestoneStrip"
	strip.add_theme_constant_override("separation", 6)
	var parent := _product_root_vbox()
	if parent == null:
		return strip
	parent.add_child(strip)
	# Place it just above the shipped-features list
	var scroll := feature_list_container.get_parent()
	if scroll:
		parent.move_child(strip, scroll.get_index())
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
