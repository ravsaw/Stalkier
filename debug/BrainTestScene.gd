extends Node3D

var test_npc: TestNPC
var debug_ui: Control
var camera: Camera3D
var camera_controller: CameraController

func _ready():
	_setup_test_environment()
	_create_debug_ui()
	print("Debug test scene ready")

func _setup_test_environment():
	# Create test NPC
	test_npc = TestNPC.new()
	test_npc.name = "TestNPC"
	test_npc.position = Vector3(0, 1, 0)
	add_child(test_npc)
	
	# Add simple floor
	var floor = StaticBody3D.new()
	var floor_shape = CollisionShape3D.new()
	floor_shape.shape = BoxShape3D.new()
	floor_shape.shape.size = Vector3(20, 0.1, 20)
	floor.add_child(floor_shape)
	
	var floor_mesh = MeshInstance3D.new()
	floor_mesh.mesh = BoxMesh.new()
	floor_mesh.mesh.size = Vector3(20, 0.1, 20)
	var floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color.GRAY
	floor_mesh.set_surface_override_material(0, floor_material)
	floor.add_child(floor_mesh)
	add_child(floor)
	
	# Setup camera
	_setup_camera()
	
	# Create some random obstacles
	_create_obstacles()

func _setup_camera():
	camera = Camera3D.new()
	camera.position = Vector3(0, 5, 10)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	add_child(camera)
	
	# Simple camera controller
	camera_controller = CameraController.new()
	camera_controller.camera = camera
	camera_controller.target = test_npc
	add_child(camera_controller)

func _create_obstacles():
	# Add some obstacles for pathfinding
	for i in range(5):
		var obstacle = StaticBody3D.new()
		var obstacle_shape = CollisionShape3D.new()
		obstacle_shape.shape = BoxShape3D.new()
		obstacle_shape.shape.size = Vector3(1, 2, 1)
		obstacle.add_child(obstacle_shape)
		
		var obstacle_mesh = MeshInstance3D.new()
		obstacle_mesh.mesh = BoxMesh.new()
		obstacle_mesh.mesh.size = Vector3(1, 2, 1)
		var obstacle_material = StandardMaterial3D.new()
		obstacle_material.albedo_color = Color.RED
		obstacle_mesh.set_surface_override_material(0, obstacle_material)
		obstacle.add_child(obstacle_mesh)
		
		# Random position
		obstacle.position = Vector3(
			randf_range(-8, 8),
			1,
			randf_range(-8, 8)
		)
		add_child(obstacle)

func _create_debug_ui():
	debug_ui = Control.new()
	debug_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(debug_ui)
	
	# Create instruction panel
	var instructions = _create_instruction_panel()
	debug_ui.add_child(instructions)
	
	# The debug viewer will be created automatically by the NPC's brain system

func _create_instruction_panel() -> Panel:
	var panel = Panel.new()
	panel.position = Vector2(10, 10)
	panel.size = Vector2(300, 150)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("margin", 10)
	
	var title = Label.new()
	title.text = "AI Test Scene"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	var instructions = Label.new()
	instructions.text = "Instructions:\n• Click buttons in Debug Viewer to give NPC goals\n• Watch NPC behavior in 3D view\n• Monitor brain states in debug panel"
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(instructions)
	
	# Add direct control buttons
	var btn_container = HBoxContainer.new()
	vbox.add_child(btn_container)
	
	var explore_btn = Button.new()
	explore_btn.text = "Random Explore"
	explore_btn.pressed.connect(_give_random_goal)
	btn_container.add_child(explore_btn)
	
	var toggle_debug_btn = Button.new()
	toggle_debug_btn.text = "Toggle Debug"
	toggle_debug_btn.pressed.connect(_toggle_debug_viewer)
	btn_container.add_child(toggle_debug_btn)
	
	return panel

func _input(event):
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_SPACE:
				_give_random_goal()
			KEY_D:
				_toggle_debug_viewer()
			KEY_R:
				_reset_npc()

func _give_random_goal():
	if test_npc:
		var target = Vector3(
			randf_range(-8, 8),
			1,
			randf_range(-8, 8)
		)
		test_npc.give_exploration_goal(target)

func _toggle_debug_viewer():
	if test_npc and test_npc.brain_system and test_npc.brain_system.debug_viewer:
		var debug_viewer = test_npc.brain_system.debug_viewer
		debug_viewer.visible = not debug_viewer.visible

func _reset_npc():
	if test_npc:
		test_npc.position = Vector3(0, 1, 0)
		test_npc.velocity = Vector3.ZERO
		print("NPC reset to origin")

class CameraController:
	extends Node
	
	var camera: Camera3D
	var target: Node3D
	var distance: float = 10.0
	var height: float = 5.0
	var rotation_speed: float = 2.0
	
	func _process(delta):
		if not camera or not target:
			return
		
		# Simple camera follow
		var target_pos = target.global_position + Vector3(0, height, distance)
		camera.global_position = camera.global_position.lerp(target_pos, 2.0 * delta)
		camera.look_at(target.global_position, Vector3.UP)
