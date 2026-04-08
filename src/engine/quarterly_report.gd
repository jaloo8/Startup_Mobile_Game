class_name QuarterlyReport
extends RefCounted
## Builds a short narrative summary for the quarter.
##
## Lines rotate phrasing each quarter to avoid repetition during long runs.
## The quarter number seeds a simple index so the same quarter always shows
## the same variant (deterministic but varied).


static func generate(state: Node) -> Array[String]:
	var bullets: Array[String] = []
	var history: Array[Dictionary] = state.history

	bullets.append(_revenue_line(state, history))
	bullets.append(_cash_line(state))
	bullets.append(_team_line(state, history))
	bullets.append(_product_line(state))
	bullets.append(_user_line(state, history))
	bullets.append(_economy_line(state))
	var world_line := _world_event_line(state)
	if not world_line.is_empty():
		bullets.append(world_line)
	bullets.append(_hosting_line(state))

	var energy_line := _energy_line(state)
	if not energy_line.is_empty():
		bullets.append(energy_line)

	var board_line := _board_line(state)
	if not board_line.is_empty():
		bullets.append(board_line)

	var synergy_line := _synergy_line(state)
	if not synergy_line.is_empty():
		bullets.append(synergy_line)

	return bullets


static func _revenue_line(state: Node, history: Array[Dictionary]) -> String:
	var rev: float = state.financials.revenue
	if history.size() >= 2:
		var prev_rev: float = history[-2].get("revenue", 0.0)
		if prev_rev > 0 and rev > 0:
			var pct: float = ((rev - prev_rev) / prev_rev) * 100.0
			if pct > 5:
				return _pick([
					"Revenue up %.0f%% to $%s this quarter" % [pct, SceneLoader.format_money(rev)],
					"$%s revenue — that's %.0f%% growth over last quarter" % [SceneLoader.format_money(rev), pct],
				] as Array[String], state)
			elif pct < -5:
				return _pick([
					"Revenue down %.0f%% to $%s — need more users or better pricing" % [absf(pct), SceneLoader.format_money(rev)],
					"$%s revenue, off %.0f%% from last quarter. Watch that trend" % [SceneLoader.format_money(rev), absf(pct)],
				] as Array[String], state)
			else:
				return _pick([
					"Revenue flat at $%s" % SceneLoader.format_money(rev),
					"$%s revenue — holding steady but not growing" % SceneLoader.format_money(rev),
				] as Array[String], state)
		elif rev > 0 and prev_rev <= 0:
			return "First revenue! $%s this quarter" % SceneLoader.format_money(rev)
	if rev > 0:
		return "Earning $%s per quarter" % SceneLoader.format_money(rev)
	return "No revenue yet — keep building"


static func _cash_line(state: Node) -> String:
	var cash: float = state.company.cash
	var rw: float = state.financials.runway_quarters(cash)

	if rw == INF:
		return _pick([
			"$%s in the bank — profitable and self-sustaining" % SceneLoader.format_money(cash),
			"Self-sustaining with $%s cash. Revenue covers all costs" % SceneLoader.format_money(cash),
		] as Array[String], state)
	elif cash <= 0.0:
		return "Cash is gone — bankruptcy hits if you can't raise or cut costs immediately"
	elif rw < 1.0:
		return "Cash critical at $%s — less than 1 quarter of runway. Raise now or shut down" % SceneLoader.format_money(cash)
	elif rw < 3.0:
		return "$%s in the bank. ~%d quarters of runway — clock is ticking" % [SceneLoader.format_money(cash), roundi(rw)]
	else:
		return _pick([
			"$%s in the bank. About %d quarters of runway" % [SceneLoader.format_money(cash), roundi(rw)],
			"$%s cash on hand — roughly %d quarters of runway at current burn" % [SceneLoader.format_money(cash), roundi(rw)],
		] as Array[String], state)


