extends Control
## Employee management screen — view team, hire, fire, assign work.

@onready var list_container: VBoxContainer = %EmployeeListContainer
@onready var hire_btn: Button = %HireButton
@onready var back_btn: Button = %BackButton
@onready var capacity_label: Label = %CapacityLabel
@onready var candidate_container: VBoxContainer = %CandidateContainer
@onready var candidate_panel: PanelContainer = %CandidatePanel
@onready var sort_row: HBoxContainer = %SortRow

var _candidates: Array[EmployeeData] = []
var _interviewed: Dictionary = {}
var _negotiated: Dictionary = {}   # candidate name -> true if already negotiated
var _card_style: StyleBoxFlat
var _assign_target: EmployeeData

enum SortKey { NAME, SKILL, MORALE, SALARY, ASSIGNMENT }
var _current_sort: SortKey = SortKey.NAME
var _sort_ascending: bool = true

const SORT_LABELS := {
	SortKey.NAME: "Name",
	SortKey.SKILL: "Skill",
	SortKey.MORALE: "Morale",
	SortKey.SALARY: "Salary",
	SortKey.ASSIGNMENT: "Focus",
}

const POSTING_FEE := 5_000.0

const AVATAR_COUNT := 8
const ASSIGNMENT_ICON_PATHS := {
	EmployeeData.Assignment.FEATURES:  "res://assets/icons/assign_features.png",
	EmployeeData.Assignment.BUGS:      "res://assets/icons/assign_bugs.png",
	EmployeeData.Assignment.TECH_DEBT: "res://assets/icons/assign_techdebt.png",
	EmployeeData.Assignment.INFRA:     "res://assets/icons/assign_infra.png",
	EmployeeData.Assignment.RND:       "res://assets/icons/assign_rnd.png",
}

const ASSIGNMENT_DESCRIPTIONS := {
	EmployeeData.Assignment.FEATURES: "Build new product features.\nMore features attract users.",
	EmployeeData.Assignment.BUGS: "Squash bugs.\nFewer bugs means less churn.",
	EmployeeData.Assignment.TECH_DEBT: "Clean up messy code.\nHigh tech debt slows everyone down.",
	EmployeeData.Assignment.INFRA: "Improve stability and uptime.\nUnstable products lose users fast.",
	EmployeeData.Assignment.RND: "Research and improve UX.\nBetter UX means happier users.",
}


func _ready() -> void:
	_card_style = _make_card_style()
	hire_btn.pressed.connect(_on_hire_pressed)
	back_btn.pressed.connect(_on_back)
	candidate_panel.visible = false
	_build_sort_buttons()
	_update_hire_button()
	_refresh_list()
	Analytics.track_screen("people")


func _exit_tree() -> void:
	_candidates.clear()
	_interviewed.clear()
	_card_style = null
	_assign_target = null


func _update_hire_button() -> void:
	if GameState.employees.size() >= GameState.company.office_capacity():
		hire_btn.disabled = true
		hire_btn.text = "Office Full — Upgrade in Finances to hire more"
		hire_btn.modulate = Color(1, 1, 1, 0.5)
		_show_office_upgrade_hint()
		return

	if GameState.company.cash < POSTING_FEE:
		hire_btn.disabled = true
		hire_btn.text = "Can't afford to post ($%sK)" % str(snapped(POSTING_FEE / 1000.0, 0.1))
		hire_btn.modulate = Color(1, 1, 1, 0.5)
		return

	hire_btn.disabled = false
	hire_btn.text = "Post Job Listing ($%sK)" % str(snapped(POSTING_FEE / 1000.0, 0.1))
	hire_btn.modulate = Color(1, 1, 1, 1)


func _build_sort_buttons() -> void:
	# Add a label before the sort buttons so it's clear they sort the team list
	var sort_heading := Label.new()
	sort_heading.text = "Sort your team by:"
	sort_heading.add_theme_font_size_override("font_size", 11)
	sort_heading.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	sort_row.add_child(sort_heading)

	for key in SortKey.values():
		var btn := Button.new()
		btn.text = SORT_LABELS[key]
		btn.custom_minimum_size = Vector2(56, 28)
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_on_sort_pressed.bind(key))
		sort_row.add_child(btn)
	_highlight_sort_button()


