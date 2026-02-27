extends Control

# --- Noeuds UI ---
@onready var end_minigame_sound: AudioStreamPlayer = $"../../Son/FinMiniJeux"
@onready var minigame_sound: AudioStreamPlayer = $"../../Son/Minijeux"

# Tableaux pour gérer les 4 emplacements du classement (podium)
@onready var winner_icons = [
	$"Control/VBoxContainer/1er/Icon", 
	$"Control/VBoxContainer/2eme/Icon", 
	$"Control/VBoxContainer/3eme/Icon", 
	$"Control/VBoxContainer/4eme/Icon"
]

@onready var winner_times = [
	$"Control/VBoxContainer/1er/Time", 
	$"Control/VBoxContainer/2eme/Time", 
	$"Control/VBoxContainer/3eme/Time", 
	$"Control/VBoxContainer/4eme/Time"
]

func _ready() -> void:
	# On cache l'écran de résultats au démarrage
	self.hide()

# Fonction appelée par le contrôleur de mini-jeu quand tous les scores sont reçus
func show_results(raw_scores: Array): 
	# Gestion sonore : on coupe la musique du jeu pour le jingle de fin
	minigame_sound.stop()
	end_minigame_sound.play()
	
	# 1. Sécurité : si aucun score n'est présent, on ne fait rien
	if raw_scores.is_empty(): 
		return
	
	# 2. Tri des scores : du temps le plus court (meilleur) au plus long
	# On utilise une fonction personnalisée (lambda) pour comparer la clé "temps"
	raw_scores.sort_custom(func(a, b): return float(a["temps"]) < float(b["temps"]))
	
	# 3. Mise à jour de l'affichage pour chaque ligne du classement
	for i in range(winner_icons.size()):
		if i < raw_scores.size():
			var data = raw_scores[i]
			var player_id = int(data["id"])
			var player_time = float(data["temps"])
			
			# Affichage du temps formaté (ex: 12.45s)
			winner_times[i].text = "%.2f" % player_time + "s"
			
			# Récupération de l'icône du joueur via le script général
			var profile_nodes = DatabaseConfig.script_general.profile_nodes
			if player_id < profile_nodes.size():
				var source_profile = profile_nodes[player_id]
				
				if is_instance_valid(source_profile):
					# On va chercher la texture du personnage dans son profil respectif
					var sprite = source_profile.get_node_or_null("PlayerIcon/Personnage")
					if sprite:
						winner_icons[i].texture = sprite.texture
			
			# On affiche la ligne (Parent du nœud icône)
			winner_icons[i].get_parent().show()
		else:
			# On cache les lignes inutilisées (si moins de 4 joueurs)
			winner_icons[i].get_parent().hide()

	# On affiche enfin le panneau de résultats
	self.show()

# Appelé quand le joueur ferme l'écran de résultats
func _on_fin_mini_jeu_pressed() -> void:
	# Émet un signal global pour distribuer les récompenses basées sur le classement
	DatabaseConfig.rewards_received.emit(DatabaseConfig.scores_data)
	self.hide()
