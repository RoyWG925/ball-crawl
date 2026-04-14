# Ball Crawl Prototype v1 — Core Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable prototype in Godot 4 that validates whether ball physics + walk→shoot loop feels good enough to build the full game on.

**Architecture:** Godot 4 project in `game/` subfolder of this repo. Central TurnManager state machine drives the loop. Ball field uses Godot's RigidBody2D physics. Board ring is a logical array of Tile objects rendered as colored rectangles around the field. Pure logic (dice, turns, board math) is tested with GUT; physics and visuals are manually verified.

**Tech Stack:** Godot 4.3+, GDScript, GUT (Godot Unit Test framework)

**Prototype scope:**
- ✅ Ball physics field, drag-to-aim, dotted trajectory, 1 ball type, balls stay on field
- ✅ Placeholder monsters (colored box, HP, die on contact)
- ✅ Board ring (24 tiles, player token, Surge/Event/Start types)
- ✅ Dice (2d6, split/combined choice)
- ✅ Turn state machine (ROLL → MOVE_DECISION → MOVING → SHOOT → RESOLVE)
- ✅ Monster overflow fail condition (>10 monsters = lose)
- ❌ NOT in this prototype: durability, boss, chips, economy, Surge tile logic, special balls, meta-progression, magazine track UI

---

## File Map

| File | Responsibility |
|---|---|
| `game/project.godot` | Godot 4 project config |
| `game/scripts/dice.gd` | Pure logic: roll 2d6, combined, split |
| `game/scripts/tile.gd` | Tile data class: type enum |
| `game/scripts/board_ring.gd` | Ring logic: tiles array, player position, move() |
| `game/scripts/turn_manager.gd` | State machine: ROLL→MOVE→SHOOT→RESOLVE |
| `game/scripts/monster.gd` | Monster: HP, take_damage(), die signal |
| `game/scripts/ball.gd` | Ball: RigidBody2D, drag-to-aim, trajectory, settle |
| `game/scripts/ball_field.gd` | Field: spawn monsters, manage balls, overflow check |
| `game/scripts/board_ring_node.gd` | Visual wrapper: draws ring + player token, emits signals |
| `game/scripts/main.gd` | Root: wires TurnManager ↔ UI ↔ BallField ↔ BoardRing |
| `game/scenes/monster.tscn` | Monster scene: colored box + HP label |
| `game/scenes/ball.tscn` | Ball scene: circle RigidBody2D |
| `game/scenes/ball_field.tscn` | Field scene: physics walls + dark background |
| `game/scenes/board_ring.tscn` | Ring scene: visual node, drawn procedurally |
| `game/scenes/main.tscn` | Root scene: field + ring + UI |
| `game/tests/test_dice.gd` | GUT tests: roll range, combined, split |
| `game/tests/test_board_ring.gd` | GUT tests: movement, wrapping, lap detection |
| `game/tests/test_turn_manager.gd` | GUT tests: state transitions |
| `game/tests/test_monster.gd` | GUT tests: damage, death |

---

## Task 1: Godot 4 Project Setup + GUT

**Files:**
- Create: `game/project.godot`
- Create: `game/.gitignore`
- Create: `game/addons/gut/` (GUT framework files)
- Create: `game/tests/test_runner.tscn`
- Create: `game/scenes/main.tscn`

- [ ] **Step 1: Create the Godot project file**

Create `game/project.godot`:

```ini
; Engine configuration file.
[gd_resource type="ProjectSettings" load_steps=1 format=3]

[application]

config/name="BallCrawl"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.3", "GL Compatibility")

[physics]

2d/default_gravity=0.0

[rendering]

renderer/rendering_method="gl_compatibility"
```

- [ ] **Step 2: Create folder structure**

```bash
mkdir -p game/scripts game/scenes game/tests game/addons
```

- [ ] **Step 3: Create .gitignore for Godot**

Create `game/.gitignore`:

```
.godot/
*.uid
export_presets.cfg
android/build/
```

- [ ] **Step 4: Install GUT**

Download GUT for Godot 4 from https://github.com/bitwes/Gut/releases — get the latest `gut_vX.X.X.zip`. Extract so that `plugin.cfg` lives at `game/addons/gut/plugin.cfg`.

