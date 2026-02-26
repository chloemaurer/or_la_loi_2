extends Control

@onready var give_player: TextureRect = $Control/HBoxContainer/GivePlayer
@onready var effect: Label = $Control/HBoxContainer/VBoxContainer/HBoxContainer2/Effect
@onready var type: TextureRect = $Control/HBoxContainer/VBoxContainer/HBoxContainer2/Type
@onready var get_player: TextureRect = $Control/HBoxContainer/GetPlayer
@onready var timer: Timer = $Timer


const ALCOOL = preload("uid://btlu4r2ley4ww")
const NOURRITURE = preload("uid://jpvdd31q8et")

func afficher_don(id_donneur: String, id_receveur: String, valeur_effet: int, zone: String):
	# 1. Récupération des icônes des joueurs
	var nodes = DatabaseConfig.script_general.profils_noeuds
	
	var idx_donneur = int(id_donneur)
	var idx_receveur = int(id_receveur)
	
	if nodes.size() > max(idx_donneur, idx_receveur):
		give_player.texture = nodes[idx_donneur].get_node("PlayerIcon/Personnage").texture
		get_player.texture = nodes[idx_receveur].get_node("PlayerIcon/Personnage").texture

	# 2. Configuration de l'effet et du type d'icône
	effect.text = str(valeur_effet)
	
	# Logique selon la zone (Saloon ou Restaurant/Taverne)
	if zone == "saloon":
		type.texture = ALCOOL
	elif zone == "restaurant":
		type.texture = NOURRITURE
	else:
		# Optionnel : une icône par défaut si c'est de l'argent ou de la vie
		type.texture = null 

	# 3. Animation et affichage
	self.show()
	timer.start()
	

func _on_timer_timeout() -> void:
	self.hide()
