extends Node

var path = "user://data.tres"

func _ready():
	_load()

func _process(_delta):
	if Input.is_action_just_pressed("altf4"):
		_save()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save()

func _save():
	var saveResource = preload("res://scenes/main/save/SaveRes.tres")
	saveResource.playerData = Twitch.players
	ResourceSaver.save(saveResource, path)
	print("saved game")
	return saveResource

func _load():
	var dir = DirAccess.open("user://")
	if dir.file_exists("data.tres"):	
		var loadResource = preload("user://data.tres")
		Twitch.players = loadResource.playerData
		print("loaded game")
