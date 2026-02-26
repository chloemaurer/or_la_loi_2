extends Control

# --- UI Nodes ---
@onready var hearts_container: Array = $Effect/Life.get_children() # hearts
@onready var winner_rect: TextureRect = $Duel/Gagnant
@onready var loser_rect: TextureRect = $Duel/Perdant
@onready var weapon_visual: TextureRect = $Effect/Gun # gun
@onready var duel_end_sound: AudioStreamPlayer = $"../../Son/FinDuel"

# --- Assets ---
@onready var gun_shoot_textures = [
	preload("uid://bs5swbvmuugrl"), 
	preload("uid://c6i2pqsx3aw7p"),  
	preload("uid://b1j22bf1ehjt2"), 
]

func _ready() -> void:
	self.hide()
	
# This function is called by DatabaseConfig after a duel
func show_duel_result(winner_id: int, loser_id: int, damage_dealt: int):
	duel_end_sound.play()
	
	# 1. Fetch character icons from the main profile nodes
	var profile_nodes = DatabaseConfig.script_general.profile_nodes
	
	if profile_nodes.size() > winner_id:
		# Accessing the icon through the node structure
		var winner_tex = profile_nodes[winner_id].get_node("PlayerIcon/Personnage").texture
		winner_rect.texture = winner_tex
		
	if profile_nodes.size() > loser_id:
		var loser_tex = profile_nodes[loser_id].get_node("PlayerIcon/Personnage").texture
		loser_rect.texture = loser_tex

	# 2. Update the Weapon visual based on damage level
	# Damage is 1, 2, or 3. Map to array index 0, 1, 2
	var level_index = clampi(damage_dealt - 1, 0, 2) 
	weapon_visual.texture = gun_shoot_textures[level_index]

	# 3. Handle heart visibility based on damage points
	for i in range(hearts_container.size()):
		hearts_container[i].visible = (i < damage_dealt)

	# 4. Display the Pop-up
	self.show()

func _on_close_pressed() -> void:
	self.hide()
