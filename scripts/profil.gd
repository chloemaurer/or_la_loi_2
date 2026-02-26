class_name Profil
extends Control

# --- UI Nodes ---
@onready var life_container: HBoxContainer = $Resources/Life # liste_des_coeurs
@onready var drink_container: HBoxContainer = $Resources/Drink # liste_drink
@onready var food_container: HBoxContainer = $Resources/Food # liste_food
@onready var money_label: Label = $Items/Items/Money # money
@onready var player_name: Label = $NomJoueur # nom_joueur
@onready var ammo_label: Label = $Items/Items/Control/Munition # munition
@onready var keypad: Node2D = $Keypad
@onready var weapon_icon: TextureRect = $Items/Items/Control/Gun # gun
@onready var player_icon: TextureRect = $"PlayerIcon/Personnage" # player_icone
@onready var background: TextureRect = $"TextureRect" # fond

# --- Assets ---
@onready var characters = [
	{"sprite": preload("uid://brntffde21jyb"), "background": preload("uid://k8aqihjvcery")},
	{"sprite": preload("uid://b56iwvx4nh63n"), "background": preload("uid://cgvlmje6wxcwj")},
	{"sprite": preload("uid://bg3rdqu4pcayv"), "background": preload("uid://ge5n77q02fhq")},
	{"sprite": preload("uid://d3hkmacsq0pag"), "background": preload("uid://b7mfhv7byc41k")},
]

const LVL_1_GUN = preload("uid://dwg03ruoyaydt") # NIV_1_ICON
const LVL_2_GUN = preload("uid://dmcrgshg65fct") # NIV_2_ICON
const LVL_3_GUN = preload("uid://v5lcdv6u4ott") # NIV_3_ICON

# --- Internal Stats (Mirrors for the Dispatcher) ---
var _current_life: int = 0
var _current_food: int = 0
var _current_drink: int = 0
var _current_money: int = 0
var _current_ammo: int = 0
var _current_weapon_lvl: int = 0


# Called by DatabaseConfig's dispatcher to refresh visuals
func update_visual(key: String, value):
	match key:
		"Icone":
			var index = int(value)
			if index >= 0 and index < characters.size():
				var design = characters[index]
				if player_icon: 
					player_icon.texture = design["sprite"]
				if background:
					background.texture = design["background"]
			else:
				print("ERROR: Invalid icon index: ", index)
				
		"Vie":
			_current_life = int(value)
			_update_hbox_icons(life_container, _current_life)
		"Nourriture":
			_current_food = int(value)
			_update_hbox_icons(food_container, _current_food)
		"Boisson":
			_current_drink = int(value)
			_update_hbox_icons(drink_container, _current_drink)
		"Argent":
			_current_money = int(value)
			if money_label: 
				money_label.text = str(_current_money)
		"Nom":
			player_name.text = str(value)
		"Munition":
			_current_ammo = int(value)
			if ammo_label: 
				ammo_label.text = str(_current_ammo)
		"Arme":
			_current_weapon_lvl = int(value)
			_show_weapon_visual()

# Helper function to dim/highlight resource icons
func _update_hbox_icons(container: HBoxContainer, n: int):
	if not container: return
	var children = container.get_children()
	for i in range(children.size()):
		# Active color (greyish pink) vs Empty color (dark grey)
		children[i].modulate = Color(0.345, 0.345, 0.345) if i < n else Color(0.149, 0.149, 0.149)

# --- GETTERS (Called by Main script and Mine script) ---

func get_life(): 
	return _current_life

func get_food(): 
	return _current_food

func get_drink(): 
	return _current_drink

func get_money(): 
	return _current_money
	
func get_munition(): 
	return _current_ammo
	
func get_gun():
	return _current_weapon_lvl

# --- Visual updates ---

func _show_weapon_visual():
	match _current_weapon_lvl:
		1:
			weapon_icon.texture = LVL_1_GUN
			print("Visual: Weapon Level 1")
		2:
			weapon_icon.texture = LVL_2_GUN
			print("Visual: Weapon Level 2")
		3:
			weapon_icon.texture = LVL_3_GUN
			print("Visual: Weapon Level 3")

func _on_keypad_open_pressed() -> void:
	keypad.visible = !keypad.visible
