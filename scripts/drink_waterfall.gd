extends Node2D
class_name DrinkWaterfall

func setup(color: Color) -> void:
	print("✅ setup() called with color:", color)

	var body := $Body
	var foam := $Foam

	if body:
		body.self_modulate = color  # ✅ Only apply color

	if foam:
		foam.visible = true  # ✅ Leave visible
