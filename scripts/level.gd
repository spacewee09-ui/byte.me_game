class_name Level
extends Node2D
## One level. It is built from ASCII art (see scripts/levels.gd), which means
## you can add a whole level by typing characters into a text file.
##
## It owns the timer, the death counter, respawning and the camera.

signal player_died
signal bandage_collected
signal completed

const CELL := 32
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const SPIKE_SCRIPT := preload("res://scripts/spike.gd")
const SAW_SCRIPT := preload("res://scripts/saw.gd")
const BANDAGE_SCRIPT := preload("res://scripts/bandage.gd")
const GOAL_SCRIPT := preload("res://scripts/goal.gd")
const GIB_SCRIPT := preload("res://scripts/gib.gd")
const CAMERA_SCRIPT := preload("res://scripts/camera.gd")

const RESPAWN_DELAY := 0.42

var level_number := 1
var level_name := ""
var hint := ""

var rows: Array = []
var cols := 0
var size := Vector2.ZERO

var player: MeatGuy = null
var camera: Camera2D = null

var time := 0.0
var deaths := 0
var running := false
var bandage_found := false

var _spawn := Vector2.ZERO
var _block_cells: Array = []
var _solid_cells := {}
var _respawn_timer := -1.0
var _rng := RandomNumberGenerator.new()


func setup(data: Dictionary, number: int = 1) -> void:
	level_number = number
	level_name = str(data.get("name", "UNTITLED"))
	hint = str(data.get("hint", ""))
	rows = data.get("rows", [])
	cols = 0
	for row in rows:
		cols = maxi(cols, str(row).length())
	size = Vector2(cols * CELL, rows.size() * CELL)
	_rng.randomize()

	_build_solids()
	_spawn_player()
	_build_objects()
	_build_camera()

	queue_redraw()
	_respawn_timer = -1.0
	running = true


# --- Building ---------------------------------------------------------------

func _build_solids() -> void:
	var solid := StaticBody2D.new()
	solid.name = "Solids"
	solid.collision_layer = 1
	solid.collision_mask = 0
	add_child(solid)

	for y in rows.size():
		var line := str(rows[y])
		var x := 0
		while x < line.length():
			if line[x] == "#":
				var start := x
				while x < line.length() and line[x] == "#":
					x += 1
				_add_block_run(solid, start, x, y)
			else:
				x += 1


func _add_block_run(solid: StaticBody2D, start_x: int, end_x: int, y: int) -> void:
	for x in range(start_x, end_x):
		_block_cells.append(Vector2i(x, y))
		_solid_cells[Vector2i(x, y)] = true

	var width := float(end_x - start_x) * CELL
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, CELL)
	shape.shape = rect
	shape.position = Vector2(start_x * CELL + width * 0.5, y * CELL + CELL * 0.5)
	solid.add_child(shape)


func _spawn_player() -> void:
	var spawn_cell := Vector2i(2, rows.size() - 3)
	var goal_cell := Vector2i(cols - 3, 1)
	for y in rows.size():
		var line := str(rows[y])
		for x in line.length():
			if line[x] == "P":
				spawn_cell = Vector2i(x, y)
			elif line[x] == "G":
				goal_cell = Vector2i(x, y)

	_spawn = cell_center(spawn_cell) + Vector2(0, 1)
	player = PLAYER_SCENE.instantiate()
	player.global_position = _spawn
	add_child(player)
	_goal_cell = goal_cell


var _goal_cell := Vector2i.ZERO
var _bandage: Area2D = null


func _build_objects() -> void:
	for y in rows.size():
		var line := str(rows[y])
		for x in line.length():
			var cell := Vector2i(x, y)
			match line[x]:
				"^":
					_add_spike(cell, false)
				"v":
					_add_spike(cell, true)
				"S":
					_add_saw(cell, Vector2.ZERO)
				"T":
					_add_saw(cell, Vector2(2.5 * CELL, 0))
				"U":
					_add_saw(cell, Vector2(0, 2.0 * CELL))
				"o":
					_add_bandage(cell)
				"G":
					_add_goal(cell)


func _add_spike(cell: Vector2i, pointing_down: bool) -> void:
	var spike = SPIKE_SCRIPT.new()
	spike.position = cell_center(cell)
	spike.pointing_down = pointing_down
	add_child(spike)
	spike.body_entered.connect(_on_hazard_touched)


func _add_saw(cell: Vector2i, patrol: Vector2) -> void:
	var saw = SAW_SCRIPT.new()
	saw.position = cell_center(cell)
	saw.patrol = patrol
	add_child(saw)
	saw.body_entered.connect(_on_hazard_touched)


func _add_bandage(cell: Vector2i) -> void:
	var bandage = BANDAGE_SCRIPT.new()
	bandage.position = cell_center(cell)
	add_child(bandage)
	bandage.body_entered.connect(_on_bandage_touched)
	_bandage = bandage


func _add_goal(cell: Vector2i) -> void:
	var goal = GOAL_SCRIPT.new()
	goal.position = cell_center(cell)
	add_child(goal)
	goal.body_entered.connect(_on_goal_touched)


func _build_camera() -> void:
	camera = Camera2D.new()
	camera.set_script(CAMERA_SCRIPT)
	camera.position = _spawn + Vector2(0, -30)
	camera.limit_left = 0
	camera.limit_top = -16
	camera.limit_right = int(size.x)
	camera.limit_bottom = int(size.y)
	add_child(camera)
	camera.target = player
	camera.make_current()