func _on_sort_pressed(key: SortKey) -> void:
	if _current_sort == key:
		_sort_ascending = not _sort_ascending
	else:
		_current_sort = key
		_sort_ascending = true
	_highlight_sort_button()
	_refresh_list()


func _highlight_sort_button() -> void:
	var idx := 0
	for child in sort_row.get_children():
		if child is Button:
			var key: SortKey = SortKey.values()[idx]
			if key == _current_sort:
				child.modulate = Color(0.4, 0.85, 1.0)
				child.text = SORT_LABELS[key] + (" ↑" if _sort_ascending else " ↓")
			else:
				child.modulate = Color(1, 1, 1, 0.7)
				child.text = SORT_LABELS[key]
			idx += 1


func _sorted_employees() -> Array[EmployeeData]:
	var arr: Array[EmployeeData] = []
	arr.assign(GameState.employees.duplicate())
	arr.sort_custom(func(a: EmployeeData, b: EmployeeData) -> bool:
		var result: bool
		match _current_sort:
			SortKey.SKILL:
				result = a.skill > b.skill
			SortKey.MORALE:
				result = a.morale < b.morale
			SortKey.SALARY:
				result = a.salary_per_quarter > b.salary_per_quarter
			SortKey.ASSIGNMENT:
				result = int(a.assignment) < int(b.assignment)
			_:
				result = a.employee_name.naturalnocasecmp_to(b.employee_name) < 0
		return result if _sort_ascending else not result
	)
	return arr


func _refresh_list() -> void:
	SceneLoader.free_children(list_container)

	capacity_label.text = "Team: %d / %d (%s)" % [
		GameState.employees.size(),
		GameState.company.office_capacity(),
		GameState.company.office_name(),
	]

	if GameState.employees.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No employees yet. Hire your first team member!"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		list_container.add_child(empty_label)
		return

	for emp in _sorted_employees():
		list_container.add_child(_create_employee_card(emp))


static func _avatar_texture(employee_name: String) -> Texture2D:
	var idx: int = (hash(employee_name) % AVATAR_COUNT) + 1
	return ResourceLoader.load("res://assets/avatars/avatar_%d.png" % idx) as Texture2D


