@tool
extends SceneTree

const MapConfig = preload("res://scripts/map_config.gd")

func test_res(res: int):
	var t0 = Time.get_ticks_msec()
	var half = MapConfig.HALF_SIZE
	var step = MapConfig.MAP_SIZE / float(res)
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for gz in range(res):
		for gx in range(res):
			var x0 = -half + float(gx) * step
			var x1 = x0 + step
			var z0 = -half + float(gz) * step
			var z1 = z0 + step
			
			var y00 = MapConfig.get_height_at(x0, z0)
			var y10 = MapConfig.get_height_at(x1, z0)
			var y01 = MapConfig.get_height_at(x0, z1)
			var y11 = MapConfig.get_height_at(x1, z1)
			
			var p00 = Vector3(x0, y00, z0)
			var p10 = Vector3(x1, y10, z0)
			var p01 = Vector3(x0, y01, z1)
			var p11 = Vector3(x1, y11, z1)
			
			surface_tool.add_vertex(p00)
			surface_tool.add_vertex(p10)
			surface_tool.add_vertex(p11)
			
			surface_tool.add_vertex(p00)
			surface_tool.add_vertex(p11)
			surface_tool.add_vertex(p01)
	
	surface_tool.generate_normals()
	var mesh = surface_tool.commit()
	var t_mesh = Time.get_ticks_msec()
	
	var shape = mesh.create_trimesh_shape()
	var t_shape = Time.get_ticks_msec()
	
	var tri_count = res * res * 2
	print("Res: %dx%d | Triangles: %d | Mesh Gen: %d ms | Trimesh Col: %d ms | Total: %d ms" % [
		res, res, tri_count, (t_mesh - t0), (t_shape - t_mesh), (t_shape - t0)
	])

func _init():
	print("--- BENCHMARK TERRAIN RESOLUTION ---")
	test_res(96)
	test_res(128)
	test_res(192)
	test_res(256)
	quit(0)
