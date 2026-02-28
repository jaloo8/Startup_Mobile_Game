class_name Deck
## Deck of player cards (and optionally Joker-type cards). Draw, shuffle, discard.

var cards: Array = []  # CardData or resource IDs
var discard_pile: Array = []


func shuffle() -> void:
	cards.shuffle()


func draw(count: int) -> Array:
	var drawn: Array = []
	for i in range(count):
		if cards.is_empty():
			# TODO: reshuffle discard into deck if needed
			break
		drawn.append(cards.pop_back())
	return drawn


func add_card(card: Variant) -> void:
	cards.append(card)


func discard(card: Variant) -> void:
	discard_pile.append(card)


func size() -> int:
	return cards.size()
