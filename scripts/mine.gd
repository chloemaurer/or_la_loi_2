extends Control

# --- Logic Variables ---
var current_player_idx := 0 # joueur_actuel

# --- UI Nodes ---
@onready var dice_control: Control = $"../Dés" # dés
@onready var game_over_screen: Control = $"../../FinJeu" # fin_jeu
@onready var pass_turn_button: Button = $Passturn # passturn
@onready var lose_animation: VideoStreamPlayer = $"../../Animations/LoseEnd" # lose_end
@onready var win_animation: VideoStreamPlayer = $"../../Animations/WinEnd" # win_end

func start_mine_event():
	current_player_idx = 0
	_move_to_next_player()

func _move_to_next_player():
	# --- STEP 1: CHECK VICTORY CONDITIONS ---
	if current_player_idx >= 4:
		print("[MINE] All players have finished their turn.")
		DatabaseConfig.current_zone = "" 

		var real_survivors = 0
		# Check if each player has enough resources to survive after the mine
		for p in DatabaseConfig.script_general.profile_nodes:
			var has_life = p.get_life() >= 2 
			var has_drink = p.get_drink() >= 1  
			var has_food = p.get_food() >= 1 
			
			if has_life and has_drink and has_food:
				real_survivors += 1
				DatabaseConfig.notify_error("Vous avez assez de ressources pour rentrer")
			else:
				DatabaseConfig.notify_error("Vous n'avez pas assez de ressources pour rentrer")
				print("Player ", p.name, " lacks resources to survive the aftermath!")
		
		print("MINE: Survivors = ", real_survivors, " | Expected = ", DatabaseConfig.players_alive)

		# Victory only if all alive players made it
		if real_survivors > 0 and real_survivors == DatabaseConfig.players_alive:
			print("CONGRATULATIONS: Collective Victory!")
			display_result(true)
		else:
			print("GAME OVER: Someone stayed behind...")
			display_result(false)
		return

	# --- STEP 2: GET PLAYER PROFILE ---
	var player_profile = DatabaseConfig.script_general.profile_nodes[current_player_idx]

	# 3. DEATH LOGIC: If player is already dead, skip them
	if player_profile.get_life() <= 0:
		current_player_idx += 1
		_move_to_next_player()
		return

	# 4. VISUAL FEEDBACK
	_update_profiles_visuals(current_player_idx)

	# 5. KEYPAD CONFIGURATION
	DatabaseConfig.current_profile_id = str(current_player_idx)
	DatabaseConfig.current_zone = "mine"
	
	var local_keypad = player_profile.keypad
	if is_instance_valid(local_keypad):
		# Connect to the mine_completed signal of the keypad
		if not local_keypad.mine_completed.is_connected(_on_player_finished):
			local_keypad.mine_completed.connect(_on_player_finished)
		local_keypad.prepare_for_mine()

func _update_profiles_visuals(active_id: int):
	# Dim all profiles except the one currently playing
	for i in range(4):
		var p = DatabaseConfig.script_general.profile_nodes[i]
		if i == active_id:
			p.modulate = Color(1, 1, 1, 1) # Full brightness
		else:
			if p.get_life() <= 0:
				p.modulate = Color(0.2, 0.2, 0.2, 0.8) # Dead/Dark
			else:
				p.modulate = Color(0.3, 0.3, 0.3, 1) # Waiting/Dimmed

func _on_player_finished():
	# Disconnect signal from the player who just finished
	var previous_profile = DatabaseConfig.script_general.profile_nodes[current_player_idx]
	if previous_profile.keypad.mine_completed.is_connected(_on_player_finished):
		previous_profile.keypad.mine_completed.disconnect(_on_player_finished)

	current_player_idx += 1
	_move_to_next_player()

func display_result(victory: bool):
	if victory:
		win_animation.show()
		win_animation.play()
	else:
		lose_animation.show()
		lose_animation.play()
		
func _on_button_pressed() -> void:
	dice_control.hide()
	start_mine_event()
	pass_turn_button.show()

func _on_passturn_pressed() -> void:
	# Manual game over / concede
	game_over_screen.display_result(false)
