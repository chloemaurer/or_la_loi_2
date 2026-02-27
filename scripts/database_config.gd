extends Node

# --- Signals ---
signal error_display_requested
signal rewards_received(times)
signal fight_started()
signal db_ready

# --- Core Variables ---
var db_ref : FirebaseDatabaseReference = null
var is_ready : bool = false

# --- Local Player Stats ---
var local_money : int = 0
var local_munition : int = 0
var local_life : int = 0
var local_drink : int = 0
var local_food : int = 0
var current_gun_level : int = 0
var current_profile_id : String = "0"
var gift_target_id : String = "" # Target player ID for GiveCard
var current_zone : String = ""
var current_round : int = 1
var duel_target_id : String = ""
var active_minigame : String = ""
var rewards_distributed : bool = false
var accumulated_scores : Dictionary = {"0": 0.0, "1": 0.0, "2": 0.0, "3": 0.0}
var players_alive : int = 4
var error_message : String = ""

# --- Script References (Assigned by Main) ---
var script_general = null 
var script_saloon = null 
var script_restaurant = null 
var script_bank = null
var script_armory = null
var script_duel = null
var script_don = null
var script_result = null
var script_duel_result = null
var script_don_result = null

# --- Data Caching ---
var cards_cache = null
var scores_data : Array = []

# --- Turn Logic ---
var actions_done : int = 0
const MAX_ACTIONS : int = 2

func _ready() -> void:
	Firebase.Auth.login_succeeded.connect(_on_firebase_auth_login_succeeded)
	Firebase.Auth.login_with_email_and_password("chloe29.maurer@gmail.com", "Yeraci_8")
	rewards_received.connect(_on_rewards_signal_received)
	
func _on_firebase_auth_login_succeeded(_auth):
	print("Firebase Connected. Initializing Global Dispatcher...")
	db_ref = Firebase.Database.get_database_reference("", {})
	db_ref.new_data_update.connect(_on_db_data_update)
	db_ref.patch_data_update.connect(_on_db_data_update)
	is_ready = true
	db_ready.emit()

# --- CENTRAL DATABASE DISPATCHER ---

func _on_db_data_update(resource: FirebaseResource):
	var path = resource.key
	var data = resource.data
	
	if path == null: return

	# 1. Profiles Update
	if path.begins_with("profils") or path == "profils":
		if script_general:
			script_general.distribute_data(path, data)
		_sort_local_data(path, data)
		
		if script_bank and script_bank.has_method("update_interface"):
			script_bank.update_interface()
			
		if script_armory and script_armory.has_method("update_interface"):
			script_armory.update_interface()

	# 2. Saloon Shop
	if path.begins_with("saloon"):
		if script_saloon and typeof(script_saloon) == TYPE_OBJECT:
			var sub_key = path.replace("saloon/", "")
			script_saloon.update_catalog(sub_key, data)

	# 3. Restaurant Shop
	if path.begins_with("restaurant"):
		if script_restaurant and typeof(script_restaurant) == TYPE_OBJECT:
			var sub_key = path.replace("restaurant/", "")
			script_restaurant.update_catalog(sub_key, data)
			
	# 4. Cards Catalog
	if path.begins_with("cartes"):
		cards_cache = data 
		if script_general and script_general.keypads.size() > 0:
			var sub_key = path.replace("cartes/", "")
			for kp in script_general.keypads:
				if is_instance_valid(kp) and kp.has_method("update_catalog"):
					kp.update_catalog(sub_key, data)

	# 5. Minigames & Duels
	if path.begins_with("mini_jeu"):
		_extract_score(path, data)
		var is_duel = false
		if typeof(data) == TYPE_DICTIONARY and data.get("duel") == true:
			is_duel = true

		if duel_target_id != "" or is_duel:
			if check_ready_for_duel():
				finish_duel()

# --- SCORE HELPERS ---

func _extract_score(path: String, data):
	var parts = path.split("/")
	if parts.size() > 1:
		var id_key = parts[1].replace("ID","")
		if typeof(data) == TYPE_DICTIONARY:
			if data.has("temps_duel"):
				accumulated_scores[id_key] = float(data["temps_duel"])
			elif data.has("temps"):
				accumulated_scores[id_key] = float(data["temps"])
		elif typeof(data) in [TYPE_INT, TYPE_FLOAT]:
			accumulated_scores[id_key] = float(data)
		validate_and_distribute_scores()

# --- LOCAL DATA SORTING ---

func _sort_local_data(path: String, data):
	var active_tag = "ID" + current_profile_id
	if path.contains(active_tag):
		_update_local_vars(path, data)
	elif path == "profils" and typeof(data) == TYPE_DICTIONARY:
		if data.has(active_tag):
			_update_local_vars("", data[active_tag])