static func _team_line(state: Node, history: Array[Dictionary]) -> String:
	var current_size: int = state.employees.size()
	if history.size() >= 2:
		var prev_size: int = history[-2].get("employees", 0)
		var diff: int = current_size - prev_size
		if diff > 0:
			return _pick([
				"Hired %d new team member%s — now %d strong" % [diff, "s" if diff != 1 else "", current_size],
				"Team grew by %d — %d people on the roster now" % [diff, current_size],
			] as Array[String], state)
		elif diff < 0:
			return _pick([
				"Lost %d team member%s — down to %d" % [absi(diff), "s" if absi(diff) != 1 else "", current_size],
				"%d team member%s departed. Headcount is %d" % [absi(diff), "s" if absi(diff) != 1 else "", current_size],
			] as Array[String], state)
	if current_size == 0:
		return "Flying solo — visit People to hire your first employee"
	return _pick([
		"Team of %d holding steady" % current_size,
		"%d employees, no changes this quarter" % current_size,
		"Headcount stable at %d" % current_size,
	] as Array[String], state)


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
	elif features >= 5:
		parts.append("zero bugs — clean codebase")

	if td > 60:
		parts.append("tech debt is slowing everything down")
	elif td > 40:
		parts.append("tech debt building up")
	elif td <= 10 and features >= 5:
		parts.append("tech debt under control")

	var stage: String = _responsibility_stage(state)
	if stage != "early":
		var missing: Array[String] = []
		if _assignment_count(state, EmployeeData.Assignment.BUGS) == 0:
			missing.append("Bug Fixes")
		if _assignment_count(state, EmployeeData.Assignment.TECH_DEBT) == 0:
			missing.append("Tech Debt")
		if _assignment_count(state, EmployeeData.Assignment.INFRA) == 0:
			missing.append("Infrastructure")
		if _assignment_count(state, EmployeeData.Assignment.RND) == 0:
			missing.append("R&D")
		if not missing.is_empty():
			parts.append("specialization gap: no coverage in %s" % ", ".join(missing))
		else:
			parts.append(_pick([
				"roles are meshing well — balanced coverage is protecting quality and retention",
				"all specializations covered — your team is running like a real engineering org",
				"strong coverage across all roles. That discipline pays dividends",
			] as Array[String], state))

	return ". ".join(parts)


static func _assignment_count(state: Node, target: EmployeeData.Assignment) -> int:
	var count := 0
	for emp: EmployeeData in state.employees:
		if emp.assignment == target:
			count += 1
	return count


static func _responsibility_stage(state: Node) -> String:
	return SimulationEngine.responsibility_stage(state)


static func _user_line(state: Node, history: Array[Dictionary]) -> String:
	var users: int = state.product.users
	if history.size() >= 2:
		var prev_users: int = history[-2].get("users", 0)
		var diff: int = users - prev_users
		if diff > 0:
			return _pick([
				"%s new users this quarter — total %s" % [SceneLoader.format_number(diff), SceneLoader.format_number(users)],
				"User base grew by %s to %s total" % [SceneLoader.format_number(diff), SceneLoader.format_number(users)],
				"Added %s users. Now at %s and climbing" % [SceneLoader.format_number(diff), SceneLoader.format_number(users)],
			] as Array[String], state)
		elif diff < 0:
			return _pick([
				"Lost %s users this quarter — down to %s" % [SceneLoader.format_number(absi(diff)), SceneLoader.format_number(users)],
				"Churn hit hard: %s users gone, %s remaining" % [SceneLoader.format_number(absi(diff)), SceneLoader.format_number(users)],
			] as Array[String], state)
	if users > 0:
		return "%s users total" % SceneLoader.format_number(users)
	return "No users yet — ship features and they'll come"


static func _pick(variants: Array[String], state: Node) -> String:
	var idx: int = (state.current_quarter + state.current_year * 4) % variants.size()
	return variants[idx]


