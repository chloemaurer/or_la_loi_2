extends Control

# --- Noeuds UI ---
# On stocke les emplacements (slots) où apparaîtront les adversaires potentiels
@onready var slots = [
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur1, "label": $VBoxContainer/Joueurs/Joueurs/Joueur1/Nomjoueur1},
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur2, "label": $VBoxContainer/Joueurs/Joueurs/Joueur2/Nomjoueur2},
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur3, "label": $VBoxContainer/Joueurs/Joueurs/Joueur3/Nomjoueur3}
]
@onready var duel_start_sound: AudioStreamPlayer = $"../../Son/DuelStart"

# --- Variables de Logique ---
var chosen_target_id : String = "" # ID de l'adversaire actuellement sélectionné

# Remplit l'interface avec les autres joueurs disponibles pour un duel
func fill_selection(all_profiles: Array, my_current_id: String) -> void:
	var slot_index = 0
	chosen_target_id = "" # Réinitialise la sélection à l'ouverture

	# Cache tous les slots par défaut
	for s in slots:
		s.rect.hide()

	# Parcourt la liste de tous les profils de la partie
	for i in range(all_profiles.size()):
		var opponent_id = str(i)
		
		# On ignore mon propre profil (pas de duel contre soi-même)
		if opponent_id == my_current_id:
			continue
		
		# Remplit les 3 slots d'affichage disponibles
		if slot_index < slots.size():
			var current_slot = slots[slot_index]
			var profile_data = all_profiles[i] 
			
			# Récupère le nom et l'icône directement depuis le profil du joueur
			current_slot.label.text = profile_data.player_name.text
			
			if profile_data.player_icon and profile_data.player_icon.texture:
				current_slot.rect.texture = profile_data.player_icon.texture
			else:
				current_slot.rect.texture = profile_data.characters[i]["sprite"]

			# Applique la même apparence que sur le profil (ex: gris si le joueur est mort)
			current_slot.rect.modulate = profile_data.modulate

			# Nettoie et connecte le signal de clic pour chaque adversaire
			if current_slot.rect.gui_input.is_connected(_on_opponent_clicked):
				current_slot.rect.gui_input.disconnect(_on_opponent_clicked)
			current_slot.rect.gui_input.connect(_on_opponent_clicked.bind(slot_index))
			
			# Sauvegarde l'ID du joueur dans les métadonnées du bouton pour le retrouver au clic
			current_slot.rect.set_meta("player_id", opponent_id)
			current_slot.rect.show()
			
			slot_index += 1

# Gère la sélection visuelle quand on clique sur un adversaire
func _on_opponent_clicked(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		var clicked_slot = slots[index]
		
		# Sécurité : empêche de sélectionner un joueur mort (ceux avec une transparence/alpha réduite)
		if clicked_slot.rect.modulate.a < 1.0: 
			DatabaseConfig.notify_error("impossible cet adversaire est mort")
			return
			
		if clicked_slot.rect.has_meta("player_id"):
			var new_target = str(clicked_slot.rect.get_meta("player_id"))
	
			# Réinitialise l'effet de surbrillance (outline) sur tous les slots
			for slot in slots:
				var tr : TextureRect = slot.rect
				if tr.material is ShaderMaterial:
					tr.material.set("shader_parameter/thickness", 0.0)

			# Logique de bascule (Toggle) : si on reclique sur le même, on désélectionne
			if chosen_target_id == new_target:
				chosen_target_id = "" 
				print("[Duel] Sélection annulée.")
			else:
				# Sinon, on sélectionne le nouveau et on active l'outline via le shader
				chosen_target_id = new_target
				var texture_rect : TextureRect = clicked_slot.rect
				if texture_rect.material is ShaderMaterial:
					texture_rect.material.set("shader_parameter/thickness", 5.0)
		
			print("[Duel] Cible choisie = ", chosen_target_id)

# Valide le duel et lance la logique de combat
func _on_versus_pressed() -> void:
	if chosen_target_id == "":
		DatabaseConfig.notify_error("Aucun adversaire sélectionné")
		return
	
	var my_id = DatabaseConfig.current_profile_id
	duel_start_sound.play()
	
	# Lance la procédure de duel dans le Singleton Global
	DatabaseConfig.start_duel(my_id, chosen_target_id)
	
	# Consomme une action de tour
	DatabaseConfig.actions_done += 1
	
	# Vérifie si le tour doit se terminer
	if DatabaseConfig.script_general:
		DatabaseConfig.script_general.check_action_limit()
		
	# Ferme le menu de sélection
	self.hide()
	chosen_target_id = ""
