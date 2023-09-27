extends Node

var asp_pool := []

func _ready():
	for _i in range(5):  # Adjust the number based on your needs
		var asp = AudioStreamPlayer.new()
		asp.bus = "SFX"
		add_child(asp)
		asp_pool.append(asp)  # Add each player to the pool

func play(filename):
	var stream = load("res://asset/sfx/" + filename + ".ogg")
	
	# Find an available AudioStreamPlayer from the pool
	for asp in asp_pool:
		if not asp.is_playing():
			asp.stream = stream
			asp.play()
			return  # Exit the loop once an available player is found
	# If all players are busy, you can choose to either wait or prioritize the latest request.
	# Here, we're prioritizing the latest request.
	asp_pool[-1].stream = stream
	asp_pool[-1].play()