static func _make_avatar_rect(employee_name: String, size: int = 48) -> TextureRect:
	var rect := TextureRect.new()
	rect.custom_minimum_size = Vector2(size, size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.clip_contents = true
	rect.texture = _avatar_texture(employee_name)
	return rect


static func _assign_icon_texture(assignment: EmployeeData.Assignment) -> Texture2D:
	var path: String = ASSIGNMENT_ICON_PATHS.get(assignment, "")
	if path.is_empty():
		return null
	return ResourceLoader.load(path) as Texture2D


func _create_employee_card(emp: EmployeeData) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _card_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# Title row: avatar + name + specialty fit badge for the current assignment
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	vbox.add_child(title_row)

	title_row.add_child(_make_avatar_rect(emp.employee_name, 44))

	var name_label := Label.new()
	name_label.text = "%s — %s" % [emp.employee_name, emp.display_title()]
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(name_label)

	# Fit badge only shows when assigned to a work category (not Unassigned)
	if emp.assignment != EmployeeData.Assignment.UNASSIGNED and GameState.company != null:
		var match_label: String = EmployeeData.specialty_match_label(
			emp.specialty, emp.assignment, GameState.company.type)
		if not match_label.is_empty():
			var badge := Label.new()
			if match_label == "Great fit":
				badge.text = "⚡ Great fit"
				badge.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))
			elif match_label == "Good fit":
				badge.text = "✓ Good fit"
				badge.add_theme_color_override("font_color", Color(0.4, 0.85, 0.5))
			else:
				badge.text = "Off-specialty"
				badge.add_theme_color_override("font_color", Color(0.65, 0.55, 0.55))
			badge.add_theme_font_size_override("font_size", 12)
			title_row.add_child(badge)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 16)
	vbox.add_child(stats_row)
	_add_stat(stats_row, "Skill", emp.skill)
	_add_stat(stats_row, "Morale", emp.morale)
	_add_stat(stats_row, "Stress", emp.stress)

	var salary_label := Label.new()
	salary_label.text = "$%sK/yr" % str(snapped(emp.salary_per_quarter * 4 / 1000.0, 0.1))
	salary_label.add_theme_font_size_override("font_size", 13)
	salary_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	vbox.add_child(salary_label)

	var assign_row := HBoxContainer.new()
	assign_row.add_theme_constant_override("separation", 6)
	vbox.add_child(assign_row)

	var assign_label := Label.new()
	assign_label.text = "Focus:"
	assign_label.add_theme_font_size_override("font_size", 13)
	assign_row.add_child(assign_label)

	for a_key in EmployeeData.ASSIGNMENT_NAMES:
		if a_key == EmployeeData.Assignment.UNASSIGNED:
			continue
		var btn := Button.new()
		btn.text = EmployeeData.ASSIGNMENT_NAMES[a_key]
		btn.custom_minimum_size = Vector2(0, 30)
		btn.toggle_mode = true
		btn.button_pressed = (emp.assignment == a_key)
		btn.add_theme_font_size_override("font_size", 11)
		var icon_tex := _assign_icon_texture(a_key)
		if icon_tex:
			btn.icon = icon_tex
			btn.add_theme_constant_override("icon_max_width", 18)
		if emp.assignment == a_key:
			btn.modulate = Color(0.4, 0.8, 1.0)
		btn.pressed.connect(_on_assign_direct.bind(emp, a_key))
		assign_row.add_child(btn)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	vbox.add_child(action_row)

	var fire_btn := Button.new()
	fire_btn.text = "Let Go"
	fire_btn.custom_minimum_size = Vector2(70, 30)
	fire_btn.pressed.connect(_on_fire.bind(emp))
	action_row.add_child(fire_btn)

	return panel


func _on_assign_direct(emp: EmployeeData, assignment: EmployeeData.Assignment) -> void:
	emp.assignment = assignment
	Analytics.track_assignment_change(EmployeeData.ASSIGNMENT_NAMES.get(assignment, "unknown"))
	_refresh_list()


func _on_fire(emp: EmployeeData) -> void:
	Analytics.track_fire()
	GameState.fire_employee(emp)
	_update_hire_button()
	_refresh_list()


func _add_stat(parent: HBoxContainer, label_text: String, value: int) -> void:
	var lbl := Label.new()
	var color: Color
	if value >= 70:
		color = Color(0.3, 0.85, 0.4)
	elif value >= 40:
		color = Color(0.9, 0.8, 0.2)
	else:
		color = Color(0.9, 0.3, 0.3)
	lbl.text = "%s: %d" % [label_text, value]
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)


func _on_hire_pressed() -> void:
	if GameState.employees.size() >= GameState.company.office_capacity():
		_update_hire_button()
		return

	if GameState.company.cash < POSTING_FEE:
		_update_hire_button()
		return

	GameState.company.cash -= POSTING_FEE
	Analytics.track_job_posted(POSTING_FEE)
	GameState.append_event_log({
		"quarter": GameState.current_quarter,
		"year": GameState.current_year,
		"event_id": "job_posting",
		"title": "Posted a job listing — $%sK" % str(snapped(POSTING_FEE / 1000.0, 0.1)),
	})

	_candidates = HiringEngine.generate_candidates(3, GameState.market)
	_interviewed.clear()
	_negotiated.clear()
	candidate_panel.visible = true
	_update_hire_button()
	_refresh_candidates()


