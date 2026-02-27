extends Control

# --- Noeuds UI ---
# Récupère les coeurs, les portraits des duellistes et l'image de l'arme
@onready var hearts_container: Array = $Effect/Life.get_children()
@onready var winner_rect: TextureRect = $Duel/Gagnant
@onready var loser_rect: TextureRect = $Duel/Perdant
@onready var weapon_visual: TextureRect = $Effect/Gun
@onready var duel_end_sound: AudioStreamPlayer = $"../../Son/FinDuel"

# --- Ressources (Textures) ---
# Liste des visuels de tir selon le niveau de l'arme (1, 2 ou 3)
@onready var gun_shoot_textures = [
	preload("uid://bs5swbvmuugrl"), 
	preload("uid://c6i2pqsx3aw7p"),   
	preload("uid://b1j22bf1ehjt2"), 
]

func _ready() -> void:
	# On cache l'écran de résultat au démarrage
	self.hide()
	
# Cette fonction est déclenchée par le Singleton DatabaseConfig dès qu'un duel est fini
func show_duel_result(winner_id: int, loser_id: int, damage_dealt: int):
	duel_end_sound.play()
	
	# 1. Récupération dynamique des portraits des joueurs
	# On va chercher les textures directement dans les noeuds des profils du script Main
	var profile_nodes = DatabaseConfig.script_general.profile_nodes
	
	if profile_nodes.size() > winner_id:
		# Accès au chemin précis de l'icône du vainqueur
		var winner_tex = profile_nodes[winner_id].get_node("PlayerIcon/Personnage").texture
		winner_rect.texture = winner_tex
		
	if profile_nodes.size() > loser_id:
		# Accès au chemin précis de l'icône du perdant
		var loser_tex = profile_nodes[loser_id].get_node("PlayerIcon/Personnage").texture
		loser_rect.texture = loser_tex

	# 2. Mise à jour du visuel de l'arme selon les dégâts infligés
	# Les dégâts sont de 1, 2 ou 3. On mappe cela aux index 0, 1, 2 de notre tableau
	var level_index = clampi(damage_dealt - 1, 0, 2) 
	weapon_visual.texture = gun_shoot_textures[level_index]

	# 3. Gestion de l'affichage des cœurs (Dégâts visuels)
	# On affiche seulement le nombre de cœurs correspondant aux dégâts reçus
	for i in range(hearts_container.size()):
		hearts_container[i].visible = (i < damage_dealt)

	# 4. Affichage de la fenêtre surgissante (Pop-up)
	self.show()

# Ferme l'écran de résultat
func _on_close_pressed() -> void:
	self.hide()
