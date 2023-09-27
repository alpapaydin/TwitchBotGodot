extends Node

var players = {}
var sender_command_cooldowns = {}
var pending_dices = {}  # Store pending dice requests
var shopItems = {"maserati": 4500, "adidas esofman takimi": 3100, "kozmetik":315}
var cps = preload("res://scenes/show/vfx/coinpickup/coin.tscn")
var popupscene = preload("res://scenes/show/singlepopup/popup.tscn")
var fadepopupscene = preload("res://scenes/show/fadepopup/fadepopup.tscn")
var chatall = preload("res://scenes/show/chatall/spawn_chat_names.tscn")
var whale
var command_cost = {
	"attack": 0.0,
	"heal": 10.0,
	"speak": 31.0,
	"speakeng": 20.0,
	"sa": 999999.0,
}
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
			if !payCommandCost(sender, command):
				return sender+" you need "+str(command_cost[command])+"$ to "+command
			match command:
				"sa":
					popup("as "+sender)
					return "as "+sender
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
				"dice":
					var args = arg.split(" ", 2)
					return askDice(sender, args[0], int(args[1]))
				"accept":
					return acceptDice(sender)
				"reisler":
					return get_top_players()
				"speak":
					return "ok"
				"speakeng":
					return "ok"
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


# Function to initiate dice roll request
func askDice(player, to, amount):
	if players.has(to) and players.has(player):
		if players[player]["coin"] >= amount:
			pending_dices[to] = [{"from": player, "amount": amount}]
			return player+" has asked "+to+" for a dice roll of "+str(amount)+" coins. Type !accept to accept."
		else:
			return player+" does not have enough coins."
	return "Invalid player."

# Function to accept dice roll request and perform the roll
func acceptDice(player):
	if pending_dices.has(player) and pending_dices[player].size()>0:
		var amount = pending_dices[player][0]["amount"]
		var from_player = pending_dices[player][0]["from"]
		if players[player]["coin"] >= amount:
			if players[from_player]["coin"] >= amount:
				var roll1 = randi() % 6 + 1
				var roll2 = randi() % 6 + 1
				var winner = ""
				if roll1 > roll2:
					winner = from_player
				elif roll2 > roll1:
					winner = player
				else:
					return "It's a tie!"
				players[from_player if winner == player else player]["coin"] -= amount
				pickupCoin(winner, amount * 2)
				pending_dices.erase(player) # sadece atılan ilk istek de silinebilir.
				return from_player+" rolled "+str(roll1)+", "+player+" rolled "+str(roll2)+". "+winner+" wins "+str(amount * 2)+" coins!"
			return from_player+" does not have enough coins to accept the dice roll."
		return player+" does not have enough coins to accept the dice roll."
	return "No pending dice request."


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
	if whale.dead:
		return "Please revive the holy whale using !res"
	var playerLevel = players[player]["level"]
	var multiplier = players[player]["upgrades"]["heal"]
	var healLevel = playerLevel * multiplier * 15
	var healamount = 100 * healLevel
	fadePopup(player+" cansın")
	whale.anim.play("Attack")
	whale.healWhale(healamount)
	Audioload.play("heal")
	pickupCoin(player, healLevel)
	return "Healed for "+str(healamount)+" and got "+str(healLevel)+"$."

func resWhale(player):
	if whale.dead:
		Audioload.play("res")
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
	fadePopup(player + " " + str(round(players[player]["coin"])) + "$", true)

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

func drawCoins(player, amount):
	if players[player]["coin"] >= amount:
		players[player]["coin"] -= amount
		return true
	return false

func payCommandCost(player, command):
	if !command_cost.has(command):
		return true
	if drawCoins(player, command_cost[command]):
		return true
	return false

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
	var pop = popupscene.instantiate()
	pop.text = text
	add_child(pop)

func fadePopup(text, below = false):
	var pop = fadepopupscene.instantiate()
	pop.text = text
	pop.below = below
	add_child(pop)

func userSubscribed(user):
	Speak.text("Welcome "+user+" adamsın")

func get_top_players() -> String:
	var player_names = players.keys()
	
	# Sort player names by coins in descending order
	player_names.sort_custom(sort_by_coins)
	
	# Reverse the array to get it in descending order
	player_names.reverse()
	
	# Return top 5 players
	return str(player_names.slice(0, 4))

func sort_by_coins(a, b):
	return players[a]["coin"] - players[b]["coin"]
