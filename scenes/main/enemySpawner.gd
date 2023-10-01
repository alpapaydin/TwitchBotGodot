extends Node2D

@export var enemy_scene: PackedScene
@export var offset: float = 0.0  # Offset outside the screen.

var radius: float = 300.0
var helpTimer = Timer.new()
var spawnTimer = Timer.new()
var enemyCount = 0

@onready var player = Twitch.whale

func _ready():
	spawnTimer.wait_time = 2
	spawnTimer.connect("timeout", spawn_enemy)
	add_child(spawnTimer)
	helpTimer.wait_time = 60
	helpTimer.connect("timeout", help)
	add_child(helpTimer)
	spawnTimer.start()

func _process(_delta):
	if helpTimer.is_stopped():
		if enemyCount >= 50:
			helpTimer.start()
	elif !enemyCount >= 50:
		helpTimer.stop()
		
func help():
	if player.dead:
		Twitch.popup("!res")
		return
	Twitch.popup("!attack")

func spawn_enemy():
	if player.dead:
		return
	# Generate a random angle in radians.
	var angle: float = randf() * 2.0 * PI
	
	# Calculate the position on the circle using polar coordinates.
	var x: float = radius * cos(angle)
	var y: float = radius * sin(angle)
	var spawn_position: Vector2 = Vector2(x, y)
	
	# Create the enemy instance and add it to the current scene.
	var enemy_instance: Node2D = enemy_scene.instantiate() as Node2D
	if x < 0:
		enemy_instance.get_node("AnimatedSprite2D").flip_h = true
	enemy_instance.position = spawn_position
	enemyCount += 1
	add_child(enemy_instance)

