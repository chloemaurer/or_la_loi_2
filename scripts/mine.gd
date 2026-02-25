extends Control

var joueur_actuel := 0
@onready var dés: Control = $"../Dés"
@onready var fin_jeu: Control = $"../../FinJeu"
@onready var passturn: Button = $Passturn
@onready var lose_end: VideoStreamPlayer = $"../../Animations/LoseEnd"
@onready var win_end: VideoStreamPlayer = $"../../Animations/WinEnd"


func lancer_evenement_mine():
	joueur_actuel = 0
	_passer_au_joueur_suivant()

func _passer_au_joueur_suivant():
	# --- ÉTAPE 1 : VÉRIFICATION DE LA VICTOIRE (MODIFIÉE) ---
	if joueur_actuel >= 4:
		print("[MINE] Tous les joueurs ont fini leur tour.")
		DatabaseConfig.zone = "" 

		var survivants_reels = 0
		for p in DatabaseConfig.script_general.profils_noeuds:
			var a_vie = p.get_life() >= 2 
			var a_boisson = p.get_drink() >= 1  
			var a_nourriture = p.get_food() >= 1 
			
			if a_vie and a_boisson and a_nourriture:
				survivants_reels += 1
				DatabaseConfig.notifier_erreur("Vous avez assez de ressource pour rentrer")
			else:
				DatabaseConfig.notifier_erreur("Vous n'avez pas assez de ressource pour rentrer")
				print("Joueur ", p.name, " n'a pas assez de ressources pour survivre à l'après-mine !")
		
		print("MINE : Survivants = ", survivants_reels, " | Attendus = ", DatabaseConfig.players_alive)

		if survivants_reels > 0 and survivants_reels == DatabaseConfig.players_alive:
			print("FÉLICITATIONS : Victoire collective !")
			afficher_resultat(true)
		else:
			print("DOMMAGE : Quelqu'un est resté au fond...")
			afficher_resultat(false)
		return

	# --- ÉTAPE 2 : RÉCUPÉRATION DU PROFIL (GARDER LA SUITE) ---
	var profil_du_joueur = DatabaseConfig.script_general.profils_noeuds[joueur_actuel]

	# 3. LOGIQUE DES MORTS : Si le joueur est déjà mort avant, on passe
	if profil_du_joueur.get_life() <= 0:
		joueur_actuel += 1
		_passer_au_joueur_suivant()
		return

	# 4. GESTION VISUELLE
	_actualiser_visuel_profils(joueur_actuel)

	# 5. CONFIGURATION ET OUVERTURE KEYPAD
	DatabaseConfig.current_profil_id = str(joueur_actuel)
	DatabaseConfig.zone = "mine"
	
	var keypad_local = profil_du_joueur.keypad
	if is_instance_valid(keypad_local):
		if not keypad_local.mine_terminee.is_connected(_on_joueur_a_fini):
			keypad_local.mine_terminee.connect(_on_joueur_a_fini)
		keypad_local.preparer_pour_mine()

func _actualiser_visuel_profils(id_actif: int):
	# On parcourt tous les profils pour les griser, sauf celui qui doit jouer
	for i in range(4):
		var p = DatabaseConfig.script_general.profils_noeuds[i]
		if i == id_actif:
			p.modulate = Color(1, 1, 1, 1) # Allumé
		else:
			# On le grise (plus sombre s'il est mort, un peu moins s'il attend juste son tour)
			if p.get_life() <= 0:
				p.modulate = Color(0.2, 0.2, 0.2, 0.8) # Mort
			else:
				p.modulate = Color(0.3, 0.3, 0.3, 1) # En attente

func _on_joueur_a_fini():
	# déconnexion signal ancien joueur
	var profil_precedent = DatabaseConfig.script_general.profils_noeuds[joueur_actuel]
	if profil_precedent.keypad.mine_terminee.is_connected(_on_joueur_a_fini):
		profil_precedent.keypad.mine_terminee.disconnect(_on_joueur_a_fini)

	joueur_actuel += 1
	_passer_au_joueur_suivant()

func afficher_resultat(victoire: bool):
	if victoire:
		win_end.show()
		win_end.play()
		
	else:
		lose_end.show()
		lose_end.play()
		
		
func _on_button_pressed() -> void:
	dés.hide()
	lancer_evenement_mine()
	passturn.show()
	

func _on_passturn_pressed() -> void:
	fin_jeu.afficher_resultat(false)
