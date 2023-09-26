extends Node

var players = {}
var sender_command_cooldowns = {}
var shopItems = {"maserati": 4500, "adidas esofman takimi": 3100, "kozmetik":315}
var cps = preload("res://scenes/show/vfx/coinpickup/coin.tscn")
var popupscene = preload("res://scenes/show/singlepopup/popup.tscn")
var fadepopupscene = preload("res://scenes/show/fadepopup/fadepopup.tscn")
var chatall = preload("res://scenes/show/chatall/spawn_chat_names.tscn")
var whale

var command_cooldowns = {
	"attack": 10.0,
	"heal": 1.0,
	"command2": 10.0,
	"command3": 3.0,
}

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
			checkRegisterPlayer(sender)
			match command:
				"sa":
					popup("as "+sender)
				"attack":
					if isOnCooldown(sender, "attack"):
						return sender+", wait before "+command
					updateCooldown(sender, "attack")
					return playerAttack(sender)
				"play":
					return playSong(sender, arg)
				"heal":
					if isOnCooldown(sender, "attack"):
						return "Cooldown"
					updateCooldown(sender, "attack")
					return playerHeal(sender)
				"stats":
					return playerStats(sender)
				"upgrade":
					return buyUpgrade(sender, arg)
				"buy":
					return shopBuy(sender, arg)
				"res":
					return resWhale(sender)
				"reisler":
					return sort_players_by_coins()
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
	return "OK"

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

func playSong(player, playing):
	var multiplier = players[player]["upgrades"]["play"]
	var playLevel = players[player]["level"] * multiplier
	fadePopup("Now Playing: "+playing)
	pickupCoin(player, playLevel)
	whale.anim.play("Fall")
	return player+" got "+str(playLevel)+" for playing masterpiece "+playing

func playerStats(sender):
	var toNextLevel =  pow(players[sender]["level"], 2) * 31
	var stats = "
	Player: "+sender+"
	Cash: "+str(round(players[sender]["coin"]))+"$, 
	Level: "+str(players[sender]["level"])+", 
	Exp: "+str(round(players[sender]["exp"]))+"/"+str(toNextLevel)+"."
	return stats

func playerAttack(player):
	var destroyed = whale.attack(players[player]["items"].has("kozmetik"))
	var multiplier = players[player]["upgrades"]["attack"]
	var attackLevel = players[player]["level"] * multiplier
	var getGold = destroyed * attackLevel
	var gotExp = getExp(player, destroyed)
	pickupCoin(player, getGold)
	return player + " popped " + str(destroyed) + " enemies. Got " + str(getGold) + " gold and " + str(gotExp) + " exp."

func playerHeal(player):
	var playerLevel = players[player]["level"]
	var multiplier = players[player]["upgrades"]["heal"]
	var healLevel = playerLevel * multiplier
	var healamount = 100 * healLevel
	fadePopup(player+" cansın")
	whale.anim.play("Fall")
	whale.healWhale(healamount)
	pickupCoin(player, healLevel)
	return str(healamount)+" can bastın ve "+str(healLevel)+" para kastın."

func resWhale(player):
	if whale.dead:
		whale.hp = whale.maxhp
		whale.dead = false
		whale.anim.play("Idle")
		pickupCoin(player, 3131)
		return player+" has resurrected the holy whale and gained 3131 coins."
	return ""

func pickupCoin(player, amount = 1):
	checkRegisterPlayer(player)
	players[player]["coin"] += amount
	var coin = cps.instantiate()
	add_child(coin)
	Speak.text("respect "+player)
	fadePopup(player + " " + str(players[player]["coin"]) + "$", true)

func getExp(player, amount = 1):
	var multiplier = players[player]["upgrades"]["exp"]
	var toNextLevel =  pow(players[player]["level"], 2) * 31
	var gotExp = amount * multiplier
	players[player]["exp"] += gotExp
	if players[player]["exp"] >= toNextLevel:
		players[player]["exp"] -= toNextLevel
		players[player]["level"] += 1
		print("level up")
	return gotExp

func buyUpgrade(player, upgrade):
	if players[player]["upgrades"].has(upgrade):
		var playerCoin = players[player]["coin"]
		var currentLevel = players[player]["upgrades"][upgrade]
		var goldNeed = pow(currentLevel,2) * 250
		if playerCoin >= goldNeed:
			players[player]["coin"] -= goldNeed
			players[player]["upgrades"][upgrade] *= 1.2
			return upgrade+" is now level "+str(players[player]["upgrades"][upgrade])
		return "You need "+ str(goldNeed - playerCoin) + " more coins."
	return "Invalid upgrade name, try "+str(players[player]["upgrades"].keys())+"."

func shopBuy(player, item):
	if shopItems.has(item):
		if players[player]["coin"] >= shopItems[item]:
			if players[player]["items"].has(item):
				players[player]["items"][item] += 1
				return player+" bought "+item+" ("+str(players[player]["items"][item])+")"
			players[player]["items"][item] = 1
			return player+" bought "+item
		return "You need "+str(shopItems[item] - players[player]["coin"])+" more gold to buy "+item+"."
	return str(shopItems)

func checkRegisterPlayer(player):
	#player stats
	if !players.has(player):
		players[player] = {
			"coin": 1,
			"level": 1,
			"exp": 0,
			"items": {},
			"upgrades": {
				"play": 1.0,
				"heal": 1.0,
				"attack": 1.0,
				"exp": 1.0,
			}
		}

#Cooldown
# Function to check if a command is on cooldown for a sender
func isOnCooldown(sender: String, command: String) -> bool:
	var current_time = Time.get_ticks_msec() / 1000.0
	if sender_command_cooldowns.has(sender) and sender_command_cooldowns[sender].has(command):
		var last_time = sender_command_cooldowns[sender][command]
		if current_time - last_time < command_cooldowns[command]:
			return true
	return false

# Function to update the cooldown for a sender and command
func updateCooldown(sender: String, command: String):
	var current_time = Time.get_ticks_msec() / 1000.0
	if not sender_command_cooldowns.has(sender):
		sender_command_cooldowns[sender] = {}
	sender_command_cooldowns[sender][command] = current_time


func popup(text):
	var popup = popupscene.instantiate()
	popup.text = text
	add_child(popup)

func fadePopup(text, below = false):
	var popup = fadepopupscene.instantiate()
	popup.text = text
	popup.below = below
	add_child(popup)

func userSubscribed(user):
	Speak.text("Welcome "+user+" adamsın")

func compare(a, b):
		return b["coin"] - a["coin"]

func sort_players_by_coins():
	var player_keys = players.keys()
	player_keys.sort_custom(compare)
	
	var sorted_players = {}
	for key in player_keys:
		sorted_players[key] = players[key]
		
	return str(sorted_players.keys())
