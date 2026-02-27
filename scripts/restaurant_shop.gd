extends Control

# --- Assets (Textures des plats) ---
# Liste des images pour le "Food Roller" (le visuel qui change aléatoirement)
var food_textures = [
	preload("uid://uquodl1cy3my"), preload("uid://03gr4lta6i66"),
	preload("uid://fcengsh4b1qa"), preload("uid://qiism03hwew0"), 
	preload("uid://b3wf0jsr51id"), preload("uid://wvsewo06pnvq")
]

# --- Noeuds UI ---
@onready var food_roller: TextureRect = $VBoxContainer/FoodRoller
@onready var food_name_label: Label = $VBoxContainer/FoodName
@onready var food_desc_label: Label = $VBoxContainer/FoodDescription
@onready var restaurant_menu: Control = $"../Restaurant" # Menu parent
@onready var money_sound: AudioStreamPlayer = $"../../Son/Money"
@onready var get_resources: AudioStreamPlayer = $"../../Son/GetResources"

# --- Variables de Logique ---
var food_catalog = {} # Données récupérées depuis Firebase (prix, effets, noms)
var current_food_id = 0 # L'index du plat actuellement affiché

func _ready() -> void:
	# On génère un premier plat au hasard dès le chargement
	randomize_food()

# Mise à jour par le Dispatcher (DatabaseConfig)
# Cette fonction synchronise les données locales avec Firebase
func update_catalog(key: String, value):
	if key == "restaurant" and typeof(value) == TYPE_DICTIONARY:
		food_catalog = value
	else:
		food_catalog[key] = value
	
	print("Catalogue Restaurant mis à jour pour : ", key)
	refresh_interface()

# Choisit un plat au hasard dans la liste des assets
func randomize_food() -> void:
	current_food_id = randi() % food_textures.size()
	food_roller.texture = food_textures[current_food_id]
	refresh_interface()

# Met à jour les textes (nom et effet) selon le plat sélectionné
func refresh_interface() -> void:
	var key = "ID" + str(current_food_id)
	if food_catalog.has(key):
		var data = food_catalog[key]
		food_name_label.text = str(data.get("nom", "Inconnu"))
		food_desc_label.text = "Effet : " + str(int(data.get("effet", 0)))

# Gère la transaction financière et l'attribution de la ressource
func process_food_purchase():
	var key = "ID" + str(current_food_id)
	if food_catalog.has(key):
		var data = food_catalog[key] 
		var food_effect = data.get("effet", 0)
		var player_id = DatabaseConfig.current_profile_id
		
		# Le prix est fixe à 1 or (selon ton équilibrage actuel)
		var food_price = 1
		
		print("Restaurant : Tentative d'achat pour le Profil ", player_id)
		
		# 1. On demande au Singleton de dépenser l'argent
		var success = DatabaseConfig.spend_money(food_price, player_id)

		if success:
			money_sound.play()
			print("Restaurant : Achat validé. Application de l'effet : ", food_effect)
			# 2. On ajoute la nourriture au joueur
			DatabaseConfig.get_food(food_effect, player_id)
			get_resources.play()
		else:
			# Feedback en cas de manque de fonds
			DatabaseConfig.notify_error("Achat échoué ! Vous n'avez pas assez d'argent")

# Appelé lors du clic sur le bouton d'achat
func _on_food_buy_card_pressed() -> void:
	process_food_purchase()

# Finalise l'action, consomme un point de tour et ferme la boutique
func _on_get_food_receive_pressed() -> void:
	# On incrémente le compteur global d'actions du tour
	DatabaseConfig.actions_done += 1
	self.hide()
	
	# On prépare déjà le prochain plat pour la prochaine visite
	randomize_food()
	
	# Vérification de la limite d'actions (2 max par tour) via le script général
	if DatabaseConfig.script_general:
		DatabaseConfig.script_general.check_action_limit()
	
	# Si le joueur a encore une action possible, on revient au menu principal du restaurant
	if DatabaseConfig.actions_done < 2:
		restaurant_menu.show()
