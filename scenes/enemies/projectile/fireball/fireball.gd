extends Node2D

var speed = 1000  # Movement speed in pixels per second
var target = Twitch.whale.global_position

func _process(delta):
	var direction = (target - global_position).normalized()
	var move_amount = speed * delta
	var new_position = global_position + direction * move_amount
	if new_position.distance_to(target) < move_amount:
		queue_free()
		#global_position = target  # Snap to target if close enough
	else:
		global_position = new_position  # Otherwise, update the position


func _on_timer_timeout():
	queue_free()
