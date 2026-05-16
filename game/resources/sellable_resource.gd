class_name SellableResource extends StaticBody3D


func _ready() -> void:
	visibility_changed.connect(on_visibility_changed)

func on_visibility_changed():
	await get_tree().physics_frame
	set_collision_layer_value(3, visible)
