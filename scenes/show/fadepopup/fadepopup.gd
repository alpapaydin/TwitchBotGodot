extends PanelContainer

var text
var below = false
var player = null

func _process(_delta):
	if player:
		$PopupText.text = player + " " + str(round(Twitch.players[player]["coin"])) + "$"

func _ready():
	$PopupText.text = text
	$AudioStreamPlayer2D.play()
	if below:
		$HeartRect.queue_free()
		position.y = 100
	else:
		$GoldRect.queue_free()
	
func _on_text_anim_animation_finished(_anim_name):
	queue_free()
