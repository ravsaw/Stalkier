# scenes/areas/Area3D.gd
extends Node3D

# === AREA DATA ===
var area_data: Area
var area_id: String

# === SCENE REFERENCES ===
@onready var visual_layer: Node3D = $VisualLayer
@onready var terrain_mesh: MeshInstance3D = $VisualLayer/TerrainMesh
@onready var npc_container: Node3D = $NPCContainer
@onready var poi_container: Node3D = $POIContainer
@onready var navigation_region: NavigationRegion3D = $NavigationRegion3D
@onready var transition_points: Node3D = $TransitionPoints
@onready var environment: Node3D = $Environment
@onready var lighting: Node3D = $Environment/Lighting

# === 3D ASSETS ===
var npc_3d_scene = preload("res://scenes/npcs/NPCAgent3D.tscn")

func setup(area: Area):
	"""Initialize the 3D area with data"""
	area_data = area
	area_id = area.area_id
	name = "Area3D_" + area_id
	
	# Setup 3D environment
	setup_terrain()
	setup_navigation_3d()
	setup_lighting()
	setup_environment_effects()
	
	print("Setup 3D area: %s" % [area.display_name])

func setup_terrain():
	"""Generate 3D terrain for the area"""
	var terrain_material = StandardMaterial3D.new()
	terrain_material.albedo_color = get_terrain_color_3d(area_data.terrain_type)
	
	# Create simple plane mesh for terrain
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(1000, 1000)  # Match area size
	plane_mesh.subdivide_width = 32
	plane_mesh.subdivide_depth = 32
	
	terrain_mesh.mesh = plane_mesh
	terrain_mesh.material_override = terrain_material
	
	# Add some height variation based on terrain type
	if area_data.terrain_type == Area.TerrainType.MOUNTAINS:
		add_terrain_height_variation()

func setup_navigation_3d():
	"""Setup 3D navigation mesh"""
	var nav_mesh = NavigationMesh.new()
	
	# Configure navigation mesh parameters
	nav_mesh.geometry_collision_mask = 1
	nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	nav_mesh.cell_size = 0.25
	nav_mesh.cell_height = 0.2
	nav_mesh.agent_height = 2.0
	nav_mesh.agent_radius = 0.5
	nav_mesh.agent_max_climb = 0.9
	nav_mesh.agent_max_slope = 45.0
	
	navigation_region.navigation_mesh = nav_mesh
	
	# Bake navigation mesh
	call_deferred("bake_navigation_mesh")

func bake_navigation_mesh():
	"""Bake the navigation mesh for this area"""
	if navigation_region and navigation_region.navigation_mesh:
		# In a full implementation, you would bake the navigation mesh here
		# NavigationServer3D.bake_from_source_geometry_data(...)
		print("Navigation mesh baked for area: %s" % area_id)

func setup_lighting():
	"""Setup area lighting based on environment"""
	var directional_light = lighting.get_node("DirectionalLight3D")
	
	# Adjust lighting based on area properties
	match area_data.climate:
		Area.Climate.COLD:
			directional_light.light_color = Color(0.8, 0.9, 1.0)  # Cool light
			directional_light.light_energy = 0.8
		Area.Climate.HOT:
			directional_light.light_color = Color(1.0, 0.9, 0.7)  # Warm light
			directional_light.light_energy = 1.2
		Area.Climate.TOXIC:
			directional_light.light_color = Color(0.7, 1.0, 0.7)  # Sickly green
			directional_light.light_energy = 0.6
		_:
			directional_light.light_color = Color.WHITE
			directional_light.light_energy = 1.0

func setup_environment_effects():
	"""Setup environmental effects like fog, particles, etc."""
	# Add environmental effects based on area properties
	match area_data.climate:
		Area.Climate.WET:
			add_fog_effect()
		Area.Climate.TOXIC:
			add_toxic_atmosphere()
		Area.Climate.DRY:
			add_dust_particles()

func get_terrain_color_3d(terrain_type: int) -> Color:
	"""Get 3D terrain color"""
	match terrain_type:
		Area.TerrainType.PLAINS:
			return Color(0.4, 0.7, 0.2)
		Area.TerrainType.FOREST:
			return Color(0.2, 0.5, 0.1)
		Area.TerrainType.MOUNTAINS:
			return Color(0.6, 0.6, 0.6)
		Area.TerrainType.SWAMP:
			return Color(0.3, 0.4, 0.2)
		Area.TerrainType.DESERT:
			return Color(0.8, 0.7, 0.4)
		Area.TerrainType.URBAN:
			return Color(0.5, 0.5, 0.5)
		Area.TerrainType.INDUSTRIAL:
			return Color(0.4, 0.3, 0.2)
		Area.TerrainType.UNDERGROUND:
			return Color(0.3, 0.2, 0.2)
		_:
			return Color.GRAY

