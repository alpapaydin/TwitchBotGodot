extends Node

var namescene = preload("res://scenes/show/chatall/name_popup.tscn")
@onready var rect = $SpawnRect.get_rect()
var chatterData

func _ready():
	if chatterData:
		spawnChatties(chatterData)

func spawnChatties(chatties):
	for chatter in chatties:
		spawn_single_chatty(chatter)
		await get_tree().create_timer(0.5).timeout  # 0.5 seconds delay
	await get_tree().create_timer(2.5).timeout
	queue_free()
	
func spawn_single_chatty(chatter):
	var namepop = namescene.instantiate()
	var random_point = get_random_point_in_rect(rect)
	namepop.get_node("Label").text = chatter
	namepop.global_position = random_point
	print(random_point)
	get_parent().add_child(namepop)

func get_random_point_in_rect(rect: Rect2) -> Vector2:
	var x = randf() * (rect.size.x) + rect.position.x
	var y = randf() * (rect.size.y) + rect.position.y
	return Vector2(x, y)
