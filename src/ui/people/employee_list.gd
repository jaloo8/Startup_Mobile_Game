extends Control
## Employee management screen — view team, hire, fire, assign work.

@onready var list_container: VBoxContainer = %EmployeeListContainer
@onready var hire_btn: Button = %HireButton
@onready var back_btn: Button = %BackButton
@onready var capacity_label: Label = %CapacityLabel
@onready var candidate_container: VBoxContainer = %CandidateContainer
@onready var candidate_panel: PanelContainer = %CandidatePanel
@onready var sort_row: HBoxContainer = %SortRow
@onready var sort_label: Label = %SortLabel

var _candidates: Array[EmployeeData] = []
var _interview_reports: Dictionary = {}  # candidate_key -> interview report
var _negotiated: Dictionary = {}         # candidate_key -> true if already negotiated
var _card_style: StyleBoxFlat
var _assign_target: EmployeeData
var _sort_buttons: Dictionary = {}  # SortKey -> Button
var _sort_hint_label: Label
var _allocation_hint_label: Label

enum SortKey { NAME, SKILL, MORALE, SALARY, ASSIGNMENT }
var _current_sort: SortKey = SortKey.NAME
var _sort_ascending: bool = true

const SORT_LABELS: Dictionary = {
	SortKey.NAME: "Name",
	SortKey.SKILL: "Skill",
	SortKey.MORALE: "Morale",
	SortKey.SALARY: "Salary",
	SortKey.ASSIGNMENT: "Focus",
}

const POSTING_FEE := 5_000.0
const CULTURE_READ_THRESHOLD := 70
const INTERVIEW_ROLE_VP := "VP"
const INTERVIEW_ROLE_DIRECTOR := "Director"
const INTERVIEW_ROLE_MANAGER := "Manager"
const INTERVIEW_ROLE_ENGINEER := "Engineer"
const INTERVIEW_ROLE_FOUNDER := "Founder"
const INTERVIEW_COST_BY_ROLE: Dictionary = {
	INTERVIEW_ROLE_FOUNDER: 1_500.0,
	INTERVIEW_ROLE_VP: 6_000.0,
	INTERVIEW_ROLE_DIRECTOR: 3_500.0,
	INTERVIEW_ROLE_MANAGER: 2_000.0,
	INTERVIEW_ROLE_ENGINEER: 750.0,
}
const INTERVIEW_LOCK_BY_ROLE: Dictionary = {
	INTERVIEW_ROLE_FOUNDER: 0,  # founder has energy cost, no assignment lock
	INTERVIEW_ROLE_VP: 2,
	INTERVIEW_ROLE_DIRECTOR: 1,
	INTERVIEW_ROLE_MANAGER: 1,
	INTERVIEW_ROLE_ENGINEER: 1,
}
const INTERVIEW_EARLY_QUARTER_MAX := 8
const INTERVIEW_LATE_QUARTER_MIN := 24
const INTERVIEW_LATE_VALUATION := 250_000_000.0
const INTERVIEW_COST_MULT_EARLY := 0.72
const INTERVIEW_COST_MULT_MID := 1.0
const INTERVIEW_COST_MULT_LATE := 1.22
const INTERVIEW_COST_DIFF_MULT: Dictionary = {
	"sandbox": 0.90,
	"normal": 1.00,
	"hardcore": 1.10,
}

const AVATAR_COUNT := 8
const ASSIGNMENT_ICON_PATHS: Dictionary = {
	EmployeeData.Assignment.FEATURES:  "res://assets/icons/assign_features.png",
	EmployeeData.Assignment.BUGS:      "res://assets/icons/assign_bugs.png",
	EmployeeData.Assignment.TECH_DEBT: "res://assets/icons/assign_techdebt.png",
	EmployeeData.Assignment.INFRA:     "res://assets/icons/assign_infra.png",
	EmployeeData.Assignment.RND:       "res://assets/icons/assign_rnd.png",
}

const ASSIGNMENT_DESCRIPTIONS: Dictionary = {
	EmployeeData.Assignment.FEATURES: "Build new product features.\nMore features attract users.",
	EmployeeData.Assignment.BUGS: "Squash bugs.\nFewer bugs means less churn.",
	EmployeeData.Assignment.TECH_DEBT: "Clean up messy code.\nHigh tech debt slows everyone down.",
	EmployeeData.Assignment.INFRA: "Improve stability and uptime.\nUnstable products lose users fast.",
	EmployeeData.Assignment.RND: "Research and improve UX.\nBetter UX means happier users.",
}
const RESPONSIBILITY_STAGE_EARLY := "early"
const RESPONSIBILITY_STAGE_GROWTH := "growth"
const RESPONSIBILITY_STAGE_SCALE := "scale"


func _ready() -> void:
	_card_style = _make_card_style()
	hire_btn.pressed.connect(_on_hire_pressed)
	back_btn.pressed.connect(_on_back)
	candidate_panel.visible = false
	_build_sort_buttons()
	_build_allocation_hint_label()
	_update_hire_button()
	_refresh_list()
	UITouchHelper.harden_tree(self)
	Analytics.track_screen("people")
	AnimHelper.pop_in(capacity_label, 0.0, 0.22)
	AnimHelper.stagger_list(list_container, 0.05, 0.06, 20.0)


func _exit_tree() -> void:
	_candidates.clear()
	_interview_reports.clear()
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
	sort_label.text = "Sort hired team:"
	sort_label.add_theme_font_size_override("font_size", 12)
	sort_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.86))

	_sort_buttons.clear()
	for key in SortKey.values():
		var btn := Button.new()
		btn.text = SORT_LABELS[key]
		btn.custom_minimum_size = Vector2(82, 46)
		btn.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
		btn.pressed.connect(_on_sort_pressed.bind(key))
		sort_row.add_child(btn)
		_sort_buttons[key] = btn

	_build_sort_hint_label()
	_highlight_sort_button()
	_refresh_sort_hint()


func _build_sort_hint_label() -> void:
	if _sort_hint_label != null:
		return
	var parent := sort_row.get_parent()
	if parent == null:
		return
	_sort_hint_label = Label.new()
	_sort_hint_label.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	_sort_hint_label.add_theme_color_override("font_color", Color(0.56, 0.6, 0.72))
	_sort_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(_sort_hint_label)
	parent.move_child(_sort_hint_label, sort_row.get_index() + 1)


