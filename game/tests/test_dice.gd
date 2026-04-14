extends GutTest

func test_roll_returns_two_values() -> void:
    var result: Array[int] = Dice.roll()
    assert_eq(result.size(), 2, "roll() should return exactly 2 values")

func test_roll_values_between_1_and_6() -> void:
    for i in range(200):
        var result: Array[int] = Dice.roll()
        assert_between(result[0], 1, 6, "die 1 should be 1-6")
        assert_between(result[1], 1, 6, "die 2 should be 1-6")

func test_combined_sums_both_dice() -> void:
    assert_eq(Dice.combined([3, 4]), 7)
    assert_eq(Dice.combined([1, 1]), 2)
    assert_eq(Dice.combined([6, 6]), 12)

func test_split_returns_both_values_in_order() -> void:
    var result: Array[int] = Dice.split([3, 4])
    assert_eq(result.size(), 2)
    assert_eq(result[0], 3)
    assert_eq(result[1], 4)
