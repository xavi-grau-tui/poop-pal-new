extends Node2D

@onready var icon = $Icon  # Your Sprite2D or TextureRect for the food image
@onready var name_label = $NameLabel  # Your Label for the name
@onready var kcal_label = $KcalLabel  # Your Label for the kcal info
@onready var info_label = $InfoLabel  # Optional: e.g., for showing tags

func set_food(food_data: Dictionary):
	# Set the image
	if food_data.has("icon") and icon:
		icon.texture = load(food_data.icon)

	# Set the name
	if food_data.has("name") and name_label:
		name_label.text = food_data.name

	# Set the kcal
	if food_data.has("kcal") and kcal_label:
		kcal_label.text = str(food_data.kcal) + " kcal"

	# Optional: Tag info
	if food_data.has("tags") and info_label:
		info_label.text = ", ".join(food_data.tags)