func _build_allocation_hint_label() -> void:
	if _allocation_hint_label != null:
		return
	var parent := capacity_label.get_parent()
	if parent == null:
		return
	_allocation_hint_label = Label.new()
	_allocation_hint_label.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	_allocation_hint_label.add_theme_color_override("font_color", ThemeManager.C_TEXT_HINT)
	_allocation_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(_allocation_hint_label)
	parent.move_child(_allocation_hint_label, capacity_label.get_index() + 1)


func _responsibility_stage() -> String:
	return SimulationEngine.responsibility_stage(GameState)


func _assignment_count(target: EmployeeData.Assignment) -> int:
	var count := 0
	for emp: EmployeeData in GameState.employees:
		if emp.assignment == target:
			count += 1
	return count


func _refresh_allocation_hint() -> void:
	if _allocation_hint_label == null:
		return
	var stage: String = _responsibility_stage()
	if stage == RESPONSIBILITY_STAGE_EARLY:
		_allocation_hint_label.text = "Team model: Early startup (shared hats). Keep most people on Features; other lanes still provide partial feature support."
		_allocation_hint_label.add_theme_color_override("font_color", ThemeManager.C_TEXT_HINT)
		return

	var missing: Array[String] = []
	if _assignment_count(EmployeeData.Assignment.BUGS) == 0:
		missing.append("Bug Fixes")
	if _assignment_count(EmployeeData.Assignment.TECH_DEBT) == 0:
		missing.append("Tech Debt")
	if _assignment_count(EmployeeData.Assignment.INFRA) == 0:
		missing.append("Infrastructure")
	if _assignment_count(EmployeeData.Assignment.RND) == 0:
		missing.append("R&D")
	if missing.is_empty():
		if stage == RESPONSIBILITY_STAGE_GROWTH:
			_allocation_hint_label.text = "Team model: Growth stage. Coverage looks balanced across delivery and maintenance lanes."
		else:
			_allocation_hint_label.text = "Team model: Scale stage. Nice specialization coverage — this keeps churn and hidden drag under control."
		_allocation_hint_label.add_theme_color_override("font_color", Color(0.45, 0.84, 0.56))
		return

	_allocation_hint_label.text = "Specialization now matters: add coverage in %s." % ", ".join(missing)
	_allocation_hint_label.add_theme_color_override("font_color", Color(0.92, 0.72, 0.40))


func _assignment_description_for_stage(a_key: EmployeeData.Assignment, stage: String) -> String:
	var base: String = str(ASSIGNMENT_DESCRIPTIONS.get(a_key, ""))
	if stage == RESPONSIBILITY_STAGE_EARLY:
		if a_key == EmployeeData.Assignment.FEATURES:
			return base + "\nEarly stage: this is your main shipping lane."
		return base + "\nEarly stage: still contributes some support to feature delivery."
	if stage == RESPONSIBILITY_STAGE_GROWTH:
		match a_key:
			EmployeeData.Assignment.BUGS:
				return base + "\nGrowth stage: prevents churn spikes from unresolved bugs."
			EmployeeData.Assignment.TECH_DEBT:
				return base + "\nGrowth stage: protects feature velocity as complexity rises."
			EmployeeData.Assignment.INFRA:
				return base + "\nGrowth stage: protects reliability and hosting pressure."
			EmployeeData.Assignment.RND:
				return base + "\nGrowth stage: improves retention and user pull."
			_:
				return base + "\nGrowth stage: still important, but not enough alone."
	match a_key:
		EmployeeData.Assignment.FEATURES:
			return base + "\nScale stage: ships roadmap, but needs support lanes to stay efficient."
		EmployeeData.Assignment.BUGS:
			return base + "\nScale stage: critical for churn and quality control."
		EmployeeData.Assignment.TECH_DEBT:
			return base + "\nScale stage: critical for avoiding hidden productivity drag."
		EmployeeData.Assignment.INFRA:
			return base + "\nScale stage: critical for uptime and incident prevention."
		EmployeeData.Assignment.RND:
			return base + "\nScale stage: critical for engagement and growth quality."
		_:
			return base


func _refresh_sort_hint() -> void:
	if _sort_hint_label == null:
		return
	var order_text := "A→Z"
	match _current_sort:
		SortKey.SKILL, SortKey.MORALE, SortKey.SALARY:
			order_text = "low→high" if _sort_ascending else "high→low"
		SortKey.ASSIGNMENT:
			order_text = "focus A→Z" if _sort_ascending else "focus Z→A"
		_:
			order_text = "A→Z" if _sort_ascending else "Z→A"

	var base := "Team sort: %s (%s)." % [SORT_LABELS[_current_sort], order_text]
	if GameState.employees.size() <= 1:
		base += " Hire at least 2 teammates to see reordering."
	elif candidate_panel.visible and not _candidates.is_empty():
		base += " Candidate cards keep hiring-pipeline order."
	_sort_hint_label.text = base


func _on_sort_pressed(key: SortKey) -> void:
	if _current_sort == key:
		_sort_ascending = not _sort_ascending
	else:
		_current_sort = key
		# Numeric priorities default to strongest-first.
		_sort_ascending = false if key in [SortKey.SKILL, SortKey.MORALE, SortKey.SALARY] else true
	_highlight_sort_button()
	_refresh_list()
	_refresh_sort_hint()


func _highlight_sort_button() -> void:
	for key in SortKey.values():
		var btn := _sort_buttons.get(key, null) as Button
		if btn == null:
			continue
		if key == _current_sort:
			btn.modulate = Color(0.4, 0.85, 1.0)
			btn.text = SORT_LABELS[key] + (" ↑" if _sort_ascending else " ↓")
		else:
			btn.modulate = Color(1, 1, 1, 0.7)
			btn.text = SORT_LABELS[key]


static func _int_cmp(a: int, b: int) -> int:
	if a < b:
		return -1
	if a > b:
		return 1
	return 0


static func _float_cmp(a: float, b: float) -> int:
	if is_equal_approx(a, b):
		return 0
	return -1 if a < b else 1


