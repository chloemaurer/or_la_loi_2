extends Control

# --- Player and UI Nodes ---
@onready var profile_nodes = [
	$Profils/Profil,
	$Profils/Profil2,
	$Profils/Profil3,
	$Profils/Profil4
]

@onready var end_turn_buttons = [
	$Profils/Profil/EndTurn1, 
	$Profils/Profil2/EndTurn2, 
	$Profils/Profil3/EndTurn3, 
	$Profils/Profil4/EndTurn4
]

@onready var keypads = [
	$Profils/Profil/Keypad, 
	$Profils/Profil2/Keypad, 
	$Profils/Profil3/Keypad,
	$Profils/Profil4/Keypad
]

@onready var start_labels = [
	$Profils/Profil/StartProfil1,
	$Profils/Profil2/StartProfil2,
	$Profils/Profil3/StartProfil3,
	$Profils/Profil4/StartProfil4
]

# --- Logic Variables ---
var players_ready = [false, false, false, false]
var game_started = false

# --- Map and Shop Nodes ---
@onready var places_controller: Node2D = $Map/Places # places
@onready var restaurant_shop: Control = $Map/RestaurantShop
@onready var saloon_shop: Control = $Map/SaloonShop
@onready var armory: Control = $Map/Armory
@onready var bank: Control = $Map/Bank
@onready var duel: Control = $Map/Duel
@onready var give_card: Control = $Map/GiveCard
@onready var map_container: Control = $Map # map
@onready var start_action_menu: Control = $Map/StartAction # start_action
@onready var mine_event: Control = $Map/Mine # mine
@onready var round_transition_video: VideoStreamPlayer = $Map/RoundTransition
@onready var result_screen: Control = $Map/Result # result
@onready var duel_result_screen: Control = $Map/DuelResult # duel_result
@onready var gift_effect_overlay: Control = $Map/GiveCardEffect # give_card_effect
@onready var map_visual: TextureRect = $Map/Panel2/MapVisual
@onready var sand_storm_video: VideoStreamPlayer = $Map/SandTempest # sand_tempest
@onready var get_resources: AudioStreamPlayer = $Son/GetResources


func _ready() -> void:
	# Reference this script in the global singleton
	DatabaseConfig.script_general = self
	
	# Set references for sub-scripts in the Singleton
	DatabaseConfig.script_saloon = saloon_shop
	DatabaseConfig.script_restaurant = restaurant_shop
	DatabaseConfig.script_bank = bank
	DatabaseConfig.script_armory = armory
	DatabaseConfig.script_duel = duel
	DatabaseConfig.script_don = give_card
	DatabaseConfig.script_result = result_screen
	DatabaseConfig.script_duel_result = duel_result_screen
	DatabaseConfig.script_don_result = gift_effect_overlay
	
	give_card.hide()
	
	# Initialize keypads with cached cards if available
	if DatabaseConfig.cards_cache != null:
		for kp in keypads:
			if is_instance_valid(kp) and kp.has_method("update_catalog"):
				kp.update_catalog("cards", DatabaseConfig.cards_cache)

	# Connect Player Profile UI signals
	for i in range(profile_nodes.size()):
		profile_nodes[i].gui_input.connect(_on_profile_clicked.bind(i))
		end_turn_buttons[i].pressed.connect(_on_end_turn_pressed.bind(i))
		end_turn_buttons[i].hide()

	# Start initialization if DB is ready, otherwise wait for signal
	if DatabaseConfig.is_ready:
		_initialize_game_state()
	else:
		DatabaseConfig.db_ready.connect(_initialize_game_state)

func _initialize_game_state():
	print("[Main] Game ready. Waiting for players to join...")
	places_controller.hide()
	start_action_menu.hide()
	for i in range(profile_nodes.size()):
		profile_nodes[i].modulate = Color(0.5, 0.5, 0.5, 1) 
		if is_instance_valid(start_labels[i]):
			start_labels[i].show()
		