func add_terrain_height_variation():
	"""Add height variation to terrain mesh"""
	# This would involve modifying the mesh vertices
	# For now, just adjust the scale slightly
	terrain_mesh.scale = Vector3(1.0, 0.5, 1.0)

func add_fog_effect():
	"""Add fog effect to the area"""
	# Create fog environment
	var fog_environment = Environment.new()
	fog_environment.fog_enabled = true
	fog_environment.fog_light_color = Color(0.8, 0.9, 1.0)
	fog_environment.fog_density = 0.01
	
	# Apply to camera when player enters area
	# This would need to be handled by the camera system

func add_toxic_atmosphere():
	"""Add toxic atmosphere effects"""
	# Create particle system for toxic atmosphere
	var particles = GPUParticles3D.new()
	particles.emitting = true
	particles.amount = 100
	particles.lifetime = 5.0
	
	environment.add_child(particles)

func add_dust_particles():
	"""Add dust particle effects"""
	var dust_particles = GPUParticles3D.new()
	dust_particles.emitting = true
	dust_particles.amount = 50
	dust_particles.lifetime = 10.0
	
	environment.add_child(dust_particles)

func add_npc_3d(npc: NPC) -> Node3D:
	"""Add 3D representation of NPC"""
	var npc_3d_instance = npc_3d_scene.instantiate()
	npc_3d_instance.name = "NPC3D_" + npc.npc_id
	
	# Position in 3D space
	var local_3d_pos = CoordinateConverter.world_2d_to_local_3d(npc.position, area_data.world_position)
	npc_3d_instance.position = local_3d_pos
	
	# Setup the 3D NPC
	npc_3d_instance.setup(npc)
	
	npc_container.add_child(npc_3d_instance)
	
	# Connect 3D navigation agent to NPC
	var nav_agent_3d = npc_3d_instance.get_node("NavigationAgent3D")
	if nav_agent_3d:
		npc.set_navigation_agent_3d(nav_agent_3d)
	
	return npc_3d_instance

func remove_npc_3d(npc_id: String):
	"""Remove 3D NPC representation"""
	var npc_3d = npc_container.get_node_or_null("NPC3D_" + npc_id)
	if npc_3d:
		npc_3d.queue_free()

func update_npc_3d_position(npc: NPC):
	"""Update 3D NPC position"""
	var npc_3d = npc_container.get_node_or_null("NPC3D_" + npc.npc_id)
	if npc_3d:
		var local_3d_pos = CoordinateConverter.world_2d_to_local_3d(npc.position, area_data.world_position)
		npc_3d.position = local_3d_pos

func add_transition_point_3d(transition: TransitionPoint):
	"""Add 3D visual for transition point"""
	var transition_visual = Node3D.new()
	transition_visual.name = "Transition3D_" + transition.transition_id
	
	# Convert position to 3D
	var local_3d_pos = CoordinateConverter.world_2d_to_local_3d(transition.from_position, area_data.world_position)
	transition_visual.position = local_3d_pos
	
	# Create 3D transition marker
	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = 5.0
	cylinder_mesh.top_radius = 2.0
	cylinder_mesh.bottom_radius = 2.0
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.CYAN
	material.emission_enabled = true
	material.emission = Color.CYAN * 0.3
	
	mesh_instance.mesh = cylinder_mesh
	mesh_instance.material_override = material
	
	transition_visual.add_child(mesh_instance)
	transition_points.add_child(transition_visual)

func get_spawn_position_3d() -> Vector3:
	"""Get a valid 3D spawn position in this area"""
	var spawn_2d = area_data.get_random_spawn_point()
	return CoordinateConverter.world_2d_to_local_3d(spawn_2d, area_data.world_position)

func is_position_valid_3d(pos: Vector3) -> bool:
	"""Check if a 3D position is valid in this area"""
	# Convert to 2D and check area bounds
	var world_2d = CoordinateConverter.local_3d_to_world_2d(pos, area_data.world_position)
	return area_data.is_position_in_area(world_2d)

func cleanup():
	"""Clean up 3D area resources"""
	# Remove all 3D elements
	for child in npc_container.get_children():
		child.queue_free()
	
	for child in poi_container.get_children():
		child.queue_free()
	
	for child in transition_points.get_children():
		child.queue_free()
	
	for child in environment.get_children():
		if child != lighting:  # Keep basic lighting
			child.queue_free()

func get_area_bounds_3d() -> AABB:
	"""Get 3D bounding box for this area"""
	var half_size = 500.0
	return AABB(
		Vector3(-half_size, -10, -half_size),
		Vector3(1000, 20, 1000)
	)