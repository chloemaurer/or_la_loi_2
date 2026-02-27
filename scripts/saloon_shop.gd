extends Control

# --- Assets (Textures des boissons) ---
# Contient les images des différentes bouteilles ou verres disponibles
var drink_textures = [
	preload("uid://bmbrqc2cdl5cj"), preload("uid://duq0qpxicvgwe"),
	preload("uid://dbk7n00v8a0jk"), preload("uid://defnlcal2s16u"),
	preload("uid://yntx2g58parc"), preload("uid://djpm3liihmd0r")
]

# --- Noeuds UI ---
@onready var saloon_menu: Control = $"../Saloon"
@onready var drink_roller: TextureRect = $VBoxContainer/DrinkRoller
@onready var drink_name_label: Label = $VBoxContainer/DrinkName
@onready var drink_desc_label: Label = $VBoxContainer/DrinkDescription
@onready var money_sound: AudioStreamPlayer = $"../../Son/Money"
@onready var get_resources: AudioStreamPlayer = $"../../Son/GetResources"

# --- Variables de Logique ---
var drink_catalog = {} # Données provenant de Firebase (noms, effets)
var current_drink_id = 0 # Index de la boisson affichée

func _ready() -> void:
	# On initialise avec une boisson aléatoire à l'ouverture
	randomize_drink()

# Mis à jour par le Dispatcher de DatabaseConfig
# Synchronise les prix et effets du catalogue avec la base de données distante
func update_catalog(key: String, value):
	if key == "saloon" and typeof(value) == TYPE_DICTIONARY:
		drink_catalog = value
	else:
		drink_catalog[key] = value
	
	print("Catalogue Saloon mis à jour pour : ", key)
	refresh_interface()

# Sélectionne une boisson au hasard pour le "Drink Roller"
func randomize_drink() -> void:
	current_drink_id = randi() % drink_textures.size()
	drink_roller.texture = drink_textures[current_drink_id]
	refresh_interface()

# Actualise les étiquettes de nom et de description (effet)
func refresh_interface() -> void:
	var key = "ID" + str(current_drink_id)
	if drink_catalog.has(key):
		var data = drink_catalog[key]
		drink_name_label.text = str(data.get("nom", "Inconnu"))
		drink_desc_label.text = "Effet : +" + str(int(data.get("effet", 0)))

# Gère la transaction financière et l'ajout de la boisson aux stats du joueur
func process_drink_purchase():
	var key = "ID" + str(current_drink_id)
	if drink_catalog.has(key):
		var data = drink_catalog[key] 
		var drink_effect = data.get("effet", 0)
		var player_id = DatabaseConfig.current_profile_id
		
		# Prix standard fixé à 1 pépite/pièce
		var drink_price = 1
		
		print("Saloon : Tentative d'achat pour le Profil ", player_id)
		
		# 1. Vérifie si le joueur a assez d'argent via le Singleton
		var success = DatabaseConfig.spend_money(drink_price, player_id)
		
		if success:
			money_sound.play()
			print("Saloon : Achat validé. Ajout de boisson : ", drink_effect)
			# 2. Crédite la boisson au joueur
			DatabaseConfig.get_drink(drink_effect, player_id)
			get_resources.play()
		else:
			# Feedback d'erreur si le solde est insuffisant
			DatabaseConfig.notify_error("Achat échoué ! Vous n'avez pas assez d'argent")

# Signal lié au bouton d'achat
func _on_drink_buy_card_pressed() -> void:
	process_drink_purchase()

# Termine l'action du Saloon et gère le flux du tour
func _on_get_drink_receive_pressed() -> void:
	# Consomme un point d'action
	DatabaseConfig.actions_done += 1
	self.hide()
	
	# Prépare la prochaine boisson pour le prochain passage
	randomize_drink()
	
	# Vérifie si le joueur a dépassé ses 2 actions autorisées
	if DatabaseConfig.script_general:
		DatabaseConfig.script_general.check_action_limit()
	
	# Si des actions restent disponibles, on retourne au menu du saloon
	if DatabaseConfig.actions_done < 2:
		saloon_menu.show()
