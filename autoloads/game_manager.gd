extends Node
enum State { MENU, PLAYING, PAUSED, GAME_OVER, COMPLETE }
var state: State = State.MENU
var score := 0
var lives := 3
var rescued := 0
var shots := 0
var hits := 0
var mission := 0
var elapsed := 0.0
var checkpoint := Vector3(2, 1, 0)
var player: CharacterBody3D
var level: Node3D
var god_mode := false
var hitstop_until := 0
var score_breakdown: Dictionary = {}
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.hitstop_requested.connect(func(duration: float):
		if state == State.PLAYING:
			hitstop_until = maxi(hitstop_until, Time.get_ticks_msec() + int(duration * 1000))
			Engine.time_scale = 0.12)
	EventBus.enemy_killed.connect(func(points: int):
		score += points
		EventBus.hud_changed.emit())
func _process(_delta: float) -> void:
	if hitstop_until > 0 and (Time.get_ticks_msec() >= hitstop_until or state != State.PLAYING):
		hitstop_until = 0
		Engine.time_scale = 1.0
func _physics_process(delta: float) -> void:
	if state == State.PLAYING:
		elapsed += delta
func begin(index: int) -> void:
	score_breakdown.clear()
	god_mode = false
	mission = index
	score = 0
	lives = 3
	rescued = 0
	shots = 0
	hits = 0
	elapsed = 0
	checkpoint = Vector3(2, 1, 0)
	state = State.PLAYING
func finish() -> void:
	if state != State.PLAYING:
		return
	state = State.COMPLETE
	var par := 240.0
	if is_instance_valid(level):
		par = level.data.par_time
	score_breakdown = {
		"combat_and_pickups": score,
		"rescue_bonus": rescued * 1000,
		"time_bonus": maxi(0, int(par - elapsed)) * 10,
		"par_time": par,
		"accuracy": accuracy()
	}
	score += int(score_breakdown.rescue_bonus) + int(score_breakdown.time_bonus)
	score_breakdown.total = score
	SaveManager.record(mission, score)
	EventBus.mission_finished.emit()
func rank() -> String:
	var rating := score + int(accuracy() * 3000) + rescued * 1000
	return "S" if rating > 14000 else ("A" if rating > 9000 else ("B" if rating > 4500 else "C"))

func accuracy() -> float:
	return clampf(float(hits) / maxi(shots, 1), 0.0, 1.0)
