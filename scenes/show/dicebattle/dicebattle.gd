extends Node2D

@onready var attackername = $PanelContainer/VBoxContainer/HBoxContainer/Attacker/VBoxContainer/AttackerName
@onready var attackerdice = $PanelContainer/VBoxContainer/HBoxContainer/Attacker/VBoxContainer/AttackerDice
@onready var defendername = $PanelContainer/VBoxContainer/HBoxContainer/Defender/VBoxContainer/DefenderName
@onready var defenderdice = $PanelContainer/VBoxContainer/HBoxContainer/Defender/VBoxContainer/DefenderDice

var attacker
var defender
var atkrol
var defrol

func _ready():
	attackername.text = attacker
	defendername.text = defender

func _on_dice_timer_timeout():
	attackerdice.get_node("AnimationPlayer").play(str(atkrol))
	defenderdice.get_node("AnimationPlayer").play(str(defrol))
	$destroyTimer.start()

func _on_destroy_timer_timeout():
	queue_free()
