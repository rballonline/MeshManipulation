extends Spatial

var is_rotate_enabled = false
var is_zoom_enabled = false
var input_start_position = Vector2()
var camera_anchor
var rotation_speed = 0.2
var zoom_step = 0.002
var camera
var zoom_min = 3

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

	if event is InputEventMouse:
		var delta = input_start_position - event.get_position()
		if is_rotate_enabled:
			print("Delta x:", delta.x, " y: ", delta.y)
			camera_anchor.rotate_y(deg2rad(delta.x) * rotation_speed)
			#camera_anchor.rotate_z(deg2rad(delta.y) * rotation_speed) # Hmm
			input_start_position = event.get_position()
		elif is_zoom_enabled:
			var camera_to_anchor = camera_anchor.get_global_transform().origin - camera.get_global_transform().origin
			var length = camera_to_anchor.length()
			if(length > zoom_min):
				camera.global_translate((delta.y * zoom_step) * camera_to_anchor)
			input_start_position = event.get_position()

func _ready():
	camera_anchor = get_node("CameraAnchor")
	camera = get_node("CameraAnchor/Camera")

	if show_wireframe:
		drawWireframe()
	if show_axes:
		drawAxes()
	if show_face_normals:
		drawSurfaceNormals()

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

func drawWireframe():
	var cubeMeshInstance = get_node("Meshes/Cube")
	var cubeMesh = cubeMeshInstance.get_mesh()
	
	var ig = ImmediateGeometry.new()
	var sm = SpatialMaterial.new()
	sm.flags_unshaded = true
	sm.vertex_color_use_as_albedo = true
	ig.material_override = sm

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

func _on_StaticBody_mouse_entered():
	print("In cube")

func _on_StaticBody_mouse_exited():
	print("Out cube")

func _on_StaticBody_input_event(camera, event, click_position, click_normal, shape_idx):
	if event.is_action_pressed("left_mouse"):
		print("Pos ", click_position)
