extends Gift

func _ready() -> void:
	cmd_no_permission.connect(no_permission)
	chat_message.connect(on_chat)
	event.connect(on_event)
	unhandled_message.connect(unhandledMessage)
	# I use a file in the working directory to store auth data
	# so that I don't accidentally push it to the repository.
	# Replace this or create a auth file with 3 lines in your
	# project directory:
	# <client_id>
	# <client_secret>
	# <initial channel>
	var authfile := FileAccess.open("user://auth", FileAccess.READ)
	client_id = authfile.get_line()
	client_secret = authfile.get_line()
	var initial_channel = authfile.get_line()

	# When calling this method, a browser will open.
	# Log in to the account that should be used.
	await(authenticate(client_id, client_secret))
	var success = await(connect_to_irc())
	if (success):
		request_caps()
		join_channel(initial_channel)
	await(connect_to_eventsub())
	# Refer to https://dev.twitch.tv/docs/eventsub/eventsub-subscription-types/ for details on
	# what events exist, which API versions are available and which conditions are required.
	# Make sure your token has all required scopes for the event.
	subscribe_event("channel.follow", 2, {"broadcaster_user_id": user_id, "moderator_user_id": user_id})
###

func unhandledMessage(message, _tags):
	print("TEST::: "+message)


var shopItems = {
	"maserati": 4500,
	"adidas esofman takimi": 3100,
	"kozmetik":315
	}
	
var businesses = {
	"seo ajansi": {"startup_price": 100, "min_level": 1},
	"camgirl subesi": {"startup_price": 500, "min_level": 2},
	"taksi duragi": {"startup_price": 1000, "min_level": 3},
	"telefoncu": {"startup_price": 5000, "min_level": 4},
	"nargile cafe": {"startup_price": 10000, "min_level": 5}
}

	#scenes
var cps = preload("res://scenes/show/vfx/coinpickup/coin.tscn")
var popupscene = preload("res://scenes/show/singlepopup/popup.tscn")
var fadepopupscene = preload("res://scenes/show/fadepopup/fadepopup.tscn")
var chatall = preload("res://scenes/show/chatall/spawn_chat_names.tscn")
var dicebattle = preload("res://scenes/show/dicebattle/dicebattle.tscn")

var command_cost = {
	"attack": 0.0,
	"heal": 10.0,
	"speak": 31.0,
	"speakeng": 20.0,
}
var command_cooldowns = {
	"attack": 10.0,
	"heal": 1.0,
	"command2": 10.0,
	"command3": 3.0,
}

var whale
var players = {}
var sender_command_cooldowns = {}
var pending_dices = {}  # Store pending dice requests

func checkRegisterPlayer(player):
	#player stats
	if !players.has(player):
		players[player] = {
			"coin": 1,
			"level": 1,
			"exp": 0,
			"items": {},
			"businesses": {},
			"upgrades": {
				"play": 1.0,
				"heal": 1.0,
				"attack": 1.0,
				"exp": 1.0,
				"bank": 1.0,
			}
		}
		
func on_event(type : String, data : Dictionary) -> void:
	match(type):
		"channel.follow":
			print("%s followed your channel!" % data["user_name"])

func on_chat(data : SenderData, msg : String) -> void:
	if msg[0] == "!":
		var modified_str = msg.lstrip("!").split(" ", true, 1)
		if !modified_str.size()>1:
			modified_str.append("null")
		var response = gotMessage(data.user+"."+modified_str[0]+"."+modified_str[1])
		chat(response)
		print(data.user+"."+modified_str[0]+"."+modified_str[1])
		
	#%ChatContainer.put_chat(data, msg)

