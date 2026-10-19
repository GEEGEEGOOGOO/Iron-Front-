extends Node
var failures := 0
func check(value: bool,message: String) -> void:
	if not value:
		failures+=1;push_error(message)
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	for mission in [0,1,2]:
		var main=load("res://scenes/main.tscn").instantiate();add_child(main);main.start_mission(mission)
		var field=main.level.battlefield
		if mission==1:
			check(field.name=="DustBattalion" and not field is MissionBattlefield,"Dust Battalion must retain its original builder")
		else:
			check(field is MissionBattlefield,"New missions must use distinct industrial scenery")
			check(field.foundry==(mission==2),"Foundry must use the night industrial theme")
			check(field.terminals.size()==3,"Each new mission needs three interactive doors")
			var actor=GameManager.player
			actor.set_physics_process(false);actor.position=field.terminals[0].global_position
			check(field.use_terminal(actor),"Nearby E interaction must operate a door")
			check(field.powered[0] and field.doors[0].collision_layer==0,"Open door must disable its collision")
			check(field.use_terminal(actor) and not field.powered[0],"Second interaction must close the door")
			check(field.doors[0].collision_layer==1,"Closed door must restore collision")
			check(main.level.ladders.size()>0,"New scenery must preserve climbing")
		main.quit_to_menu();main.queue_free();await get_tree().process_frame
	print("MISSION MAPS REGRESSION ","PASS" if failures==0 else "FAIL")
	get_tree().quit(0 if failures==0 else 1)