func _refresh_candidates() -> void:
	SceneLoader.free_children(candidate_container)

	if _candidates.is_empty():
		var lbl := Label.new()
		lbl.text = "No more candidates this round."
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		candidate_container.add_child(lbl)
		return

	for candidate in _candidates:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _card_style)
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		card.add_child(vbox)

		# Candidate title row with avatar + specialty fit hint for Features work
		var cand_title_row := HBoxContainer.new()
		cand_title_row.add_theme_constant_override("separation", 10)
		vbox.add_child(cand_title_row)

		cand_title_row.add_child(_make_avatar_rect(candidate.employee_name, 40))

		var name_lbl := Label.new()
		name_lbl.text = "%s — %s" % [candidate.employee_name, candidate.display_title()]
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cand_title_row.add_child(name_lbl)

		# Show how well they'd fit on Features for this company type
		if GameState.company != null:
			var fit_str := EmployeeData.specialty_match_label(
				candidate.specialty, EmployeeData.Assignment.FEATURES, GameState.company.type)
			if not fit_str.is_empty():
				var fit_badge := Label.new()
				if fit_str == "Great fit":
					fit_badge.text = "⚡ Great for Features"
					fit_badge.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))
				elif fit_str == "Good fit":
					fit_badge.text = "✓ Good for Features"
					fit_badge.add_theme_color_override("font_color", Color(0.4, 0.85, 0.5))
				fit_badge.add_theme_font_size_override("font_size", 11)
				cand_title_row.add_child(fit_badge)

		var cost_per_q: float = candidate.salary_per_quarter
		var runway: float = GameState.financials.runway_quarters(GameState.company.cash)
		var salary_text := "Asking $%sK/yr ($%sK/quarter)" % [
			str(snapped(cost_per_q * 4 / 1000.0, 0.1)),
			str(snapped(cost_per_q / 1000.0, 0.1)),
		]
		var salary_lbl := Label.new()
		salary_lbl.text = salary_text
		salary_lbl.add_theme_font_size_override("font_size", 13)
		salary_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		vbox.add_child(salary_lbl)

		if runway != INF and runway < 4.0:
			var warn_lbl := Label.new()
			warn_lbl.text = "⚠ You have ~%d quarters of runway left" % roundi(runway)
			warn_lbl.add_theme_font_size_override("font_size", 12)
			warn_lbl.add_theme_color_override("font_color", Color(0.95, 0.6, 0.2))
			vbox.add_child(warn_lbl)

		var interviewed: bool = _interviewed.has(candidate.employee_name)
		if interviewed:
			var stats_row := HBoxContainer.new()
			stats_row.add_theme_constant_override("separation", 16)
			vbox.add_child(stats_row)
			_add_stat(stats_row, "Skill", candidate.skill)
			_add_stat(stats_row, "Speed", candidate.speed)
			_add_stat(stats_row, "Morale", candidate.morale)

			var growth_lbl := Label.new()
			var growth_text: String
			match candidate.growth_potential:
				EmployeeData.GrowthPotential.HIGH: growth_text = "High growth potential"
				EmployeeData.GrowthPotential.MEDIUM: growth_text = "Moderate growth potential"
				_: growth_text = "Limited growth potential"
			growth_lbl.text = growth_text
			growth_lbl.add_theme_font_size_override("font_size", 12)
			growth_lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 0.9))
			vbox.add_child(growth_lbl)
		else:
			var hidden_lbl := Label.new()
			hidden_lbl.text = "Interview to learn more about this candidate"
			hidden_lbl.add_theme_font_size_override("font_size", 12)
			hidden_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
			vbox.add_child(hidden_lbl)

		# Negotiation row — show if not yet negotiated
		var already_negotiated: bool = _negotiated.has(candidate.employee_name)
		if not already_negotiated:
			var neg_row := HBoxContainer.new()
			neg_row.add_theme_constant_override("separation", 8)
			vbox.add_child(neg_row)

			var neg_btn := Button.new()
			neg_btn.text = "Negotiate Salary (-15%)"
			neg_btn.custom_minimum_size = Vector2(0, 32)
			neg_btn.add_theme_font_size_override("font_size", 12)
			neg_btn.pressed.connect(_on_negotiate_salary.bind(candidate))
			neg_row.add_child(neg_btn)

			var neg_hint := Label.new()
			neg_hint.text = "One chance — they may walk"
			neg_hint.add_theme_font_size_override("font_size", 11)
			neg_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
			neg_row.add_child(neg_hint)
		else:
			var neg_done_lbl := Label.new()
			neg_done_lbl.text = "Salary negotiated"
			neg_done_lbl.add_theme_font_size_override("font_size", 11)
			neg_done_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
			vbox.add_child(neg_done_lbl)

		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 8)
		vbox.add_child(btn_row)

		if not interviewed:
			var interview_btn := Button.new()
			interview_btn.text = "Interview"
			interview_btn.custom_minimum_size = Vector2(90, 36)
			interview_btn.pressed.connect(_on_interview.bind(candidate))
			btn_row.add_child(interview_btn)

			if AdManager.is_ad_available("rewarded_reveal_stats"):
				var ad_btn := Button.new()
				ad_btn.text = "Quick Peek (Ad)"
				ad_btn.custom_minimum_size = Vector2(110, 36)
				ad_btn.add_theme_font_size_override("font_size", 11)
				ad_btn.pressed.connect(_on_ad_reveal.bind(candidate))
				btn_row.add_child(ad_btn)

		var hire_one_btn := Button.new()
		hire_one_btn.text = "Hire"
		hire_one_btn.custom_minimum_size = Vector2(70, 32)
		hire_one_btn.pressed.connect(_on_hire_candidate.bind(candidate))
		btn_row.add_child(hire_one_btn)

		var pass_btn := Button.new()
		pass_btn.text = "Pass"
		pass_btn.custom_minimum_size = Vector2(60, 32)
		pass_btn.pressed.connect(_on_pass_candidate.bind(candidate))
		btn_row.add_child(pass_btn)

		candidate_container.add_child(card)


