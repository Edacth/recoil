extends Node
class_name GravityInfluence

@export_subgroup("Properties")
@export var jump_strength = 7

var player: Player

var gravity: float = 0.0
var jump_single := true
var jump_double := true


func init(player: Player):
	self.player = player



func handle_gravity(delta):
	# Handle gravity
	gravity += 20 * delta
	
	if gravity > 0 and player.is_on_floor():
		
		jump_single = true
		gravity = 0
	print(gravity)


func jump():
	if jump_single or jump_double:
		Audio.play("sounds/jump_a.ogg, sounds/jump_b.ogg, sounds/jump_c.ogg")
		
		if jump_double:
			
			gravity = -jump_strength
			jump_double = false
			
		if(jump_single): 
			gravity = -jump_strength
	
			jump_single = false;
			jump_double = true;
	


func get_influence() -> float:
	return gravity
