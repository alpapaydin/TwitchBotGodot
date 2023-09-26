extends CharacterBody2D

@export var attack_range: float = 250.0
@export var speed: float = 125.0
@onready var player = Twitch.whale 
@onready var sprite = $AnimatedSprite2D
@onready var spawner = get_parent()
var projectileScene = preload("res://scenes/enemies/projectile/fireball/fireball.tscn")
var attacking: bool = false
var attackDamage = 31
var cooldown = Timer.new()

func _ready():
	cooldown.wait_time = 1.925
	cooldown.one_shot = true
	add_child(cooldown)
	cooldown.start()

func _physics_process(_delta):
	if player == null:
		return
	
	var direction_to_target = (player.global_position - global_position).normalized()
	
	# Check if within attack range.
	if global_position.distance_to(player.global_position) <= attack_range:
		if not attacking:
			start_attack()
	else:
		velocity = direction_to_target * speed
		move_and_slide()

func start_attack():
	if cooldown.is_stopped() and player.hp > 0:
		sendFireball()
		player.getDamage(attackDamage)
		sprite.play("attack")
		attacking = true
		cooldown.start()

func sendFireball():
	var fireball = projectileScene.instantiate()
	add_child(fireball)

func _exit_tree():
	spawner.enemyCount -= 1

func _on_animated_sprite_2d_animation_finished():
	attacking = false
	sprite.play("idle")