func _update_local_vars(path: String, data):
	if typeof(data) != TYPE_DICTIONARY:
		if "Argent" in path: local_money = int(data)
		elif "Vie" in path: local_life = int(data)
		elif "Nourriture" in path: local_food = int(data)
		elif "Boisson" in path: local_drink = int(data)
		elif "Munition" in path: local_munition = int(data)
		elif "Arme" in path: current_gun_level = int(data)
	else:
		if data.has("Argent"): local_money = int(data["Argent"])
		if data.has("Vie"): local_life = int(data["Vie"])
		if data.has("Nourriture"): local_food = int(data["Nourriture"])
		if data.has("Boisson"): local_drink = int(data["Boisson"])
		if data.has("Munition"): local_munition = int(data["Munition"])
		if data.has("Arme"): current_gun_level = int(data["Arme"])

# --- TURN LOGIC ---

func can_act() -> bool:
	return actions_done < MAX_ACTIONS

func record_action():
	actions_done += 1
	if actions_done >= MAX_ACTIONS:
		print("No more actions available!")

# --- DATABASE WRITE FUNCTIONS ---

func spend_money(amount: int, profile_id: String) -> bool:
	if local_money >= amount:
		var new_balance = local_money - amount
		var path = "profils/ID" + profile_id
		db_ref.update(path, {"Argent": new_balance})
		return true
	return false

func get_munition(amount_to_add: int, profile_id: String):
	var new_amount = max(0, local_munition + amount_to_add)
	local_munition = new_amount
	var path = "profils/ID" + profile_id
	db_ref.update(path, {"Munition": local_munition})

func get_money(amount: int, profile_id: String):
	var index = int(profile_id)
	if script_general and script_general.profile_nodes.size() > index:
		var target_node = script_general.profile_nodes[index]
		var path = "profils/ID" + profile_id
		var new_total = target_node.get_money() + amount
		
		if target_node.has_method("update_visual"):
			target_node.update_visual("Argent", new_total)
		
		if profile_id == current_profile_id:
			local_money = new_total
		
		db_ref.update(path, {"Argent": new_total})

func get_life(amount: int, profile_id: String):
	var new_total = clampi(local_life + amount, 0, 5)
	var path = "profils/ID" + profile_id
	db_ref.update(path, {"Vie": new_total})

func lose_life(amount: int, profile_id: String):
	var index = int(profile_id)
	if script_general and script_general.profile_nodes.size() > index:
		var target = script_general.profile_nodes[index]
		var current_life = target.get_life() 
		var new_total = clampi(current_life - amount, 0, 5)
		var path = "profils/ID" + profile_id
		db_ref.update(path, {"Vie": new_total})

		if new_total <= 0:
			script_general.kill_player(index)
			if profile_id == current_profile_id:
				print("[Database] Le joueur actif est mort. Passage automatique au suivant.")
				script_general._on_end_turn_pressed(index)
				
func get_drink(val: int, profile_id: String):
	var target_node = script_general.profile_nodes[int(profile_id)]
	var current_val = target_node.get_drink()
	var new_total = clampi(current_val + val, 0, 5)
	var path = "profils/ID" + profile_id
	db_ref.update(path, {"Boisson": new_total})

func get_food(val: int, profile_id: String):
	var target_node = script_general.profile_nodes[int(profile_id)]
	var current_val = target_node.get_food()
	var new_total = clampi(current_val + val, 0, 5)
	var path = "profils/ID" + profile_id
	db_ref.update(path, {"Nourriture": new_total})

func update_gun(val: int, profile_id: String):
	var path = "profils/ID" + profile_id
	if val == 2 && current_gun_level == 1:
		current_gun_level = val
	elif val == 3 && current_gun_level == 2:
		current_gun_level = val
	db_ref.update(path, {"Arme": current_gun_level})

func disable_card(card_id: String):
	var path = "cartes/" + card_id
	db_ref.update(path, {"disponible": false})

# --- MINIGAMES LOGIC ---

func play_minigame(minigame_id: String):
	rewards_distributed = false
	accumulated_scores = {"0": 0.0, "1": 0.0, "2": 0.0, "3": 0.0}
	
	var path = "MiniJeux/" + minigame_id
	db_ref.update(path, {"play": true})
	
	var score_resets = {
		"ID0/temps": 0, "ID1/temps": 0, "ID2/temps": 0, "ID3/temps": 0
	}
	Firebase.Database.get_database_reference("mini_jeu").update("", score_resets)

func _on_rewards_signal_received(results: Array):
	reward_minigame_winners(results)