func _show_office_upgrade_hint() -> void:
	# Remove any existing hint first
	var existing := list_container.get_node_or_null("OfficeHint")
	if existing:
		return  # already showing

	var hint := PanelContainer.new()
	hint.name = "OfficeHint"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.14, 0.08)
	style.border_color = Color(0.85, 0.65, 0.2)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	hint.add_theme_stylebox_override("panel", style)

	var lbl := Label.new()
	lbl.text = "Your %s is full (%d/%d).\nTo hire more people, go to Finances → Office & Logistics to upgrade your workspace." % [
		GameState.company.office_name(),
		GameState.employees.size(),
		GameState.company.office_capacity(),
	]
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.75, 0.35))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_child(lbl)
	list_container.add_child(hint)
	list_container.move_child(hint, 0)


func _on_negotiate_salary(candidate: EmployeeData) -> void:
	# One-shot negotiation: reduce salary 15%, but low-morale candidates may walk.
	# Chance they walk scales with how low their culture_fit + morale are.
	_negotiated[candidate.employee_name] = true
	var walk_chance: float = remap(float(candidate.culture_fit + candidate.morale), 0.0, 200.0, 0.35, 0.0)
	walk_chance = clampf(walk_chance, 0.0, 0.35)
	if randf() < walk_chance:
		# They walked
		_candidates.erase(candidate)
		candidate_panel.visible = not _candidates.is_empty()
		_refresh_candidates()
		_show_temp_message("They declined and pulled out of the process.")
	else:
		candidate.salary_per_quarter = maxf(1000.0, candidate.salary_per_quarter * 0.85)
		_refresh_candidates()


func _show_temp_message(msg: String) -> void:
	var lbl := Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.55, 0.3))
	candidate_container.add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(func() -> void:
		if is_instance_valid(lbl):
			lbl.queue_free()
	)


func _on_ad_reveal(candidate: EmployeeData) -> void:
	if AdManager.show_ad("rewarded_reveal_stats"):
		_interviewed[candidate.employee_name] = true
		_refresh_candidates()


func _on_interview(candidate: EmployeeData) -> void:
	_interviewed[candidate.employee_name] = true
	Analytics.track_interview()
	_refresh_candidates()


func _on_hire_candidate(candidate: EmployeeData) -> void:
	if GameState.hire_employee(candidate):
		Analytics.track_hire(
			EmployeeData.SPECIALTY_NAMES.get(candidate.specialty, "unknown"),
			EmployeeData.SENIORITY_NAMES.get(candidate.seniority, "unknown"),
		)
		_candidates.erase(candidate)
		candidate_panel.visible = not _candidates.is_empty()
		_refresh_candidates()
		_assign_target = candidate
		_update_hire_button()
		_refresh_list()
		_show_hire_badge(candidate)


