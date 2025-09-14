# scenes/areas/Area2D.gd
extends Node2D

# === AREA DATA ===
var area_data: Area
var area_id: String

# === SCENE REFERENCES ===
@onready var visual_layer: Node2D = $VisualLayer
@onready var npc_container: Node2D = $NPCContainer
@onready var poi_container: Node2D = $POIContainer
@onready var navigation_region: NavigationRegion2D = $NavigationRegion2D
@onready var transition_points: Node2D = $TransitionPoints
@onready var area_bounds: Area2D = $AreaBounds

# === VISUAL ELEMENTS ===
var background_sprite: Sprite2D
var area_label: Label

func setup(area: Area):
	"""Initialize the 2D area with data"""
	area_data = area
	area_id = area.area_id
	name = "Area2D_" + area_id
	
	position = area.world_position
	
	# Setup visual elements
	setup_background()
	setup_label()
	setup_navigation()
	setup_bounds()
	
	print("Setup 2D area: %s at %s" % [area.display_name, area.world_position])

func setup_background():
	"""Setup background visual representation"""
	background_sprite = Sprite2D.new()
	
	# Create simple colored background based on terrain type
	var texture = ImageTexture.new()
	var image = Image.create(100, 100, false, Image.FORMAT_RGB8)
	
	var color = get_terrain_color(area_data.terrain_type)
	image.fill(color)
	texture.set_image(image)
	
	background_sprite.texture = texture
	background_sprite.scale = Vector2(10, 10)  # Scale up to area size
	background_sprite.modulate.a = 0.3  # Semi-transparent
	
	visual_layer.add_child(background_sprite)

func setup_label():
	"""Setup area name label"""
	area_label = Label.new()
	area_label.text = area_data.display_name
	area_label.position = Vector2(-100, -50)
	area_label.add_theme_font_size_override("font_size", 24)
	
	# Color label based on area type
	match area_data.area_type:
		Area.AreaType.SAFE_ZONE:
			area_label.modulate = Color.GREEN
		Area.AreaType.DANGER_ZONE:
			area_label.modulate = Color.RED
		Area.AreaType.SETTLEMENT:
			area_label.modulate = Color.BLUE
		_:
			area_label.modulate = Color.WHITE
	
	visual_layer.add_child(area_label)

func setup_navigation():
	"""Setup navigation region for this area"""
	var nav_polygon = NavigationPolygon.new()
	
	# Create navigation area boundaries
	var half_size = 500.0  # Half of 1000x1000 area
	var boundary = PackedVector2Array([
		Vector2(-half_size, -half_size),
		Vector2(half_size, -half_size),
		Vector2(half_size, half_size),
		Vector2(-half_size, half_size)
	])
	
	nav_polygon.add_outline(boundary)
	nav_polygon.make_polygons_from_outlines()
	
	navigation_region.navigation_polygon = nav_polygon

func setup_bounds():
	"""Setup area boundary detection"""
	var collision_shape = RectangleShape2D.new()
	collision_shape.size = Vector2(1000, 1000)
	
	var collision_node = area_bounds.get_node("AreaBoundsCollision")
	collision_node.shape = collision_shape
	
	# Connect boundary signals
	area_bounds.body_entered.connect(_on_body_entered)
	area_bounds.body_exited.connect(_on_body_exited)

func get_terrain_color(terrain_type: int) -> Color:
	"""Get color representation for terrain type"""
	match terrain_type:
		Area.TerrainType.PLAINS:
			return Color.GREEN
		Area.TerrainType.FOREST:
			return Color.DARK_GREEN
		Area.TerrainType.MOUNTAINS:
			return Color.GRAY
		Area.TerrainType.SWAMP:
			return Color(0.4, 0.6, 0.3)
		Area.TerrainType.DESERT:
			return Color.YELLOW
		Area.TerrainType.URBAN:
			return Color.LIGHT_GRAY
		Area.TerrainType.INDUSTRIAL:
			return Color(0.5, 0.3, 0.2)
		Area.TerrainType.UNDERGROUND:
			return Color(0.2, 0.2, 0.2)
		_:
			return Color.WHITE

func add_npc_visual(npc: NPC):
	"""Add visual representation of NPC to this area"""
	# This would create a simple 2D representation
	var npc_visual = Node2D.new()
	npc_visual.name = "NPC_" + npc.npc_id
	npc_visual.position = npc.position - area_data.world_position
	
	# Simple circle representation
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://npc.png")  # Use existing NPC sprite
	sprite.scale = Vector2(0.5, 0.5)
	
	npc_visual.add_child(sprite)
	npc_container.add_child(npc_visual)

func remove_npc_visual(npc_id: String):
	"""Remove NPC visual from this area"""
	var npc_visual = npc_container.get_node_or_null("NPC_" + npc_id)
	if npc_visual:
		npc_visual.queue_free()

func update_npc_position(npc: NPC):
	"""Update NPC visual position"""
	var npc_visual = npc_container.get_node_or_null("NPC_" + npc.npc_id)
	if npc_visual:
		npc_visual.position = npc.position - area_data.world_position

func add_transition_point_visual(transition: TransitionPoint):
	"""Add visual for transition point"""
	var transition_visual = Node2D.new()
	transition_visual.name = "Transition_" + transition.transition_id
	transition_visual.position = transition.from_position - area_data.world_position
	
	# Create transition marker
	var sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(20, 20, false, Image.FORMAT_RGB8)
	image.fill(Color.CYAN)
	texture.set_image(image)
	sprite.texture = texture
	
	transition_visual.add_child(sprite)
	transition_points.add_child(transition_visual)

func _on_body_entered(body):
	"""Handle something entering area bounds"""
	# This could be used for area entry detection
	pass

func _on_body_exited(body):
	"""Handle something exiting area bounds"""
	# This could be used for area exit detection
	pass

func get_local_position(world_pos: Vector2) -> Vector2:
	"""Convert world position to local area position"""
	return world_pos - area_data.world_position

func get_world_position(local_pos: Vector2) -> Vector2:
	"""Convert local area position to world position"""
	return area_data.world_position + local_pos

func cleanup():
	"""Clean up area resources"""
	# Remove all visual elements
	for child in npc_container.get_children():
		child.queue_free()
	
	for child in poi_container.get_children():
		child.queue_free()
	
	for child in transition_points.get_children():
		child.queue_free()