func reward_minigame_winners(results: Array):
	for i in range(results.size()):
		var player_id = results[i]["id"]
		match i:
			0: get_money(5, player_id) # 1st
			1: get_money(3, player_id) # 2nd
			2: get_money(2, player_id) # 3rd

func validate_and_distribute_scores():
	var temp_results = []
	var survivors_ids = []

	for i in range(4):
		if script_general.profile_nodes[i].get_life() > 0:
			survivors_ids.append(str(i))

	for id_key in survivors_ids:
		if accumulated_scores.has(id_key):
			var t = float(accumulated_scores[id_key])
			if t > 0:
				temp_results.append({"id": id_key, "temps": t})

	if temp_results.size() >= survivors_ids.size() and survivors_ids.size() > 0:
		temp_results.sort_custom(func(a, b): return a["temps"] < b["temps"])
		script_result.show_results(temp_results)	
		scores_data = temp_results.duplicate()
		accumulated_scores = {"0": 0.0, "1": 0.0, "2": 0.0, "3": 0.0} 

# --- DUEL LOGIC ---

func start_duel(attacker_id: String, target_id: String):
	var path_attacker = "mini_jeu/ID" + attacker_id
	var path_target = "mini_jeu/ID" + target_id
	var resets = {"ID0/temps": 0, "ID1/temps": 0, "ID2/temps": 0, "ID3/temps": 0}
	
	if current_profile_id == attacker_id: duel_target_id = target_id
	elif current_profile_id == target_id: duel_target_id = attacker_id
		
	db_ref.update("mini_jeu", resets)
	db_ref.update(path_attacker, {"duel": true})
	db_ref.update(path_target, {"duel": true})

func check_ready_for_duel() -> bool:
	if duel_target_id == "": return false
	if not accumulated_scores.has(current_profile_id) or not accumulated_scores.has(duel_target_id):
		return false
	return float(accumulated_scores[current_profile_id]) > 0.001 and float(accumulated_scores[duel_target_id]) > 0.001

func finish_duel():
	var id_a = current_profile_id
	var id_b = duel_target_id
	var t_a = float(accumulated_scores.get(id_a, 0))
	var t_b = float(accumulated_scores.get(id_b, 0))

	if t_a <= 0 or t_b <= 0: return

	var mun_a = script_general.profile_nodes[int(id_a)].get_munition()
	var mun_b = script_general.profile_nodes[int(id_b)].get_munition()
	
	var faster = id_a if t_a < t_b else id_b
	var slower = id_b if t_a < t_b else id_a
	var mun_faster = mun_a if t_a < t_b else mun_b
	var mun_slower = mun_b if t_a < t_b else mun_a

	var final_winner = ""
	var final_loser = ""
	
	if mun_faster > 0:
		final_winner = faster
		final_loser = slower
	elif mun_slower > 0:
		final_winner = slower
		final_loser = faster
	else:
		_reset_duel_after_combat()
		return

	_subtract_munition_firebase(id_a, mun_a)
	_subtract_munition_firebase(id_b, mun_b)

	var damage = script_general.profile_nodes[int(final_winner)].get_gun()
	if script_duel_result:
		script_duel_result.show_duel_result(int(final_winner), int(final_loser), damage)
	
	lose_life(damage, final_loser)
	_reset_duel_after_combat()

func _subtract_munition_firebase(player_id: String, current_stock: int):
	var new_stock = max(0, current_stock - 1)
	var path = "profils/ID" + player_id
	db_ref.update(path, {"Munition": new_stock})
	if player_id == current_profile_id:
		local_munition = new_stock

func _reset_duel_after_combat():
	accumulated_scores = {"0": 0.0, "1": 0.0, "2": 0.0, "3": 0.0}
	duel_target_id = ""

# --- Error Handling ---

func notify_error(msg: String):
	error_message = msg
	error_display_requested.emit()

# --- Reset Logic ---

func reset_game():
	if db_ref == null: return
	current_round = 1
	actions_done = 0
	current_profile_id = "0"
	players_alive = 4

	for i in range(4):
		var path = "profils/ID" + str(i)
		var data = {"Vie": 5, "Boisson": 5, "Nourriture": 5, "Munition": 0, "Argent": 10, "Arme": 1}
		db_ref.update(path, data)
	
	_reset_all_cards()
	db_ref.update("mini_jeu", {"ID0/temps":0,"ID1/temps":0,"ID2/temps":0,"ID3/temps":0})
	await get_tree().create_timer(1.0).timeout

func _reset_all_cards():
	var big_update = {}
	for i in range(100): big_update["ID" + str(i) + "/disponible"] = true
	db_ref.update("cartes", big_update)
