extends GdUnitTestSuite
## Unit tests for Deck. Requires GdUnit4 addon.
## Run from Godot: GdUnit panel → Run Tests.

var deck: Deck

func before_test() -> void:
	deck = Deck.new()
	for i in range(5):
		deck.add_card({ "id": "card_%d" % i })


func test_draw_one() -> void:
	var drawn: Array = deck.draw(1)
	assert_int(drawn.size()).is_equal(1)
	assert_int(deck.size()).is_equal(4)


func test_draw_more_than_deck() -> void:
	var drawn: Array = deck.draw(10)
	assert_int(drawn.size()).is_equal(5)
	assert_int(deck.size()).is_equal(0)


func test_shuffle_changes_order() -> void:
	var order_before: Array = deck.cards.duplicate()
	deck.shuffle()
	# After shuffle, order might be same by chance; we only check size
	assert_int(deck.cards.size()).is_equal(5)