func distribute_data(path: String, data):
	# Refresh visuals for all profiles or a specific stat
	if path == "profils" and typeof(data) == TYPE_DICTIONARY:
		for profile_id in data.keys():
			var index = int(profile_id.replace("ID", ""))
			if index < profile_nodes.size():
				var target = profile_nodes[index]
				var stats = data[profile_id]
				if typeof(stats) == TYPE_DICTIONARY:
					for key in stats.keys():
						target.update_visual(key, stats[key])
	else:
		# Targeted update for specific paths (e.g., "profils/ID0/Vie")
		for i in range(profile_nodes.size()):
			var tag = "ID" + str(i)
			if tag in path:
				var target = profile_nodes[i]
				if typeof(data) == TYPE_DICTIONARY:
					for key in data.keys():
						target.update_visual(key, data[key])
				else:
					var parts = path.split("/")
					var final_key = parts[-1] 
					target.update_visual(final_key, data)
				break

# --- Turn and Round Logic ---

func select_profile(chosen_index: int):
	print("[Main] Switching to active profile: ", chosen_index)
	start_action_menu.show()
	DatabaseConfig.current_profile_id = str(chosen_index)
	DatabaseConfig.actions_done = 0 
	
	# Rotate UI for local players seated on the other side of the screen
	if chosen_index == 2 or chosen_index == 3:
		map_container.rotation_degrees = 180
	else:
		map_container.rotation_degrees = 0
		
	_sync_stats_to_global(chosen_index)
	
	# Update visual focus and turn buttons
	for i in range(profile_nodes.size()):
		if profile_nodes[i].get_life() <= 0:
			profile_nodes[i].modulate.a = 0.3 # Dead player styling
			end_turn_buttons[i].hide()
		elif i == chosen_index:
			profile_nodes[i].modulate = Color(1, 1, 1, 1) # Active
			end_turn_buttons[i].disabled = false
			end_turn_buttons[i].show()
		else:
			profile_nodes[i].modulate = Color(0.3, 0.3, 0.3, 1) # Dimmed
			end_turn_buttons[i].disabled = true
			end_turn_buttons[i].hide()
			
func _sync_stats_to_global(index: int):
	var target = profile_nodes[index]
	
	# Small safety delay to ensure nodes are fully updated
	if not is_instance_valid(target) or not target.has_method("get_life"):
		await get_tree().process_frame
		_sync_stats_to_global(index)
		return

	DatabaseConfig.local_life = target.get_life()
	DatabaseConfig.local_food = target.get_food()
	DatabaseConfig.local_drink = target.get_drink()
	DatabaseConfig.local_money = target.get_money()
	DatabaseConfig.local_munition = target.get_munition()
	DatabaseConfig.current_gun_level = target.get_gun()
	
func _on_end_turn_pressed(current_index: int):
	
	var next_profile = (current_index + 1) % profile_nodes.size()
	var attempts = 0
	var lone_survivor = false

	# Find next alive player
	while profile_nodes[next_profile].get_life() <= 0 and attempts < profile_nodes.size():
		next_profile = (next_profile + 1) % profile_nodes.size()
		attempts += 1
		
	if next_profile == current_index:
		lone_survivor = true
		
	# New Round Detection (when the cycle returns to 0 or lone survivor finishes)
	if next_profile <= current_index or lone_survivor:
		DatabaseConfig.current_round += 1
		round_transition_video.show()
		round_transition_video.play()
		get_resources.play()
		_consume_round_resources()
		
		# Update visual round counters
		if has_node("Manches"): $Manches.update_train_display()
		if has_node("Manches2"): $Manches2.update_train_display()
		
		# Trigger End Game Event
		if DatabaseConfig.current_round >= 11:
			start_action_menu.hide()
			places_controller.hide()
			places_controller.close_all()
			DatabaseConfig.actions_done = 0 
			mine_event.show()
			return 
			
	# Move to next turn
	select_profile(next_profile)
	places_controller.show()
	places_controller.close_all()
	places_controller.close_place()
		
	if restaurant_shop: restaurant_shop.randomize_food()
	if saloon_shop: saloon_shop.randomize_drink()



