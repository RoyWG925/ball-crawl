class_name TurnManager
extends RefCounted

enum State {
    ROLL,
    MOVE_DECISION,
    MOVING,
    SHOOT_PHASE,
    RESOLVE
}

var state: State = State.ROLL
var current_roll: Array[int] = []
var move_steps: Array[int] = []

signal state_changed(new_state: State)

func on_roll_done(roll: Array[int]) -> void:
    assert(state == State.ROLL)
    current_roll = roll
    _set_state(State.MOVE_DECISION)

func choose_combined() -> void:
    assert(state == State.MOVE_DECISION)
    move_steps = [Dice.combined(current_roll)]
    _set_state(State.MOVING)

func choose_split() -> void:
    assert(state == State.MOVE_DECISION)
    move_steps = Dice.split(current_roll)
    _set_state(State.MOVING)

func on_move_done() -> void:
    assert(state == State.MOVING)
    _set_state(State.SHOOT_PHASE)

func on_shoot_done() -> void:
    assert(state == State.SHOOT_PHASE)
    _set_state(State.RESOLVE)

func on_resolve_done() -> void:
    assert(state == State.RESOLVE)
    _set_state(State.ROLL)

func _set_state(new_state: State) -> void:
    state = new_state
    state_changed.emit(new_state)
