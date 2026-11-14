extends Control
## Everything the player reads: timer, deaths, level select, pause, clear screen.
## All drawn with primitives so the project needs no font or UI assets.

const CREAM := Color("#f7ead9")
const RED := Color("#ff6b5e")
const DIM := Color("#bb9a94")
const GOLD := Color("#ffcf6b")
const DARK := Color("#120507")

var game = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if game == null:
		return
	match game.state:
		"menu":
			_draw_menu()
		"play":
			_draw_hud()
		"paused":
			_draw_hud()
			_draw_pause()
		"clear":
			_draw_hud()
			_draw_clear()
		"win":
			_draw_win()


# --- In-game HUD ------------------------------------------------------------

func _draw_hud() -> void:
	var w := size.x
	var level = game.level
	if level == null:
		return

	draw_rect(Rect2(0, 0, w, 72), Color(0.05, 0.015, 0.02, 0.55))
	draw_line(Vector2(0, 72), Vector2(w, 72), Color(0.9, 0.3, 0.25, 0.25), 2.0)

	_text(Vector2(30, 28), "LEVEL %d / %d" % [level.level_number, Levels.LEVELS.size()], 14, DIM)
	_text(Vector2(30, 56), level.level_name, 24, CREAM)

	_text(Vector2(w - 330, 46), _format_time(level.time), 30, CREAM, HORIZONTAL_ALIGNMENT_RIGHT, 300)

	var found: bool = bool(game.bandages.get(level.level_number - 1, false)) or level.bandage_found
	var status := "DEATHS %d" % level.deaths
	if found:
		status += "   BANDAGE FOUND"
	_text(Vector2(w - 330, 64), status, 13, GOLD if found else DIM, HORIZONTAL_ALIGNMENT_RIGHT, 300)

	# The hint fades out after the first few seconds.
	if level.time < 6.5:
		var alpha := clampf(6.5 - level.time, 0.0, 1.0)
		_text(Vector2(0, size.y - 96), level.hint, 17, Color(CREAM, alpha * 0.9), HORIZONTAL_ALIGNMENT_CENTER, w)

	_text(Vector2(0, size.y - 22), "R  RESTART        ESC  PAUSE", 13, Color(DIM, 0.65), HORIZONTAL_ALIGNMENT_CENTER, w)


# --- Menu -------------------------------------------------------------------

func _draw_menu() -> void:
	var w := size.x
	draw_rect(Rect2(0, 0, w, size.y), Color(0.05, 0.015, 0.02, 0.55))
	_draw_menu_meat(Vector2(w * 0.5, 132))

	_text(Vector2(0, 300), "BYTE.ME", 96, CREAM, HORIZONTAL_ALIGNMENT_CENTER, w)
	_text(Vector2(0, 336), "A  M E A T - G R I N D E R   P L A T F O R M E R", 16, RED, HORIZONTAL_ALIGNMENT_CENTER, w)

	# Level chips.
	var count: int = Levels.LEVELS.size()
	var chip_w := 64.0
	var gap := 14.0
	var total := count * chip_w + (count - 1) * gap
	var start := (w - total) * 0.5
	for i in count:
		var rect := Rect2(start + i * (chip_w + gap), 396, chip_w, 44)
		var is_unlocked: bool = i < game.unlocked
		var is_selected: bool = i == game.selected
		draw_rect(rect, Color(0.1, 0.03, 0.04, 0.9) if is_unlocked else Color(0.06, 0.02, 0.03, 0.7))
		if is_selected:
			draw_rect(rect, Color(RED, 0.85), false, 3.0)
		else:
			draw_rect(rect, Color(1, 0.5, 0.4, 0.18), false, 1.5)
		var label := "%02d" % (i + 1)
		if not is_unlocked:
			label = "--"
		_text(rect.position + Vector2(0, 30), label, 20, CREAM if is_unlocked else Color(DIM, 0.4), HORIZONTAL_ALIGNMENT_CENTER, chip_w)

	var chosen: Dictionary = Levels.LEVELS[game.selected]
	_text(Vector2(0, 474), str(chosen.get("name", "")), 22, CREAM, HORIZONTAL_ALIGNMENT_CENTER, w)

	var best := float(game.best_times.get(game.selected, 0.0))
	var best_text := "BEST  %s" % _format_time(best) if best > 0.0 else "NOT BEATEN YET"
	_text(Vector2(0, 502), best_text, 14, GOLD if best > 0.0 else Color(DIM, 0.8), HORIZONTAL_ALIGNMENT_CENTER, w)

	var blink := fmod(Time.get_ticks_msec() / 1000.0, 1.3) < 0.85
	_text(Vector2(0, 570), "PRESS  SPACE  TO  PLAY", 24, Color(CREAM, 1.0 if blink else 0.25), HORIZONTAL_ALIGNMENT_CENTER, w)

	_text(Vector2(0, 630), "A / D  or  ARROWS     RUN", 15, DIM, HORIZONTAL_ALIGNMENT_CENTER, w)
	_text(Vector2(0, 654), "SPACE     JUMP   ·   ON A WALL, JUMP AGAIN TO WALL-JUMP", 15, DIM, HORIZONTAL_ALIGNMENT_CENTER, w)
	_text(Vector2(0, 678), "R     RESTART LEVEL        ESC     PAUSE", 15, DIM, HORIZONTAL_ALIGNMENT_CENTER, w)

	var total_bandages: int = game.total_bandages()
	_text(Vector2(0, size.y - 18), "BANDAGES  %d / %d        MADE WITH GODOT 4" % [total_bandages, count], 13, Color(DIM, 0.7), HORIZONTAL_ALIGNMENT_CENTER, w)


