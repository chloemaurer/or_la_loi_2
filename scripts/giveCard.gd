extends Control

# --- Noeuds UI ---
# On définit la liste des emplacements (slots) pour afficher les autres joueurs
@onready var slots = [
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur1, "label": $VBoxContainer/Joueurs/Joueurs/Joueur1/Nomjoueur1},
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur2, "label": $VBoxContainer/Joueurs/Joueurs/Joueur2/Nomjoueur2},
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur3, "label": $VBoxContainer/Joueurs/Joueurs/Joueur3/Nomjoueur3}
]

# --- Variables de Logique ---
var chosen_target_id : String = "" # Stocke l'ID du joueur à qui on veut donner une carte


# Remplit l'interface avec les profils des autres joueurs
func fill_selection(all_profiles: Array, my_current_id: String) -> void:
	var slot_index = 0
	chosen_target_id = "" # Réinitialise la sélection à chaque ouverture du menu

	# Cache tous les slots au départ
	for s in slots:
		s.rect.hide()

	# Parcourt la liste des profils pour trouver les alliés/adversaires
	for i in range(all_profiles.size()):
		var opponent_id = str(i)
		
		# On s'ignore soi-même dans la liste
		if opponent_id == my_current_id:
			continue
		
		if slot_index < slots.size():
			var current_slot = slots[slot_index]
			var profile_data = all_profiles[i]
			
			# Configuration du nom du joueur
			current_slot.label.text = profile_data.player_name.text
			
			# Configuration de l'icône (avec sécurité si l'icône n'est pas chargée)
			if profile_data.player_icon and profile_data.player_icon.texture:
				current_slot.rect.texture = profile_data.player_icon.texture
			else:
				current_slot.rect.texture = profile_data.characters[i]["sprite"]

			# Gestion des signaux : déconnecte l'ancien signal pour éviter les doubles clics
			if current_slot.rect.gui_input.is_connected(_on_opponent_clicked):
				current_slot.rect.gui_input.disconnect(_on_opponent_clicked)
			current_slot.rect.gui_input.connect(_on_opponent_clicked.bind(slot_index))
			
			# Stocke l'ID en métadonnée et applique la transparence (si le joueur est mort)
			current_slot.rect.set_meta("player_id", opponent_id)
			current_slot.rect.modulate = profile_data.modulate
			current_slot.rect.show()
			slot_index += 1

# Gère le clic sur un portrait pour sélectionner le destinataire
func _on_opponent_clicked(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		var clicked_slot = slots[index]
		
		if clicked_slot.rect.has_meta("player_id"):
			var new_target = str(clicked_slot.rect.get_meta("player_id"))
	
			# Désactive l'effet de surbrillance (outline) sur tous les joueurs
			for slot in slots:
				var tr : TextureRect = slot.rect
				if tr.material is ShaderMaterial:
					tr.material.set("shader_parameter/thickness", 0.0)

			# Système de bascule : si on reclique sur le même, on désélectionne
			if chosen_target_id == new_target:
				chosen_target_id = "" 
				print("[Don] Sélection annulée.")
			else:
				# Sinon, on sélectionne et on active l'effet visuel (outline)
				chosen_target_id = new_target
				var texture_rect : TextureRect = clicked_slot.rect
				if texture_rect.material is ShaderMaterial:
					texture_rect.material.set("shader_parameter/thickness", 5.0)
		
			print("[Don] Cible choisie = ", chosen_target_id)

# Valide le choix et passe à l'étape du choix de la carte
func _on_give_card_pressed() -> void:
	if chosen_target_id == "":
		DatabaseConfig.notify_error("Sélectionner un adversaire d'abord")
		return
	
	# Vérifie si le joueur cible est toujours en vie
	var target_idx = int(chosen_target_id)
	if DatabaseConfig.script_general.profile_nodes[target_idx].get_life() <= 0:
		DatabaseConfig.notify_error("Ce joueur est mort vous ne pouvez pas l'affronter")
		return

	# 1. Enregistre l'ID de la cible dans le Singleton pour que le Keypad le sache
	DatabaseConfig.gift_target_id = chosen_target_id
	print("[Don] Cible enregistrée : ", DatabaseConfig.gift_target_id)
	
	# 2. Ferme ce menu et ouvre le Keypad (pavé numérique)
	self.hide()
	
	var main_script = DatabaseConfig.script_general
	main_script._open_current_keypad() 

	# 3. Prépare le Keypad en mode "Don" pour modifier son comportement de validation
	var player_id = int(DatabaseConfig.current_profile_id)
	if main_script.keypads.size() > player_id:
		main_script.keypads[player_id].prepare_keypad_for_gift()
	
	# 4. Réinitialise le visuel pour la prochaine utilisation
	_reset_selection_visuals()

# Nettoie les effets visuels de sélection
func _reset_selection_visuals():
	chosen_target_id = ""
	for slot in slots:
		var tr : TextureRect = slot.rect
		if tr.material is ShaderMaterial:
			tr.material.set("shader_parameter/thickness", 0.0)
