extends Node

func get_camera_center_hit(ray_length: float = 10, collision_mask = get_collision_mask([1]),  with_areas: bool = false) -> Dictionary:
	var viewport = get_viewport()
	var camera = viewport.get_camera_3d()
	
	# Если камеры нет на сцене, выходим
	if not camera:
		return {}
		
	# 1. Находим центр экрана
	var screen_center = viewport.size / 2
	
	# 2. Проецируем луч из центра камеры в 3D пространство
	var ray_origin = camera.project_ray_origin(screen_center)
	var ray_normal = camera.project_ray_normal(screen_center)
	var ray_to = ray_origin + ray_normal * ray_length
	
	# 3. Получаем доступ к прямому состоянию физического пространства (Физикс-сервер)
	var space_state = camera.get_world_3d().direct_space_state
	
	# 4. Создаем параметры запроса для Godot 4
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_to, collision_mask)
	query.collide_with_areas = with_areas
	
	# Опционально: исключить определенные объекты (например, самого игрока)
	# query.exclude = [self.get_rid()]
	
	# Опционально: настроить маску коллизий (по умолчанию проверяет все слои)
	# query.collision_mask = 1 
	
	# 5. Пускаем луч
	var result = space_state.intersect_ray(query)
	
	# 6. Обрабатываем результат
	if not result.is_empty():
		# Возвращаем точку пересечения в глобальных координатах
		return result
		
	return {}


func get_mouse_center_offset() -> Vector2:
	var viewport: Viewport = get_viewport()
	var screen_center: Vector2 = viewport.get_visible_rect().size / 2
	var mouse_pos: Vector2 = viewport.get_mouse_position()
	
	return mouse_pos - screen_center


func get_collision_mask(layers: Array[int]) -> int:
	var mask: int = 0
	for layer in layers:
		if layer >= 1 and layer <= 32:
			mask |= 1 << (layer - 1)
	return mask
