class_name QuarterlyReport
extends RefCounted
## Builds a short narrative summary for the quarter.


static func generate(state: Node) -> Array[String]:
	var bullets: Array[String] = []
	var history: Array[Dictionary] = state.history

	bullets.append(_revenue_line(state, history))
	bullets.append(_cash_line(state))
	bullets.append(_team_line(state, history))
	bullets.append(_product_line(state))
	bullets.append(_user_line(state, history))
	bullets.append(_economy_line(state))
	bullets.append(_hosting_line(state))

	var energy_line := _energy_line(state)
	if not energy_line.is_empty():
		bullets.append(energy_line)

	var board_line := _board_line(state)
	if not board_line.is_empty():
		bullets.append(board_line)

	return bullets


static func _revenue_line(state: Node, history: Array[Dictionary]) -> String:
	var rev: float = state.financials.revenue
	if history.size() >= 2:
		var prev_rev: float = history[-2].get("revenue", 0.0)
		if prev_rev > 0 and rev > 0:
			var pct: float = ((rev - prev_rev) / prev_rev) * 100.0
			if pct > 5:
				return "Revenue up %.0f%% to $%s this quarter" % [pct, SceneLoader.format_money(rev)]
			elif pct < -5:
				return "Revenue down %.0f%% to $%s — need more users or better pricing" % [absf(pct), SceneLoader.format_money(rev)]
			else:
				return "Revenue flat at $%s" % SceneLoader.format_money(rev)
		elif rev > 0 and prev_rev <= 0:
			return "First revenue! $%s this quarter" % SceneLoader.format_money(rev)
	if rev > 0:
		return "Earning $%s per quarter" % SceneLoader.format_money(rev)
	return "No revenue yet — keep building"


static func _cash_line(state: Node) -> String:
	var cash: float = state.company.cash
	var burn: float = state.financials.burn_rate
	var rw: float = state.financials.runway_quarters(cash)

	if rw == INF:
		return "$%s in the bank — profitable and self-sustaining" % SceneLoader.format_money(cash)
	elif rw < 1.0:
		return "Cash critical — less than 1 quarter of runway left"
	elif rw < 3.0:
		return "$%s in the bank. ~%d quarters of runway. Time is running out" % [SceneLoader.format_money(cash), roundi(rw)]
	else:
		return "$%s in the bank. About %d quarters of runway" % [SceneLoader.format_money(cash), roundi(rw)]


static func _team_line(state: Node, history: Array[Dictionary]) -> String:
	var current_size: int = state.employees.size()
	if history.size() >= 2:
		var prev_size: int = history[-2].get("employees", 0)
		var diff: int = current_size - prev_size
		if diff > 0:
			return "Hired %d new team member%s — now %d strong" % [diff, "s" if diff != 1 else "", current_size]
		elif diff < 0:
			return "Lost %d team member%s — down to %d" % [absi(diff), "s" if absi(diff) != 1 else "", current_size]
	if current_size == 0:
		return "Flying solo — visit People to hire your first employee"
	return "Team of %d holding steady" % current_size


static func _product_line(state: Node) -> String:
	var features: int = state.product.feature_count()
	var bugs: int = state.product.bugs
	var td: int = state.product.tech_debt

	var parts: Array[String] = []
	if features > 0:
		parts.append("%d feature%s shipped" % [features, "s" if features != 1 else ""])
	else:
		parts.append("No features yet — assign engineers to Features")

	if bugs > 10:
		parts.append("%d bugs outstanding — users are noticing" % bugs)
	elif bugs > 0:
		parts.append("%d bug%s in the backlog" % [bugs, "s" if bugs != 1 else ""])

	if td > 60:
		parts.append("tech debt is slowing everything down")
	elif td > 40:
		parts.append("tech debt building up")

	return ". ".join(parts)


static func _user_line(state: Node, history: Array[Dictionary]) -> String:
	var users: int = state.product.users
	if history.size() >= 2:
		var prev_users: int = history[-2].get("users", 0)
		var diff: int = users - prev_users
		if diff > 0:
			return "%s new users this quarter — total %s" % [SceneLoader.format_number(diff), SceneLoader.format_number(users)]
		elif diff < 0:
			return "Lost %s users this quarter — down to %s" % [SceneLoader.format_number(absi(diff)), SceneLoader.format_number(users)]
	if users > 0:
		return "%s users total" % SceneLoader.format_number(users)
	return "No users yet — ship features and they'll come"


static func _economy_line(state: Node) -> String:
	match state.market.economy_state:
		MarketData.EconomyState.BULL:
			return "Markets are hot — investors and users are more open right now"
		MarketData.EconomyState.BEAR:
			return "Markets are rough — growth is harder and VCs are cautious"
		_:
			return "The market is steady — no strong tailwinds or headwinds"


static func _hosting_line(state: Node) -> String:
	var reliability: float = float(state.company.hosting_reliability)
	var overage_cost: float = float(state.company.hosting_overage_cost)
	var incidents: int = int(state.company.hosting_incidents_last_quarter)
	var total_upgrades: int = int(state.company.hosting_upgrade_web_level) \
		+ int(state.company.hosting_upgrade_cache_level) \
		+ int(state.company.hosting_upgrade_data_level)
	var optimization_level: int = int(state.company.hosting_optimization_level)
	var pressure: float = float(state.company.hosting_data_center_pressure)
	var workload_profile: String = str(state.company.hosting_workload_profile).strip_edges()
	if workload_profile.is_empty():
		workload_profile = "General Cloud"
	var plan_name := "Managed Cloud"
	if state.company.has_method("hosting_plan_name"):
		plan_name = str(state.company.call("hosting_plan_name"))

	if incidents > 0:
		return "Hosting had %d incident%s (%.1f%% reliability) — overage added $%s this quarter under %s workload" % [
			incidents,
			"s" if incidents != 1 else "",
			reliability,
			SceneLoader.format_money(overage_cost),
			workload_profile,
		]
	if reliability < 96.0:
		return "Hosting looked strained (%.1f%% reliability) under %s workload. Consider adding Infra staff or switching plan" % [reliability, workload_profile]
	if overage_cost >= 200.0:
		return "Hosting overage: $%s this quarter on %s (%s workload)" % [SceneLoader.format_money(overage_cost), plan_name, workload_profile]
	if pressure >= 2.2:
		return "Workload is now data-center-heavy (%s). Keep Data/Cache capacity ahead of growth" % workload_profile
	if total_upgrades > 0 or optimization_level > 0:
		return "Hosting stable at %.1f%% reliability on %s (%s, lane upgrades: %d, optimization L%d)" % [
			reliability,
			plan_name,
			workload_profile,
			total_upgrades,
			optimization_level,
		]
	return "Hosting stable at %.1f%% reliability on %s (%s)" % [reliability, plan_name, workload_profile]


static func _energy_line(state: Node) -> String:
	var e: int = state.founder_energy
	if e < 20:
		return "You're burning out — one more bad quarter and you might have to walk away"
	elif e < 40:
		return "The stress is mounting. You need a win soon"
	return ""


static func _board_line(state: Node) -> String:
	var bp: int = state.board_patience
	if bp > 4 or state.financials.funding_rounds.is_empty():
		return ""
	if bp <= 1:
		return "Your board is furious — they're discussing replacing you as CEO"
	if bp <= 2:
		return "Investors are losing patience — you need to show results"
	if bp <= 3:
		return "Your board expects better numbers next quarter"
	return ""


