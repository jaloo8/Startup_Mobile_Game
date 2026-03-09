class_name TemplateEngine
extends RefCounted
## Replaces {variable} placeholders in text with game state values.

static var _unresolved_regex: RegEx


static func apply(template: String, context: Dictionary) -> String:
	var result := template
	for key in context:
		var token := "{%s}" % key
		if token in result:
			result = result.replace(token, str(context[key]))
	return _strip_unresolved(result)


static func _strip_unresolved(text: String) -> String:
	if _unresolved_regex == null:
		_unresolved_regex = RegEx.new()
		_unresolved_regex.compile("\\{\\w+\\}")
	return _unresolved_regex.sub(text, "", true)


static func build_context(state: Node, extra: Dictionary = {}) -> Dictionary:
	var ctx := {
		"company_name": state.company.company_name,
		"company_type": state.company.type_name(),
		"cash": "$" + SceneLoader.format_money(state.company.cash),
		"burn_rate": "$" + SceneLoader.format_money(state.financials.burn_rate),
		"revenue": "$" + SceneLoader.format_money(state.financials.revenue),
		"runway": _fmt_runway(state.financials.runway_quarters(state.company.cash)),
		"user_count": SceneLoader.format_number(state.product.users),
		"quarter": state.current_quarter,
		"year": state.current_year,
		"employee_count": state.employees.size(),
		"tech_debt": state.product.tech_debt,
		"bugs": state.product.bugs,
		"stability": state.product.stability,
	}

	if not state.market.competitors.is_empty():
		var comp: Dictionary = state.market.competitors.pick_random()
		ctx["competitor_name"] = comp.get("name", "a competitor")

	if not state.employees.is_empty():
		var emp: EmployeeData = state.employees.pick_random()
		ctx["employee_name"] = emp.employee_name
		ctx["employee_role"] = emp.display_title()
		ctx["current_salary"] = "$" + SceneLoader.format_money(emp.salary_per_quarter * 4)
		ctx["salary_increase"] = str(randi_range(20, 45))

	ctx.merge(extra, true)
	return ctx


static func pick_variation(base_template: String, variations: Array) -> String:
	if variations.is_empty():
		return base_template
	var pool := [base_template]
	pool.append_array(variations)
	return pool.pick_random()


static func _fmt_runway(quarters: float) -> String:
	if quarters == INF:
		return "infinite"
	elif quarters < 0:
		return "negative"
	return "%.1f quarters" % quarters