func _consume_round_resources():
	for i in range(profile_nodes.size()):
		var player = profile_nodes[i]
		var id_str = str(i)
		
		# On ne traite que les joueurs vivants
		if player.get_life() > 0:
			# 1. Tout le monde perd 1 ressource
			DatabaseConfig.get_food(-1, id_str)
			DatabaseConfig.get_drink(-1, id_str)
			
			# 2. On attend un tout petit peu que les stats soient à jour (optionnel mais plus sûr)
			# 3. Vérification immédiate de la famine/soif
			var damage = 0
			if player.get_food() <= 0: damage += 1
			if player.get_drink() <= 0: damage += 1
				
			if damage > 0:
				# Perte de vie
				DatabaseConfig.lose_life(damage, id_str)
				
				# Secours d'urgence : on remet à 2 ressources
				# On calcule combien ajouter pour arriver exactement à 2
				var food_to_add = 2 - player.get_food()
				var drink_to_add = 2 - player.get_drink()
				DatabaseConfig.get_food(food_to_add, id_str)
				DatabaseConfig.get_drink(drink_to_add, id_str)
				
			# 4. Si le joueur n'a plus de vie après la punition
			if player.get_life() <= 0:
				kill_player(i)


func kill_player(index: int):
	var target = profile_nodes[index]
	var id_str = str(index)
	target.modulate.a = 0.5
	# Reset resources for dead players
	DatabaseConfig.get_food(-5, id_str) 
	DatabaseConfig.get_drink(-5, id_str)
	DatabaseConfig.players_alive -= 1
	end_turn_buttons[index].hide()

func check_action_limit():
	if DatabaseConfig.actions_done >= 2:
		DatabaseConfig.notify_error("Limite d'action atteinte pour votre tour")
		places_controller.close_all() 
		places_controller.hide()

# --- Interaction Handlers ---

func _on_profile_clicked(event: InputEvent, index: int):
	if game_started: return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not players_ready[index]:
			players_ready[index] = true
			profile_nodes[index].modulate = Color(1, 1, 1, 1)
			if is_instance_valid(start_labels[index]):
				start_labels[index].hide()

	_check_all_players_ready()

func _check_all_players_ready():
	if not players_ready.has(false):
		game_started = true
		for i in range(profile_nodes.size()):
			if profile_nodes[i].gui_input.is_connected(_on_profile_clicked):
				profile_nodes[i].gui_input.disconnect(_on_profile_clicked)
		select_profile(0)

func _on_duel_pressed() -> void:
	var my_id = DatabaseConfig.current_profile_id
	if is_instance_valid(duel) and duel.has_method("fill_selection"):
		duel.fill_selection(profile_nodes, my_id)
		duel.show()
	
func _open_current_keypad():
	if DatabaseConfig.actions_done >= 2: return
		
	var my_id = int(DatabaseConfig.current_profile_id)
	if my_id < keypads.size():
		var current_keypad = keypads[my_id]
		if is_instance_valid(current_keypad):
			current_keypad.show()

# --- Zone UI Triggers ---

func _on_saloon_use_card_pressed() -> void:
	DatabaseConfig.current_zone = "saloon"
	_open_current_keypad()

func _on_restaurant_use_card_pressed() -> void:
	DatabaseConfig.current_zone = "restaurant"
	_open_current_keypad()

func _on_armory_use_card_pressed() -> void:
	DatabaseConfig.current_zone = "armurerie"
	_open_current_keypad()

func _on_saloon_give_card_pressed() -> void:
	DatabaseConfig.current_zone = "saloon"
	give_card.fill_selection(profile_nodes, DatabaseConfig.current_profile_id)
	give_card.show()

func _on_restaurant_give_card_pressed() -> void:
	DatabaseConfig.current_zone = "restaurant"
	give_card.fill_selection(profile_nodes, DatabaseConfig.current_profile_id)
	give_card.show()

func _on_round_transition_finished() -> void:
	round_transition_video.hide()
	# Mid-game visual update (Round 6)
	if DatabaseConfig.current_round == 6:
		sand_storm_video.show()
		sand_storm_video.play()
		map_visual.texture = preload("uid://b8lqmhaiis554")
