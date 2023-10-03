extends Area2D

var sender: String

var speed: float = 500.0
var direction: Vector2

# For the trail effect
var line: Line2D
var points_queue = Array()

func _ready():
	$TrailLabel.text = sender
	var angle: float = randf() * 2 * PI
	direction = Vector2(cos(angle), sin(angle)).normalized()
	
	# Initialize Line2D for trail effect
	line = Line2D.new()
	line.width = 9.0
	line.modulate = random_color()
	line.gradient = Gradient.new()
	line.gradient.set_color(0, random_color())
	line.gradient.set_color(1, random_color())
	add_child(line)
	var newrot = direction.angle_to_point(Vector2.ZERO) * 180 / PI
	$TrailLabel.rotation_degrees = newrot

func _physics_process(_delta: float) -> void:
	position += direction * speed * _delta

	# Add the current global_position to the points_queue
	points_queue.append(global_position)
	
	# Remove the oldest point if there are more than 50 points
	if points_queue.size() > 50:
		points_queue.pop_at(0)
		
	# Update the Line2D points
	var local_points = [global_position - global_position] # Start with the current point (as zero)
	for point in points_queue:
		local_points.append(point - global_position) # Convert global points to local coordinates
	line.points = local_points

func random_color() -> Color:
	return Color(randf(), randf(), randf(), 1.0)

func _on_Area2D_body_entered(body: Node) -> void:
	$AudioStreamPlayer.play()
	body.queue_free()
	call_deferred("spawn_children")
	call_deferred("queue_free")

func spawn_children() -> void:
	if scale.x < 0.1:
		return
	var angle1: float = direction.angle() + deg_to_rad(120.0)
	var angle2: float = direction.angle() - deg_to_rad(120.0)
	var projectile_scene = preload("res://scenes/whale/attacks/projectile.tscn")
	
	for angle in [angle1, angle2]:
		var new_direction: Vector2 = Vector2(cos(angle), sin(angle)).normalized()
		var projectile = projectile_scene.instantiate()
		projectile.scale = scale / 2.0
		projectile.sender = sender
		projectile.get_node("AudioStreamPlayer").volume_db -= 15.0
		projectile.direction = new_direction
		get_parent().add_child(projectile)
		projectile.global_position = global_position


func _on_destroy_timer_timeout():
	queue_free()
