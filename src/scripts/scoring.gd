extends RefCounted
class_name Scoring
## Static scoring logic. Input: lineups + modifiers; output: final score.
## Unit test this heavily (tests/test_scoring.gd).


static func compute_score(offense_lineup: Array, defense_lineup: Array) -> int:
	var off: int = _sum_stats(offense_lineup, "offense")
	var def: int = _sum_stats(defense_lineup, "defense")
	# Placeholder: simple sum. Replace with real formula (e.g. off * def, multipliers).
	return off + def


static func _sum_stats(lineup: Array, stat_key: String) -> int:
	var total: int = 0
	for item in lineup:
		if item is Dictionary and item.has(stat_key):
			total += int(item[stat_key])
		elif item.get("stats") is Dictionary:
			total += int(item.stats.get(stat_key, 0))
	return total
