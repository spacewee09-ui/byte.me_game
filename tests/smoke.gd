extends SceneTree
## Headless checks for BYTE.ME.
##
## Run it with:
##   godot --headless --path . -s res://tests/smoke.gd
##
## It checks the input map and the level data, then actually plays level 1:
## run, jump, die on spikes, respawn and reach the exit.

var _failures := 0


func _initialize() -> void:
	_run()


func _check(ok: bool, message: String) -> void:
	if ok:
		print("  ok    ", message)
	else:
		_failures += 1
		printerr("  FAIL  ", message)


func _run() -> void:
	print("BYTE.ME smoke test")

	print("\n[input map]")
	for action in ["move_left", "move_right", "jump", "restart", "pause"]:
		_check(InputMap.has_action(action), "action exists: %s" % action)
		if InputMap.has_action(action):
			_check(InputMap.action_get_events(action).size() > 0, "action has keys: %s" % action)

	print("\n[level data]")
	_check(Levels.LEVELS.size() > 0, "there is at least one level")
	for i in Levels.LEVELS.size():
		var data: Dictionary = Levels.LEVELS[i]
		var rows: Array = data.get("rows", [])
		var width := -1
		var same_width := true
		var p_count := 0
		var g_count := 0
		var bad_chars := ""
		for row in rows:
			if width == -1:
				width = str(row).length()
			elif str(row).length() != width:
				same_width = false
			for ch in str(row):
				if ch == "P":
					p_count += 1
				elif ch == "G":
					g_count += 1
				elif not ".#^vSTUo".contains(ch) and not bad_chars.contains(ch):
					bad_chars += ch
		_check(same_width, "level %d rows are all the same length" % (i + 1))
		_check(p_count == 1, "level %d has exactly one start (P)" % (i + 1))
		_check(g_count == 1, "level %d has exactly one exit (G)" % (i + 1))
		_check(bad_chars == "", "level %d uses only known tiles" % (i + 1))

	print("\n[game]")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	_check(main.state == "menu", "game boots to the menu")

	main._start_level(0)
	await create_timer(0.45).timeout
	_check(main.state == "play", "level 1 starts")

	var level = main.level
	if level == null:
		printerr("  FAIL  level did not load, stopping here")
		_finish()
		return

	var guy = level.player
	_check(guy != null, "meat guy spawned")
	_check(guy.is_on_floor(), "meat guy is standing on the floor")

	print("\n[movement]")
	var start_x: float = guy.global_position.x
	Input.action_press("move_right")
	await create_timer(0.35).timeout
	Input.action_release("move_right")
	_check(guy.global_position.x > start_x + 20.0, "running right moves the meat guy")

	Input.action_press("jump")
	await create_timer(0.06).timeout
	_check(guy.velocity.y < 0.0, "jumping goes up")
	Input.action_release("jump")
	await create_timer(0.7).timeout
	_check(guy.is_on_floor(), "the meat guy lands again")

	print("\n[death and respawn]")
	var spike = null
	var goal = null
	for child in level.get_children():
		if child.get_script() == load("res://scripts/spike.gd"):
			spike = child
		elif child.get_script() == load("res://scripts/goal.gd"):
			goal = child
	_check(spike != null, "level 1 has spikes")
	_check(goal != null, "level 1 has an exit")

	if spike != null:
		guy.global_position = spike.global_position
		guy.velocity = Vector2.ZERO
		await create_timer(0.18).timeout
		_check(level.deaths == 1, "touching spikes kills the meat guy")
		await create_timer(0.7).timeout
		_check(guy.alive, "the meat guy respawns after death")
		_check(absf(guy.global_position.x - level.cell_center(Vector2i(4, 19)).x) < 40.0, "respawn happens at the start")

	print("\n[finishing a level]")
	if goal != null:
		guy.global_position = goal.global_position + Vector2(0, 6)
		guy.velocity = Vector2.ZERO
		await create_timer(0.25).timeout
		_check(main.state == "clear", "touching the grinder clears the level")
		_check(level.time > 0.0, "the level timer ran")

	print("\n[pausing]")
	main._start_level(0)
	await create_timer(0.3).timeout
	main._set_paused(true)
	_check(main.state == "paused", "pause switches state")
	_check(main.level.process_mode == Node.PROCESS_MODE_DISABLED, "pause freezes the level")
	main._set_paused(false)
	_check(main.state == "play", "unpause switches back")

	print("\n[every level builds]")
	for i in Levels.LEVELS.size():
		main._start_level(i)
		await create_timer(0.3).timeout
		var loaded = main.level
		_check(
			loaded != null and loaded.player != null and loaded.camera != null,
			"level %d builds and has a player and camera" % (i + 1)
		)
		if loaded != null:
			_check(loaded.get_child_count() > 2, "level %d has objects in it" % (i + 1))

	_finish()


func _finish() -> void:
	if _failures == 0:
		print("\nALL CHECKS PASSED")
	else:
		printerr("\n%d CHECK(S) FAILED" % _failures)
	quit(1 if _failures > 0 else 0)