func _employee_cmp(a: EmployeeData, b: EmployeeData) -> int:
	var cmp := 0
	match _current_sort:
		SortKey.SKILL:
			cmp = _int_cmp(a.skill, b.skill)
		SortKey.MORALE:
			cmp = _int_cmp(a.morale, b.morale)
		SortKey.SALARY:
			cmp = _float_cmp(a.salary_per_quarter, b.salary_per_quarter)
		SortKey.ASSIGNMENT:
			cmp = _int_cmp(int(a.assignment), int(b.assignment))
		_:
			cmp = a.employee_name.naturalnocasecmp_to(b.employee_name)
	if cmp == 0:
		cmp = a.employee_name.naturalnocasecmp_to(b.employee_name)
	return cmp


func _sorted_employees() -> Array[EmployeeData]:
	var arr: Array[EmployeeData] = []
	arr.assign(GameState.employees.duplicate())
	arr.sort_custom(func(a: EmployeeData, b: EmployeeData) -> bool:
		var cmp := _employee_cmp(a, b)
		if cmp == 0:
			return false
		return (cmp < 0) if _sort_ascending else (cmp > 0)
	)
	return arr


func _refresh_list() -> void:
	SceneLoader.free_children(list_container)

	capacity_label.text = "Team: %d / %d (%s)" % [
		GameState.employees.size(),
		GameState.company.office_capacity(),
		GameState.company.office_name(),
	]
	_refresh_allocation_hint()

	if GameState.employees.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No employees yet. Hire your first team member!"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		list_container.add_child(empty_label)
		_refresh_sort_hint()
		UITouchHelper.harden_tree(self)
		return

	for emp in _sorted_employees():
		list_container.add_child(_create_employee_card(emp))
	AnimHelper.stagger_list(list_container, 0.045, 0.0, 24.0)
	_refresh_sort_hint()
	UITouchHelper.harden_tree(self)


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
	# Apply a morale-tinted left border accent to the card.
	var styled := StyleBoxFlat.new()
	styled.bg_color = Color(0.12, 0.12, 0.16)
	styled.set_corner_radius_all(8)
	styled.content_margin_left = 12
	styled.content_margin_right = 12
	styled.content_margin_top = 10
	styled.content_margin_bottom = 10
	styled.border_width_left = 3
	if emp.morale >= 70:
		styled.border_color = ThemeManager.C_GREEN   # green
	elif emp.morale >= 40:
		styled.border_color = Color(0.92, 0.76, 0.22)   # gold
	else:
		styled.border_color = ThemeManager.C_RED   # red
	panel.add_theme_stylebox_override("panel", styled)

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

	# High-stress warning badge
	if emp.stress >= 70:
		var stress_badge := Label.new()
		stress_badge.text = "⚠ Burnout risk" if emp.stress >= 85 else "⚠ High stress"
		stress_badge.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
		stress_badge.add_theme_color_override("font_color",
			Color(0.92, 0.28, 0.28) if emp.stress >= 85 else Color(0.95, 0.62, 0.22))
		title_row.add_child(stress_badge)

	var busy_q := GameState.interviewer_busy_for(emp.employee_uid)
	if busy_q > 0:
		var busy_badge := Label.new()
		busy_badge.text = "Interviewing (%dQ left)" % busy_q
		busy_badge.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
		busy_badge.add_theme_color_override("font_color", Color(0.95, 0.72, 0.35))
		title_row.add_child(busy_badge)

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
	if emp.employment_type == EmployeeData.EmploymentType.CONTRACTOR:
		salary_label.text = "Contract: $%sK/quarter" % str(snapped(emp.salary_per_quarter / 1000.0, 0.1))
	elif emp.employment_type == EmployeeData.EmploymentType.INTERN:
		salary_label.text = "Intern stipend: $%sK/quarter" % str(snapped(emp.salary_per_quarter / 1000.0, 0.1))
	salary_label.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	salary_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	vbox.add_child(salary_label)

	var profile_lbl := Label.new()
	profile_lbl.text = "%s · %s" % [emp.employment_label(), emp.personality_label()]
	profile_lbl.add_theme_font_size_override("font_size", 12)
	profile_lbl.add_theme_color_override("font_color", Color(0.58, 0.66, 0.82))
	vbox.add_child(profile_lbl)

	var assign_row := HBoxContainer.new()
	assign_row.add_theme_constant_override("separation", 6)
	vbox.add_child(assign_row)

	var assign_label := Label.new()
	assign_label.text = "Focus:"
	assign_label.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	assign_row.add_child(assign_label)

	for a_key in EmployeeData.ASSIGNMENT_NAMES:
		if a_key == EmployeeData.Assignment.UNASSIGNED:
			continue
		var btn := Button.new()
		btn.text = EmployeeData.ASSIGNMENT_NAMES[a_key]
		btn.custom_minimum_size = Vector2(0, 46)
		btn.toggle_mode = true
		btn.button_pressed = (emp.assignment == a_key)
		btn.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
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
	fire_btn.custom_minimum_size = Vector2(78, 46)
	fire_btn.pressed.connect(_on_fire.bind(emp))
	action_row.add_child(fire_btn)

	var detail_btn := Button.new()
	detail_btn.text = "Details"
	detail_btn.custom_minimum_size = Vector2(82, 46)
	detail_btn.pressed.connect(_on_view_details.bind(emp))
	action_row.add_child(detail_btn)

	return panel


func _on_assign_direct(emp: EmployeeData, assignment: EmployeeData.Assignment) -> void:
	emp.assignment = assignment
	Analytics.track_assignment_change(EmployeeData.ASSIGNMENT_NAMES.get(assignment, "unknown"))
	_refresh_list()


func _on_fire(emp: EmployeeData) -> void:
	Analytics.track_fire()
	SfxPlayer.play("fire")
	GameState.fire_employee(emp)
	_update_hire_button()
	_refresh_list()


func _on_view_details(emp: EmployeeData) -> void:
	if emp == null:
		return
	GameState.set_meta("employee_detail_uid", emp.employee_uid)
	SceneLoader.goto_scene("res://src/ui/people/employee_detail.tscn")


func _add_stat(parent: HBoxContainer, label_text: String, value: int) -> void:
	var lbl := Label.new()
	var color: Color
	if value >= 70:
		color = ThemeManager.C_GREEN
	elif value >= 40:
		color = Color(0.9, 0.8, 0.2)
	else:
		color = ThemeManager.C_RED
	lbl.text = "%s: %d" % [label_text, value]
	lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
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

	_candidates = HiringEngine.generate_candidates(3, GameState.market, GameState)
	_interview_reports.clear()
	_negotiated.clear()
	candidate_panel.visible = true
	AnimHelper.pop_in(candidate_panel, 0.0, 0.2)
	_update_hire_button()
	_refresh_candidates()