Then add to `game/project.godot`:

```ini
[editor_plugins]

enabled=PackedStringArray("res://addons/gut/plugin.cfg")
```

- [ ] **Step 5: Create GUT test runner scene**

Create `game/tests/test_runner.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://addons/gut/gut_cmdln.gd" id="1"]

[node name="GUT" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 6: Create placeholder main scene**

Create `game/scenes/main.tscn`:

```
[gd_scene format=3]

[node name="Main" type="Node2D"]
```

- [ ] **Step 7: Verify Godot opens the project**

Open Godot 4, click "Import", select `game/project.godot`. Confirm no errors in the output panel.

- [ ] **Step 8: Commit**

```bash
cd game && git add project.godot .gitignore addons/ tests/test_runner.tscn scenes/main.tscn
git commit -m "feat: initialize Godot 4 project with GUT testing framework"
```

---

## Task 2: Dice System (TDD)

**Files:**
- Create: `game/scripts/dice.gd`
- Create: `game/tests/test_dice.gd`

- [ ] **Step 1: Write failing tests**

Create `game/tests/test_dice.gd`:

```gdscript
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
```

- [ ] **Step 2: Run tests — expect failure**

In Godot editor, run `tests/test_runner.tscn`. Expected: all 4 tests fail with "Dice is not defined".

- [ ] **Step 3: Implement dice.gd**

Create `game/scripts/dice.gd`:

```gdscript
class_name Dice
extends RefCounted

static func roll() -> Array[int]:
    return [randi_range(1, 6), randi_range(1, 6)]

static func combined(rolls: Array[int]) -> int:
    return rolls[0] + rolls[1]

static func split(rolls: Array[int]) -> Array[int]:
    return [rolls[0], rolls[1]]
```

- [ ] **Step 4: Run tests — expect pass**

Run `tests/test_runner.tscn`. Expected: all 4 tests pass (green).

- [ ] **Step 5: Commit**

```bash
git add scripts/dice.gd tests/test_dice.gd
git commit -m "feat: add dice system with TDD (roll, combined, split)"
```

---

## Task 3: Tile and Board Ring Logic (TDD)

**Files:**
- Create: `game/scripts/tile.gd`
- Create: `game/scripts/board_ring.gd`
- Create: `game/tests/test_board_ring.gd`

- [ ] **Step 1: Write failing tests**

Create `game/tests/test_board_ring.gd`:

```gdscript
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
```

- [ ] **Step 2: Run tests — expect failure**

Run GUT. Expected: all tests fail with "BoardRing is not defined".

- [ ] **Step 3: Implement tile.gd**

Create `game/scripts/tile.gd`:

```gdscript
class_name Tile
extends RefCounted

enum Type {
    NORMAL,
    SURGE,
    EVENT,
    START
}

var type: Type = Type.NORMAL
var index: int = 0

func _init(p_index: int, p_type: Type = Type.NORMAL) -> void:
    index = p_index
    type = p_type
```

- [ ] **Step 4: Implement board_ring.gd**

Create `game/scripts/board_ring.gd`:

```gdscript
class_name BoardRing
extends RefCounted

var player_position: int = 0
var completed_lap: bool = false
var _tiles: Array[Tile] = []

func setup(count: int) -> void:
    _tiles.clear()
    completed_lap = false
    player_position = 0
    for i in range(count):
        var type := Tile.Type.NORMAL
        if i == 0:
            type = Tile.Type.START
        elif i % 7 == 0:
            type = Tile.Type.EVENT
        elif i % 11 == 0:
            type = Tile.Type.SURGE
        _tiles.append(Tile.new(i, type))

func tile_count() -> int:
    return _tiles.size()

func get_tile(index: int) -> Tile:
    return _tiles[index % _tiles.size()]

func move(steps: int) -> Array[int]:
    completed_lap = false
    var visited: Array[int] = []
    for i in range(steps):
        player_position = (player_position + 1) % _tiles.size()
        if player_position == 0:
            completed_lap = true
        visited.append(player_position)
    return visited

