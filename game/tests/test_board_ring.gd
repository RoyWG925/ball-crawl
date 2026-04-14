extends GutTest

var board: BoardRing

func before_each() -> void:
    board = BoardRing.new()
    board.setup(24)

func after_each() -> void:
    board.free()

func test_board_has_correct_tile_count() -> void:
    assert_eq(board.tile_count(), 24)

func test_player_starts_at_zero() -> void:
    assert_eq(board.player_position, 0)

func test_move_forward_updates_position() -> void:
    board.move(3)
    assert_eq(board.player_position, 3)

func test_move_wraps_around_board() -> void:
    board.player_position = 22
    board.move(4)
    assert_eq(board.player_position, 2)  # (22+4) % 24 = 2

func test_move_returns_tiles_visited() -> void:
    board.player_position = 0
    var visited: Array[int] = board.move(3)
    assert_eq(visited, [1, 2, 3])

func test_split_move_returns_two_stop_positions() -> void:
    board.player_position = 0
    var stops: Array[int] = board.split_move(3, 4)
    assert_eq(stops[0], 3)
    assert_eq(stops[1], 7)

func test_completed_lap_detected_when_passing_zero() -> void:
    board.player_position = 22
    board.move(3)
    assert_true(board.completed_lap)

func test_completed_lap_false_when_not_crossing_zero() -> void:
    board.player_position = 0
    board.move(5)
    assert_false(board.completed_lap)
