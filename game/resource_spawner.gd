extends Node3D

@export var spawn: bool = false

@export var level_meshes: Node3D
@export var level_static_body: StaticBody3D

@export_category("Resources")
## Сцена ресурса для спавна
@export var spawn_chance_table: Dictionary[PackedScene, float] = {
	
}
@export var spawn_level_table: Dictionary[PackedScene, Curve] = {
	
}

## Узел, куда будут складываться ресурсы
@export var resources_container: Node3D
## Максимальная глубина для расчета шанса по кривой (от y_limit вниз)
@export var start_spawn_y: float = -5.0
@export var spacing: float = 3
@export var spawn_max_depth: float = -25.0
@export var spawn_curve: Curve
@export var resource_count: int = 400


func _ready() -> void:
	if not spawn:
		return
	fill_resources_below_y(start_spawn_y, spawn_max_depth, spacing, spawn_curve)

func fill_resources_below_y(spawn_from: float, spawn_to: float, spacing: float, spawn_curve: Curve) -> void:
	if resources_container == null:
		resources_container = self
		
	if spawn_curve == null:
		push_error("Spawn curve is not assigned!")
		return

	var bounds: AABB = _get_level_bounds()
	if bounds.size == Vector3.ZERO:
		push_warning("Could not determine level bounds for resource spawning.")
		return
	
	var space_state := get_world_3d().direct_space_state
	
	# Итерируемся по сетке XZ в пределах границ уровня
	var x_steps: int = int(bounds.size.x / spacing)
	var z_steps: int = int(bounds.size.z / spacing)
	
	for i in range(x_steps + 1):
		for j in range(z_steps + 1):
			var x: float = bounds.position.x + i * spacing
			var z: float = bounds.position.z + j * spacing
			x += randf() * spacing
			z += randf() * spacing
			
			# Пускаем луч сверху вниз от spawn_from
			var ray_origin := Vector3(x, spawn_from + 1.0, z)
			var ray_end := Vector3(x, clamp(bounds.position.y - 10.0, spawn_to, spawn_from), z) # До дна уровня с запасом
			
			var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
			# Исключаем уже существующие ресурсы и игрока из проверок, если нужно
			# В данном случае лучше всего проверять только столкновения с уровнем
			if level_static_body:
				query.collision_mask = level_static_body.collision_layer
			
			var result := space_state.intersect_ray(query)
			
			if result:
				var hit_pos: Vector3 = result.position
				var hit_normal: Vector3 = result.normal
				
				# Проверяем, что точка попадания ниже лимита
				if hit_pos.y <= spawn_from:
					var depth: float = spawn_from - hit_pos.y
					var t: float = clamp(depth / spawn_to, 0.0, 1.0)
					var chance: float = spawn_curve.sample_baked(t)
					
					if randf() < chance:
						_spawn_resource_at(hit_pos, hit_normal)
 
 
func _spawn_resource_at(pos: Vector3, normal: Vector3) -> void:
	var y_level = pos.y
	
	# Нормализуем высоту (от 0.0 до 1.0)
	var sample_pos = clamp(y_level / spawn_max_depth, 0.0, 1.0)
	
	var resources = spawn_chance_table.keys()
	# ОБЯЗАТЕЛЬНО перемешиваем, так как шансы теперь независимые.
	# Иначе первый ресурс в списке всегда будет проверяться первым.
	resources.shuffle()
	
	var res: Node3D = null
	
	for resource in resources:
		var base_chance = spawn_chance_table[resource]
		var level_modifier = 1.0
		
		# Читаем значение из Curve
		if spawn_level_table.has(resource) and spawn_level_table[resource] != null:
			level_modifier = spawn_level_table[resource].sample(sample_pos)
		
		# Если по кривой на этой высоте спавн запрещен (значение 0), пропускаем
		if level_modifier <= 0.0:
			continue
			
		# Итоговый абсолютный шанс для этого конкретного ресурса
		var final_chance = base_chance * level_modifier
		
		# Делаем независимый бросок
		if randf() <= final_chance:
			res = resource.instantiate()
			break # Ресурс успешно выбран, остальные на эту точку не претендуют
			
	# Если ни один ресурс не выпал (что нормально при независимых шансах)
	if res == null:
		return

	# Добавляем на сцену
	resources_container.add_child(res)
	res.global_position = pos
	
	# Выравниваем ресурс по нормали поверхности
	if normal.dot(Vector3.UP) < 0.99:
		var axis := Vector3.UP.cross(normal).normalized()
		var angle := Vector3.UP.angle_to(normal)
		if axis.length() > 0.001:
			res.rotate(axis, angle)
	
	# Случайное вращение вокруг собственной оси Y для разнообразия
	res.rotate_object_local(Vector3.UP, randf() * TAU)
 
 
func _get_level_bounds() -> AABB:
	var total_aabb := AABB()
	var first := true
	
	if level_meshes:
		for child in level_meshes.find_children("*", "MeshInstance3D", true):
			var mesh_instance := child as MeshInstance3D
			if mesh_instance and mesh_instance.visible:
				var local_aabb: AABB = mesh_instance.get_mesh().get_aabb()
				var global_aabb: AABB = mesh_instance.global_transform * local_aabb
				
				if first:
					total_aabb = global_aabb
					first = false
				else:
					total_aabb = total_aabb.merge(global_aabb)
 
	return total_aabb
