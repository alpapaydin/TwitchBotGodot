extends Node

var thread: Thread
var botpath

func _ready() -> void:
	var botpath = ProjectSettings.globalize_path("res://bot/")
	print(botpath)
	thread = Thread.new()
	thread.start(_thread)

	while thread.is_alive():
		await print(31)

	print(thread.wait_to_finish())
	thread = null

func _thread() -> String:
	
	var output := []
	var err: int = OS.execute("CMD.exe", [botpath, "python.exe bot.py"], output)

	if err != 0:
		printerr("Error occurred: %d" % err)
		
	return str(output)
