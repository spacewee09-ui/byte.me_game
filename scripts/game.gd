extends Node2D
## Runs the whole game: menus, level order, timing, saved progress.
##
## States: "menu", "play", "paused", "clear", "win".
## The HUD reads this node's state and draws the right screen.

const SAVE_PATH := "user://byte_me_save.cfg"

@onready var world = $World
@onready var hud = $UI/HUD
@onready var background = $Backdrop/Background

var state := "menu"
var selected := 0
var level: Level = null

var best_times := {}
var bandages := {}
var unlocked := 1

var run_time := 0.0
var run_deaths := 0
var run_bandages := 0
var last_time := 0.0
var last_was_best := false


func _ready() -> void:
	hud.game = self
	_load_progress()
	_enter_menu()


func _unhandled_input(event: InputEvent) -> void:
	if state == "menu":
		if event.is_action_pressed("ui_right"):
			_change_selection(1)
		elif event.is_action_pressed("ui_left"):
			_change_selection(-1)
		elif event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
			_start_run()
	elif state == "play":
		if event.is_action_pressed("restart"):
			_start_level(selected)
		elif event.is_action_pressed("pause"):
			_set_paused(true)
	elif state == "paused":
		if event.is_action_pressed("pause"):
			_set_paused(false)
		elif event.is_action_pressed("restart"):
			_set_paused(false)
			_start_level(selected)
		elif _is_key(event, KEY_Q):
			_enter_menu()
	elif state == "clear":
		if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
			_next_level()
		elif event.is_action_pressed("restart"):
			_start_level(selected)
	elif state == "win":
		if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
			_enter_menu()


func _is_key(event: InputEvent, keycode: int) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo and event.keycode == keycode
	return false


# --- Flow -------------------------------------------------------------------

func _enter_menu() -> void:
	state = "menu"
	_clear_level()
	run_time = 0.0
	run_deaths = 0
	run_bandages = 0
	last_was_best = false


func _start_run() -> void:
	run_time = 0.0
	run_deaths = 0
	run_bandages = 0
	_start_level(selected)


func _start_level(index: int) -> void:
	_clear_level()
	selected = clampi(index, 0, Levels.LEVELS.size() - 1)
	state = "play"

	level = Level.new()
	level.name = "Level%d" % (selected + 1)
	world.add_child(level)
	level.player_died.connect(_on_player_died)
	level.bandage_collected.connect(_on_bandage_collected)
	level.completed.connect(_on_completed)
	level.setup(Levels.LEVELS[selected], selected + 1)

	Audio.play("click", -12.0)


func _next_level() -> void:
	if selected + 1 >= Levels.LEVELS.size():
		state = "win"
		Audio.play("win", -2.0)
	else:
		_start_level(selected + 1)


func _clear_level() -> void:
	if level != null and is_instance_valid(level):
		level.queue_free()
	level = null


func _set_paused(paused: bool) -> void:
	if level == null:
		return
	state = "paused" if paused else "play"
	level.process_mode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT


func _change_selection(step: int) -> void:
	var next := clampi(selected + step, 0, maxi(0, unlocked - 1))
	if next != selected:
		selected = next
		Audio.play("click", -14.0)


# --- Signals from the level --------------------------------------------------

func _on_player_died() -> void:
	run_deaths += 1


func _on_bandage_collected() -> void:
	bandages[selected] = true
	run_bandages += 1
	_save_progress()


func _on_completed() -> void:
	state = "clear"
	last_time = level.time
	run_time += level.time

	var previous := float(best_times.get(selected, 0.0))
	last_was_best = false
	if previous <= 0.0 or last_time < previous:
		best_times[selected] = last_time
		last_was_best = previous > 0.0

	unlocked = maxi(unlocked, mini(selected + 2, Levels.LEVELS.size()))
	_save_progress()


# --- Saved progress ----------------------------------------------------------

func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	for i in Levels.LEVELS.size():
		if best_times.has(i):
			cfg.set_value("levels", "best_%d" % i, float(best_times[i]))
		if bandages.get(i, false):
			cfg.set_value("levels", "bandage_%d" % i, true)
	cfg.save(SAVE_PATH)


func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	unlocked = clampi(int(cfg.get_value("progress", "unlocked", 1)), 1, Levels.LEVELS.size())
	for i in Levels.LEVELS.size():
		if cfg.has_section_key("levels", "best_%d" % i):
			best_times[i] = float(cfg.get_value("levels", "best_%d" % i, 0.0))
		if cfg.has_section_key("levels", "bandage_%d" % i):
			bandages[i] = bool(cfg.get_value("levels", "bandage_%d" % i, false))


## Used by the HUD.
func total_bandages() -> int:
	var count := 0
	for i in Levels.LEVELS.size():
		if bandages.get(i, false):
			count += 1
	return count
