class_name OutlineInteractVisualizer extends InteractVisualizer

@export var mesh_node_path: NodePath

var outline_material: ShaderMaterial = preload("res://assets/materials/shaders/interact_outline_shader.tres")

func toggle(value):
	var mesh: GeometryInstance3D = interaction_area.get_node(mesh_node_path)
	mesh.material_overlay = outline_material if value else null
