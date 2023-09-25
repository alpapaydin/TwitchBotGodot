extends PanelContainer

var text

func _ready():
	$PopupText.text = text
	$AudioStreamPlayer2D.play()
	
func _on_text_anim_animation_finished(anim_name):
	queue_free()