func _draw_menu_meat(center: Vector2) -> void:
	# A big, slightly smug meat guy for the title screen.
	draw_circle(center + Vector2(4, 8), 52.0, Color(0, 0, 0, 0.35))
	draw_circle(center, 50.0, Color("#3a0f0f"))
	draw_circle(center, 46.0, Color("#e8514a"))
	draw_circle(center + Vector2(10, 16), 34.0, Color("#a32b28"))
	draw_circle(center + Vector2(-16, -18), 15.0, Color("#ff9a7c"))
	for ex in [-16.0, 16.0]:
		draw_circle(center + Vector2(ex, -8), 13.0, Color.WHITE)
		draw_circle(center + Vector2(ex + 4, -8), 6.0, Color("#20100f"))
	draw_arc(center + Vector2(0, 22), 14.0, PI * 0.1, PI * 0.9, 14, Color("#3a0f0f"), 4.0)


# --- Overlays ---------------------------------------------------------------

func _draw_pause() -> void:
	_dim_screen(0.65)
	var w := size.x
	_text(Vector2(0, size.y * 0.5 - 10), "PAUSED", 64, CREAM, HORIZONTAL_ALIGNMENT_CENTER, w)
	_text(Vector2(0, size.y * 0.5 + 40), "ESC  RESUME        R  RESTART        Q  QUIT TO MENU", 16, DIM, HORIZONTAL_ALIGNMENT_CENTER, w)


func _draw_clear() -> void:
	_dim_screen(0.72)
	var w := size.x
	var level = game.level

	_text(Vector2(0, 250), "LEVEL CLEAR", 64, RED, HORIZONTAL_ALIGNMENT_CENTER, w)
	if level != null:
		_text(Vector2(0, 288), str(level.level_name), 22, CREAM, HORIZONTAL_ALIGNMENT_CENTER, w)

	var y := 360.0
	_text(Vector2(0, y), "YOUR TIME   %s" % _format_time(game.last_time), 24, CREAM, HORIZONTAL_ALIGNMENT_CENTER, w)

	var best := float(game.best_times.get(game.selected, 0.0))
	if game.last_was_best:
		_text(Vector2(0, y + 38), "NEW BEST TIME!", 20, GOLD, HORIZONTAL_ALIGNMENT_CENTER, w)
	else:
		_text(Vector2(0, y + 38), "BEST   %s" % _format_time(best), 18, DIM, HORIZONTAL_ALIGNMENT_CENTER, w)

	if level != null:
		_text(Vector2(0, y + 78), "YOU DIED %d TIMES" % level.deaths, 18, DIM, HORIZONTAL_ALIGNMENT_CENTER, w)
		if level.bandage_found:
			_text(Vector2(0, y + 112), "BANDAGE FOUND", 18, GOLD, HORIZONTAL_ALIGNMENT_CENTER, w)

	var blink := fmod(Time.get_ticks_msec() / 1000.0, 1.3) < 0.85
	var prompt := "PRESS  SPACE  FOR  THE  NEXT  LEVEL"
	if game.selected + 1 >= Levels.LEVELS.size():
		prompt = "PRESS  SPACE  TO  SEE  THE  RESULT"
	_text(Vector2(0, 560), prompt, 22, Color(CREAM, 1.0 if blink else 0.3), HORIZONTAL_ALIGNMENT_CENTER, w)
	_text(Vector2(0, 596), "R  RETRY THIS LEVEL", 14, Color(DIM, 0.8), HORIZONTAL_ALIGNMENT_CENTER, w)


func _draw_win() -> void:
	_dim_screen(0.82)
	var w := size.x
	_text(Vector2(0, 260), "YOU SURVIVED", 72, RED, HORIZONTAL_ALIGNMENT_CENTER, w)
	_text(Vector2(0, 300), "THE  GRINDER", 22, CREAM, HORIZONTAL_ALIGNMENT_CENTER, w)

	_text(Vector2(0, 390), "TOTAL TIME    %s" % _format_time(game.run_time), 26, CREAM, HORIZONTAL_ALIGNMENT_CENTER, w)
	_text(Vector2(0, 432), "TOTAL DEATHS    %d" % game.run_deaths, 20, DIM, HORIZONTAL_ALIGNMENT_CENTER, w)
	_text(
		Vector2(0, 470),
		"BANDAGES    %d / %d" % [game.total_bandages(), Levels.LEVELS.size()],
		20,
		GOLD,
		HORIZONTAL_ALIGNMENT_CENTER,
		w
	)

	_text(Vector2(0, 560), "THANKS FOR PLAYING", 18, DIM, HORIZONTAL_ALIGNMENT_CENTER, w)
	var blink := fmod(Time.get_ticks_msec() / 1000.0, 1.3) < 0.85
	_text(Vector2(0, 610), "PRESS  SPACE  TO  GO  BACK  TO  THE  MENU", 20, Color(CREAM, 1.0 if blink else 0.3), HORIZONTAL_ALIGNMENT_CENTER, w)


func _dim_screen(alpha: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(DARK, alpha))


# --- Helpers ----------------------------------------------------------------

func _text(pos: Vector2, txt: String, font_size: int, color: Color, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null or txt == "":
		return
	draw_string(font, pos + Vector2(0, 2), txt, align, width, font_size, Color(0.04, 0.01, 0.02, 0.6 * color.a))
	draw_string(font, pos, txt, align, width, font_size, color)


func _format_time(seconds: float) -> String:
	var whole := int(seconds)
	return "%d:%05.2f" % [whole / 60, fmod(seconds, 60.0)]