func _refresh_candidates() -> void:
	SceneLoader.free_children(candidate_container)

	if _candidates.is_empty():
		var lbl := Label.new()
		lbl.text = "No more candidates this round."
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		candidate_container.add_child(lbl)
		_refresh_sort_hint()
		UITouchHelper.harden_tree(candidate_panel)
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
		name_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_MD)
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
				fit_badge.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
				cand_title_row.add_child(fit_badge)

		var cost_per_q: float = candidate.salary_per_quarter
		var runway: float = GameState.financials.runway_quarters(GameState.company.cash)
		var salary_text := "Asking $%sK/yr ($%sK/quarter)" % [str(snapped(cost_per_q * 4 / 1000.0, 0.1)), str(snapped(cost_per_q / 1000.0, 0.1))]
		if candidate.employment_type == EmployeeData.EmploymentType.CONTRACTOR:
			salary_text = "Contract rate $%sK/quarter (flex headcount)" % str(snapped(cost_per_q / 1000.0, 0.1))
		elif candidate.employment_type == EmployeeData.EmploymentType.INTERN:
			salary_text = "Intern stipend $%sK/quarter (high growth upside)" % str(snapped(cost_per_q / 1000.0, 0.1))
		var salary_lbl := Label.new()
		salary_lbl.text = salary_text
		salary_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
		salary_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		vbox.add_child(salary_lbl)

		var profile_line := Label.new()
		profile_line.text = "%s · %s" % [candidate.employment_label(), candidate.personality_label()]
		profile_line.add_theme_font_size_override("font_size", 12)
		profile_line.add_theme_color_override("font_color", Color(0.58, 0.66, 0.82))
		vbox.add_child(profile_line)

		if runway != INF and runway < 4.0:
			var warn_lbl := Label.new()
			warn_lbl.text = "⚠ You have ~%d quarters of runway left" % roundi(runway)
			warn_lbl.add_theme_font_size_override("font_size", 12)
			warn_lbl.add_theme_color_override("font_color", Color(0.95, 0.6, 0.2))
			vbox.add_child(warn_lbl)

		var ckey: int = _candidate_key(candidate)
		var report: Dictionary = _safe_dict(_interview_reports.get(ckey, {}))
		var interviewed: bool = not report.is_empty()
		if interviewed:
			var stats_row := HBoxContainer.new()
			stats_row.add_theme_constant_override("separation", 16)
			vbox.add_child(stats_row)
			_add_stat(stats_row, "Skill", int(report.get("skill", candidate.skill)))
			_add_stat(stats_row, "Speed", int(report.get("speed", candidate.speed)))
			_add_stat(stats_row, "Morale", int(report.get("morale", candidate.morale)))

			var culture_estimate: int = int(report.get("culture_fit", -1))
			var culture_lbl := Label.new()
			if culture_estimate < 0:
				culture_lbl.text = "Culture fit: ??? (interviewer not confident)"
				culture_lbl.add_theme_color_override("font_color", Color(0.66, 0.58, 0.42))
			else:
				culture_lbl.text = "Culture fit estimate: %d" % culture_estimate
				culture_lbl.add_theme_color_override("font_color", Color(0.56, 0.74, 0.90))
			culture_lbl.add_theme_font_size_override("font_size", 12)
			vbox.add_child(culture_lbl)

			var growth_lbl := Label.new()
			growth_lbl.text = str(report.get("growth_text", "Growth potential estimate unavailable"))
			growth_lbl.add_theme_font_size_override("font_size", 12)
			growth_lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 0.9))
			vbox.add_child(growth_lbl)

			var meta_lbl := Label.new()
			meta_lbl.text = "Interviewed by %s (%s) — %s" % [
				report.get("interviewer_name", "Unknown"),
				report.get("interviewer_role", "Interviewer"),
				report.get("confidence", "Unknown confidence"),
			]
			meta_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
			meta_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
			vbox.add_child(meta_lbl)

			var feedback_lbl := Label.new()
			feedback_lbl.text = str(report.get("feedback", ""))
			feedback_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
			feedback_lbl.add_theme_color_override("font_color", Color(0.78, 0.80, 0.88))
			feedback_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(feedback_lbl)
		else:
			var hidden_lbl := Label.new()
			hidden_lbl.text = "Run an interview to estimate their stats and fit."
			hidden_lbl.add_theme_font_size_override("font_size", 12)
			hidden_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
			vbox.add_child(hidden_lbl)

		# Negotiation row — show if not yet negotiated
		var already_negotiated: bool = _negotiated.has(ckey)
		if not already_negotiated:
			var neg_row := HBoxContainer.new()
			neg_row.add_theme_constant_override("separation", 8)
			vbox.add_child(neg_row)

			var neg_btn := Button.new()
			neg_btn.text = "Negotiate Salary (-15%)"
			neg_btn.custom_minimum_size = Vector2(0, 46)
			neg_btn.add_theme_font_size_override("font_size", 12)
			neg_btn.pressed.connect(_on_negotiate_salary.bind(candidate))
			neg_row.add_child(neg_btn)

			var neg_hint := Label.new()
			neg_hint.text = "One chance — they may walk"
			neg_hint.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
			neg_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
			neg_row.add_child(neg_hint)
		else:
			var neg_done_lbl := Label.new()
			neg_done_lbl.text = "Salary negotiated"
			neg_done_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
			neg_done_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
			vbox.add_child(neg_done_lbl)

		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 8)
		vbox.add_child(btn_row)

		if not interviewed:
			var interview_btn := Button.new()
			interview_btn.text = "Interview Team…"
			interview_btn.custom_minimum_size = Vector2(134, 46)
			interview_btn.pressed.connect(_on_interview.bind(candidate))
			btn_row.add_child(interview_btn)

			if AdManager.is_ad_available("rewarded_reveal_stats"):
				var ad_btn := Button.new()
				ad_btn.text = "Quick Peek (Ad)"
				ad_btn.custom_minimum_size = Vector2(120, 46)
				ad_btn.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
				ad_btn.pressed.connect(_on_ad_reveal.bind(candidate))
				btn_row.add_child(ad_btn)

		var hire_one_btn := Button.new()
		hire_one_btn.text = "Hire"
		hire_one_btn.custom_minimum_size = Vector2(78, 46)
		hire_one_btn.pressed.connect(_on_hire_candidate.bind(candidate))
		btn_row.add_child(hire_one_btn)

		var pass_btn := Button.new()
		pass_btn.text = "Pass"
		pass_btn.custom_minimum_size = Vector2(68, 46)
		pass_btn.pressed.connect(_on_pass_candidate.bind(candidate))
		btn_row.add_child(pass_btn)

		candidate_container.add_child(card)
	_add_extra_candidate_button()
	AnimHelper.stagger_list(candidate_container, 0.05, 0.04, 22.0)
	_refresh_sort_hint()
	UITouchHelper.harden_tree(candidate_panel)


