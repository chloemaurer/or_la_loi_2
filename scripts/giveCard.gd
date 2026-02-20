extends Control

@onready var emplacements = [
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur1, "label": $VBoxContainer/Joueurs/Joueurs/Joueur1/Nomjoueur1},
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur2, "label": $VBoxContainer/Joueurs/Joueurs/Joueur2/Nomjoueur2},
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur3, "label": $VBoxContainer/Joueurs/Joueurs/Joueur3/Nomjoueur3}
]

var cible_choisie_id : String = ""


func remplir_selection(tous_les_profils: Array, mon_id_actuel: String) -> void:
	var index_slot = 0
	cible_choisie_id = "" # Reset de la sélection précédente

	# 1. On cache tous les slots au départ
	for s in emplacements:
		s.rect.hide()

	# 2. On boucle sur les 4 profils reçus
	for i in range(tous_les_profils.size()):
		var id_adversaire = str(i)
		
		# SI l'ID est celui du joueur actuel, on l'ignore (on ne se bat pas contre soi-même)
		if id_adversaire == mon_id_actuel:
			continue
		
		if index_slot < emplacements.size():
			var slot = emplacements[index_slot]
			var profil_data = tous_les_profils[i]
			
			# --- RÉCUPÉRATION DU NOM ---
			slot.label.text = profil_data.nom_joueur.text
			
			# --- RÉCUPÉRATION DE L'ICÔNE (Méthode fiable) ---
			if profil_data.player_icone and profil_data.player_icone.texture:
				slot.rect.texture = profil_data.player_icone.texture
			else:
				# Sécurité : on pioche dans le tableau si le visuel n'est pas encore prêt
				slot.rect.texture = profil_data.personnages[i]["sprite"]

			# --- GESTION DU CLIC (Déconnexion propre puis connexion) ---
			if slot.rect.gui_input.is_connected(_on_adversaire_clique):
				slot.rect.gui_input.disconnect(_on_adversaire_clique)
			slot.rect.gui_input.connect(_on_adversaire_clique.bind(index_slot))
			
			# --- METADATA ET AFFICHAGE ---
			slot.rect.set_meta("joueur_id", id_adversaire)
			
			# OPTIONNEL : Si le joueur est mort, on rend son icône grise aussi dans le menu
			slot.rect.modulate = profil_data.modulate
			slot.rect.show()
			index_slot += 1

func _on_adversaire_clique(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		var slot_clique = emplacements[index]
		
		print("[Duel] Clic détecté sur Slot ", index)
		
		if slot_clique.rect.has_meta("joueur_id"):
			var nouvelle_cible = str(slot_clique.rect.get_meta("joueur_id"))
	
	# 1. RÉINITIALISATION : On enlève le shader de TOUT LE MONDE
			for slot in emplacements:
				var tr : TextureRect = slot.rect
				if tr.material is ShaderMaterial:
					tr.material.set("shader_parameter/thickness", 0.0)

	# 2. LOGIQUE DE TOGGLE : 
	# Si on clique sur celui qui est déjà sélectionné, on le désactive (Toggle Off)
			if cible_choisie_id == nouvelle_cible:
				cible_choisie_id = "" # On vide la sélection
				print("[Duel] Sélection annulée.")
			else:
				# Sinon, on active le nouveau (Toggle On)
				cible_choisie_id = nouvelle_cible
				var texture_rect : TextureRect = slot_clique.rect
				if texture_rect.material is ShaderMaterial:
					texture_rect.material.set("shader_parameter/thickness", 5.0)
		
			print("[Duel] SUCCÈS : Cible choisie = ", cible_choisie_id)
		else:
			print("[Duel] ERREUR : Le Slot ", index, " n'a pas de Meta joueur_id au moment du clic !")

	

func _on_give_card_pressed() -> void:
	if cible_choisie_id == "":
		DatabaseConfig.notifier_erreur("Sélectionne un allié d'abord !")
		return
	
	# Vérification : Est-ce que la cible est en vie ?
	var idx_cible = int(cible_choisie_id)
	if DatabaseConfig.script_general.profils_noeuds[idx_cible].get_life() <= 0:
		DatabaseConfig.notifier_erreur("Ce joueur est KO, tu ne peux rien lui donner.")
		return

	# 1. Enregistrement de l'ID pour le Singleton
	DatabaseConfig.cible_don_id = cible_choisie_id
	print("[GiveCard] Cible enregistrée : ", DatabaseConfig.cible_don_id)
	
	# 2. Fermeture et ouverture Keypad
	self.hide()
	
	var principal = DatabaseConfig.script_general
	principal.open_current_keypad() 

	# 3. Préparer le keypad
	var id_joueur = int(DatabaseConfig.current_profil_id)
	if principal.keypad.size() > id_joueur:
		principal.keypad[id_joueur].preparer_clavier_pour_don()
	
	# 4. RESET du visuel pour la prochaine fois
	_reset_visuel_selection()

func _reset_visuel_selection():
	cible_choisie_id = ""
	for slot in emplacements:
		var tr : TextureRect = slot.rect
		if tr.material is ShaderMaterial:
			tr.material.set("shader_parameter/thickness", 0.0)