func split_move(first: int, second: int) -> Array[int]:
    completed_lap = false
    move(first)
    var stop_one := player_position
    move(second)
    var stop_two := player_position
    return [stop_one, stop_two]
```

- [ ] **Step 5: Run tests — expect pass**

Run GUT. Expected: all 8 tests pass.

- [ ] **Step 6: Commit**

```bash
git add scripts/tile.gd scripts/board_ring.gd tests/test_board_ring.gd
git commit -m "feat: add tile types and board ring movement logic with TDD"
```

---

## Task 4: Turn State Machine (TDD)

**Files:**
- Create: `game/scripts/turn_manager.gd`
- Create: `game/tests/test_turn_manager.gd`

- [ ] **Step 1: Write failing tests**

Create `game/tests/test_turn_manager.gd`:

```gdscript
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
```

- [ ] **Step 2: Run tests — expect failure**

Run GUT. Expected: all 8 tests fail with "TurnManager is not defined".

- [ ] **Step 3: Implement turn_manager.gd**

Create `game/scripts/turn_manager.gd`:

```gdscript
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
```

- [ ] **Step 4: Run tests — expect pass**

Run GUT. Expected: all 8 tests pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/turn_manager.gd tests/test_turn_manager.gd
git commit -m "feat: add turn state machine ROLL→MOVE→SHOOT→RESOLVE with TDD"
```

---

## Task 5: Monster (TDD + Scene)

**Files:**
- Create: `game/scripts/monster.gd`
- Create: `game/scenes/monster.tscn`
- Create: `game/tests/test_monster.gd`

- [ ] **Step 1: Write failing tests**

Create `game/tests/test_monster.gd`:

```gdscript
extends GutTest

func test_monster_hp_initialized_to_max() -> void:
    var m := Monster.new()
    m.max_hp = 3
    m.hp = m.max_hp
    assert_eq(m.hp, 3)

func test_take_damage_reduces_hp() -> void:
    var m := Monster.new()
    m.max_hp = 3
    m.hp = 3
    m.take_damage(1)
    assert_eq(m.hp, 2)

func test_take_damage_clamps_at_zero() -> void:
    var m := Monster.new()
    m.max_hp = 3
    m.hp = 3
    m.take_damage(10)
    assert_eq(m.hp, 0)

func test_is_dead_returns_true_at_zero_hp() -> void:
    var m := Monster.new()
    m.max_hp = 3
    m.hp = 0
    assert_true(m.is_dead())

func test_is_dead_returns_false_above_zero() -> void:
    var m := Monster.new()
    m.max_hp = 3
    m.hp = 1
    assert_false(m.is_dead())
```

- [ ] **Step 2: Run tests — expect failure**

Run GUT. Expected: all 5 tests fail with "Monster is not defined".

- [ ] **Step 3: Implement monster.gd**

Create `game/scripts/monster.gd`:

```gdscript
class_name Monster
extends Area2D

@export var max_hp: int = 3
var hp: int = 0

signal died

@onready var hp_label: Label = $HPLabel

func _ready() -> void:
    hp = max_hp
    _update_label()

func take_damage(amount: int) -> void:
    hp = max(0, hp - amount)
    _update_label()
    if is_dead():
        died.emit()
        queue_free()

func is_dead() -> bool:
    return hp <= 0

func _update_label() -> void:
    if is_node_ready() and hp_label != null:
        hp_label.text = str(hp)
```

- [ ] **Step 4: Run tests — expect pass**

