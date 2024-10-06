@tool
extends Node3D

@export var planet_data : PlanetData: 
	set(val):
		planet_data = val
		on_data_change()
		if planet_data != null and not planet_data.is_connected("changed", on_data_change):
			planet_data.connect("changed", on_data_change)


func _ready():
	on_data_change()

func on_data_change():
	planet_data.min_height = 99999.0
	planet_data.max_height = 0.0
	for child in get_children():
		var face := child as PlanetMeshFace
		face.regen_mesh(planet_data)
