extends Node2D

@onready var food_option_1 = $Menu/FoodOption1
@onready var food_option_2 = $Menu/FoodOption2
@onready var food_option_3 = $Menu/FoodOption3

func _ready():
	print("Food Option 1:", food_option_1.name)
	print("Food Option 2:", food_option_2.name)
	print("Food Option 3:", food_option_3.name)
