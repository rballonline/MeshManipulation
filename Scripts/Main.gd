extends Spatial

var is_rotate_enabled = false
var is_zoom_enabled = false
var input_start_position = Vector2()
var camera_gimble
var inner_gimbal
var rotation_speed = 0.2
var zoom_step = 0.002
var camera
var zoom_min = 3
export var invert_x = false
export var invert_y = false
export var mouse_sensitivity = 0.005

export var show_wireframe = true
export var show_axes = true
export var show_face_normals = true

func _input(event):
	if event.is_action_pressed("ui_rotate"):
		is_rotate_enabled = true
		input_start_position = get_viewport().get_mouse_position()
	if event.is_action_released("ui_rotate"):
		is_rotate_enabled = false

	if event.is_action_pressed("ui_zoom"):
		is_zoom_enabled = true
		input_start_position = get_viewport().get_mouse_position()
	if event.is_action_released("ui_zoom"):
		is_zoom_enabled = false
	
	if event.is_action_pressed("ui_exit"):
		get_tree().quit()

	if event is InputEventMouseMotion:
		if is_rotate_enabled:
			if event.relative.x != 0:
				var dir = 1 if invert_x else -1
				camera_gimble.rotate_object_local(Vector3.UP, dir * event.relative.x * mouse_sensitivity)
			if event.relative.y != 0:
				var dir = 1 if invert_y else -1
				inner_gimbal.rotate_object_local(Vector3.RIGHT, dir * event.relative.y * mouse_sensitivity)
		elif is_zoom_enabled:
			var camera_to_anchor = camera_gimble.get_global_transform().origin - camera.get_global_transform().origin
			var length = camera_to_anchor.length()
			if length > zoom_min or event.relative.y < 0:
				camera.global_translate((event.relative.y * zoom_step) * camera_to_anchor)

func _ready():
	camera_gimble = get_node("CameraGimbal")
	inner_gimbal = get_node("CameraGimbal/InnerGimbal")
	camera = get_node("CameraGimbal/InnerGimbal/Camera")
	
	createAndAssignCubeMesh()
	
	if show_wireframe:
		drawWireframe()
	if show_axes:
		drawAxes()
	if show_face_normals:
		drawSurfaceNormals()

	drawSelectedOutline(1)

func createAndAssignCubeMesh():
	var uniqueCubeVertices = [
		Vector3(-0.5,0.5,0.5),
		Vector3(0.5,0.5,0.5),
		Vector3(0.5,-0.5,0.5),
		Vector3(-0.5,-0.5,0.5),

		Vector3(-0.5,0.5,-0.5),
		Vector3(0.5,0.5,-0.5),
		Vector3(0.5,-0.5,-0.5),
		Vector3(-0.5,-0.5,-0.5),
	]

	var cube_faces = [
		uniqueCubeVertices[0], uniqueCubeVertices[1], uniqueCubeVertices[2], # top
		uniqueCubeVertices[0], uniqueCubeVertices[2], uniqueCubeVertices[3],
		uniqueCubeVertices[4], uniqueCubeVertices[6], uniqueCubeVertices[5], # back
		uniqueCubeVertices[4], uniqueCubeVertices[7], uniqueCubeVertices[6],
		uniqueCubeVertices[0], uniqueCubeVertices[7], uniqueCubeVertices[4], # left
		uniqueCubeVertices[0], uniqueCubeVertices[3], uniqueCubeVertices[7],
		uniqueCubeVertices[1], uniqueCubeVertices[5], uniqueCubeVertices[6], # right
		uniqueCubeVertices[1], uniqueCubeVertices[6], uniqueCubeVertices[2],
		uniqueCubeVertices[0], uniqueCubeVertices[4], uniqueCubeVertices[1], # top
		uniqueCubeVertices[4], uniqueCubeVertices[5], uniqueCubeVertices[1],
		uniqueCubeVertices[7], uniqueCubeVertices[3], uniqueCubeVertices[2], # bottom
		uniqueCubeVertices[6], uniqueCubeVertices[7], uniqueCubeVertices[2]
	]

	var sTool = SurfaceTool.new()
	sTool.begin(Mesh.PRIMITIVE_TRIANGLES)

	for x in cube_faces:
		sTool.add_vertex(x)

	sTool.generate_normals()
	var cube = $Meshes/Cube
	cube.mesh = sTool.commit()
	
	var material = SpatialMaterial.new()
	material.albedo_color = Color("36c92a")
	cube.material_override = material
	
	cube.create_convex_collision()
	var cubesStaticBody = cube.get_child(0)
	cubesStaticBody.name = "CubeStaticBody"
	cubesStaticBody.connect("input_event", get_node("/root/Main"), "_on_StaticBody_input_event")
	cubesStaticBody.connect("mouse_exited", get_node("/root/Main"), "_on_StaticBody_mouse_exited")
	cubesStaticBody.connect("mouse_entered", get_node("/root/Main"), "_on_StaticBody_mouse_entered")
	

