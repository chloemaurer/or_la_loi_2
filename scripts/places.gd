extends Node2D

# --- UI Popups (Interaction Menus) ---
@onready var saloon_menu: Control = $"../Saloon" # saloon
@onready var saloon_shop: Control = $"../SaloonShop"
@onready var restaurant_shop: Control = $"../RestaurantShop"
@onready var restaurant_menu: Control = $"../Restaurant" # restaurant
@onready var bank_menu: Control = $"../Bank" # bank
@onready var armory_menu: Control = $"../Armory" # armory
@onready var duel_menu: Control = $"../Duel" # duel
@onready var dice_control: Control = $"../Dés" # dés
@onready var mine_event: Control = $"../Mine" # mine

# --- Map Buttons (The actual icons on the board) ---
@onready var saloon_button: Button = $Saloon
@onready var mine_button: Button = $Mine
@onready var restaurant_button: Button = $Restaurant
@onready var armory_button: Button = $Armory
@onready var bank_button: Button = $Bank
@onready var duel_button: Button = $Duel

func _ready():
	close_all()

# Closes all interaction menus and shops
func close_all():
	saloon_menu.hide()
	saloon_shop.hide()
	restaurant_menu.hide()
	restaurant_shop.hide()
	bank_menu.hide()
	armory_menu.hide()
	duel_menu.hide()
	mine_event.hide()

# Hides all location icons on the map
func close_place():
	saloon_button.hide()
	mine_button.hide()
	restaurant_button.hide()
	armory_button.hide()
	bank_button.hide()
	duel_button.hide()

# --- LOCATION BUTTON LOGIC ---

func _on_saloon_pressed() -> void:
	close_all()
	close_place()
	saloon_button.show()
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
	_check_ammo_and_open_duel()

# Duel requires at least 1 ammo in local stats
func _check_ammo_and_open_duel():
	var ammo_count = DatabaseConfig.local_munition
	if ammo_count > 0:
		print("[DUEL] Ammo detected: ", ammo_count)
		close_all()
		close_place()
		duel_button.show()
		duel_menu.show()
		dice_control.hide()
	else:
		DatabaseConfig.notify_error("Pas de munitions ! Vous ne pouvez pas commencer un duel")
		print("[DUEL] Refused: Player has no ammo.")
		duel_menu.hide() 
		
func _on_mine_pressed() -> void:
	close_all()
	close_place()
	mine_button.show()
	mine_event.show()
	dice_control.hide()
	
# --- SHOP NAVIGATION LOGIC ---

func _on_drink_buy_card_pressed() -> void:
	saloon_shop.show()
	saloon_menu.hide() # Hide the small menu to show the full shop

func _on_food_buy_card_pressed() -> void:
	restaurant_shop.show()
	restaurant_menu.hide()
