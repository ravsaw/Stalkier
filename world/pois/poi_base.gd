# Basic POI implementation
extends Node3D
class_name POI

@export var poi_id: String = "default_poi"
@export var poi_type: String = "generic"  # settlement, outpost, resource_site, etc.
@export var poi_name: String = "Default POI"
@export var influence_radius: float = 50.0

# Basic POI state - can be expanded later for A-Life integration
@export var controlled_by: String = "neutral"  # faction_id or "neutral"
@export var is_accessible: bool = true

# Visual components
@export var show_influence_radius: bool = false

var influence_visualization: MeshInstance3D

func _ready():
	# Create influence radius visualization if needed
	if show_influence_radius:
		create_influence_visualization()
	
	# Initialize any sub-objects
	#initialize_sub_objects()

func create_influence_visualization():
	influence_visualization = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = influence_radius
	mesh.height = influence_radius * 2
	
	influence_visualization.mesh = mesh
	influence_visualization.material_override = StandardMaterial3D.new()
	influence_visualization.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	influence_visualization.material_override.albedo_color = Color(0, 1, 0, 0.1)
	
	add_child(influence_visualization)

#func initialize_sub_objects():
	# Find and setup any children that are POI sub-objects
#	for child in get_children():
#		if child is POISubObject:
#			child.initialize(self)

func is_point_inside_influence(point: Vector3) -> bool:
	var distance = point.distance_to(global_transform.origin)
	return distance <= influence_radius

func get_poi_info() -> Dictionary:
	return {
		"id": poi_id,
		"name": poi_name,
		"type": poi_type,
		"position": global_transform.origin,
		"controlled_by": controlled_by,
		"is_accessible": is_accessible
	}
