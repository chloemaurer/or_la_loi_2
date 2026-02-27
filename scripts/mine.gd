extends Control

# --- Variables de Logique ---
var current_player_idx := 0 # Index du joueur en train de passer son test de survie

# --- Noeuds UI ---
@onready var dice_control: Control = $"../Dés"
@onready var game_over_screen: Control = $"../../FinJeu"
@onready var pass_turn_button: Button = $Passturn
@onready var lose_animation: VideoStreamPlayer = $"../../Animations/LoseEnd"
@onready var win_animation: VideoStreamPlayer = $"../../Animations/WinEnd"

# Initialise l'événement de la mine
func start_mine_event():
	current_player_idx = 0
	_move_to_next_player()

# Gère le passage d'un joueur à l'autre et vérifie la victoire à la fin
func _move_to_next_player():
	# --- ÉTAPE 1 : VÉRIFICATION DE LA VICTOIRE (Fin de liste) ---
	if current_player_idx >= 4:
		print("[MINE] Tous les joueurs ont terminé.")
		DatabaseConfig.current_zone = "" 

		var real_survivors = 0
		# Vérifie si chaque joueur vivant a assez de ressources (PV, Boisson, Nourriture)
		for p in DatabaseConfig.script_general.profile_nodes:
			var has_life = p.get_life() >= 2 
			var has_drink = p.get_drink() >= 1  
			var has_food = p.get_food() >= 1 
			
			if has_life and has_drink and has_food:
				real_survivors += 1
				DatabaseConfig.notify_error("Vous avez assez de ressources pour rentrer")
			else:
				# Si un seul joueur manque de ressources, c'est l'échec collectif
				DatabaseConfig.notify_error("Vous n'avez pas assez de ressources pour rentrer")
		
		# La victoire est collective : tous les joueurs en vie doivent avoir réussi
		if real_survivors > 0 and real_survivors == DatabaseConfig.players_alive:
			display_result(true)
		else:
			display_result(false)
		return

	# --- ÉTAPE 2 : RÉCUPÉRATION DU PROFIL ---
	var player_profile = DatabaseConfig.script_general.profile_nodes[current_player_idx]

	# Si le joueur est déjà mort, on passe directement au suivant
	if player_profile.get_life() <= 0:
		current_player_idx += 1
		_move_to_next_player()
		return

	# --- ÉTAPE 3 : MISE À JOUR VISUELLE ---
	# Met en avant le joueur actif et grise les autres
	_update_profiles_visuals(current_player_idx)

	# --- ÉTAPE 4 : CONFIGURATION DU KEYPAD ---
	DatabaseConfig.current_profile_id = str(current_player_idx)
	DatabaseConfig.current_zone = "mine"
	
	var local_keypad = player_profile.keypad
	if is_instance_valid(local_keypad):
		# Connecte le signal "mine_completed" pour savoir quand le joueur a fini de donner ses cartes
		if not local_keypad.mine_completed.is_connected(_on_player_finished):
			local_keypad.mine_completed.connect(_on_player_finished)
		local_keypad.prepare_for_mine()

# Gère la modulation (opacité/couleur) des profils pour le feedback visuel
func _update_profiles_visuals(active_id: int):
	for i in range(4):
		var p = DatabaseConfig.script_general.profile_nodes[i]
		if i == active_id:
			p.modulate = Color(1, 1, 1, 1) # Lumineux
		else:
			if p.get_life() <= 0:
				p.modulate = Color(0.2, 0.2, 0.2, 0.8) # Mort
			else:
				p.modulate = Color(0.3, 0.3, 0.3, 1) # En attente

# Appelé quand le Keypad confirme que le joueur a validé ses cartes
func _on_player_finished():
	var previous_profile = DatabaseConfig.script_general.profile_nodes[current_player_idx]
	if previous_profile.keypad.mine_completed.is_connected(_on_player_finished):
		previous_profile.keypad.mine_completed.disconnect(_on_player_finished)

	current_player_idx += 1
	_move_to_next_player()

# Affiche la vidéo de fin (Gagné ou Perdu)
func display_result(victory: bool):
	if victory:
		win_animation.show()
		win_animation.play()
	else:
		lose_animation.show()
		lose_animation.play()
		
# Lance l'événement quand on clique sur le bouton Mine (après le tour 6)
func _on_button_pressed() -> void:
	dice_control.hide()
	start_mine_event()
	pass_turn_button.show()

# Permet d'abandonner ou de forcer la fin
func _on_passturn_pressed() -> void:
	game_over_screen.display_result(false)
