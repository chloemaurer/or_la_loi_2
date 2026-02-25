extends Control

@onready var hearts: Array = $Effect/Life.get_children() 
@onready var gagnant_rect: TextureRect = $Duel/Gagnant
@onready var perdant_rect: TextureRect = $Duel/Perdant
@onready var gun: TextureRect = $Effect/Gun

@onready var gun_shoot = [
	preload("uid://bs5swbvmuugrl"), 
	preload("uid://c6i2pqsx3aw7p"),  
	preload("uid://b1j22bf1ehjt2"), 
]

func _ready() -> void:
	self.hide()
	
func afficher_duel_resultat(id_gagnant: int, id_perdant: int, degats: int):
	# 1. Récupérer les icônes des personnages
	var nodes_profils = DatabaseConfig.script_general.profils_noeuds
	
	if nodes_profils.size() > id_gagnant:
		var tex_gagnant = nodes_profils[id_gagnant].get_node("PlayerIcon/Personnage").texture
		gagnant_rect.texture = tex_gagnant
		
	if nodes_profils.size() > id_perdant:
		var tex_perdant = nodes_profils[id_perdant].get_node("PlayerIcon/Personnage").texture
		perdant_rect.texture = tex_perdant

	# 2. Mise à jour de l'image du Gun selon le niveau
	# degats vaut 1, 2 ou 3. On fait -1 pour correspondre aux index 0, 1, 2
	var level_index = clampi(degats - 1, 0, 2) 
	gun.texture = gun_shoot[level_index]

	# 3. Gérer la visibilité des cœurs selon les dégâts
	for i in range(hearts.size()):
		hearts[i].visible = (i < degats)

	# 4. Afficher le Pop-up
	self.show()

func _on_close_pressed() -> void:
	self.hide()
