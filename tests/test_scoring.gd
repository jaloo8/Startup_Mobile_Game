extends GdUnitTestSuite
## Unit tests for Scoring. Requires GdUnit4 addon.
## Run from Godot: GdUnit panel → Run Tests.

func test_compute_score_empty_lineups() -> void:
	var score: int = Scoring.compute_score([], [])
	assert_int(score).is_equal(0)


func test_compute_score_single_player_offense() -> void:
	var offense := [{ "offense": 10, "defense": 5 }]
	var score: int = Scoring.compute_score(offense, [])
	assert_int(score).is_equal(10)


func test_compute_score_offense_and_defense_sum() -> void:
	var offense := [{ "offense": 10, "defense": 2 }]
	var defense := [{ "offense": 1, "defense": 8 }]
	var score: int = Scoring.compute_score(offense, defense)
	# Current formula: off sum + def sum -> 10 + 8 = 18
	assert_int(score).is_equal(18)