func no_permission(_cmd_info : CommandInfo) -> void:
	chat("NO PERMISSION!")

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
				"chatall":
					chatAll(chatters)
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
						return "Cooldown..."
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
				"donate":
					var args = arg.split(" ", 2)
					return sendCoins(sender, args[0], int(args[1]))
				"accept":
					return acceptDice(sender)
				"reisler":
					return get_top_players("coin")
				"speak":
					Speak.text(arg)
					return "ok"
				"speakeng":
					return "ok"
				"biz":
					var args = arg.split(" ")
					var sub_command = args[0]
					var businessName = ""
					for i in range(1, args.size()):
						businessName += args[i] + " "
					businessName = businessName.strip_edges()  # Remove trailing spaces
					
					match sub_command:
						"buy", "sell", "upgrade", "info":
							return handleBusinessCommand(sender, sub_command, businessName)
						"list":
							return listBusinesses()
						_:
							return "Business Commands: !biz list, !biz buy (name), !biz sell (name), !biz upgrade(name), !biz info (name)"
		2:
			#pass datac
			var tag = data[0]
			var content = data[1]
			match tag:
				"subscribed":
					userSubscribed(content)
		1:
			#notify
			match msg:
				"newmessage":
					whale.flipandmove()
	return "OK"

func chatAll(data):
	var spawner = chatall.instantiate()
	spawner.chatterData = data
	add_child(spawner)

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

###BUSINESS
# Initialize businesses for players
func initBusinesses():
	for player in players.keys():
		players[player]["businesses"] = {}

# Function to list all available businesses
func listBusinesses():
	var business_list_str = "Available Businesses:\n"
	for businessName in businesses.keys():
		var business = businesses[businessName]
		business_list_str += "//" + businessName + " (Startup Price: " + str(business["startup_price"]) + ", Min Level: " + str(business["min_level"]) + ")/"
	return business_list_str

# Function to handle business commands that require a business name
func handleBusinessCommand(player, sub_command, businessName):
	if businessName == "":
		return "Please specify a business to " + sub_command + "."
	match sub_command:
		"buy":
			return buyBusiness(player, businessName)
		"sell":
			return sellBusiness(player, businessName)
		"upgrade":
			return reinvestBusiness(player, businessName)
		"info":
			return businessInfo(player, businessName)

# Buy a business
func buyBusiness(player, businessName):
	print(businessName)
	if businesses.has(businessName):
		if !players[player]["businesses"].has(businessName):
			var business = businesses[businessName]
			if players[player]["level"] >= business["min_level"]:
				if players[player]["coin"] >= business["startup_price"]:
					players[player]["coin"] -= business["startup_price"]
					players[player]["businesses"][businessName] = {"level": 1}
					return player + " bought " + businessName
				return "Not enough money."
			return "Level too low."
		return "You already own this business type. Use !biz info"
	return "Invalid business name."

# Sell a business
func sellBusiness(player, businessName):
	if players[player]["businesses"].has(businessName):
		var sell_price = 100  # Example
		players[player]["coin"] += sell_price
		players[player]["businesses"].erase(businessName)
		return player + " sold " + businessName
	return "You don't own this business."

# Reinvest in business
func reinvestBusiness(player, businessName):
	if players[player]["businesses"].has(businessName):
		var upgrade_cost = calculateUpgradeCost(player, businessName)
		if players[player]["coin"] >= upgrade_cost:
			players[player]["coin"] -= upgrade_cost
			players[player]["businesses"][businessName]["level"] += 1
			return player + " upgraded " + businessName
		else:
			return "Not enough money."
	return "You don't own this business."

# Business info
func businessInfo(player, businessName):
	if players[player]["businesses"].has(businessName):
		var level = players[player]["businesses"][businessName]["level"]
		var upgrade_cost = calculateUpgradeCost(player, businessName)
		var income = calculateIncome(player, businessName)
		return businessName + " Info: [Level: " + str(level) + ", Upgrade Cost: " + str(upgrade_cost) + ", Periodic Yield: " + str(income) + "]"
	return "You don't own this business."

# Calculate upgrade cost
func calculateUpgradeCost(player, businessName):
	if players[player]["businesses"].has(businessName):
		var level = players[player]["businesses"][businessName]["level"]
		var base_cost = businesses[businessName]["startup_price"]
		var upgrade_cost = base_cost * pow(1.15, level)
		return int(upgrade_cost)
	return 0  # Placeholder

