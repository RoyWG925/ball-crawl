extends Node2D

const BALLS_PER_TURN := 2
const MONSTERS_PER_WAVE := 3

var turn_manager := TurnManager.new()
var balls_shot_this_turn := 0

@onready var ball_field: BallField = $BallField
@onready var board_ring: BoardRingNode = $BoardRing
@onready var dice_label: Label = $UI/DiceLabel
@onready var status_label: Label = $UI/StatusLabel
@onready var roll_button: Button = $UI/RollButton
@onready var combined_button: Button = $UI/CombinedButton
@onready var split_button: Button = $UI/SplitButton

func _ready() -> void:
    ball_field.monster_scene = preload("res://scenes/monster.tscn")
    ball_field.ball_scene = preload("res://scenes/ball.tscn")
    turn_manager.state_changed.connect(_on_state_changed)
    roll_button.pressed.connect(_on_roll_pressed)
    combined_button.pressed.connect(_on_combined_pressed)
    split_button.pressed.connect(_on_split_pressed)
    board_ring.tile_landed.connect(_on_tile_landed)
    board_ring.lap_completed.connect(_on_lap_completed)
    _on_state_changed(TurnManager.State.ROLL)

func _on_state_changed(new_state: TurnManager.State) -> void:
    roll_button.visible = false
    combined_button.visible = false
    split_button.visible = false

    match new_state:
        TurnManager.State.ROLL:
            roll_button.visible = true
            status_label.text = "Roll the dice!"

        TurnManager.State.MOVE_DECISION:
            var r := turn_manager.current_roll
            dice_label.text = "%d  +  %d" % [r[0], r[1]]
            combined_button.text = "Combined  →  %d steps" % Dice.combined(r)
            split_button.text = "Split  →  %d then %d" % [r[0], r[1]]
            combined_button.visible = true
            split_button.visible = true
            status_label.text = "Choose how to move"

        TurnManager.State.MOVING:
            status_label.text = "Moving..."
            _execute_movement()

        TurnManager.State.SHOOT_PHASE:
            balls_shot_this_turn = 0
            ball_field.spawn_monsters(MONSTERS_PER_WAVE)
            status_label.text = "Monsters spawned! Shoot!"
            _next_shot()

        TurnManager.State.RESOLVE:
            if ball_field.is_overflowed():
                status_label.text = "GAME OVER — too many monsters!"
                dice_label.text = ""
                return
            status_label.text = "Resolving..."
            await get_tree().create_timer(0.5).timeout
            turn_manager.on_resolve_done()

func _on_roll_pressed() -> void:
    var roll := Dice.roll()
    turn_manager.on_roll_done(roll)

func _on_combined_pressed() -> void:
    turn_manager.choose_combined()

func _on_split_pressed() -> void:
    turn_manager.choose_split()

func _execute_movement() -> void:
    var steps := turn_manager.move_steps
    if steps.size() == 1:
        board_ring.move_player(steps[0])
    else:
        board_ring.split_move_player(steps[0], steps[1])
    turn_manager.on_move_done()

func _next_shot() -> void:
    if balls_shot_this_turn >= BALLS_PER_TURN:
        turn_manager.on_shoot_done()
        return
    status_label.text = "Ball %d/%d — drag to aim, release to fire" % [balls_shot_this_turn + 1, BALLS_PER_TURN]
    var b := ball_field.spawn_ball_at_launcher()
    b.settled.connect(_on_ball_settled)

func _on_ball_settled() -> void:
    balls_shot_this_turn += 1
    _next_shot()

func _on_tile_landed(tile: Tile) -> void:
    match tile.type:
        Tile.Type.START:
            status_label.text = "START — passing bonus!"
        Tile.Type.SURGE:
            status_label.text = "SURGE — [effect TODO]"
        Tile.Type.EVENT:
            status_label.text = "EVENT — [effect TODO]"
        _:
            pass

func _on_lap_completed() -> void:
    status_label.text = "Lap complete!"
