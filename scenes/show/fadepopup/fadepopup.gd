extends PanelContainer

var text
var below = false

func _ready():
	if below:
		position.y = 100
	$PopupText.text = text
	$AudioStreamPlayer2D.play()
	
func _on_text_anim_animation_finished(_anim_name):
	queue_free()
