extends Node
class_name GravityInfluence

@export_subgroup("Properties")
@export var jump_strength = 7

var player: Player

var influence: float = 0.0
var jumps_remaining: int = 2

var downward_pull := 15


func init(player: Player):
	self.player = player


func handle_gravity(delta):
	influence -= downward_pull * delta
	influence = clamp(influence, -6, 10000)
	
	if influence < 0 and player.is_on_floor():
		jumps_remaining = 2
		influence = 0
		
#	print(influence)


func jump():
	if jumps_remaining > 0:
		Audio.play("sounds/jump_a.ogg, sounds/jump_b.ogg, sounds/jump_c.ogg")
		
		influence = jump_strength
		jumps_remaining -= 1


func get_influence() -> float:
	return influence