Run GUT. Expected: all 5 tests pass. (`_ready()` and `hp_label` don't run outside a scene tree — tested methods are pure logic.)

- [ ] **Step 5: Create monster.tscn in editor**

In Godot editor, create new scene `scenes/monster.tscn`:

1. Root node: `Area2D` named `Monster`, script: `scripts/monster.gd`
2. Child: `CollisionShape2D` with `RectangleShape2D` size `(40, 40)`
3. Child: `ColorRect` position `(-20, -20)` size `(40, 40)` color `#e74c3c`
4. Child: `Label` named `HPLabel`, position `(-5, -8)`, text `"3"`, font size 14, modulate white

Connect signal `body_entered` → not needed here; ball collides with monster via `BallField`. Save scene.

- [ ] **Step 6: Commit**

```bash
git add scripts/monster.gd scenes/monster.tscn tests/test_monster.gd
git commit -m "feat: add monster with HP, damage, and death signal (TDD)"
```

---

## Task 6: Ball Field Scene

**Files:**
- Create: `game/scripts/ball_field.gd`
- Create: `game/scenes/ball_field.tscn`

- [ ] **Step 1: Create ball_field.gd**

Create `game/scripts/ball_field.gd`:

```gdscript
class_name BallField
extends Node2D

const FIELD_WIDTH := 600.0
const FIELD_HEIGHT := 500.0
const MAX_MONSTERS := 10
const SPAWN_POSITIONS: Array[Vector2] = [
    Vector2(100, 100), Vector2(300, 80),  Vector2(500, 100),
    Vector2(150, 220), Vector2(450, 220), Vector2(300, 180),
]

var monsters: Array[Monster] = []
var balls: Array[Ball] = []

signal all_monsters_dead
signal ball_settled(ball: Ball)

@export var monster_scene: PackedScene
@export var ball_scene: PackedScene

func spawn_monsters(count: int) -> void:
    var to_spawn := min(count, SPAWN_POSITIONS.size())
    for i in range(to_spawn):
        var m: Monster = monster_scene.instantiate()
        m.position = SPAWN_POSITIONS[i]
        m.died.connect(_on_monster_died.bind(m))
        add_child(m)
        monsters.append(m)

func monster_count() -> int:
    return monsters.size()

func is_overflowed() -> bool:
    return monsters.size() >= MAX_MONSTERS

func spawn_ball_at_launcher() -> Ball:
    var b: Ball = ball_scene.instantiate()
    b.position = Vector2(FIELD_WIDTH / 2.0, FIELD_HEIGHT - 50.0)
    b.settled.connect(_on_ball_settled.bind(b))
    add_child(b)
    balls.append(b)
    return b

func _on_monster_died(m: Monster) -> void:
    monsters.erase(m)
    if monsters.is_empty():
        all_monsters_dead.emit()

func _on_ball_settled(b: Ball) -> void:
    ball_settled.emit(b)
```

- [ ] **Step 2: Create ball_field.tscn in editor**

In Godot editor, create `scenes/ball_field.tscn`:

1. Root: `Node2D` named `BallField`, script: `scripts/ball_field.gd`
2. Child: `ColorRect` named `Background`, position `(0,0)`, size `(600, 500)`, color `#0d1117`
3. Four wall `StaticBody2D` nodes, each with `CollisionShape2D` (SegmentShape2D) and a thin `ColorRect` border:
   - `WallTop`: segment from `(0,0)` to `(600,0)`, ColorRect height 4, color `#1f2937`
   - `WallBottom`: segment from `(0,500)` to `(600,500)`, ColorRect height 4
   - `WallLeft`: segment from `(0,0)` to `(0,500)`, ColorRect width 4
   - `WallRight`: segment from `(600,0)` to `(600,500)`, ColorRect width 4
4. Set exports: `monster_scene = res://scenes/monster.tscn`, `ball_scene = res://scenes/ball.tscn` (set after Task 7)

- [ ] **Step 3: Manual test — confirm scene loads**

Add `BallField` to a temporary test scene, run it. Verify: dark rectangle appears with visible border. No errors in console.

- [ ] **Step 4: Commit**

```bash
git add scripts/ball_field.gd scenes/ball_field.tscn
git commit -m "feat: add ball field with physics walls and monster/ball management"
```

---

## Task 7: Ball Physics + Drag-to-Aim

**Files:**
- Create: `game/scripts/ball.gd`
- Create: `game/scenes/ball.tscn`

- [ ] **Step 1: Create ball.gd**

Create `game/scripts/ball.gd`:

```gdscript
class_name Ball
extends RigidBody2D

const LAUNCH_FORCE := 800.0
const SETTLE_THRESHOLD := 20.0
const SETTLE_DELAY := 0.6
const DAMAGE := 1

var is_launched: bool = false
var is_settled: bool = false
var _settle_timer: float = 0.0
var _drag_start: Vector2 = Vector2.ZERO
var _is_dragging: bool = false

signal settled
signal hit_monster(monster: Monster)

@onready var trajectory: Line2D = $Trajectory

func _ready() -> void:
    freeze = true
    contact_monitor = true
    max_contacts_reported = 8

func _input(event: InputEvent) -> void:
    if is_launched or is_settled:
        return
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_LEFT:
            if mb.pressed:
                _drag_start = get_global_mouse_position()
                _is_dragging = true
            elif _is_dragging:
                _launch()
                _is_dragging = false
    elif event is InputEventMouseMotion and _is_dragging:
        _draw_trajectory()

func _physics_process(delta: float) -> void:
    if not is_launched or is_settled:
        return
    if linear_velocity.length() < SETTLE_THRESHOLD:
        _settle_timer += delta
        if _settle_timer >= SETTLE_DELAY:
            _do_settle()
    else:
        _settle_timer = 0.0

func _launch() -> void:
    var mouse_pos := get_global_mouse_position()
    var dir := (_drag_start - mouse_pos).normalized()
    if dir.length() < 0.1:
        return
    trajectory.clear_points()
    freeze = false
    is_launched = true
    linear_velocity = dir * LAUNCH_FORCE

func _draw_trajectory() -> void:
    var mouse_pos := get_global_mouse_position()
    var dir := (_drag_start - mouse_pos).normalized()
    trajectory.clear_points()
    var p := global_position
    var v := dir * LAUNCH_FORCE
    for i in range(25):
        trajectory.add_point(to_local(p))
        p += v * 0.016

func _do_settle() -> void:
    is_settled = true
    freeze = true
    linear_velocity = Vector2.ZERO
    trajectory.clear_points()
    settled.emit()

func _on_body_entered(body: Node) -> void:
    if body is Monster:
        (body as Monster).take_damage(DAMAGE)
        hit_monster.emit(body)
```

- [ ] **Step 2: Create ball.tscn in editor**

In Godot editor, create `scenes/ball.tscn`:

1. Root: `RigidBody2D` named `Ball`, script: `scripts/ball.gd`
   - Gravity Scale: `0`
   - Physics Material: Bounce `1.0`, Friction `0.0`
2. Child: `CollisionShape2D` with `CircleShape2D` radius `12`
3. Child: `MeshInstance2D` (or `ColorRect` offset `(-12,-12)` size `(24,24)`) color `#6366f1`
4. Child: `Line2D` named `Trajectory`, width `2`, default_color `#6366f180`
   - Add dash pattern: set `texture_mode` to `TILE`, add a simple 4px dash texture, or leave solid with low alpha
5. Connect signal `body_entered` → `_on_body_entered`

- [ ] **Step 3: Manual test — drag-to-aim**

Add a BallField scene and a Ball child at bottom center. Run:
- Click and drag upward from the ball → dotted line appears
- Release → ball launches
- Ball bounces off walls ≥ 3 times
- Ball slows and freezes → `settled` signal fires (verify in console with `print`)

- [ ] **Step 4: Manual test — monster damage**

Add 3 monsters to BallField. Aim at a monster, fire:
- Ball contacts monster → HP label decreases
- Monster at 0 HP disappears
- Ball continues bouncing after contact

- [ ] **Step 5: Commit**

```bash
git add scripts/ball.gd scenes/ball.tscn
git commit -m "feat: add ball with drag-to-aim, trajectory preview, bounce physics, monster damage"
```

---

## Task 8: Board Ring Visual

**Files:**
- Create: `game/scripts/board_ring_node.gd`
- Create: `game/scenes/board_ring.tscn`

- [ ] **Step 1: Create board_ring_node.gd**

Create `game/scripts/board_ring_node.gd`:

```gdscript
class_name BoardRingNode
extends Node2D

const TILE_COUNT := 24
const FIELD_W := 600.0
const FIELD_H := 500.0
const TILE_SIZE := 24.0
const OFFSET := 28.0  # gap between field edge and ring inner edge

const TILE_COLORS := {
    Tile.Type.NORMAL: Color("#1f2937"),
    Tile.Type.SURGE:  Color("#6366f1"),
    Tile.Type.EVENT:  Color("#a855f7"),
    Tile.Type.START:  Color("#22c55e"),
}
const PLAYER_COLOR := Color("#fbbf24")

# Distribution: 8 top, 4 right, 8 bottom, 4 left = 24
const TOP_COUNT    := 8
const RIGHT_COUNT  := 4
const BOTTOM_COUNT := 8
const LEFT_COUNT   := 4

var logic := BoardRing.new()
var _rects: Array[Rect2] = []

signal tile_landed(tile: Tile)
signal tile_passed(tile: Tile)
signal lap_completed

func _ready() -> void:
    logic.setup(TILE_COUNT)
    _build_rects()
    queue_redraw()

func _build_rects() -> void:
    _rects.clear()
    var top_step := (FIELD_W + OFFSET * 2) / TOP_COUNT
    for i in range(TOP_COUNT):
        _rects.append(Rect2(-OFFSET + i * top_step, -OFFSET - TILE_SIZE, TILE_SIZE, TILE_SIZE))
    var right_step := (FIELD_H + OFFSET * 2) / RIGHT_COUNT
    for i in range(RIGHT_COUNT):
        _rects.append(Rect2(FIELD_W + OFFSET - TILE_SIZE, -OFFSET + i * right_step, TILE_SIZE, TILE_SIZE))
    var bot_step := (FIELD_W + OFFSET * 2) / BOTTOM_COUNT
    for i in range(BOTTOM_COUNT):
        _rects.append(Rect2(FIELD_W + OFFSET - TILE_SIZE - i * bot_step, FIELD_H + OFFSET - TILE_SIZE, TILE_SIZE, TILE_SIZE))
    var left_step := (FIELD_H + OFFSET * 2) / LEFT_COUNT
    for i in range(LEFT_COUNT):
        _rects.append(Rect2(-OFFSET - TILE_SIZE, FIELD_H + OFFSET - TILE_SIZE - i * left_step, TILE_SIZE, TILE_SIZE))

func _draw() -> void:
    for i in range(_rects.size()):
        var tile := logic.get_tile(i)
        var col: Color = TILE_COLORS.get(tile.type, TILE_COLORS[Tile.Type.NORMAL])
        draw_rect(_rects[i], col)
        draw_rect(_rects[i], Color("#374151"), false, 1.0)
    if logic.player_position < _rects.size():
        draw_rect(_rects[logic.player_position].grow(-4), PLAYER_COLOR)

func move_player(steps: int) -> void:
    var visited := logic.move(steps)
    for idx in visited:
        tile_passed.emit(logic.get_tile(idx))
    tile_landed.emit(logic.get_tile(logic.player_position))
    if logic.completed_lap:
        lap_completed.emit()
    queue_redraw()

func split_move_player(first: int, second: int) -> void:
    logic.completed_lap = false
    logic.move(first)
    tile_landed.emit(logic.get_tile(logic.player_position))
    logic.move(second)
    tile_landed.emit(logic.get_tile(logic.player_position))
    if logic.completed_lap:
        lap_completed.emit()
    queue_redraw()
```

- [ ] **Step 2: Create board_ring.tscn in editor**

Create `scenes/board_ring.tscn`:
1. Root: `Node2D` named `BoardRing`, script: `scripts/board_ring_node.gd`

All drawing happens in `_draw()` — no child nodes needed.

- [ ] **Step 3: Manual test — ring renders correctly**

Add `BoardRing` to a test scene positioned at `(60, 60)`, run it. Verify:
- 24 colored rectangles form a ring around the field area
- Green tile at index 0 (START)
- Purple tiles at indices 7, 14, 21 (EVENT)
- Blue tile at index 11 (SURGE)
- Yellow player token on index 0

- [ ] **Step 4: Commit**

```bash
git add scripts/board_ring_node.gd scenes/board_ring.tscn
git commit -m "feat: add board ring visual with 24 colored tiles and player token"
```

---

## Task 9: Integration — Wire the Full Loop

**Files:**
- Create: `game/scripts/main.gd`
- Modify: `game/scenes/main.tscn`

- [ ] **Step 1: Create main.gd**

Create `game/scripts/main.gd`:

```gdscript
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
```

- [ ] **Step 2: Build main.tscn in editor**

Open `scenes/main.tscn`. Build this node tree:

```
Main (Node2D, script: scripts/main.gd)
├── BallField  (instance: ball_field.tscn)   position: (60, 60)
├── BoardRing  (instance: board_ring.tscn)   position: (60, 60)
└── UI (CanvasLayer)
    ├── DiceLabel    (Label)   position:(700,80)  text:""   font_size:28
    ├── StatusLabel  (Label)   position:(700,130) text:""   font_size:16
    ├── RollButton   (Button)  position:(700,170) text:"Roll"
    ├── CombinedButton (Button) position:(700,210) text:"Combined"
    └── SplitButton  (Button)  position:(700,250) text:"Split"
```

Set `ball_field.tscn` exports: `monster_scene = res://scenes/monster.tscn`, `ball_scene = res://scenes/ball.tscn`.

- [ ] **Step 3: Manual test — play one full turn**

Run `scenes/main.tscn`. Complete one full turn:

1. Click "Roll" → two numbers appear in DiceLabel
2. Click "Combined" or "Split" → player token moves on ring
3. 3 red monsters appear in ball field
4. Drag from ball launcher upward → dotted line shows direction
5. Release → ball launches and bounces around field
6. Ball hits a monster → HP label decreases; at 0, monster disappears
7. Ball slows and stops → second ball spawns at launcher
8. Second ball launched and settled → turn resolves → Roll button reappears

- [ ] **Step 4: Manual test — overflow fail condition**

Play multiple turns without killing monsters. After 4+ turns (12+ monsters spawned), confirm:
- `is_overflowed()` triggers when `monsters.size() >= 10`
- Status label shows "GAME OVER" and game halts

- [ ] **Step 5: Run all GUT tests one final time**

Run `tests/test_runner.tscn`. Expected: all tests in test_dice.gd, test_board_ring.gd, test_turn_manager.gd, test_monster.gd pass (green).

- [ ] **Step 6: Commit**

```bash
git add scripts/main.gd scenes/main.tscn
git commit -m "feat: integrate full turn loop — prototype v1 playable end-to-end"
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Covered by |
|---|---|
| 細框棋盤環 + 球場在中央 | Task 8 (BoardRingNode visual) + Task 6 (BallField) |
| 底部彈道軌道，拖拉瞄準 | Task 7 (Ball drag-to-aim, trajectory Line2D) |
| 每顆球獨立決策，射一顆看結果再射下一顆 | Task 9: `_next_shot()` awaits `settled` signal before spawning next |
| 球留在場上（射出 = 佈置棋子） | Ball.freeze=true on settle, not removed |
| 消耗球模型（無球庫） | BALLS_PER_TURN constant; no library object |
| 擲 2 顆骰子，整步/拆步 | Task 2 (Dice) + Task 4 (TurnManager) + Task 9 (UI buttons) |
| 棋盤大，格子有類型 | Task 3 (BoardRing 24 tiles, Tile.Type enum) |
| 怪物超過 10 隻即失敗 | Task 6: `is_overflowed()`, Task 9: RESOLVE checks it |
| Surge / Event 格子存在 | Tile.Type.SURGE / EVENT, color-coded on ring, stub in main.gd |
| 經過格有效果、停下有大效果 | `tile_passed` / `tile_landed` signals emitted; effects are stubs (next plan) |
| Boss 系統 | ❌ Out of scope for prototype |
| 晶片系統 | ❌ Out of scope for prototype |
| Meta 進度 | ❌ Out of scope for prototype |

**Placeholder scan:** `status_label.text = "SURGE — [effect TODO]"` and `"EVENT — [effect TODO]"` are intentional stubs marking where Prototype v2 will plug in tile effects. All other steps have complete code.

**Type consistency:** `BoardRing` (logic class) and `BoardRingNode` (visual Node2D) named distinctly throughout. `Monster`, `Ball`, `Tile`, `Dice`, `TurnManager` class names consistent across all tasks.