func _add_extra_candidate_button() -> void:
	var cost: int = CurrencyManager.COST_EXTRA_CANDIDATE
	if not CurrencyManager.can_afford(cost):
		return
	# Don't offer if already at office capacity.
	if GameState.employees.size() + _candidates.size() >= GameState.company.office_capacity():
		return
	var btn := Button.new()
	btn.text = "Reveal Extra Candidate (%d chips)" % cost
	btn.custom_minimum_size = Vector2(0, 46)
	btn.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	btn.add_theme_color_override("font_color", ThemeManager.C_CHIP)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.20, 0.5)
	style.set_corner_radius_all(ThemeManager.CORNER_MD)
	style.set_content_margin_all(8.0)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = style.bg_color.lightened(0.08)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", style)
	btn.pressed.connect(_on_extra_candidate)
	candidate_container.add_child(btn)


func _on_extra_candidate() -> void:
	if not CurrencyManager.spend_extra_candidate():
		return
	var extras: Array[EmployeeData] = HiringEngine.generate_candidates(
		1, GameState.market, GameState)
	_candidates.append_array(extras)
	AnimHelper.float_text(candidate_panel, "-%d chips" % CurrencyManager.COST_EXTRA_CANDIDATE,
		ThemeManager.C_CHIP, Vector2(candidate_panel.size.x * 0.5, 0))
	SfxPlayer.play("chip_spend")
	_refresh_candidates()


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
	lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.75, 0.35))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_child(lbl)
	list_container.add_child(hint)
	list_container.move_child(hint, 0)


func _on_negotiate_salary(candidate: EmployeeData) -> void:
	# One-shot negotiation: reduce salary 15%, but low-morale candidates may walk.
	# Chance they walk scales with how low their culture_fit + morale are.
	_negotiated[_candidate_key(candidate)] = true
	var walk_chance: float = remap(float(candidate.culture_fit + candidate.morale), 0.0, 200.0, 0.35, 0.0)
	walk_chance = clampf(walk_chance, 0.0, 0.35)
	if randf() < walk_chance:
		# They walked
		_interview_reports.erase(_candidate_key(candidate))
		_candidates.erase(candidate)
		if _candidates.is_empty():
			AnimHelper.pop_out(candidate_panel, 0.14, func() -> void:
				candidate_panel.visible = false
			)
		else:
			_refresh_candidates()
		_show_temp_message("They declined and pulled out of the process.")
	else:
		candidate.salary_per_quarter = maxf(1000.0, candidate.salary_per_quarter * 0.85)
		_refresh_candidates()


func _show_temp_message(msg: String) -> void:
	var lbl := Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.55, 0.3))
	candidate_container.add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(func() -> void:
		if is_instance_valid(lbl):
			lbl.queue_free()
	)


func _on_ad_reveal(candidate: EmployeeData) -> void:
	var ckey := _candidate_key(candidate)
	if _interview_reports.has(ckey):
		return
	if AdManager.show_ad("rewarded_reveal_stats"):
		_interview_reports[ckey] = _quick_peek_report(candidate)
		_refresh_candidates()


func _on_interview(candidate: EmployeeData) -> void:
	if _interview_reports.has(_candidate_key(candidate)):
		return
	_show_interviewer_picker(candidate)


static func _candidate_key(candidate: EmployeeData) -> int:
	return candidate.get_instance_id()


static func _safe_dict(value) -> Dictionary:
	return value if value is Dictionary else {}


func _interview_stage() -> String:
	var elapsed_q := GameState.total_quarters_elapsed()
	if elapsed_q <= INTERVIEW_EARLY_QUARTER_MAX and GameState.company.cash < 250_000.0:
		return "early"
	if elapsed_q >= INTERVIEW_LATE_QUARTER_MIN or GameState.company.valuation >= INTERVIEW_LATE_VALUATION:
		return "late"
	return "mid"


func _interview_stage_cost_mult() -> float:
	match _interview_stage():
		"early":
			return INTERVIEW_COST_MULT_EARLY
		"late":
			return INTERVIEW_COST_MULT_LATE
		_:
			return INTERVIEW_COST_MULT_MID


func _effective_interview_cost(role: String) -> float:
	var base_cost := float(INTERVIEW_COST_BY_ROLE.get(role, 1000.0))
	var difficulty_mult := float(INTERVIEW_COST_DIFF_MULT.get(GameState.difficulty, 1.0))
	var tuned := base_cost * _interview_stage_cost_mult() * difficulty_mult
	return maxf(250.0, snapped(tuned, 50.0))


func _effective_interview_lock(role: String) -> int:
	var base_lock := int(INTERVIEW_LOCK_BY_ROLE.get(role, 1))
	if base_lock <= 0:
		return 0
	var stage := _interview_stage()
	if stage == "early":
		return maxi(0, base_lock - 1)
	if stage == "late" and (role == INTERVIEW_ROLE_VP or role == INTERVIEW_ROLE_DIRECTOR):
		return mini(3, base_lock + 1)
	return base_lock


func _interview_stage_hint() -> String:
	var stage := _interview_stage()
	var raw_mult: float = _interview_stage_cost_mult()
	match stage:
		"early":
			var discount_pct := roundi((1.0 - raw_mult) * 100.0)
			return "Early-stage hiring market: interview costs are %d%% cheaper." % discount_pct
		"late":
			var premium_pct := roundi((raw_mult - 1.0) * 100.0)
			return "Late-stage hiring market: interview costs are %d%% higher and senior lock times are longer." % premium_pct
		_:
			return "Growth-stage hiring market: standard interview costs."


static func _cost_k(cost: float) -> String:
	return str(snapped(cost / 1000.0, 0.1))


