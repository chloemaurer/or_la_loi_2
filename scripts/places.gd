extends Node2D

# --- Noeuds UI (Menus d'interaction) ---
# Ces menus apparaissent au centre de l'écran quand on clique sur un lieu
@onready var saloon_menu: Control = $"../Saloon"
@onready var saloon_shop: Control = $"../SaloonShop"
@onready var restaurant_shop: Control = $"../RestaurantShop"
@onready var restaurant_menu: Control = $"../Restaurant"
@onready var bank_menu: Control = $"../Bank"
@onready var armory_menu: Control = $"../Armory"
@onready var duel_menu: Control = $"../Duel"
@onready var dice_control: Control = $"../Dés"
@onready var mine_event: Control = $"../Mine"

# --- Boutons de la Carte (Les icônes sur le plateau) ---
@onready var saloon_button: Button = $Saloon
@onready var mine_button: Button = $Mine
@onready var restaurant_button: Button = $Restaurant
@onready var armory_button: Button = $Armory
@onready var bank_button: Button = $Bank
@onready var duel_button: Button = $Duel

func _ready():
	# Au démarrage, on s'assure que tout est propre et fermé
	close_all()

# Ferme tous les menus d'interaction et les boutiques
func close_all():
	saloon_menu.hide()
	saloon_shop.hide()
	restaurant_menu.hide()
	restaurant_shop.hide()
	bank_menu.hide()
	armory_menu.hide()
	duel_menu.hide()
	mine_event.hide()

# Cache les icônes de lieux sur la carte (utilisé lors des transitions)
func close_place():
	saloon_button.hide()
	mine_button.hide()
	restaurant_button.hide()
	armory_button.hide()
	bank_button.hide()
	duel_button.hide()

# --- LOGIQUE DES BOUTONS DE LIEUX ---
# Chaque fonction gère le nettoyage de l'écran et l'affichage du menu correspondant

func _on_saloon_pressed() -> void:
	close_all()
	close_place()
	saloon_button.show() # On garde le bouton du lieu actif visible
	saloon_menu.show()
	dice_control.hide()	

func _on_restaurant_pressed() -> void:
	close_all()
	close_place()
	restaurant_button.show()
	restaurant_menu.show()
	dice_control.hide()
	
func _on_bank_pressed() -> void:
	close_all()
	close_place()
	bank_button.show()
	bank_menu.show()
	dice_control.hide()
	
func _on_armory_pressed() -> void:
	close_all()
	close_place()
	armory_button.show()
	armory_menu.show()
	dice_control.hide()
	
func _on_duel_pressed() -> void:
	# Le duel est spécial : on vérifie d'abord si le joueur a de quoi tirer
	_check_ammo_and_open_duel()

# Vérifie les munitions dans les stats locales avant d'autoriser le duel
func _check_ammo_and_open_duel():
	var ammo_count = DatabaseConfig.local_munition
	if ammo_count > 0:
		print("[DUEL] Munitions détectées : ", ammo_count)
		close_all()
		close_place()
		duel_button.show()
		duel_menu.show()
		dice_control.hide()
	else:
		# Si le joueur n'a pas de balles, on bloque l'action et on l'informe
		DatabaseConfig.notify_error("Pas de munitions ! Vous ne pouvez pas commencer un duel")
		print("[DUEL] Refusé : Le joueur n'a pas de munitions.")
		duel_menu.hide() 
		
func _on_mine_pressed() -> void:
	close_all()
	close_place()
	mine_button.show()
	mine_event.show()
	dice_control.hide()
	
# --- LOGIQUE DE NAVIGATION VERS LES BOUTIQUES ---

# Ouvre la boutique du Saloon (Achat de cartes de boisson)
func _on_drink_buy_card_pressed() -> void:
	saloon_shop.show()
	saloon_menu.hide() # On cache le petit menu pour laisser place à la boutique complète

# Ouvre la boutique du Restaurant (Achat de cartes de nourriture)
func _on_food_buy_card_pressed() -> void:
	restaurant_shop.show()
	restaurant_menu.hide()
