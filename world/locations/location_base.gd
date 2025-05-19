# Base location class
extends Node3D
class_name Location

@export var location_name: String = "Default_Location"
@export var location_size: Vector3 = Vector3(1000, 500, 1000)  # Size in meters
@export var is_interior: bool = false
@export var default_ambient_light: Color = Color(0.1, 0.1, 0.1)

# POIs in this location
@export var pois: Array[NodePath] = []

# Visual boundary for debugging
@export var show_boundaries: bool = false

# Boundary visualization
var boundary_visualization: MeshInstance3D

func _ready():
	# Setup environment
	setup_environment()
	
	# Create boundary visualization if needed
	if show_boundaries:
		create_boundary_visualization()

func setup_environment():
	# Set up environment based on interior/exterior
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	
	if is_interior:
		# Interior environment settings
		env.ambient_light_color = default_ambient_light
		env.ambient_light_energy = 0.3
		env.fog_enabled = true
		env.fog_density = 0.01
	else:
		# Exterior environment settings
		env.ambient_light_color = default_ambient_light
		env.ambient_light_energy = 1.0
		env.fog_enabled = true
		env.fog_density = 0.001
	
	environment.environment = env
	add_child(environment)

func create_boundary_visualization():
	# Create a wireframe box showing the location boundaries
	boundary_visualization = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = location_size
	
	boundary_visualization.mesh = mesh
	boundary_visualization.material_override = StandardMaterial3D.new()
	boundary_visualization.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	boundary_visualization.material_override.albedo_color = Color(1, 0, 0, 0.2)
	
	add_child(boundary_visualization)

func get_boundaries() -> Dictionary:
	return {
		"center": global_transform.origin,
		"size": location_size
	}

func get_pois() -> Array:
	var poi_nodes = []
	for poi_path in pois:
		var poi = get_node(poi_path)
		if poi and poi is POI:
			poi_nodes.append(poi)
	return poi_nodes
