extends Control

# --- UI Nodes (The 10 wagon slots) ---
@onready var wagon_slots = [
	$MancheUnVide, $MancheDeuxVide, $MancheTroisVide, $MancheQuatreVide, $MancheCinqVide, 
	$MancheSixVide, $MancheSeptVide, $MancheHuitVide, $MancheNeufVide, $MancheDixVide
]

# --- Assets: Empty/Base Wagons ---
@onready var empty_wagon_textures = [
	 preload("uid://eu77wppshotv"),
	 preload("uid://cxi4w0adl10gf"),
	 preload("uid://d1tok5ke3hiyx"),
	 preload("uid://btchig2cm0ebn"),
	 preload("uid://4oe5jxv11730"),
	 preload("uid://dujpup0gg3wv8"),
	 preload("uid://ct623muwomadu"),
	 preload("uid://x0g50ubywhb2"),
	 preload("uid://bujo73mhqjlue"),
	 preload("uid://bmh4qx47anx7t"),
]

# --- Assets: Filled/Active Wagons ---
@onready var filled_wagon_textures = [
	preload("uid://eu77wppshotv"), # Locomotive (usually doesn't change)
	preload("uid://dup5x38jho7t6"),
	preload("uid://dn52d3tfcxhsq"),
	preload("uid://d24bekjlqj123"),
	preload("uid://bqlm8wq16k08k"),
	preload("uid://dc476m4r8noyd"),
	preload("uid://dm2qmeydhmey7"),
	preload("uid://btl2i2x4etvqv"),
	preload("uid://bepnrld44r5uy"),
	preload("uid://b8vrupdagj82x")
]

# Updates the train display based on the current round
func update_train_display():
	var current_round = DatabaseConfig.current_round
	
	for i in range(wagon_slots.size()):
		if i < current_round:
			# Fill the wagons for rounds already completed or current
			if i < filled_wagon_textures.size():
				wagon_slots[i].texture = filled_wagon_textures[i]
		else:
			# Reset the future wagons to their empty state
			if i < empty_wagon_textures.size():
				wagon_slots[i].texture = empty_wagon_textures[i]

# Visually clears all wagons (useful for a hard reset)
func reset_all_wagons():
	for i in range(wagon_slots.size()):
		wagon_slots[i].texture = empty_wagon_textures[i]
