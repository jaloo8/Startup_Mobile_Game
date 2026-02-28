extends Node
## Runs the core loop: deck, hand, lineup, blinds, scoring.
## Single source of truth for run state. Call from game_board or autoload.

var deck: Deck
var hand: Array  # of CardData or card refs
var lineup_offense: Array
var lineup_defense: Array
var current_blind_index: int = 0
var score: int = 0

func _ready() -> void:
	deck = Deck.new()
	# TODO: init hand from deck, set first blind


func start_run() -> void:
	deck.shuffle()
	draw_hand()
	current_blind_index = 0
	score = 0


func draw_hand() -> void:
	hand.clear()
	# TODO: draw N cards from deck into hand


func play_card_to_lineup(card_index: int, slot: String) -> bool:
	# slot e.g. "offense" / "defense"
	# Returns true if play was valid.
	return false  # TODO


func resolve_blind() -> int:
	var total: int = Scoring.compute_score(lineup_offense, lineup_defense)
	score = total
	return total  # TODO: apply modifiers, compare to blind threshold


func advance_blind() -> void:
	current_blind_index += 1
	# TODO: next blind or run complete
