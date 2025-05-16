extends Node3D
class_name RenderingLayer3D

var current_active_location: Node3D

func _ready():
	GameGlobals.rendering_layer = self
	print("3D Rendering Layer initialized")

func render_location(location_data):
	# For now, just print - we'll implement this fully later
	print("Rendering location: ", location_data)
