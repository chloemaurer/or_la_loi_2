extends Control

@onready var hearts: Array = $Effect/Life.get_children() # Récupère les 3 TextureRect
@onready var gagnant_rect: TextureRect = $Duel/Gagnant
@onready var perdant_rect: TextureRect = $Duel/Perdant

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

	# 2. Gérer la visibilité des cœurs selon les dégâts (1, 2 ou 3)
	# On boucle sur les 3 enfants du HBoxContainer
	for i in range(hearts.size()):
		# Si l'index est inférieur aux dégâts, on montre le cœur, sinon on le cache
		hearts[i].visible = (i < degats)

	# 3. Afficher le Pop-up
	self.show()



func _on_close_pressed() -> void:
	self.hide()