func drawSurfaceNormals():
	var cubeMeshInstance = get_node("Meshes/Cube")
	var cubeMesh = cubeMeshInstance.get_mesh()
	var vertices = cubeMesh.get_faces()
	var arrayMesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrayMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var meshDataTool = MeshDataTool.new()
	meshDataTool.create_from_surface(arrayMesh, 0)
	
	var ig = ImmediateGeometry.new()
	ig.name = "SurfaceNormals_ImmediateGeometry"
	var sm = SpatialMaterial.new()
	sm.flags_unshaded = true
	sm.vertex_color_use_as_albedo = true
	ig.material_override = sm

	ig.begin(Mesh.PRIMITIVE_LINES)
	ig.set_color(Color.white)
	
	var i = 0
	while i < meshDataTool.get_face_count():
		var verticesIndex = i * 3
		var a = vertices[verticesIndex]
		var b = vertices[verticesIndex + 1]
		var c = vertices[verticesIndex + 2]
		var face_center = (a+b+c)/3

		ig.add_vertex(face_center)
		ig.add_vertex(meshDataTool.get_face_normal(i) + face_center)
		i += 1

	ig.end()
	cubeMeshInstance.add_child(ig)

func drawAxes():
	var axisGeom = ImmediateGeometry.new()
	axisGeom.name = "AxisGeom"
	var axisMaterial = SpatialMaterial.new()
	var axisLength = 10
	axisMaterial.flags_unshaded = true
	axisMaterial.vertex_color_use_as_albedo = true
	axisMaterial.flags_no_depth_test = true # Makes it so the lines are drawn over the earlier added objects
	axisGeom.material_override = axisMaterial;
	axisGeom.begin(Mesh.PRIMITIVE_LINES)

	axisGeom.set_color(Color.red)
	axisGeom.add_vertex(Vector3(0,0,0))
	axisGeom.add_vertex(Vector3(axisLength,0,0))
	axisGeom.set_color(Color.green)
	axisGeom.add_vertex(Vector3(0,0,0))
	axisGeom.add_vertex(Vector3(0,axisLength,0))
	axisGeom.set_color(Color.blue)
	axisGeom.add_vertex(Vector3(0,0,0))
	axisGeom.add_vertex(Vector3(0,0,axisLength))
	
	axisGeom.end()
	add_child(axisGeom)

func drawSelectedOutline(selectedFace):
	var cubeMeshInstance = get_node("Meshes/Cube")
	var cubeMesh = cubeMeshInstance.get_mesh()
	
	var ig = ImmediateGeometry.new()
	var sm = SpatialMaterial.new()
	sm.flags_unshaded = true
	sm.vertex_color_use_as_albedo = true
	ig.material_override = sm
	ig.name = "DrawSelectedOutline_ImmediateGeometry"

	ig.begin(Mesh.PRIMITIVE_TRIANGLES)
	ig.set_color(Color.purple)
	
	cubeMesh.create_outline(1.0)
	var vertices = cubeMesh.get_faces()
	
	var startVertex = selectedFace * 3
	ig.add_vertex(vertices[startVertex])
	ig.add_vertex(vertices[startVertex + 1])
	ig.add_vertex(vertices[startVertex + 2])
	
	ig.end()
	var sf = 1.005
	ig.set_scale(Vector3(sf, sf, sf))
	cubeMeshInstance.add_child(ig)

func drawWireframe():
	var cubeMeshInstance = get_node("Meshes/Cube")
	var cubeMesh = cubeMeshInstance.get_mesh()
	
	var ig = ImmediateGeometry.new()
	var sm = SpatialMaterial.new()
	sm.flags_unshaded = true
	sm.vertex_color_use_as_albedo = true
	ig.material_override = sm
	ig.name = "Wireframe_ImmediateGeometry"

	ig.begin(Mesh.PRIMITIVE_LINES)
	ig.set_color(Color.yellow)
	
	cubeMesh.create_outline(1.0)
	var vertices = cubeMesh.get_faces()
	
	var i = 0
	print("Size: %s" % vertices.size())
	while i < vertices.size():
		ig.add_vertex(vertices[i])
		ig.add_vertex(vertices[i+1])
		ig.add_vertex(vertices[i+1])
		ig.add_vertex(vertices[i+2])
		ig.add_vertex(vertices[i+2])
		ig.add_vertex(vertices[i])
		i += 3
	
	ig.end()
	var sf = 1.005
	ig.set_scale(Vector3(sf, sf, sf))
	cubeMeshInstance.add_child(ig)
	
static func rotate_vector3_around(var v3_pos,var v3_pivot,var y_angle): 
		var dir = v3_pos - v3_pivot 
		dir = Quat(Vector3(0,1,0),y_angle) * dir 
		var point = dir - v3_pivot 
		return point

func _on_StaticBody_mouse_entered():
	print("In cube")

func _on_StaticBody_mouse_exited():
	print("Out cube")

func _on_StaticBody_input_event(camera, event, click_position, click_normal, shape_idx):
	if event.is_action_pressed("left_mouse"):
		print("Pos ", click_position)
