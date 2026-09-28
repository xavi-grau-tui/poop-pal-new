extends Node

var all_drinks = [
	{
		"name": "Water",
		"icon": preload("res://textures/drinks/water.png"),
		"kcal": 0,
		"tags": ["hydrating", "healthy"],
		"color": Color(0.75, 0.85, 1.0, 0.5)  # soft blue
	},
	{
		"name": "Cola",
		"icon": preload("res://textures/drinks/soda.png"),
		"kcal": 140,
		"tags": ["unhealthy", "sugary"],
		"color": Color(0.45, 0.22, 0.22, 0.45)  # muted red-brown
	},
	{
		"name": "Energy Drink",
		"icon": preload("res://textures/drinks/energydrink.png"),
		"kcal": 110,
		"tags": ["unhealthy", "stimulating"],
		"color": Color(0.7, 0.95, 0.55, 0.45)  # pale lime green
	},
	{
		"name": "Orange Juice",
		"icon": preload("res://textures/drinks/orangejuice.png"),
		"kcal": 110,
		"tags": ["neutral", "vitamins"],
		"color": Color(1.0, 0.75, 0.45, 0.45)  # pastel orange
	}
]