# Calculate income
func calculateIncome(player, businessName):
	if players[player]["businesses"].has(businessName):
		var level = players[player]["businesses"][businessName]["level"]
		var base_yield = businesses[businessName]["startup_price"] * 0.1
		var income = base_yield * pow(1.07, level)
		return int(income)
	return 0  # Placeholder

# Connected to the Timer's timeout signal
func _on_IncomeTimer_timeout():
	for player in players.keys():
		var total_income = 0
		for businessName in players[player]["businesses"].keys():
			var income = calculateIncome(player, businessName)
			total_income += income
		players[player]["coin"] += total_income

###DICE
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
				diceBattle(from_player, player, roll1, roll2)
				var winner = ""
				if roll1 > roll2:
					winner = from_player
				elif roll2 > roll1:
					winner = player
				else:
					return "It's a tie!"
				players[from_player if winner == player else player]["coin"] -= amount
				pickupCoin(winner, amount)
				pending_dices.erase(player) # sadece atılan ilk istek de silinebilir.
				return from_player+" rolled "+str(roll1)+", "+player+" rolled "+str(roll2)+". "+winner+" wins "+str(amount * 2)+" coins!"
			return from_player+" does not have enough coins to accept the dice roll."
		return player+" does not have enough coins to accept the dice roll."
	return "No pending dice request."


func diceBattle(attacker, defender, atkrol, defrol):
	var diceinstance = dicebattle.instantiate()
	diceinstance.attacker = attacker
	diceinstance.defender = defender
	diceinstance.atkrol = atkrol
	diceinstance.defrol = defrol
	add_child(diceinstance)

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
	Cash: "+str(floor(players[sender]["coin"]))+"$, 
	Level: "+str(players[sender]["level"])+", 
	Exp: "+str(round(players[sender]["exp"]))+"/"+str(toNextLevel)+"."
	return stats

func playerAttack(player):
	var destroyed = whale.attack(players[player]["items"].has("kozmetik"))
	var multiplier = players[player]["upgrades"]["attack"]
	var attackLevel = players[player]["level"] * multiplier
	var getGold = destroyed * attackLevel ## destroyed ** 2 olurmu?
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
	fadePopup(player + " " + str(round(players[player]["coin"])) + "$", true, player)

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

func sendCoins(from, to, amount):
	if players[from]["coin"] >= amount:
		players[from]["coin"] -= amount
		players[to]["coin"] += amount
		return from+" donated "+to+" "+str(amount)
	return from+" fakirsin."

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

func addInterest():
	for player in players:
		players[player]["coin"] += players[player]["coin"]*players[player]["upgrades"]["bank"] / 10000

func popup(text):
	var pop = popupscene.instantiate()
	pop.text = text
	add_child(pop)

func fadePopup(text, below = false, player = null):
	var pop = fadepopupscene.instantiate()
	pop.text = text
	pop.below = below
	if player:
		pop.player = player
	add_child(pop)

func userSubscribed(user):
	Speak.text("Welcome "+user+" adamsın")

var selectedstat

func get_top_players(stat_tag: String) -> String:
	selectedstat = stat_tag
	var sorted_players: Array = []

	# Create an array of dictionaries with 'playername' and the specific stat
	for player in players.keys():
		var dict_entry: Dictionary = {
			"playername": player,
			selectedstat: players[player][stat_tag]
		}
		sorted_players.append(dict_entry)

	# Sort the array in descending order based on the selected stat
	sorted_players.sort_custom(compare_stats_desc)
	sorted_players.reverse()
	return str(sorted_players)

# Custom comparison function for sorting in descending order
func compare_stats_desc(a: Dictionary, b: Dictionary) -> int:
	var diff = float(b[selectedstat]) - float(a[selectedstat])
	if diff > 0.0:
		return -1
	elif diff < 0.0:
		return 1
	else:
		return 0

