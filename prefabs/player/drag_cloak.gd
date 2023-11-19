extends Node
class_name DragCloak

@onready var audio_stream_player:= $AudioStreamPlayer as AudioStreamPlayer

var is_active := false
var knockback_drag_factor := 0.98
var gravity_drag_factor := 0.4

func activate():
	is_active = true
	audio_stream_player.play()


func deactivate():
	is_active = false
	audio_stream_player.stop()
	
	
	
func applyKnockbackDragIfActive(influence:float) -> float:
	if (is_active):
		return applyKnockbackDrag(influence)
	return influence
	
func applyKnockbackDrag(influence: float) -> float:
	return influence * knockback_drag_factor


func applyGravityDragIfActive(influence:float) -> float:
	if (is_active):
		return applyGravityDrag(influence)
	return influence
	
func applyGravityDrag(influence: float) -> float:
	return influence * gravity_drag_factor


#func _process(delta):
#	if is_active:
#		audio_stream_player.
