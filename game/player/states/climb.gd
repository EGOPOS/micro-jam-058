extends PlayerAttachableState

var camera: Camera3D

func enter(data):
	super(data)
	camera = get_viewport().get_camera_3d()
	player.reset_jump_buffer()
	#player.camera_animation_strength = player.camera_animation_air_strength

func physics_update(delta):
	super(delta)
	
	var sum_velocity = Vector3()
	var attached_positions = player.get_attached_positions()
	
	if attached_positions.is_empty():
		if not player.is_on_floor():
			change_state(states.Fall)
		else:
			change_state(states.Idle)
		return
	
	if player.is_right_unattaching():
		player.attached_points.right = null
	
	if player.is_left_unattaching():
		player.attached_points.left = null
		
	if player.is_can_jump() and Input.is_action_just_pressed("movement_jump"):
		change_state(states.Jump)
		return
	
	var average_point = Vector3()
	for point: Vector3 in attached_positions:
		average_point += point
	average_point /= attached_positions.size()
	
	var camera_forward = -camera.global_transform.basis.z
	var target_pos = average_point + camera_forward * player.lean_amount
	
	var target_velocity = (target_pos - player.global_position) * player.lean_speed
	player.apply_climb_attaching(delta, target_velocity)
	
	var direction = player.get_direction()
	player.apply_air_acceleration(delta, direction)
	
	player.move_and_slide()

func exit():
	super()
	player.attached_points.left = null
	player.attached_points.right = null
