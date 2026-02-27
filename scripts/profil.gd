class_name Profil
extends Control

# --- Noeuds UI ---
# Récupère les conteneurs de ressources et les labels pour l'affichage
@onready var life_container: HBoxContainer = $Resources/Life
@onready var drink_container: HBoxContainer = $Resources/Drink
@onready var food_container: HBoxContainer = $Resources/Food
@onready var money_label: Label = $Items/Items/Money
@onready var player_name: Label = $NomJoueur
@onready var ammo_label: Label = $Items/Items/Control/Munition
@onready var keypad: Node2D = $Keypad
@onready var weapon_icon: TextureRect = $Items/Items/Control/Gun
@onready var player_icon: TextureRect = $"PlayerIcon/Personnage"
@onready var background: TextureRect = $"TextureRect"

# --- Ressources (Assets) ---
# Liste des textures pour les personnages et leurs fonds respectifs
@onready var characters = [
	{"sprite": preload("uid://brntffde21jyb"), "background": preload("uid://k8aqihjvcery")},
	{"sprite": preload("uid://b56iwvx4nh63n"), "background": preload("uid://cgvlmje6wxcwj")},
	{"sprite": preload("uid://bg3rdqu4pcayv"), "background": preload("uid://ge5n77q02fhq")},
	{"sprite": preload("uid://d3hkmacsq0pag"), "background": preload("uid://b7mfhv7byc41k")},
]

# Icônes pour les différents niveaux d'armes
const LVL_1_GUN = preload("uid://dwg03ruoyaydt")
const LVL_2_GUN = preload("uid://dmcrgshg65fct")
const LVL_3_GUN = preload("uid://v5lcdv6u4ott")

# --- Statistiques Internes (Miroir pour le Dispatcher) ---
# Stocke les valeurs actuelles pour permettre au jeu de lire les stats sans interroger Firebase
var _current_life: int = 0
var _current_food: int = 0
var _current_drink: int = 0
var _current_money: int = 0
var _current_ammo: int = 0
var _current_weapon_lvl: int = 0


# Appelé par le dispatcher de DatabaseConfig pour rafraîchir le visuel suite à un changement DB
func update_visual(key: String, value):
	match key:
		"Icone":
			var index = int(value)
			if index >= 0 and index < characters.size():
				var design = characters[index]
				if player_icon: player_icon.texture = design["sprite"]
				if background: background.texture = design["background"]
			else:
				print("ERREUR: Index d'icône invalide: ", index)
				
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
			if money_label: money_label.text = str(_current_money)
		"Nom":
			player_name.text = str(value)
		"Munition":
			_current_ammo = int(value)
			if ammo_label: ammo_label.text = str(_current_ammo)
		"Arme":
			_current_weapon_lvl = int(value)
			_show_weapon_visual()

# Fonction utilitaire pour allumer ou griser les icônes (coeurs, bouteilles, etc.)
func _update_hbox_icons(container: HBoxContainer, n: int):
	if not container: return
	var children = container.get_children()
	for i in range(children.size()):
		# On utilise des modulations de couleur pour simuler des icônes pleines ou vides
		# Gris clair pour les ressources possédées, Gris très foncé pour les emplacements vides
		children[i].modulate = Color(0.345, 0.345, 0.345) if i < n else Color(0.149, 0.149, 0.149)

# --- GETTERS (Utilisés par le script Main et la Mine pour vérifier l'état du joueur) ---

func get_life(): return _current_life
func get_food(): return _current_food
func get_drink(): return _current_drink
func get_money(): return _current_money
func get_munition(): return _current_ammo
func get_gun(): return _current_weapon_lvl

# --- Mise à jour visuelle des équipements ---

# Change l'icône de l'arme selon le niveau actuel
func _show_weapon_visual():
	match _current_weapon_lvl:
		1: weapon_icon.texture = LVL_1_GUN
		2: weapon_icon.texture = LVL_2_GUN
		3: weapon_icon.texture = LVL_3_GUN

# Permet d'ouvrir/fermer le pavé numérique du profil
func _on_keypad_open_pressed() -> void:
	keypad.visible = !keypad.visible