static func _economy_line(state: Node) -> String:
	match state.market.economy_state:
		MarketData.EconomyState.BULL:
			return _pick([
				"Markets are hot — investors and users are more open right now",
				"Bull market energy everywhere. Fundraising windows don't stay open forever",
				"VCs are writing checks fast — great time to raise if you need runway",
				"Optimism in the market is lifting growth rates across the board",
			] as Array[String], state)
		MarketData.EconomyState.BEAR:
			return _pick([
				"Markets are rough — growth is harder and VCs are cautious",
				"Bear market. Extend your runway and focus on unit economics",
				"Funding has dried up — survival mode until sentiment shifts",
				"Layoff headlines everywhere. Investors want profitability, not growth",
			] as Array[String], state)
		_:
			return _pick([
				"The market is steady — no strong tailwinds or headwinds",
				"Neutral macro conditions — your execution matters more than the market",
				"Economy is flat. Not great, not terrible — focus on what you can control",
				"Steady-state market. No free tailwinds, but no panic either",
			] as Array[String], state)


static func _world_event_line(state: Node) -> String:
	if int(state.active_world_event_quarters_left) <= 0:
		return ""
	var title := str(state.active_world_event_title).strip_edges()
	if title.is_empty():
		return ""
	var growth_mult := 1.0
	var cost_mult := 1.0
	var fundraise_mult := 1.0
	if state.has_method("world_event_mult"):
		growth_mult = float(state.world_event_mult("growth_mult", 1.0))
		cost_mult = float(state.world_event_mult("cost_mult", 1.0))
		fundraise_mult = float(state.world_event_mult("fundraise_amount_mult", 1.0))
	var tailwind := growth_mult > 1.03 and cost_mult <= 1.03 and fundraise_mult >= 1.0
	var headwind := growth_mult < 0.97 or cost_mult > 1.03 or fundraise_mult < 0.97
	var tone := "mixed impact"
	if tailwind:
		tone = "tailwind"
	elif headwind:
		tone = "headwind"
	return "World pulse: %s (%dQ left) — %s" % [title, int(state.active_world_event_quarters_left), tone]


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
	if reliability < 98.0 and reliability >= 96.0:
		return "Hosting at %.1f%% reliability — approaching incident risk. Upgrade capacity or add Infra staff soon" % reliability
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
		return _pick([
			"You're burning out — one more bad quarter and you might have to walk away",
			"Burnout is real. You can barely focus. Something has to change",
		] as Array[String], state)
	elif e < 40:
		return _pick([
			"The stress is mounting. You need a win soon",
			"Long hours are taking a toll. A good quarter would help",
		] as Array[String], state)
	return ""


static func _board_line(state: Node) -> String:
	var bp: int = state.board_patience
	if bp > 4 or state.financials.funding_rounds.is_empty():
		return ""
	if bp <= 1:
		return _pick([
			"Your board is furious — they're discussing replacing you as CEO",
			"Board meeting was brutal. You're one bad quarter from getting ousted",
		] as Array[String], state)
	if bp <= 2:
		return _pick([
			"Investors are losing patience — you need to show results",
			"Your lead investor called twice this week. That's not a good sign",
		] as Array[String], state)
	if bp <= 3:
		return _pick([
			"Your board expects better numbers next quarter",
			"Board wants to see momentum. Keep pushing",
		] as Array[String], state)
	return ""


static func _synergy_line(state: Node) -> String:
	# Show near-miss synergy hints in the quarterly report to nudge discovery.
	var near: Array[Dictionary] = SynergyEngine.get_near_misses(state)
	if near.is_empty():
		return ""
	var hint: Dictionary = near[0]
	var sname: String = hint.get("name", "")
	var missing: String = hint.get("missing_feature", "")
	if sname.is_empty() or missing.is_empty():
		return ""
	return "Your team is close to unlocking a synergy: ship %s to activate %s" % [missing, sname]


