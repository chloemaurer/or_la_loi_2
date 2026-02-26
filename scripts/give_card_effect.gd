extends Control

# --- UI Nodes ---
@onready var giver_icon: TextureRect = $Control/HBoxContainer/GivePlayer # give_player
@onready var effect_label: Label = $Control/HBoxContainer/VBoxContainer/HBoxContainer2/Effect # effect
@onready var type_icon: TextureRect = $Control/HBoxContainer/VBoxContainer/HBoxContainer2/Type # type
@onready var receiver_icon: TextureRect = $Control/HBoxContainer/GetPlayer # get_player
@onready var display_timer: Timer = $Timer # timer

# --- Assets ---
const ALCOHOL_ICON = preload("uid://btlu4r2ley4ww") # ALCOOL
const FOOD_ICON = preload("uid://jpvdd31q8et") # NOURRITURE

func _ready() -> void:
	self.hide()

# Cette fonction est appelée par le dispatcher ou le script de résultat de don
func show_gift_effect(giver_id: String, receiver_id: String, effect_value: int, zone: String):
	# 1. Récupération des icônes des joueurs via le script général
	var profile_nodes = DatabaseConfig.script_general.profile_nodes
	
	var idx_giver = int(giver_id)
	var idx_receiver = int(receiver_id)
	
	if profile_nodes.size() > max(idx_giver, idx_receiver):
		# Accès au nœud Personnage à l'intérieur de l'icône du profil
		giver_icon.texture = profile_nodes[idx_giver].get_node("PlayerIcon/Personnage").texture
		receiver_icon.texture = profile_nodes[idx_receiver].get_node("PlayerIcon/Personnage").texture

	# 2. Configuration du texte de l'effet
	effect_label.text = str(effect_value)
	
	# Logique selon la zone pour l'icône de type (Alcool ou Nourriture)
	if zone == "saloon":
		type_icon.texture = ALCOHOL_ICON
	elif zone == "restaurant":
		type_icon.texture = FOOD_ICON
	else:
		# Optionnel : icône par défaut
		type_icon.texture = null 

	# 3. Animation et affichage
	self.show()
	display_timer.start()

func _on_timer_timeout() -> void:
	self.hide()
