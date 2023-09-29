extends Control

@onready var window = get_window()
var click_pos

func _ready():
	pass
	#get_window().mouse_passthrough_polygon = get_node("Polygon2D").polygon
	#OS.shell_open("https://dashboard.twitch.tv/popout/u/basitgaming/stream-manager/chat?uuid=8c119a0fed2486b4292d2a1017c08e1d")

func _input(_event):
	if Input.is_action_just_pressed("click"):
		Twitch.playerAttack("basitgaming")
		click_pos = get_local_mouse_position()
	if Input.is_action_pressed("click"):
		window.position += Vector2i(get_global_mouse_position() - click_pos)


func _on_timer_timeout():
	Twitch.addInterest()


func _on_incometimer_timeout():
	Saver._save()
	Twitch._on_IncomeTimer_timeout()
