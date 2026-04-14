extends GutTest

var tm: TurnManager

func before_each() -> void:
    tm = TurnManager.new()

func after_each() -> void:
    tm.free()

func test_starts_in_roll_state() -> void:
    assert_eq(tm.state, TurnManager.State.ROLL)

func test_on_roll_done_enters_move_decision() -> void:
    tm.on_roll_done([3, 4])
    assert_eq(tm.state, TurnManager.State.MOVE_DECISION)

func test_on_roll_done_stores_dice_values() -> void:
    tm.on_roll_done([2, 5])
    assert_eq(tm.current_roll[0], 2)
    assert_eq(tm.current_roll[1], 5)

func test_choose_combined_sets_single_move_step() -> void:
    tm.on_roll_done([3, 4])
    tm.choose_combined()
    assert_eq(tm.state, TurnManager.State.MOVING)
    assert_eq(tm.move_steps, [7])

func test_choose_split_sets_two_move_steps() -> void:
    tm.on_roll_done([3, 4])
    tm.choose_split()
    assert_eq(tm.state, TurnManager.State.MOVING)
    assert_eq(tm.move_steps, [3, 4])

func test_on_move_done_enters_shoot_phase() -> void:
    tm.on_roll_done([3, 4])
    tm.choose_combined()
    tm.on_move_done()
    assert_eq(tm.state, TurnManager.State.SHOOT_PHASE)

func test_on_shoot_done_enters_resolve() -> void:
    tm.on_roll_done([3, 4])
    tm.choose_combined()
    tm.on_move_done()
    tm.on_shoot_done()
    assert_eq(tm.state, TurnManager.State.RESOLVE)

func test_on_resolve_done_returns_to_roll() -> void:
    tm.on_roll_done([3, 4])
    tm.choose_combined()
    tm.on_move_done()
    tm.on_shoot_done()
    tm.on_resolve_done()
    assert_eq(tm.state, TurnManager.State.ROLL)
