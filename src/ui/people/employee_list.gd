extends Control
## Employee management screen — view team, hire, fire, assign work.

@onready var list_container: VBoxContainer = %EmployeeListContainer
@onready var hire_btn: Button = %HireButton
@onready var back_btn: Button = %BackButton
@onready var capacity_label: Label = %CapacityLabel
@onready var candidate_container: VBoxContainer = %CandidateContainer
@onready var candidate_panel: PanelContainer = %CandidatePanel

var _candidates: Array[EmployeeData] = []
var _interviewed: Dictionary = {}  # employee_name -> true
var _card_style: StyleBoxFlat


func _ready() -> void:
	_card_style = _make_card_style()
	hire_btn.pressed.connect(_on_hire_pressed)
	back_btn.pressed.connect(_on_back)
	candidate_panel.visible = false
	_refresh_list()


func _exit_tree() -> void:
	_candidates.clear()
	_interviewed.clear()
	_card_style = null


func _refresh_list() -> void:
	_free_children(list_container)

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

	for emp in GameState.employees:
		list_container.add_child(_create_employee_card(emp))


func _create_employee_card(emp: EmployeeData) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _card_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var name_label := Label.new()
	name_label.text = "%s — %s" % [emp.employee_name, emp.display_title()]
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 16)
	vbox.add_child(stats_row)
	_add_stat(stats_row, "Skill", emp.skill)
	_add_stat(stats_row, "Morale", emp.morale)
	_add_stat(stats_row, "Stress", emp.stress)

	var salary_label := Label.new()
	salary_label.text = "$%sK/yr • %s" % [
		str(snapped(emp.salary_per_quarter * 4 / 1000.0, 0.1)),
		EmployeeData.ASSIGNMENT_NAMES.get(emp.assignment, "Unassigned"),
	]
	salary_label.add_theme_font_size_override("font_size", 13)
	salary_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	vbox.add_child(salary_label)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	var assign_btn := OptionButton.new()
	assign_btn.custom_minimum_size = Vector2(140, 32)
	for a_key in EmployeeData.ASSIGNMENT_NAMES:
		assign_btn.add_item(EmployeeData.ASSIGNMENT_NAMES[a_key], a_key)
	assign_btn.selected = _find_assignment_index(assign_btn, emp.assignment)
	var emp_ref := emp
	assign_btn.item_selected.connect(_on_assign_changed.bind(emp_ref, assign_btn))
	btn_row.add_child(assign_btn)

	var fire_btn := Button.new()
	fire_btn.text = "Let Go"
	fire_btn.custom_minimum_size = Vector2(70, 32)
	fire_btn.pressed.connect(_on_fire.bind(emp_ref))
	btn_row.add_child(fire_btn)

	return panel


func _on_assign_changed(idx: int, emp: EmployeeData, btn: OptionButton) -> void:
	emp.assignment = btn.get_item_id(idx) as EmployeeData.Assignment


func _on_fire(emp: EmployeeData) -> void:
	GameState.fire_employee(emp)
	_refresh_list()


func _find_assignment_index(option_btn: OptionButton, assignment: EmployeeData.Assignment) -> int:
	for i in option_btn.item_count:
		if option_btn.get_item_id(i) == assignment:
			return i
	return option_btn.item_count - 1


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
		hire_btn.disabled = true
		hire_btn.text = "Office Full — Upgrade to Hire"
		return

	_candidates = HiringEngine.generate_candidates(3, GameState.market)
	_interviewed.clear()
	candidate_panel.visible = true
	_refresh_candidates()


func _refresh_candidates() -> void:
	_free_children(candidate_container)

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

		var name_lbl := Label.new()
		name_lbl.text = "%s — %s" % [candidate.employee_name, candidate.display_title()]
		name_lbl.add_theme_font_size_override("font_size", 15)
		vbox.add_child(name_lbl)

		var salary_lbl := Label.new()
		salary_lbl.text = "Asking $%sK/yr" % str(snapped(candidate.salary_per_quarter * 4 / 1000.0, 0.1))
		salary_lbl.add_theme_font_size_override("font_size", 13)
		salary_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		vbox.add_child(salary_lbl)

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

		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 8)
		vbox.add_child(btn_row)

		if not interviewed:
			var interview_btn := Button.new()
			interview_btn.text = "Interview"
			interview_btn.custom_minimum_size = Vector2(90, 32)
			interview_btn.pressed.connect(_on_interview.bind(candidate))
			btn_row.add_child(interview_btn)

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


func _on_interview(candidate: EmployeeData) -> void:
	_interviewed[candidate.employee_name] = true
	_refresh_candidates()


func _on_hire_candidate(candidate: EmployeeData) -> void:
	if GameState.hire_employee(candidate):
		_candidates.erase(candidate)
		candidate_panel.visible = not _candidates.is_empty()
		_refresh_candidates()
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


static func _free_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
