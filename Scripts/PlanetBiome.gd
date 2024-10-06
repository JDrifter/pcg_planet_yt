@tool
extends Resource

class_name PlanetBiome

@export var gradient : GradientTexture1D : set = set_gradient
@export var start_height : float : set = set_start_height

func set_gradient(val):
	gradient = val
	emit_signal("changed")
	if gradient != null and not gradient.is_connected("changed", on_data_changed):
		gradient.connect("changed", on_data_changed)

func set_start_height(val):
	start_height = val
	emit_signal("changed")

func on_data_changed():
	emit_signal("changed")
