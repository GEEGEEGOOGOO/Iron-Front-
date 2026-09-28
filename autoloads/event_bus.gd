extends Node
signal hud_changed
signal player_died
signal enemy_killed(points: int)
signal pow_rescued
signal weapon_picked_up(weapon_name: String)
signal shake_requested(intensity: float, duration: float)
signal wave_cleared
signal mission_finished
signal damage_received(target: Node, amount: float)
signal hitstop_requested(duration: float)
