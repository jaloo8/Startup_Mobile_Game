class_name CompetitorAI
extends RefCounted
## Simple AI that grows competitors each quarter on a schedule.

const BASE_USER_GROWTH_PER_QUARTER := 50


static func step(market: MarketData) -> void:
	for i in market.competitors.size():
		var comp: Dictionary = market.competitors[i]
		var growth_rate: float = comp.get("growth_rate", 0.05)
		var current_users: int = comp.get("users", 0)

		var organic := ceili(current_users * growth_rate)
		var base := randi_range(BASE_USER_GROWTH_PER_QUARTER / 2, BASE_USER_GROWTH_PER_QUARTER)
		comp["users"] = current_users + organic + base

		comp["product_quality"] = mini(100, comp.get("product_quality", 50) + randi_range(0, 3))

		if randf() < 0.1:
			comp["funding"] = comp.get("funding", 0) + randi_range(1_000_000, 10_000_000)

		market.competitors[i] = comp


static func generate_starting_competitors(count: int) -> Array[Dictionary]:
	var names := ["NovaTech", "Apex Systems", "ClearStack", "Foundry Labs", "Nimbus AI",
		"StackForge", "Bright Data", "LaunchPad", "Synapse Co", "Meridian"]
	var comps: Array[Dictionary] = []
	for i in mini(count, names.size()):
		comps.append({
			"name": names[i],
			"users": randi_range(100, 5_000),
			"funding": randi_range(50_000, 500_000),
			"product_quality": randi_range(30, 60),
			"growth_rate": randf_range(0.03, 0.08),
		})
	return comps
