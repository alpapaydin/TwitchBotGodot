extends Node2D

var is_dragging: bool = false
var drag_start_position: Vector2 = Vector2()
var click_pos = Vector2.ZERO
var popupscene = preload("res://scenes/show/singlepopup/popup.tscn")
var chatall = preload("res://scenes/show/chatall/spawn_chat_names.tscn")
@onready var anim = $dragpart/Sprite2D/AnimationPlayer

func _ready():
	get_tree().get_root().set_transparent_background(true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true, 0)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	DisplayServer.window_set_size($dragpart/Sprite2D.texture.get_size() * 2)
	

func _process(_delta):
	if !anim.is_playing():
		anim.play("Idle")
	if Input.is_action_just_pressed("click"):
		anim.play("Swallow (Bomb)")
		click_pos = get_local_mouse_position()
	if Input.is_action_pressed("click"):
		get_window().position += Vector2i(get_global_mouse_position() - click_pos)


func _on_animation_player_animation_finished(_anim_name):
	pass

func gotMessage(msg):
	var data = msg.split(".", 2)
	match data.size():
		3:
			#pass user commands
			print(data)
			var sender = data[0]
			var command = data[1]
			var arg = data[2]
			match command:
				"saa":
					var popup = popupscene.instantiate()
					popup.text = "as "+sender
					add_child(popup)
					anim.play("Attack")
		2:
			#pass datac
			var tag = data[0]
			var content = data[1]
			match tag:
				"chatterData":
					var spawner = chatall.instantiate()
					spawner.chatterData = strtoArray(content)
					add_child(spawner)
		1:
			#notify
			match msg:
				"newmessage":
					anim.play("Run")

func strtoArray(s: String) -> Array:
	# Remove the outer brackets
	s = s.substr(1, s.length() - 2)
	
	# Split by comma
	var raw_array = s.split(",")
	
	# Remove the single quotes around each name and handle potential spaces
	var result_array = []
	for item in raw_array:
		item = item.replace(" ", "")  # Remove spaces
		result_array.append(item.substr(1, item.length() - 2))
	
	return result_array
