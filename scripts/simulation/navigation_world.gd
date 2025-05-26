# scripts/simulation/navigation_world.gd - nowy komponent
extends Node2D
class_name NavigationWorld 

@onready var navigation_region: NavigationRegion2D = $NavigationRegion2D
@onready var navigation_map: RID

# === CONFIGURATION ===
@export var world_size: Vector2 = Vector2(400, 400)  # 100 units * 4 scale
@export var cell_size: float = 2.0
@export var obstacle_margin: float = 5.0

func _ready():
    setup_navigation_region()
    create_navigation_mesh()
    register_obstacles()

func setup_navigation_region():
    navigation_map = NavigationServer2D.map_create()
    NavigationServer2D.map_set_active(navigation_map, true)
    NavigationServer2D.map_set_cell_size(navigation_map, cell_size)
    
    navigation_region.set_navigation_map(navigation_map)

func create_navigation_mesh():
    var nav_mesh = NavigationPolygon.new()
    
    # Create basic walkable area (entire world)
    var world_outline = PackedVector2Array([
        Vector2(0, 0),
        Vector2(world_size.x, 0),
        Vector2(world_size.x, world_size.y),
        Vector2(0, world_size.y)
    ])
    nav_mesh.add_outline(world_outline)
    
    # Add obstacles around POIs and dangerous areas
    add_poi_obstacles(nav_mesh)
    add_terrain_obstacles(nav_mesh)
    
    # Bake the navigation mesh
    nav_mesh.make_polygons_from_outlines()
    navigation_region.set_navigation_polygon(nav_mesh)

func add_poi_obstacles(nav_mesh: NavigationPolygon):
    for poi in POIManager.get_all_pois():
        match poi.poi_type:
            POI.POIType.ANOMALY_ZONE:
                # Anomaly zones are partial obstacles - dangerous but passable
                add_hazard_zone(nav_mesh, poi.position, 8.0, 0.5)
            
            POI.POIType.INDUSTRIAL_RUINS:
                # Complex obstacle layout for ruins
                add_building_obstacles(nav_mesh, poi.position, 15.0)
            
            _:
                # Regular POIs have small obstacle around them
                add_circular_obstacle(nav_mesh, poi.position, 3.0)

func add_hazard_zone(nav_mesh: NavigationPolygon, center: Vector2, radius: float, danger_level: float):
    # Create navigation penalty area (not complete obstacle)
    # Higher danger = higher navigation cost
    var penalty_outline = create_circle_outline(center, radius)
    nav_mesh.add_outline(penalty_outline)
    
    # Register as high-cost area
    NavigationServer2D.map_set_cell_size(navigation_map, cell_size * (1.0 + danger_level))

func get_navigation_map() -> RID:
    return navigation_map