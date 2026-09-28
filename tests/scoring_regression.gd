extends Node
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var saved: Dictionary = SaveManager.data.duplicate(true)
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.start_mission(0)
	await get_tree().create_timer(0.1).timeout
	var original_par: float = main.level.data.par_time
	main.level.data.par_time = 100
	GameManager.score = 750
	GameManager.rescued = 2
	GameManager.elapsed = 40
	GameManager.shots = 10
	GameManager.hits = 6
	GameManager.finish()
	check(GameManager.score == 3350, "Final tally must use mission par time")
	check(GameManager.score_breakdown.combat_and_pickups == 750, "Base score must be preserved")
	check(GameManager.score_breakdown.rescue_bonus == 2000, "Rescue bonus must be itemized")
	check(GameManager.score_breakdown.time_bonus == 600, "Time bonus must be itemized")
	GameManager.finish()
	check(GameManager.score == 3350, "Repeated finish must not add bonuses again")
	check(int(SaveManager.data.high_scores["0"]) >= 3350, "Total score must be saved")
	GameManager.shots = 0
	GameManager.hits = 0
	check(GameManager.accuracy() == 0, "No shots must have zero accuracy")
	GameManager.shots = 1
	GameManager.hits = 2
	check(GameManager.accuracy() == 1, "Accuracy must not exceed 100 percent")
	main.level.data.par_time = original_par
	main.start_mission(0)
	GameManager.elapsed = 999
	GameManager.finish()
	check(GameManager.score_breakdown.time_bonus == 0, "Over-par missions must not subtract score")
	GameManager.mission = 2
	main.show_result()
	var campaign_heading := false
	var unexpected_next := false
	for control in main.screen.get_children():
		if control is Label and control.text == "CAMPAIGN COMPLETE":
			campaign_heading = true
		if control is Button and control.text == "NEXT MISSION":
			unexpected_next = true
	check(campaign_heading and not unexpected_next, "Final mission result must close the campaign without looping")
	main.quit_to_menu()
	SaveManager.data = saved
	SaveManager.save()
	await get_tree().create_timer(0.15).timeout
	print("SCORING REGRESSION ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(0 if failures == 0 else 1)
