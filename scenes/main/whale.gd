extends Node2D

var is_dragging: bool = false
var drag_start_position: Vector2 = Vector2()
var click_pos = Vector2.ZERO

@onready var anim = $Sprite2D/AnimationPlayer
@onready var window = get_window()

func _ready():
	Twitch.whale = self
	get_tree().get_root().set_transparent_background(true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true, 0)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	DisplayServer.window_set_size($Sprite2D.texture.get_size() * 1.5)
	

func _process(_delta):
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
		click_pos = get_local_mouse_position()
	if Input.is_action_pressed("click"):
		window.position += Vector2i(get_global_mouse_position() - click_pos)

func flipandmove():
	$Sprite2D.flip_h = !$Sprite2D.flip_h
	anim.play("Run")
