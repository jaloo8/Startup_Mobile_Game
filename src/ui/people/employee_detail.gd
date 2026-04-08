extends Control
## Employee deep profile: role, current status, and quarter-by-quarter trajectory.

@onready var back_btn: Button = %BackButton
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var profile_label: Label = %ProfileLabel
@onready var tenure_label: Label = %TenureLabel
@onready var assignment_label: Label = %AssignmentLabel
@onready var trend_meta: Label = %TrendMeta
@onready var trend_chart: Control = %TrendChart
@onready var history_list: VBoxContainer = %HistoryList

var _employee: EmployeeData = null


func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	_load_employee()
	UITouchHelper.harden_tree(self)
	Analytics.track_screen("employee_detail")
	AnimHelper.pop_in(title_label, 0.0, 0.22)
	AnimHelper.stagger_list(history_list, 0.04, 0.08, 16.0)


func _load_employee() -> void:
	var uid := str(GameState.get_meta("employee_detail_uid", "")).strip_edges()
	if uid.is_empty():
		_show_missing_state("No employee selected.")
		return

	_employee = GameState.get_employee_by_uid(uid)
	if _employee == null:
		_show_missing_state("That employee is no longer on your team.")
		return

	_refresh_profile()


func _show_missing_state(msg: String) -> void:
	title_label.text = "Employee Detail"
	subtitle_label.text = msg
	profile_label.text = ""
	tenure_label.text = ""
	assignment_label.text = ""
	trend_meta.text = "No history available"
	if trend_chart and trend_chart.has_method("clear"):
		trend_chart.clear()
	SceneLoader.free_children(history_list)


func _refresh_profile() -> void:
	if _employee == null:
		return

	title_label.text = _employee.employee_name
	subtitle_label.text = _employee.display_title()

	var profile_parts: Array = [_employee.employment_label(), _employee.personality_label()]
	if _employee.age > 0:
		profile_parts.append("Age %d" % _employee.age)
	profile_label.text = " · ".join(profile_parts)

	var tenure_parts: Array = ["Tenure: %d quarter%s" % [_employee.tenure_quarters, "s" if _employee.tenure_quarters != 1 else ""]]
	if not _employee.bio.is_empty():
		tenure_parts.append(_employee.bio)
	tenure_label.text = "\n".join(tenure_parts)

	assignment_label.text = "Current focus: %s · %s" % [
		EmployeeData.ASSIGNMENT_NAMES.get(_employee.assignment, "Unknown"),
		_employee.personality_effect_hint(),
	]

	_refresh_history_chart()
	_refresh_history_rows()


func _refresh_history_chart() -> void:
	if trend_chart == null:
		return

	var hist: Array[Dictionary] = _employee.recent_history(12)
	if hist.is_empty():
		hist = [{
			"year": GameState.current_year,
			"quarter": GameState.current_quarter,
			"skill": _employee.skill,
			"morale": _employee.morale,
			"stress": _employee.stress,
		}]

	var skill_series: Array[float] = []
	var morale_series: Array[float] = []
	var stress_series: Array[float] = []
	for point in hist:
		skill_series.append(float(point.get("skill", _employee.skill)))
		morale_series.append(float(point.get("morale", _employee.morale)))
		stress_series.append(float(point.get("stress", _employee.stress)))

	if trend_chart.has_method("set_series"):
		trend_chart.set_series(skill_series, morale_series, stress_series)
	trend_meta.text = "Last %d quarter%s (Skill / Morale / Stress)" % [hist.size(), "s" if hist.size() != 1 else ""]


func _refresh_history_rows() -> void:
	SceneLoader.free_children(history_list)
	var hist: Array[Dictionary] = _employee.recent_history(16)
	if hist.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No quarter history yet. Advance a quarter to see trajectory."
		empty_lbl.add_theme_color_override("font_color", Color(0.55, 0.57, 0.64))
		history_list.add_child(empty_lbl)
		return

	for point in hist:
		var row := Label.new()
		row.add_theme_font_size_override("font_size", 12)
		row.add_theme_color_override("font_color", Color(0.74, 0.77, 0.84))
		row.text = "Y%d Q%d · %s · Skill %d · Morale %d · Stress %d" % [
			int(point.get("year", 1)),
			int(point.get("quarter", 1)),
			EmployeeData.ASSIGNMENT_NAMES.get(int(point.get("assignment", EmployeeData.Assignment.UNASSIGNED)), "Unassigned"),
			int(point.get("skill", 0)),
			int(point.get("morale", 0)),
			int(point.get("stress", 0)),
		]
		history_list.add_child(row)


func _on_back() -> void:
	SceneLoader.goto_scene("res://src/ui/people/employee_list.tscn")
