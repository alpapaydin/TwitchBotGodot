extends Node2D


var hp = 313131.1
var maxhp = hp
var dead = false
var is_dragging: bool = false
var drag_start_position: Vector2 = Vector2()
var click_pos = Vector2.ZERO
@onready var hpbar = $hpbar
@onready var hpanim = $hpbar/hpbaranim
@onready var anim = $Sprite2D/AnimationPlayer
@onready var window = get_window()
@onready var sprite = $Sprite2D
@onready var help = $helpTimer

func _ready():
	Twitch.whale = self
	get_tree().get_root().set_transparent_background(true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true, 0)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	DisplayServer.window_set_size($Sprite2D.texture.get_size() * 1.5)
	

func _process(_delta):
	if dead:
		if help.is_stopped():
			help.start()
		if !anim.is_playing():
			anim.play("Fall")
		return
	help.stop()
	if !anim.is_playing():
		anim.play("Idle")
	else:
		if anim.current_animation == "Run":
			if !$Sprite2D.flip_h:
				window.position.x -= 1
				window.position.y += 0.01
			else:
				window.position.x += 1
				window.position.y -= 0.01
	if Input.is_action_just_pressed("click"):
		anim.play("Swallow (Bomb)")
		sendFireball("basitgaming", 31)
		print(Twitch.chatters)
		click_pos = get_local_mouse_position()
	if Input.is_action_pressed("click"):
		window.position += Vector2i(get_global_mouse_position() - click_pos)
		
func resMe():
	Twitch.popup("!res")

func attackPulse(radius, _damage, effect):
	var destroyed = 0
	var vfxscene = load("res://scenes/show/vfx/"+effect+".tscn")
	var vfx = vfxscene.instantiate()
	var query_params = PhysicsShapeQueryParameters2D.new()
	query_params.shape = CircleShape2D.new()
	query_params.shape.radius = radius
	query_params.collision_mask = 1
	query_params.motion = Vector2.ZERO
	query_params.margin = 0.0
	query_params.transform = Transform2D(0,global_position)
	query_params.collide_with_bodies = true
	var physics_server = get_world_2d().get_direct_space_state()

	var result = physics_server.intersect_shape(query_params, 64)

	for item in result:
		var collider = item["collider"]
		#if collider.is_in_group("enemy"):
		collider.queue_free()
		destroyed += 1
			#knockback ekle
	add_child(vfx)
	return destroyed
	
func sendFireball(sender, _dmg):
	var fireballScene = preload("res://scenes/whale/attacks/projectile.tscn")
	var fireball = fireballScene.instantiate()
	fireball.sender = sender
	$mouthsocket.add_child(fireball)

func getDamage(dmg):
	hp -= dmg
	hpbar.value = hp/maxhp * 100
	anim.play("Hit")
	hpanim.play("damaged")
	if hp <= 0:
		onDead()

func healWhale(amount = 313131):
	hp += amount
	hpbar.value = hp/maxhp * 100
	hpanim.play("damaged")
		
func onDead():
	dead = true
	anim.play("Dead Hit")

func attack(kozmetik):
	anim.play("Attack")
	if kozmetik:
		return attackPulse(310, 31, "lightning")
	return attackPulse(310, 31, "explosion")
	
func flipandmove():
	$Sprite2D.flip_h = !$Sprite2D.flip_h
	anim.play("Run")


func _on_animation_player_animation_finished(anim_name):
	match anim_name:
		"Dead Hit":
			anim.play("Fall")