func _confidence_chip_color(accuracy: float) -> Color:
	if accuracy >= 0.86:
		return Color(0.20, 0.46, 0.30)
	if accuracy >= 0.74:
		return Color(0.45, 0.37, 0.15)
	return Color(0.45, 0.22, 0.20)


func _chip(text: String, bg_color: Color, fg_color: Color = Color(0.95, 0.97, 1.0)) -> PanelContainer:
	var chip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	chip.add_theme_stylebox_override("panel", style)

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", fg_color)
	chip.add_child(lbl)
	return chip


func _interviewer_role(emp: EmployeeData) -> String:
	match emp.seniority:
		EmployeeData.Seniority.PRINCIPAL:
			return INTERVIEW_ROLE_VP
		EmployeeData.Seniority.LEAD:
			return INTERVIEW_ROLE_DIRECTOR
		EmployeeData.Seniority.SENIOR:
			return INTERVIEW_ROLE_MANAGER
		_:
			return INTERVIEW_ROLE_ENGINEER


func _interviewer_people_skill(emp: EmployeeData) -> int:
	var seniority_bonus := 0
	match emp.seniority:
		EmployeeData.Seniority.PRINCIPAL: seniority_bonus = 12
		EmployeeData.Seniority.LEAD: seniority_bonus = 8
		EmployeeData.Seniority.SENIOR: seniority_bonus = 4
		EmployeeData.Seniority.JUNIOR: seniority_bonus = -4
	var estimate := roundi(emp.culture_fit * 0.45 + emp.morale * 0.35 + emp.skill * 0.20) + seniority_bonus
	return clampi(estimate, 1, 100)


func _interview_accuracy(role: String, people_skill: int) -> float:
	match role:
		INTERVIEW_ROLE_VP:
			return 0.88 + float(people_skill - 50) * 0.001
		INTERVIEW_ROLE_DIRECTOR:
			return 0.80 + float(people_skill - 50) * 0.0012
		INTERVIEW_ROLE_MANAGER:
			return 0.72 + float(people_skill - 50) * 0.0014
		INTERVIEW_ROLE_FOUNDER:
			return 0.58 + float(people_skill) * 0.0032
		_:
			# Engineers are cheaper but quality depends heavily on people skill.
			return 0.50 + float(people_skill) * 0.0030


func _confidence_label(accuracy: float) -> String:
	if accuracy >= 0.86:
		return "High confidence"
	if accuracy >= 0.74:
		return "Moderate confidence"
	return "Low confidence"


func _fuzzy_stat(actual: int, margin: int) -> int:
	return clampi(actual + randi_range(-margin, margin), 0, 100)


func _growth_text(value: int) -> String:
	match value:
		EmployeeData.GrowthPotential.HIGH:
			return "High growth potential"
		EmployeeData.GrowthPotential.MEDIUM:
			return "Moderate growth potential"
		_:
			return "Limited growth potential"


func _estimate_growth_text(actual: int, accuracy: float) -> String:
	var shown := actual
	if randf() > accuracy:
		shown += (1 if randf() < 0.5 else -1)
	shown = clampi(shown, EmployeeData.GrowthPotential.LOW, EmployeeData.GrowthPotential.HIGH)
	return _growth_text(shown)


func _feedback_text(role: String, skill: int, speed: int, morale: int, culture_fit: int) -> String:
	var role_bias := ""
	match role:
		INTERVIEW_ROLE_VP:
			role_bias = "Leans toward strategic ownership and leadership potential."
		INTERVIEW_ROLE_DIRECTOR:
			role_bias = "Leans toward execution reliability and cross-team delivery."
		INTERVIEW_ROLE_MANAGER:
			role_bias = "Leans toward day-to-day consistency and coachability."
		INTERVIEW_ROLE_ENGINEER:
			role_bias = "Leans toward technical signal more than soft-skill nuance."
		_:
			role_bias = "Founder gut check."

	var verdict := ""
	if skill >= 75 and speed >= 70 and morale >= 65:
		verdict = "Strong near-term hire."
	elif skill >= 60 and morale >= 55:
		verdict = "Solid hire with manageable risk."
	else:
		verdict = "Higher-risk hire; needs support and tighter onboarding."

	if culture_fit < 0:
		return "%s %s Culture fit remains unclear." % [verdict, role_bias]
	if culture_fit >= 70:
		return "%s %s Culture alignment looks good." % [verdict, role_bias]
	return "%s %s Culture alignment may need attention." % [verdict, role_bias]


func _quick_peek_report(candidate: EmployeeData) -> Dictionary:
	var accuracy := 0.52
	var margin := maxi(12, roundi((1.0 - accuracy) * 32.0))
	var shown_skill := _fuzzy_stat(candidate.skill, margin)
	var shown_speed := _fuzzy_stat(candidate.speed, margin)
	var shown_morale := _fuzzy_stat(candidate.morale, margin)
	return {
		"interviewer_name": "Quick Peek",
		"interviewer_role": "Ad Snapshot",
		"confidence": _confidence_label(accuracy),
		"skill": shown_skill,
		"speed": shown_speed,
		"morale": shown_morale,
		"culture_fit": -1,
		"growth_text": _estimate_growth_text(candidate.growth_potential, accuracy),
		"feedback": "Fast signal only — treat this as directional, not definitive.",
	}