func _show_hire_badge(emp: EmployeeData) -> void:
	# Dim overlay
	var overlay := ColorRect.new()
	overlay.name = "BadgeOverlay"
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	# Badge card
	var card := PanelContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card.offset_left  = -160
	card.offset_right  = 160
	card.offset_top   = -240
	card.offset_bottom = 240
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.11, 0.12, 0.17)
	card_style.set_corner_radius_all(16)
	card_style.border_color = Color(0.35, 0.65, 1.0, 0.6)
	card_style.border_width_left   = 2
	card_style.border_width_right  = 2
	card_style.border_width_top    = 2
	card_style.border_width_bottom = 2
	card_style.content_margin_left   = 0
	card_style.content_margin_right  = 0
	card_style.content_margin_top    = 0
	card_style.content_margin_bottom = 0
	card.add_theme_stylebox_override("panel", card_style)
	overlay.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	card.add_child(vbox)

	# Coloured top strip
	var top_strip := PanelContainer.new()
	top_strip.custom_minimum_size = Vector2(0, 48)
	var strip_style := StyleBoxFlat.new()
	strip_style.bg_color = Color(0.22, 0.47, 0.82)
	strip_style.corner_radius_top_left  = 14
	strip_style.corner_radius_top_right = 14
	strip_style.content_margin_left  = 16
	strip_style.content_margin_right = 16
	strip_style.content_margin_top   = 8
	strip_style.content_margin_bottom = 8
	top_strip.add_theme_stylebox_override("panel", strip_style)
	vbox.add_child(top_strip)

	var strip_hbox := HBoxContainer.new()
	strip_hbox.alignment = BoxContainer.ALIGNMENT_SPACE_BETWEEN
	top_strip.add_child(strip_hbox)

	var company_lbl := Label.new()
	company_lbl.text = GameState.company.company_name if GameState.company else "Venture"
	company_lbl.add_theme_font_size_override("font_size", 13)
	company_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	strip_hbox.add_child(company_lbl)

	var badge_tag := Label.new()
	badge_tag.text = "EMPLOYEE"
	badge_tag.add_theme_font_size_override("font_size", 10)
	badge_tag.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	strip_hbox.add_child(badge_tag)

	# Body padding
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	body.set("theme_override_constants/margin_left", 20)
	body.set("theme_override_constants/margin_right", 20)
	var body_margin := MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left",   20)
	body_margin.add_theme_constant_override("margin_right",  20)
	body_margin.add_theme_constant_override("margin_top",    16)
	body_margin.add_theme_constant_override("margin_bottom", 16)
	body_margin.add_child(body)
	vbox.add_child(body_margin)

	# Avatar — centred
	var avatar_center := CenterContainer.new()
	body.add_child(avatar_center)
	var avatar_rect := _make_avatar_rect(emp.employee_name, 80)
	# Circular clip via a rounded StyleBox on a Panel behind the TextureRect
	var av_panel := PanelContainer.new()
	var av_style := StyleBoxFlat.new()
	av_style.bg_color = Color(0.2, 0.2, 0.28)
	av_style.set_corner_radius_all(40)
	av_style.border_color = Color(0.35, 0.65, 1.0, 0.7)
	av_style.border_width_left   = 3
	av_style.border_width_right  = 3
	av_style.border_width_top    = 3
	av_style.border_width_bottom = 3
	av_style.content_margin_left   = 4
	av_style.content_margin_right  = 4
	av_style.content_margin_top    = 4
	av_style.content_margin_bottom = 4
	av_panel.add_theme_stylebox_override("panel", av_style)
	av_panel.add_child(avatar_rect)
	avatar_center.add_child(av_panel)

	# "NEW HIRE" glow label
	var new_hire_lbl := Label.new()
	new_hire_lbl.text = "✦  WELCOME TO THE TEAM  ✦"
	new_hire_lbl.add_theme_font_size_override("font_size", 11)
	new_hire_lbl.add_theme_color_override("font_color", Color(0.45, 0.78, 1.0))
	new_hire_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(new_hire_lbl)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = emp.employee_name
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(name_lbl)

	# Title
	var title_lbl := Label.new()
	title_lbl.text = emp.display_title()
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title_lbl)

	# Divider
	var sep := HSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.12)
	body.add_child(sep)

	# Stats row
	var stats_row := HBoxContainer.new()
	stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_row.add_theme_constant_override("separation", 20)
	body.add_child(stats_row)
	_badge_stat(stats_row, "Skill",   emp.skill)
	_badge_stat(stats_row, "Morale",  emp.morale)
	_badge_stat(stats_row, "Speed",   emp.speed)

	# Employee number + hire date
	var meta_lbl := Label.new()
	meta_lbl.text = "EMP #%03d  •  Q%d Y%d" % [
		GameState.employees.size(),
		GameState.current_quarter,
		GameState.current_year,
	]
	meta_lbl.add_theme_font_size_override("font_size", 10)
	meta_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.52))
	meta_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(meta_lbl)

	# Assign button
	var assign_btn := Button.new()
	assign_btn.text = "Assign to work  →"
	assign_btn.custom_minimum_size = Vector2(0, 44)
	assign_btn.add_theme_font_size_override("font_size", 14)
	assign_btn.pressed.connect(func() -> void:
		overlay.queue_free()
		_show_assign_prompt(emp)
	)
	body.add_child(assign_btn)

	# Pop-in animation
	card.scale = Vector2(0.7, 0.7)
	card.pivot_offset = Vector2(160, 240)
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(card, "scale", Vector2(1.0, 1.0), 0.3)


