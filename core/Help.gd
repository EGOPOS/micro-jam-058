extends Node

func get_camera_center_hit(ray_length: float = 10.0, collision_mask: int = 1, with_areas: bool = false) -> Dictionary:
	var viewport := get_viewport()
	var camera := viewport.get_camera_3d()
	
	if not camera:
		return {}
		
	# 1. Берем логический центр игрового экрана (разрешение проекта)
	var logical_center := viewport.get_visible_rect().size / 2.0
	
	# 2. УМНОЖАЕМ НА МАТРИЦУ ТРАНСФОРМАЦИИ:
	# Это переводит логические координаты в реальные пиксели вьюпорта,
	# автоматически учитывая черные полосы, растяжение canvas_items или viewport.
	var screen_center := viewport.get_canvas_transform() * logical_center
	
	# 3. Проецируем луч из полученной математически точной точки
	var ray_origin := camera.project_ray_origin(screen_center)
	var ray_normal := camera.project_ray_normal(screen_center)
	var ray_to := ray_origin + ray_normal * ray_length
	
	var space_state := camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_to, collision_mask)
	query.collide_with_areas = with_areas
	
	return space_state.intersect_ray(query)


func get_mouse_center_offset() -> Vector2:
	var viewport := get_viewport()
	
	# Находим точный центр экрана в пикселях системы координат вьюпорта
	var logical_center := viewport.get_visible_rect().size / 2.0
	var screen_center := viewport.get_canvas_transform() * logical_center
	
	# Позиция мыши (она уже находится в пикселях вьюпорта)
	var mouse_pos := viewport.get_mouse_position()
	
	return mouse_pos - screen_center


func get_collision_mask(layers: Array[int]) -> int:
	var mask: int = 0
	for layer in layers:
		if layer >= 1 and layer <= 32:
			mask |= 1 << (layer - 1)
	return mask