func _show_interviewer_picker(candidate: EmployeeData) -> void:
	var existing := get_node_or_null("InterviewOverlay")
	if existing:
		existing.queue_free()

	var overlay := ColorRect.new()
	overlay.name = "InterviewOverlay"
	overlay.color = Color(0, 0, 0, 0.72)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -300
	panel.offset_right = 300
	panel.offset_top = -250
	panel.offset_bottom = 250
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.10, 0.15)
	style.set_corner_radius_all(12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	var title := Label.new()
	title.text = "Choose an interviewer for %s" % candidate.employee_name
	title.add_theme_font_size_override("font_size", ThemeManager.FONT_LG)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Better interviewers give cleaner reads, but can tie up team capacity."
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(subtitle)

	var stage_lbl := Label.new()
	stage_lbl.text = _interview_stage_hint()
	stage_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	stage_lbl.add_theme_color_override("font_color", Color(0.56, 0.74, 0.90))
	stage_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(stage_lbl)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 300)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var options := VBoxContainer.new()
	options.add_theme_constant_override("separation", 6)
	scroll.add_child(options)

	# Founder option (always available, no output lock, founder energy hit).
	var founder_people := clampi(GameState.company.founder_stat("people") * 10, 1, 100)
	var founder_accuracy := clampf(_interview_accuracy(INTERVIEW_ROLE_FOUNDER, founder_people), 0.40, 0.95)
	var founder_cost := _effective_interview_cost(INTERVIEW_ROLE_FOUNDER)
	var founder_lock := _effective_interview_lock(INTERVIEW_ROLE_FOUNDER)
	_add_interviewer_option(
		options, overlay, candidate,
		"Founder", INTERVIEW_ROLE_FOUNDER, founder_people, founder_accuracy,
		founder_cost,
		founder_lock,
		""
	)

	for emp in GameState.employees:
		emp.ensure_uid()
		var role := _interviewer_role(emp)
		var people_skill := _interviewer_people_skill(emp)
		var accuracy := clampf(_interview_accuracy(role, people_skill), 0.40, 0.95)
		var role_cost := _effective_interview_cost(role)
		var role_lock := _effective_interview_lock(role)
		_add_interviewer_option(
			options, overlay, candidate,
			emp.employee_name, role, people_skill, accuracy,
			role_cost,
			role_lock,
			emp.employee_uid
		)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 46)
	cancel_btn.pressed.connect(func() -> void: overlay.queue_free())
	root.add_child(cancel_btn)
	UITouchHelper.harden_tree(overlay)


func _add_interviewer_option(
	container: VBoxContainer,
	overlay: Control,
	candidate: EmployeeData,
	interviewer_name: String,
	role: String,
	people_skill: int,
	accuracy: float,
	cost: float,
	lock_quarters: int,
	employee_uid: String
) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.12, 0.14, 0.21, 0.96)
	card_style.set_corner_radius_all(10)
	card_style.border_width_left = 1
	card_style.border_width_right = 1
	card_style.border_width_top = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(0.26, 0.30, 0.46, 0.65)
	card_style.content_margin_left = 10
	card_style.content_margin_right = 10
	card_style.content_margin_top = 8
	card_style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", card_style)
	container.add_child(card)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	card.add_child(body)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	body.add_child(title_row)

	var name_lbl := Label.new()
	name_lbl.text = "%s — %s" % [interviewer_name, role]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	name_lbl.add_theme_color_override("font_color", Color(0.93, 0.95, 1.0))
	title_row.add_child(name_lbl)

	var read_lbl := Label.new()
	read_lbl.text = "People read %d" % people_skill
	read_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	read_lbl.add_theme_color_override("font_color", Color(0.62, 0.74, 0.92))
	title_row.add_child(read_lbl)

	var chips_row := HBoxContainer.new()
	chips_row.add_theme_constant_override("separation", 6)
	body.add_child(chips_row)

	chips_row.add_child(_chip("Cost $%sK" % _cost_k(cost), Color(0.20, 0.36, 0.66)))
	if lock_quarters > 0:
		chips_row.add_child(_chip("Lock %dQ" % lock_quarters, Color(0.34, 0.28, 0.58)))
	else:
		chips_row.add_child(_chip("No lock", Color(0.22, 0.42, 0.44)))
	chips_row.add_child(_chip(_confidence_label(accuracy), _confidence_chip_color(accuracy)))

	var hint_lbl := Label.new()
	hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	body.add_child(hint_lbl)

	var run_btn := Button.new()
	run_btn.text = "Run interview"
	run_btn.custom_minimum_size = Vector2(0, 46)
	body.add_child(run_btn)

	var busy_q := 0
	if not employee_uid.is_empty():
		busy_q = GameState.interviewer_busy_for(employee_uid)
	if busy_q > 0:
		run_btn.disabled = true
		run_btn.text = "Unavailable"
		hint_lbl.text = "Unavailable: currently interviewing (%dQ left)." % busy_q
		hint_lbl.add_theme_color_override("font_color", Color(0.95, 0.72, 0.35))
	elif GameState.company.cash < cost:
		run_btn.disabled = true
		run_btn.text = "Not enough cash"
		var shortage := maxf(0.0, cost - GameState.company.cash)
		hint_lbl.text = "Need $%sK more cash to run this interview." % _cost_k(shortage)
		hint_lbl.add_theme_color_override("font_color", Color(0.92, 0.48, 0.45))
	else:
		var lock_note := "No assignment lock."
		if role == INTERVIEW_ROLE_FOUNDER:
			lock_note = "Founder energy -4."
		elif lock_quarters > 0:
			lock_note = "%s unavailable for %d quarter%s after this interview." % [
				interviewer_name, lock_quarters, "s" if lock_quarters > 1 else ""
			]
		hint_lbl.text = "%s %s" % [_confidence_label(accuracy), lock_note]
		hint_lbl.add_theme_color_override("font_color", Color(0.64, 0.67, 0.77))
		run_btn.pressed.connect(func() -> void:
			_complete_interview(
				candidate, interviewer_name, role, people_skill, accuracy,
				cost, lock_quarters, employee_uid
			)
			overlay.queue_free()
		)


func _complete_interview(
	candidate: EmployeeData,
	interviewer_name: String,
	role: String,
	people_skill: int,
	accuracy: float,
	cost: float,
	lock_quarters: int,
	employee_uid: String
) -> void:
	var ckey := _candidate_key(candidate)
	if _interview_reports.has(ckey):
		return
	if GameState.company.cash < cost:
		_show_temp_message("Not enough cash to run that interview.")
		return

	GameState.company.cash -= cost
	if not employee_uid.is_empty() and lock_quarters > 0:
		GameState.lock_interviewer(employee_uid, lock_quarters)
	if role == INTERVIEW_ROLE_FOUNDER:
		GameState.founder_energy = maxi(0, GameState.founder_energy - 4)

	var margin := maxi(3, roundi((1.0 - accuracy) * 28.0))
	var shown_skill := _fuzzy_stat(candidate.skill, margin)
	var shown_speed := _fuzzy_stat(candidate.speed, margin)
	var shown_morale := _fuzzy_stat(candidate.morale, margin)

	var culture_estimate := -1
	if people_skill >= CULTURE_READ_THRESHOLD:
		culture_estimate = _fuzzy_stat(candidate.culture_fit, maxi(3, margin - 2))

	_interview_reports[ckey] = {
		"interviewer_name": interviewer_name,
		"interviewer_role": role,
		"confidence": _confidence_label(accuracy),
		"skill": shown_skill,
		"speed": shown_speed,
		"morale": shown_morale,
		"culture_fit": culture_estimate,
		"growth_text": _estimate_growth_text(candidate.growth_potential, accuracy),
		"feedback": _feedback_text(role, shown_skill, shown_speed, shown_morale, culture_estimate),
	}

	GameState.append_event_log({
		"quarter": GameState.current_quarter,
		"year": GameState.current_year,
		"event_id": "deep_interview",
		"title": "Interviewed %s with %s" % [candidate.employee_name, interviewer_name],
	})
	Analytics.track_interview()
	_update_hire_button()
	_refresh_candidates()
	_refresh_list()

	var note := "Interview complete."
	if lock_quarters > 0 and not employee_uid.is_empty():
		note += " %s is tied up for %d quarter%s." % [interviewer_name, lock_quarters, "s" if lock_quarters > 1 else ""]
	_show_temp_message(note)


