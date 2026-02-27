extends Control

# --- Noeuds UI (Les 10 emplacements de wagons) ---
# Chaque variable correspond à un Sprite ou une TextureRect dans ton interface
@onready var wagon_slots = [
	$MancheUnVide, $MancheDeuxVide, $MancheTroisVide, $MancheQuatreVide, $MancheCinqVide, 
	$MancheSixVide, $MancheSeptVide, $MancheHuitVide, $MancheNeufVide, $MancheDixVide
]

# --- Assets : Wagons Vides / État de base ---
# Ces textures sont affichées pour les manches qui n'ont pas encore eu lieu
@onready var empty_wagon_textures = [
	 preload("uid://eu77wppshotv"), # Locomotive (Base)
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

# --- Assets : Wagons Remplis / État Actif ---
# Ces textures remplacent les wagons vides pour marquer la progression
@onready var filled_wagon_textures = [
	preload("uid://eu77wppshotv"), # La locomotive reste généralement identique
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

# Met à jour l'affichage du train en fonction de la manche actuelle stockée dans DatabaseConfig
func update_train_display():
	var current_round = DatabaseConfig.current_round
	
	# On parcourt les 10 emplacements de wagons
	for i in range(wagon_slots.size()):
		if i < current_round:
			# Si l'index est inférieur à la manche actuelle, on affiche le wagon "rempli"
			# (On vérifie par sécurité que l'index existe dans le tableau de textures)
			if i < filled_wagon_textures.size():
				wagon_slots[i].texture = filled_wagon_textures[i]
		else:
			# Pour les manches futures, on s'assure que le wagon est à l'état "vide"
			if i < empty_wagon_textures.size():
				wagon_slots[i].texture = empty_wagon_textures[i]

# Réinitialise visuellement tous les wagons à l'état vide (ex: pour une nouvelle partie)
func reset_all_wagons():
	for i in range(wagon_slots.size()):
		wagon_slots[i].texture = empty_wagon_textures[i]
