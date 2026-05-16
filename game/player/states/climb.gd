extends PlayerAttachableState

var camera: Camera3D

func enter(data):
	super(data)
	camera = get_viewport().get_camera_3d()
	player.reset_jump_buffer()
	#player.camera_animation_strength = player.camera_animation_air_strength

func physics_update(delta):
	super(delta)
	
	#player.spend_stamina(delta)
	
	var attached_positions = player.get_attached_positions()
	
	if attached_positions.is_empty() or not player.is_can_climb():
		if not player.is_on_floor():
			change_state(states.Fall)
		else:
			change_state(states.Idle)
		return
	
	if player.is_right_unattaching():
		player.attached_points.right = null
		player.right_attach_toggled.emit(null)
	
	if player.is_left_unattaching():
		player.attached_points.left = null
		player.left_attach_toggled.emit(null)
		
	if player.is_can_jump() and Input.is_action_just_pressed("movement_jump"):
		change_state(states.Jump, {
			"multiplier": player.climb_jump_velocity_multiplier
		})
		return
	
	var average_point: Vector3 = Vector3()
	for point: Vector3 in attached_positions:
		average_point += point
	average_point /= attached_positions.size()
	
	var direction = player.get_free_direction()
	var target_pos = average_point + direction * player.lean_amount
	
	var multiplier = 1.0 # 1.0 — жесткое ограничение, 0.1 — мягкое «резиновое» натяжение
	var distance = player.global_position.distance_to(average_point)
	if distance > player.max_attach_distance:
		var dir = (player.global_position - average_point).normalized()
		var target_position = average_point + dir * player.max_attach_distance
		player.global_position = player.global_position.lerp(target_position, multiplier)
		
		#multiplier += (diff.length() - player.lean_amount)
		#print(average_point, player.global_position)
	
	var target_velocity = (target_pos - player.global_position) * player.lean_speed
	player.apply_climb_attaching(delta, target_velocity, player.lean_speed)
	
	player.move_and_slide()

func exit():
	super()
	player.time_not_climbing = get_time()
	player.attached_points.left = null
	player.attached_points.right = null
	player.right_attach_toggled.emit(null)
	player.left_attach_toggled.emit(null)
