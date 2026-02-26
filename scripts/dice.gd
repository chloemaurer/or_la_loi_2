extends BaseButton

# --- Animation Nodes ---
@onready var roll_anim_1: AnimationPlayer = $"../SubViewportContainer/SubViewport/Node3D/RollDiceAnimation" # roll_dice_animation
@onready var roll_anim_2: AnimationPlayer = $"../SubViewportContainer/SubViewport/Node3D2/RollDiceAnimation2" # roll_dice_animation_2

# --- Dice Nodes ---
const DiceScript = preload("uid://fd3fwqw0llor") # Getdice
@onready var dice_6_sides: DiceScript = $"../SubViewportContainer/SubViewport/Node3D/D6" # d_6
@onready var dice_2_sides: DiceScript = $"../SubViewportContainer/SubViewport/Node3D2/D2" # d_2

# --- UI Nodes ---
@onready var dice_result_label: Label = $"../DiceResultLabel"
@onready var places_container: Node2D = $"../../Places" # places

# --- Location Buttons ---
@onready var saloon_btn: Button = $"../../Places/Saloon"
@onready var mine_btn: Button = $"../../Places/Mine"
@onready var restaurant_btn: Button = $"../../Places/Restaurant"
@onready var armory_btn: Button = $"../../Places/Armory"
@onready var bank_btn: Button = $"../../Places/Bank"
@onready var duel_btn: Button = $"../../Places/Duel"

# --- Logic Variables ---
var total_dice_value := 0 # totalnumber

func roll_dice():
	_hide_all_places()
	
	# Randomize visual rotation for both dice
	_randomize_rotation(dice_6_sides)
	_randomize_rotation(dice_2_sides)
	
	# Play animations
	roll_anim_1.play("dice_6")
	roll_anim_2.play("dice_2")
	
	# Calculate total (ensure get_number() is called on both)
	total_dice_value = dice_6_sides.get_number() + dice_2_sides.get_number()

# Helper to randomize dice starting orientation
func _randomize_rotation(dice_node):
	dice_node.rotate_x(deg_to_rad(randi_range(0, 5) * 90))
	dice_node.rotate_z(deg_to_rad(randi_range(0, 5) * 90))
	dice_node.rotate_y(deg_to_rad(randi_range(0, 5) * 90))

func display_result(value: int):
	dice_result_label.text = str(value)

func _hide_all_places() -> void:
	bank_btn.hide()
	saloon_btn.hide()
	mine_btn.hide()
	restaurant_btn.hide()
	duel_btn.hide()
	armory_btn.hide()

# --- Probability Logic: Unlocks locations based on dice total ---

func enable_available_places():
	var current_round = DatabaseConfig.current_round
	
	match total_dice_value:
		2:
			bank_btn.show()
			duel_btn.show()
			if current_round >= 6: mine_btn.show()
		3:
			bank_btn.show()
			duel_btn.show()
		4:
			duel_btn.show()
			restaurant_btn.show()
		5:
			duel_btn.show()
			restaurant_btn.show()
			saloon_btn.show()
		6:
			duel_btn.show()
			restaurant_btn.show()
			saloon_btn.show()
		7:
			saloon_btn.show()
			restaurant_btn.show()
		8:
			saloon_btn.show()
			restaurant_btn.show()
			armory_btn.show()
		9:
			saloon_btn.show()
			armory_btn.show()
		10:
			armory_btn.show()
		11:
			armory_btn.show()
			bank_btn.show()
		12:
			armory_btn.show()
			bank_btn.show()
			if current_round >= 6: mine_btn.show()
		_:
			print("Error: Unknown dice total ", total_dice_value)

func _on_roll_dice_animation_animation_finished(_anim_name: StringName) -> void:
	places_container.show()
	display_result(total_dice_value)	
	enable_available_places()
