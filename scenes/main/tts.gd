extends Node

# One-time steps.
# Pick a voice. Here, we arbitrarily pick the first English voice.
var voices = DisplayServer.tts_get_voices_for_language("en")
var voice_idk = voices[0]
var voice_ide = voices[1]

#func _ready():
	#print(DisplayServer.tts_get_voices())
	# Say "Hello, world!".
	#DisplayServer.tts_speak("Hello, world!", voice_idk)

func text(txt, kari = false):
	var id = voice_idk if kari else voice_ide
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(txt, id)
