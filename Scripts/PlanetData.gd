@tool
extends Resource

class_name PlanetData

@export var radius : float = 1.0 : set = set_radius
@export var resolution : int = 5 : set = set_resolution
@export var planet_noise : Array[PlanetNoise] : set = set_planet_noise
@export var biomes : Array[PlanetBiome] : set = set_biomes
@export var biome_noise : FastNoiseLite : set = set_biome_noise
@export var biome_amplitude : float = 1.0 : set = set_biome_amplitude
@export var biome_offset : float = 1.0 : set = set_biome_offset
@export_range(0.0, 1.0) var biome_blend : float = 1.0 : set = set_biome_blend


var min_height := 99999.0
var max_height := 0.0

func set_biome_noise(val):
	biome_noise = val
	emit_signal("changed")
	if biome_noise != null and not biome_noise.is_connected("changed", on_data_changed):
			biome_noise.connect("changed", on_data_changed)

func set_biome_amplitude(val):
	biome_amplitude = val
	emit_signal("changed")

func set_biome_offset(val):
	biome_offset = val
	emit_signal("changed")

func set_biome_blend(val):
	biome_blend = val
	emit_signal("changed")

func set_planet_noise(val):
	planet_noise = val
	emit_signal("changed")
	for n in planet_noise:
		if n != null and not n.is_connected("changed", on_data_changed):
			n.connect("changed", on_data_changed)

func set_biomes(val):
	biomes = val
	if biomes.size() == 0:
		biomes[0] = PlanetBiome.new()
	for n in biomes:
		if n == null:
			n = PlanetBiome.new()
		if not n.is_connected("changed", on_data_changed):
			n.connect("changed", on_data_changed)
	
	emit_signal("changed")

const MAXRES : int = 100
const MINRES : int = -MAXRES

func set_radius(val):
	radius = val
	emit_signal("changed")

func set_resolution(val):
	if val > MAXRES:
		val = MAXRES
	if val < MINRES:
		val = MINRES
	resolution = val
	emit_signal("changed")

func on_data_changed():
	emit_signal("changed")


func point_on_planet_old(pos : Vector3) -> Vector3:
	var elevation : float = 0.0
	for n in planet_noise:
		var nelevation = n.noise_map.get_noise_3dv(pos)
		nelevation = nelevation + 1 / 2.0 * n.amplitude
		nelevation = max(0.0, nelevation - n.minh)
		elevation += nelevation
	return pos * radius * (elevation+1.0)


func update_biome_texture() -> ImageTexture:
	var image_texture = ImageTexture.new()
	var dynamic_image = Image.new()
	var h : int = biomes.size()
	if h > 0:
		var data : PackedByteArray = []
		var w : int = biomes[0].gradient.width
		for b in biomes:
			data.append_array(b.gradient.get_image().get_data())
		
		dynamic_image = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)
		
		image_texture.set_image(dynamic_image)
		image_texture.resource_name = "Biome Texture"
	
	return image_texture

func biome_percent_from_point(point_on_unit_sphere : Vector3) -> float:
	var height_percent : float = (point_on_unit_sphere.y + 1.0) / 2.0
	height_percent += ((biome_noise.get_noise_3dv(point_on_unit_sphere*100.0)+1.0/2.0)-biome_offset) * biome_amplitude
	var num_biome : float = biomes.size()
	var biome_index : float = 0.0;
	var blend_range : float = biome_blend / 2.0 + 0.0001
	for i in range(num_biome):
		var dst : float = height_percent - biomes[i].start_height
		var weight = clamp(inverse_lerp(-blend_range, blend_range, dst), 0.0, 1.0)
		biome_index *= (1 - weight)
		biome_index += i * weight
	return biome_index / max(1.0, num_biome - 1.0)

func point_on_planet(point_on_sphere : Vector3) -> Vector3:
	var elevation : float = 0.0
	var base_elevation := 0.0
	if planet_noise.size() > 0:
		base_elevation = (planet_noise[0].noise_map.get_noise_3dv(point_on_sphere*100.0))
		base_elevation = (base_elevation + 1.0) / 2.0 * planet_noise[0].amplitude
		base_elevation = max(0.0, base_elevation - planet_noise[0].minh)
	for n in planet_noise:
		var mask := 1.0
		if n.use_first_layer_as_mask:
			mask = base_elevation
		var level_elevation = n.noise_map.get_noise_3dv(point_on_sphere*100.0)
		level_elevation = (level_elevation + 1.0) / 2.0 * n.amplitude
		level_elevation = max(0.0, level_elevation - n.minh) * mask
		elevation += level_elevation
	return point_on_sphere * radius * (elevation+1.0)
