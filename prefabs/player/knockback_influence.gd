extends Node
class_name KnockbackInfluence

var total_influence: Vector3 = Vector3.ZERO

func handle_influence(delta):
	var length = total_influence.length()
	var new_length = clampf(length - 20 * delta, 0, 1.79769e308) 
	total_influence = total_influence.normalized() * new_length
#	print(new_length)


func add_influence(influence: Vector3, strength: float):
	total_influence += influence * strength


func get_influence() -> Vector3:
	return total_influence
