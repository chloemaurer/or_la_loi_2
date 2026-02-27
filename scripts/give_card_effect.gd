extends Control

# --- Noeuds UI ---
# On récupère les icônes du donneur, du receveur et les labels d'effets
@onready var giver_icon: TextureRect = $Control/HBoxContainer/GivePlayer
@onready var effect_label: Label = $Control/HBoxContainer/VBoxContainer/HBoxContainer2/Effect
@onready var type_icon: TextureRect = $Control/HBoxContainer/VBoxContainer/HBoxContainer2/Type
@onready var receiver_icon: TextureRect = $Control/HBoxContainer/GetPlayer
@onready var display_timer: Timer = $Timer

# --- Ressources Visuelles ---
# Icônes pour différencier visuellement l'alcool de la nourriture
const ALCOHOL_ICON = preload("uid://btlu4r2ley4ww")
const FOOD_ICON = preload("uid://jpvdd31q8et")

func _ready() -> void:
	# On cache le menu de résultat au démarrage
	self.hide()

# Fonction appelée pour afficher qui a donné quoi à qui
func show_gift_effect(giver_id: String, receiver_id: String, effect_value: int, zone: String):
	# 1. Récupération dynamique des portraits des joueurs
	# On accède aux profils stockés dans le script général pour afficher les bons visuels
	var profile_nodes = DatabaseConfig.script_general.profile_nodes
	
	var idx_giver = int(giver_id)
	var idx_receiver = int(receiver_id)
	
	if profile_nodes.size() > max(idx_giver, idx_receiver):
		# On va chercher la texture du personnage pour le donneur et le receveur
		giver_icon.texture = profile_nodes[idx_giver].get_node("PlayerIcon/Personnage").texture
		receiver_icon.texture = profile_nodes[idx_receiver].get_node("PlayerIcon/Personnage").texture

	# 2. Configuration de l'affichage de la ressource
	# Affiche la valeur numérique de l'effet (ex: +2)
	effect_label.text = str(effect_value)
	
	# Sélectionne l'icône appropriée selon la provenance de la carte (Saloon ou Restaurant)
	if zone == "saloon":
		type_icon.texture = ALCOHOL_ICON
	elif zone == "restaurant":
		type_icon.texture = FOOD_ICON
	else:
		# Sécurité si la zone est inconnue
		type_icon.texture = null 

	# 3. Lancement de l'affichage et du compte à rebours avant fermeture
	self.show()
	display_timer.start()

# Ferme automatiquement la notification quand le temps est écoulé
func _on_timer_timeout() -> void:
	self.hide()
