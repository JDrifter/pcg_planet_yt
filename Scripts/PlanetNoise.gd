@tool
extends Resource
class_name PlanetNoise

@export var amplitude : float = 1.0 : set = set_amplitude
@export var minh : float = 1.0 : set = set_minh
@export var noise_map : FastNoiseLite : set = set_noise_map
@export var use_first_layer_as_mask : bool = false : set = set_first_layer_as_mask

func set_first_layer_as_mask(val):
	use_first_layer_as_mask = val
	emit_signal("changed")

func set_amplitude(val):
	amplitude = val
	emit_signal("changed")

func set_minh(val):
	minh = val
	emit_signal("changed")

func set_noise_map(val):
	noise_map = val
	if noise_map != null and not noise_map.is_connected("changed", on_data_changed):
		noise_map.connect("changed", on_data_changed)


func on_data_changed():
	emit_signal("changed")
