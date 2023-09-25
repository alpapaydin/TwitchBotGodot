extends Node

var players = {}

var cps = preload("res://scenes/show/vfx/coinpickup/coin.tscn")
var popupscene = preload("res://scenes/show/singlepopup/popup.tscn")
var fadepopupscene = preload("res://scenes/show/fadepopup/fadepopup.tscn")
var chatall = preload("res://scenes/show/chatall/spawn_chat_names.tscn")
var whale

#RECEIVE FROM TWITCH BOT
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
					whale.anim.play("Attack")
					pickupCoin(sender)
				"play":
					fadePopup("Now Playing: "+arg)
					whale.anim.play("Fall")
					pickupCoin(sender, 31)
		2:
			#pass datac
			var tag = data[0]
			var content = data[1]
			match tag:
				"chatterData":
					var spawner = chatall.instantiate()
					spawner.chatterData = strtoArray(content)
					add_child(spawner)
				"subscribed":
					userSubscribed(content)
		1:
			#notify
			match msg:
				"newmessage":
					whale.flipandmove()

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

func pickupCoin(player, amount = 1):
	checkRegisterPlayer(player)
	players[player]["coin"] += amount
	var coin = cps.instantiate()
	add_child(coin)
	Speak.text("respect "+player)
	fadePopup(player + " coins: " + str(players[player]["coin"]), true)

func checkRegisterPlayer(player):
	#player stats
	if !players.has(player):
		players[player] = {
			"coin": 1,
		}

func fadePopup(text, below = false):
	var popup = fadepopupscene.instantiate()
	popup.text = text
	popup.below = below
	add_child(popup)

func userSubscribed(user):
	Speak.text("Welcome "+user+" adamsın")