# --- Running ----------------------------------------------------------------

func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL + CELL * 0.5, cell.y * CELL + CELL * 0.5)


func _physics_process(delta: float) -> void:
	if not running:
		return

	time += delta

	if player != null and player.alive and player.global_position.y > size.y + 160.0:
		kill_player()

	if _respawn_timer >= 0.0:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_respawn_timer = -1.0
			_respawn_player()


func kill_player() -> void:
	if not running or player == null or not player.alive:
		return
	player.die()
	deaths += 1
	_spawn_meat(player.global_position, 16)
	player_died.emit()
	Audio.play("death", -5.0, randf_range(0.9, 1.05))
	if camera != null:
		camera.shake(15.0)
	_respawn_timer = RESPAWN_DELAY


func _respawn_player() -> void:
	if player == null or running == false:
		return
	player.respawn(_spawn)
	if camera != null:
		camera.global_position = _spawn + Vector2(0, -30)
		camera.reset_smoothing()


func _on_hazard_touched(body: Node2D) -> void:
	if body is MeatGuy:
		kill_player()


func _on_bandage_touched(body: Node2D) -> void:
	if not (body is MeatGuy) or bandage_found:
		return
	bandage_found = true
	bandage_collected.emit()
	Audio.play("collect", -6.0)
	if _bandage != null and is_instance_valid(_bandage):
		_spawn_dust(_bandage.global_position, Color("#ffd479"), 14)
		_bandage.queue_free()
		_bandage = null


func _on_goal_touched(body: Node2D) -> void:
	if not (body is MeatGuy) or not running:
		return
	running = false
	player.freeze()
	_spawn_dust(cell_center(_goal_cell), Color("#ffd479"), 18)
	completed.emit()
	Audio.play("win", -3.0)
	if camera != null:
		camera.shake(6.0)



# --- Particles --------------------------------------------------------------

func _spawn_meat(at: Vector2, amount: int) -> void:
	var colors := [Color("#c11f24"), Color("#e8514a"), Color("#8f1a1f"), Color("#ff7b6b")]
	for i in amount:
		var gib = GIB_SCRIPT.new()
		gib.position = at
		var dir := Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.2, 0.2))
		gib.velocity = dir * _rng.randf_range(160.0, 420.0)
		gib.spin = _rng.randf_range(-14.0, 14.0)
		gib.color = colors[i % colors.size()]
		gib.chunk_size = _rng.randf_range(3.0, 7.0)
		gib.life = _rng.randf_range(0.5, 1.1)
		add_child(gib)


func _spawn_dust(at: Vector2, color: Color, amount: int) -> void:
	for i in amount:
		var gib = GIB_SCRIPT.new()
		gib.position = at + Vector2(_rng.randf_range(-8.0, 8.0), _rng.randf_range(-8.0, 8.0))
		gib.velocity = Vector2(_rng.randf_range(-80.0, 80.0), _rng.randf_range(-260.0, -60.0))
		gib.spin = _rng.randf_range(-6.0, 6.0)
		gib.color = color
		gib.chunk_size = _rng.randf_range(2.0, 5.0)
		gib.life = _rng.randf_range(0.3, 0.7)
		gib.gravity = 400.0
		gib.drag = 1.6
		gib.is_round = true
		add_child(gib)


# --- Drawing ----------------------------------------------------------------

func _draw() -> void:
	for cell in _block_cells:
		_draw_block(cell)


func _is_solid(cell: Vector2i) -> bool:
	return _solid_cells.has(cell)


func _noise(cell: Vector2i) -> int:
	return absi((cell.x * 73856093) ^ (cell.y * 19349663) ^ 0x5f3759df)


func _draw_block(cell: Vector2i) -> void:
	var pos := Vector2(cell) * CELL
	var n := _noise(cell)

	# Base meat-brick.
	draw_rect(Rect2(pos, Vector2(CELL, CELL)), Color("#42202a"))

	# A couple of darker patches so big walls are not flat.
	if n % 3 == 0:
		draw_rect(Rect2(pos + Vector2(4 + n % 17, 9 + n % 13), Vector2(10, 7)), Color("#3a1c25"))
	if n % 5 == 0:
		draw_rect(Rect2(pos + Vector2(7 + n % 12, 20), Vector2(13, 5)), Color("#4d2833"))
	if n % 7 == 0:
		draw_rect(Rect2(pos + Vector2(18, 6), Vector2(5, 4)), Color("#552c36"))

	# Lit top edge, dark underside, darker exposed sides.
	if not _is_solid(cell + Vector2i(0, -1)):
		draw_rect(Rect2(pos, Vector2(CELL, 5)), Color("#7c4753"))
		draw_rect(Rect2(pos + Vector2(0, 5), Vector2(CELL, 2)), Color("#5c313c"))
	if not _is_solid(cell + Vector2i(0, 1)):
		draw_rect(Rect2(pos + Vector2(0, CELL - 5), Vector2(CELL, 5)), Color("#26121a"))
	if not _is_solid(cell + Vector2i(-1, 0)):
		draw_rect(Rect2(pos, Vector2(3, CELL)), Color("#2b131c"))
	if not _is_solid(cell + Vector2i(1, 0)):
		draw_rect(Rect2(pos + Vector2(CELL - 3, 0), Vector2(3, CELL)), Color("#2b131c"))
