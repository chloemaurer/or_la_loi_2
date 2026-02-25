extends Control
@onready var fin_mini_jeux: AudioStreamPlayer = $"../../Son/FinMiniJeux"

@onready var icon_winner = [
$"Control/VBoxContainer/1er/Icon", $"Control/VBoxContainer/2eme/Icon", $"Control/VBoxContainer/3eme/Icon", $"Control/VBoxContainer/4eme/Icon"
]

@onready var time_winner = [
	$"Control/VBoxContainer/1er/Time", $"Control/VBoxContainer/2eme/Time", $"Control/VBoxContainer/3eme/Time", $"Control/VBoxContainer/4eme/Time"
]
func _ready() -> void:
	self.hide()

func afficher_resultats(scores_bruts: Array):
	fin_mini_jeux.play()
	# 1. Sécurité : On s'assure que le tableau n'est pas vide
	if scores_bruts.is_empty(): 
		return
	
	# 2. Trier les scores (du plus petit temps au plus grand)
	# On utilise ["temps"] car ce sont des dictionnaires venant de DatabaseConfig
	scores_bruts.sort_custom(func(a, b): return float(a["temps"]) < float(b["temps"]))
	
	# 3. Parcourir les nodes d'affichage
	for i in range(icon_winner.size()):
		if i < scores_bruts.size():
			var data = scores_bruts[i]
			
			# CORRECTION ICI : Accès par clé string ["id"] et ["temps"]
			var id_joueur = int(data["id"])
			var temps_joueur = float(data["temps"])
			
			# Affichage du temps
			time_winner[i].text = "%.2f" % temps_joueur + "s"
			
			# Récupérer l'icône du joueur
			var nodes_profils = DatabaseConfig.script_general.profils_noeuds
			if id_joueur < nodes_profils.size():
				var profil_source = nodes_profils[id_joueur]
				
				if is_instance_valid(profil_source):
					# On cherche le Sprite ou TextureRect du perso
					var sprite = profil_source.get_node_or_null("PlayerIcon/Personnage")
					if sprite:
						icon_winner[i].texture = sprite.texture
			
			icon_winner[i].get_parent().show()
		else:
			icon_winner[i].get_parent().hide()

	self.show()



func _on_fin_mini_jeu_pressed() -> void:
	DatabaseConfig.rewards.emit(DatabaseConfig.donnees_scores)
	self.hide()