static func _badge_stat(parent: HBoxContainer, label: String, value: int) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	parent.add_child(col)

	var val_lbl := Label.new()
	val_lbl.text = str(value)
	val_lbl.add_theme_font_size_override("font_size", 18)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if value >= 70:
		val_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.4))
	elif value >= 40:
		val_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	else:
		val_lbl.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35))
	col.add_child(val_lbl)

	var key_lbl := Label.new()
	key_lbl.text = label
	key_lbl.add_theme_font_size_override("font_size", 10)
	key_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.58))
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(key_lbl)


func _show_assign_prompt(emp: EmployeeData) -> void:
	var overlay := ColorRect.new()
	overlay.name = "AssignOverlay"
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -280
	panel.offset_right = 280
	panel.offset_top = -220
	panel.offset_bottom = 220
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.14)
	style.set_corner_radius_all(12)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var header_row := HBoxContainer.new()
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header_row.add_theme_constant_override("separation", 12)
	vbox.add_child(header_row)

	var prompt_avatar := _make_avatar_rect(emp.employee_name, 56)
	header_row.add_child(prompt_avatar)

	var title := Label.new()
	title.text = "Where should\n%s focus?" % emp.employee_name
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header_row.add_child(title)

	for a_key in ASSIGNMENT_DESCRIPTIONS:
		var btn := Button.new()
		btn.text = "%s\n%s" % [EmployeeData.ASSIGNMENT_NAMES[a_key], ASSIGNMENT_DESCRIPTIONS[a_key]]
		btn.custom_minimum_size = Vector2(0, 50)
		btn.add_theme_font_size_override("font_size", 13)
		var prompt_icon := _assign_icon_texture(a_key)
		if prompt_icon:
			btn.icon = prompt_icon
			btn.add_theme_constant_override("icon_max_width", 24)
		btn.pressed.connect(_on_assign_from_prompt.bind(emp, a_key, overlay))
		vbox.add_child(btn)


func _on_assign_from_prompt(emp: EmployeeData, assignment: EmployeeData.Assignment, overlay: Control) -> void:
	emp.assignment = assignment
	overlay.queue_free()
	_assign_target = null
	_refresh_list()


func _on_pass_candidate(candidate: EmployeeData) -> void:
	_candidates.erase(candidate)
	candidate_panel.visible = not _candidates.is_empty()
	_refresh_candidates()


func _on_back() -> void:
	SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")


static func _make_card_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.12, 0.12, 0.16)
	s.set_corner_radius_all(8)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s
