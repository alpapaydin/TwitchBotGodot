extends Node2D

var namescene = preload("res://scenes/show/chatall/name_popup.tscn")
@onready var rect = $SpawnRect.get_rect()
var chatterData

func _ready():
	if chatterData:
		spawnChatties(chatterData)

func spawnChatties(chatties):
	var delay = 0.5  # initial delay in seconds
	var decrement = 0.05  # the amount by which the delay decreases each iteration
	var min_delay = 0.1  # minimum delay in seconds
	
	var pitch_scale = 1.0  # initial pitch scale
	var pitch_increment = 0.1  # the amount by which the pitch scale increases each iteration
	var max_pitch = 3.0  # maximum pitch scale

	for chatter in chatties:
		spawn_single_chatty(chatter, min(max_pitch, pitch_scale))
		await get_tree().create_timer(max(min_delay, delay)).timeout
		delay -= decrement
		pitch_scale += pitch_increment


	await get_tree().create_timer(2.5).timeout
	queue_free() # type /chatall
	
func spawn_single_chatty(chatter, pitch):
	var namepop = namescene.instantiate()
	var random_point = get_random_point_in_rect(rect)
	namepop.get_node("NamePopup/Label").text = chatter
	namepop.global_position = random_point
	namepop.modulate = map_float_to_color(pitch)
	get_parent().add_child(namepop)
	var sound = namepop.get_node("SFX")
	sound.pitch_scale = pitch
	sound.play()

func get_random_point_in_rect(rectt: Rect2) -> Vector2:
	var x = randf() * (rectt.size.x) + rectt.position.x
	var y = randf() * (rectt.size.y) + rectt.position.y
	return Vector2(x, y)

# Define boundary colors
var color_1 = Color(0, 1, 0)  # Red
var color_2 = Color(0.5, 0.5, 0)  # Green
var color_3 = Color(0.1, 0.3, 1)  # Blue


# Function to map a float to a color
func map_float_to_color(value: float) -> Color:
	if value <= 2.0:
		# Interpolate between color_1 and color_2
		return color_1.lerp(color_2, value - 1.0)
	elif value <= 3.0:
		# Interpolate between color_2 and color_3
		return color_2.lerp(color_3, value - 2.0)
	return Color(0, 0, 0)  # Default to black if value is out of range