func _on_hire_candidate(candidate: EmployeeData) -> void:
	var ckey := _candidate_key(candidate)
	if GameState.hire_employee(candidate):
		SfxPlayer.play("hire")
		Analytics.track_hire(
			EmployeeData.SPECIALTY_NAMES.get(candidate.specialty, "unknown"),
			EmployeeData.SENIORITY_NAMES.get(candidate.seniority, "unknown"),
		)
		_interview_reports.erase(ckey)
		_negotiated.erase(ckey)
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
	strip_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_strip.add_child(strip_hbox)

	var company_lbl := Label.new()
	company_lbl.text = GameState.company.company_name if GameState.company else "Venture"
	company_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	company_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	strip_hbox.add_child(company_lbl)

	var strip_spacer := Control.new()
	strip_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip_hbox.add_child(strip_spacer)

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
	new_hire_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
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
	title_lbl.text = "%s · %s" % [emp.display_title(), emp.employment_label()]
	title_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	title_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title_lbl)

	var trait_lbl := Label.new()
	trait_lbl.text = "%s — %s" % [emp.personality_label(), emp.personality_effect_hint()]
	trait_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	trait_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT_HINT)
	trait_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trait_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(trait_lbl)

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

	# --- Celebration animation (Disney-style: anticipation → pop → follow-through) ---
	# Screen flash on hire — impact moment.
	AnimHelper.screen_flash(self, Color(0.35, 0.65, 1.0, 0.25), 0.35)
	AnimHelper.haptic(&"medium")
	SfxPlayer.play("hire")

	# Card pop-in with spring overshoot (starts tiny, overshoots 1.08, settles 1.0).
	card.scale = Vector2(0.0, 0.0)
	card.pivot_offset = Vector2(160, 240)
	card.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(card, "scale", Vector2(1.0, 1.0), 0.36) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(card, "modulate:a", 1.0, 0.18) \
		.set_ease(Tween.EASE_OUT)

	# Confetti burst behind the badge card — celebration!
	tw.set_parallel(false)
	tw.tween_callback(func() -> void:
		if is_instance_valid(overlay):
			AnimHelper.confetti_burst(overlay, Vector2(size.x * 0.5, size.y * 0.4),
				[Color(0.35, 0.65, 1.0), Color(0.30, 0.85, 0.45), Color(1.0, 0.84, 0.0),
				 Color(0.80, 0.45, 0.95), Color(1.0, 0.55, 0.25)], 30, 200.0, 1.8)
	)

	# Avatar pop-in with slight delay for staggered feel.
	av_panel.scale = Vector2(0.0, 0.0)
	av_panel.pivot_offset = av_panel.size * 0.5
	get_tree().create_timer(0.20).timeout.connect(func() -> void:
		if is_instance_valid(av_panel):
			AnimHelper.pop_in(av_panel, 0.0, 0.28)
	)

	# Name typewriter reveal for dramatic flair.
	get_tree().create_timer(0.30).timeout.connect(func() -> void:
		if is_instance_valid(name_lbl):
			AnimHelper.typewriter(name_lbl, name_lbl.text, 30.0)
	)


static func _badge_stat(parent: HBoxContainer, label: String, value: int) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	parent.add_child(col)

	var val_lbl := Label.new()
	val_lbl.text = str(value)
	val_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_LG)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if value >= 70:
		val_lbl.add_theme_color_override("font_color", ThemeManager.C_GREEN)
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
	title.add_theme_font_size_override("font_size", ThemeManager.FONT_LG)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header_row.add_child(title)

	var stage: String = _responsibility_stage()
	var stage_hint := Label.new()
	if stage == RESPONSIBILITY_STAGE_EARLY:
		stage_hint.text = "Early startup mode: people wear multiple hats, and Features should stay the main lane."
	elif stage == RESPONSIBILITY_STAGE_GROWTH:
		stage_hint.text = "Growth mode: start dedicated coverage for Bugs, Tech Debt, Infra, and R&D."
	else:
		stage_hint.text = "Scale mode: specialization is required to avoid hidden drag and churn."
	stage_hint.add_theme_font_size_override("font_size", 12)
	stage_hint.add_theme_color_override("font_color", Color(0.58, 0.76, 0.92))
	stage_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(stage_hint)

	for a_key in ASSIGNMENT_DESCRIPTIONS:
		var btn := Button.new()
		btn.text = "%s\n%s" % [EmployeeData.ASSIGNMENT_NAMES[a_key], _assignment_description_for_stage(a_key, stage)]
		btn.custom_minimum_size = Vector2(0, 50)
		btn.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
		var prompt_icon := _assign_icon_texture(a_key)
		if prompt_icon:
			btn.icon = prompt_icon
			btn.add_theme_constant_override("icon_max_width", 24)
		btn.pressed.connect(_on_assign_from_prompt.bind(emp, a_key, overlay))
		vbox.add_child(btn)
	UITouchHelper.harden_tree(overlay)


func _on_assign_from_prompt(emp: EmployeeData, assignment: EmployeeData.Assignment, overlay: Control) -> void:
	emp.assignment = assignment
	overlay.queue_free()
	_assign_target = null
	_refresh_list()


func _on_pass_candidate(candidate: EmployeeData) -> void:
	var ckey := _candidate_key(candidate)
	_interview_reports.erase(ckey)
	_negotiated.erase(ckey)
	_candidates.erase(candidate)
	if _candidates.is_empty():
		AnimHelper.pop_out(candidate_panel, 0.14, func() -> void:
			candidate_panel.visible = false
		)
	else:
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
