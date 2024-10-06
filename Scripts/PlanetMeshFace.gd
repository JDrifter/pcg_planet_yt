@tool
extends MeshInstance3D
class_name PlanetMeshFace
@export var normal : Vector3

func regen_mesh(planet_data : PlanetData):
	var arrs := []
	arrs.resize(Mesh.ARRAY_MAX)
	
	var vertexArr := PackedVector3Array()
	var uvArr := PackedVector2Array()
	var normalArr := PackedVector3Array()
	var indexArr := PackedInt32Array()
	
	var resolution := planet_data.resolution
	var numVerts : int = resolution * resolution
	var numIndices : int = (resolution-1) * (resolution-1) * 6
	
	normalArr.resize(numVerts)
	uvArr.resize(numVerts)
	vertexArr.resize(numVerts)
	indexArr.resize(numIndices)
	
	var triIndex : int = 0
	var axisA := Vector3(normal.y, normal.z, normal.x)
	var axisB : Vector3 = normal.cross(axisA)
	for y in range (resolution):
		for x in range (resolution):
			var i : int = x + y * resolution
			var percent := Vector2(x,y) / (resolution-1)
			var pointOnUnitCube : Vector3 = normal + (percent.x-0.5) * 2.0 * axisA + (percent.y-0.5) * 2.0 * axisB
			var pointOnUnitSphere := pointOnUnitCube.normalized() * float(planet_data.radius)
			var biome_index = planet_data.biome_percent_from_point(pointOnUnitSphere)
			var pointOnPlanet := planet_data.point_on_planet(pointOnUnitSphere)
			
			vertexArr[i] = pointOnPlanet
			uvArr[i] = Vector2(0.0, biome_index)
			
			var l = pointOnPlanet.length()
			if l < planet_data.min_height:
				planet_data.min_height = l
			if l > planet_data.max_height:
				planet_data.max_height = l
			
			if x != resolution-1 and y != resolution-1: #dont render outside of box
				indexArr[triIndex+2] = i
				indexArr[triIndex+1] = i + resolution+1
				indexArr[triIndex] = i + resolution
				
				indexArr[triIndex+5] = i
				indexArr[triIndex+4] = i+1
				indexArr[triIndex+3] = i+resolution+1
				triIndex+=6

	for a in range(0, indexArr.size(), 3):
		var b : int = a + 1
		var c : int = a + 2
		var ab : Vector3 = vertexArr[indexArr[b]] - vertexArr[indexArr[a]]
		var bc : Vector3 = vertexArr[indexArr[c]] - vertexArr[indexArr[b]]
		var ca : Vector3 = vertexArr[indexArr[a]] - vertexArr[indexArr[c]]
		var cross_ab_bc : Vector3 = ab.cross(bc) * -1.0
		var cross_bc_ca : Vector3 = bc.cross(ca) * -1.0
		var cross_ca_ab : Vector3 = ca.cross(ab) * -1.0
		normalArr[indexArr[a]] += cross_ab_bc + cross_bc_ca + cross_ca_ab
		normalArr[indexArr[b]] += cross_ab_bc + cross_bc_ca + cross_ca_ab
		normalArr[indexArr[c]] += cross_ab_bc + cross_bc_ca + cross_ca_ab

	for i in range(normalArr.size()):
		normalArr[i] = normalArr[i].normalized()
	
	arrs[Mesh.ARRAY_VERTEX] = vertexArr
	arrs[Mesh.ARRAY_NORMAL] = normalArr
	arrs[Mesh.ARRAY_TEX_UV] = uvArr
	arrs[Mesh.ARRAY_INDEX] = indexArr
	
	call_deferred("_update_mesh", arrs, planet_data)
	
func _update_mesh(arrs : Array, planet_data : PlanetData):
	var _mesh := ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrs)
	self.mesh = _mesh

	material_override.set_shader_parameter("min_height", planet_data.min_height)
	material_override.set_shader_parameter("max_height", planet_data.max_height)
	material_override.set_shader_parameter("height_color", planet_data.update_biome_texture())
